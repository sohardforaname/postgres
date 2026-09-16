-- UNION ALL join estimation: the only manual test entry point for this patch.
-- From the repository root:
--   psql -X -v ON_ERROR_STOP=1 -d YOUR_TEST_DB -f union_all_join_test.sql > union-all-test.log 2>&1
-- Add your usual -h / -p / -U connection options as needed.
-- Do not use --single-transaction or invoke inside an existing transaction.
-- All objects are temporary; all settings use SET LOCAL; the script rolls back.
-- Assertions run with the feature on; paired cases then run off and on.
-- Plans are generated with EXECUTE after each switch, avoiding cached plans.
-- Counts before EXPLAIN warm the data; timings are not a performance benchmark.
-- Large-cardinality legacy cases below use EXPLAIN only, not EXPLAIN ANALYZE.
-- Executed five-table fixtures produce 25700 rows (25701 with the outer FULL JOIN).
-- This bundled SQL has NOT been executed by the authoring assistant.
-- Original v1 assertions and the earlier basic A/B were run successfully by the user.
-- No regression schedule or expected files are modified.
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

ROLLBACK;
\echo === UNION ALL test: all assertions passed; transaction rolled back ===
