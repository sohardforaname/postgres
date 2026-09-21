-- Singleton GROUP BY review: PostgreSQL baseline versus v1 patches 0001+0002.
-- Source thread:
-- https://www.postgresql.org/message-id/flat/tencent_4DDFEE26EA4A2E1BA967729AF20822D61207%40qq.com
-- Generated 2026-09-20. Static review only; not executed against PostgreSQL here.
--
-- Run in a dedicated test database on each build, at the SAME base commit.
-- First pass creates a fresh sg_review schema and runs the cases:
--   psql -X -p 5432 -d review -v label=baseline -f benchmark.sql > baseline.log 2>&1
--   psql -X -p 5433 -d review -v label=patched  -f benchmark.sql > patched.log 2>&1
-- Repeat without setup; discard the first pass and compare >=5 measured passes:
--   psql -X -p 5432 -d review -v setup=0 -v label=baseline-r2 -f benchmark.sql > baseline-r2.log 2>&1
-- Optional scan diagnostics, not part of the default-plan comparison:
--   psql -X -p 5433 -d review -v setup=0 -v probes=1 -v label=patched-probes -f benchmark.sql > probes.log 2>&1
-- Optional larger setup: -v n=1000000 (only used when setup=1).
-- setup=1 deliberately FAILS if sg_review already exists; it does not drop data.
-- Tables are ordinary tables, not TEMP: parallel paths must remain available.
-- Approximate default table+index footprint: several hundred MB; n=1M is >1GB.
-- VACUUM ANALYZE is deliberate: the wide heap versus narrow index-only scan
-- comparison needs all-visible pages. This is a warm-cache test by default;
-- shared read blocks do not prove physical disk reads (OS cache may serve them).
-- Do not run the two clusters' measured queries concurrently.
--
-- Interpretation:
--  * Same case, same settings, patched/base median >1 means slower (check noise).
--  * A faster no-GROUP-BY control shows remaining opportunity, not necessarily
--    a regression. Do not use HAVING true / count(*) as timing baselines.
--  * Compare Execution Time, Planning Time, rows, buffers, Sort/Hash spill,
--    Heap Fetches, Workers Planned/Launched, and VERBOSE Output expressions.
--  * TIMING OFF avoids per-node clock overhead but retains total execution time.
--    If a case regresses, rerun ONLY that case with TIMING ON to localize it.
--  * EXPLAIN ANALYZE executes target expressions, without sending all result
--    rows to the client. Do not wrap performance queries in SELECT count(*).
--  * ProjectionPath need not become a separate Result execution node.
--  * Full-consumption sequence cases have exact call-count checks. LIMIT cases
--    report observations only: blocking/streaming plans can consume different
--    numbers of input rows, so call-count differences alone are not a bug.
--  * Function COST affects estimates, not actual runtime. slow_i and slow_v
--    have the same real work and cost; the latter deliberately has no side
--    effects, so PARALLEL SAFE is valid even though it is marked VOLATILE.
--  * A boolean *_ok=false is a correctness candidate; compare both builds.
--  * No server settings are changed globally. SETs affect this connection only.

\set ON_ERROR_STOP on
\pset pager off
\timing on
\if :{?setup}
\else
\set setup 1
\endif
\if :{?probes}
\else
\set probes 0
\endif
\if :{?n}
\else
\set n 300000
\endif
\if :{?label}
\else
\set label unlabelled
\endif

SET jit = off;
SET max_parallel_workers_per_gather = 0;
SET work_mem = '32MB';
SET enable_partitionwise_aggregate = off;
SET search_path = sg_review, pg_catalog;

\echo '=== Run label:' :label '==='
SELECT version();
SELECT name, setting, unit FROM pg_settings
WHERE name IN ('block_size', 'shared_buffers', 'effective_cache_size',
 'seq_page_cost', 'random_page_cost', 'cpu_tuple_cost', 'cpu_operator_cost',
 'work_mem', 'jit', 'max_worker_processes', 'max_parallel_workers',
 'max_parallel_workers_per_gather', 'parallel_setup_cost',
 'parallel_tuple_cost', 'min_parallel_table_scan_size',
 'min_parallel_index_scan_size', 'enable_hashagg', 'enable_seqscan',
 'enable_indexscan', 'enable_indexonlyscan', 'enable_bitmapscan',
 'enable_partition_pruning', 'enable_partitionwise_aggregate',
 'enable_group_by_reordering', 'enable_incremental_sort', 'track_io_timing')
ORDER BY name;

\if :setup
\echo '=== Setup (excluded from timings) ==='
DROP SCHEMA IF EXISTS sg_review CASCADE;
CREATE SCHEMA sg_review;

