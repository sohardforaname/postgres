\set ON_ERROR_STOP on
\pset pager off
\timing on

-- Default output is compact.  Run with
--   psql -v topnbench_verbose=true -f contrib/topnbench/benchmark.sql
-- to include every per-case diagnostic row.
\if :{?topnbench_verbose}
\else
\set topnbench_verbose false
\endif

\echo
\echo '== Setup =='

DROP EXTENSION IF EXISTS topnbench;
CREATE EXTENSION topnbench;

DROP TABLE IF EXISTS topnbench_width_underestimate;
DROP TABLE IF EXISTS topnbench_width_overestimate;
DROP TABLE IF EXISTS topnbench_data;
CREATE UNLOGGED TABLE topnbench_data
(
    a integer NOT NULL,
    a_desc integer NOT NULL,
    a_random integer NOT NULL,
    same1 integer NOT NULL,
    same2 integer NOT NULL,
    inverse integer NOT NULL
);
INSERT INTO topnbench_data
SELECT g,
       1000001 - g,
       ((g::bigint * 48271) % 1000003)::integer,
       g,
       g,
       1000001 - g
FROM generate_series(1, 1000000) AS g;
ALTER TABLE topnbench_data SET (parallel_workers = 2);
ANALYZE topnbench_data;

\echo
\echo '== Generated quick matrix: upstream policy versus POC =='

-- Run the current PostgreSQL projection policy and the POC policy in the
-- same backend.  With the POC disabled, make_sort_input_target() retains the
-- upstream per-expression rule; it is not the same as forcing early
-- projection.
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
DROP TABLE IF EXISTS topnbench_master_results;
CREATE TEMP TABLE topnbench_master_results AS
SELECT *
FROM topnbench_run('topnbench_data', 'a_random', 5, 'quick', true);

-- Isolate the delayed-projection path construction from the new Sort cost.
SET enable_cost_based_delayed_projection = on;
SET enable_sort_tuple_width_cost = off;
DROP TABLE IF EXISTS topnbench_path_only_results;
CREATE TEMP TABLE topnbench_path_only_results AS
SELECT *
FROM topnbench_run('topnbench_data', 'a_random', 5, 'quick', true);

SET enable_sort_tuple_width_cost = on;

-- Materialize the POC run once so that the detail and summary queries below
-- use exactly the same measurements.
DROP TABLE IF EXISTS topnbench_results;
CREATE TEMP TABLE topnbench_results AS
SELECT *
FROM topnbench_run('topnbench_data', 'a_random', 5, 'quick', true);

\if :topnbench_verbose
SELECT case_name,
       round(selectivity::numeric, 6) AS selectivity,
       expression_shape,
       expression_steps,
       declared_cost,
       work_rounds,
       requested_workers AS workers,
       planner_choice,
       actual_winner,
       decision_class,
       planner_choice_correct AS correct,
       round(row_estimation_ratio::numeric, 3) AS row_est_error,
       estimated_sort_width AS est_width,
       sort_method,
       sort_space_type,
       round(sort_space_used_kb::numeric, 0) AS sort_kb,
       round(auto_median_ms::numeric, 3) AS auto_ms,
       round(manual_late_median_ms::numeric, 3) AS late_ms,
       round(forced_early_median_ms::numeric, 3) AS early_ms,
       round(choice_regression_ratio::numeric, 3) AS regret,
       cost_model_choice AS cost_model,
       structural_model_choice AS structural_model
FROM topnbench_results
ORDER BY ctid;
\endif

SELECT count(*) FILTER (WHERE planner_choice_correct) AS planner_correct,
       count(*) FILTER (WHERE planner_choice_correct = false) AS planner_wrong,
       count(*) FILTER (WHERE planner_choice_correct IS NULL) AS inconclusive,
       count(*) FILTER (WHERE decision_class = 'false-late') AS false_late,
       count(*) FILTER (WHERE decision_class = 'false-early') AS false_early,
       round(max(choice_regression_ratio)::numeric, 3) AS worst_regret,
       round((percentile_cont(0.95) WITHIN GROUP
              (ORDER BY choice_regression_ratio))::numeric, 3) AS p95_regret,
       count(*) FILTER (WHERE cost_model_correct) AS cost_model_correct,
       count(*) FILTER (WHERE cost_model_correct = false) AS cost_model_wrong,
       count(*) FILTER (WHERE structural_model_correct) AS structural_correct,
       count(*) FILTER (WHERE structural_model_correct = false) AS structural_wrong
FROM topnbench_results;

-- Compare planner decisions, using all policy runs only to establish whether
-- the measured winner was stable.  Strategy timings come from the POC run, so
-- the speedup is not contaminated by cross-run cache or frequency changes.
DROP TABLE IF EXISTS topnbench_choice_comparison;
CREATE TEMP TABLE topnbench_choice_comparison AS
WITH paired AS
(
    SELECT p.case_name,
           m.planner_choice AS master_choice,
           o.planner_choice AS path_only_choice,
           p.planner_choice AS patched_choice,
           m.actual_winner AS master_actual_winner,
           o.actual_winner AS path_only_actual_winner,
           p.actual_winner AS patched_actual_winner,
           CASE m.planner_choice
               WHEN 'late' THEN p.manual_late_median_ms
               WHEN 'early' THEN p.forced_early_median_ms
           END AS master_strategy_ms,
           CASE p.planner_choice
               WHEN 'late' THEN p.manual_late_median_ms
               WHEN 'early' THEN p.forced_early_median_ms
           END AS patched_strategy_ms,
           CASE o.planner_choice
               WHEN 'late' THEN p.manual_late_median_ms
               WHEN 'early' THEN p.forced_early_median_ms
           END AS path_only_strategy_ms
    FROM topnbench_results AS p
    JOIN topnbench_master_results AS m USING (case_name)
    JOIN topnbench_path_only_results AS o USING (case_name)
), classified AS
(
    SELECT paired.*,
           CASE
               WHEN master_choice IS NULL OR patched_choice IS NULL OR
                    master_choice = 'unknown' OR
                    patched_choice = 'unknown' OR
                    master_actual_winner = 'tie' OR
                    patched_actual_winner = 'tie' OR
                    master_actual_winner <> patched_actual_winner
                   THEN 'inconclusive'
               WHEN master_choice = patched_choice AND
                    patched_choice = patched_actual_winner
                   THEN 'unchanged-correct'
               WHEN master_choice = patched_choice
                   THEN 'unchanged-miss'
               WHEN patched_choice = patched_actual_winner
                   THEN 'improvement'
               WHEN master_choice = patched_actual_winner
                   THEN 'regression'
               ELSE 'inconclusive'
           END AS patch_effect,
           CASE
               WHEN path_only_choice IS NULL OR patched_choice IS NULL OR
                    path_only_choice = 'unknown' OR
                    patched_choice = 'unknown' OR
                    path_only_actual_winner = 'tie' OR
                    patched_actual_winner = 'tie' OR
                    path_only_actual_winner <> patched_actual_winner
                   THEN 'inconclusive'
               WHEN path_only_choice = patched_choice AND
                    patched_choice = patched_actual_winner
                   THEN 'unchanged-correct'
               WHEN path_only_choice = patched_choice
                   THEN 'unchanged-miss'
               WHEN patched_choice = patched_actual_winner
                   THEN 'improvement'
               WHEN path_only_choice = patched_actual_winner
                   THEN 'regression'
               ELSE 'inconclusive'
           END AS width_cost_effect
    FROM paired
)
SELECT classified.*,
       master_strategy_ms / NULLIF(patched_strategy_ms, 0) AS
           patch_vs_master_speedup,
       path_only_strategy_ms / NULLIF(patched_strategy_ms, 0) AS
           width_cost_vs_path_only_speedup
