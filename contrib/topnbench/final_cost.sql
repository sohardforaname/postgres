\echo
\echo '== Complete-result candidate comparison: 0011 versus 0012 =='

-- Run after benchmark.sql setup.  Reuse its 128/256-byte relations and add
-- only the widths needed to bracket the observed FINAL pruning boundary.
DO $$
DECLARE
    w integer;
    t text;
BEGIN
    FOREACH w IN ARRAY ARRAY[96, 160, 192] LOOP
        t := format('topnbench_copy_width_%s', w);
        EXECUTE format('DROP TABLE IF EXISTS %I', t);
        EXECUTE format('CREATE UNLOGGED TABLE %I '
                       '(sort_key integer NOT NULL, payload text NOT NULL)', t);
        EXECUTE format('INSERT INTO %I SELECT '
                       '((g::bigint * 48271) %% 100003)::integer, '
                       'left(repeat(md5(g::text), %s), %s) '
                       'FROM generate_series(1, 100000) g', t, (w + 31) / 32, w);
        EXECUTE format('ANALYZE %I', t);
    END LOOP;
END $$;

DROP TABLE IF EXISTS topnbench_final_cases;
CREATE TEMP TABLE topnbench_final_cases AS
WITH cases(case_no, case_name, width_bytes, limit_rows, offset_rows,
           workers, rounds) AS (
    VALUES
    (1,  'width-96-limit-25pct',  96, 25000, 0, 0, 0),
    (2,  'width-128-limit-25pct', 128, 25000, 0, 0, 0),
    (3,  'width-160-limit-25pct', 160, 25000, 0, 0, 0),
    (4,  'width-192-limit-25pct', 192, 25000, 0, 0, 0),
    (5,  'width-256-limit-25pct', 256, 25000, 0, 0, 0),
    (6,  'width-128-limit-20pct', 128, 20000, 0, 0, 0),
    (7,  'width-128-limit-30pct', 128, 30000, 0, 0, 0),
    (8,  'offset-half-of-25pct',  128, 12500, 12500, 0, 0),
    (9,  'offset-most-of-25pct',  128, 1000, 24000, 0, 0),
    (10, 'expensive-limit-1pct',  256, 1000, 0, 0, 128),
    (11, 'parallel-width-128',   128, 25000, 0, 2, 0),
    (12, 'parallel-width-256',   256, 25000, 0, 2, 0)
), expressions AS (
    SELECT *, format('topnbench_copy_width_%s', width_bytes) AS relname,
           format('topnbench_work_cost_1(octet_length(payload), %s, 0)',
                  rounds) AS expr
    FROM cases
)
SELECT case_no, case_name, width_bytes, limit_rows, offset_rows, workers,
       format('SELECT sort_key AS k, %s AS e1 FROM %I '
              'ORDER BY sort_key LIMIT %s OFFSET %s',
              expr, relname, limit_rows, offset_rows) AS auto_query,
       -- Keep projection below the *outer* OFFSET, so this control evaluates
       -- offset+limit expressions, like the natural post-Sort projection.
       -- It is deliberately not the after-OFFSET subquery rewrite.
       format('SELECT s.k, %s AS e1 FROM '
              '(SELECT sort_key AS k, payload FROM %I '
              'ORDER BY sort_key LIMIT %s) s '
              'ORDER BY s.k LIMIT %s OFFSET %s',
              expr, relname, offset_rows + limit_rows,
              limit_rows, offset_rows) AS manual_late_query,
       format('SELECT sort_key AS k, %s AS e1 FROM %I '
              'ORDER BY sort_key, e1 LIMIT %s OFFSET %s',
              expr, relname, limit_rows, offset_rows) AS forced_early_query
FROM expressions;

ALTER TABLE topnbench_final_cases ADD COLUMN work_mem_setting text DEFAULT '64MB';