CREATE TABLE wide_heap (
    id integer PRIMARY KEY,
    rank_key integer NOT NULL,
    payload text NOT NULL
);
-- Prevent TOAST/compression from hiding the intended wide-heap scan cost.
ALTER TABLE wide_heap ALTER COLUMN payload SET STORAGE PLAIN;
INSERT INTO wide_heap
SELECT g, ((g::bigint * 48271) % 2147483647)::integer,
       repeat(md5(g::text), 32)
FROM generate_series(1, :n) AS s(g);
CREATE INDEX wide_heap_rank_id ON wide_heap (rank_key, id);
VACUUM (ANALYZE) wide_heap;

CREATE TABLE part_heap (
    bucket integer NOT NULL,
    id integer NOT NULL,
    rank_key integer NOT NULL,
    payload text NOT NULL,
    PRIMARY KEY (bucket, id)
) PARTITION BY RANGE (bucket);
ALTER TABLE part_heap ALTER COLUMN payload SET STORAGE PLAIN;
CREATE TABLE part_heap_0 PARTITION OF part_heap FOR VALUES FROM (0) TO (1);
CREATE TABLE part_heap_1 PARTITION OF part_heap FOR VALUES FROM (1) TO (2);
CREATE TABLE part_heap_2 PARTITION OF part_heap FOR VALUES FROM (2) TO (3);
CREATE TABLE part_heap_3 PARTITION OF part_heap FOR VALUES FROM (3) TO (4);
CREATE TABLE part_heap_4 PARTITION OF part_heap FOR VALUES FROM (4) TO (5);
CREATE TABLE part_heap_5 PARTITION OF part_heap FOR VALUES FROM (5) TO (6);
CREATE TABLE part_heap_6 PARTITION OF part_heap FOR VALUES FROM (6) TO (7);
CREATE TABLE part_heap_7 PARTITION OF part_heap FOR VALUES FROM (7) TO (8);
INSERT INTO part_heap
SELECT (g - 1) % 8, (g - 1) / 8 + 1,
       ((g::bigint * 48271) % 2147483647)::integer,
       repeat(md5(g::text), 32)
FROM generate_series(1, :n) AS s(g);
CREATE INDEX part_heap_rank_id ON part_heap (rank_key, bucket, id);
VACUUM (ANALYZE) part_heap;
-- Explicit parent statistics, independent of autovacuum's parent handling.
ANALYZE part_heap;

-- Same function implementation, different volatility classification.
-- PL/pgSQL avoids SQL-function inlining; these are test expressions, not
-- a benchmark runner or dynamic-SQL abstraction.
CREATE FUNCTION slow_i(p text) RETURNS text
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE COST 100 AS $$
DECLARE r text := p;
BEGIN
    FOR i IN 1..8 LOOP
        r := md5(p || r);
    END LOOP;
    RETURN r;
END
$$;
CREATE FUNCTION slow_v(p text) RETURNS text
LANGUAGE plpgsql VOLATILE STRICT PARALLEL SAFE COST 100 AS $$
DECLARE r text := p;
BEGIN
    FOR i IN 1..8 LOOP
        r := md5(p || r);
    END LOOP;
    RETURN r;
END
$$;

CREATE TABLE tiny (id integer PRIMARY KEY, payload text);
INSERT INTO tiny SELECT g, 'v' || g FROM generate_series(1, 32) s(g);
CREATE SEQUENCE expr_calls CACHE 1;

CREATE TABLE tiny_part (bucket integer, id integer, PRIMARY KEY (bucket, id))
PARTITION BY RANGE (bucket);
CREATE TABLE tiny_part_0 PARTITION OF tiny_part FOR VALUES FROM (0) TO (1);
CREATE TABLE tiny_part_1 PARTITION OF tiny_part FOR VALUES FROM (1) TO (2);
INSERT INTO tiny_part SELECT b, g FROM generate_series(0, 1) s(b),
    generate_series(1, 16) t(g);

CREATE TABLE nullable_key (a integer NOT NULL, b integer, UNIQUE (a, b));
INSERT INTO nullable_key VALUES (1, NULL), (1, NULL);
CREATE TABLE nnd_key (a integer, b integer, UNIQUE NULLS NOT DISTINCT (a, b));
INSERT INTO nnd_key VALUES (1, NULL), (NULL, 1), (NULL, NULL);
CREATE TABLE inherited_parent (id integer PRIMARY KEY);
CREATE TABLE inherited_child () INHERITS (inherited_parent);
INSERT INTO inherited_parent VALUES (1);
INSERT INTO inherited_child VALUES (1);
\endif