FROM classified;

\if :topnbench_verbose
SELECT case_name,
       master_choice,
       path_only_choice,
       patched_choice,
       patched_actual_winner AS actual_winner,
       patch_effect,
       width_cost_effect,
       round(master_strategy_ms::numeric, 3) AS master_strategy_ms,
       round(patched_strategy_ms::numeric, 3) AS patched_strategy_ms,
       round(patch_vs_master_speedup::numeric, 3) AS
           patch_vs_master_speedup
FROM topnbench_choice_comparison
ORDER BY case_name;
\endif

SELECT count(*) FILTER (WHERE master_choice <> patched_choice) AS
           changed_choices,
       count(*) FILTER (WHERE patch_effect = 'improvement') AS improvements,
       count(*) FILTER (WHERE patch_effect = 'improvement' AND
                              patched_choice = 'late') AS changed_to_late_wins,
       count(*) FILTER (WHERE patch_effect = 'improvement' AND
                              patched_choice = 'early') AS changed_to_early_wins,
       count(*) FILTER (WHERE patch_effect = 'regression') AS new_regressions,
       count(*) FILTER (WHERE patch_effect = 'unchanged-miss') AS
           unchanged_misses,
       count(*) FILTER (WHERE patch_effect = 'inconclusive') AS inconclusive,
       count(*) FILTER (WHERE path_only_choice <> patched_choice) AS
           width_cost_changes,
       count(*) FILTER (WHERE width_cost_effect = 'improvement') AS
           width_cost_improvements,
       count(*) FILTER (WHERE width_cost_effect = 'regression') AS
           width_cost_regressions,
       round(max(CASE WHEN patch_effect = 'improvement'
                      THEN patch_vs_master_speedup END)::numeric, 3) AS
           best_new_speedup,
       round(max(CASE WHEN patch_effect = 'regression'
                      THEN 1.0 / patch_vs_master_speedup END)::numeric, 3) AS
           worst_new_regret
FROM topnbench_choice_comparison;

\echo
\echo '== Supplemental case catalog =='

-- Keep the hand-written cases in one catalog.  A phase identifies the
-- session state under which a case must run; category is only for reporting.
DROP TABLE IF EXISTS topnbench_case_definitions;
CREATE TEMP TABLE topnbench_case_definitions
(
    case_order integer PRIMARY KEY,
    phase text NOT NULL,
    category text NOT NULL,
    case_name text NOT NULL UNIQUE,
    auto_query text NOT NULL,
    manual_late_query text NOT NULL,
    forced_early_query text NOT NULL,
    iterations integer NOT NULL,
    work_mem_setting text
);

-- Representative expressions run with the normal parallel settings.
INSERT INTO topnbench_case_definitions VALUES
    (100, 'parallel-expressions', 'real-expressions', 'numeric-example',
     $q$SELECT a,
               a / (a * -1),
               a::numeric AS b,
               abs(a::numeric) / 12345.345632
        FROM topnbench_data ORDER BY a LIMIT 1$q$,
     $q$SELECT s.a,
               s.a / (s.a * -1),
               s.a::numeric AS b,
               abs(s.a::numeric) / 12345.345632
        FROM (SELECT a FROM topnbench_data ORDER BY a LIMIT 1) AS s$q$,
     $q$SELECT a,
               a / (a * -1) AS e2,
               a::numeric AS b,
               abs(a::numeric) / 12345.345632 AS e4
        FROM topnbench_data ORDER BY a, e2, b, e4 LIMIT 1$q$,
     7, NULL),
    (110, 'parallel-expressions', 'real-expressions', 'cheap-builtins',
     $q$SELECT a, a + 1 AS e1, a * 3 AS e2,
               abs(a - 500000) AS e3
        FROM topnbench_data ORDER BY a LIMIT 250000$q$,
     $q$SELECT s.a, s.a + 1 AS e1, s.a * 3 AS e2,
               abs(s.a - 500000) AS e3
        FROM (SELECT a FROM topnbench_data
              ORDER BY a LIMIT 250000) AS s$q$,
     $q$SELECT a, a + 1 AS e1, a * 3 AS e2,
               abs(a - 500000) AS e3
        FROM topnbench_data ORDER BY a, e1, e2, e3 LIMIT 250000$q$,
     7, NULL),
    (120, 'parallel-expressions', 'real-expressions', 'text-producing',
     $q$SELECT a, a::text AS e1, md5(a::text) AS e2
        FROM topnbench_data ORDER BY a LIMIT 10000$q$,
     $q$SELECT s.a, s.a::text AS e1, md5(s.a::text) AS e2
        FROM (SELECT a FROM topnbench_data
              ORDER BY a LIMIT 10000) AS s$q$,
     $q$SELECT a, a::text AS e1, md5(a::text) AS e2
        FROM topnbench_data ORDER BY a, e1, e2 LIMIT 10000$q$,
     7, NULL);

-- Use topnbench_compare()'s declared row type as the result-table schema.
-- WITH NO DATA guarantees that creating the table performs no benchmark run.
DROP TABLE IF EXISTS topnbench_supplemental_results;
CREATE TEMP TABLE topnbench_supplemental_results AS
SELECT 'master'::text AS policy,
       d.case_order,
       d.phase,
       d.category,
       d.case_name,
       c.*
