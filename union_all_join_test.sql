-- 0011: incremental on 0010; changes costsize.c and this sole root SQL.
-- Rebuild, install and restart the server before running.
--   psql -X -v ON_ERROR_STOP=1 -d YOUR_TEST_DB -f union_all_join_test.sql > union-all-0011.log 2>&1
-- The prototype now requires usable MCV slots on both sides of every equality.
-- Missing slots or denied operator statistics access cause whole-call fallback.
-- This is deliberately narrower eligibility, not a complete statistics model.
-- Uniform/unique/all-NULL columns without MCVs may now use the old estimates.
-- Keeps the 120-case matrix but pins the same 16 cases executed under 0010.
-- Prints actual MCV/NDV state, independent-arm estimates, and cases 7/10/40/41.
-- No promise that MCV presence resolves filtered-joinrel or multi-column errors.
-- Existing correctness checks retained; boundaries distinguish MCV/fallback inputs.
-- 2 warmups + 8 alternating measurements per mode; temporary objects, ROLLBACK.
-- The assistant has not compiled or executed this revision.
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
-- Check result counts separately, then print a compact execution summary.
-- Counting first warms this tiny fixture; timings are diagnostic, not a benchmark.
CREATE FUNCTION pg_temp.ua_ab_case(label text, query text, expected bigint)
RETURNS SETOF text LANGUAGE plpgsql AS $func$
DECLARE
    actual bigint;
    doc json;
BEGIN
    EXECUTE 'SELECT count(*) FROM (' || query || ') AS checked' INTO actual;
    IF actual <> expected THEN
        RAISE EXCEPTION '%: actual %, expected %', label, actual, expected;
    END IF;
    RAISE NOTICE '%: mode=%, join_collapse_limit=%, actual=%',
                 label, current_setting('enable_union_all_join_estimates'),
                 current_setting('join_collapse_limit'), actual;
    EXECUTE 'EXPLAIN (ANALYZE, BUFFERS, TIMING OFF, FORMAT JSON) ' || query INTO doc;
    RETURN NEXT format('%s: %s, estimate=%s, actual=%s, cost=%s, execution_ms=%s',
        label, doc->0->'Plan'->>'Node Type', doc->0->'Plan'->>'Plan Rows',
        doc->0->'Plan'->>'Actual Rows', doc->0->'Plan'->>'Total Cost',
        doc->0->>'Execution Time');
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
        -- This helper also asserts actual output count and prints a summary.
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

\echo === 0011: MCV eligibility, not merely statistics-tuple presence ===
CREATE FUNCTION pg_temp.ua_expect_mcv(p_table text, p_column text, p_expected boolean)
RETURNS void LANGUAGE plpgsql AS $func$
DECLARE
    found_mcv boolean;
BEGIN
    SELECT most_common_vals IS NOT NULL AND most_common_freqs IS NOT NULL
           AND cardinality(most_common_freqs)>0 INTO found_mcv
    FROM pg_stats WHERE schemaname=(SELECT nspname FROM pg_namespace WHERE oid=pg_my_temp_schema())
      AND tablename=p_table AND attname=p_column AND NOT inherited;
    IF NOT FOUND OR found_mcv IS DISTINCT FROM p_expected THEN
        RAISE EXCEPTION 'MCV fixture %.%: expected %, observed % (NULL can mean no stats row)',
            p_table,p_column,p_expected,found_mcv;
    END IF;
END
$func$;
CREATE FUNCTION pg_temp.ua_mcv_guard_case(p_label text, p_query text,
                                         p_expected bigint, p_fallback boolean)
RETURNS text LANGUAGE plpgsql AS $func$
DECLARE
    doc json;
    off_plan jsonb;
    on_plan jsonb;
    mode text;
    actual bigint;
    old_feature text := current_setting('enable_union_all_join_estimates');