\echo '=== Data sizes (excluded from timings) ==='
SELECT count(*) AS heap_rows FROM wide_heap;
SELECT pg_size_pretty(pg_relation_size('wide_heap')) AS heap_size,
       pg_size_pretty(pg_relation_size('wide_heap_pkey')) AS pk_size,
       pg_size_pretty(pg_relation_size('wide_heap_rank_id')) AS ordered_index_size;
SELECT tableoid::regclass AS partition, count(*) AS rows
FROM part_heap GROUP BY tableoid ORDER BY 1;

\echo '=== A1: narrow output over wide heap; index-only versus seq scan ==='
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SETTINGS, TIMING OFF, SUMMARY ON)
SELECT id FROM wide_heap GROUP BY id;

\echo '=== A2: grouping and ORDER BY share key, LIMIT 10 ==='
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SETTINGS, TIMING OFF, SUMMARY ON)
SELECT id FROM wide_heap GROUP BY id ORDER BY id LIMIT 10;

\echo '=== A3: grouping key differs from useful ORDER BY index, LIMIT 10 ==='
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SETTINGS, TIMING OFF, SUMMARY ON)
SELECT id, rank_key FROM wide_heap
GROUP BY id, rank_key ORDER BY rank_key, id LIMIT 10;

\echo '=== A3-control: manually remove redundant GROUP BY ==='
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SETTINGS, TIMING OFF, SUMMARY ON)
SELECT id, rank_key FROM wide_heap ORDER BY rank_key, id LIMIT 10;

\echo '=== A4: selective index predicate, approximately one percent ==='
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SETTINGS, TIMING OFF, SUMMARY ON)
SELECT id, rank_key FROM wide_heap
WHERE rank_key < 21474836 GROUP BY id, rank_key;

\echo '=== A5: wide output and different ordering, LIMIT 100 ==='
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SETTINGS, TIMING OFF, SUMMARY ON)
SELECT id, rank_key, payload FROM wide_heap
GROUP BY id, rank_key, payload ORDER BY rank_key, id LIMIT 100;

\if :probes
\echo '=== A1-probe-seq: diagnostic forced preference, not auto-plan result ==='
BEGIN;
SET LOCAL enable_indexscan = off;
SET LOCAL enable_indexonlyscan = off;
SET LOCAL enable_bitmapscan = off;
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SETTINGS, TIMING OFF, SUMMARY ON)
SELECT id FROM wide_heap GROUP BY id;
ROLLBACK;
\echo '=== A1-probe-index: diagnostic forced preference, not auto-plan result ==='
BEGIN;
SET LOCAL enable_seqscan = off;
SET LOCAL enable_bitmapscan = off;
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SETTINGS, TIMING OFF, SUMMARY ON)
SELECT id FROM wide_heap GROUP BY id;
ROLLBACK;
\endif

\echo '=== B0-control: immutable expensive projection, no grouping ==='
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SETTINGS, TIMING OFF, SUMMARY ON)
SELECT id, slow_i(payload) AS v FROM wide_heap;

\echo '=== B1: immutable expensive expression only in output ==='
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SETTINGS, TIMING OFF, SUMMARY ON)
SELECT id, slow_i(payload) AS v FROM wide_heap GROUP BY id;

\echo '=== B2: same immutable expression is also a grouping key ==='
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SETTINGS, TIMING OFF, SUMMARY ON)
SELECT id, slow_i(payload) AS v FROM wide_heap GROUP BY id, v;

\echo '=== B3: volatile expensive expression only in output ==='
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SETTINGS, TIMING OFF, SUMMARY ON)
SELECT id, slow_v(payload) AS v FROM wide_heap GROUP BY id;

\echo '=== B4: same volatile expression is also a grouping key ==='
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SETTINGS, TIMING OFF, SUMMARY ON)
SELECT id, slow_v(payload) AS v FROM wide_heap GROUP BY id, v;

\echo '=== B5: four independent expensive outputs ==='
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SETTINGS, TIMING OFF, SUMMARY ON)
SELECT id, slow_v(payload || 'a'), slow_v(payload || 'b'),
       slow_v(payload || 'c'), slow_v(payload || 'd')
FROM wide_heap GROUP BY id;

\echo '=== B6: expensive output, alternate ORDER BY, LIMIT 10 ==='
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SETTINGS, TIMING OFF, SUMMARY ON)
SELECT id, rank_key, slow_v(payload) AS v FROM wide_heap
GROUP BY id, rank_key ORDER BY rank_key, id LIMIT 10;