FROM topnbench_case_definitions AS d
CROSS JOIN LATERAL topnbench_compare(
    d.auto_query,
    d.manual_late_query,
    d.forced_early_query,
    d.iterations,
    true,
    d.work_mem_setting) AS c
WITH NO DATA;

\echo
\echo '== Supplemental phase: representative expressions =='

SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
INSERT INTO topnbench_supplemental_results
SELECT 'master', d.case_order, d.phase, d.category, d.case_name, c.*
FROM topnbench_case_definitions AS d
CROSS JOIN LATERAL topnbench_compare(
    d.auto_query, d.manual_late_query, d.forced_early_query,
    d.iterations, true, d.work_mem_setting) AS c
WHERE d.phase = 'parallel-expressions'
ORDER BY d.case_order;

SET enable_cost_based_delayed_projection = on;
INSERT INTO topnbench_supplemental_results
SELECT 'path-only', d.case_order, d.phase, d.category, d.case_name, c.*
FROM topnbench_case_definitions AS d
CROSS JOIN LATERAL topnbench_compare(
    d.auto_query, d.manual_late_query, d.forced_early_query,
    d.iterations, true, d.work_mem_setting) AS c
WHERE d.phase = 'parallel-expressions'
ORDER BY d.case_order;

SET enable_sort_tuple_width_cost = on;
INSERT INTO topnbench_supplemental_results
SELECT 'patched', d.case_order, d.phase, d.category, d.case_name, c.*
FROM topnbench_case_definitions AS d
CROSS JOIN LATERAL topnbench_compare(
    d.auto_query, d.manual_late_query, d.forced_early_query,
    d.iterations, true, d.work_mem_setting) AS c
WHERE d.phase = 'parallel-expressions'
ORDER BY d.case_order;

\echo
\echo '== Supplemental setup: adversarial estimates and Sort behavior =='

-- Robustness tests are serial so row estimates and Sort-space measurements
-- are easier to interpret.  They are targeted cases, not a Cartesian product.
SET max_parallel_workers_per_gather = 0;
SET work_mem = '256MB';

-- Physical input order changes real Sort work without changing planner inputs.
INSERT INTO topnbench_case_definitions
SELECT 200 + q.case_offset,
       'serial-stale',
       'physical-input-order',
       q.case_name,
       format(
           'SELECT %1$I AS k, topnbench_work_cost_1(%1$I, 16, 1) AS e1 '
           'FROM topnbench_data ORDER BY %1$I LIMIT 250000',
           q.key_column),
       format(
           'SELECT s.k, topnbench_work_cost_1(s.k, 16, 1) AS e1 '
           'FROM (SELECT %1$I AS k FROM topnbench_data '
           'ORDER BY %1$I LIMIT 250000) AS s',
           q.key_column),
       format(
           'SELECT %1$I AS k, topnbench_work_cost_1(%1$I, 16, 1) AS e1 '
           'FROM topnbench_data ORDER BY %1$I, e1 LIMIT 250000',
           q.key_column),
       5,
       NULL
FROM (VALUES (1, 'input-ascending', 'a'),
             (2, 'input-descending', 'a_desc'),
             (3, 'input-random', 'a_random'))
     AS q(case_offset, case_name, key_column);

-- Correlated predicates create cardinality errors while preserving the true
-- input cardinality used by the paired manual strategies.
INSERT INTO topnbench_case_definitions VALUES
    (300, 'serial-stale', 'row-estimation', 'rows-underestimated',
     $q$SELECT a_random AS k,
               topnbench_work_cost_1(a_random, 16, 1) AS e1
        FROM topnbench_data
        WHERE a <= 100000 AND same1 <= 100000 AND same2 <= 100000
        ORDER BY a_random LIMIT 10000$q$,
     $q$SELECT s.k, topnbench_work_cost_1(s.k, 16, 1) AS e1
        FROM (SELECT a_random AS k
              FROM topnbench_data
              WHERE a <= 100000 AND same1 <= 100000 AND same2 <= 100000
              ORDER BY a_random LIMIT 10000) AS s$q$,
     $q$SELECT a_random AS k,
               topnbench_work_cost_1(a_random, 16, 1) AS e1
        FROM topnbench_data
        WHERE a <= 100000 AND same1 <= 100000 AND same2 <= 100000
        ORDER BY a_random, e1 LIMIT 10000$q$,
     5, NULL),
    (301, 'serial-stale', 'row-estimation', 'rows-overestimated',
     $q$SELECT a_random AS k,
               topnbench_work_cost_1(a_random, 16, 1) AS e1
        FROM topnbench_data
        WHERE a <= 550000 AND inverse <= 550000
        ORDER BY a_random LIMIT 50000$q$,
     $q$SELECT s.k, topnbench_work_cost_1(s.k, 16, 1) AS e1
        FROM (SELECT a_random AS k
              FROM topnbench_data
              WHERE a <= 550000 AND inverse <= 550000
              ORDER BY a_random LIMIT 50000) AS s$q$,
     $q$SELECT a_random AS k,
               topnbench_work_cost_1(a_random, 16, 1) AS e1
        FROM topnbench_data
        WHERE a <= 550000 AND inverse <= 550000
        ORDER BY a_random, e1 LIMIT 50000$q$,
     5, NULL);

-- Preserve stale width statistics deliberately.  One table grows after
-- ANALYZE and the other shrinks, covering both error directions.
CREATE UNLOGGED TABLE topnbench_width_underestimate
(
    a integer NOT NULL,
    sort_key integer NOT NULL,
    payload text NOT NULL
) WITH (autovacuum_enabled = false);
INSERT INTO topnbench_width_underestimate
SELECT g,
       ((g::bigint * 48271) % 100003)::integer,
       'x'
FROM generate_series(1, 100000) AS g;
ANALYZE topnbench_width_underestimate;
UPDATE topnbench_width_underestimate
SET payload = md5(a::text || ':1') || md5(a::text || ':2') ||
              md5(a::text || ':3') || md5(a::text || ':4') ||
              md5(a::text || ':5') || md5(a::text || ':6') ||
              md5(a::text || ':7') || md5(a::text || ':8');
-- Refresh relpages/reltuples without replacing the stale pg_statistic value.
VACUUM topnbench_width_underestimate;

CREATE UNLOGGED TABLE topnbench_width_overestimate
(
    a integer NOT NULL,
    payload text NOT NULL
) WITH (autovacuum_enabled = false);
INSERT INTO topnbench_width_overestimate
SELECT g,
       md5(g::text || ':1') || md5(g::text || ':2') ||
       md5(g::text || ':3') || md5(g::text || ':4') ||
       md5(g::text || ':5') || md5(g::text || ':6') ||
       md5(g::text || ':7') || md5(g::text || ':8')