BEGIN
    FOREACH mode IN ARRAY ARRAY['off','on'] LOOP
        PERFORM set_config('enable_union_all_join_estimates',mode,true);
        EXECUTE 'SELECT count(*) FROM ('||p_query||') q' INTO actual;
        IF actual<>p_expected THEN
            RAISE EXCEPTION '% / %: actual %, expected %',p_label,mode,actual,p_expected;
        END IF;
        EXECUTE 'EXPLAIN (FORMAT JSON) '||p_query INTO doc;
        IF mode='off' THEN off_plan:=(doc->0->'Plan')::jsonb;
        ELSE on_plan:=(doc->0->'Plan')::jsonb; END IF;
    END LOOP;
    IF p_fallback THEN
        IF off_plan IS DISTINCT FROM on_plan THEN
            RAISE EXCEPTION '%: missing-MCV fallback changed full Plan',p_label
                USING DETAIL='off='||off_plan::text||', on='||on_plan::text;
        END IF;
    ELSIF (on_plan->>'Plan Rows')::numeric<>p_expected OR
          (on_plan->>'Plan Rows')::numeric=(off_plan->>'Plan Rows')::numeric THEN
        RAISE EXCEPTION '%: expected a corrected MCV estimate %, off %, on %',
            p_label,p_expected,off_plan->>'Plan Rows',on_plan->>'Plan Rows';
    END IF;
    PERFORM set_config('enable_union_all_join_estimates',old_feature,true);
    RETURN format('PASS %s: fallback=%s, rows %s -> %s, actual=%s',
        p_label,p_fallback,off_plan->>'Plan Rows',on_plan->>'Plan Rows',actual);
END
$func$;
CREATE TEMP TABLE ua_mcv_single AS SELECT 1 AS k;
CREATE TEMP TABLE ua_mcv_four AS SELECT 1 AS k FROM generate_series(1,4);
CREATE TEMP TABLE ua_mcv_unique AS SELECT i AS k FROM generate_series(1,10) g(i);
ANALYZE ua_mcv_single;
ANALYZE ua_mcv_four;
ANALYZE ua_mcv_unique;
SELECT pg_temp.ua_expect_mcv('ua_mcv_single','k',false);
SELECT pg_temp.ua_expect_mcv('ua_mcv_four','k',true);
SELECT pg_temp.ua_expect_mcv('ua_mcv_unique','k',false);
SELECT pg_temp.ua_expect_mcv('ua_a','k',true);
SELECT pg_temp.ua_expect_mcv('ua_b','k',true);

SELECT pg_temp.ua_mcv_guard_case('single-row other input: no MCV',
    'SELECT u.k FROM ua_v u JOIN ua_mcv_single d ON u.k=d.k',100,true);
SELECT pg_temp.ua_mcv_guard_case('reversed single-row input: no MCV',
    'SELECT u.k FROM ua_mcv_single d JOIN ua_v u ON d.k=u.k',100,true);
SELECT pg_temp.ua_mcv_guard_case('one child has stats but no MCV',
    'SELECT u.k FROM (SELECT k FROM ua_a UNION ALL SELECT k FROM ua_mcv_unique) u JOIN ua_mcv_four d ON u.k=d.k',404,true);
SELECT pg_temp.ua_mcv_guard_case('both sides have MCV: retain improvement',
    'SELECT u.k FROM ua_v u JOIN ua_mcv_four d ON u.k=d.k',400,false);

-- Retain the old two-row unique-child fixture as a new fallback check.
-- The separate branch-limit fixture below now duplicates each key to have MCVs.
CREATE TEMP TABLE ua_scale_unique AS SELECT k FROM (VALUES(1),(2)) v(k);
ANALYZE ua_scale_unique;
SELECT pg_temp.ua_expect_mcv('ua_scale_unique','k',false);
SELECT pg_temp.ua_mcv_guard_case('two unique child keys without MCV',
    'SELECT u.k FROM (SELECT k FROM ua_scale_unique UNION ALL SELECT k FROM ua_scale_unique) u JOIN ua_ab_d d ON u.k=d.k',100,true);

SELECT pg_temp.ua_expect_mcv('ua_edge_a','k',true);
SELECT pg_temp.ua_expect_mcv('ua_edge_b','k',false);
SELECT pg_temp.ua_expect_mcv('ua_edge_d','k',true);
SELECT pg_temp.ua_expect_mcv('ua_edge_null','k',false);

-- ua_edge_b has distinct non-NULL values without an MCV list.
SELECT * FROM pg_temp.ua_edge_case('NULL keys, one child without MCV: fallback',
$query$SELECT u.k FROM (SELECT k FROM ua_edge_a UNION ALL SELECT k FROM ua_edge_b) u
JOIN ua_edge_d d ON u.k = d.k$query$, 6, 'unchanged');