\echo '=== B7: expensive expression also groups, alternate ORDER BY, LIMIT 10 ==='
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SETTINGS, TIMING OFF, SUMMARY ON)
SELECT id, rank_key, slow_v(payload) AS v FROM wide_heap
GROUP BY id, rank_key, v ORDER BY rank_key, id LIMIT 10;

\echo '=== B7-control: same expression needed for ORDER BY, LIMIT 10 ==='
-- This is an evaluation-placement probe, not an equivalent timing baseline
-- for B6/B7. Sorting by v makes the expression necessary for all candidates.
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SETTINGS, TIMING OFF, SUMMARY ON)
SELECT id, slow_v(payload) AS v FROM wide_heap
GROUP BY id, v ORDER BY v, id LIMIT 10;

\echo '=== V1: output-only nextval, full consumption, exactly 32 calls ==='
ALTER SEQUENCE expr_calls RESTART WITH 1;
SELECT id, nextval('expr_calls') AS v FROM tiny GROUP BY id ORDER BY id;
SELECT last_value, is_called, is_called AND last_value = 32 AS calls_ok
FROM expr_calls;

\echo '=== V2: output/group/order reference the same value, exactly 32 calls ==='
ALTER SEQUENCE expr_calls RESTART WITH 1;
SELECT id, nextval('expr_calls') AS v FROM tiny GROUP BY id, v ORDER BY v, id;
SELECT last_value, is_called, is_called AND last_value = 32 AS calls_ok
FROM expr_calls;

\echo '=== V3: resjunk volatile grouping expression, exactly 32 calls ==='
ALTER SEQUENCE expr_calls RESTART WITH 1;
SELECT id FROM tiny GROUP BY id, nextval('expr_calls') ORDER BY id;
SELECT last_value, is_called, is_called AND last_value = 32 AS calls_ok
FROM expr_calls;

\echo '=== V4: zero qualifying rows must not evaluate nextval ==='
ALTER SEQUENCE expr_calls RESTART WITH 1;
SELECT id, nextval('expr_calls') AS v FROM tiny
WHERE id < 0 GROUP BY id, v;
SELECT last_value, is_called, NOT is_called AS zero_calls_ok FROM expr_calls;

\echo '=== V5: LIMIT observation; no fixed call-count assertion ==='
ALTER SEQUENCE expr_calls RESTART WITH 1;
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SETTINGS, TIMING OFF, SUMMARY ON)
SELECT id, nextval('expr_calls') AS v FROM tiny
GROUP BY id, v ORDER BY id LIMIT 3;
SELECT last_value, is_called FROM expr_calls;

\echo '=== V6: LIMIT and resjunk grouping expression; observation only ==='
ALTER SEQUENCE expr_calls RESTART WITH 1;
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SETTINGS, TIMING OFF, SUMMARY ON)
SELECT id FROM tiny GROUP BY id, nextval('expr_calls') ORDER BY id LIMIT 3;
SELECT last_value, is_called FROM expr_calls;

\echo '=== V7: partition Append, full consumption, exactly 32 calls ==='
ALTER SEQUENCE expr_calls RESTART WITH 1;
SELECT bucket, id, nextval('expr_calls') AS v FROM tiny_part
GROUP BY bucket, id, v ORDER BY bucket, id;
SELECT last_value, is_called, is_called AND last_value = 32 AS calls_ok
FROM expr_calls;

\echo '=== V8: pruned partition, full consumption, exactly 16 calls ==='
ALTER SEQUENCE expr_calls RESTART WITH 1;
SELECT bucket, id FROM tiny_part WHERE bucket = 1
GROUP BY bucket, id, nextval('expr_calls') ORDER BY bucket, id;
SELECT last_value, is_called, is_called AND last_value = 16 AS calls_ok
FROM expr_calls;

\echo '=== P1: complete partition-wide key, all eight partitions ==='
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SETTINGS, TIMING OFF, SUMMARY ON)
SELECT bucket, id FROM part_heap GROUP BY bucket, id;

\echo '=== P2: one partition; bucket can be simplified by equivalence processing ==='
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SETTINGS, TIMING OFF, SUMMARY ON)
SELECT bucket, id FROM part_heap WHERE bucket = 3 GROUP BY bucket, id;

\echo '=== P3: ordered partition paths plus LIMIT ==='
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SETTINGS, TIMING OFF, SUMMARY ON)
SELECT bucket, id FROM part_heap
GROUP BY bucket, id ORDER BY bucket, id LIMIT 10;