FROM generate_series(1, 100000) AS g;
ANALYZE topnbench_width_overestimate;
UPDATE topnbench_width_overestimate SET payload = 'x';
VACUUM topnbench_width_overestimate;

SELECT q.case_name,
       s.avg_width AS statistics_avg_width,
       q.actual_avg_width
FROM (
    SELECT 'width-underestimated' AS case_name,
           avg(pg_column_size(payload))::numeric(10, 2) AS actual_avg_width
    FROM topnbench_width_underestimate
    UNION ALL
    SELECT 'width-overestimated',
           avg(pg_column_size(payload))::numeric(10, 2)
    FROM topnbench_width_overestimate
) AS q
JOIN LATERAL (
    SELECT avg_width
    FROM pg_stats
    WHERE schemaname = current_schema()
      AND tablename = CASE q.case_name
            WHEN 'width-underestimated' THEN 'topnbench_width_underestimate'
            ELSE 'topnbench_width_overestimate'
          END
      AND attname = 'payload'
) AS s ON true;

-- Direct stale-width checks.
INSERT INTO topnbench_case_definitions
SELECT 400 + q.case_offset,
       'serial-stale',
       'width-estimation',
       q.case_name,
       format('SELECT a, length(payload) AS e1 FROM %I '
              'ORDER BY a LIMIT 25000', q.relation_name),
       format('SELECT s.a, length(s.payload) AS e1 '
              'FROM (SELECT a, payload FROM %I '
              'ORDER BY a LIMIT 25000) AS s', q.relation_name),
       format('SELECT a, length(payload) AS e1 FROM %I '
              'ORDER BY a, e1 LIMIT 25000', q.relation_name),
       5,
       NULL
FROM (VALUES (1, 'width-underestimated',
                 'topnbench_width_underestimate'),
             (2, 'width-overestimated',
                 'topnbench_width_overestimate'))
     AS q(case_offset, case_name, relation_name);

-- Early evaluation expands a narrow integer into a wide text value.
INSERT INTO topnbench_case_definitions VALUES
    (450, 'serial-stale', 'tuple-width', 'projection-expands-tuple',
     $q$SELECT a_random AS k, repeat(md5(a_random::text), 8) AS e1
        FROM topnbench_data ORDER BY a_random LIMIT 10000$q$,
     $q$SELECT s.k, repeat(md5(s.k::text), 8) AS e1
        FROM (SELECT a_random AS k FROM topnbench_data
              ORDER BY a_random LIMIT 10000) AS s$q$,
     $q$SELECT a_random AS k, repeat(md5(a_random::text), 8) AS e1
        FROM topnbench_data ORDER BY a_random, e1 LIMIT 10000$q$,
     5, NULL);

-- Sweep work_mem while stale statistics understate the source width.
INSERT INTO topnbench_case_definitions
SELECT 500 + q.case_offset,
       'serial-stale',
       'work-mem-stale-width',
       format('width-shrinks-work-mem-%s', q.work_mem_setting),
       $q$SELECT a, length(payload) AS e1
          FROM topnbench_width_underestimate ORDER BY a LIMIT 5000$q$,
       $q$SELECT s.a, length(s.payload) AS e1
          FROM (SELECT a, payload FROM topnbench_width_underestimate
                ORDER BY a LIMIT 5000) AS s$q$,
       $q$SELECT a, length(payload) AS e1
          FROM topnbench_width_underestimate ORDER BY a, e1 LIMIT 5000$q$,
       5,
       q.work_mem_setting
FROM (VALUES (1, '64kB'), (2, '256kB'), (3, '1MB'), (4, '4MB'),
             (5, '16MB'), (6, '64MB'), (7, '256MB'))
     AS q(case_offset, work_mem_setting);

\echo
\echo '== Supplemental phase: stale statistics and adversarial inputs =='

SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
INSERT INTO topnbench_supplemental_results
SELECT 'master', d.case_order, d.phase, d.category, d.case_name, c.*
FROM topnbench_case_definitions AS d
CROSS JOIN LATERAL topnbench_compare(
    d.auto_query, d.manual_late_query, d.forced_early_query,
    d.iterations, true, d.work_mem_setting) AS c
WHERE d.phase = 'serial-stale'
ORDER BY d.case_order;

SET enable_cost_based_delayed_projection = on;
INSERT INTO topnbench_supplemental_results
SELECT 'path-only', d.case_order, d.phase, d.category, d.case_name, c.*
FROM topnbench_case_definitions AS d
CROSS JOIN LATERAL topnbench_compare(
    d.auto_query, d.manual_late_query, d.forced_early_query,
    d.iterations, true, d.work_mem_setting) AS c
WHERE d.phase = 'serial-stale'
ORDER BY d.case_order;

SET enable_sort_tuple_width_cost = on;
INSERT INTO topnbench_supplemental_results
SELECT 'patched', d.case_order, d.phase, d.category, d.case_name, c.*
FROM topnbench_case_definitions AS d
CROSS JOIN LATERAL topnbench_compare(
    d.auto_query, d.manual_late_query, d.forced_early_query,
    d.iterations, true, d.work_mem_setting) AS c
WHERE d.phase = 'serial-stale'
ORDER BY d.case_order;

-- Repair avg_width and repeat only the work_mem sweep.  This separates a
-- weakness in costing from a decision caused by stale statistics.
ANALYZE topnbench_width_underestimate;
SELECT avg_width AS repaired_statistics_avg_width
FROM pg_stats
WHERE schemaname = current_schema()
  AND tablename = 'topnbench_width_underestimate'
  AND attname = 'payload';

-- Build accurately analyzed relations whose payload width changes while row
-- count, key distribution, expression work, and work_mem remain fixed.  All
-- values stay below the normal TOAST threshold so the measured width is also
-- the number of payload bytes copied into an in-memory Sort tuple.
SELECT format('DROP TABLE IF EXISTS %I',
              format('topnbench_copy_width_%s', width_bytes))
FROM unnest(ARRAY[8, 32, 128, 256, 512, 1024]) AS w(width_bytes)
\gexec

SELECT format(
           'CREATE UNLOGGED TABLE %1$I '
           '(sort_key integer NOT NULL, payload text NOT NULL)',
           format('topnbench_copy_width_%s', width_bytes))
FROM unnest(ARRAY[8, 32, 128, 256, 512, 1024]) AS w(width_bytes)
\gexec