-- Keep a value-aware nullable-input test as well.
CREATE TEMP TABLE ua_edge_b_mcv AS SELECT * FROM ua_edge_b UNION ALL SELECT * FROM ua_edge_b;
ANALYZE ua_edge_b_mcv;
SELECT pg_temp.ua_expect_mcv('ua_edge_b_mcv','k',true);
SELECT * FROM pg_temp.ua_edge_case('NULL keys with MCVs on all inputs',
$query$SELECT u.k FROM (SELECT k FROM ua_edge_a UNION ALL SELECT k FROM ua_edge_b_mcv) u
JOIN ua_edge_d d ON u.k = d.k$query$, 7, 'sum',
ARRAY['SELECT a.k FROM ua_edge_a a JOIN ua_edge_d d ON a.k = d.k',
      'SELECT b.k FROM ua_edge_b_mcv b JOIN ua_edge_d d ON b.k = d.k']);

SELECT * FROM pg_temp.ua_edge_case('all-NULL children without MCV: fallback',
$query$SELECT u.k FROM (SELECT k FROM ua_edge_null UNION ALL SELECT k FROM ua_edge_null) u
JOIN ua_edge_d d ON u.k = d.k$query$, 0, 'unchanged');

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
-- Repeated keys ensure this still tests the branch limit, not missing MCVs.
CREATE TEMP TABLE ua_scale_arm AS SELECT k FROM (VALUES (1), (1), (2), (2)) v(k);
ANALYZE ua_scale_arm;
SELECT pg_temp.ua_expect_mcv('ua_scale_arm','k',true);
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
             100::bigint * n, CASE WHEN n <= 64 THEN 'exact' ELSE 'unchanged' END);
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