\echo '=== P4: alternate partition index order plus LIMIT ==='
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SETTINGS, TIMING OFF, SUMMARY ON)
SELECT bucket, id, rank_key FROM part_heap
GROUP BY bucket, id, rank_key ORDER BY rank_key, bucket, id LIMIT 10;

\echo '=== P5: expensive grouping expression above partitioned input ==='
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SETTINGS, TIMING OFF, SUMMARY ON)
SELECT bucket, id, slow_v(payload) AS v FROM part_heap
GROUP BY bucket, id, v;

\echo '=== P6: partitionwise aggregation enabled ==='
BEGIN;
SET LOCAL enable_partitionwise_aggregate = on;
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SETTINGS, TIMING OFF, SUMMARY ON)
SELECT bucket, id FROM part_heap GROUP BY bucket, id;
ROLLBACK;

\echo '=== P7: incomplete key; duplicates across partitions MUST merge ==='
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SETTINGS, TIMING OFF, SUMMARY ON)
SELECT id FROM tiny_part GROUP BY id;
SELECT count(*) = 16 AS incomplete_key_ok FROM
    (SELECT id FROM tiny_part GROUP BY id) s;

\echo '=== P8: empty partitioned input ==='
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SETTINGS, TIMING OFF, SUMMARY ON)
SELECT bucket, id FROM part_heap WHERE bucket = 99 GROUP BY bucket, id;

\echo '=== P9: generic prepared plan and execution-time partition pruning ==='
BEGIN;
SET LOCAL plan_cache_mode = force_generic_plan;
PREPARE sg_partition(integer) AS
SELECT bucket, id FROM part_heap WHERE bucket = $1 GROUP BY bucket, id;
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SETTINGS, TIMING OFF, SUMMARY ON)
EXECUTE sg_partition(3);
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SETTINGS, TIMING OFF, SUMMARY ON)
EXECUTE sg_partition(99);
DEALLOCATE sg_partition;
ROLLBACK;

\echo '=== Q: parallel stress profile (same settings on both builds) ==='
-- nextval is parallel unsafe; it is deliberately absent from this section.
-- parallel-safe slow_v has no side effects and can execute in workers.
-- Actual worker launch is not guaranteed: inspect Workers Launched.
BEGIN;
SET LOCAL max_parallel_workers_per_gather = 2;
SET LOCAL min_parallel_table_scan_size = 0;
SET LOCAL min_parallel_index_scan_size = 0;
SET LOCAL parallel_setup_cost = 0;
SET LOCAL parallel_tuple_cost = 0;

\echo '=== Q1: expensive output on ordinary table, grouping ==='
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SETTINGS, TIMING OFF, SUMMARY ON)
SELECT id, slow_v(payload) AS v FROM wide_heap GROUP BY id;

\echo '=== Q2: expensive grouping expression on ordinary table ==='
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SETTINGS, TIMING OFF, SUMMARY ON)
SELECT id, slow_v(payload) AS v FROM wide_heap GROUP BY id, v;

\echo '=== Q3: expensive grouping expression on partitioned table ==='
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SETTINGS, TIMING OFF, SUMMARY ON)
SELECT bucket, id, slow_v(payload) AS v FROM part_heap
GROUP BY bucket, id, v;

\echo '=== Q4-control: ordinary table, no grouping, parallel profile ==='
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SETTINGS, TIMING OFF, SUMMARY ON)
SELECT id, slow_v(payload) AS v FROM wide_heap;
ROLLBACK;

\echo '=== N1: nullable unique key cannot prove singleton groups ==='
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SETTINGS, TIMING OFF, SUMMARY ON)
SELECT a, b FROM nullable_key GROUP BY a, b;
SELECT count(*) = 1 AS nullable_key_ok FROM
    (SELECT a, b FROM nullable_key GROUP BY a, b) s;

\echo '=== N2: NULLS NOT DISTINCT can prove singleton groups ==='
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SETTINGS, TIMING OFF, SUMMARY ON)
SELECT a, b FROM nnd_key GROUP BY a, b;
SELECT count(*) = 3 AS nnd_key_ok FROM
    (SELECT a, b FROM nnd_key GROUP BY a, b) s;

\echo '=== N3: inherited rows can duplicate the parent primary key ==='
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SETTINGS, TIMING OFF, SUMMARY ON)
SELECT id FROM inherited_parent GROUP BY id;
SELECT count(*) = 1 AS inheritance_ok FROM
    (SELECT id FROM inherited_parent GROUP BY id) s;

\echo '=== End:' :label '==='
-- Objects remain for repeat runs. Cleanup only when finished, in this test DB:
-- DROP SCHEMA sg_review CASCADE;