SELECT format(
           'INSERT INTO %1$I '
           'SELECT ((g::bigint * 48271) %% 100003)::integer, '
           'left(repeat(md5(g::text), %2$s), %3$s) '
           'FROM generate_series(1, 100000) AS g',
           format('topnbench_copy_width_%s', width_bytes),
           (width_bytes + 31) / 32,
           width_bytes)
FROM unnest(ARRAY[8, 32, 128, 256, 512, 1024]) AS w(width_bytes)
\gexec

SELECT format('ANALYZE %I',
              format('topnbench_copy_width_%s', width_bytes))
FROM unnest(ARRAY[8, 32, 128, 256, 512, 1024]) AS w(width_bytes)
\gexec

SELECT tablename,
       avg_width
FROM pg_stats
WHERE schemaname = current_schema()
  AND tablename LIKE 'topnbench_copy_width_%'
  AND attname = 'payload'
ORDER BY avg_width;

\echo
\echo '== Pure Sort width calibration =='

-- Unlike the early/late comparisons below, these query pairs contain no
-- computed target expressions.  Their only intended difference is whether
-- payload is carried through Sort, so the measured delta calibrates the new
-- width term without expression-cost or Result-node overhead.
SET enable_cost_based_delayed_projection = on;
SET enable_sort_tuple_width_cost = on;
DROP TABLE IF EXISTS topnbench_sort_calibration_raw;
CREATE TEMP TABLE topnbench_sort_calibration_raw AS
SELECT w.width_bytes,
       l.limit_order,
       l.limit_label,
       l.limit_rows,
       s.shape,
       m.*
FROM (VALUES
          (8, 'topnbench_copy_width_8'),
          (32, 'topnbench_copy_width_32'),
          (128, 'topnbench_copy_width_128'),
          (256, 'topnbench_copy_width_256'),
          (512, 'topnbench_copy_width_512'),
          (1024, 'topnbench_copy_width_1024'))
     AS w(width_bytes, relation_name)
CROSS JOIN (VALUES (1, '1pct', 1000),
                   (2, '25pct', 25000),
                   (3, '50pct', 50000),
                   (4, '100pct', 100000))
     AS l(limit_order, limit_label, limit_rows)
CROSS JOIN (VALUES ('narrow'), ('wide')) AS s(shape)
CROSS JOIN LATERAL topnbench_measure(
    format(
        CASE s.shape
            WHEN 'narrow' THEN
                'SELECT sort_key FROM %1$I ORDER BY sort_key LIMIT %2$s'
            ELSE
                'SELECT sort_key, payload FROM %1$I '
                'ORDER BY sort_key LIMIT %2$s'
        END,
        w.relation_name, l.limit_rows),
    5, '1GB') AS m;

DROP TABLE IF EXISTS topnbench_sort_calibration;
CREATE TEMP TABLE topnbench_sort_calibration AS
SELECT width_bytes,
       limit_order,
       limit_label,
       limit_rows,
       max(estimated_sort_width) FILTER (WHERE shape = 'narrow') AS
           narrow_plan_width,
       max(estimated_sort_width) FILTER (WHERE shape = 'wide') AS
           wide_plan_width,
       max(total_cost) FILTER (WHERE shape = 'narrow') AS narrow_cost,
       max(total_cost) FILTER (WHERE shape = 'wide') AS wide_cost,
       max(median_ms) FILTER (WHERE shape = 'narrow') AS narrow_ms,
       max(median_ms) FILTER (WHERE shape = 'wide') AS wide_ms,
       max(sort_space_used_kb) FILTER (WHERE shape = 'narrow') AS narrow_kb,
       max(sort_space_used_kb) FILTER (WHERE shape = 'wide') AS wide_kb
FROM topnbench_sort_calibration_raw
GROUP BY width_bytes, limit_order, limit_label, limit_rows;

-- Four compact calibration rows are printed by default.  A low correlation
-- or a very early crossover means the constants need more work.
SELECT limit_label,
       min(width_bytes) FILTER
           (WHERE wide_ms > narrow_ms * 1.10) AS first_width_10pct_slower,
       round(max(wide_ms / NULLIF(narrow_ms, 0))::numeric, 3) AS
           worst_wide_time_ratio,
       round(corr(wide_cost - narrow_cost,
                  wide_ms - narrow_ms)::numeric, 3) AS cost_time_correlation
FROM topnbench_sort_calibration
GROUP BY limit_order, limit_label
ORDER BY limit_order;

\if :topnbench_verbose
SELECT width_bytes,
       limit_label,
       narrow_plan_width,
       wide_plan_width,
       round((wide_cost - narrow_cost)::numeric, 3) AS estimated_cost_delta,
       round(narrow_ms::numeric, 3) AS narrow_ms,
       round(wide_ms::numeric, 3) AS wide_ms,
       round((wide_ms - narrow_ms)::numeric, 3) AS actual_ms_delta,
       round((wide_ms / NULLIF(narrow_ms, 0))::numeric, 3) AS time_ratio,
       round(narrow_kb::numeric, 0) AS narrow_kb,
       round(wide_kb::numeric, 0) AS wide_kb
FROM topnbench_sort_calibration
ORDER BY limit_order, width_bytes;
\endif

INSERT INTO topnbench_case_definitions
SELECT 600 + q.case_offset,
       'serial-accurate-width',
       'work-mem-accurate-width',
       format('width-accurate-work-mem-%s', q.work_mem_setting),
       $q$SELECT a, length(payload) AS e1
          FROM topnbench_width_underestimate ORDER BY a LIMIT 5000$q$,
       $q$SELECT s.a, length(s.payload) AS e1
          FROM (SELECT a, payload FROM topnbench_width_underestimate
                ORDER BY a LIMIT 5000) AS s$q$,
       $q$SELECT a, length(payload) AS e1
          FROM topnbench_width_underestimate ORDER BY a, e1 LIMIT 5000$q$,
       5,
       q.work_mem_setting
FROM (VALUES (1, '64kB'), (2, '256kB'), (3, '1MB'), (4, '4MB'),
             (5, '16MB'), (6, '64MB'), (7, '256MB'))
     AS q(case_offset, work_mem_setting);