-- Reuse the quick matrix's recorded case parameters instead of maintaining a
-- second copy of its COST/work/target-count definitions.  These four cases
-- lost a late choice after 0012; measure both policies on the same statements.
INSERT INTO topnbench_final_cases
WITH expressions AS (
    SELECT r.*, x.targets, x.late_targets, x.sort_keys
    FROM topnbench_results r
    CROSS JOIN LATERAL (
        SELECT string_agg(format('topnbench_work_cost_%s(a_random, %s, %s) AS e%s',
                                 r.declared_cost, r.work_rounds, i, i), ', ' ORDER BY i) AS targets,
               string_agg(format('topnbench_work_cost_%s(s.k, %s, %s) AS e%s',
                                 r.declared_cost, r.work_rounds, i, i), ', ' ORDER BY i) AS late_targets,
               string_agg(format('e%s', i), ', ' ORDER BY i) AS sort_keys
        FROM generate_series(1, r.target_count) i
    ) x
    WHERE r.case_name IN ('cost-1-work-1', 'cost-1-work-16',
                         'cost-1-work-64', 'limit-90pct')
)
SELECT 12 + row_number() OVER (ORDER BY case_name), case_name, NULL::integer,
       limit_rows, offset_rows, requested_workers,
       format('SELECT a_random AS k, %s FROM topnbench_data '
              'ORDER BY a_random LIMIT %s', targets, limit_rows),
       format('SELECT s.k, %s FROM (SELECT a_random AS k FROM topnbench_data '
              'ORDER BY a_random LIMIT %s) AS s LIMIT %s',
              late_targets, sort_rows, limit_rows),
       format('SELECT a_random AS k, %s FROM topnbench_data '
              'ORDER BY a_random, %s LIMIT %s', targets, sort_keys, limit_rows),
       :'topnbench_quick_work_mem'
FROM expressions;

DROP TABLE IF EXISTS topnbench_final_runs;
CREATE TEMP TABLE topnbench_final_runs AS
SELECT 0::integer AS case_no, ''::text AS case_name, 0::integer AS batch,
       ''::text AS policy, c.*
FROM topnbench_compare('SELECT 1', 'SELECT 1', 'SELECT 1',
                      1, false, '64MB', true) c
WITH NO DATA;

DROP TABLE IF EXISTS topnbench_final_plans;
CREATE TEMP TABLE topnbench_final_plans
    (case_name text, policy text, plan jsonb, PRIMARY KEY (case_name, policy));

-- SET LOCAL settings expire with this DO statement's transaction.  No trace
-- logging in timed runs.  Both policies retain the same width-cost formula.
DO $$
DECLARE
    c record;
    b integer;
    p text;
    saved_plan jsonb;
    saved_messages text := current_setting('client_min_messages');
