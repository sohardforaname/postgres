-- 0009: apply incrementally on the complete 0008 tree, even if commits are squashed.
-- Removes the private estimate cache, cache GUC, and PlannerInfo cache field.
-- Keeps bounded stack arrays and duplicate-column validation reduction.
-- Rebuild, install, and restart the patched server before running this file.
-- Remove any explicit enable_union_all_join_estimates_cache configuration.
-- Single entry point, from the repository root:
--   psql -X -v ON_ERROR_STOP=1 -d YOUR_TEST_DB -f union_all_join_test.sql > union-all-0009.log 2>&1
-- Temporary objects only; one transaction, rolled back at the end.
-- Existing correctness/costing/boundary checks are retained.
-- New execution comparison: 50,000 and 250,000 rows per arm; eleven cases per size.
-- Exact bag equality and analytic row-count assertions precede measured runs.
-- Two warmups and eight measurements per mode/case, alternating order.
-- Fresh EXECUTE plans, serial execution, all join methods enabled for new cases.
-- Timings include EXPLAIN ANALYZE instrumentation, not client transfer time.
-- Temp tables and warmed data do not model production shared-buffer/cold-I/O behavior.
-- Timing flags identify candidates for review; they do not prove an optimal plan.
-- A PASS covers assertions, not absence of performance regressions or crashes.
-- The authoring assistant has not compiled or executed this revision.
\set ON_ERROR_STOP 1
\pset pager off
\echo === UNION ALL test: start ===
BEGIN;
SET LOCAL enable_union_all_join_estimates = on;
SET LOCAL max_parallel_workers_per_gather = 0;
SET LOCAL jit = off;
SET LOCAL default_statistics_target = 1000;
SET LOCAL join_collapse_limit = 1;

CREATE TEMP TABLE ua_a AS
SELECT i AS id, i % 2 + 1 AS k, i % 2 + 1 AS j, i <= 100 AS keep
FROM generate_series(1, 200) AS g(i);
CREATE TEMP TABLE ua_b AS
SELECT i AS id, 3 AS k, 3 AS j, i <= 150 AS keep
FROM generate_series(1, 300) AS g(i);
CREATE TEMP TABLE ua_d AS
SELECT CASE WHEN i <= 40 THEN 1 ELSE 2 END AS k,
       CASE WHEN i <= 40 THEN 1 ELSE 2 END AS j
FROM generate_series(1, 50) AS g(i);
CREATE TEMP TABLE ua_empty (LIKE ua_a);
ANALYZE ua_a;
ANALYZE ua_b;
ANALYZE ua_d;
ANALYZE ua_empty;

CREATE TEMP VIEW ua_v AS
SELECT k, j, keep FROM ua_a
UNION ALL
SELECT k, j, keep FROM ua_b;

CREATE FUNCTION pg_temp.ua_estimate(query text) RETURNS numeric
LANGUAGE plpgsql AS $func$
DECLARE
    plan json;
BEGIN
    EXECUTE 'EXPLAIN (FORMAT JSON) ' || query INTO plan;
    RETURN (plan->0->'Plan'->>'Plan Rows')::numeric;
END
$func$;

CREATE FUNCTION pg_temp.ua_assert_sum(label text, query text,
                                     arm_a text, arm_b text) RETURNS void
LANGUAGE plpgsql AS $func$
DECLARE
    combined numeric := pg_temp.ua_estimate(query);
    separate numeric := pg_temp.ua_estimate(arm_a) + pg_temp.ua_estimate(arm_b);
BEGIN
    -- Each separately planned arm is rounded and clamped to at least one
    -- row.  The patched estimate is rounded only after adding contributions.
    IF abs(combined - separate) > 2 THEN
        RAISE EXCEPTION '%: combined %, sum of arms %', label, combined, separate;
    END IF;
    RAISE NOTICE '%: combined %, sum of arms %', label, combined, separate;
END
$func$;

SELECT pg_temp.ua_assert_sum('different child MCVs',
    'SELECT u.k FROM ua_v u JOIN ua_d d ON u.k = d.k',
    'SELECT a.k FROM ua_a a JOIN ua_d d ON a.k = d.k',
    'SELECT b.k FROM ua_b b JOIN ua_d d ON b.k = d.k');

SELECT pg_temp.ua_assert_sum('reversed inputs and operands',
    'SELECT u.k FROM ua_d d JOIN ua_v u ON d.k = u.k',
    'SELECT a.k FROM ua_d d JOIN ua_a a ON d.k = a.k',
    'SELECT b.k FROM ua_d d JOIN ua_b b ON d.k = b.k');

SELECT pg_temp.ua_assert_sum('overlapping duplicate arms',
    'SELECT u.k FROM (SELECT k FROM ua_a UNION ALL SELECT k FROM ua_a) u
     JOIN ua_d d ON u.k = d.k',
    'SELECT a.k FROM ua_a a JOIN ua_d d ON a.k = d.k',
    'SELECT a.k FROM ua_a a JOIN ua_d d ON a.k = d.k');

SELECT pg_temp.ua_assert_sum('multiple equalities, product within each child',
    'SELECT u.k FROM ua_v u JOIN ua_d d ON u.k = d.k AND u.j = d.j',
    'SELECT a.k FROM ua_a a JOIN ua_d d ON a.k = d.k AND a.j = d.j',
    'SELECT b.k FROM ua_b b JOIN ua_d d ON b.k = d.k AND b.j = d.j');

SELECT pg_temp.ua_assert_sum('filtered subquery arms',
    'SELECT u.k FROM (SELECT k FROM ua_a WHERE keep
                     UNION ALL SELECT k FROM ua_b WHERE keep) u
     JOIN ua_d d ON u.k = d.k',
    'SELECT a.k FROM ua_a a JOIN ua_d d ON a.k = d.k WHERE a.keep',
    'SELECT b.k FROM ua_b b JOIN ua_d d ON b.k = d.k WHERE b.keep');

SELECT pg_temp.ua_assert_sum('pruned child',
    'SELECT u.k FROM (SELECT k FROM ua_a
                     UNION ALL SELECT k FROM ua_b WHERE false) u
     JOIN ua_d d ON u.k = d.k',
    'SELECT a.k FROM ua_a a JOIN ua_d d ON a.k = d.k',
    'SELECT b.k FROM ua_b b JOIN ua_d d ON b.k = d.k WHERE false');

-- The physical join method must not change the joinrel's cardinality.
DO $test$
DECLARE
    before_estimate numeric;
    after_estimate numeric;
BEGIN
    before_estimate := pg_temp.ua_estimate(
        'SELECT u.k FROM ua_v u JOIN ua_d d ON u.k = d.k');
    PERFORM set_config('enable_hashjoin', 'off', true);
    PERFORM set_config('enable_mergejoin', 'off', true);
    after_estimate := pg_temp.ua_estimate(
        'SELECT u.k FROM ua_v u JOIN ua_d d ON u.k = d.k');
    IF before_estimate <> after_estimate THEN
        RAISE EXCEPTION 'join method changed cardinality: % vs %',
                        before_estimate, after_estimate;
    END IF;
    PERFORM set_config('enable_hashjoin', 'on', true);
    PERFORM set_config('enable_mergejoin', 'on', true);
END
$test$;

-- The controlled fixture has 100*40 + 100*10 = 5000 matching pairs.
-- The second arm has no matching keys.  This tests improvement over the
-- parent-level default NDV estimate as well as result multiplicity.
DO $test$
DECLARE
    estimated numeric;
    actual bigint;
BEGIN
    estimated := pg_temp.ua_estimate(
        'SELECT u.k FROM ua_v u JOIN ua_d d ON u.k = d.k');
    SELECT count(*) INTO actual FROM ua_v u JOIN ua_d d ON u.k = d.k;
    IF actual <> 5000 OR abs(estimated - actual) > 2 THEN
        RAISE EXCEPTION 'MCV fixture: estimated %, actual %', estimated, actual;
    END IF;
END
$test$;