-- Negative controls for late projection.  In these cases early evaluation
-- can replace a 260-byte payload with a four-byte integer before sorting.
-- The existing COST 1 and COST 100 aliases share one C implementation and
-- receive the same octet_length input with zero work rounds, so this matrix
-- also tests whether an inaccurate procost can make the POC choose late when
-- early is actually faster.  The pseudo-random key avoids a physically
-- ordered input accidentally making Sort unusually cheap.
INSERT INTO topnbench_case_definitions
SELECT 700 + c.case_offset * 100 + l.case_offset * 10 + w.case_offset,
       'serial-accurate-width',
       'early-winner-controls',
       format('early-control-%s-limit-%s-work-mem-%s',
              c.cost_label, l.limit_label, w.work_mem_setting),
       format(
           'SELECT sort_key AS k, '
           '%1$I(octet_length(payload), 0, 0) AS e1 '
           'FROM topnbench_width_underestimate '
           'ORDER BY sort_key LIMIT %2$s',
           c.function_name, l.limit_rows),
       format(
           'SELECT s.k, '
           '%1$I(octet_length(s.payload), 0, 0) AS e1 '
           'FROM (SELECT sort_key AS k, payload '
           'FROM topnbench_width_underestimate '
           'ORDER BY sort_key LIMIT %2$s) AS s',
           c.function_name, l.limit_rows),
       format(
           'SELECT sort_key AS k, '
           '%1$I(octet_length(payload), 0, 0) AS e1 '
           'FROM topnbench_width_underestimate '
           'ORDER BY sort_key, e1 LIMIT %2$s',
           c.function_name, l.limit_rows),
       5,
       w.work_mem_setting
FROM (VALUES (0, 'cost-1', 'topnbench_work_cost_1'),
             (1, 'cost-100', 'topnbench_work_cost_100'))
     AS c(case_offset, cost_label, function_name)
CROSS JOIN (VALUES (1, '25pct', 25000),
                   (2, '50pct', 50000),
                   (3, '75pct', 75000),
                   (4, '100pct', 100000))
           AS l(case_offset, limit_label, limit_rows)
CROSS JOIN (VALUES (1, '64kB'), (2, '4MB'), (3, '256MB'))
           AS w(case_offset, work_mem_setting);

-- Isolate the in-memory tuple-copy component of Sort costing.  The function
-- does no synthetic work and always returns an integer, so increasing the
-- source payload changes the late Sort width without changing the early Sort
-- width.  One gigabyte of work_mem keeps even the 1024-byte case in memory.
-- LIMIT 100% makes both placements execute the expression for every row;
-- smaller LIMITs show where expression savings outweigh tuple width.
INSERT INTO topnbench_case_definitions
SELECT 1000 + w.case_offset * 10 + l.case_offset,
       'serial-accurate-width',
       'tuple-copy-width',
       format('tuple-copy-width-%s-limit-%s',
              w.width_label, l.limit_label),
       format(
           'SELECT sort_key AS k, '
           'topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1 '
           'FROM %1$I ORDER BY sort_key LIMIT %2$s',
           w.relation_name, l.limit_rows),
       format(
           'SELECT s.k, '
           'topnbench_work_cost_1(octet_length(s.payload), 0, 0) AS e1 '
           'FROM (SELECT sort_key AS k, payload FROM %1$I '
           'ORDER BY sort_key LIMIT %2$s) AS s',
           w.relation_name, l.limit_rows),
       format(
           'SELECT sort_key AS k, '
           'topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1 '
           'FROM %1$I ORDER BY sort_key, e1 LIMIT %2$s',
           w.relation_name, l.limit_rows),
       5,
       '1GB'
FROM (VALUES
          (1, '8', 'topnbench_copy_width_8'),
          (2, '32', 'topnbench_copy_width_32'),
          (3, '128', 'topnbench_copy_width_128'),
          (4, '256', 'topnbench_copy_width_256'),
          (5, '512', 'topnbench_copy_width_512'),
          (6, '1024', 'topnbench_copy_width_1024'))
     AS w(case_offset, width_label, relation_name)
CROSS JOIN (VALUES (1, '1pct', 1000),
                   (2, '25pct', 25000),
                   (3, '50pct', 50000),
                   (4, '100pct', 100000))
           AS l(case_offset, limit_label, limit_rows);

\echo
\echo '== Supplemental phase: repaired width and early-winner controls =='

SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
INSERT INTO topnbench_supplemental_results
SELECT 'master', d.case_order, d.phase, d.category, d.case_name, c.*
FROM topnbench_case_definitions AS d
CROSS JOIN LATERAL topnbench_compare(
    d.auto_query, d.manual_late_query, d.forced_early_query,
    d.iterations, true, d.work_mem_setting) AS c
WHERE d.phase = 'serial-accurate-width'
ORDER BY d.case_order;

SET enable_cost_based_delayed_projection = on;
INSERT INTO topnbench_supplemental_results
SELECT 'path-only', d.case_order, d.phase, d.category, d.case_name, c.*
FROM topnbench_case_definitions AS d
CROSS JOIN LATERAL topnbench_compare(
    d.auto_query, d.manual_late_query, d.forced_early_query,
    d.iterations, true, d.work_mem_setting) AS c
WHERE d.phase = 'serial-accurate-width'
ORDER BY d.case_order;

SET enable_sort_tuple_width_cost = on;
INSERT INTO topnbench_supplemental_results
SELECT 'patched', d.case_order, d.phase, d.category, d.case_name, c.*
FROM topnbench_case_definitions AS d
CROSS JOIN LATERAL topnbench_compare(
    d.auto_query, d.manual_late_query, d.forced_early_query,
    d.iterations, true, d.work_mem_setting) AS c
WHERE d.phase = 'serial-accurate-width'
ORDER BY d.case_order;

RESET max_parallel_workers_per_gather;
RESET work_mem;
RESET enable_cost_based_delayed_projection;
RESET enable_sort_tuple_width_cost;

\echo
\echo '== Supplemental policy comparison =='