BEGIN
    PERFORM set_config('enable_cost_based_delayed_projection', 'on', true);
    PERFORM set_config('enable_sort_tuple_width_cost', 'on', true);
    PERFORM set_config('debug_print_projection_paths', 'off', true);
    PERFORM set_config('jit', 'off', true);
    PERFORM set_config('min_parallel_table_scan_size', '0', true);
    PERFORM set_config('parallel_setup_cost', '0', true);
    PERFORM set_config('parallel_tuple_cost', '0', true);
    FOR c IN SELECT * FROM topnbench_final_cases ORDER BY case_no LOOP
        PERFORM set_config('max_parallel_workers_per_gather', c.workers::text, true);
        FOR b IN 1..4 LOOP
            FOREACH p IN ARRAY CASE WHEN b % 2 = 1
                THEN ARRAY['0011', '0012'] ELSE ARRAY['0012', '0011'] END
            LOOP
                PERFORM set_config('enable_projection_total_cost',
                                   CASE p WHEN '0012' THEN 'on' ELSE 'off' END, true);
                INSERT INTO topnbench_final_runs
                SELECT c.case_no, c.case_name, b, p, r.*
                FROM topnbench_compare(c.auto_query, c.manual_late_query,
                                       c.forced_early_query, 3, b = 1,
                                       c.work_mem_setting) r;
            END LOOP;
        END LOOP;
    END LOOP;

    -- Trace the four benefit-loss cases only after ALL timing is finished.
    -- ORDERED components show inclusive costs and projection target costs;
    -- the existing FINAL trace then shows LIMIT adjustment and elimination.
    FOR c IN SELECT * FROM topnbench_final_cases WHERE case_no > 12 ORDER BY case_no LOOP
        PERFORM set_config('work_mem', c.work_mem_setting, true);
        PERFORM set_config('max_parallel_workers_per_gather', c.workers::text, true);
        FOREACH p IN ARRAY ARRAY['0011', '0012'] LOOP
            PERFORM set_config('enable_projection_total_cost',
                               CASE p WHEN '0012' THEN 'on' ELSE 'off' END, true);
            RAISE NOTICE 'topn-trace BEGIN case=% policy=%', c.case_name, p;
            PERFORM set_config('client_min_messages', 'debug1', true);
            PERFORM set_config('debug_print_projection_paths', 'on', true);
            EXECUTE 'EXPLAIN (VERBOSE, COSTS ON, FORMAT JSON) ' || c.auto_query INTO saved_plan;
            PERFORM set_config('debug_print_projection_paths', 'off', true);
            PERFORM set_config('client_min_messages', saved_messages, true);
            RAISE NOTICE 'topn-trace END case=% policy=%', c.case_name, p;
            INSERT INTO topnbench_final_plans VALUES (c.case_name, p, saved_plan);
        END LOOP;
    END LOOP;
END $$;

-- These are paired *natural query* times, not estimated times inferred from
-- the early/late controls.  Four batches diagnose repeatability, not statistical
-- significance.  The controls still show whether either policy missed a winner.
WITH pairs AS (
    SELECT o.case_no, o.case_name, o.batch,
           o.planner_choice AS old_choice, n.planner_choice AS new_choice,
           o.auto_median_ms AS old_ms, n.auto_median_ms AS new_ms,
           n.auto_median_ms / nullif(o.auto_median_ms, 0) AS ratio,
           n.manual_late_median_ms AS late_ms,
           n.forced_early_median_ms AS early_ms,
           o.launched_workers AS old_workers, n.launched_workers AS new_workers
    FROM topnbench_final_runs o JOIN topnbench_final_runs n
      USING (case_no, case_name, batch)
    WHERE o.policy = '0011' AND n.policy = '0012'
)
SELECT case_name, string_agg(DISTINCT old_choice, '/') AS choice_0011,
       string_agg(DISTINCT new_choice, '/') AS choice_0012,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY old_ms)::numeric, 3) AS ms_0011,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY new_ms)::numeric, 3) AS ms_0012,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY ratio)::numeric, 3) AS new_vs_old,
       count(*) FILTER (WHERE ratio > 1.05) AS slower_batches,
       count(*) FILTER (WHERE ratio < 0.95) AS faster_batches,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY late_ms)::numeric, 3) AS late_ms,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY early_ms)::numeric, 3) AS early_ms,
       min(old_workers) AS min_workers_0011, min(new_workers) AS min_workers_0012
FROM pairs GROUP BY case_no, case_name ORDER BY case_no;

\echo '== Benefit-loss cases: paired natural-query times (>1 means 0012 is slower) =='
SELECT o.case_name, o.batch, o.planner_choice AS choice_0011,
       n.planner_choice AS choice_0012,
       round(o.auto_median_ms::numeric, 3) AS ms_0011,
       round(n.auto_median_ms::numeric, 3) AS ms_0012,
       round((n.auto_median_ms / nullif(o.auto_median_ms, 0))::numeric, 3) AS new_vs_old
FROM topnbench_final_runs o JOIN topnbench_final_runs n USING (case_no, case_name, batch)
WHERE o.case_no > 12 AND o.policy = '0011' AND n.policy = '0012'
ORDER BY o.case_no, o.batch;