\echo === 0009 plan details only for changed-plan or slower candidates ===
-- Preserve tree order, join/scan methods, predicates, per-loop row estimates,
-- actual loop counts, index selection, buffer traffic and spill evidence.
-- Buffers are inclusive of descendants: do not sum these node-level counters.
WITH RECURSIVE tree(arm_rows, case_name, mode, node_path, node) AS (
    SELECT arm_rows, case_name, mode, ARRAY[0]::int[], document->0->'Plan'
    FROM ua_perf_samples s WHERE sample_no=1 AND (
        EXISTS (SELECT 1 FROM ua_perf_samples other
                WHERE other.arm_rows=s.arm_rows AND other.case_name=s.case_name
                  AND other.mode<>s.mode AND other.shape<>s.shape)
        OR EXISTS (SELECT 1 FROM ua_perf_summary a JOIN ua_perf_summary b
                       USING (arm_rows,case_name)
                   WHERE a.arm_rows=s.arm_rows AND a.case_name=s.case_name
                     AND a.mode='off' AND b.mode='on'
                     AND b.exec_p50>=a.exec_p50*1.20 AND b.exec_p50-a.exec_p50>=1))
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
\echo === 0011: plan competition, screen first and then execute selected pairs ===
CREATE TEMP TABLE ua_comp_cases (
    case_id int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    hot_rows int, fanout int, probe_rows int, collapse_limit int,
    random_cost numeric, expected_rows bigint, query_text text
);
CREATE TEMP TABLE ua_comp_screen (
    case_id int, mode text, shape jsonb, document jsonb,
    estimated_rows numeric, total_cost numeric,
    PRIMARY KEY(case_id,mode)
);
CREATE TEMP TABLE ua_comp_samples (
    case_id int, mode text, sample_no int,
    execution_ms double precision NOT NULL, planning_ms double precision NOT NULL,
    shape jsonb NOT NULL, document jsonb NOT NULL,
    PRIMARY KEY(case_id,mode,sample_no)
);
CREATE TEMP TABLE ua_comp_correctness (
    case_id int PRIMARY KEY, result_rows bigint, bag_equal boolean
);

DO $build$
DECLARE
    hot int;
    copies int;
    downstream int;
    collapse int;
    rpc numeric;
    expected bigint;
    query_sql text;
BEGIN
    -- Coprime permutation scatters the hot prefix across downstream index
    -- keys. Keep k a stored column: expression outputs would cause fallback.
    CREATE TEMP TABLE ua_comp_b AS
        SELECT 100000+i AS id, 3 AS k FROM generate_series(1,100000) g(i);
    CREATE INDEX ON ua_comp_b(id);
    ANALYZE ua_comp_b;
    FOREACH hot IN ARRAY ARRAY[100,1000,10000,50000,90000] LOOP
        EXECUTE format('CREATE TEMP TABLE %I AS SELECT ((i*7919::bigint) %% 100000 + 1)::int AS id, CASE WHEN i<=%s THEN 1 ELSE 2 END AS k FROM generate_series(1,100000) g(i)',
            'ua_comp_a_'||hot, hot);
        EXECUTE format('CREATE INDEX ON %I(id)', 'ua_comp_a_'||hot);
        EXECUTE format('ANALYZE %I', 'ua_comp_a_'||hot);
        EXECUTE format('CREATE TEMP VIEW %I AS SELECT * FROM %I UNION ALL SELECT * FROM ua_comp_b',
            'ua_comp_u_'||hot, 'ua_comp_a_'||hot);
    END LOOP;
    FOREACH copies IN ARRAY ARRAY[1,4] LOOP
        EXECUTE format('CREATE TEMP TABLE %I AS SELECT 1 AS k, i AS tag FROM generate_series(1,%s) g(i)',
            'ua_comp_d_'||copies, copies);
        EXECUTE format('ANALYZE %I', 'ua_comp_d_'||copies);
    END LOOP;
    FOREACH downstream IN ARRAY ARRAY[20000,400000] LOOP
        -- Padding increases heap access cost, even though only v is projected.
        EXECUTE format('CREATE TEMP TABLE %I AS SELECT i AS id, i %% 97 AS v, repeat(''p'',64) AS padding FROM generate_series(1,%s) g(i)',
            'ua_comp_p_'||downstream, downstream);
        EXECUTE format('ALTER TABLE %I ADD PRIMARY KEY(id)', 'ua_comp_p_'||downstream);
        EXECUTE format('ANALYZE %I', 'ua_comp_p_'||downstream);
    END LOOP;
    FOREACH hot IN ARRAY ARRAY[100,1000,10000,50000,90000] LOOP
        FOREACH copies IN ARRAY ARRAY[1,4] LOOP
            FOREACH downstream IN ARRAY ARRAY[20000,400000] LOOP
                -- Independent fixture arithmetic, without consulting join estimates.
                SELECT count(*)*copies INTO expected
                FROM generate_series(1,hot) g(i)
                WHERE (i*7919::bigint)%100000+1<=downstream;
                query_sql := format('SELECT u.id, d.tag, p.v FROM %I u JOIN %I d ON u.k=d.k JOIN %I p ON u.id=p.id',
                    'ua_comp_u_'||hot, 'ua_comp_d_'||copies, 'ua_comp_p_'||downstream);
                FOREACH collapse IN ARRAY ARRAY[1,8] LOOP
                    FOREACH rpc IN ARRAY ARRAY[1.1,4,8]::numeric[] LOOP
                        INSERT INTO ua_comp_cases(hot_rows,fanout,probe_rows,collapse_limit,
                            random_cost,expected_rows,query_text)
                        VALUES(hot,copies,downstream,collapse,rpc,expected,query_sql);
                    END LOOP;
                END LOOP;
            END LOOP;
        END LOOP;
    END LOOP;
END
$build$;

\echo === 0011 actual column statistics (n_distinct is raw pg_stats notation) ===
SELECT tablename,attname,null_frac,n_distinct,
       most_common_vals IS NOT NULL AS has_mcv,
       coalesce(cardinality(most_common_freqs),0) AS mcv_items,
       left(most_common_vals::text,120) AS mcv_values,
       most_common_freqs AS mcv_freqs
FROM pg_stats
WHERE schemaname=(SELECT nspname FROM pg_namespace WHERE oid=pg_my_temp_schema())
  AND NOT inherited AND
      ((tablename LIKE 'ua_comp_a_%' AND attname='k') OR
       (tablename IN ('ua_comp_b','ua_comp_d_1','ua_comp_d_4') AND attname='k') OR
       (tablename IN ('ua_comp_p_20000','ua_comp_p_400000') AND attname='id'))
ORDER BY tablename,attname;
SELECT pg_temp.ua_expect_mcv('ua_comp_d_1','k',false);
SELECT pg_temp.ua_expect_mcv('ua_comp_d_4','k',true);
SELECT pg_temp.ua_expect_mcv('ua_comp_a_100','k',true);
SELECT pg_temp.ua_expect_mcv('ua_comp_a_1000','k',true);
SELECT pg_temp.ua_expect_mcv('ua_comp_b','k',true);
SELECT pg_temp.ua_expect_mcv('ua_comp_p_20000','id',false);
SELECT pg_temp.ua_expect_mcv('ua_comp_p_400000','id',false);

-- Planning-only diagnostic: isolate the first join from subsequent join order
-- and parameterized paths. A very large independent-arm sum with a one-row
-- dimension would demonstrate the underlying eqjoinsel limitation, rather
-- than treating every bad sum as a translation or cache bug.
CREATE FUNCTION pg_temp.ua_mcv_probe(p_hot int, p_fanout int)
RETURNS TABLE(hot_rows int, fanout int, mode text, union_estimate numeric,
              arm_a_estimate numeric, arm_b_estimate numeric,
              arm_sum numeric, known_actual bigint)
LANGUAGE plpgsql AS $func$
DECLARE
    old_feature text:=current_setting('enable_union_all_join_estimates');
    off_estimate numeric;
BEGIN
    hot_rows:=p_hot;
    fanout:=p_fanout;
    known_actual:=p_hot::bigint*p_fanout;
    FOREACH mode IN ARRAY ARRAY['off','on'] LOOP
        PERFORM set_config('enable_union_all_join_estimates',mode,true);
        union_estimate:=pg_temp.ua_estimate(format(
            'SELECT u.id FROM %I u JOIN %I d ON u.k=d.k',
            'ua_comp_u_'||p_hot,'ua_comp_d_'||p_fanout));
        arm_a_estimate:=pg_temp.ua_estimate(format(
            'SELECT a.id FROM %I a JOIN %I d ON a.k=d.k',
            'ua_comp_a_'||p_hot,'ua_comp_d_'||p_fanout));
        arm_b_estimate:=pg_temp.ua_estimate(format(
            'SELECT b.id FROM ua_comp_b b JOIN %I d ON b.k=d.k',
            'ua_comp_d_'||p_fanout));
        arm_sum:=arm_a_estimate+arm_b_estimate;
        IF mode='off' THEN off_estimate:=union_estimate;
        ELSIF p_fanout=1 AND union_estimate<>off_estimate THEN
            RAISE EXCEPTION '0011 single-row MCV guard failed for hot_rows %',p_hot;
        ELSIF p_fanout=4 AND (abs(union_estimate-known_actual)>2 OR
                              abs(union_estimate-arm_sum)>2) THEN
            RAISE EXCEPTION '0011 both-MCV estimate lost: hot %, estimate %, actual %, arm sum %',
                p_hot,union_estimate,known_actual,arm_sum;
        END IF;
        RETURN NEXT;
    END LOOP;
    PERFORM set_config('enable_union_all_join_estimates',old_feature,true);
END
$func$;
\echo === 0011 isolated first join: union versus independently planned children ===
SELECT d.* FROM (VALUES(100,1),(100,4),(1000,1),(1000,4)) c(hot,copies)
CROSS JOIN LATERAL pg_temp.ua_mcv_probe(c.hot,c.copies) d ORDER BY hot_rows,fanout,mode;

-- Record and restore settings so the screen and every timed pair use identical
-- costs and join-search limits. All algorithms remain available in both modes.
DO $screen$
DECLARE
    c record;
    mode text;
    doc json;
    old_feature text := current_setting('enable_union_all_join_estimates');
    old_collapse text := current_setting('join_collapse_limit');
    old_rpc text := current_setting('random_page_cost');
BEGIN
    FOR c IN SELECT * FROM ua_comp_cases ORDER BY case_id LOOP
        PERFORM set_config('join_collapse_limit',c.collapse_limit::text,true);
        PERFORM set_config('random_page_cost',c.random_cost::text,true);
        FOREACH mode IN ARRAY ARRAY['off','on'] LOOP
            PERFORM set_config('enable_union_all_join_estimates',mode,true);
            EXECUTE 'EXPLAIN (FORMAT JSON) '||c.query_text INTO doc;
            INSERT INTO ua_comp_screen VALUES(c.case_id,mode,
                pg_temp.ua_plan_shape((doc->0->'Plan')::jsonb),doc::jsonb,
                (doc->0->'Plan'->>'Plan Rows')::numeric,
                (doc->0->'Plan'->>'Total Cost')::numeric);
        END LOOP;
    END LOOP;
    PERFORM set_config('enable_union_all_join_estimates',old_feature,true);
    PERFORM set_config('join_collapse_limit',old_collapse,true);
    PERFORM set_config('random_page_cost',old_rpc,true);
END
$screen$;

CREATE TEMP VIEW ua_comp_pairs AS
SELECT c.*, a.shape<>b.shape AS plan_changed,
       a.estimated_rows AS off_rows,b.estimated_rows AS on_rows,
       a.total_cost AS off_cost,b.total_cost AS on_cost,
       a.document->0->'Plan'->>'Node Type' AS off_root,
       b.document->0->'Plan'->>'Node Type' AS on_root,
       CASE WHEN b.estimated_rows>a.estimated_rows THEN 'estimate_up'
            WHEN b.estimated_rows<a.estimated_rows THEN 'estimate_down'
            ELSE 'estimate_same' END AS estimate_direction
FROM ua_comp_cases c JOIN ua_comp_screen a USING(case_id)
JOIN ua_comp_screen b USING(case_id) WHERE a.mode='off' AND b.mode='on';

-- Both join keys on the other inputs lack MCVs in the single-row family
-- (d.k and p.id), so every union estimate attempt must fall back. Compare
-- entire Plan objects, including costs/rows, for all 60 such screen pairs.
DO $guard$
BEGIN
    IF (SELECT count(*) FROM ua_comp_cases WHERE fanout=1)<>60 OR EXISTS (
        SELECT 1 FROM ua_comp_cases c JOIN ua_comp_screen a USING(case_id)
        JOIN ua_comp_screen b USING(case_id)
        WHERE c.fanout=1 AND a.mode='off' AND b.mode='on'
          AND (a.document->0->'Plan') IS DISTINCT FROM (b.document->0->'Plan')
    ) THEN
        RAISE EXCEPTION '0011 single-row family: full-plan fallback mismatch';
    END IF;
    RAISE NOTICE '0011 PASS: all 60 single-row-dimension Plan pairs identical';
END
$guard$;

-- Pin the original 0010 execution cohort. Repaired cases must not disappear
-- from execution merely because their plans no longer differ.
CREATE TEMP TABLE ua_comp_selected AS
SELECT case_id, CASE WHEN case_id IN (13,14,16,17) THEN '0010 improvement'
                     WHEN case_id IN (19,37,43,61) THEN '0010 control'
                     ELSE '0010 regression' END AS selection_reason
FROM ua_comp_cases WHERE case_id IN (1,2,4,7,8,10,13,14,16,17,19,37,40,41,43,61);
ALTER TABLE ua_comp_selected ADD PRIMARY KEY(case_id);

\echo === 0011 screen coverage (planning only for unselected cases) ===
SELECT collapse_limit,random_cost,count(*) AS screened,
       count(*) FILTER(WHERE plan_changed) AS changed,
       count(*) FILTER(WHERE NOT plan_changed) AS unchanged,
       count(*) FILTER(WHERE case_id IN (SELECT case_id FROM ua_comp_selected)) AS selected
FROM ua_comp_pairs GROUP BY collapse_limit,random_cost ORDER BY collapse_limit,random_cost;

\echo === 0011 selected workload parameters / root estimates (not timing results) ===
SELECT p.case_id,s.selection_reason,p.hot_rows,p.fanout,p.probe_rows,p.collapse_limit,
       p.random_cost,p.off_root,p.on_root,p.off_rows,p.on_rows,p.expected_rows,
       p.off_cost,p.on_cost
FROM ua_comp_pairs p JOIN ua_comp_selected s USING(case_id) ORDER BY p.case_id;

DO $coverage$
BEGIN
    IF (SELECT count(*) FROM ua_comp_cases)<>120 OR
       (SELECT count(*) FROM ua_comp_screen)<>240 THEN
        RAISE EXCEPTION '0011 incomplete plan screen';
    END IF;
    IF NOT EXISTS(SELECT 1 FROM ua_comp_pairs WHERE plan_changed) THEN
        RAISE NOTICE 'COVERAGE NOTE: no current plan switches; fixed 0010 cohort still checks the repaired cases';
    END IF;
END
$coverage$;

DO $execute$
DECLARE
    c record;
    sample int;
    mode text;
    modes text[];
    doc json;
    different boolean;
    off_count bigint;
    on_count bigint;
    old_feature text := current_setting('enable_union_all_join_estimates');
    old_collapse text := current_setting('join_collapse_limit');
    old_rpc text := current_setting('random_page_cost');
BEGIN
    FOR c IN SELECT p.* FROM ua_comp_cases p JOIN ua_comp_selected s USING(case_id)
             ORDER BY p.case_id LOOP
        PERFORM set_config('join_collapse_limit',c.collapse_limit::text,true);
        PERFORM set_config('random_page_cost',c.random_cost::text,true);
        PERFORM set_config('enable_union_all_join_estimates','off',true);
        EXECUTE 'CREATE TEMP TABLE ua_comp_off AS '||c.query_text;
        PERFORM set_config('enable_union_all_join_estimates','on',true);
        EXECUTE 'CREATE TEMP TABLE ua_comp_on AS '||c.query_text;
        SELECT count(*) INTO off_count FROM ua_comp_off;
        SELECT count(*) INTO on_count FROM ua_comp_on;
        SELECT EXISTS(SELECT 1 FROM (
            (SELECT * FROM ua_comp_off EXCEPT ALL SELECT * FROM ua_comp_on)
            UNION ALL
            (SELECT * FROM ua_comp_on EXCEPT ALL SELECT * FROM ua_comp_off)
        ) delta) INTO different;
        IF different OR off_count<>c.expected_rows OR on_count<>c.expected_rows THEN
            RAISE EXCEPTION '0011 case %: bag mismatch %, off %, on %, expected %',
                c.case_id,different,off_count,on_count,c.expected_rows;
        END IF;
        INSERT INTO ua_comp_correctness VALUES(c.case_id,on_count,true);
        DROP TABLE ua_comp_off,ua_comp_on;
        RAISE NOTICE '0011 case %: exact result PASS (% rows); measuring',c.case_id,on_count;
        FOR sample IN 1..10 LOOP
            modes := CASE WHEN sample%2=1 THEN ARRAY['off','on'] ELSE ARRAY['on','off'] END;
            FOREACH mode IN ARRAY modes LOOP
                PERFORM set_config('enable_union_all_join_estimates',mode,true);
                EXECUTE 'EXPLAIN (ANALYZE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON) '
                    ||c.query_text INTO doc;
                IF (doc->0->'Plan'->>'Actual Rows')::numeric<>c.expected_rows OR
                   (doc->0->'Plan'->>'Actual Loops')::numeric<>1 THEN
                    RAISE EXCEPTION '0011 case % / %: measured rows/loops mismatch',c.case_id,mode;
                END IF;
                IF sample>2 THEN
                    INSERT INTO ua_comp_samples VALUES(c.case_id,mode,sample-2,
                        (doc->0->>'Execution Time')::double precision,
                        (doc->0->>'Planning Time')::double precision,
                        pg_temp.ua_plan_shape((doc->0->'Plan')::jsonb),doc::jsonb);
                END IF;
            END LOOP;
        END LOOP;
    END LOOP;
    PERFORM set_config('enable_union_all_join_estimates',old_feature,true);
    PERFORM set_config('join_collapse_limit',old_collapse,true);
    PERFORM set_config('random_page_cost',old_rpc,true);
END
$execute$;

CREATE TEMP VIEW ua_comp_summary AS
SELECT case_id,mode,count(*) AS samples,
       percentile_cont(0.5) WITHIN GROUP(ORDER BY execution_ms) AS p50,
       percentile_cont(0.95) WITHIN GROUP(ORDER BY execution_ms) AS p95,
       percentile_cont(0.5) WITHIN GROUP(ORDER BY execution_ms+planning_ms) AS total_p50,
       count(DISTINCT shape) AS variants
FROM ua_comp_samples GROUP BY case_id,mode;
CREATE TEMP VIEW ua_comp_result AS
WITH paired AS (
    SELECT a.case_id, bool_or(a.shape<>b.shape) AS measured_switch,
           percentile_cont(0.5) WITHIN GROUP(ORDER BY b.execution_ms/nullif(a.execution_ms,0)) AS paired_ratio,
           count(*) FILTER(WHERE b.execution_ms>a.execution_ms) AS slower_pairs
    FROM ua_comp_samples a JOIN ua_comp_samples b USING(case_id,sample_no)
    WHERE a.mode='off' AND b.mode='on' GROUP BY a.case_id
)
SELECT p.case_id,p.plan_changed AS screened_switch, r.measured_switch,
       a.p50 AS off_ms,b.p50 AS on_ms,a.p95 AS off_p95,b.p95 AS on_p95,
       b.p50-a.p50 AS delta_ms,100*(b.p50/nullif(a.p50,0)-1) AS delta_pct,
       a.p50/nullif(b.p50,0) AS speedup_off_div_on,r.paired_ratio,r.slower_pairs,
       b.total_p50-a.total_p50 AS total_delta_ms,
       CASE WHEN a.variants>1 OR b.variants>1 THEN 'REVIEW: unstable plan signature'
            WHEN EXISTS(SELECT 1 FROM ua_comp_samples x JOIN ua_comp_screen y USING(case_id,mode)
                        WHERE x.case_id=p.case_id AND x.shape<>y.shape)
                THEN 'REVIEW: execution plan differs from screen'
            WHEN b.p50>=a.p50*1.2 AND b.p50-a.p50>=1
                THEN CASE WHEN r.measured_switch THEN 'REVIEW: possible plan regression'
                          ELSE 'REVIEW: slower with same plan signature' END
            WHEN b.p50<=a.p50*0.8 AND a.p50-b.p50>=1 THEN 'observed improvement'
            ELSE 'below timing screen' END AS assessment
FROM ua_comp_pairs p JOIN ua_comp_summary a USING(case_id)
JOIN ua_comp_summary b USING(case_id) JOIN paired r USING(case_id)
WHERE a.mode='off' AND b.mode='on';

\echo === 0011 timing: positive delta = slower; speedup >1 = faster ===
SELECT case_id,screened_switch,measured_switch,
       round(off_ms::numeric,3) AS off_ms,round(on_ms::numeric,3) AS on_ms,
       round(off_p95::numeric,3) AS off_p95_ms,round(on_p95::numeric,3) AS on_p95_ms,
       round(delta_ms::numeric,3) AS delta_ms,round(delta_pct::numeric,1) AS delta_pct,
       round(speedup_off_div_on::numeric,2) AS speedup_off_div_on,
       round(paired_ratio::numeric,2) AS paired_on_div_off,slower_pairs,
       round(total_delta_ms::numeric,3) AS plan_plus_exec_delta_ms,assessment
FROM ua_comp_result ORDER BY delta_ms DESC,case_id;

-- Always expose the two worst single-row cases and the previously omitted
-- four-row/free-order cases, even if they become unchanged or improve.
CREATE TEMP TABLE ua_comp_details AS
SELECT case_id FROM ua_comp_result WHERE case_id IN (7,10,40,41);
\echo === 0011 pinned plan details: cases 7/10/40/41, sample 1 ===
WITH RECURSIVE tree(case_id,mode,node_path,node) AS (
    SELECT s.case_id,s.mode,ARRAY[0]::int[],s.document->0->'Plan'
    FROM ua_comp_samples s JOIN ua_comp_details d USING(case_id) WHERE s.sample_no=1
    UNION ALL
    SELECT t.case_id,t.mode,t.node_path||p.ord::int,p.node
    FROM tree t CROSS JOIN LATERAL jsonb_array_elements(
        coalesce(t.node->'Plans','[]'::jsonb)) WITH ORDINALITY p(node,ord)
)
SELECT case_id,mode,node_path,node->>'Plan Rows' AS estimated_rows,
       node->>'Actual Rows' AS actual_rows_per_loop,node->>'Actual Loops' AS loops,
       node->>'Total Cost' AS total_cost,node->>'Local Hit Blocks' AS local_hits,
       node->>'Local Read Blocks' AS local_reads,node->>'Temp Written Blocks' AS temp_writes,
       node->>'Hash Batches' AS hash_batches,pg_temp.ua_plan_shape(node)-'Plans' AS node_details
FROM tree ORDER BY case_id,mode,node_path;

DO $complete$
DECLARE
    chosen int := (SELECT count(*) FROM ua_comp_selected);
BEGIN
    IF chosen<>16 OR
       (SELECT count(*) FROM ua_comp_correctness WHERE bag_equal)<>chosen OR
       (SELECT count(*) FROM ua_comp_samples)<>chosen*16 OR
       (SELECT count(*) FROM ua_comp_summary)<>chosen*2 OR
       EXISTS(SELECT 1 FROM ua_comp_summary WHERE samples<>8) THEN
        RAISE EXCEPTION '0011 incomplete execution samples';
    END IF;
    RAISE NOTICE '0011 complete: % screened, % screened switches, % executed pairs, % measured switches. Unselected cases were NOT executed.',
        (SELECT count(*) FROM ua_comp_pairs),
        (SELECT count(*) FROM ua_comp_pairs WHERE plan_changed),chosen,
        (SELECT count(*) FROM ua_comp_result WHERE measured_switch);
END
$complete$;

ROLLBACK;
\echo === UNION ALL test: all assertions passed; review timing and plan-switch coverage above ===