DROP TABLE IF EXISTS topnbench_supplemental_comparison;
CREATE TEMP TABLE topnbench_supplemental_comparison AS
-- As in the quick matrix, all policy runs establish decision and winner
-- stability.  The strategy-to-strategy speedup uses only the POC run's late
-- and early timings so cache or frequency drift between runs cannot bias it.
WITH paired AS
(
    SELECT p.case_order,
           p.phase,
           p.category,
           p.case_name,
           m.planner_choice AS master_choice,
           o.planner_choice AS path_only_choice,
           p.planner_choice AS patched_choice,
           m.actual_winner AS master_actual_winner,
           o.actual_winner AS path_only_actual_winner,
           p.actual_winner AS patched_actual_winner,
           m.decision_class AS master_decision_class,
           p.decision_class AS patched_decision_class,
           CASE m.planner_choice
               WHEN 'late' THEN p.manual_late_median_ms
               WHEN 'early' THEN p.forced_early_median_ms
           END AS master_strategy_ms,
           CASE p.planner_choice
               WHEN 'late' THEN p.manual_late_median_ms
               WHEN 'early' THEN p.forced_early_median_ms
           END AS patched_strategy_ms,
           CASE o.planner_choice
               WHEN 'late' THEN p.manual_late_median_ms
               WHEN 'early' THEN p.forced_early_median_ms
           END AS path_only_strategy_ms
    FROM topnbench_supplemental_results AS p
    JOIN topnbench_supplemental_results AS m
      ON m.case_name = p.case_name
     AND m.policy = 'master'
    JOIN topnbench_supplemental_results AS o
      ON o.case_name = p.case_name
     AND o.policy = 'path-only'
    WHERE p.policy = 'patched'
), classified AS
(
    SELECT paired.*,
           CASE
               WHEN master_choice IS NULL OR patched_choice IS NULL OR
                    master_choice = 'unknown' OR
                    patched_choice = 'unknown' OR
                    master_actual_winner = 'tie' OR
                    patched_actual_winner = 'tie' OR
                    master_actual_winner <> patched_actual_winner
                   THEN 'inconclusive'
               WHEN master_choice = patched_choice AND
                    patched_choice = patched_actual_winner
                   THEN 'unchanged-correct'
               WHEN master_choice = patched_choice
                   THEN 'unchanged-miss'
               WHEN patched_choice = patched_actual_winner
                   THEN 'improvement'
               WHEN master_choice = patched_actual_winner
                   THEN 'regression'
               ELSE 'inconclusive'
           END AS patch_effect,
           CASE
               WHEN path_only_choice IS NULL OR patched_choice IS NULL OR
                    path_only_choice = 'unknown' OR
                    patched_choice = 'unknown' OR
                    path_only_actual_winner = 'tie' OR
                    patched_actual_winner = 'tie' OR
                    path_only_actual_winner <> patched_actual_winner
                   THEN 'inconclusive'
               WHEN path_only_choice = patched_choice AND
                    patched_choice = patched_actual_winner
                   THEN 'unchanged-correct'
               WHEN path_only_choice = patched_choice
                   THEN 'unchanged-miss'
               WHEN patched_choice = patched_actual_winner
                   THEN 'improvement'
               WHEN path_only_choice = patched_actual_winner
                   THEN 'regression'
               ELSE 'inconclusive'
           END AS width_cost_effect
    FROM paired
)
SELECT classified.*,
       master_strategy_ms / NULLIF(patched_strategy_ms, 0) AS
           patch_vs_master_speedup,
       path_only_strategy_ms / NULLIF(patched_strategy_ms, 0) AS
           width_cost_vs_path_only_speedup
FROM classified;

-- Compact per-case result: one row describes all three planner policies.
\if :topnbench_verbose
SELECT category,
       case_name,
       master_choice,
       path_only_choice,
       patched_choice,
       patched_actual_winner AS actual_winner,
       patch_effect,
       width_cost_effect,
       round(master_strategy_ms::numeric, 3) AS master_strategy_ms,
       round(patched_strategy_ms::numeric, 3) AS patched_strategy_ms,
       round(patch_vs_master_speedup::numeric, 3) AS
           patch_vs_master_speedup
FROM topnbench_supplemental_comparison
ORDER BY case_order;
\endif

-- Summarize each test category and the complete supplemental suite.
SELECT CASE WHEN GROUPING(category) = 1 THEN 'ALL' ELSE category END AS category,
       count(*) AS cases,
       count(*) FILTER (WHERE patched_actual_winner = 'late') AS late_wins,
       count(*) FILTER (WHERE patched_actual_winner = 'early') AS early_wins,
       count(*) FILTER (WHERE patched_actual_winner = 'tie') AS ties,
       count(*) FILTER (WHERE master_choice <> patched_choice) AS
           changed_choices,
       count(*) FILTER (WHERE patch_effect = 'improvement') AS improvements,
       count(*) FILTER (WHERE patch_effect = 'regression') AS new_regressions,
       count(*) FILTER (WHERE patch_effect = 'unchanged-miss') AS
           unchanged_misses,
       count(*) FILTER (WHERE patch_effect = 'inconclusive') AS inconclusive,
       count(*) FILTER (WHERE path_only_choice <> patched_choice) AS
           width_cost_changes,
       count(*) FILTER (WHERE width_cost_effect = 'improvement') AS
           width_cost_improvements,
       count(*) FILTER (WHERE width_cost_effect = 'regression') AS
           width_cost_regressions,
       round(max(CASE WHEN patch_effect = 'improvement'
                      THEN patch_vs_master_speedup END)::numeric, 3) AS
           best_new_speedup,
       round(max(CASE WHEN patch_effect = 'regression'
                      THEN 1.0 / patch_vs_master_speedup END)::numeric, 3) AS
           worst_new_regret
FROM topnbench_supplemental_comparison
GROUP BY GROUPING SETS ((category), ())
ORDER BY GROUPING(category), category;

\echo
\echo '== Combined quick and supplemental summary =='

WITH all_comparisons AS
(
    SELECT 'quick'::text AS suite,
           master_choice,
           path_only_choice,
           patched_choice,
           patched_actual_winner AS actual_winner,
           patch_effect,
           width_cost_effect,
           patch_vs_master_speedup,
           width_cost_vs_path_only_speedup
    FROM topnbench_choice_comparison
    UNION ALL
    SELECT 'supplemental',
           master_choice,
           path_only_choice,
           patched_choice,
           patched_actual_winner,
           patch_effect,
           width_cost_effect,
           patch_vs_master_speedup,
           width_cost_vs_path_only_speedup
    FROM topnbench_supplemental_comparison
)
SELECT CASE WHEN GROUPING(suite) = 1 THEN 'ALL' ELSE suite END AS suite,
       count(*) AS cases,
       count(*) FILTER (WHERE actual_winner = 'late') AS late_wins,
       count(*) FILTER (WHERE actual_winner = 'early') AS early_wins,
       count(*) FILTER (WHERE actual_winner = 'tie') AS ties,
       count(*) FILTER (WHERE master_choice <> patched_choice) AS
           changed_choices,
       count(*) FILTER (WHERE patch_effect = 'improvement') AS improvements,
       count(*) FILTER (WHERE patch_effect = 'regression') AS new_regressions,
       count(*) FILTER (WHERE patch_effect = 'unchanged-miss') AS
           unchanged_misses,
       count(*) FILTER (WHERE patch_effect = 'inconclusive') AS inconclusive,
       count(*) FILTER (WHERE path_only_choice <> patched_choice) AS
           width_cost_changes,
       count(*) FILTER (WHERE width_cost_effect = 'improvement') AS
           width_cost_improvements,
       count(*) FILTER (WHERE width_cost_effect = 'regression') AS
           width_cost_regressions,
       round(max(CASE WHEN patch_effect = 'improvement'
                      THEN patch_vs_master_speedup END)::numeric, 3) AS
           best_new_speedup,
       round(max(CASE WHEN patch_effect = 'regression'
                      THEN 1.0 / patch_vs_master_speedup END)::numeric, 3) AS
           worst_new_regret