\echo '== Benefit-loss cases: ORDERED candidate costs and selected final cost =='
-- Candidate estimates belong to batch 1; the selected final cost comes from
-- the untimed EXPLAIN.  The trace is authoritative for each actual tournament.
SELECT r.case_name, r.policy, r.planner_choice, r.lower_limit_cost_choice,
       round(r.early_startup_cost::numeric, 3) AS early_startup,
       round(r.early_total_cost::numeric, 3) AS early_total,
       round(r.early_limit_cost::numeric, 3) AS early_to_limit,
       r.early_sort_width,
       round(r.late_startup_cost::numeric, 3) AS late_startup,
       round(r.late_total_cost::numeric, 3) AS late_total,
       round(r.late_limit_cost::numeric, 3) AS late_to_limit,
       r.late_sort_width,
       p.plan->0->'Plan'->>'Total Cost' AS selected_total
FROM topnbench_final_runs r JOIN topnbench_final_plans p USING (case_name, policy)
WHERE r.batch = 1 ORDER BY r.case_no, r.policy;

SELECT case_name, work_mem_setting, auto_query, manual_late_query, forced_early_query
FROM topnbench_final_cases WHERE case_no > 12 ORDER BY case_no;

\echo '== Scope guards: plan must stay unchanged =='

DROP TABLE IF EXISTS topnbench_final_guards;
CREATE TEMP TABLE topnbench_final_guards(case_name text, unchanged boolean);
DO $$
DECLARE
    q text := 'SELECT sort_key AS k, '
              'topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1 '
              'FROM topnbench_copy_width_128 ORDER BY sort_key';
    c record;
    old_plan jsonb;
    new_plan jsonb;
BEGIN
    PERFORM set_config('enable_cost_based_delayed_projection', 'on', true);
    PERFORM set_config('enable_sort_tuple_width_cost', 'on', true);
    PERFORM set_config('debug_print_projection_paths', 'off', true);
    PERFORM set_config('max_parallel_workers_per_gather', '0', true);
    PERFORM set_config('work_mem', '64MB', true);
    FOR c IN
        SELECT * FROM (VALUES
            ('cursor-1pct', '0.01', 'DECLARE topnbench_guard NO SCROLL CURSOR FOR ' || q || ' LIMIT 25000'),
            ('cursor-10pct', '0.1', 'DECLARE topnbench_guard NO SCROLL CURSOR FOR ' || q || ' LIMIT 25000'),
            ('subquery', '0.1', 'SELECT * FROM (' || q || ' LIMIT 25000) s'),
            ('with-ties', '0.1', q || ' FETCH FIRST 25000 ROWS WITH TIES'),
            ('limit-zero', '0.1', q || ' LIMIT 0'),
            ('limit-all', '0.1', q || ' LIMIT ALL'),
            ('volatile', '0.1', 'SELECT sort_key, random() FROM topnbench_copy_width_128 ORDER BY sort_key LIMIT 25000'),
            ('srf', '0.1', 'SELECT sort_key, generate_series(1,2) FROM topnbench_copy_width_128 ORDER BY sort_key LIMIT 25000')
        ) v(case_name, cursor_fraction, query)
    LOOP
        PERFORM set_config('cursor_tuple_fraction', c.cursor_fraction, true);
        PERFORM set_config('enable_projection_total_cost', 'off', true);
        EXECUTE 'EXPLAIN (FORMAT JSON, VERBOSE) ' || c.query INTO old_plan;
        PERFORM set_config('enable_projection_total_cost', 'on', true);
        EXECUTE 'EXPLAIN (FORMAT JSON, VERBOSE) ' || c.query INTO new_plan;
        INSERT INTO topnbench_final_guards VALUES (c.case_name, old_plan = new_plan);
        IF old_plan IS DISTINCT FROM new_plan THEN
            RAISE EXCEPTION 'complete-result policy changed excluded case %', c.case_name;
        END IF;
    END LOOP;
END $$;
SELECT * FROM topnbench_final_guards ORDER BY case_name;