-- Five-relation inner subtree, with the union entering last.  The full
-- join above it keeps this close to the motivating query shape.
CREATE TEMP TABLE ua_e AS SELECT * FROM ua_d;
CREATE TEMP TABLE ua_f AS SELECT * FROM ua_d;
CREATE TEMP TABLE ua_g AS SELECT * FROM ua_d;
ANALYZE ua_e;
ANALYZE ua_f;
ANALYZE ua_g;
SELECT pg_temp.ua_assert_sum('union joins an existing inner joinrel',
    'SELECT u.k FROM ua_d d JOIN ua_e e USING (k)
     JOIN ua_f f USING (k) JOIN ua_g g USING (k) JOIN ua_v u USING (k)',
    'SELECT a.k FROM ua_d d JOIN ua_e e USING (k)
     JOIN ua_f f USING (k) JOIN ua_g g USING (k) JOIN ua_a a USING (k)',
    'SELECT b.k FROM ua_d d JOIN ua_e e USING (k)
     JOIN ua_f f USING (k) JOIN ua_g g USING (k) JOIN ua_b b USING (k)');

EXPLAIN
SELECT * FROM ua_empty x FULL JOIN
    (SELECT u.k FROM ua_d d JOIN ua_e e USING (k)
     JOIN ua_f f USING (k) JOIN ua_g g USING (k) JOIN ua_v u USING (k)) q
ON x.k = q.k;

-- Print estimates and counts for comparison with an unpatched server.
-- These cases check safe fallback/result semantics, not improved estimates.
DO $test$
DECLARE
    r record;
    actual bigint;
BEGIN
    FOR r IN SELECT * FROM (VALUES
        ('full join',
         'SELECT u.k FROM ua_v u FULL JOIN ua_d d ON u.k = d.k', 5300::bigint),
        ('left join',
         'SELECT u.k FROM ua_v u LEFT JOIN ua_d d ON u.k = d.k', 5300::bigint),
        ('semi join',
         'SELECT u.k FROM ua_v u WHERE EXISTS (SELECT FROM ua_d d WHERE d.k = u.k)', 200::bigint),
        ('anti join',
         'SELECT u.k FROM ua_v u WHERE NOT EXISTS (SELECT FROM ua_d d WHERE d.k = u.k)', 300::bigint),
        ('constant and NULL outputs',
         'SELECT u.k FROM (SELECT 1 AS k FROM ua_a
                          UNION ALL SELECT NULL::int FROM ua_b) u
          JOIN ua_d d ON u.k = d.k', 8000::bigint),
        ('expression output',
         'SELECT u.k FROM (SELECT k + 0 AS k FROM ua_a
                          UNION ALL SELECT k + 0 FROM ua_b) u
          JOIN ua_d d ON u.k = d.k', 5000::bigint),
        ('two union inputs',
         'SELECT u.k FROM ua_v u JOIN ua_v v ON u.k = v.k', 110000::bigint),
        ('missing child statistics',
         'SELECT u.k FROM (SELECT k FROM ua_a
                          UNION ALL SELECT k FROM ua_empty) u
          JOIN ua_d d ON u.k = d.k', 5000::bigint)
    ) AS cases(label, query, expected)
    LOOP
        EXECUTE 'SELECT count(*) FROM (' || r.query || ') q' INTO actual;
        IF actual <> r.expected THEN
            RAISE EXCEPTION '%: actual %, expected %', r.label, actual, r.expected;
        END IF;
        RAISE NOTICE '%: estimated %, actual %',
                     r.label, pg_temp.ua_estimate(r.query), actual;
    END LOOP;
END
$test$;

SET LOCAL max_parallel_workers_per_gather = 0;
SET LOCAL jit = off;
SET LOCAL default_statistics_target = 1000;
SET LOCAL from_collapse_limit = 8;
SET LOCAL geqo = off;

CREATE TEMP TABLE ua_ab_a AS
SELECT i % 2 + 1 AS k, i % 2 + 1 AS j, i <= 100 AS keep
FROM generate_series(1, 200) g(i);
CREATE TEMP TABLE ua_ab_b AS
SELECT 3 AS k, 3 AS j, i <= 150 AS keep
FROM generate_series(1, 300) g(i);
CREATE TEMP TABLE ua_ab_d AS
SELECT CASE WHEN i <= 40 THEN 1 ELSE 2 END AS k,
       CASE WHEN i <= 40 THEN 1 ELSE 2 END AS j
FROM generate_series(1, 50) g(i);

-- Four small dimensions: four rows with k=1 and one with k=2 each.
-- The five-table query yields 100 * (4^4 + 1^4) = 25700 rows.
CREATE TEMP TABLE ua_ab_e AS
SELECT CASE WHEN i <= 4 THEN 1 ELSE 2 END AS k
FROM generate_series(1, 5) g(i);
CREATE TEMP TABLE ua_ab_f AS SELECT * FROM ua_ab_e;
CREATE TEMP TABLE ua_ab_g AS SELECT * FROM ua_ab_e;
CREATE TEMP TABLE ua_ab_h AS SELECT * FROM ua_ab_e;
CREATE TEMP TABLE ua_ab_x AS SELECT k FROM (VALUES (1), (4)) v(k);
ANALYZE ua_ab_a;
ANALYZE ua_ab_b;
ANALYZE ua_ab_d;
ANALYZE ua_ab_e;
ANALYZE ua_ab_f;
ANALYZE ua_ab_g;
ANALYZE ua_ab_h;
ANALYZE ua_ab_x;

CREATE TEMP VIEW ua_ab_v AS
SELECT k, j, keep FROM ua_ab_a
UNION ALL
SELECT k, j, keep FROM ua_ab_b;

-- EXECUTE plans afresh after every GUC change: no cached generic plan reuse.
-- Check result counts separately, then print the full EXPLAIN ANALYZE plan.
-- Counting first warms this tiny fixture; timings are diagnostic, not a benchmark.
CREATE FUNCTION pg_temp.ua_ab_case(label text, query text, expected bigint)
RETURNS SETOF text LANGUAGE plpgsql AS $func$
DECLARE
    actual bigint;
BEGIN
    EXECUTE 'SELECT count(*) FROM (' || query || ') AS checked' INTO actual;
    IF actual <> expected THEN
        RAISE EXCEPTION '%: actual %, expected %', label, actual, expected;
    END IF;
    RAISE NOTICE '%: mode=%, join_collapse_limit=%, actual=%',
                 label, current_setting('enable_union_all_join_estimates'),
                 current_setting('join_collapse_limit'), actual;
    RETURN QUERY EXECUTE
        'EXPLAIN (ANALYZE, BUFFERS, TIMING OFF, VERBOSE, SETTINGS) ' || query;
END
$func$;

\echo === basic inner join ===
SET LOCAL join_collapse_limit = 8;
SET LOCAL enable_union_all_join_estimates = off;
SELECT * FROM pg_temp.ua_ab_case('basic inner join',
$query$SELECT u.k FROM ua_ab_v u JOIN ua_ab_d d ON u.k = d.k$query$, 5000);
SET LOCAL enable_union_all_join_estimates = on;
SELECT * FROM pg_temp.ua_ab_case('basic inner join',
$query$SELECT u.k FROM ua_ab_v u JOIN ua_ab_d d ON u.k = d.k$query$, 5000);

\echo === reversed inputs ===
SET LOCAL join_collapse_limit = 8;
SET LOCAL enable_union_all_join_estimates = off;
SELECT * FROM pg_temp.ua_ab_case('reversed inputs',
$query$SELECT u.k FROM ua_ab_d d JOIN ua_ab_v u ON d.k = u.k$query$, 5000);
SET LOCAL enable_union_all_join_estimates = on;
SELECT * FROM pg_temp.ua_ab_case('reversed inputs',
$query$SELECT u.k FROM ua_ab_d d JOIN ua_ab_v u ON d.k = u.k$query$, 5000);

\echo === correlated columns (no accuracy assertion) ===
SET LOCAL join_collapse_limit = 8;
SET LOCAL enable_union_all_join_estimates = off;
SELECT * FROM pg_temp.ua_ab_case('correlated columns (no accuracy assertion)',
$query$SELECT u.k FROM ua_ab_v u JOIN ua_ab_d d ON u.k = d.k AND u.j = d.j$query$, 5000);
SET LOCAL enable_union_all_join_estimates = on;
SELECT * FROM pg_temp.ua_ab_case('correlated columns (no accuracy assertion)',
$query$SELECT u.k FROM ua_ab_v u JOIN ua_ab_d d ON u.k = d.k AND u.j = d.j$query$, 5000);

\echo === filtered union ===
SET LOCAL join_collapse_limit = 8;
SET LOCAL enable_union_all_join_estimates = off;
SELECT * FROM pg_temp.ua_ab_case('filtered union',
$query$SELECT u.k FROM ua_ab_v u JOIN ua_ab_d d ON u.k = d.k WHERE u.keep$query$, 2500);
SET LOCAL enable_union_all_join_estimates = on;
SELECT * FROM pg_temp.ua_ab_case('filtered union',
$query$SELECT u.k FROM ua_ab_v u JOIN ua_ab_d d ON u.k = d.k WHERE u.keep$query$, 2500);

\echo === five tables, union last, fixed order ===
SET LOCAL join_collapse_limit = 1;
SET LOCAL enable_union_all_join_estimates = off;
SELECT * FROM pg_temp.ua_ab_case('five tables, union last, fixed order',
$query$SELECT u.k FROM ua_ab_e e JOIN ua_ab_f f USING (k)
JOIN ua_ab_g g USING (k) JOIN ua_ab_h h USING (k)
JOIN ua_ab_v u USING (k)$query$, 25700);
SET LOCAL enable_union_all_join_estimates = on;
SELECT * FROM pg_temp.ua_ab_case('five tables, union last, fixed order',
$query$SELECT u.k FROM ua_ab_e e JOIN ua_ab_f f USING (k)
JOIN ua_ab_g g USING (k) JOIN ua_ab_h h USING (k)
JOIN ua_ab_v u USING (k)$query$, 25700);

\echo === five tables, optimizer chooses order ===
SET LOCAL join_collapse_limit = 8;
SET LOCAL enable_union_all_join_estimates = off;
SELECT * FROM pg_temp.ua_ab_case('five tables, optimizer chooses order',
$query$SELECT u.k FROM ua_ab_e e JOIN ua_ab_f f USING (k)
JOIN ua_ab_g g USING (k) JOIN ua_ab_h h USING (k)
JOIN ua_ab_v u USING (k)$query$, 25700);
SET LOCAL enable_union_all_join_estimates = on;
SELECT * FROM pg_temp.ua_ab_case('five tables, optimizer chooses order',
$query$SELECT u.k FROM ua_ab_e e JOIN ua_ab_f f USING (k)
JOIN ua_ab_g g USING (k) JOIN ua_ab_h h USING (k)
JOIN ua_ab_v u USING (k)$query$, 25700);

\echo === FULL JOIN above five-table inner subtree, fixed inner order ===
SET LOCAL join_collapse_limit = 1;
SET LOCAL enable_union_all_join_estimates = off;
SELECT * FROM pg_temp.ua_ab_case('FULL JOIN above five-table inner subtree, fixed inner order',
$query$SELECT x.k AS xk, q.k AS qk FROM ua_ab_x x FULL JOIN (
SELECT u.k FROM ua_ab_e e JOIN ua_ab_f f USING (k)
JOIN ua_ab_g g USING (k) JOIN ua_ab_h h USING (k)
JOIN ua_ab_v u USING (k)
) q ON x.k = q.k$query$, 25701);
SET LOCAL enable_union_all_join_estimates = on;
SELECT * FROM pg_temp.ua_ab_case('FULL JOIN above five-table inner subtree, fixed inner order',
$query$SELECT x.k AS xk, q.k AS qk FROM ua_ab_x x FULL JOIN (
SELECT u.k FROM ua_ab_e e JOIN ua_ab_f f USING (k)
JOIN ua_ab_g g USING (k) JOIN ua_ab_h h USING (k)
JOIN ua_ab_v u USING (k)
) q ON x.k = q.k$query$, 25701);

\echo === FULL JOIN above five-table inner subtree, free inner order ===
SET LOCAL join_collapse_limit = 8;
SET LOCAL enable_union_all_join_estimates = off;
SELECT * FROM pg_temp.ua_ab_case('FULL JOIN above five-table inner subtree, free inner order',
$query$SELECT x.k AS xk, q.k AS qk FROM ua_ab_x x FULL JOIN (
SELECT u.k FROM ua_ab_e e JOIN ua_ab_f f USING (k)
JOIN ua_ab_g g USING (k) JOIN ua_ab_h h USING (k)
JOIN ua_ab_v u USING (k)
) q ON x.k = q.k$query$, 25701);
SET LOCAL enable_union_all_join_estimates = on;
SELECT * FROM pg_temp.ua_ab_case('FULL JOIN above five-table inner subtree, free inner order',
$query$SELECT x.k AS xk, q.k AS qk FROM ua_ab_x x FULL JOIN (
SELECT u.k FROM ua_ab_e e JOIN ua_ab_f f USING (k)
JOIN ua_ab_g g USING (k) JOIN ua_ab_h h USING (k)
JOIN ua_ab_v u USING (k)
) q ON x.k = q.k$query$, 25701);

\echo === direct FULL JOIN fallback ===
SET LOCAL join_collapse_limit = 8;
SET LOCAL enable_union_all_join_estimates = off;
SELECT * FROM pg_temp.ua_ab_case('direct FULL JOIN fallback',
$query$SELECT u.k AS uk, d.k AS dk FROM ua_ab_v u FULL JOIN ua_ab_d d ON u.k = d.k$query$, 5300);
SET LOCAL enable_union_all_join_estimates = on;
SELECT * FROM pg_temp.ua_ab_case('direct FULL JOIN fallback',
$query$SELECT u.k AS uk, d.k AS dk FROM ua_ab_v u FULL JOIN ua_ab_d d ON u.k = d.k$query$, 5300);

\echo === expression output fallback ===
SET LOCAL join_collapse_limit = 8;
SET LOCAL enable_union_all_join_estimates = off;
SELECT * FROM pg_temp.ua_ab_case('expression output fallback',
$query$SELECT u.k FROM (SELECT k + 0 AS k FROM ua_ab_a
UNION ALL SELECT k + 0 FROM ua_ab_b) u JOIN ua_ab_d d ON u.k = d.k$query$, 5000);
SET LOCAL enable_union_all_join_estimates = on;
SELECT * FROM pg_temp.ua_ab_case('expression output fallback',
$query$SELECT u.k FROM (SELECT k + 0 AS k FROM ua_ab_a
UNION ALL SELECT k + 0 FROM ua_ab_b) u JOIN ua_ab_d d ON u.k = d.k$query$, 5000);


-- Preserve the original reproducer's explicitly distributed join comparison.
\echo === Explicitly distributed UNION ALL joins ===
SET LOCAL join_collapse_limit = 8;
SET LOCAL enable_union_all_join_estimates = off;
SELECT * FROM pg_temp.ua_ab_case('explicitly distributed joins',
$query$SELECT a.k FROM ua_ab_a a JOIN ua_ab_d d ON a.k = d.k
UNION ALL
SELECT b.k FROM ua_ab_b b JOIN ua_ab_d d ON b.k = d.k$query$, 5000);
SET LOCAL enable_union_all_join_estimates = on;
SELECT * FROM pg_temp.ua_ab_case('explicitly distributed joins',
$query$SELECT a.k FROM ua_ab_a a JOIN ua_ab_d d ON a.k = d.k
UNION ALL
SELECT b.k FROM ua_ab_b b JOIN ua_ab_d d ON b.k = d.k$query$, 5000);


-- 0006: isolate Hash/Merge costing with a tiny serial INNER JOIN fixture.
-- A residual join filter leaves 1000 output rows, but 5000 key-matching
-- pairs still reach that filter.  Do not substitute the final row estimate
-- for this candidate-pair estimate.
CREATE FUNCTION pg_temp.ua_cost_pair(label text, query text, method text,
                                     expected bigint, corrected_rows numeric)
RETURNS SETOF text LANGUAGE plpgsql AS $func$
DECLARE
    mode text;
    plan json;
    root_plan json;
    off_cost numeric;
    on_cost numeric;
    off_rows numeric;
    on_rows numeric;
    old_feature text := current_setting('enable_union_all_join_estimates');
    old_hash text := current_setting('enable_hashjoin');
    old_merge text := current_setting('enable_mergejoin');
    old_nest text := current_setting('enable_nestloop');
BEGIN
    IF method NOT IN ('Hash Join', 'Merge Join') THEN
        RAISE EXCEPTION 'unsupported test method: %', method;
    END IF;
    PERFORM set_config('enable_hashjoin',
                      CASE WHEN method = 'Hash Join' THEN 'on' ELSE 'off' END, true);
    PERFORM set_config('enable_mergejoin',
                      CASE WHEN method = 'Merge Join' THEN 'on' ELSE 'off' END, true);
    PERFORM set_config('enable_nestloop', 'off', true);

    FOREACH mode IN ARRAY ARRAY['off', 'on']
    LOOP
        PERFORM set_config('enable_union_all_join_estimates', mode, true);
        EXECUTE 'EXPLAIN (FORMAT JSON) ' || query INTO plan;
        root_plan := plan->0->'Plan';
        IF root_plan->>'Node Type' IS DISTINCT FROM method THEN
            RAISE EXCEPTION '%: mode %, expected %, got %',
                            label, mode, method, root_plan->>'Node Type';
        END IF;
        IF mode = 'off' THEN
            off_cost := (root_plan->>'Total Cost')::numeric;
            off_rows := (root_plan->>'Plan Rows')::numeric;
        ELSE
            on_cost := (root_plan->>'Total Cost')::numeric;
            on_rows := (root_plan->>'Plan Rows')::numeric;
        END IF;
        RETURN NEXT format('%s: mode=%s, rows=%s, total_cost=%s',
                           label, mode, root_plan->>'Plan Rows',
                           root_plan->>'Total Cost');
        -- This helper also asserts actual output count and prints the plan.
        RETURN QUERY SELECT * FROM pg_temp.ua_ab_case(label, query, expected);
    END LOOP;

    -- These fixtures have far more key matches than the default estimate.
    -- A cost increase verifies that fixing rows alone is no longer enough.
    IF on_cost <= off_cost THEN
        RAISE EXCEPTION '%: match-pair costing did not increase: off %, on %',
                        label, off_cost, on_cost;
    END IF;
    IF corrected_rows IS NOT NULL AND on_rows <> corrected_rows THEN
        RAISE EXCEPTION '%: expected corrected rows %, got %',
                        label, corrected_rows, on_rows;
    END IF;
    IF corrected_rows IS NULL AND on_rows <> off_rows THEN
        RAISE EXCEPTION '%: unsupported residual clause should retain row fallback: off %, on %',
                        label, off_rows, on_rows;
    END IF;
    RETURN NEXT format('PASS %s: estimated rows %s -> %s; total cost %s -> %s',
                       label, off_rows, on_rows, off_cost, on_cost);
    PERFORM set_config('enable_union_all_join_estimates', old_feature, true);
    PERFORM set_config('enable_hashjoin', old_hash, true);
    PERFORM set_config('enable_mergejoin', old_merge, true);
    PERFORM set_config('enable_nestloop', old_nest, true);
END
$func$;

\echo === 0006 INNER JOIN match-pair costing assertions ===
SET LOCAL max_parallel_workers_per_gather = 0;
SET LOCAL join_collapse_limit = 8;

SELECT * FROM pg_temp.ua_cost_pair('hash matching pairs',
$query$SELECT u.k FROM ua_ab_v u JOIN ua_ab_d d ON u.k = d.k$query$,
'Hash Join', 5000, 5000);

SELECT * FROM pg_temp.ua_cost_pair('merge matching pairs',
$query$SELECT u.k FROM ua_ab_v u JOIN ua_ab_d d ON u.k = d.k$query$,
'Merge Join', 5000, 5000);

SELECT * FROM pg_temp.ua_cost_pair('hash with residual filter',
$query$SELECT u.k FROM ua_ab_v u JOIN ua_ab_d d
ON u.k = d.k AND u.j + d.j > 2$query$,
'Hash Join', 1000, NULL);

SELECT * FROM pg_temp.ua_cost_pair('merge with residual filter',
$query$SELECT u.k FROM ua_ab_v u JOIN ua_ab_d d
ON u.k = d.k AND u.j + d.j > 2$query$,
'Merge Join', 1000, NULL);

-- 0007: boundary assertions.  Only result counts and narrowly specified
-- estimate/cost relationships are asserted; timings have no pass threshold.
\echo === 0007 INNER JOIN boundary assertions ===
SET LOCAL enable_hashjoin = on;
SET LOCAL enable_mergejoin = on;
SET LOCAL enable_nestloop = on;
SET LOCAL max_parallel_workers_per_gather = 0;
SET LOCAL join_collapse_limit = 8;

CREATE TEMP TABLE ua_edge_a AS
SELECT k FROM (VALUES (1), (1), (2), (NULL::int), (NULL::int)) v(k);
CREATE TEMP TABLE ua_edge_b AS
SELECT k FROM (VALUES (2), (3), (NULL::int)) v(k);
CREATE TEMP TABLE ua_edge_d AS
SELECT k FROM (VALUES (1), (1), (2), (4), (NULL::int)) v(k);
CREATE TEMP TABLE ua_edge_null AS SELECT NULL::int AS k FROM generate_series(1, 3);
CREATE TEMP TABLE ua_edge_empty (k int);
ANALYZE ua_edge_a;
ANALYZE ua_edge_b;
ANALYZE ua_edge_d;
ANALYZE ua_edge_null;
ANALYZE ua_edge_empty;

CREATE TEMP TABLE ua_cast_a AS
SELECT (CASE WHEN i <= 40 THEN 'aa' ELSE 'bb' END)::varchar(8) AS k
FROM generate_series(1, 50) g(i);
CREATE TEMP TABLE ua_cast_b AS
SELECT 'cc'::varchar(8) AS k FROM generate_series(1, 40);
CREATE TEMP TABLE ua_cast_d AS
SELECT CASE WHEN i <= 10 THEN 'aa' ELSE 'bb' END AS k
FROM generate_series(1, 30) g(i);
ANALYZE ua_cast_a;
ANALYZE ua_cast_b;
ANALYZE ua_cast_d;

CREATE FUNCTION pg_temp.ua_edge_case(p_label text, p_query text,
                                    p_expected bigint, p_check text,
                                    p_arms text[] DEFAULT NULL)
RETURNS TABLE(case_name text, mode text, estimated numeric,
              actual bigint, total_cost numeric, check_kind text)
LANGUAGE plpgsql AS $func$
DECLARE
    doc json;
    off_rows numeric;
    on_rows numeric;
    off_cost numeric;
    on_cost numeric;
    arm text;
    arm_sum numeric := 0;
    old_feature text := current_setting('enable_union_all_join_estimates');
BEGIN
    IF p_check NOT IN ('sum', 'exact', 'unchanged') THEN
        RAISE EXCEPTION 'unknown boundary check: %', p_check;
    END IF;
    FOREACH mode IN ARRAY ARRAY['off', 'on'] LOOP
        PERFORM set_config('enable_union_all_join_estimates', mode, true);
        EXECUTE 'SELECT count(*) FROM (' || p_query || ') q' INTO actual;
        IF actual <> p_expected THEN
            RAISE EXCEPTION '%: mode %, actual %, expected %',
                            p_label, mode, actual, p_expected;
        END IF;
        EXECUTE 'EXPLAIN (FORMAT JSON) ' || p_query INTO doc;
        estimated := (doc->0->'Plan'->>'Plan Rows')::numeric;
        total_cost := (doc->0->'Plan'->>'Total Cost')::numeric;
        IF mode = 'off' THEN
            off_rows := estimated; off_cost := total_cost;
        ELSE
            on_rows := estimated; on_cost := total_cost;
        END IF;
        case_name := p_label;
        check_kind := p_check;
        RETURN NEXT;
    END LOOP;
    IF p_check = 'sum' THEN
        IF p_arms IS NULL OR cardinality(p_arms) = 0 THEN
            RAISE EXCEPTION '%: missing reference arms', p_label;
        END IF;
        FOREACH arm IN ARRAY p_arms LOOP
            EXECUTE 'EXPLAIN (FORMAT JSON) ' || arm INTO doc;
            arm_sum := arm_sum + (doc->0->'Plan'->>'Plan Rows')::numeric;
        END LOOP;
        IF abs(on_rows - arm_sum) > cardinality(p_arms) THEN
            RAISE EXCEPTION '%: combined %, separate arm sum %',
                            p_label, on_rows, arm_sum;
        END IF;
    ELSIF p_check = 'exact' THEN
        IF on_rows <> p_expected OR on_rows <= off_rows THEN
            RAISE EXCEPTION '%: expected corrected rows %, got off %, on %',
                            p_label, p_expected, off_rows, on_rows;
        END IF;
    ELSE
        -- A fixture-level observation, not proof of a specific fallback branch.
        IF on_rows <> off_rows OR on_cost <> off_cost THEN
            RAISE EXCEPTION '%: fallback estimate/cost changed: rows % -> %, cost % -> %',
                            p_label, off_rows, on_rows, off_cost, on_cost;
        END IF;
    END IF;
    PERFORM set_config('enable_union_all_join_estimates', old_feature, true);
END
$func$;

SELECT * FROM pg_temp.ua_edge_case('NULL keys never match NULL keys',
$query$SELECT u.k FROM (SELECT k FROM ua_edge_a UNION ALL SELECT k FROM ua_edge_b) u
JOIN ua_edge_d d ON u.k = d.k$query$, 6, 'sum',
ARRAY['SELECT a.k FROM ua_edge_a a JOIN ua_edge_d d ON a.k = d.k',
      'SELECT b.k FROM ua_edge_b b JOIN ua_edge_d d ON b.k = d.k']);

SELECT * FROM pg_temp.ua_edge_case('all-NULL children',
$query$SELECT u.k FROM (SELECT k FROM ua_edge_null UNION ALL SELECT k FROM ua_edge_null) u
JOIN ua_edge_d d ON u.k = d.k$query$, 0, 'sum',
ARRAY['SELECT a.k FROM ua_edge_null a JOIN ua_edge_d d ON a.k = d.k',
      'SELECT b.k FROM ua_edge_null b JOIN ua_edge_d d ON b.k = d.k']);

SELECT * FROM pg_temp.ua_edge_case('physical empty child without column statistics',
$query$SELECT u.k FROM (SELECT k FROM ua_edge_a UNION ALL SELECT k FROM ua_edge_empty) u
JOIN ua_edge_d d ON u.k = d.k$query$, 5, 'unchanged');

SELECT * FROM pg_temp.ua_edge_case('all children pruned',
$query$SELECT u.k FROM (SELECT k FROM ua_edge_a WHERE false
UNION ALL SELECT k FROM ua_edge_b WHERE false) u
JOIN ua_edge_d d ON u.k = d.k$query$, 0, 'unchanged');

SELECT * FROM pg_temp.ua_edge_case('binary varchar-to-text child relabel',
$query$SELECT u.k FROM (SELECT k::text AS k FROM ua_cast_a
UNION ALL SELECT k::text AS k FROM ua_cast_b) u
JOIN ua_cast_d d ON u.k = d.k$query$, 600, 'sum',
ARRAY['SELECT a.k::text FROM ua_cast_a a JOIN ua_cast_d d ON a.k::text = d.k',
      'SELECT b.k::text FROM ua_cast_b b JOIN ua_cast_d d ON b.k::text = d.k']);

-- The arms intentionally repeat one physical table: bag multiplicity must
-- remain intact, while each reference receives its own planner relation.
CREATE TEMP TABLE ua_scale_arm AS SELECT k FROM (VALUES (1), (2)) v(k);
ANALYZE ua_scale_arm;
CREATE TEMP TABLE ua_plan_cases (
    case_name text PRIMARY KEY, branches int,
    collapse_limit int, query_text text, expected bigint, boundary_check text
);
DO $test$
DECLARE
    n int;
    union_query text;
BEGIN
    FOREACH n IN ARRAY ARRAY[2, 8, 32, 64, 65] LOOP
        SELECT string_agg('SELECT k FROM ua_scale_arm', ' UNION ALL ' ORDER BY i)
          INTO union_query FROM generate_series(1, n) g(i);
        INSERT INTO ua_plan_cases VALUES
            ('branches_' || n, n, 8,
             'SELECT u.k FROM (' || union_query || ') u JOIN ua_ab_d d ON u.k = d.k',
             50::bigint * n, CASE WHEN n <= 64 THEN 'exact' ELSE 'unchanged' END);
    END LOOP;
END
$test$;

SELECT result.* FROM ua_plan_cases c
CROSS JOIN LATERAL pg_temp.ua_edge_case(c.case_name, c.query_text,
                                      c.expected, c.boundary_check) result
ORDER BY c.branches, result.mode;

-- Distinct column pairs prevent duplicate-clause elimination.  Every key is
-- constant in the data (not a constant SQL expression), so all 50 pairs match.
-- At 16 clauses the prototype applies; at 17 it must retain the old estimate.
DO $test$
DECLARE
    columns_sql text;
BEGIN
    SELECT string_agg(format('1 AS c%s', i), ', ' ORDER BY i)
      INTO columns_sql FROM generate_series(1, 17) g(i);
    EXECUTE 'CREATE TEMP TABLE ua_wide_a AS SELECT ' || columns_sql ||
            ' FROM generate_series(1, 5)';
    CREATE TEMP TABLE ua_wide_b AS SELECT * FROM ua_wide_a;
    CREATE TEMP TABLE ua_wide_d AS SELECT * FROM ua_wide_a;
END
$test$;
ANALYZE ua_wide_a;
ANALYZE ua_wide_b;
ANALYZE ua_wide_d;
CREATE TEMP TABLE ua_clause_cases (clause_count int, query_text text);
INSERT INTO ua_clause_cases
SELECT n, 'SELECT u.c1 FROM (SELECT * FROM ua_wide_a UNION ALL SELECT * FROM ua_wide_b) u '
       || 'JOIN ua_wide_d d ON '
       || (SELECT string_agg(format('u.c%s = d.c%s', i, i), ' AND ' ORDER BY i)
             FROM generate_series(1, n) g(i))
FROM (VALUES (16), (17)) v(n);

SELECT result.* FROM ua_clause_cases c
CROSS JOIN LATERAL pg_temp.ua_edge_case('clauses_' || c.clause_count, c.query_text,
    50, CASE WHEN c.clause_count = 16 THEN 'exact' ELSE 'unchanged' END) result
ORDER BY c.clause_count, result.mode;

-- Reuse the established small five-table query for planning-only samples.
INSERT INTO ua_plan_cases
SELECT 'five_tables_' || CASE WHEN n = 1 THEN 'fixed' ELSE 'free' END,
       2, n,
$query$SELECT u.k FROM ua_ab_e e JOIN ua_ab_f f USING (k)
JOIN ua_ab_g g USING (k) JOIN ua_ab_h h USING (k) JOIN ua_ab_v u USING (k)$query$,
       25700, NULL
FROM (VALUES (1), (8)) v(n);

\echo === small planning samples: EXPLAIN only, no query execution ===
-- Four warmups per mode, then 20 measured samples per mode and query.
-- Alternate which mode goes first.  PostgreSQL Planning Time and total
-- EXPLAIN wall time are stored separately; EXPLAIN wall time includes formatting.
CREATE TEMP TABLE ua_plan_samples (
    case_name text, branches int, collapse_limit int,
    mode text, sample_no int, planning_ms double precision,
    explain_wall_ms double precision, estimated_rows numeric,
    total_cost numeric, node_type text
);
DO $measure$
DECLARE
    c record;
    sample int;
    mode text;
    modes text[];
    doc json;
    started_at timestamptz;
    elapsed_ms double precision;
    old_feature text := current_setting('enable_union_all_join_estimates');
    old_collapse text := current_setting('join_collapse_limit');
BEGIN
    FOR c IN SELECT * FROM ua_plan_cases ORDER BY case_name LOOP
        PERFORM set_config('join_collapse_limit', c.collapse_limit::text, true);
        RAISE NOTICE 'Planning samples: %, branches %, join_collapse_limit %',
                     c.case_name, c.branches, c.collapse_limit;
        FOR sample IN 1..24 LOOP
            modes := CASE WHEN sample % 2 = 1 THEN ARRAY['off', 'on']
                          ELSE ARRAY['on', 'off'] END;
            FOREACH mode IN ARRAY modes LOOP
                PERFORM set_config('enable_union_all_join_estimates', mode, true);
                started_at := clock_timestamp();
                EXECUTE 'EXPLAIN (FORMAT JSON, SUMMARY ON) ' || c.query_text INTO doc;
                elapsed_ms := extract(epoch FROM clock_timestamp() - started_at) * 1000;
                IF sample > 4 THEN
                    INSERT INTO ua_plan_samples VALUES
                        (c.case_name, c.branches, c.collapse_limit, mode, sample - 4,
                         (doc->0->>'Planning Time')::double precision, elapsed_ms,
                         (doc->0->'Plan'->>'Plan Rows')::numeric,
                         (doc->0->'Plan'->>'Total Cost')::numeric,
                         doc->0->'Plan'->>'Node Type');
                END IF;
            END LOOP;
        END LOOP;
    END LOOP;
    PERFORM set_config('enable_union_all_join_estimates', old_feature, true);
    PERFORM set_config('join_collapse_limit', old_collapse, true);
END
$measure$;

SELECT case_name, branches, collapse_limit, mode,
       count(*) AS samples, count(planning_ms) AS reported_planning_samples,
       round((percentile_cont(0.5) WITHIN GROUP (ORDER BY planning_ms))::numeric, 3) AS planning_p50_ms,
       round((percentile_cont(0.95) WITHIN GROUP (ORDER BY planning_ms))::numeric, 3) AS planning_p95_ms,
       round((percentile_cont(0.5) WITHIN GROUP (ORDER BY explain_wall_ms))::numeric, 3) AS explain_wall_p50_ms,
       round((percentile_cont(0.95) WITHIN GROUP (ORDER BY explain_wall_ms))::numeric, 3) AS explain_wall_p95_ms,
       min(estimated_rows) AS rows_min, max(estimated_rows) AS rows_max,
       min(total_cost) AS cost_min, max(total_cost) AS cost_max,
       string_agg(DISTINCT node_type, ', ' ORDER BY node_type) AS plan_types
FROM ua_plan_samples
GROUP BY case_name, branches, collapse_limit, mode
ORDER BY case_name, mode;

-- Require complete collection, but never fail on timing magnitude.
DO $test$
BEGIN
    IF (SELECT count(*) FROM ua_plan_samples) <> 280 THEN
        RAISE EXCEPTION 'incomplete planning samples';
    END IF;
END
$test$;

\echo === 0009 larger INNER JOIN execution / plan-regression screen ===
SET LOCAL join_collapse_limit = 8;
SET LOCAL from_collapse_limit = 8;
SET LOCAL geqo = off;
SET LOCAL enable_hashjoin = on;
SET LOCAL enable_mergejoin = on;
SET LOCAL enable_nestloop = on;
SET LOCAL max_parallel_workers_per_gather = 0;
SET LOCAL jit = off;
SET LOCAL work_mem = '16MB';

SELECT version();
SELECT name, setting, unit FROM pg_settings
WHERE name IN ('work_mem', 'temp_buffers', 'shared_buffers', 'random_page_cost',
               'seq_page_cost', 'cpu_tuple_cost', 'cpu_operator_cost',
               'effective_cache_size', 'default_statistics_target',
               'enable_memoize', 'enable_material', 'enable_hashjoin',
               'enable_mergejoin', 'enable_nestloop', 'jit',
               'max_parallel_workers_per_gather') ORDER BY name;

-- Compare structure, relation/index identities, and predicates, excluding
-- estimated costs/cardinalities and execution instrumentation.  A changed
-- estimate alone is not a changed physical plan.  This is a diagnostic
-- signature, not a complete semantic equivalence check of arbitrary plans.
CREATE FUNCTION pg_temp.ua_plan_shape(p_node jsonb) RETURNS jsonb
LANGUAGE plpgsql IMMUTABLE AS $func$
DECLARE
    shaped jsonb;
    children jsonb := '[]'::jsonb;
    child jsonb;
BEGIN
    SELECT coalesce(jsonb_object_agg(key, value), '{}'::jsonb) INTO shaped
    FROM jsonb_each(p_node)
    WHERE key IN ('Node Type', 'Join Type', 'Parent Relationship',
                  'Relation Name', 'Alias', 'Index Name', 'Scan Direction',
                  'Strategy', 'Partial Mode', 'Parallel Aware', 'Inner Unique',
                  'Hash Cond', 'Merge Cond', 'Join Filter', 'Index Cond',
                  'Recheck Cond', 'Filter', 'Sort Key', 'Presorted Key',
                  'Group Key', 'Cache Key', 'Subplan Name');
    FOR child IN SELECT value FROM jsonb_array_elements(
        coalesce(p_node->'Plans', '[]'::jsonb)) LOOP
        children := children || jsonb_build_array(pg_temp.ua_plan_shape(child));
    END LOOP;
    RETURN shaped || jsonb_build_object('Plans', children);
END
$func$;

CREATE TEMP TABLE ua_perf_cases (
    case_name text PRIMARY KEY, query_text text NOT NULL, expected_rows bigint NOT NULL
);
CREATE TEMP TABLE ua_perf_samples (
    arm_rows int, case_name text, mode text, sample_no int,
    planning_ms double precision NOT NULL, execution_ms double precision NOT NULL,
    estimated_rows numeric, actual_rows numeric, total_cost numeric,
    shape jsonb NOT NULL, document jsonb NOT NULL,
    PRIMARY KEY (arm_rows, case_name, mode, sample_no)
);
CREATE TEMP TABLE ua_perf_correctness (
    arm_rows int, case_name text, actual_rows bigint, bag_equal boolean,
    PRIMARY KEY (arm_rows, case_name)
);

DO $bench$
DECLARE
    n int;
    c record;
    mode text;
    modes text[];
    sample int;
    doc json;
    off_count bigint;
    on_count bigint;
    different boolean;
    old_feature text := current_setting('enable_union_all_join_estimates');
BEGIN
    FOREACH n IN ARRAY ARRAY[50000, 250000] LOOP
        RAISE NOTICE '0009: building % rows per arm (% total uniform input rows)', n, 2*n;
        -- a covers keys 1..1000, b covers 1001..2000.  Correlated j/keep
        -- deliberately exercise assumptions not fixed by this prototype.
        EXECUTE format($q$CREATE TEMP TABLE ua_perf_a AS
            SELECT i AS id, (i-1) %% 1000 + 1 AS k,
                   (((i-1) %% 1000) + 1) %% 4 AS j,
                   (i-1) %% 1000 < 4 AS keep, i %% 97 AS v
            FROM generate_series(1, %s) g(i)$q$, n);
        EXECUTE format($q$CREATE TEMP TABLE ua_perf_b AS
            SELECT %s + i AS id, (i-1) %% 1000 + 1001 AS k,
                   (((i-1) %% 1000) + 1001) %% 4 AS j,
                   false AS keep, i %% 97 AS v
            FROM generate_series(1, %s) g(i)$q$, n, n);
        EXECUTE format($q$CREATE TEMP TABLE ua_perf_skew AS
            SELECT i AS id, k, k %% 4 AS j, k <= 4 AS keep, i %% 97 AS v
            FROM (SELECT i, CASE WHEN i <= %s THEN 1
                       ELSE (i-1) %% 1000 + 2 END AS k
                  FROM generate_series(1, %s) g(i)) s$q$, n*9/10, n);
        CREATE INDEX ON ua_perf_a (k);
        CREATE INDEX ON ua_perf_b (k);
        CREATE INDEX ON ua_perf_skew (k);
        CREATE TEMP TABLE ua_perf_d AS
            SELECT i AS k, i % 4 AS j, i <= 4 AS selected, i % 17 AS w
            FROM generate_series(1, 2000) g(i);
        ALTER TABLE ua_perf_d ADD PRIMARY KEY (k);
        CREATE TEMP TABLE ua_perf_e AS SELECT k FROM ua_perf_d;
        CREATE TEMP TABLE ua_perf_f AS SELECT k FROM ua_perf_d;
        CREATE TEMP TABLE ua_perf_g AS SELECT k, selected FROM ua_perf_d;
        ALTER TABLE ua_perf_e ADD PRIMARY KEY (k);
        ALTER TABLE ua_perf_f ADD PRIMARY KEY (k);
        ALTER TABLE ua_perf_g ADD PRIMARY KEY (k);
        CREATE TEMP TABLE ua_perf_hot AS
            SELECT 1 AS k, i % 17 AS w FROM generate_series(1, 200) g(i);
        CREATE TEMP TABLE ua_perf_none AS
            SELECT i AS k, i % 17 AS w FROM generate_series(3001, 5000) g(i);
        ALTER TABLE ua_perf_none ADD PRIMARY KEY (k);
        ANALYZE ua_perf_a;
        ANALYZE ua_perf_b;
        ANALYZE ua_perf_skew;
        ANALYZE ua_perf_d;
        ANALYZE ua_perf_e;
        ANALYZE ua_perf_f;
        ANALYZE ua_perf_g;
        ANALYZE ua_perf_hot;
        ANALYZE ua_perf_none;
        CREATE TEMP VIEW ua_perf_u AS
            SELECT * FROM ua_perf_a UNION ALL SELECT * FROM ua_perf_b;
        CREATE TEMP VIEW ua_perf_s AS
            SELECT * FROM ua_perf_skew UNION ALL SELECT * FROM ua_perf_b;
        TRUNCATE ua_perf_cases;
        INSERT INTO ua_perf_cases VALUES
        ('uniform_unique',
         'SELECT u.id, u.k, u.v+d.w AS v FROM ua_perf_u u JOIN ua_perf_d d ON u.k=d.k', 2*n),
        ('one_matching_arm',
         'SELECT u.id, u.k, u.v+d.w AS v FROM ua_perf_u u JOIN ua_perf_d d ON u.k=d.k WHERE d.k<=1000', n),
        ('overlapping_duplicate_arms',
         'SELECT u.id, u.k, u.v+d.w AS v FROM (SELECT * FROM ua_perf_a UNION ALL SELECT * FROM ua_perf_a) u JOIN ua_perf_d d ON u.k=d.k', 2*n),
        ('selective_dimension_indexes',
         'SELECT u.id, u.k, u.v+d.w AS v FROM ua_perf_u u JOIN ua_perf_d d ON u.k=d.k WHERE d.selected', n/250),
        ('filtered_union_correlation',
         'SELECT u.id, u.k, u.v+d.w AS v FROM ua_perf_u u JOIN ua_perf_d d ON u.k=d.k WHERE u.keep', n/250),
        ('skew_hot_key_selected',
         'SELECT u.id, u.k, u.v+d.w AS v FROM ua_perf_s u JOIN ua_perf_d d ON u.k=d.k WHERE d.selected', n*9/10+3*n/10000),
        ('correlated_two_columns',
         'SELECT u.id, u.k, u.v+d.w AS v FROM ua_perf_u u JOIN ua_perf_d d ON u.k=d.k AND u.j=d.j', 2*n),
        ('residual_join_filter',
         'SELECT u.id, u.k, u.v+d.w AS v FROM ua_perf_u u JOIN ua_perf_d d ON u.k=d.k AND u.j+d.j>2', n),
        ('five_table_selective',
         'SELECT u.id, u.k, u.v+d.w AS v FROM ua_perf_u u JOIN ua_perf_d d USING(k) JOIN ua_perf_e e USING(k) JOIN ua_perf_f f USING(k) JOIN ua_perf_g g USING(k) WHERE g.selected', n/250),
        ('duplicate_dimension_mcv',
         'SELECT u.id, u.k, u.v+d.w AS v FROM ua_perf_u u JOIN ua_perf_hot d ON u.k=d.k', n/5),
        ('no_matching_keys',
         'SELECT u.id, u.k, u.v+d.w AS v FROM ua_perf_u u JOIN ua_perf_none d ON u.k=d.k', 0);

        FOR c IN SELECT * FROM ua_perf_cases ORDER BY case_name LOOP
            -- Untimed bag equality: compare every projected value and every
            -- duplicate, not just counts or a potentially colliding checksum.
            PERFORM set_config('enable_union_all_join_estimates', 'off', true);
            EXECUTE 'CREATE TEMP TABLE ua_perf_off AS ' || c.query_text;
            PERFORM set_config('enable_union_all_join_estimates', 'on', true);
            EXECUTE 'CREATE TEMP TABLE ua_perf_on AS ' || c.query_text;
            SELECT count(*) INTO off_count FROM ua_perf_off;
            SELECT count(*) INTO on_count FROM ua_perf_on;
            SELECT EXISTS (
                SELECT 1 FROM (
                    (SELECT * FROM ua_perf_off EXCEPT ALL SELECT * FROM ua_perf_on)
                    UNION ALL
                    (SELECT * FROM ua_perf_on EXCEPT ALL SELECT * FROM ua_perf_off)
                ) differences
            ) INTO different;
            IF different OR off_count <> c.expected_rows OR on_count <> c.expected_rows THEN
                RAISE EXCEPTION '0009 %, arm_rows %: result mismatch; off %, on %, expected %, bags differ %',
                    c.case_name, n, off_count, on_count, c.expected_rows, different;
            END IF;
            INSERT INTO ua_perf_correctness VALUES (n, c.case_name, on_count, true);
            DROP TABLE ua_perf_off, ua_perf_on;
            RAISE NOTICE '0009 % / %: bag equality PASS, rows %; measuring', n, c.case_name, on_count;
            -- Fresh planning on every call. Two warmups per mode; eight paired
            -- measurements, with the first mode alternating to reduce order bias.
            FOR sample IN 1..10 LOOP
                modes := CASE WHEN sample % 2 = 1 THEN ARRAY['off','on']
                              ELSE ARRAY['on','off'] END;
                FOREACH mode IN ARRAY modes LOOP
                    PERFORM set_config('enable_union_all_join_estimates', mode, true);
                    EXECUTE 'EXPLAIN (ANALYZE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON) '
                            || c.query_text INTO doc;
                    IF (doc->0->'Plan'->>'Actual Rows')::numeric <> c.expected_rows
                       OR (doc->0->'Plan'->>'Actual Loops')::numeric <> 1 THEN
                        RAISE EXCEPTION '0009 % / % / %: unexpected measured root rows or loops',
                            n, c.case_name, mode;
                    END IF;
                    IF sample > 2 THEN
                        INSERT INTO ua_perf_samples VALUES (
                            n, c.case_name, mode, sample-2,
                            (doc->0->>'Planning Time')::double precision,
                            (doc->0->>'Execution Time')::double precision,
                            (doc->0->'Plan'->>'Plan Rows')::numeric,
                            (doc->0->'Plan'->>'Actual Rows')::numeric,
                            (doc->0->'Plan'->>'Total Cost')::numeric,
                            pg_temp.ua_plan_shape((doc->0->'Plan')::jsonb), doc::jsonb);
                    END IF;
                END LOOP;
            END LOOP;
        END LOOP;
        DROP VIEW ua_perf_u, ua_perf_s;
        DROP TABLE ua_perf_a, ua_perf_b, ua_perf_skew, ua_perf_d,
                   ua_perf_e, ua_perf_f, ua_perf_g, ua_perf_hot, ua_perf_none;
    END LOOP;
    PERFORM set_config('enable_union_all_join_estimates', old_feature, true);
END
$bench$;

CREATE TEMP VIEW ua_perf_summary AS
SELECT arm_rows, case_name, mode, count(*) AS samples,
       percentile_cont(0.5) WITHIN GROUP (ORDER BY execution_ms) AS exec_p50,
       percentile_cont(0.95) WITHIN GROUP (ORDER BY execution_ms) AS exec_p95,
       percentile_cont(0.5) WITHIN GROUP (ORDER BY planning_ms) AS planning_p50,
       percentile_cont(0.5) WITHIN GROUP (ORDER BY planning_ms+execution_ms) AS total_p50,
       min(estimated_rows) AS estimate_min, max(estimated_rows) AS estimate_max,
       min(actual_rows) AS actual_rows, min(total_cost) AS cost_min, max(total_cost) AS cost_max,
       count(DISTINCT shape) AS plan_variants,
       max(greatest(greatest(estimated_rows, 1)/greatest(actual_rows, 1),
                    greatest(actual_rows, 1)/greatest(estimated_rows, 1))) AS root_q_error_floor1
FROM ua_perf_samples GROUP BY arm_rows, case_name, mode;

\echo === 0009 per-mode execution results (milliseconds; q-error floors rows at 1) ===
SELECT arm_rows, case_name, mode, samples,
       round(exec_p50::numeric,3) AS exec_p50_ms,
       round(exec_p95::numeric,3) AS exec_p95_ms,
       round(planning_p50::numeric,3) AS planning_p50_ms,
       round(total_p50::numeric,3) AS plan_plus_exec_p50_ms,
       estimate_min, estimate_max, actual_rows,
       round(root_q_error_floor1,2) AS root_q_error_floor1,
       cost_min, cost_max, plan_variants
FROM ua_perf_summary ORDER BY arm_rows, case_name, mode;

\echo === 0009 off/on comparison: positive delta means slower; ratio >1 means slower ===
-- Same-plan timing changes are separated from plan-change candidates. The
-- 20% AND 1ms screen is only a reporting threshold, never a pass/fail gate.
-- Eight paired samples cannot establish significance or global plan optimality.
WITH pairs AS (
    SELECT a.arm_rows, a.case_name,
           percentile_cont(0.5) WITHIN GROUP
               (ORDER BY b.execution_ms/nullif(a.execution_ms,0)) AS paired_ratio,
           count(*) FILTER (WHERE b.execution_ms>a.execution_ms) AS slower_pairs
    FROM ua_perf_samples a JOIN ua_perf_samples b
      USING (arm_rows, case_name, sample_no)
    WHERE a.mode='off' AND b.mode='on' GROUP BY a.arm_rows, a.case_name
), comparison AS (
    SELECT a.*, b.exec_p50 AS on_p50, b.exec_p95 AS on_p95,
           b.total_p50 AS on_total_p50, b.plan_variants AS on_variants,
           p.paired_ratio, p.slower_pairs,
           EXISTS (SELECT 1 FROM ua_perf_samples x JOIN ua_perf_samples y
                       USING (arm_rows, case_name, sample_no)
                   WHERE x.arm_rows=a.arm_rows AND x.case_name=a.case_name
                     AND x.mode='off' AND y.mode='on' AND x.shape<>y.shape) AS plan_changed
    FROM ua_perf_summary a JOIN ua_perf_summary b USING (arm_rows, case_name)
    JOIN pairs p USING (arm_rows, case_name)
    WHERE a.mode='off' AND b.mode='on'
)
SELECT arm_rows, case_name, plan_changed,
       round(exec_p50::numeric,3) AS off_ms, round(on_p50::numeric,3) AS on_ms,
       round((on_p50-exec_p50)::numeric,3) AS delta_ms,
       round((100*(on_p50/nullif(exec_p50,0)-1))::numeric,1) AS delta_pct,
       round((exec_p50/nullif(on_p50,0))::numeric,2) AS speedup_off_div_on,
       round(paired_ratio::numeric,2) AS paired_on_div_off, slower_pairs,
       round((on_total_p50-total_p50)::numeric,3) AS plan_plus_exec_delta_ms,
       CASE WHEN plan_variants>1 OR on_variants>1 THEN 'REVIEW: plan varies within mode'
            WHEN on_p50>=exec_p50*1.20 AND on_p50-exec_p50>=1
              THEN CASE WHEN plan_changed THEN 'REVIEW: possible plan regression'
                        ELSE 'REVIEW: slower with same plan signature' END
            WHEN on_p50<=exec_p50*0.80 AND exec_p50-on_p50>=1 THEN 'observed improvement'
            ELSE 'below timing screen' END AS assessment
FROM comparison ORDER BY (on_p50-exec_p50) DESC, arm_rows, case_name;

\echo === 0009 representative plan trees: sample 1 for every case/mode ===
-- Preserve tree order, join/scan methods, predicates, per-loop row estimates,
-- actual loop counts, index selection, buffer traffic and spill evidence.
-- Buffers are inclusive of descendants: do not sum these node-level counters.
WITH RECURSIVE tree(arm_rows, case_name, mode, node_path, node) AS (
    SELECT arm_rows, case_name, mode, ARRAY[0]::int[], document->0->'Plan'
    FROM ua_perf_samples WHERE sample_no=1
    UNION ALL
    SELECT t.arm_rows, t.case_name, t.mode, t.node_path || p.ord::int, p.node
    FROM tree t CROSS JOIN LATERAL jsonb_array_elements(
        coalesce(t.node->'Plans','[]'::jsonb)) WITH ORDINALITY AS p(node,ord)
)
SELECT arm_rows, case_name, mode, node_path,
       node->>'Node Type' AS node_type, node->>'Join Type' AS join_type,
       node->>'Relation Name' AS relation, node->>'Alias' AS alias,
       node->>'Index Name' AS index_name,
       node->>'Plan Rows' AS estimated_rows, node->>'Actual Rows' AS actual_rows_per_loop,
       node->>'Actual Loops' AS loops,
       CASE WHEN (node->>'Actual Loops')::numeric>0 THEN
           round(greatest(greatest((node->>'Plan Rows')::numeric,1)/greatest((node->>'Actual Rows')::numeric,1),
                          greatest((node->>'Actual Rows')::numeric,1)/greatest((node->>'Plan Rows')::numeric,1)),2)
       END AS q_error_floor1,
       node->>'Total Cost' AS total_cost,
       node->>'Local Hit Blocks' AS local_hits, node->>'Local Read Blocks' AS local_reads,
       node->>'Temp Read Blocks' AS temp_reads, node->>'Temp Written Blocks' AS temp_writes,
       node->>'Hash Batches' AS hash_batches, node->>'Sort Space Type' AS sort_space,
       node->>'Rows Removed by Join Filter' AS removed_by_join_filter,
       pg_temp.ua_plan_shape(node)-'Plans' AS node_details
FROM tree ORDER BY arm_rows, case_name, mode, node_path;

DO $test$
BEGIN
    IF (SELECT count(*) FROM ua_perf_correctness WHERE bag_equal) <> 22
       OR (SELECT count(*) FROM ua_perf_samples) <> 352
       OR (SELECT count(*) FROM ua_perf_summary) <> 44
       OR EXISTS (SELECT 1 FROM ua_perf_summary WHERE samples<>8) THEN
        RAISE EXCEPTION '0009 incomplete correctness or execution measurements';
    END IF;
END
$test$;

\echo === 0009: inspect REVIEW rows above; assertion success does not mean no timing regressions ===
ROLLBACK;
\echo === UNION ALL test: all assertions passed; transaction rolled back ===