FROM all_comparisons
GROUP BY GROUPING SETS ((suite), ())
ORDER BY GROUPING(suite), suite;

\echo
\echo '== Actionable wrong choices and new regressions =='

WITH actionable AS
(
    SELECT 'quick'::text AS suite,
           'generated'::text AS category,
           c.case_name,
           c.path_only_choice,
           c.patched_choice,
           c.patched_actual_winner AS actual_winner,
           c.patch_effect,
           c.width_cost_effect,
           p.choice_regression_ratio AS regret
    FROM topnbench_choice_comparison AS c
    JOIN topnbench_results AS p USING (case_name)
    UNION ALL
    SELECT 'supplemental',
           c.category,
           c.case_name,
           c.path_only_choice,
           c.patched_choice,
           c.patched_actual_winner,
           c.patch_effect,
           c.width_cost_effect,
           p.choice_regression_ratio
    FROM topnbench_supplemental_comparison AS c
    JOIN topnbench_supplemental_results AS p
      ON p.case_name = c.case_name
     AND p.policy = 'patched'
)
SELECT suite,
       category,
       case_name,
       path_only_choice,
       patched_choice,
       actual_winner,
       patch_effect,
       width_cost_effect,
       round(regret::numeric, 3) AS regret
FROM actionable
WHERE patch_effect = 'regression'
   OR width_cost_effect = 'regression'
   OR regret >= 1.20
ORDER BY suite, category, case_name;

\if :topnbench_verbose
\echo
\echo '== Candidate path costs for unresolved decisions =='

-- These are the surviving early/late Paths from the POC's own
-- UPPERREL_ORDERED pathlist, not estimates obtained from rewritten SQL.
WITH candidate_diagnostics AS
(
    SELECT 'quick'::text AS suite,
           'generated'::text AS category,
           c.case_name,
           c.patched_choice AS planner_choice,
           c.patched_actual_winner AS actual_winner,
           c.patch_effect,
           p.lower_limit_cost_choice,
           p.costs_within_1pct,
           p.early_startup_cost,
           p.early_total_cost,
           p.early_limit_cost,
           p.early_sort_rows,
           p.early_sort_width,
           p.late_startup_cost,
           p.late_total_cost,
           p.late_limit_cost,
           p.late_sort_rows,
           p.late_sort_width,
           p.estimated_late_vs_early_cost
    FROM topnbench_choice_comparison AS c
    JOIN topnbench_results AS p USING (case_name)
    UNION ALL
    SELECT 'supplemental',
           c.category,
           c.case_name,
           c.patched_choice,
           c.patched_actual_winner,
           c.patch_effect,
           p.lower_limit_cost_choice,
           p.costs_within_1pct,
           p.early_startup_cost,
           p.early_total_cost,
           p.early_limit_cost,
           p.early_sort_rows,
           p.early_sort_width,
           p.late_startup_cost,
           p.late_total_cost,
           p.late_limit_cost,
           p.late_sort_rows,
           p.late_sort_width,
           p.estimated_late_vs_early_cost
    FROM topnbench_supplemental_comparison AS c
    JOIN topnbench_supplemental_results AS p
      ON p.case_name = c.case_name
     AND p.policy = 'patched'
)
SELECT suite,
       category,
       case_name,
       planner_choice,
       lower_limit_cost_choice,
       costs_within_1pct,
       actual_winner,
       patch_effect,
       round(early_startup_cost::numeric, 3) AS early_startup,
       round(early_total_cost::numeric, 3) AS early_total,
       round(early_limit_cost::numeric, 3) AS early_to_limit,
       round(early_sort_rows::numeric, 0) AS early_sort_rows,
       early_sort_width,
       round(late_startup_cost::numeric, 3) AS late_startup,
       round(late_total_cost::numeric, 3) AS late_total,
       round(late_limit_cost::numeric, 3) AS late_to_limit,
       round(late_sort_rows::numeric, 0) AS late_sort_rows,
       late_sort_width,
       round(estimated_late_vs_early_cost::numeric, 4) AS
           estimated_late_vs_early
FROM candidate_diagnostics
WHERE patch_effect IN ('regression', 'unchanged-miss', 'inconclusive')
ORDER BY suite, category, case_name;

\echo
\echo '== Supplemental misses, regressions, and inconclusive cases =='

-- Print wider diagnostics only for cases that still need investigation.
SELECT c.category,
       c.case_name,
       c.master_choice,
       c.patched_choice,
       c.patched_actual_winner AS actual_winner,
       c.patch_effect,
       round(p.row_estimation_ratio::numeric, 3) AS row_estimation_ratio,
       p.estimated_sort_width,
       p.sort_method,
       p.sort_space_type,
       round(p.sort_space_used_kb::numeric, 0) AS sort_kb,
       round(p.manual_late_median_ms::numeric, 3) AS late_ms,
       round(p.forced_early_median_ms::numeric, 3) AS early_ms,
       round(p.choice_regression_ratio::numeric, 3) AS choice_regret,
       p.manual_late_sort_method AS late_sort_method,
       round(p.manual_late_sort_space_used_kb::numeric, 0) AS late_sort_kb,
       p.forced_early_sort_method AS early_sort_method,
       round(p.forced_early_sort_space_used_kb::numeric, 0) AS early_sort_kb
FROM topnbench_supplemental_comparison AS c
JOIN topnbench_supplemental_results AS p
  ON p.case_name = c.case_name
 AND p.policy = 'patched'
WHERE c.patch_effect IN ('regression', 'unchanged-miss', 'inconclusive')
ORDER BY c.case_order;

-- Projection signatures are noisy, so show them only when classification
-- failed instead of widening every result row.
SELECT c.category,
       c.case_name,
       p.auto_sort_output,
       p.manual_late_sort_output,
       p.forced_early_sort_output
FROM topnbench_supplemental_comparison AS c
JOIN topnbench_supplemental_results AS p
  ON p.case_name = c.case_name
 AND p.policy = 'patched'
WHERE c.master_choice = 'unknown' OR c.patched_choice = 'unknown'
ORDER BY c.case_order;
\endif
