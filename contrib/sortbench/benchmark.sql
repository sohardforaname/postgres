-- Single test entrypoint. Run after rebuilding/installing and restarting PostgreSQL.
-- psql -X -d sort_test -f contrib/sortbench/benchmark.sql > sortbench-report.txt 2>&1
-- Recreates the sortbench extension and public.sortbench_data in a dedicated test database.
-- OFF preserves baseline heap-root retention; ON releases replaced roots.
-- All measured SELECTs are literal. Markers only label the next EXPLAIN.
-- Round 05 defaults to slots A/B. Set sortbench_slots off for older modes:
-- sortbench_full off selects round 04; on selects the complete round 03 matrix.
\set sortbench_slots on
\set sortbench_full off
\set ON_ERROR_STOP on
\set QUIET on
\timing off
\pset pager off
SET client_min_messages = warning;
SET search_path = public, pg_catalog;
DROP EXTENSION IF EXISTS sortbench;
CREATE EXTENSION sortbench VERSION '1.0';
SELECT sortbench_prepare()
\gexec
SET max_parallel_workers_per_gather = 0;
SET max_parallel_workers = 0;
SET jit = off;
SET synchronize_seqscans = off;
SET trace_sort = off;
SET debug_sort_heap_on_slots = off;
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;

\echo '== Small-fixture correctness: ordered keys and payloads, OFF and ON =='
SET work_mem = '64MB';

SET debug_sort_free_heap_root = off;
SELECT 'datum/ascending/off' AS check_name,
       sortbench_assert_result(ARRAY(
           SELECT k::text FROM (
SELECT k
FROM sortbench_heap_ascending
ORDER BY k
LIMIT 4096
           ) s ORDER BY s.k), false) AS result;

SET debug_sort_free_heap_root = on;
SELECT 'datum/ascending/on' AS check_name,
       sortbench_assert_result(ARRAY(
           SELECT k::text FROM (
SELECT k
FROM sortbench_heap_ascending
ORDER BY k
LIMIT 4096
           ) s ORDER BY s.k), false) AS result;

SET debug_sort_free_heap_root = off;
SELECT 'datum/descending/off' AS check_name,
       sortbench_assert_result(ARRAY(
           SELECT k::text FROM (
SELECT k
FROM sortbench_heap_descending
ORDER BY k
LIMIT 4096
           ) s ORDER BY s.k), false) AS result;

SET debug_sort_free_heap_root = on;
SELECT 'datum/descending/on' AS check_name,
       sortbench_assert_result(ARRAY(
           SELECT k::text FROM (
SELECT k
FROM sortbench_heap_descending
ORDER BY k
LIMIT 4096
           ) s ORDER BY s.k), false) AS result;

SET debug_sort_free_heap_root = off;
SELECT 'datum/permuted/off' AS check_name,
       sortbench_assert_result(ARRAY(
           SELECT k::text FROM (
SELECT k
FROM sortbench_heap_permuted
ORDER BY k
LIMIT 4096
           ) s ORDER BY s.k), false) AS result;

SET debug_sort_free_heap_root = on;
SELECT 'datum/permuted/on' AS check_name,
       sortbench_assert_result(ARRAY(
           SELECT k::text FROM (
SELECT k
FROM sortbench_heap_permuted
ORDER BY k
LIMIT 4096
           ) s ORDER BY s.k), false) AS result;

SET debug_sort_free_heap_root = off;
SELECT 'tuple/ascending/off' AS check_name,
       sortbench_assert_result(ARRAY(
           SELECT ROW(k,payload)::text FROM (
SELECT k, payload
FROM sortbench_heap_ascending
ORDER BY k
LIMIT 4096
           ) s ORDER BY s.k), true) AS result;

SET debug_sort_free_heap_root = on;
SELECT 'tuple/ascending/on' AS check_name,
       sortbench_assert_result(ARRAY(
           SELECT ROW(k,payload)::text FROM (
SELECT k, payload
FROM sortbench_heap_ascending
ORDER BY k
LIMIT 4096
           ) s ORDER BY s.k), true) AS result;

SET debug_sort_free_heap_root = off;
SELECT 'tuple/descending/off' AS check_name,
       sortbench_assert_result(ARRAY(
           SELECT ROW(k,payload)::text FROM (
SELECT k, payload
FROM sortbench_heap_descending
ORDER BY k
LIMIT 4096
           ) s ORDER BY s.k), true) AS result;

SET debug_sort_free_heap_root = on;
SELECT 'tuple/descending/on' AS check_name,
       sortbench_assert_result(ARRAY(
           SELECT ROW(k,payload)::text FROM (
SELECT k, payload
FROM sortbench_heap_descending
ORDER BY k
LIMIT 4096
           ) s ORDER BY s.k), true) AS result;

SET debug_sort_free_heap_root = off;
SELECT 'tuple/permuted/off' AS check_name,
       sortbench_assert_result(ARRAY(
           SELECT ROW(k,payload)::text FROM (
SELECT k, payload
FROM sortbench_heap_permuted
ORDER BY k
LIMIT 4096
           ) s ORDER BY s.k), true) AS result;

SET debug_sort_free_heap_root = on;
SELECT 'tuple/permuted/on' AS check_name,
       sortbench_assert_result(ARRAY(
           SELECT ROW(k,payload)::text FROM (
SELECT k, payload
FROM sortbench_heap_permuted
ORDER BY k
LIMIT 4096
           ) s ORDER BY s.k), true) AS result;

\if :sortbench_slots
\echo '== Round 05 correctness: slots OFF/ON, root release ON == '
SET work_mem = '128kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT 'datum/ascending/k3500/off' AS check_name,
       sortbench_slots_assert(ARRAY(
           SELECT s.k::text FROM (
SELECT k
FROM sortbench_heap_ascending
ORDER BY k
LIMIT 3500
           ) s ORDER BY s.k), 'datum', 3500, 0) AS result;

SET work_mem = '128kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT 'datum/ascending/k3500/on' AS check_name,
       sortbench_slots_assert(ARRAY(
           SELECT s.k::text FROM (
SELECT k
FROM sortbench_heap_ascending
ORDER BY k
LIMIT 3500
           ) s ORDER BY s.k), 'datum', 3500, 0) AS result;

SET work_mem = '128kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT 'datum/descending/k3500/off' AS check_name,
       sortbench_slots_assert(ARRAY(
           SELECT s.k::text FROM (
SELECT k
FROM sortbench_heap_descending
ORDER BY k
LIMIT 3500
           ) s ORDER BY s.k), 'datum', 3500, 0) AS result;

SET work_mem = '128kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT 'datum/descending/k3500/on' AS check_name,
       sortbench_slots_assert(ARRAY(
           SELECT s.k::text FROM (
SELECT k
FROM sortbench_heap_descending
ORDER BY k
LIMIT 3500
           ) s ORDER BY s.k), 'datum', 3500, 0) AS result;

SET work_mem = '128kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT 'datum/permuted/k3500/off' AS check_name,
       sortbench_slots_assert(ARRAY(
           SELECT s.k::text FROM (
SELECT k
FROM sortbench_heap_permuted
ORDER BY k
LIMIT 3500
           ) s ORDER BY s.k), 'datum', 3500, 0) AS result;

SET work_mem = '128kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT 'datum/permuted/k3500/on' AS check_name,
       sortbench_slots_assert(ARRAY(
           SELECT s.k::text FROM (
SELECT k
FROM sortbench_heap_permuted
ORDER BY k
LIMIT 3500
           ) s ORDER BY s.k), 'datum', 3500, 0) AS result;

SET work_mem = '128kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT 'tuple/ascending/k1200/off' AS check_name,
       sortbench_slots_assert(ARRAY(
           SELECT ROW(s.k,s.payload)::text FROM (
SELECT k, payload
FROM sortbench_heap_ascending
ORDER BY k
LIMIT 1200
           ) s ORDER BY s.k), 'tuple', 1200, 0) AS result;

SET work_mem = '128kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT 'tuple/ascending/k1200/on' AS check_name,
       sortbench_slots_assert(ARRAY(
           SELECT ROW(s.k,s.payload)::text FROM (
SELECT k, payload
FROM sortbench_heap_ascending
ORDER BY k
LIMIT 1200
           ) s ORDER BY s.k), 'tuple', 1200, 0) AS result;

SET work_mem = '128kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT 'tuple/descending/k1200/off' AS check_name,
       sortbench_slots_assert(ARRAY(
           SELECT ROW(s.k,s.payload)::text FROM (
SELECT k, payload
FROM sortbench_heap_descending
ORDER BY k
LIMIT 1200
           ) s ORDER BY s.k), 'tuple', 1200, 0) AS result;

SET work_mem = '128kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT 'tuple/descending/k1200/on' AS check_name,
       sortbench_slots_assert(ARRAY(
           SELECT ROW(s.k,s.payload)::text FROM (
SELECT k, payload
FROM sortbench_heap_descending
ORDER BY k
LIMIT 1200
           ) s ORDER BY s.k), 'tuple', 1200, 0) AS result;

SET work_mem = '128kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT 'tuple/permuted/k1200/off' AS check_name,
       sortbench_slots_assert(ARRAY(
           SELECT ROW(s.k,s.payload)::text FROM (
SELECT k, payload
FROM sortbench_heap_permuted
ORDER BY k
LIMIT 1200
           ) s ORDER BY s.k), 'tuple', 1200, 0) AS result;

SET work_mem = '128kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT 'tuple/permuted/k1200/on' AS check_name,
       sortbench_slots_assert(ARRAY(
           SELECT ROW(s.k,s.payload)::text FROM (
SELECT k, payload
FROM sortbench_heap_permuted
ORDER BY k
LIMIT 1200
           ) s ORDER BY s.k), 'tuple', 1200, 0) AS result;

SET work_mem = '128kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT 'tuple/edge/k2046/off' AS check_name,
       sortbench_slots_assert(ARRAY(
           SELECT ROW(s.k,s.payload)::text FROM (
SELECT k, payload
FROM sortbench_heap_permuted
ORDER BY k
LIMIT 2046
           ) s ORDER BY s.k), 'tuple', 2046, 0) AS result;

SET work_mem = '128kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT 'tuple/edge/k2046/on' AS check_name,
       sortbench_slots_assert(ARRAY(
           SELECT ROW(s.k,s.payload)::text FROM (
SELECT k, payload
FROM sortbench_heap_permuted
ORDER BY k
LIMIT 2046
           ) s ORDER BY s.k), 'tuple', 2046, 0) AS result;

SET work_mem = '128kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT 'tuple/edge/k2047/off' AS check_name,
       sortbench_slots_assert(ARRAY(
           SELECT ROW(s.k,s.payload)::text FROM (
SELECT k, payload
FROM sortbench_heap_permuted
ORDER BY k
LIMIT 2047
           ) s ORDER BY s.k), 'tuple', 2047, 0) AS result;

SET work_mem = '128kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT 'tuple/edge/k2047/on' AS check_name,
       sortbench_slots_assert(ARRAY(
           SELECT ROW(s.k,s.payload)::text FROM (
SELECT k, payload
FROM sortbench_heap_permuted
ORDER BY k
LIMIT 2047
           ) s ORDER BY s.k), 'tuple', 2047, 0) AS result;

SET work_mem = '128kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT 'tuple/edge/k2048/off' AS check_name,
       sortbench_slots_assert(ARRAY(
           SELECT ROW(s.k,s.payload)::text FROM (
SELECT k, payload
FROM sortbench_heap_permuted
ORDER BY k
LIMIT 2048
           ) s ORDER BY s.k), 'tuple', 2048, 0) AS result;

SET work_mem = '128kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT 'tuple/edge/k2048/on' AS check_name,
       sortbench_slots_assert(ARRAY(
           SELECT ROW(s.k,s.payload)::text FROM (
SELECT k, payload
FROM sortbench_heap_permuted
ORDER BY k
LIMIT 2048
           ) s ORDER BY s.k), 'tuple', 2048, 0) AS result;

SET work_mem = '128kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT 'tuple/offset/off' AS check_name,
       sortbench_slots_assert(ARRAY(
           SELECT ROW(s.k,s.payload)::text FROM (
SELECT k, payload
FROM sortbench_heap_descending
ORDER BY k
LIMIT 1000 OFFSET 200
           ) s ORDER BY s.k), 'tuple', 1000, 200) AS result;

SET work_mem = '128kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT 'tuple/offset/on' AS check_name,
       sortbench_slots_assert(ARRAY(
           SELECT ROW(s.k,s.payload)::text FROM (
SELECT k, payload
FROM sortbench_heap_descending
ORDER BY k
LIMIT 1000 OFFSET 200
           ) s ORDER BY s.k), 'tuple', 1000, 200) AS result;

SET work_mem = '128kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT 'nulls-first/off' AS check_name,
       sortbench_slots_assert(ARRAY(
           SELECT ROW(s.k,s.payload)::text FROM (
SELECT k, payload
FROM sortbench_slots_nulls
ORDER BY k NULLS FIRST, payload
LIMIT 1200
           ) s ORDER BY s.k NULLS FIRST, s.payload), 'nulls-first', 1200, 0) AS result;

SET work_mem = '128kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT 'nulls-first/on' AS check_name,
       sortbench_slots_assert(ARRAY(
           SELECT ROW(s.k,s.payload)::text FROM (
SELECT k, payload
FROM sortbench_slots_nulls
ORDER BY k NULLS FIRST, payload
LIMIT 1200
           ) s ORDER BY s.k NULLS FIRST, s.payload), 'nulls-first', 1200, 0) AS result;

SET work_mem = '128kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT 'nulls-last/off' AS check_name,
       sortbench_slots_assert(ARRAY(
           SELECT ROW(s.k,s.payload)::text FROM (
SELECT k, payload
FROM sortbench_slots_nulls
ORDER BY k NULLS LAST, payload
LIMIT 1200
           ) s ORDER BY s.k NULLS LAST, s.payload), 'nulls-last', 1200, 0) AS result;

SET work_mem = '128kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT 'nulls-last/on' AS check_name,
       sortbench_slots_assert(ARRAY(
           SELECT ROW(s.k,s.payload)::text FROM (
SELECT k, payload
FROM sortbench_slots_nulls
ORDER BY k NULLS LAST, payload
LIMIT 1200
           ) s ORDER BY s.k NULLS LAST, s.payload), 'nulls-last', 1200, 0) AS result;

\pset format unaligned
\pset tuples_only on
\o sortbench-plans.log
SELECT sortbench_capture_begin(420);
SET work_mem = '128kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots-check/datum/ascending/k3500', 'off/default', 'slots-small', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k
FROM sortbench_heap_ascending
ORDER BY k
LIMIT 3500;

SET work_mem = '128kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots-check/datum/ascending/k3500', 'on/default', 'slots-small', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k
FROM sortbench_heap_ascending
ORDER BY k
LIMIT 3500;

SET work_mem = '128kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots-check/datum/descending/k3500', 'off/default', 'slots-small', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k
FROM sortbench_heap_descending
ORDER BY k
LIMIT 3500;

SET work_mem = '128kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots-check/datum/descending/k3500', 'on/default', 'slots-small', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k
FROM sortbench_heap_descending
ORDER BY k
LIMIT 3500;

SET work_mem = '128kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots-check/datum/permuted/k3500', 'off/default', 'slots-small', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k
FROM sortbench_heap_permuted
ORDER BY k
LIMIT 3500;

SET work_mem = '128kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots-check/datum/permuted/k3500', 'on/default', 'slots-small', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k
FROM sortbench_heap_permuted
ORDER BY k
LIMIT 3500;

SET work_mem = '128kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots-check/tuple/ascending/k1200', 'off/default', 'slots-small', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, payload
FROM sortbench_heap_ascending
ORDER BY k
LIMIT 1200;

SET work_mem = '128kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots-check/tuple/ascending/k1200', 'on/default', 'slots-small', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, payload
FROM sortbench_heap_ascending
ORDER BY k
LIMIT 1200;

SET work_mem = '128kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots-check/tuple/descending/k1200', 'off/default', 'slots-small', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, payload
FROM sortbench_heap_descending
ORDER BY k
LIMIT 1200;

SET work_mem = '128kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots-check/tuple/descending/k1200', 'on/default', 'slots-small', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, payload
FROM sortbench_heap_descending
ORDER BY k
LIMIT 1200;

SET work_mem = '128kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots-check/tuple/permuted/k1200', 'off/default', 'slots-small', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, payload
FROM sortbench_heap_permuted
ORDER BY k
LIMIT 1200;

SET work_mem = '128kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots-check/tuple/permuted/k1200', 'on/default', 'slots-small', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, payload
FROM sortbench_heap_permuted
ORDER BY k
LIMIT 1200;

SET work_mem = '128kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots-check/tuple/edge/k2046', 'off/default', 'slots-small', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, payload
FROM sortbench_heap_permuted
ORDER BY k
LIMIT 2046;

SET work_mem = '128kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots-check/tuple/edge/k2046', 'on/default', 'slots-small', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, payload
FROM sortbench_heap_permuted
ORDER BY k
LIMIT 2046;

SET work_mem = '128kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots-check/tuple/edge/k2047', 'off/default', 'slots-small', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, payload
FROM sortbench_heap_permuted
ORDER BY k
LIMIT 2047;

SET work_mem = '128kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots-check/tuple/edge/k2047', 'on/default', 'slots-small', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, payload
FROM sortbench_heap_permuted
ORDER BY k
LIMIT 2047;

SET work_mem = '128kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots-check/tuple/edge/k2048', 'off/default', 'slots-small', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, payload
FROM sortbench_heap_permuted
ORDER BY k
LIMIT 2048;

SET work_mem = '128kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots-check/tuple/edge/k2048', 'on/default', 'slots-small', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, payload
FROM sortbench_heap_permuted
ORDER BY k
LIMIT 2048;

SET work_mem = '128kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots-check/tuple/offset', 'off/default', 'slots-small', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, payload
FROM sortbench_heap_descending
ORDER BY k
LIMIT 1000 OFFSET 200;

SET work_mem = '128kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots-check/tuple/offset', 'on/default', 'slots-small', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, payload
FROM sortbench_heap_descending
ORDER BY k
LIMIT 1000 OFFSET 200;

SET work_mem = '128kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots-check/nulls-first', 'off/default', 'slots-small', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, payload
FROM sortbench_slots_nulls
ORDER BY k NULLS FIRST, payload
LIMIT 1200;

SET work_mem = '128kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots-check/nulls-first', 'on/default', 'slots-small', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, payload
FROM sortbench_slots_nulls
ORDER BY k NULLS FIRST, payload
LIMIT 1200;

SET work_mem = '128kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots-check/nulls-last', 'off/default', 'slots-small', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, payload
FROM sortbench_slots_nulls
ORDER BY k NULLS LAST, payload
LIMIT 1200;

SET work_mem = '128kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots-check/nulls-last', 'on/default', 'slots-small', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, payload
FROM sortbench_slots_nulls
ORDER BY k NULLS LAST, payload
LIMIT 1200;


-- slots/narrow/16MB/k250000 | off/default | warmup | batch 1
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/16MB/k250000', 'off/default', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/16MB/k250000 | on/default | warmup | batch 1
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/16MB/k250000', 'on/default', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/16MB/k250000 | off/no-radix | warmup | batch 1
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/16MB/k250000', 'off/no-radix', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/16MB/k250000 | on/no-radix | warmup | batch 1
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/16MB/k250000', 'on/no-radix', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/16MB/k250000 | off/no-heap | warmup | batch 1
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/16MB/k250000', 'off/no-heap', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/16MB/k250000 | on/no-heap | warmup | batch 1
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/16MB/k250000', 'on/no-heap', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/16MB/k250000 | off/default | timed | batch 1
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/16MB/k250000', 'off/default', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/16MB/k250000 | on/default | timed | batch 1
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/16MB/k250000', 'on/default', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/16MB/k250000 | off/no-radix | timed | batch 1
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/16MB/k250000', 'off/no-radix', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/16MB/k250000 | on/no-radix | timed | batch 1
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/16MB/k250000', 'on/no-radix', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/16MB/k250000 | off/no-heap | timed | batch 1
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/16MB/k250000', 'off/no-heap', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/16MB/k250000 | on/no-heap | timed | batch 1
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/16MB/k250000', 'on/no-heap', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/16MB/k250000 | on/no-radix | timed | batch 2
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/16MB/k250000', 'on/no-radix', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/16MB/k250000 | off/no-radix | timed | batch 2
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/16MB/k250000', 'off/no-radix', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/16MB/k250000 | on/no-heap | timed | batch 2
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/16MB/k250000', 'on/no-heap', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/16MB/k250000 | off/no-heap | timed | batch 2
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/16MB/k250000', 'off/no-heap', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/16MB/k250000 | on/default | timed | batch 2
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/16MB/k250000', 'on/default', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/16MB/k250000 | off/default | timed | batch 2
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/16MB/k250000', 'off/default', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/16MB/k250000 | off/no-heap | timed | batch 3
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/16MB/k250000', 'off/no-heap', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/16MB/k250000 | on/no-heap | timed | batch 3
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/16MB/k250000', 'on/no-heap', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/16MB/k250000 | off/default | timed | batch 3
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/16MB/k250000', 'off/default', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/16MB/k250000 | on/default | timed | batch 3
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/16MB/k250000', 'on/default', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/16MB/k250000 | off/no-radix | timed | batch 3
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/16MB/k250000', 'off/no-radix', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/16MB/k250000 | on/no-radix | timed | batch 3
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/16MB/k250000', 'on/no-radix', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/16MB/k250000 | on/default | timed | batch 4
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/16MB/k250000', 'on/default', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/16MB/k250000 | off/default | timed | batch 4
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/16MB/k250000', 'off/default', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/16MB/k250000 | on/no-radix | timed | batch 4
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/16MB/k250000', 'on/no-radix', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/16MB/k250000 | off/no-radix | timed | batch 4
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/16MB/k250000', 'off/no-radix', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/16MB/k250000 | on/no-heap | timed | batch 4
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/16MB/k250000', 'on/no-heap', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/16MB/k250000 | off/no-heap | timed | batch 4
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/16MB/k250000', 'off/no-heap', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/24MB/k250000 | off/default | warmup | batch 1
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/24MB/k250000', 'off/default', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/24MB/k250000 | on/default | warmup | batch 1
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/24MB/k250000', 'on/default', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/24MB/k250000 | off/no-radix | warmup | batch 1
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/24MB/k250000', 'off/no-radix', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/24MB/k250000 | on/no-radix | warmup | batch 1
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/24MB/k250000', 'on/no-radix', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/24MB/k250000 | off/default | timed | batch 1
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/24MB/k250000', 'off/default', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/24MB/k250000 | on/default | timed | batch 1
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/24MB/k250000', 'on/default', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/24MB/k250000 | off/no-radix | timed | batch 1
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/24MB/k250000', 'off/no-radix', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/24MB/k250000 | on/no-radix | timed | batch 1
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/24MB/k250000', 'on/no-radix', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/24MB/k250000 | on/no-radix | timed | batch 2
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/24MB/k250000', 'on/no-radix', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/24MB/k250000 | off/no-radix | timed | batch 2
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/24MB/k250000', 'off/no-radix', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/24MB/k250000 | on/default | timed | batch 2
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/24MB/k250000', 'on/default', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/24MB/k250000 | off/default | timed | batch 2
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/24MB/k250000', 'off/default', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/24MB/k250000 | off/default | timed | batch 3
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/24MB/k250000', 'off/default', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/24MB/k250000 | on/default | timed | batch 3
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/24MB/k250000', 'on/default', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/24MB/k250000 | off/no-radix | timed | batch 3
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/24MB/k250000', 'off/no-radix', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/24MB/k250000 | on/no-radix | timed | batch 3
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/24MB/k250000', 'on/no-radix', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/24MB/k250000 | on/no-radix | timed | batch 4
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/24MB/k250000', 'on/no-radix', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/24MB/k250000 | off/no-radix | timed | batch 4
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/24MB/k250000', 'off/no-radix', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/24MB/k250000 | on/default | timed | batch 4
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/24MB/k250000', 'on/default', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/24MB/k250000 | off/default | timed | batch 4
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/24MB/k250000', 'off/default', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/28MB/k250000 | off/default | warmup | batch 1
SET work_mem = '28MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/28MB/k250000', 'off/default', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/28MB/k250000 | on/default | warmup | batch 1
SET work_mem = '28MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/28MB/k250000', 'on/default', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/28MB/k250000 | off/no-radix | warmup | batch 1
SET work_mem = '28MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/28MB/k250000', 'off/no-radix', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/28MB/k250000 | on/no-radix | warmup | batch 1
SET work_mem = '28MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/28MB/k250000', 'on/no-radix', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/28MB/k250000 | off/default | timed | batch 1
SET work_mem = '28MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/28MB/k250000', 'off/default', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/28MB/k250000 | on/default | timed | batch 1
SET work_mem = '28MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/28MB/k250000', 'on/default', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/28MB/k250000 | off/no-radix | timed | batch 1
SET work_mem = '28MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/28MB/k250000', 'off/no-radix', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/28MB/k250000 | on/no-radix | timed | batch 1
SET work_mem = '28MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/28MB/k250000', 'on/no-radix', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/28MB/k250000 | on/no-radix | timed | batch 2
SET work_mem = '28MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/28MB/k250000', 'on/no-radix', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/28MB/k250000 | off/no-radix | timed | batch 2
SET work_mem = '28MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/28MB/k250000', 'off/no-radix', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/28MB/k250000 | on/default | timed | batch 2
SET work_mem = '28MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/28MB/k250000', 'on/default', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/28MB/k250000 | off/default | timed | batch 2
SET work_mem = '28MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/28MB/k250000', 'off/default', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/28MB/k250000 | off/default | timed | batch 3
SET work_mem = '28MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/28MB/k250000', 'off/default', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/28MB/k250000 | on/default | timed | batch 3
SET work_mem = '28MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/28MB/k250000', 'on/default', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/28MB/k250000 | off/no-radix | timed | batch 3
SET work_mem = '28MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/28MB/k250000', 'off/no-radix', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/28MB/k250000 | on/no-radix | timed | batch 3
SET work_mem = '28MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/28MB/k250000', 'on/no-radix', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/28MB/k250000 | on/no-radix | timed | batch 4
SET work_mem = '28MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/28MB/k250000', 'on/no-radix', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/28MB/k250000 | off/no-radix | timed | batch 4
SET work_mem = '28MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/28MB/k250000', 'off/no-radix', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/28MB/k250000 | on/default | timed | batch 4
SET work_mem = '28MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/28MB/k250000', 'on/default', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/28MB/k250000 | off/default | timed | batch 4
SET work_mem = '28MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/28MB/k250000', 'off/default', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/29MB/k250000 | off/default | warmup | batch 1
SET work_mem = '29MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/29MB/k250000', 'off/default', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/29MB/k250000 | on/default | warmup | batch 1
SET work_mem = '29MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/29MB/k250000', 'on/default', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/29MB/k250000 | off/no-radix | warmup | batch 1
SET work_mem = '29MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/29MB/k250000', 'off/no-radix', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/29MB/k250000 | on/no-radix | warmup | batch 1
SET work_mem = '29MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/29MB/k250000', 'on/no-radix', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/29MB/k250000 | off/default | timed | batch 1
SET work_mem = '29MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/29MB/k250000', 'off/default', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/29MB/k250000 | on/default | timed | batch 1
SET work_mem = '29MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/29MB/k250000', 'on/default', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/29MB/k250000 | off/no-radix | timed | batch 1
SET work_mem = '29MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/29MB/k250000', 'off/no-radix', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/29MB/k250000 | on/no-radix | timed | batch 1
SET work_mem = '29MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/29MB/k250000', 'on/no-radix', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/29MB/k250000 | on/no-radix | timed | batch 2
SET work_mem = '29MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/29MB/k250000', 'on/no-radix', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/29MB/k250000 | off/no-radix | timed | batch 2
SET work_mem = '29MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/29MB/k250000', 'off/no-radix', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/29MB/k250000 | on/default | timed | batch 2
SET work_mem = '29MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/29MB/k250000', 'on/default', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/29MB/k250000 | off/default | timed | batch 2
SET work_mem = '29MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/29MB/k250000', 'off/default', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/29MB/k250000 | off/default | timed | batch 3
SET work_mem = '29MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/29MB/k250000', 'off/default', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/29MB/k250000 | on/default | timed | batch 3
SET work_mem = '29MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/29MB/k250000', 'on/default', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/29MB/k250000 | off/no-radix | timed | batch 3
SET work_mem = '29MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/29MB/k250000', 'off/no-radix', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/29MB/k250000 | on/no-radix | timed | batch 3
SET work_mem = '29MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/29MB/k250000', 'on/no-radix', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/29MB/k250000 | on/no-radix | timed | batch 4
SET work_mem = '29MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/29MB/k250000', 'on/no-radix', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/29MB/k250000 | off/no-radix | timed | batch 4
SET work_mem = '29MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/29MB/k250000', 'off/no-radix', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/29MB/k250000 | on/default | timed | batch 4
SET work_mem = '29MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/29MB/k250000', 'on/default', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/29MB/k250000 | off/default | timed | batch 4
SET work_mem = '29MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/29MB/k250000', 'off/default', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/30MB/k250000 | off/default | warmup | batch 1
SET work_mem = '30MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/30MB/k250000', 'off/default', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/30MB/k250000 | on/default | warmup | batch 1
SET work_mem = '30MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/30MB/k250000', 'on/default', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/30MB/k250000 | off/no-radix | warmup | batch 1
SET work_mem = '30MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/30MB/k250000', 'off/no-radix', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/30MB/k250000 | on/no-radix | warmup | batch 1
SET work_mem = '30MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/30MB/k250000', 'on/no-radix', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/30MB/k250000 | off/default | timed | batch 1
SET work_mem = '30MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/30MB/k250000', 'off/default', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/30MB/k250000 | on/default | timed | batch 1
SET work_mem = '30MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/30MB/k250000', 'on/default', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/30MB/k250000 | off/no-radix | timed | batch 1
SET work_mem = '30MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/30MB/k250000', 'off/no-radix', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/30MB/k250000 | on/no-radix | timed | batch 1
SET work_mem = '30MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/30MB/k250000', 'on/no-radix', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/30MB/k250000 | on/no-radix | timed | batch 2
SET work_mem = '30MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/30MB/k250000', 'on/no-radix', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/30MB/k250000 | off/no-radix | timed | batch 2
SET work_mem = '30MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/30MB/k250000', 'off/no-radix', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/30MB/k250000 | on/default | timed | batch 2
SET work_mem = '30MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/30MB/k250000', 'on/default', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/30MB/k250000 | off/default | timed | batch 2
SET work_mem = '30MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/30MB/k250000', 'off/default', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/30MB/k250000 | off/default | timed | batch 3
SET work_mem = '30MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/30MB/k250000', 'off/default', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/30MB/k250000 | on/default | timed | batch 3
SET work_mem = '30MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/30MB/k250000', 'on/default', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/30MB/k250000 | off/no-radix | timed | batch 3
SET work_mem = '30MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/30MB/k250000', 'off/no-radix', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/30MB/k250000 | on/no-radix | timed | batch 3
SET work_mem = '30MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/30MB/k250000', 'on/no-radix', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/30MB/k250000 | on/no-radix | timed | batch 4
SET work_mem = '30MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/30MB/k250000', 'on/no-radix', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/30MB/k250000 | off/no-radix | timed | batch 4
SET work_mem = '30MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/30MB/k250000', 'off/no-radix', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/30MB/k250000 | on/default | timed | batch 4
SET work_mem = '30MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/30MB/k250000', 'on/default', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/30MB/k250000 | off/default | timed | batch 4
SET work_mem = '30MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/30MB/k250000', 'off/default', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/31232kB/k250000 | off/default | warmup | batch 1
SET work_mem = '31232kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/31232kB/k250000', 'off/default', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/31232kB/k250000 | on/default | warmup | batch 1
SET work_mem = '31232kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/31232kB/k250000', 'on/default', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/31232kB/k250000 | off/no-radix | warmup | batch 1
SET work_mem = '31232kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/31232kB/k250000', 'off/no-radix', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/31232kB/k250000 | on/no-radix | warmup | batch 1
SET work_mem = '31232kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/31232kB/k250000', 'on/no-radix', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/31232kB/k250000 | off/default | timed | batch 1
SET work_mem = '31232kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/31232kB/k250000', 'off/default', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/31232kB/k250000 | on/default | timed | batch 1
SET work_mem = '31232kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/31232kB/k250000', 'on/default', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/31232kB/k250000 | off/no-radix | timed | batch 1
SET work_mem = '31232kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/31232kB/k250000', 'off/no-radix', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/31232kB/k250000 | on/no-radix | timed | batch 1
SET work_mem = '31232kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/31232kB/k250000', 'on/no-radix', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/31232kB/k250000 | on/no-radix | timed | batch 2
SET work_mem = '31232kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/31232kB/k250000', 'on/no-radix', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/31232kB/k250000 | off/no-radix | timed | batch 2
SET work_mem = '31232kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/31232kB/k250000', 'off/no-radix', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/31232kB/k250000 | on/default | timed | batch 2
SET work_mem = '31232kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/31232kB/k250000', 'on/default', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/31232kB/k250000 | off/default | timed | batch 2
SET work_mem = '31232kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/31232kB/k250000', 'off/default', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/31232kB/k250000 | off/default | timed | batch 3
SET work_mem = '31232kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/31232kB/k250000', 'off/default', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/31232kB/k250000 | on/default | timed | batch 3
SET work_mem = '31232kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/31232kB/k250000', 'on/default', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/31232kB/k250000 | off/no-radix | timed | batch 3
SET work_mem = '31232kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/31232kB/k250000', 'off/no-radix', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/31232kB/k250000 | on/no-radix | timed | batch 3
SET work_mem = '31232kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/31232kB/k250000', 'on/no-radix', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/31232kB/k250000 | on/no-radix | timed | batch 4
SET work_mem = '31232kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/31232kB/k250000', 'on/no-radix', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/31232kB/k250000 | off/no-radix | timed | batch 4
SET work_mem = '31232kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/31232kB/k250000', 'off/no-radix', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/31232kB/k250000 | on/default | timed | batch 4
SET work_mem = '31232kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/31232kB/k250000', 'on/default', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/31232kB/k250000 | off/default | timed | batch 4
SET work_mem = '31232kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/31232kB/k250000', 'off/default', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/31MB/k250000 | off/default | warmup | batch 1
SET work_mem = '31MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/31MB/k250000', 'off/default', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/31MB/k250000 | on/default | warmup | batch 1
SET work_mem = '31MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/31MB/k250000', 'on/default', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/31MB/k250000 | off/default | timed | batch 1
SET work_mem = '31MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/31MB/k250000', 'off/default', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/31MB/k250000 | on/default | timed | batch 1
SET work_mem = '31MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/31MB/k250000', 'on/default', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/31MB/k250000 | on/default | timed | batch 2
SET work_mem = '31MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/31MB/k250000', 'on/default', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/31MB/k250000 | off/default | timed | batch 2
SET work_mem = '31MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/31MB/k250000', 'off/default', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/31MB/k250000 | off/default | timed | batch 3
SET work_mem = '31MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/31MB/k250000', 'off/default', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/31MB/k250000 | on/default | timed | batch 3
SET work_mem = '31MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/31MB/k250000', 'on/default', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/31MB/k250000 | on/default | timed | batch 4
SET work_mem = '31MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/31MB/k250000', 'on/default', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/31MB/k250000 | off/default | timed | batch 4
SET work_mem = '31MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/31MB/k250000', 'off/default', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/32256kB/k250000 | off/default | warmup | batch 1
SET work_mem = '32256kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/32256kB/k250000', 'off/default', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/32256kB/k250000 | on/default | warmup | batch 1
SET work_mem = '32256kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/32256kB/k250000', 'on/default', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/32256kB/k250000 | off/default | timed | batch 1
SET work_mem = '32256kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/32256kB/k250000', 'off/default', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/32256kB/k250000 | on/default | timed | batch 1
SET work_mem = '32256kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/32256kB/k250000', 'on/default', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/32256kB/k250000 | on/default | timed | batch 2
SET work_mem = '32256kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/32256kB/k250000', 'on/default', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/32256kB/k250000 | off/default | timed | batch 2
SET work_mem = '32256kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/32256kB/k250000', 'off/default', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/32256kB/k250000 | off/default | timed | batch 3
SET work_mem = '32256kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/32256kB/k250000', 'off/default', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/32256kB/k250000 | on/default | timed | batch 3
SET work_mem = '32256kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/32256kB/k250000', 'on/default', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/32256kB/k250000 | on/default | timed | batch 4
SET work_mem = '32256kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/32256kB/k250000', 'on/default', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/32256kB/k250000 | off/default | timed | batch 4
SET work_mem = '32256kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/32256kB/k250000', 'off/default', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/32MB/k250000 | off/default | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/32MB/k250000', 'off/default', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/32MB/k250000 | on/default | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/32MB/k250000', 'on/default', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/32MB/k250000 | off/no-heap | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/32MB/k250000', 'off/no-heap', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/32MB/k250000 | on/no-heap | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/32MB/k250000', 'on/no-heap', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/32MB/k250000 | off/default | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/32MB/k250000', 'off/default', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/32MB/k250000 | on/default | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/32MB/k250000', 'on/default', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/32MB/k250000 | off/no-heap | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/32MB/k250000', 'off/no-heap', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/32MB/k250000 | on/no-heap | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/32MB/k250000', 'on/no-heap', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/32MB/k250000 | on/no-heap | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/32MB/k250000', 'on/no-heap', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/32MB/k250000 | off/no-heap | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/32MB/k250000', 'off/no-heap', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/32MB/k250000 | on/default | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/32MB/k250000', 'on/default', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/32MB/k250000 | off/default | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/32MB/k250000', 'off/default', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/32MB/k250000 | off/default | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/32MB/k250000', 'off/default', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/32MB/k250000 | on/default | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/32MB/k250000', 'on/default', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/32MB/k250000 | off/no-heap | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/32MB/k250000', 'off/no-heap', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/32MB/k250000 | on/no-heap | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/32MB/k250000', 'on/no-heap', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/32MB/k250000 | on/no-heap | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/32MB/k250000', 'on/no-heap', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/32MB/k250000 | off/no-heap | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/32MB/k250000', 'off/no-heap', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/32MB/k250000 | on/default | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/32MB/k250000', 'on/default', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/32MB/k250000 | off/default | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/32MB/k250000', 'off/default', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/33MB/k250000 | off/default | warmup | batch 1
SET work_mem = '33MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/33MB/k250000', 'off/default', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/33MB/k250000 | on/default | warmup | batch 1
SET work_mem = '33MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/33MB/k250000', 'on/default', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/33MB/k250000 | off/default | timed | batch 1
SET work_mem = '33MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/33MB/k250000', 'off/default', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/33MB/k250000 | on/default | timed | batch 1
SET work_mem = '33MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/33MB/k250000', 'on/default', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/33MB/k250000 | on/default | timed | batch 2
SET work_mem = '33MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/33MB/k250000', 'on/default', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/33MB/k250000 | off/default | timed | batch 2
SET work_mem = '33MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/33MB/k250000', 'off/default', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/33MB/k250000 | off/default | timed | batch 3
SET work_mem = '33MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/33MB/k250000', 'off/default', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/33MB/k250000 | on/default | timed | batch 3
SET work_mem = '33MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/33MB/k250000', 'on/default', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/33MB/k250000 | on/default | timed | batch 4
SET work_mem = '33MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/33MB/k250000', 'on/default', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/33MB/k250000 | off/default | timed | batch 4
SET work_mem = '33MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/33MB/k250000', 'off/default', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/36MB/k250000 | off/default | warmup | batch 1
SET work_mem = '36MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/36MB/k250000', 'off/default', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/36MB/k250000 | on/default | warmup | batch 1
SET work_mem = '36MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/36MB/k250000', 'on/default', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/36MB/k250000 | off/default | timed | batch 1
SET work_mem = '36MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/36MB/k250000', 'off/default', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/36MB/k250000 | on/default | timed | batch 1
SET work_mem = '36MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/36MB/k250000', 'on/default', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/36MB/k250000 | on/default | timed | batch 2
SET work_mem = '36MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/36MB/k250000', 'on/default', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/36MB/k250000 | off/default | timed | batch 2
SET work_mem = '36MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/36MB/k250000', 'off/default', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/36MB/k250000 | off/default | timed | batch 3
SET work_mem = '36MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/36MB/k250000', 'off/default', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/36MB/k250000 | on/default | timed | batch 3
SET work_mem = '36MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/36MB/k250000', 'on/default', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/36MB/k250000 | on/default | timed | batch 4
SET work_mem = '36MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/36MB/k250000', 'on/default', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/36MB/k250000 | off/default | timed | batch 4
SET work_mem = '36MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/36MB/k250000', 'off/default', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/64MB/k250000 | off/default | warmup | batch 1
SET work_mem = '64MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/64MB/k250000', 'off/default', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/64MB/k250000 | on/default | warmup | batch 1
SET work_mem = '64MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/64MB/k250000', 'on/default', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/64MB/k250000 | off/default | timed | batch 1
SET work_mem = '64MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/64MB/k250000', 'off/default', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/64MB/k250000 | on/default | timed | batch 1
SET work_mem = '64MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/64MB/k250000', 'on/default', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/64MB/k250000 | on/default | timed | batch 2
SET work_mem = '64MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/64MB/k250000', 'on/default', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/64MB/k250000 | off/default | timed | batch 2
SET work_mem = '64MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/64MB/k250000', 'off/default', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/64MB/k250000 | off/default | timed | batch 3
SET work_mem = '64MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/64MB/k250000', 'off/default', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/64MB/k250000 | on/default | timed | batch 3
SET work_mem = '64MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/64MB/k250000', 'on/default', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/64MB/k250000 | on/default | timed | batch 4
SET work_mem = '64MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/64MB/k250000', 'on/default', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/64MB/k250000 | off/default | timed | batch 4
SET work_mem = '64MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/64MB/k250000', 'off/default', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/1GB/k250000 | off/default | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/1GB/k250000', 'off/default', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/1GB/k250000 | on/default | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/1GB/k250000', 'on/default', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/1GB/k250000 | off/default | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/1GB/k250000', 'off/default', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/1GB/k250000 | on/default | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/1GB/k250000', 'on/default', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/1GB/k250000 | on/default | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/1GB/k250000', 'on/default', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/1GB/k250000 | off/default | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/1GB/k250000', 'off/default', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/1GB/k250000 | off/default | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/1GB/k250000', 'off/default', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/1GB/k250000 | on/default | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/1GB/k250000', 'on/default', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/1GB/k250000 | on/default | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/1GB/k250000', 'on/default', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/narrow/1GB/k250000 | off/default | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/1GB/k250000', 'off/default', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/64MB/k250000 | off/default | warmup | batch 1
SET work_mem = '64MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/64MB/k250000', 'off/default', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/64MB/k250000 | on/default | warmup | batch 1
SET work_mem = '64MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/64MB/k250000', 'on/default', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/64MB/k250000 | off/default | timed | batch 1
SET work_mem = '64MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/64MB/k250000', 'off/default', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/64MB/k250000 | on/default | timed | batch 1
SET work_mem = '64MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/64MB/k250000', 'on/default', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/64MB/k250000 | on/default | timed | batch 2
SET work_mem = '64MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/64MB/k250000', 'on/default', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/64MB/k250000 | off/default | timed | batch 2
SET work_mem = '64MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/64MB/k250000', 'off/default', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/64MB/k250000 | off/default | timed | batch 3
SET work_mem = '64MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/64MB/k250000', 'off/default', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/64MB/k250000 | on/default | timed | batch 3
SET work_mem = '64MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/64MB/k250000', 'on/default', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/64MB/k250000 | on/default | timed | batch 4
SET work_mem = '64MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/64MB/k250000', 'on/default', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/64MB/k250000 | off/default | timed | batch 4
SET work_mem = '64MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/64MB/k250000', 'off/default', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/96MB/k250000 | off/default | warmup | batch 1
SET work_mem = '96MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/96MB/k250000', 'off/default', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/96MB/k250000 | on/default | warmup | batch 1
SET work_mem = '96MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/96MB/k250000', 'on/default', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/96MB/k250000 | off/default | timed | batch 1
SET work_mem = '96MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/96MB/k250000', 'off/default', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/96MB/k250000 | on/default | timed | batch 1
SET work_mem = '96MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/96MB/k250000', 'on/default', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/96MB/k250000 | on/default | timed | batch 2
SET work_mem = '96MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/96MB/k250000', 'on/default', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/96MB/k250000 | off/default | timed | batch 2
SET work_mem = '96MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/96MB/k250000', 'off/default', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/96MB/k250000 | off/default | timed | batch 3
SET work_mem = '96MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/96MB/k250000', 'off/default', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/96MB/k250000 | on/default | timed | batch 3
SET work_mem = '96MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/96MB/k250000', 'on/default', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/96MB/k250000 | on/default | timed | batch 4
SET work_mem = '96MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/96MB/k250000', 'on/default', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/96MB/k250000 | off/default | timed | batch 4
SET work_mem = '96MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/96MB/k250000', 'off/default', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/128MB/k250000 | off/default | warmup | batch 1
SET work_mem = '128MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/128MB/k250000', 'off/default', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/128MB/k250000 | on/default | warmup | batch 1
SET work_mem = '128MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/128MB/k250000', 'on/default', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/128MB/k250000 | off/default | timed | batch 1
SET work_mem = '128MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/128MB/k250000', 'off/default', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/128MB/k250000 | on/default | timed | batch 1
SET work_mem = '128MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/128MB/k250000', 'on/default', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/128MB/k250000 | on/default | timed | batch 2
SET work_mem = '128MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/128MB/k250000', 'on/default', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/128MB/k250000 | off/default | timed | batch 2
SET work_mem = '128MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/128MB/k250000', 'off/default', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/128MB/k250000 | off/default | timed | batch 3
SET work_mem = '128MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/128MB/k250000', 'off/default', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/128MB/k250000 | on/default | timed | batch 3
SET work_mem = '128MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/128MB/k250000', 'on/default', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/128MB/k250000 | on/default | timed | batch 4
SET work_mem = '128MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/128MB/k250000', 'on/default', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/128MB/k250000 | off/default | timed | batch 4
SET work_mem = '128MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/128MB/k250000', 'off/default', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/144MB/k250000 | off/default | warmup | batch 1
SET work_mem = '144MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/144MB/k250000', 'off/default', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/144MB/k250000 | on/default | warmup | batch 1
SET work_mem = '144MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/144MB/k250000', 'on/default', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/144MB/k250000 | off/no-radix | warmup | batch 1
SET work_mem = '144MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/144MB/k250000', 'off/no-radix', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/144MB/k250000 | on/no-radix | warmup | batch 1
SET work_mem = '144MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/144MB/k250000', 'on/no-radix', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/144MB/k250000 | off/no-heap | warmup | batch 1
SET work_mem = '144MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/144MB/k250000', 'off/no-heap', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/144MB/k250000 | on/no-heap | warmup | batch 1
SET work_mem = '144MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/144MB/k250000', 'on/no-heap', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/144MB/k250000 | off/default | timed | batch 1
SET work_mem = '144MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/144MB/k250000', 'off/default', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/144MB/k250000 | on/default | timed | batch 1
SET work_mem = '144MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/144MB/k250000', 'on/default', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/144MB/k250000 | off/no-radix | timed | batch 1
SET work_mem = '144MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/144MB/k250000', 'off/no-radix', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/144MB/k250000 | on/no-radix | timed | batch 1
SET work_mem = '144MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/144MB/k250000', 'on/no-radix', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/144MB/k250000 | off/no-heap | timed | batch 1
SET work_mem = '144MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/144MB/k250000', 'off/no-heap', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/144MB/k250000 | on/no-heap | timed | batch 1
SET work_mem = '144MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/144MB/k250000', 'on/no-heap', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/144MB/k250000 | on/no-radix | timed | batch 2
SET work_mem = '144MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/144MB/k250000', 'on/no-radix', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/144MB/k250000 | off/no-radix | timed | batch 2
SET work_mem = '144MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/144MB/k250000', 'off/no-radix', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/144MB/k250000 | on/no-heap | timed | batch 2
SET work_mem = '144MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/144MB/k250000', 'on/no-heap', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/144MB/k250000 | off/no-heap | timed | batch 2
SET work_mem = '144MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/144MB/k250000', 'off/no-heap', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/144MB/k250000 | on/default | timed | batch 2
SET work_mem = '144MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/144MB/k250000', 'on/default', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/144MB/k250000 | off/default | timed | batch 2
SET work_mem = '144MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/144MB/k250000', 'off/default', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/144MB/k250000 | off/no-heap | timed | batch 3
SET work_mem = '144MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/144MB/k250000', 'off/no-heap', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/144MB/k250000 | on/no-heap | timed | batch 3
SET work_mem = '144MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/144MB/k250000', 'on/no-heap', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/144MB/k250000 | off/default | timed | batch 3
SET work_mem = '144MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/144MB/k250000', 'off/default', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/144MB/k250000 | on/default | timed | batch 3
SET work_mem = '144MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/144MB/k250000', 'on/default', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/144MB/k250000 | off/no-radix | timed | batch 3
SET work_mem = '144MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/144MB/k250000', 'off/no-radix', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/144MB/k250000 | on/no-radix | timed | batch 3
SET work_mem = '144MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/144MB/k250000', 'on/no-radix', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/144MB/k250000 | on/default | timed | batch 4
SET work_mem = '144MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/144MB/k250000', 'on/default', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/144MB/k250000 | off/default | timed | batch 4
SET work_mem = '144MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/144MB/k250000', 'off/default', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/144MB/k250000 | on/no-radix | timed | batch 4
SET work_mem = '144MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/144MB/k250000', 'on/no-radix', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/144MB/k250000 | off/no-radix | timed | batch 4
SET work_mem = '144MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/144MB/k250000', 'off/no-radix', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/144MB/k250000 | on/no-heap | timed | batch 4
SET work_mem = '144MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/144MB/k250000', 'on/no-heap', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/144MB/k250000 | off/no-heap | timed | batch 4
SET work_mem = '144MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/144MB/k250000', 'off/no-heap', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/192MB/k250000 | off/default | warmup | batch 1
SET work_mem = '192MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/192MB/k250000', 'off/default', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/192MB/k250000 | on/default | warmup | batch 1
SET work_mem = '192MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/192MB/k250000', 'on/default', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/192MB/k250000 | off/no-radix | warmup | batch 1
SET work_mem = '192MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/192MB/k250000', 'off/no-radix', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/192MB/k250000 | on/no-radix | warmup | batch 1
SET work_mem = '192MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/192MB/k250000', 'on/no-radix', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/192MB/k250000 | off/default | timed | batch 1
SET work_mem = '192MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/192MB/k250000', 'off/default', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/192MB/k250000 | on/default | timed | batch 1
SET work_mem = '192MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/192MB/k250000', 'on/default', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/192MB/k250000 | off/no-radix | timed | batch 1
SET work_mem = '192MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/192MB/k250000', 'off/no-radix', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/192MB/k250000 | on/no-radix | timed | batch 1
SET work_mem = '192MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/192MB/k250000', 'on/no-radix', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/192MB/k250000 | on/no-radix | timed | batch 2
SET work_mem = '192MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/192MB/k250000', 'on/no-radix', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/192MB/k250000 | off/no-radix | timed | batch 2
SET work_mem = '192MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/192MB/k250000', 'off/no-radix', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/192MB/k250000 | on/default | timed | batch 2
SET work_mem = '192MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/192MB/k250000', 'on/default', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/192MB/k250000 | off/default | timed | batch 2
SET work_mem = '192MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/192MB/k250000', 'off/default', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/192MB/k250000 | off/default | timed | batch 3
SET work_mem = '192MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/192MB/k250000', 'off/default', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/192MB/k250000 | on/default | timed | batch 3
SET work_mem = '192MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/192MB/k250000', 'on/default', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/192MB/k250000 | off/no-radix | timed | batch 3
SET work_mem = '192MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/192MB/k250000', 'off/no-radix', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/192MB/k250000 | on/no-radix | timed | batch 3
SET work_mem = '192MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/192MB/k250000', 'on/no-radix', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/192MB/k250000 | on/no-radix | timed | batch 4
SET work_mem = '192MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/192MB/k250000', 'on/no-radix', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/192MB/k250000 | off/no-radix | timed | batch 4
SET work_mem = '192MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/192MB/k250000', 'off/no-radix', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/192MB/k250000 | on/default | timed | batch 4
SET work_mem = '192MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/192MB/k250000', 'on/default', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/192MB/k250000 | off/default | timed | batch 4
SET work_mem = '192MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/192MB/k250000', 'off/default', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/256MB/k250000 | off/default | warmup | batch 1
SET work_mem = '256MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/256MB/k250000', 'off/default', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/256MB/k250000 | on/default | warmup | batch 1
SET work_mem = '256MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/256MB/k250000', 'on/default', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/256MB/k250000 | off/no-radix | warmup | batch 1
SET work_mem = '256MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/256MB/k250000', 'off/no-radix', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/256MB/k250000 | on/no-radix | warmup | batch 1
SET work_mem = '256MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/256MB/k250000', 'on/no-radix', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/256MB/k250000 | off/default | timed | batch 1
SET work_mem = '256MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/256MB/k250000', 'off/default', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/256MB/k250000 | on/default | timed | batch 1
SET work_mem = '256MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/256MB/k250000', 'on/default', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/256MB/k250000 | off/no-radix | timed | batch 1
SET work_mem = '256MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/256MB/k250000', 'off/no-radix', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/256MB/k250000 | on/no-radix | timed | batch 1
SET work_mem = '256MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/256MB/k250000', 'on/no-radix', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/256MB/k250000 | on/no-radix | timed | batch 2
SET work_mem = '256MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/256MB/k250000', 'on/no-radix', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/256MB/k250000 | off/no-radix | timed | batch 2
SET work_mem = '256MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/256MB/k250000', 'off/no-radix', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/256MB/k250000 | on/default | timed | batch 2
SET work_mem = '256MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/256MB/k250000', 'on/default', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/256MB/k250000 | off/default | timed | batch 2
SET work_mem = '256MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/256MB/k250000', 'off/default', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/256MB/k250000 | off/default | timed | batch 3
SET work_mem = '256MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/256MB/k250000', 'off/default', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/256MB/k250000 | on/default | timed | batch 3
SET work_mem = '256MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/256MB/k250000', 'on/default', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/256MB/k250000 | off/no-radix | timed | batch 3
SET work_mem = '256MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/256MB/k250000', 'off/no-radix', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/256MB/k250000 | on/no-radix | timed | batch 3
SET work_mem = '256MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/256MB/k250000', 'on/no-radix', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/256MB/k250000 | on/no-radix | timed | batch 4
SET work_mem = '256MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/256MB/k250000', 'on/no-radix', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/256MB/k250000 | off/no-radix | timed | batch 4
SET work_mem = '256MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/256MB/k250000', 'off/no-radix', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/256MB/k250000 | on/default | timed | batch 4
SET work_mem = '256MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/256MB/k250000', 'on/default', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/256MB/k250000 | off/default | timed | batch 4
SET work_mem = '256MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/256MB/k250000', 'off/default', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/272MB/k250000 | off/default | warmup | batch 1
SET work_mem = '272MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/272MB/k250000', 'off/default', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/272MB/k250000 | on/default | warmup | batch 1
SET work_mem = '272MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/272MB/k250000', 'on/default', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/272MB/k250000 | off/default | timed | batch 1
SET work_mem = '272MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/272MB/k250000', 'off/default', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/272MB/k250000 | on/default | timed | batch 1
SET work_mem = '272MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/272MB/k250000', 'on/default', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/272MB/k250000 | on/default | timed | batch 2
SET work_mem = '272MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/272MB/k250000', 'on/default', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/272MB/k250000 | off/default | timed | batch 2
SET work_mem = '272MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/272MB/k250000', 'off/default', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/272MB/k250000 | off/default | timed | batch 3
SET work_mem = '272MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/272MB/k250000', 'off/default', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/272MB/k250000 | on/default | timed | batch 3
SET work_mem = '272MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/272MB/k250000', 'on/default', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/272MB/k250000 | on/default | timed | batch 4
SET work_mem = '272MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/272MB/k250000', 'on/default', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/272MB/k250000 | off/default | timed | batch 4
SET work_mem = '272MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/272MB/k250000', 'off/default', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/1GB/k250000 | off/default | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/1GB/k250000', 'off/default', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/1GB/k250000 | on/default | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/1GB/k250000', 'on/default', 'slots-matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/1GB/k250000 | off/default | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/1GB/k250000', 'off/default', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/1GB/k250000 | on/default | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/1GB/k250000', 'on/default', 'slots-matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/1GB/k250000 | on/default | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/1GB/k250000', 'on/default', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/1GB/k250000 | off/default | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/1GB/k250000', 'off/default', 'slots-matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/1GB/k250000 | off/default | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/1GB/k250000', 'off/default', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/1GB/k250000 | on/default | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/1GB/k250000', 'on/default', 'slots-matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/1GB/k250000 | on/default | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/1GB/k250000', 'on/default', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- slots/wide/1GB/k250000 | off/default | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/1GB/k250000', 'off/default', 'slots-matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

SET client_min_messages = log;
SET trace_sort = on;

\echo '== SLOTS seq=355: slots/narrow/16MB/k250000/trace/off/default == '
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/16MB/k250000/trace', 'off/default', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=356: slots/narrow/16MB/k250000/trace/on/default == '
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/16MB/k250000/trace', 'on/default', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=357: slots/narrow/16MB/k250000/trace/off/no-radix == '
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/16MB/k250000/trace', 'off/no-radix', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=358: slots/narrow/16MB/k250000/trace/on/no-radix == '
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/16MB/k250000/trace', 'on/no-radix', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=359: slots/narrow/16MB/k250000/trace/off/no-heap == '
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/16MB/k250000/trace', 'off/no-heap', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=360: slots/narrow/16MB/k250000/trace/on/no-heap == '
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/16MB/k250000/trace', 'on/no-heap', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=361: slots/narrow/24MB/k250000/trace/off/default == '
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/24MB/k250000/trace', 'off/default', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=362: slots/narrow/24MB/k250000/trace/on/default == '
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/24MB/k250000/trace', 'on/default', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=363: slots/narrow/24MB/k250000/trace/off/no-radix == '
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/24MB/k250000/trace', 'off/no-radix', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=364: slots/narrow/24MB/k250000/trace/on/no-radix == '
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/24MB/k250000/trace', 'on/no-radix', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=365: slots/narrow/28MB/k250000/trace/off/default == '
SET work_mem = '28MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/28MB/k250000/trace', 'off/default', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=366: slots/narrow/28MB/k250000/trace/on/default == '
SET work_mem = '28MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/28MB/k250000/trace', 'on/default', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=367: slots/narrow/28MB/k250000/trace/off/no-radix == '
SET work_mem = '28MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/28MB/k250000/trace', 'off/no-radix', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=368: slots/narrow/28MB/k250000/trace/on/no-radix == '
SET work_mem = '28MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/28MB/k250000/trace', 'on/no-radix', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=369: slots/narrow/29MB/k250000/trace/off/default == '
SET work_mem = '29MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/29MB/k250000/trace', 'off/default', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=370: slots/narrow/29MB/k250000/trace/on/default == '
SET work_mem = '29MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/29MB/k250000/trace', 'on/default', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=371: slots/narrow/29MB/k250000/trace/off/no-radix == '
SET work_mem = '29MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/29MB/k250000/trace', 'off/no-radix', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=372: slots/narrow/29MB/k250000/trace/on/no-radix == '
SET work_mem = '29MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/29MB/k250000/trace', 'on/no-radix', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=373: slots/narrow/30MB/k250000/trace/off/default == '
SET work_mem = '30MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/30MB/k250000/trace', 'off/default', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=374: slots/narrow/30MB/k250000/trace/on/default == '
SET work_mem = '30MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/30MB/k250000/trace', 'on/default', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=375: slots/narrow/30MB/k250000/trace/off/no-radix == '
SET work_mem = '30MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/30MB/k250000/trace', 'off/no-radix', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=376: slots/narrow/30MB/k250000/trace/on/no-radix == '
SET work_mem = '30MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/30MB/k250000/trace', 'on/no-radix', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=377: slots/narrow/31232kB/k250000/trace/off/default == '
SET work_mem = '31232kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/31232kB/k250000/trace', 'off/default', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=378: slots/narrow/31232kB/k250000/trace/on/default == '
SET work_mem = '31232kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/31232kB/k250000/trace', 'on/default', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=379: slots/narrow/31232kB/k250000/trace/off/no-radix == '
SET work_mem = '31232kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/31232kB/k250000/trace', 'off/no-radix', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=380: slots/narrow/31232kB/k250000/trace/on/no-radix == '
SET work_mem = '31232kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/31232kB/k250000/trace', 'on/no-radix', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=381: slots/narrow/31MB/k250000/trace/off/default == '
SET work_mem = '31MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/31MB/k250000/trace', 'off/default', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=382: slots/narrow/31MB/k250000/trace/on/default == '
SET work_mem = '31MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/31MB/k250000/trace', 'on/default', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=383: slots/narrow/32256kB/k250000/trace/off/default == '
SET work_mem = '32256kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/32256kB/k250000/trace', 'off/default', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=384: slots/narrow/32256kB/k250000/trace/on/default == '
SET work_mem = '32256kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/32256kB/k250000/trace', 'on/default', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=385: slots/narrow/32MB/k250000/trace/off/default == '
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/32MB/k250000/trace', 'off/default', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=386: slots/narrow/32MB/k250000/trace/on/default == '
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/32MB/k250000/trace', 'on/default', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=387: slots/narrow/32MB/k250000/trace/off/no-heap == '
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/32MB/k250000/trace', 'off/no-heap', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=388: slots/narrow/32MB/k250000/trace/on/no-heap == '
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/32MB/k250000/trace', 'on/no-heap', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=389: slots/narrow/33MB/k250000/trace/off/default == '
SET work_mem = '33MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/33MB/k250000/trace', 'off/default', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=390: slots/narrow/33MB/k250000/trace/on/default == '
SET work_mem = '33MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/33MB/k250000/trace', 'on/default', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=391: slots/narrow/36MB/k250000/trace/off/default == '
SET work_mem = '36MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/36MB/k250000/trace', 'off/default', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=392: slots/narrow/36MB/k250000/trace/on/default == '
SET work_mem = '36MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/36MB/k250000/trace', 'on/default', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=393: slots/narrow/64MB/k250000/trace/off/default == '
SET work_mem = '64MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/64MB/k250000/trace', 'off/default', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=394: slots/narrow/64MB/k250000/trace/on/default == '
SET work_mem = '64MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/64MB/k250000/trace', 'on/default', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=395: slots/narrow/1GB/k250000/trace/off/default == '
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/narrow/1GB/k250000/trace', 'off/default', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=396: slots/narrow/1GB/k250000/trace/on/default == '
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/narrow/1GB/k250000/trace', 'on/default', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=397: slots/wide/64MB/k250000/trace/off/default == '
SET work_mem = '64MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/64MB/k250000/trace', 'off/default', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=398: slots/wide/64MB/k250000/trace/on/default == '
SET work_mem = '64MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/64MB/k250000/trace', 'on/default', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=399: slots/wide/96MB/k250000/trace/off/default == '
SET work_mem = '96MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/96MB/k250000/trace', 'off/default', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=400: slots/wide/96MB/k250000/trace/on/default == '
SET work_mem = '96MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/96MB/k250000/trace', 'on/default', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=401: slots/wide/128MB/k250000/trace/off/default == '
SET work_mem = '128MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/128MB/k250000/trace', 'off/default', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=402: slots/wide/128MB/k250000/trace/on/default == '
SET work_mem = '128MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/128MB/k250000/trace', 'on/default', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=403: slots/wide/144MB/k250000/trace/off/default == '
SET work_mem = '144MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/144MB/k250000/trace', 'off/default', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=404: slots/wide/144MB/k250000/trace/on/default == '
SET work_mem = '144MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/144MB/k250000/trace', 'on/default', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=405: slots/wide/144MB/k250000/trace/off/no-radix == '
SET work_mem = '144MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/144MB/k250000/trace', 'off/no-radix', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=406: slots/wide/144MB/k250000/trace/on/no-radix == '
SET work_mem = '144MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/144MB/k250000/trace', 'on/no-radix', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=407: slots/wide/144MB/k250000/trace/off/no-heap == '
SET work_mem = '144MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/144MB/k250000/trace', 'off/no-heap', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=408: slots/wide/144MB/k250000/trace/on/no-heap == '
SET work_mem = '144MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/144MB/k250000/trace', 'on/no-heap', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=409: slots/wide/192MB/k250000/trace/off/default == '
SET work_mem = '192MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/192MB/k250000/trace', 'off/default', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=410: slots/wide/192MB/k250000/trace/on/default == '
SET work_mem = '192MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/192MB/k250000/trace', 'on/default', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=411: slots/wide/192MB/k250000/trace/off/no-radix == '
SET work_mem = '192MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/192MB/k250000/trace', 'off/no-radix', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=412: slots/wide/192MB/k250000/trace/on/no-radix == '
SET work_mem = '192MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/192MB/k250000/trace', 'on/no-radix', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=413: slots/wide/256MB/k250000/trace/off/default == '
SET work_mem = '256MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/256MB/k250000/trace', 'off/default', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=414: slots/wide/256MB/k250000/trace/on/default == '
SET work_mem = '256MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/256MB/k250000/trace', 'on/default', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=415: slots/wide/256MB/k250000/trace/off/no-radix == '
SET work_mem = '256MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/256MB/k250000/trace', 'off/no-radix', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=416: slots/wide/256MB/k250000/trace/on/no-radix == '
SET work_mem = '256MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/256MB/k250000/trace', 'on/no-radix', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=417: slots/wide/272MB/k250000/trace/off/default == '
SET work_mem = '272MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/272MB/k250000/trace', 'off/default', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=418: slots/wide/272MB/k250000/trace/on/default == '
SET work_mem = '272MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/272MB/k250000/trace', 'on/default', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=419: slots/wide/1GB/k250000/trace/off/default == '
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = off;
SELECT sortbench_capture('slots/wide/1GB/k250000/trace', 'off/default', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== SLOTS seq=420: slots/wide/1GB/k250000/trace/on/default == '
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SET debug_sort_heap_on_slots = on;
SELECT sortbench_capture('slots/wide/1GB/k250000/trace', 'on/default', 'slots-trace', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

SET trace_sort = off;
SET client_min_messages = warning;
SELECT sortbench_capture_end();
\o
SELECT sortbench_file_reset();
\copy pg_temp.sortbench_file_lines(line) FROM 'sortbench-plans.log' WITH (FORMAT csv, DELIMITER E'\x01', QUOTE E'\x02')
\pset format aligned
\pset tuples_only off
\echo '== Round 05 capture and consistency checks =='
SELECT sortbench_file_load();
SELECT sortbench_slots_check();
SELECT version();
\echo '== Small fixture algorithms; k=2047/2048 are edge probes, not assumed heap =='
SELECT * FROM sortbench_file_report() WHERE case_name LIKE 'slots-check/%';
\echo '== Four timed batches; trace and warmup excluded =='
SELECT * FROM sortbench_file_report() WHERE timed_samples>0;
\echo '== Paired slots ON/OFF ratios; less than 1 means ON faster =='
SELECT * FROM sortbench_slots_ratios();
\echo '== Sort cost increments and temporary IO, timed samples =='
SELECT * FROM sortbench_file_costs();
\echo '== Raw timed batches =='
SELECT case_name,variant,batch,round(ms::numeric,3) AS execution_ms
FROM pg_temp.sortbench_file_batches ORDER BY case_name,batch,variant;

\else
\if :sortbench_full
\pset format unaligned
\pset tuples_only on
\o sortbench-plans.log
SELECT sortbench_capture_begin(1212);

-- These 12 memory checks are diagnostic samples, excluded from timing statistics.

-- heap-check/datum/ascending/off
SET work_mem = '64MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('heap-check/datum/ascending', 'off', 'heap-release', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k
FROM sortbench_heap_ascending
ORDER BY k
LIMIT 4096;

-- heap-check/datum/ascending/on
SET work_mem = '64MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('heap-check/datum/ascending', 'on', 'heap-release', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k
FROM sortbench_heap_ascending
ORDER BY k
LIMIT 4096;

-- heap-check/datum/descending/off
SET work_mem = '64MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('heap-check/datum/descending', 'off', 'heap-release', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k
FROM sortbench_heap_descending
ORDER BY k
LIMIT 4096;

-- heap-check/datum/descending/on
SET work_mem = '64MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('heap-check/datum/descending', 'on', 'heap-release', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k
FROM sortbench_heap_descending
ORDER BY k
LIMIT 4096;

-- heap-check/datum/permuted/off
SET work_mem = '64MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('heap-check/datum/permuted', 'off', 'heap-release', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k
FROM sortbench_heap_permuted
ORDER BY k
LIMIT 4096;

-- heap-check/datum/permuted/on
SET work_mem = '64MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('heap-check/datum/permuted', 'on', 'heap-release', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k
FROM sortbench_heap_permuted
ORDER BY k
LIMIT 4096;

-- heap-check/tuple/ascending/off
SET work_mem = '64MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('heap-check/tuple/ascending', 'off', 'heap-release', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, payload
FROM sortbench_heap_ascending
ORDER BY k
LIMIT 4096;

-- heap-check/tuple/ascending/on
SET work_mem = '64MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('heap-check/tuple/ascending', 'on', 'heap-release', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, payload
FROM sortbench_heap_ascending
ORDER BY k
LIMIT 4096;

-- heap-check/tuple/descending/off
SET work_mem = '64MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('heap-check/tuple/descending', 'off', 'heap-release', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, payload
FROM sortbench_heap_descending
ORDER BY k
LIMIT 4096;

-- heap-check/tuple/descending/on
SET work_mem = '64MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('heap-check/tuple/descending', 'on', 'heap-release', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, payload
FROM sortbench_heap_descending
ORDER BY k
LIMIT 4096;

-- heap-check/tuple/permuted/off
SET work_mem = '64MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('heap-check/tuple/permuted', 'off', 'heap-release', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, payload
FROM sortbench_heap_permuted
ORDER BY k
LIMIT 4096;

-- heap-check/tuple/permuted/on
SET work_mem = '64MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('heap-check/tuple/permuted', 'on', 'heap-release', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, payload
FROM sortbench_heap_permuted
ORDER BY k
LIMIT 4096;

-- CASE: narrow/32MB/k001000; narrow tuples; work_mem=32MB; LIMIT=1000

-- narrow/32MB/k001000 | off/default | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k001000', 'off/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/32MB/k001000 | on/default | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k001000', 'on/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/32MB/k001000 | on/no-radix | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k001000', 'on/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/32MB/k001000 | off/no-radix | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k001000', 'off/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/32MB/k001000 | off/no-heap | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k001000', 'off/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/32MB/k001000 | on/no-heap | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k001000', 'on/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/32MB/k001000 | on/no-heap-no-radix | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k001000', 'on/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/32MB/k001000 | off/no-heap-no-radix | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k001000', 'off/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/32MB/k001000 | on/default | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k001000', 'on/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/32MB/k001000 | off/default | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k001000', 'off/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/32MB/k001000 | off/no-radix | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k001000', 'off/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/32MB/k001000 | on/no-radix | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k001000', 'on/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/32MB/k001000 | off/no-heap-no-radix | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k001000', 'off/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/32MB/k001000 | on/no-heap-no-radix | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k001000', 'on/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/32MB/k001000 | on/no-heap | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k001000', 'on/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/32MB/k001000 | off/no-heap | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k001000', 'off/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/32MB/k001000 | on/no-radix | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k001000', 'on/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/32MB/k001000 | off/no-radix | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k001000', 'off/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/32MB/k001000 | off/no-heap | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k001000', 'off/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/32MB/k001000 | on/no-heap | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k001000', 'on/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/32MB/k001000 | off/default | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k001000', 'off/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/32MB/k001000 | on/default | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k001000', 'on/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/32MB/k001000 | on/no-heap-no-radix | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k001000', 'on/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/32MB/k001000 | off/no-heap-no-radix | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k001000', 'off/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/32MB/k001000 | on/no-heap | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k001000', 'on/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/32MB/k001000 | off/no-heap | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k001000', 'off/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/32MB/k001000 | off/no-heap-no-radix | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k001000', 'off/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/32MB/k001000 | on/no-heap-no-radix | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k001000', 'on/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/32MB/k001000 | off/no-radix | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k001000', 'off/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/32MB/k001000 | on/no-radix | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k001000', 'on/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/32MB/k001000 | on/default | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k001000', 'on/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/32MB/k001000 | off/default | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k001000', 'off/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/32MB/k001000 | on/no-heap-no-radix | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k001000', 'on/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/32MB/k001000 | off/no-heap-no-radix | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k001000', 'off/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/32MB/k001000 | off/default | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k001000', 'off/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/32MB/k001000 | on/default | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k001000', 'on/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/32MB/k001000 | off/no-heap | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k001000', 'off/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/32MB/k001000 | on/no-heap | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k001000', 'on/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/32MB/k001000 | on/no-radix | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k001000', 'on/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/32MB/k001000 | off/no-radix | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k001000', 'off/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- CASE: narrow/32MB/k010000; narrow tuples; work_mem=32MB; LIMIT=10000

-- narrow/32MB/k010000 | off/default | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k010000', 'off/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/32MB/k010000 | on/default | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k010000', 'on/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/32MB/k010000 | on/no-radix | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k010000', 'on/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/32MB/k010000 | off/no-radix | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k010000', 'off/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/32MB/k010000 | off/no-heap | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k010000', 'off/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/32MB/k010000 | on/no-heap | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k010000', 'on/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/32MB/k010000 | on/no-heap-no-radix | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k010000', 'on/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/32MB/k010000 | off/no-heap-no-radix | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k010000', 'off/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/32MB/k010000 | on/default | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k010000', 'on/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/32MB/k010000 | off/default | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k010000', 'off/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/32MB/k010000 | off/no-radix | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k010000', 'off/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/32MB/k010000 | on/no-radix | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k010000', 'on/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/32MB/k010000 | off/no-heap-no-radix | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k010000', 'off/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/32MB/k010000 | on/no-heap-no-radix | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k010000', 'on/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/32MB/k010000 | on/no-heap | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k010000', 'on/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/32MB/k010000 | off/no-heap | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k010000', 'off/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/32MB/k010000 | on/no-radix | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k010000', 'on/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/32MB/k010000 | off/no-radix | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k010000', 'off/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/32MB/k010000 | off/no-heap | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k010000', 'off/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/32MB/k010000 | on/no-heap | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k010000', 'on/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/32MB/k010000 | off/default | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k010000', 'off/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/32MB/k010000 | on/default | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k010000', 'on/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/32MB/k010000 | on/no-heap-no-radix | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k010000', 'on/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/32MB/k010000 | off/no-heap-no-radix | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k010000', 'off/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/32MB/k010000 | on/no-heap | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k010000', 'on/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/32MB/k010000 | off/no-heap | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k010000', 'off/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/32MB/k010000 | off/no-heap-no-radix | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k010000', 'off/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/32MB/k010000 | on/no-heap-no-radix | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k010000', 'on/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/32MB/k010000 | off/no-radix | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k010000', 'off/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/32MB/k010000 | on/no-radix | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k010000', 'on/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/32MB/k010000 | on/default | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k010000', 'on/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/32MB/k010000 | off/default | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k010000', 'off/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/32MB/k010000 | on/no-heap-no-radix | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k010000', 'on/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/32MB/k010000 | off/no-heap-no-radix | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k010000', 'off/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/32MB/k010000 | off/default | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k010000', 'off/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/32MB/k010000 | on/default | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k010000', 'on/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/32MB/k010000 | off/no-heap | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k010000', 'off/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/32MB/k010000 | on/no-heap | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k010000', 'on/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/32MB/k010000 | on/no-radix | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k010000', 'on/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/32MB/k010000 | off/no-radix | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k010000', 'off/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- CASE: narrow/32MB/k050000; narrow tuples; work_mem=32MB; LIMIT=50000

-- narrow/32MB/k050000 | off/default | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k050000', 'off/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/32MB/k050000 | on/default | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k050000', 'on/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/32MB/k050000 | on/no-radix | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k050000', 'on/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/32MB/k050000 | off/no-radix | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k050000', 'off/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/32MB/k050000 | off/no-heap | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k050000', 'off/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/32MB/k050000 | on/no-heap | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k050000', 'on/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/32MB/k050000 | on/no-heap-no-radix | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k050000', 'on/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/32MB/k050000 | off/no-heap-no-radix | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k050000', 'off/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/32MB/k050000 | on/default | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k050000', 'on/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/32MB/k050000 | off/default | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k050000', 'off/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/32MB/k050000 | off/no-radix | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k050000', 'off/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/32MB/k050000 | on/no-radix | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k050000', 'on/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/32MB/k050000 | off/no-heap-no-radix | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k050000', 'off/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/32MB/k050000 | on/no-heap-no-radix | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k050000', 'on/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/32MB/k050000 | on/no-heap | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k050000', 'on/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/32MB/k050000 | off/no-heap | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k050000', 'off/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/32MB/k050000 | on/no-radix | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k050000', 'on/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/32MB/k050000 | off/no-radix | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k050000', 'off/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/32MB/k050000 | off/no-heap | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k050000', 'off/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/32MB/k050000 | on/no-heap | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k050000', 'on/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/32MB/k050000 | off/default | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k050000', 'off/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/32MB/k050000 | on/default | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k050000', 'on/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/32MB/k050000 | on/no-heap-no-radix | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k050000', 'on/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/32MB/k050000 | off/no-heap-no-radix | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k050000', 'off/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/32MB/k050000 | on/no-heap | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k050000', 'on/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/32MB/k050000 | off/no-heap | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k050000', 'off/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/32MB/k050000 | off/no-heap-no-radix | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k050000', 'off/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/32MB/k050000 | on/no-heap-no-radix | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k050000', 'on/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/32MB/k050000 | off/no-radix | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k050000', 'off/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/32MB/k050000 | on/no-radix | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k050000', 'on/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/32MB/k050000 | on/default | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k050000', 'on/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/32MB/k050000 | off/default | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k050000', 'off/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/32MB/k050000 | on/no-heap-no-radix | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k050000', 'on/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/32MB/k050000 | off/no-heap-no-radix | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k050000', 'off/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/32MB/k050000 | off/default | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k050000', 'off/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/32MB/k050000 | on/default | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k050000', 'on/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/32MB/k050000 | off/no-heap | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k050000', 'off/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/32MB/k050000 | on/no-heap | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k050000', 'on/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/32MB/k050000 | on/no-radix | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k050000', 'on/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/32MB/k050000 | off/no-radix | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k050000', 'off/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- CASE: narrow/32MB/k100000; narrow tuples; work_mem=32MB; LIMIT=100000

-- narrow/32MB/k100000 | off/default | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k100000', 'off/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/32MB/k100000 | on/default | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k100000', 'on/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/32MB/k100000 | on/no-radix | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k100000', 'on/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/32MB/k100000 | off/no-radix | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k100000', 'off/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/32MB/k100000 | off/no-heap | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k100000', 'off/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/32MB/k100000 | on/no-heap | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k100000', 'on/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/32MB/k100000 | on/no-heap-no-radix | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k100000', 'on/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/32MB/k100000 | off/no-heap-no-radix | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k100000', 'off/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/32MB/k100000 | on/default | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k100000', 'on/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/32MB/k100000 | off/default | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k100000', 'off/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/32MB/k100000 | off/no-radix | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k100000', 'off/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/32MB/k100000 | on/no-radix | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k100000', 'on/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/32MB/k100000 | off/no-heap-no-radix | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k100000', 'off/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/32MB/k100000 | on/no-heap-no-radix | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k100000', 'on/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/32MB/k100000 | on/no-heap | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k100000', 'on/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/32MB/k100000 | off/no-heap | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k100000', 'off/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/32MB/k100000 | on/no-radix | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k100000', 'on/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/32MB/k100000 | off/no-radix | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k100000', 'off/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/32MB/k100000 | off/no-heap | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k100000', 'off/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/32MB/k100000 | on/no-heap | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k100000', 'on/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/32MB/k100000 | off/default | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k100000', 'off/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/32MB/k100000 | on/default | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k100000', 'on/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/32MB/k100000 | on/no-heap-no-radix | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k100000', 'on/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/32MB/k100000 | off/no-heap-no-radix | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k100000', 'off/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/32MB/k100000 | on/no-heap | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k100000', 'on/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/32MB/k100000 | off/no-heap | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k100000', 'off/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/32MB/k100000 | off/no-heap-no-radix | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k100000', 'off/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/32MB/k100000 | on/no-heap-no-radix | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k100000', 'on/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/32MB/k100000 | off/no-radix | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k100000', 'off/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/32MB/k100000 | on/no-radix | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k100000', 'on/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/32MB/k100000 | on/default | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k100000', 'on/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/32MB/k100000 | off/default | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k100000', 'off/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/32MB/k100000 | on/no-heap-no-radix | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k100000', 'on/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/32MB/k100000 | off/no-heap-no-radix | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k100000', 'off/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/32MB/k100000 | off/default | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k100000', 'off/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/32MB/k100000 | on/default | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k100000', 'on/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/32MB/k100000 | off/no-heap | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k100000', 'off/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/32MB/k100000 | on/no-heap | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k100000', 'on/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/32MB/k100000 | on/no-radix | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k100000', 'on/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/32MB/k100000 | off/no-radix | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k100000', 'off/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- CASE: narrow/32MB/k250000; narrow tuples; work_mem=32MB; LIMIT=250000

-- narrow/32MB/k250000 | off/default | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k250000', 'off/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/32MB/k250000 | on/default | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k250000', 'on/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/32MB/k250000 | on/no-radix | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k250000', 'on/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/32MB/k250000 | off/no-radix | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k250000', 'off/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/32MB/k250000 | off/no-heap | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k250000', 'off/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/32MB/k250000 | on/no-heap | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k250000', 'on/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/32MB/k250000 | on/no-heap-no-radix | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k250000', 'on/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/32MB/k250000 | off/no-heap-no-radix | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k250000', 'off/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/32MB/k250000 | on/default | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k250000', 'on/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/32MB/k250000 | off/default | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k250000', 'off/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/32MB/k250000 | off/no-radix | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k250000', 'off/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/32MB/k250000 | on/no-radix | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k250000', 'on/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/32MB/k250000 | off/no-heap-no-radix | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k250000', 'off/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/32MB/k250000 | on/no-heap-no-radix | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k250000', 'on/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/32MB/k250000 | on/no-heap | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k250000', 'on/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/32MB/k250000 | off/no-heap | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k250000', 'off/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/32MB/k250000 | on/no-radix | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k250000', 'on/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/32MB/k250000 | off/no-radix | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k250000', 'off/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/32MB/k250000 | off/no-heap | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k250000', 'off/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/32MB/k250000 | on/no-heap | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k250000', 'on/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/32MB/k250000 | off/default | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k250000', 'off/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/32MB/k250000 | on/default | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k250000', 'on/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/32MB/k250000 | on/no-heap-no-radix | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k250000', 'on/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/32MB/k250000 | off/no-heap-no-radix | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k250000', 'off/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/32MB/k250000 | on/no-heap | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k250000', 'on/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/32MB/k250000 | off/no-heap | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k250000', 'off/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/32MB/k250000 | off/no-heap-no-radix | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k250000', 'off/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/32MB/k250000 | on/no-heap-no-radix | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k250000', 'on/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/32MB/k250000 | off/no-radix | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k250000', 'off/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/32MB/k250000 | on/no-radix | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k250000', 'on/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/32MB/k250000 | on/default | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k250000', 'on/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/32MB/k250000 | off/default | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k250000', 'off/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/32MB/k250000 | on/no-heap-no-radix | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k250000', 'on/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/32MB/k250000 | off/no-heap-no-radix | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k250000', 'off/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/32MB/k250000 | off/default | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k250000', 'off/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/32MB/k250000 | on/default | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k250000', 'on/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/32MB/k250000 | off/no-heap | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k250000', 'off/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/32MB/k250000 | on/no-heap | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k250000', 'on/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/32MB/k250000 | on/no-radix | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k250000', 'on/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/32MB/k250000 | off/no-radix | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k250000', 'off/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- CASE: narrow/32MB/k500000; narrow tuples; work_mem=32MB; LIMIT=500000

-- narrow/32MB/k500000 | off/default | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k500000', 'off/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/32MB/k500000 | on/default | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k500000', 'on/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/32MB/k500000 | on/no-radix | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k500000', 'on/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/32MB/k500000 | off/no-radix | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k500000', 'off/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/32MB/k500000 | off/no-heap | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k500000', 'off/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/32MB/k500000 | on/no-heap | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k500000', 'on/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/32MB/k500000 | on/no-heap-no-radix | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k500000', 'on/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/32MB/k500000 | off/no-heap-no-radix | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k500000', 'off/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/32MB/k500000 | on/default | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k500000', 'on/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/32MB/k500000 | off/default | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k500000', 'off/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/32MB/k500000 | off/no-radix | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k500000', 'off/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/32MB/k500000 | on/no-radix | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k500000', 'on/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/32MB/k500000 | off/no-heap-no-radix | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k500000', 'off/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/32MB/k500000 | on/no-heap-no-radix | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k500000', 'on/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/32MB/k500000 | on/no-heap | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k500000', 'on/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/32MB/k500000 | off/no-heap | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k500000', 'off/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/32MB/k500000 | on/no-radix | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k500000', 'on/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/32MB/k500000 | off/no-radix | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k500000', 'off/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/32MB/k500000 | off/no-heap | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k500000', 'off/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/32MB/k500000 | on/no-heap | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k500000', 'on/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/32MB/k500000 | off/default | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k500000', 'off/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/32MB/k500000 | on/default | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k500000', 'on/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/32MB/k500000 | on/no-heap-no-radix | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k500000', 'on/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/32MB/k500000 | off/no-heap-no-radix | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k500000', 'off/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/32MB/k500000 | on/no-heap | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k500000', 'on/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/32MB/k500000 | off/no-heap | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k500000', 'off/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/32MB/k500000 | off/no-heap-no-radix | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k500000', 'off/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/32MB/k500000 | on/no-heap-no-radix | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k500000', 'on/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/32MB/k500000 | off/no-radix | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k500000', 'off/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/32MB/k500000 | on/no-radix | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k500000', 'on/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/32MB/k500000 | on/default | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k500000', 'on/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/32MB/k500000 | off/default | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k500000', 'off/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/32MB/k500000 | on/no-heap-no-radix | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k500000', 'on/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/32MB/k500000 | off/no-heap-no-radix | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k500000', 'off/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/32MB/k500000 | off/default | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k500000', 'off/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/32MB/k500000 | on/default | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k500000', 'on/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/32MB/k500000 | off/no-heap | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k500000', 'off/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/32MB/k500000 | on/no-heap | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k500000', 'on/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/32MB/k500000 | on/no-radix | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k500000', 'on/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/32MB/k500000 | off/no-radix | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k500000', 'off/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- CASE: narrow/32MB/k750000; narrow tuples; work_mem=32MB; LIMIT=750000

-- narrow/32MB/k750000 | off/default | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k750000', 'off/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/32MB/k750000 | on/default | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k750000', 'on/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/32MB/k750000 | on/no-radix | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k750000', 'on/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/32MB/k750000 | off/no-radix | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k750000', 'off/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/32MB/k750000 | off/no-heap | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k750000', 'off/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/32MB/k750000 | on/no-heap | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k750000', 'on/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/32MB/k750000 | on/no-heap-no-radix | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k750000', 'on/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/32MB/k750000 | off/no-heap-no-radix | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k750000', 'off/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/32MB/k750000 | on/default | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k750000', 'on/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/32MB/k750000 | off/default | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k750000', 'off/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/32MB/k750000 | off/no-radix | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k750000', 'off/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/32MB/k750000 | on/no-radix | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k750000', 'on/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/32MB/k750000 | off/no-heap-no-radix | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k750000', 'off/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/32MB/k750000 | on/no-heap-no-radix | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k750000', 'on/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/32MB/k750000 | on/no-heap | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k750000', 'on/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/32MB/k750000 | off/no-heap | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k750000', 'off/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/32MB/k750000 | on/no-radix | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k750000', 'on/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/32MB/k750000 | off/no-radix | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k750000', 'off/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/32MB/k750000 | off/no-heap | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k750000', 'off/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/32MB/k750000 | on/no-heap | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k750000', 'on/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/32MB/k750000 | off/default | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k750000', 'off/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/32MB/k750000 | on/default | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k750000', 'on/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/32MB/k750000 | on/no-heap-no-radix | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k750000', 'on/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/32MB/k750000 | off/no-heap-no-radix | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k750000', 'off/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/32MB/k750000 | on/no-heap | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k750000', 'on/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/32MB/k750000 | off/no-heap | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k750000', 'off/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/32MB/k750000 | off/no-heap-no-radix | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k750000', 'off/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/32MB/k750000 | on/no-heap-no-radix | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k750000', 'on/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/32MB/k750000 | off/no-radix | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k750000', 'off/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/32MB/k750000 | on/no-radix | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k750000', 'on/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/32MB/k750000 | on/default | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k750000', 'on/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/32MB/k750000 | off/default | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k750000', 'off/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/32MB/k750000 | on/no-heap-no-radix | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k750000', 'on/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/32MB/k750000 | off/no-heap-no-radix | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k750000', 'off/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/32MB/k750000 | off/default | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k750000', 'off/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/32MB/k750000 | on/default | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k750000', 'on/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/32MB/k750000 | off/no-heap | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k750000', 'off/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/32MB/k750000 | on/no-heap | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k750000', 'on/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/32MB/k750000 | on/no-radix | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/32MB/k750000', 'on/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/32MB/k750000 | off/no-radix | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/32MB/k750000', 'off/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- CASE: narrow/1GB/k001000; narrow tuples; work_mem=1GB; LIMIT=1000

-- narrow/1GB/k001000 | off/default | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k001000', 'off/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/1GB/k001000 | on/default | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k001000', 'on/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/1GB/k001000 | on/no-radix | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k001000', 'on/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/1GB/k001000 | off/no-radix | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k001000', 'off/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/1GB/k001000 | off/no-heap | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k001000', 'off/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/1GB/k001000 | on/no-heap | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k001000', 'on/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/1GB/k001000 | on/no-heap-no-radix | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k001000', 'on/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/1GB/k001000 | off/no-heap-no-radix | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k001000', 'off/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/1GB/k001000 | on/default | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k001000', 'on/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/1GB/k001000 | off/default | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k001000', 'off/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/1GB/k001000 | off/no-radix | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k001000', 'off/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/1GB/k001000 | on/no-radix | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k001000', 'on/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/1GB/k001000 | off/no-heap-no-radix | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k001000', 'off/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/1GB/k001000 | on/no-heap-no-radix | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k001000', 'on/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/1GB/k001000 | on/no-heap | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k001000', 'on/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/1GB/k001000 | off/no-heap | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k001000', 'off/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/1GB/k001000 | on/no-radix | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k001000', 'on/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/1GB/k001000 | off/no-radix | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k001000', 'off/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/1GB/k001000 | off/no-heap | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k001000', 'off/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/1GB/k001000 | on/no-heap | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k001000', 'on/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/1GB/k001000 | off/default | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k001000', 'off/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/1GB/k001000 | on/default | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k001000', 'on/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/1GB/k001000 | on/no-heap-no-radix | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k001000', 'on/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/1GB/k001000 | off/no-heap-no-radix | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k001000', 'off/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/1GB/k001000 | on/no-heap | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k001000', 'on/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/1GB/k001000 | off/no-heap | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k001000', 'off/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/1GB/k001000 | off/no-heap-no-radix | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k001000', 'off/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/1GB/k001000 | on/no-heap-no-radix | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k001000', 'on/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/1GB/k001000 | off/no-radix | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k001000', 'off/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/1GB/k001000 | on/no-radix | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k001000', 'on/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/1GB/k001000 | on/default | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k001000', 'on/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/1GB/k001000 | off/default | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k001000', 'off/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/1GB/k001000 | on/no-heap-no-radix | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k001000', 'on/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/1GB/k001000 | off/no-heap-no-radix | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k001000', 'off/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/1GB/k001000 | off/default | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k001000', 'off/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/1GB/k001000 | on/default | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k001000', 'on/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/1GB/k001000 | off/no-heap | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k001000', 'off/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/1GB/k001000 | on/no-heap | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k001000', 'on/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/1GB/k001000 | on/no-radix | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k001000', 'on/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- narrow/1GB/k001000 | off/no-radix | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k001000', 'off/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- CASE: narrow/1GB/k010000; narrow tuples; work_mem=1GB; LIMIT=10000

-- narrow/1GB/k010000 | off/default | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k010000', 'off/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/1GB/k010000 | on/default | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k010000', 'on/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/1GB/k010000 | on/no-radix | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k010000', 'on/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/1GB/k010000 | off/no-radix | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k010000', 'off/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/1GB/k010000 | off/no-heap | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k010000', 'off/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/1GB/k010000 | on/no-heap | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k010000', 'on/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/1GB/k010000 | on/no-heap-no-radix | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k010000', 'on/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/1GB/k010000 | off/no-heap-no-radix | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k010000', 'off/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/1GB/k010000 | on/default | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k010000', 'on/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/1GB/k010000 | off/default | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k010000', 'off/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/1GB/k010000 | off/no-radix | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k010000', 'off/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/1GB/k010000 | on/no-radix | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k010000', 'on/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/1GB/k010000 | off/no-heap-no-radix | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k010000', 'off/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/1GB/k010000 | on/no-heap-no-radix | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k010000', 'on/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/1GB/k010000 | on/no-heap | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k010000', 'on/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/1GB/k010000 | off/no-heap | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k010000', 'off/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/1GB/k010000 | on/no-radix | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k010000', 'on/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/1GB/k010000 | off/no-radix | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k010000', 'off/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/1GB/k010000 | off/no-heap | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k010000', 'off/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/1GB/k010000 | on/no-heap | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k010000', 'on/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/1GB/k010000 | off/default | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k010000', 'off/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/1GB/k010000 | on/default | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k010000', 'on/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/1GB/k010000 | on/no-heap-no-radix | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k010000', 'on/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/1GB/k010000 | off/no-heap-no-radix | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k010000', 'off/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/1GB/k010000 | on/no-heap | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k010000', 'on/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/1GB/k010000 | off/no-heap | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k010000', 'off/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/1GB/k010000 | off/no-heap-no-radix | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k010000', 'off/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/1GB/k010000 | on/no-heap-no-radix | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k010000', 'on/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/1GB/k010000 | off/no-radix | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k010000', 'off/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/1GB/k010000 | on/no-radix | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k010000', 'on/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/1GB/k010000 | on/default | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k010000', 'on/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/1GB/k010000 | off/default | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k010000', 'off/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/1GB/k010000 | on/no-heap-no-radix | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k010000', 'on/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/1GB/k010000 | off/no-heap-no-radix | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k010000', 'off/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/1GB/k010000 | off/default | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k010000', 'off/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/1GB/k010000 | on/default | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k010000', 'on/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/1GB/k010000 | off/no-heap | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k010000', 'off/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/1GB/k010000 | on/no-heap | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k010000', 'on/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/1GB/k010000 | on/no-radix | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k010000', 'on/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- narrow/1GB/k010000 | off/no-radix | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k010000', 'off/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- CASE: narrow/1GB/k050000; narrow tuples; work_mem=1GB; LIMIT=50000

-- narrow/1GB/k050000 | off/default | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k050000', 'off/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/1GB/k050000 | on/default | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k050000', 'on/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/1GB/k050000 | on/no-radix | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k050000', 'on/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/1GB/k050000 | off/no-radix | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k050000', 'off/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/1GB/k050000 | off/no-heap | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k050000', 'off/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/1GB/k050000 | on/no-heap | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k050000', 'on/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/1GB/k050000 | on/no-heap-no-radix | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k050000', 'on/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/1GB/k050000 | off/no-heap-no-radix | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k050000', 'off/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/1GB/k050000 | on/default | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k050000', 'on/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/1GB/k050000 | off/default | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k050000', 'off/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/1GB/k050000 | off/no-radix | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k050000', 'off/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/1GB/k050000 | on/no-radix | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k050000', 'on/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/1GB/k050000 | off/no-heap-no-radix | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k050000', 'off/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/1GB/k050000 | on/no-heap-no-radix | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k050000', 'on/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/1GB/k050000 | on/no-heap | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k050000', 'on/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/1GB/k050000 | off/no-heap | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k050000', 'off/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/1GB/k050000 | on/no-radix | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k050000', 'on/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/1GB/k050000 | off/no-radix | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k050000', 'off/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/1GB/k050000 | off/no-heap | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k050000', 'off/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/1GB/k050000 | on/no-heap | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k050000', 'on/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/1GB/k050000 | off/default | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k050000', 'off/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/1GB/k050000 | on/default | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k050000', 'on/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/1GB/k050000 | on/no-heap-no-radix | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k050000', 'on/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/1GB/k050000 | off/no-heap-no-radix | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k050000', 'off/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/1GB/k050000 | on/no-heap | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k050000', 'on/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/1GB/k050000 | off/no-heap | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k050000', 'off/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/1GB/k050000 | off/no-heap-no-radix | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k050000', 'off/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/1GB/k050000 | on/no-heap-no-radix | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k050000', 'on/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/1GB/k050000 | off/no-radix | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k050000', 'off/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/1GB/k050000 | on/no-radix | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k050000', 'on/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/1GB/k050000 | on/default | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k050000', 'on/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/1GB/k050000 | off/default | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k050000', 'off/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/1GB/k050000 | on/no-heap-no-radix | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k050000', 'on/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/1GB/k050000 | off/no-heap-no-radix | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k050000', 'off/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/1GB/k050000 | off/default | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k050000', 'off/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/1GB/k050000 | on/default | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k050000', 'on/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/1GB/k050000 | off/no-heap | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k050000', 'off/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/1GB/k050000 | on/no-heap | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k050000', 'on/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/1GB/k050000 | on/no-radix | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k050000', 'on/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- narrow/1GB/k050000 | off/no-radix | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k050000', 'off/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- CASE: narrow/1GB/k100000; narrow tuples; work_mem=1GB; LIMIT=100000

-- narrow/1GB/k100000 | off/default | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k100000', 'off/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/1GB/k100000 | on/default | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k100000', 'on/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/1GB/k100000 | on/no-radix | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k100000', 'on/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/1GB/k100000 | off/no-radix | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k100000', 'off/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/1GB/k100000 | off/no-heap | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k100000', 'off/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/1GB/k100000 | on/no-heap | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k100000', 'on/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/1GB/k100000 | on/no-heap-no-radix | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k100000', 'on/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/1GB/k100000 | off/no-heap-no-radix | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k100000', 'off/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/1GB/k100000 | on/default | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k100000', 'on/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/1GB/k100000 | off/default | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k100000', 'off/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/1GB/k100000 | off/no-radix | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k100000', 'off/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/1GB/k100000 | on/no-radix | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k100000', 'on/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/1GB/k100000 | off/no-heap-no-radix | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k100000', 'off/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/1GB/k100000 | on/no-heap-no-radix | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k100000', 'on/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/1GB/k100000 | on/no-heap | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k100000', 'on/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/1GB/k100000 | off/no-heap | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k100000', 'off/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/1GB/k100000 | on/no-radix | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k100000', 'on/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/1GB/k100000 | off/no-radix | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k100000', 'off/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/1GB/k100000 | off/no-heap | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k100000', 'off/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/1GB/k100000 | on/no-heap | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k100000', 'on/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/1GB/k100000 | off/default | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k100000', 'off/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/1GB/k100000 | on/default | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k100000', 'on/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/1GB/k100000 | on/no-heap-no-radix | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k100000', 'on/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/1GB/k100000 | off/no-heap-no-radix | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k100000', 'off/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/1GB/k100000 | on/no-heap | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k100000', 'on/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/1GB/k100000 | off/no-heap | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k100000', 'off/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/1GB/k100000 | off/no-heap-no-radix | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k100000', 'off/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/1GB/k100000 | on/no-heap-no-radix | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k100000', 'on/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/1GB/k100000 | off/no-radix | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k100000', 'off/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/1GB/k100000 | on/no-radix | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k100000', 'on/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/1GB/k100000 | on/default | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k100000', 'on/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/1GB/k100000 | off/default | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k100000', 'off/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/1GB/k100000 | on/no-heap-no-radix | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k100000', 'on/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/1GB/k100000 | off/no-heap-no-radix | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k100000', 'off/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/1GB/k100000 | off/default | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k100000', 'off/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/1GB/k100000 | on/default | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k100000', 'on/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/1GB/k100000 | off/no-heap | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k100000', 'off/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/1GB/k100000 | on/no-heap | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k100000', 'on/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/1GB/k100000 | on/no-radix | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k100000', 'on/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- narrow/1GB/k100000 | off/no-radix | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k100000', 'off/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- CASE: narrow/1GB/k250000; narrow tuples; work_mem=1GB; LIMIT=250000

-- narrow/1GB/k250000 | off/default | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k250000', 'off/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/1GB/k250000 | on/default | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k250000', 'on/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/1GB/k250000 | on/no-radix | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k250000', 'on/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/1GB/k250000 | off/no-radix | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k250000', 'off/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/1GB/k250000 | off/no-heap | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k250000', 'off/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/1GB/k250000 | on/no-heap | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k250000', 'on/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/1GB/k250000 | on/no-heap-no-radix | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k250000', 'on/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/1GB/k250000 | off/no-heap-no-radix | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k250000', 'off/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/1GB/k250000 | on/default | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k250000', 'on/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/1GB/k250000 | off/default | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k250000', 'off/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/1GB/k250000 | off/no-radix | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k250000', 'off/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/1GB/k250000 | on/no-radix | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k250000', 'on/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/1GB/k250000 | off/no-heap-no-radix | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k250000', 'off/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/1GB/k250000 | on/no-heap-no-radix | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k250000', 'on/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/1GB/k250000 | on/no-heap | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k250000', 'on/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/1GB/k250000 | off/no-heap | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k250000', 'off/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/1GB/k250000 | on/no-radix | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k250000', 'on/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/1GB/k250000 | off/no-radix | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k250000', 'off/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/1GB/k250000 | off/no-heap | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k250000', 'off/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/1GB/k250000 | on/no-heap | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k250000', 'on/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/1GB/k250000 | off/default | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k250000', 'off/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/1GB/k250000 | on/default | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k250000', 'on/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/1GB/k250000 | on/no-heap-no-radix | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k250000', 'on/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/1GB/k250000 | off/no-heap-no-radix | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k250000', 'off/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/1GB/k250000 | on/no-heap | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k250000', 'on/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/1GB/k250000 | off/no-heap | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k250000', 'off/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/1GB/k250000 | off/no-heap-no-radix | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k250000', 'off/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/1GB/k250000 | on/no-heap-no-radix | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k250000', 'on/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/1GB/k250000 | off/no-radix | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k250000', 'off/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/1GB/k250000 | on/no-radix | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k250000', 'on/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/1GB/k250000 | on/default | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k250000', 'on/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/1GB/k250000 | off/default | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k250000', 'off/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/1GB/k250000 | on/no-heap-no-radix | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k250000', 'on/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/1GB/k250000 | off/no-heap-no-radix | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k250000', 'off/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/1GB/k250000 | off/default | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k250000', 'off/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/1GB/k250000 | on/default | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k250000', 'on/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/1GB/k250000 | off/no-heap | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k250000', 'off/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/1GB/k250000 | on/no-heap | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k250000', 'on/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/1GB/k250000 | on/no-radix | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k250000', 'on/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/1GB/k250000 | off/no-radix | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k250000', 'off/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- CASE: narrow/1GB/k500000; narrow tuples; work_mem=1GB; LIMIT=500000

-- narrow/1GB/k500000 | off/default | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k500000', 'off/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/1GB/k500000 | on/default | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k500000', 'on/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/1GB/k500000 | on/no-radix | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k500000', 'on/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/1GB/k500000 | off/no-radix | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k500000', 'off/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/1GB/k500000 | off/no-heap | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k500000', 'off/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/1GB/k500000 | on/no-heap | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k500000', 'on/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/1GB/k500000 | on/no-heap-no-radix | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k500000', 'on/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/1GB/k500000 | off/no-heap-no-radix | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k500000', 'off/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/1GB/k500000 | on/default | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k500000', 'on/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/1GB/k500000 | off/default | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k500000', 'off/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/1GB/k500000 | off/no-radix | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k500000', 'off/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/1GB/k500000 | on/no-radix | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k500000', 'on/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/1GB/k500000 | off/no-heap-no-radix | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k500000', 'off/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/1GB/k500000 | on/no-heap-no-radix | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k500000', 'on/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/1GB/k500000 | on/no-heap | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k500000', 'on/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/1GB/k500000 | off/no-heap | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k500000', 'off/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/1GB/k500000 | on/no-radix | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k500000', 'on/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/1GB/k500000 | off/no-radix | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k500000', 'off/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/1GB/k500000 | off/no-heap | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k500000', 'off/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/1GB/k500000 | on/no-heap | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k500000', 'on/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/1GB/k500000 | off/default | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k500000', 'off/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/1GB/k500000 | on/default | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k500000', 'on/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/1GB/k500000 | on/no-heap-no-radix | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k500000', 'on/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/1GB/k500000 | off/no-heap-no-radix | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k500000', 'off/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/1GB/k500000 | on/no-heap | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k500000', 'on/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/1GB/k500000 | off/no-heap | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k500000', 'off/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/1GB/k500000 | off/no-heap-no-radix | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k500000', 'off/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/1GB/k500000 | on/no-heap-no-radix | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k500000', 'on/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/1GB/k500000 | off/no-radix | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k500000', 'off/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/1GB/k500000 | on/no-radix | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k500000', 'on/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/1GB/k500000 | on/default | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k500000', 'on/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/1GB/k500000 | off/default | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k500000', 'off/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/1GB/k500000 | on/no-heap-no-radix | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k500000', 'on/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/1GB/k500000 | off/no-heap-no-radix | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k500000', 'off/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/1GB/k500000 | off/default | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k500000', 'off/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/1GB/k500000 | on/default | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k500000', 'on/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/1GB/k500000 | off/no-heap | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k500000', 'off/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/1GB/k500000 | on/no-heap | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k500000', 'on/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/1GB/k500000 | on/no-radix | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k500000', 'on/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- narrow/1GB/k500000 | off/no-radix | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k500000', 'off/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- CASE: narrow/1GB/k750000; narrow tuples; work_mem=1GB; LIMIT=750000

-- narrow/1GB/k750000 | off/default | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k750000', 'off/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/1GB/k750000 | on/default | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k750000', 'on/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/1GB/k750000 | on/no-radix | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k750000', 'on/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/1GB/k750000 | off/no-radix | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k750000', 'off/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/1GB/k750000 | off/no-heap | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k750000', 'off/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/1GB/k750000 | on/no-heap | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k750000', 'on/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/1GB/k750000 | on/no-heap-no-radix | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k750000', 'on/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/1GB/k750000 | off/no-heap-no-radix | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k750000', 'off/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/1GB/k750000 | on/default | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k750000', 'on/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/1GB/k750000 | off/default | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k750000', 'off/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/1GB/k750000 | off/no-radix | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k750000', 'off/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/1GB/k750000 | on/no-radix | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k750000', 'on/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/1GB/k750000 | off/no-heap-no-radix | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k750000', 'off/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/1GB/k750000 | on/no-heap-no-radix | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k750000', 'on/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/1GB/k750000 | on/no-heap | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k750000', 'on/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/1GB/k750000 | off/no-heap | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k750000', 'off/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/1GB/k750000 | on/no-radix | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k750000', 'on/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/1GB/k750000 | off/no-radix | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k750000', 'off/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/1GB/k750000 | off/no-heap | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k750000', 'off/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/1GB/k750000 | on/no-heap | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k750000', 'on/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/1GB/k750000 | off/default | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k750000', 'off/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/1GB/k750000 | on/default | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k750000', 'on/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/1GB/k750000 | on/no-heap-no-radix | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k750000', 'on/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/1GB/k750000 | off/no-heap-no-radix | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k750000', 'off/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/1GB/k750000 | on/no-heap | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k750000', 'on/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/1GB/k750000 | off/no-heap | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k750000', 'off/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/1GB/k750000 | off/no-heap-no-radix | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k750000', 'off/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/1GB/k750000 | on/no-heap-no-radix | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k750000', 'on/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/1GB/k750000 | off/no-radix | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k750000', 'off/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/1GB/k750000 | on/no-radix | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k750000', 'on/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/1GB/k750000 | on/default | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k750000', 'on/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/1GB/k750000 | off/default | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k750000', 'off/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/1GB/k750000 | on/no-heap-no-radix | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k750000', 'on/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/1GB/k750000 | off/no-heap-no-radix | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k750000', 'off/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/1GB/k750000 | off/default | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k750000', 'off/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/1GB/k750000 | on/default | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k750000', 'on/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/1GB/k750000 | off/no-heap | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k750000', 'off/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/1GB/k750000 | on/no-heap | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k750000', 'on/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/1GB/k750000 | on/no-radix | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/1GB/k750000', 'on/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- narrow/1GB/k750000 | off/no-radix | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/1GB/k750000', 'off/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- CASE: wide/1GB/k001000; wide tuples; work_mem=1GB; LIMIT=1000

-- wide/1GB/k001000 | off/default | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k001000', 'off/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- wide/1GB/k001000 | on/default | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k001000', 'on/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- wide/1GB/k001000 | on/no-radix | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k001000', 'on/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- wide/1GB/k001000 | off/no-radix | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k001000', 'off/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- wide/1GB/k001000 | off/no-heap | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k001000', 'off/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- wide/1GB/k001000 | on/no-heap | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k001000', 'on/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- wide/1GB/k001000 | on/no-heap-no-radix | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k001000', 'on/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- wide/1GB/k001000 | off/no-heap-no-radix | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k001000', 'off/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- wide/1GB/k001000 | on/default | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k001000', 'on/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- wide/1GB/k001000 | off/default | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k001000', 'off/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- wide/1GB/k001000 | off/no-radix | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k001000', 'off/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- wide/1GB/k001000 | on/no-radix | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k001000', 'on/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- wide/1GB/k001000 | off/no-heap-no-radix | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k001000', 'off/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- wide/1GB/k001000 | on/no-heap-no-radix | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k001000', 'on/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- wide/1GB/k001000 | on/no-heap | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k001000', 'on/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- wide/1GB/k001000 | off/no-heap | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k001000', 'off/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- wide/1GB/k001000 | on/no-radix | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k001000', 'on/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- wide/1GB/k001000 | off/no-radix | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k001000', 'off/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- wide/1GB/k001000 | off/no-heap | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k001000', 'off/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- wide/1GB/k001000 | on/no-heap | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k001000', 'on/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- wide/1GB/k001000 | off/default | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k001000', 'off/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- wide/1GB/k001000 | on/default | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k001000', 'on/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- wide/1GB/k001000 | on/no-heap-no-radix | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k001000', 'on/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- wide/1GB/k001000 | off/no-heap-no-radix | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k001000', 'off/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- wide/1GB/k001000 | on/no-heap | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k001000', 'on/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- wide/1GB/k001000 | off/no-heap | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k001000', 'off/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- wide/1GB/k001000 | off/no-heap-no-radix | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k001000', 'off/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- wide/1GB/k001000 | on/no-heap-no-radix | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k001000', 'on/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- wide/1GB/k001000 | off/no-radix | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k001000', 'off/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- wide/1GB/k001000 | on/no-radix | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k001000', 'on/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- wide/1GB/k001000 | on/default | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k001000', 'on/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- wide/1GB/k001000 | off/default | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k001000', 'off/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- wide/1GB/k001000 | on/no-heap-no-radix | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k001000', 'on/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- wide/1GB/k001000 | off/no-heap-no-radix | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k001000', 'off/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- wide/1GB/k001000 | off/default | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k001000', 'off/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- wide/1GB/k001000 | on/default | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k001000', 'on/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- wide/1GB/k001000 | off/no-heap | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k001000', 'off/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- wide/1GB/k001000 | on/no-heap | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k001000', 'on/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- wide/1GB/k001000 | on/no-radix | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k001000', 'on/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- wide/1GB/k001000 | off/no-radix | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k001000', 'off/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 1000;

-- CASE: wide/1GB/k010000; wide tuples; work_mem=1GB; LIMIT=10000

-- wide/1GB/k010000 | off/default | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k010000', 'off/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- wide/1GB/k010000 | on/default | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k010000', 'on/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- wide/1GB/k010000 | on/no-radix | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k010000', 'on/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- wide/1GB/k010000 | off/no-radix | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k010000', 'off/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- wide/1GB/k010000 | off/no-heap | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k010000', 'off/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- wide/1GB/k010000 | on/no-heap | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k010000', 'on/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- wide/1GB/k010000 | on/no-heap-no-radix | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k010000', 'on/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- wide/1GB/k010000 | off/no-heap-no-radix | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k010000', 'off/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- wide/1GB/k010000 | on/default | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k010000', 'on/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- wide/1GB/k010000 | off/default | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k010000', 'off/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- wide/1GB/k010000 | off/no-radix | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k010000', 'off/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- wide/1GB/k010000 | on/no-radix | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k010000', 'on/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- wide/1GB/k010000 | off/no-heap-no-radix | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k010000', 'off/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- wide/1GB/k010000 | on/no-heap-no-radix | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k010000', 'on/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- wide/1GB/k010000 | on/no-heap | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k010000', 'on/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- wide/1GB/k010000 | off/no-heap | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k010000', 'off/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- wide/1GB/k010000 | on/no-radix | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k010000', 'on/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- wide/1GB/k010000 | off/no-radix | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k010000', 'off/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- wide/1GB/k010000 | off/no-heap | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k010000', 'off/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- wide/1GB/k010000 | on/no-heap | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k010000', 'on/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- wide/1GB/k010000 | off/default | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k010000', 'off/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- wide/1GB/k010000 | on/default | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k010000', 'on/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- wide/1GB/k010000 | on/no-heap-no-radix | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k010000', 'on/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- wide/1GB/k010000 | off/no-heap-no-radix | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k010000', 'off/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- wide/1GB/k010000 | on/no-heap | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k010000', 'on/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- wide/1GB/k010000 | off/no-heap | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k010000', 'off/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- wide/1GB/k010000 | off/no-heap-no-radix | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k010000', 'off/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- wide/1GB/k010000 | on/no-heap-no-radix | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k010000', 'on/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- wide/1GB/k010000 | off/no-radix | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k010000', 'off/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- wide/1GB/k010000 | on/no-radix | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k010000', 'on/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- wide/1GB/k010000 | on/default | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k010000', 'on/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- wide/1GB/k010000 | off/default | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k010000', 'off/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- wide/1GB/k010000 | on/no-heap-no-radix | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k010000', 'on/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- wide/1GB/k010000 | off/no-heap-no-radix | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k010000', 'off/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- wide/1GB/k010000 | off/default | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k010000', 'off/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- wide/1GB/k010000 | on/default | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k010000', 'on/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- wide/1GB/k010000 | off/no-heap | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k010000', 'off/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- wide/1GB/k010000 | on/no-heap | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k010000', 'on/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- wide/1GB/k010000 | on/no-radix | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k010000', 'on/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- wide/1GB/k010000 | off/no-radix | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k010000', 'off/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 10000;

-- CASE: wide/1GB/k050000; wide tuples; work_mem=1GB; LIMIT=50000

-- wide/1GB/k050000 | off/default | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k050000', 'off/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- wide/1GB/k050000 | on/default | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k050000', 'on/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- wide/1GB/k050000 | on/no-radix | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k050000', 'on/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- wide/1GB/k050000 | off/no-radix | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k050000', 'off/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- wide/1GB/k050000 | off/no-heap | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k050000', 'off/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- wide/1GB/k050000 | on/no-heap | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k050000', 'on/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- wide/1GB/k050000 | on/no-heap-no-radix | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k050000', 'on/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- wide/1GB/k050000 | off/no-heap-no-radix | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k050000', 'off/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- wide/1GB/k050000 | on/default | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k050000', 'on/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- wide/1GB/k050000 | off/default | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k050000', 'off/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- wide/1GB/k050000 | off/no-radix | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k050000', 'off/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- wide/1GB/k050000 | on/no-radix | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k050000', 'on/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- wide/1GB/k050000 | off/no-heap-no-radix | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k050000', 'off/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- wide/1GB/k050000 | on/no-heap-no-radix | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k050000', 'on/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- wide/1GB/k050000 | on/no-heap | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k050000', 'on/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- wide/1GB/k050000 | off/no-heap | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k050000', 'off/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- wide/1GB/k050000 | on/no-radix | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k050000', 'on/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- wide/1GB/k050000 | off/no-radix | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k050000', 'off/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- wide/1GB/k050000 | off/no-heap | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k050000', 'off/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- wide/1GB/k050000 | on/no-heap | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k050000', 'on/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- wide/1GB/k050000 | off/default | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k050000', 'off/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- wide/1GB/k050000 | on/default | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k050000', 'on/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- wide/1GB/k050000 | on/no-heap-no-radix | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k050000', 'on/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- wide/1GB/k050000 | off/no-heap-no-radix | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k050000', 'off/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- wide/1GB/k050000 | on/no-heap | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k050000', 'on/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- wide/1GB/k050000 | off/no-heap | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k050000', 'off/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- wide/1GB/k050000 | off/no-heap-no-radix | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k050000', 'off/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- wide/1GB/k050000 | on/no-heap-no-radix | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k050000', 'on/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- wide/1GB/k050000 | off/no-radix | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k050000', 'off/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- wide/1GB/k050000 | on/no-radix | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k050000', 'on/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- wide/1GB/k050000 | on/default | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k050000', 'on/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- wide/1GB/k050000 | off/default | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k050000', 'off/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- wide/1GB/k050000 | on/no-heap-no-radix | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k050000', 'on/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- wide/1GB/k050000 | off/no-heap-no-radix | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k050000', 'off/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- wide/1GB/k050000 | off/default | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k050000', 'off/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- wide/1GB/k050000 | on/default | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k050000', 'on/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- wide/1GB/k050000 | off/no-heap | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k050000', 'off/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- wide/1GB/k050000 | on/no-heap | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k050000', 'on/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- wide/1GB/k050000 | on/no-radix | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k050000', 'on/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- wide/1GB/k050000 | off/no-radix | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k050000', 'off/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 50000;

-- CASE: wide/1GB/k100000; wide tuples; work_mem=1GB; LIMIT=100000

-- wide/1GB/k100000 | off/default | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k100000', 'off/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- wide/1GB/k100000 | on/default | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k100000', 'on/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- wide/1GB/k100000 | on/no-radix | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k100000', 'on/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- wide/1GB/k100000 | off/no-radix | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k100000', 'off/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- wide/1GB/k100000 | off/no-heap | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k100000', 'off/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- wide/1GB/k100000 | on/no-heap | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k100000', 'on/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- wide/1GB/k100000 | on/no-heap-no-radix | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k100000', 'on/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- wide/1GB/k100000 | off/no-heap-no-radix | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k100000', 'off/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- wide/1GB/k100000 | on/default | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k100000', 'on/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- wide/1GB/k100000 | off/default | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k100000', 'off/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- wide/1GB/k100000 | off/no-radix | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k100000', 'off/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- wide/1GB/k100000 | on/no-radix | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k100000', 'on/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- wide/1GB/k100000 | off/no-heap-no-radix | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k100000', 'off/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- wide/1GB/k100000 | on/no-heap-no-radix | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k100000', 'on/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- wide/1GB/k100000 | on/no-heap | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k100000', 'on/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- wide/1GB/k100000 | off/no-heap | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k100000', 'off/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- wide/1GB/k100000 | on/no-radix | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k100000', 'on/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- wide/1GB/k100000 | off/no-radix | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k100000', 'off/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- wide/1GB/k100000 | off/no-heap | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k100000', 'off/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- wide/1GB/k100000 | on/no-heap | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k100000', 'on/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- wide/1GB/k100000 | off/default | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k100000', 'off/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- wide/1GB/k100000 | on/default | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k100000', 'on/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- wide/1GB/k100000 | on/no-heap-no-radix | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k100000', 'on/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- wide/1GB/k100000 | off/no-heap-no-radix | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k100000', 'off/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- wide/1GB/k100000 | on/no-heap | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k100000', 'on/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- wide/1GB/k100000 | off/no-heap | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k100000', 'off/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- wide/1GB/k100000 | off/no-heap-no-radix | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k100000', 'off/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- wide/1GB/k100000 | on/no-heap-no-radix | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k100000', 'on/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- wide/1GB/k100000 | off/no-radix | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k100000', 'off/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- wide/1GB/k100000 | on/no-radix | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k100000', 'on/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- wide/1GB/k100000 | on/default | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k100000', 'on/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- wide/1GB/k100000 | off/default | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k100000', 'off/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- wide/1GB/k100000 | on/no-heap-no-radix | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k100000', 'on/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- wide/1GB/k100000 | off/no-heap-no-radix | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k100000', 'off/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- wide/1GB/k100000 | off/default | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k100000', 'off/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- wide/1GB/k100000 | on/default | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k100000', 'on/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- wide/1GB/k100000 | off/no-heap | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k100000', 'off/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- wide/1GB/k100000 | on/no-heap | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k100000', 'on/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- wide/1GB/k100000 | on/no-radix | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k100000', 'on/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- wide/1GB/k100000 | off/no-radix | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k100000', 'off/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 100000;

-- CASE: wide/1GB/k250000; wide tuples; work_mem=1GB; LIMIT=250000

-- wide/1GB/k250000 | off/default | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k250000', 'off/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/1GB/k250000 | on/default | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k250000', 'on/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/1GB/k250000 | on/no-radix | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k250000', 'on/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/1GB/k250000 | off/no-radix | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k250000', 'off/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/1GB/k250000 | off/no-heap | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k250000', 'off/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/1GB/k250000 | on/no-heap | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k250000', 'on/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/1GB/k250000 | on/no-heap-no-radix | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k250000', 'on/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/1GB/k250000 | off/no-heap-no-radix | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k250000', 'off/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/1GB/k250000 | on/default | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k250000', 'on/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/1GB/k250000 | off/default | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k250000', 'off/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/1GB/k250000 | off/no-radix | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k250000', 'off/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/1GB/k250000 | on/no-radix | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k250000', 'on/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/1GB/k250000 | off/no-heap-no-radix | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k250000', 'off/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/1GB/k250000 | on/no-heap-no-radix | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k250000', 'on/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/1GB/k250000 | on/no-heap | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k250000', 'on/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/1GB/k250000 | off/no-heap | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k250000', 'off/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/1GB/k250000 | on/no-radix | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k250000', 'on/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/1GB/k250000 | off/no-radix | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k250000', 'off/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/1GB/k250000 | off/no-heap | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k250000', 'off/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/1GB/k250000 | on/no-heap | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k250000', 'on/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/1GB/k250000 | off/default | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k250000', 'off/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/1GB/k250000 | on/default | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k250000', 'on/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/1GB/k250000 | on/no-heap-no-radix | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k250000', 'on/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/1GB/k250000 | off/no-heap-no-radix | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k250000', 'off/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/1GB/k250000 | on/no-heap | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k250000', 'on/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/1GB/k250000 | off/no-heap | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k250000', 'off/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/1GB/k250000 | off/no-heap-no-radix | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k250000', 'off/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/1GB/k250000 | on/no-heap-no-radix | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k250000', 'on/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/1GB/k250000 | off/no-radix | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k250000', 'off/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/1GB/k250000 | on/no-radix | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k250000', 'on/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/1GB/k250000 | on/default | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k250000', 'on/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/1GB/k250000 | off/default | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k250000', 'off/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/1GB/k250000 | on/no-heap-no-radix | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k250000', 'on/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/1GB/k250000 | off/no-heap-no-radix | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k250000', 'off/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/1GB/k250000 | off/default | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k250000', 'off/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/1GB/k250000 | on/default | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k250000', 'on/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/1GB/k250000 | off/no-heap | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k250000', 'off/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/1GB/k250000 | on/no-heap | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k250000', 'on/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/1GB/k250000 | on/no-radix | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k250000', 'on/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/1GB/k250000 | off/no-radix | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k250000', 'off/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- CASE: wide/1GB/k500000; wide tuples; work_mem=1GB; LIMIT=500000

-- wide/1GB/k500000 | off/default | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k500000', 'off/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- wide/1GB/k500000 | on/default | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k500000', 'on/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- wide/1GB/k500000 | on/no-radix | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k500000', 'on/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- wide/1GB/k500000 | off/no-radix | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k500000', 'off/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- wide/1GB/k500000 | off/no-heap | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k500000', 'off/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- wide/1GB/k500000 | on/no-heap | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k500000', 'on/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- wide/1GB/k500000 | on/no-heap-no-radix | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k500000', 'on/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- wide/1GB/k500000 | off/no-heap-no-radix | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k500000', 'off/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- wide/1GB/k500000 | on/default | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k500000', 'on/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- wide/1GB/k500000 | off/default | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k500000', 'off/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- wide/1GB/k500000 | off/no-radix | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k500000', 'off/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- wide/1GB/k500000 | on/no-radix | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k500000', 'on/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- wide/1GB/k500000 | off/no-heap-no-radix | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k500000', 'off/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- wide/1GB/k500000 | on/no-heap-no-radix | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k500000', 'on/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- wide/1GB/k500000 | on/no-heap | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k500000', 'on/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- wide/1GB/k500000 | off/no-heap | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k500000', 'off/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- wide/1GB/k500000 | on/no-radix | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k500000', 'on/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- wide/1GB/k500000 | off/no-radix | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k500000', 'off/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- wide/1GB/k500000 | off/no-heap | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k500000', 'off/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- wide/1GB/k500000 | on/no-heap | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k500000', 'on/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- wide/1GB/k500000 | off/default | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k500000', 'off/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- wide/1GB/k500000 | on/default | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k500000', 'on/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- wide/1GB/k500000 | on/no-heap-no-radix | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k500000', 'on/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- wide/1GB/k500000 | off/no-heap-no-radix | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k500000', 'off/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- wide/1GB/k500000 | on/no-heap | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k500000', 'on/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- wide/1GB/k500000 | off/no-heap | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k500000', 'off/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- wide/1GB/k500000 | off/no-heap-no-radix | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k500000', 'off/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- wide/1GB/k500000 | on/no-heap-no-radix | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k500000', 'on/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- wide/1GB/k500000 | off/no-radix | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k500000', 'off/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- wide/1GB/k500000 | on/no-radix | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k500000', 'on/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- wide/1GB/k500000 | on/default | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k500000', 'on/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- wide/1GB/k500000 | off/default | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k500000', 'off/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- wide/1GB/k500000 | on/no-heap-no-radix | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k500000', 'on/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- wide/1GB/k500000 | off/no-heap-no-radix | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k500000', 'off/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- wide/1GB/k500000 | off/default | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k500000', 'off/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- wide/1GB/k500000 | on/default | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k500000', 'on/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- wide/1GB/k500000 | off/no-heap | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k500000', 'off/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- wide/1GB/k500000 | on/no-heap | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k500000', 'on/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- wide/1GB/k500000 | on/no-radix | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k500000', 'on/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- wide/1GB/k500000 | off/no-radix | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k500000', 'off/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 500000;

-- CASE: wide/1GB/k750000; wide tuples; work_mem=1GB; LIMIT=750000

-- wide/1GB/k750000 | off/default | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k750000', 'off/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- wide/1GB/k750000 | on/default | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k750000', 'on/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- wide/1GB/k750000 | on/no-radix | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k750000', 'on/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- wide/1GB/k750000 | off/no-radix | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k750000', 'off/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- wide/1GB/k750000 | off/no-heap | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k750000', 'off/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- wide/1GB/k750000 | on/no-heap | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k750000', 'on/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- wide/1GB/k750000 | on/no-heap-no-radix | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k750000', 'on/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- wide/1GB/k750000 | off/no-heap-no-radix | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k750000', 'off/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- wide/1GB/k750000 | on/default | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k750000', 'on/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- wide/1GB/k750000 | off/default | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k750000', 'off/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- wide/1GB/k750000 | off/no-radix | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k750000', 'off/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- wide/1GB/k750000 | on/no-radix | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k750000', 'on/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- wide/1GB/k750000 | off/no-heap-no-radix | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k750000', 'off/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- wide/1GB/k750000 | on/no-heap-no-radix | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k750000', 'on/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- wide/1GB/k750000 | on/no-heap | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k750000', 'on/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- wide/1GB/k750000 | off/no-heap | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k750000', 'off/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- wide/1GB/k750000 | on/no-radix | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k750000', 'on/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- wide/1GB/k750000 | off/no-radix | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k750000', 'off/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- wide/1GB/k750000 | off/no-heap | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k750000', 'off/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- wide/1GB/k750000 | on/no-heap | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k750000', 'on/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- wide/1GB/k750000 | off/default | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k750000', 'off/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- wide/1GB/k750000 | on/default | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k750000', 'on/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- wide/1GB/k750000 | on/no-heap-no-radix | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k750000', 'on/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- wide/1GB/k750000 | off/no-heap-no-radix | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k750000', 'off/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- wide/1GB/k750000 | on/no-heap | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k750000', 'on/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- wide/1GB/k750000 | off/no-heap | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k750000', 'off/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- wide/1GB/k750000 | off/no-heap-no-radix | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k750000', 'off/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- wide/1GB/k750000 | on/no-heap-no-radix | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k750000', 'on/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- wide/1GB/k750000 | off/no-radix | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k750000', 'off/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- wide/1GB/k750000 | on/no-radix | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k750000', 'on/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- wide/1GB/k750000 | on/default | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k750000', 'on/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- wide/1GB/k750000 | off/default | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k750000', 'off/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- wide/1GB/k750000 | on/no-heap-no-radix | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k750000', 'on/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- wide/1GB/k750000 | off/no-heap-no-radix | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k750000', 'off/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- wide/1GB/k750000 | off/default | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k750000', 'off/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- wide/1GB/k750000 | on/default | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k750000', 'on/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- wide/1GB/k750000 | off/no-heap | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k750000', 'off/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- wide/1GB/k750000 | on/no-heap | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k750000', 'on/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- wide/1GB/k750000 | on/no-radix | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/1GB/k750000', 'on/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- wide/1GB/k750000 | off/no-radix | timed | batch 4
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/1GB/k750000', 'off/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

-- CASE: narrow/4MB/k250000; narrow tuples; work_mem=4MB; LIMIT=250000

-- narrow/4MB/k250000 | off/default | warmup | batch 1
SET work_mem = '4MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/4MB/k250000', 'off/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/4MB/k250000 | on/default | warmup | batch 1
SET work_mem = '4MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/4MB/k250000', 'on/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/4MB/k250000 | on/no-radix | warmup | batch 1
SET work_mem = '4MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/4MB/k250000', 'on/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/4MB/k250000 | off/no-radix | warmup | batch 1
SET work_mem = '4MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/4MB/k250000', 'off/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/4MB/k250000 | off/no-heap | warmup | batch 1
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/4MB/k250000', 'off/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/4MB/k250000 | on/no-heap | warmup | batch 1
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/4MB/k250000', 'on/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/4MB/k250000 | on/no-heap-no-radix | warmup | batch 1
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/4MB/k250000', 'on/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/4MB/k250000 | off/no-heap-no-radix | warmup | batch 1
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/4MB/k250000', 'off/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/4MB/k250000 | on/default | timed | batch 1
SET work_mem = '4MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/4MB/k250000', 'on/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/4MB/k250000 | off/default | timed | batch 1
SET work_mem = '4MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/4MB/k250000', 'off/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/4MB/k250000 | off/no-radix | timed | batch 1
SET work_mem = '4MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/4MB/k250000', 'off/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/4MB/k250000 | on/no-radix | timed | batch 1
SET work_mem = '4MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/4MB/k250000', 'on/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/4MB/k250000 | off/no-heap-no-radix | timed | batch 1
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/4MB/k250000', 'off/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/4MB/k250000 | on/no-heap-no-radix | timed | batch 1
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/4MB/k250000', 'on/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/4MB/k250000 | on/no-heap | timed | batch 1
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/4MB/k250000', 'on/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/4MB/k250000 | off/no-heap | timed | batch 1
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/4MB/k250000', 'off/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/4MB/k250000 | on/no-radix | timed | batch 2
SET work_mem = '4MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/4MB/k250000', 'on/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/4MB/k250000 | off/no-radix | timed | batch 2
SET work_mem = '4MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/4MB/k250000', 'off/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/4MB/k250000 | off/no-heap | timed | batch 2
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/4MB/k250000', 'off/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/4MB/k250000 | on/no-heap | timed | batch 2
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/4MB/k250000', 'on/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/4MB/k250000 | off/default | timed | batch 2
SET work_mem = '4MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/4MB/k250000', 'off/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/4MB/k250000 | on/default | timed | batch 2
SET work_mem = '4MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/4MB/k250000', 'on/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/4MB/k250000 | on/no-heap-no-radix | timed | batch 2
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/4MB/k250000', 'on/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/4MB/k250000 | off/no-heap-no-radix | timed | batch 2
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/4MB/k250000', 'off/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/4MB/k250000 | on/no-heap | timed | batch 3
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/4MB/k250000', 'on/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/4MB/k250000 | off/no-heap | timed | batch 3
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/4MB/k250000', 'off/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/4MB/k250000 | off/no-heap-no-radix | timed | batch 3
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/4MB/k250000', 'off/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/4MB/k250000 | on/no-heap-no-radix | timed | batch 3
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/4MB/k250000', 'on/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/4MB/k250000 | off/no-radix | timed | batch 3
SET work_mem = '4MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/4MB/k250000', 'off/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/4MB/k250000 | on/no-radix | timed | batch 3
SET work_mem = '4MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/4MB/k250000', 'on/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/4MB/k250000 | on/default | timed | batch 3
SET work_mem = '4MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/4MB/k250000', 'on/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/4MB/k250000 | off/default | timed | batch 3
SET work_mem = '4MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/4MB/k250000', 'off/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/4MB/k250000 | on/no-heap-no-radix | timed | batch 4
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/4MB/k250000', 'on/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/4MB/k250000 | off/no-heap-no-radix | timed | batch 4
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/4MB/k250000', 'off/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/4MB/k250000 | off/default | timed | batch 4
SET work_mem = '4MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/4MB/k250000', 'off/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/4MB/k250000 | on/default | timed | batch 4
SET work_mem = '4MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/4MB/k250000', 'on/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/4MB/k250000 | off/no-heap | timed | batch 4
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/4MB/k250000', 'off/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/4MB/k250000 | on/no-heap | timed | batch 4
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/4MB/k250000', 'on/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/4MB/k250000 | on/no-radix | timed | batch 4
SET work_mem = '4MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/4MB/k250000', 'on/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/4MB/k250000 | off/no-radix | timed | batch 4
SET work_mem = '4MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/4MB/k250000', 'off/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- CASE: narrow/8MB/k250000; narrow tuples; work_mem=8MB; LIMIT=250000

-- narrow/8MB/k250000 | off/default | warmup | batch 1
SET work_mem = '8MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/8MB/k250000', 'off/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/8MB/k250000 | on/default | warmup | batch 1
SET work_mem = '8MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/8MB/k250000', 'on/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/8MB/k250000 | on/no-radix | warmup | batch 1
SET work_mem = '8MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/8MB/k250000', 'on/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/8MB/k250000 | off/no-radix | warmup | batch 1
SET work_mem = '8MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/8MB/k250000', 'off/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/8MB/k250000 | off/no-heap | warmup | batch 1
SET work_mem = '8MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/8MB/k250000', 'off/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/8MB/k250000 | on/no-heap | warmup | batch 1
SET work_mem = '8MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/8MB/k250000', 'on/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/8MB/k250000 | on/no-heap-no-radix | warmup | batch 1
SET work_mem = '8MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/8MB/k250000', 'on/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/8MB/k250000 | off/no-heap-no-radix | warmup | batch 1
SET work_mem = '8MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/8MB/k250000', 'off/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/8MB/k250000 | on/default | timed | batch 1
SET work_mem = '8MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/8MB/k250000', 'on/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/8MB/k250000 | off/default | timed | batch 1
SET work_mem = '8MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/8MB/k250000', 'off/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/8MB/k250000 | off/no-radix | timed | batch 1
SET work_mem = '8MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/8MB/k250000', 'off/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/8MB/k250000 | on/no-radix | timed | batch 1
SET work_mem = '8MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/8MB/k250000', 'on/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/8MB/k250000 | off/no-heap-no-radix | timed | batch 1
SET work_mem = '8MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/8MB/k250000', 'off/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/8MB/k250000 | on/no-heap-no-radix | timed | batch 1
SET work_mem = '8MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/8MB/k250000', 'on/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/8MB/k250000 | on/no-heap | timed | batch 1
SET work_mem = '8MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/8MB/k250000', 'on/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/8MB/k250000 | off/no-heap | timed | batch 1
SET work_mem = '8MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/8MB/k250000', 'off/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/8MB/k250000 | on/no-radix | timed | batch 2
SET work_mem = '8MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/8MB/k250000', 'on/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/8MB/k250000 | off/no-radix | timed | batch 2
SET work_mem = '8MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/8MB/k250000', 'off/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/8MB/k250000 | off/no-heap | timed | batch 2
SET work_mem = '8MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/8MB/k250000', 'off/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/8MB/k250000 | on/no-heap | timed | batch 2
SET work_mem = '8MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/8MB/k250000', 'on/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/8MB/k250000 | off/default | timed | batch 2
SET work_mem = '8MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/8MB/k250000', 'off/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/8MB/k250000 | on/default | timed | batch 2
SET work_mem = '8MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/8MB/k250000', 'on/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/8MB/k250000 | on/no-heap-no-radix | timed | batch 2
SET work_mem = '8MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/8MB/k250000', 'on/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/8MB/k250000 | off/no-heap-no-radix | timed | batch 2
SET work_mem = '8MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/8MB/k250000', 'off/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/8MB/k250000 | on/no-heap | timed | batch 3
SET work_mem = '8MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/8MB/k250000', 'on/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/8MB/k250000 | off/no-heap | timed | batch 3
SET work_mem = '8MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/8MB/k250000', 'off/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/8MB/k250000 | off/no-heap-no-radix | timed | batch 3
SET work_mem = '8MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/8MB/k250000', 'off/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/8MB/k250000 | on/no-heap-no-radix | timed | batch 3
SET work_mem = '8MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/8MB/k250000', 'on/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/8MB/k250000 | off/no-radix | timed | batch 3
SET work_mem = '8MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/8MB/k250000', 'off/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/8MB/k250000 | on/no-radix | timed | batch 3
SET work_mem = '8MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/8MB/k250000', 'on/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/8MB/k250000 | on/default | timed | batch 3
SET work_mem = '8MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/8MB/k250000', 'on/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/8MB/k250000 | off/default | timed | batch 3
SET work_mem = '8MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/8MB/k250000', 'off/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/8MB/k250000 | on/no-heap-no-radix | timed | batch 4
SET work_mem = '8MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/8MB/k250000', 'on/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/8MB/k250000 | off/no-heap-no-radix | timed | batch 4
SET work_mem = '8MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/8MB/k250000', 'off/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/8MB/k250000 | off/default | timed | batch 4
SET work_mem = '8MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/8MB/k250000', 'off/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/8MB/k250000 | on/default | timed | batch 4
SET work_mem = '8MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/8MB/k250000', 'on/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/8MB/k250000 | off/no-heap | timed | batch 4
SET work_mem = '8MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/8MB/k250000', 'off/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/8MB/k250000 | on/no-heap | timed | batch 4
SET work_mem = '8MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/8MB/k250000', 'on/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/8MB/k250000 | on/no-radix | timed | batch 4
SET work_mem = '8MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/8MB/k250000', 'on/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/8MB/k250000 | off/no-radix | timed | batch 4
SET work_mem = '8MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/8MB/k250000', 'off/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- CASE: narrow/16MB/k250000; narrow tuples; work_mem=16MB; LIMIT=250000

-- narrow/16MB/k250000 | off/default | warmup | batch 1
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/16MB/k250000', 'off/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/16MB/k250000 | on/default | warmup | batch 1
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/16MB/k250000', 'on/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/16MB/k250000 | on/no-radix | warmup | batch 1
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/16MB/k250000', 'on/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/16MB/k250000 | off/no-radix | warmup | batch 1
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/16MB/k250000', 'off/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/16MB/k250000 | off/no-heap | warmup | batch 1
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/16MB/k250000', 'off/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/16MB/k250000 | on/no-heap | warmup | batch 1
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/16MB/k250000', 'on/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/16MB/k250000 | on/no-heap-no-radix | warmup | batch 1
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/16MB/k250000', 'on/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/16MB/k250000 | off/no-heap-no-radix | warmup | batch 1
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/16MB/k250000', 'off/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/16MB/k250000 | on/default | timed | batch 1
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/16MB/k250000', 'on/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/16MB/k250000 | off/default | timed | batch 1
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/16MB/k250000', 'off/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/16MB/k250000 | off/no-radix | timed | batch 1
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/16MB/k250000', 'off/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/16MB/k250000 | on/no-radix | timed | batch 1
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/16MB/k250000', 'on/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/16MB/k250000 | off/no-heap-no-radix | timed | batch 1
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/16MB/k250000', 'off/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/16MB/k250000 | on/no-heap-no-radix | timed | batch 1
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/16MB/k250000', 'on/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/16MB/k250000 | on/no-heap | timed | batch 1
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/16MB/k250000', 'on/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/16MB/k250000 | off/no-heap | timed | batch 1
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/16MB/k250000', 'off/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/16MB/k250000 | on/no-radix | timed | batch 2
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/16MB/k250000', 'on/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/16MB/k250000 | off/no-radix | timed | batch 2
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/16MB/k250000', 'off/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/16MB/k250000 | off/no-heap | timed | batch 2
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/16MB/k250000', 'off/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/16MB/k250000 | on/no-heap | timed | batch 2
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/16MB/k250000', 'on/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/16MB/k250000 | off/default | timed | batch 2
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/16MB/k250000', 'off/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/16MB/k250000 | on/default | timed | batch 2
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/16MB/k250000', 'on/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/16MB/k250000 | on/no-heap-no-radix | timed | batch 2
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/16MB/k250000', 'on/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/16MB/k250000 | off/no-heap-no-radix | timed | batch 2
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/16MB/k250000', 'off/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/16MB/k250000 | on/no-heap | timed | batch 3
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/16MB/k250000', 'on/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/16MB/k250000 | off/no-heap | timed | batch 3
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/16MB/k250000', 'off/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/16MB/k250000 | off/no-heap-no-radix | timed | batch 3
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/16MB/k250000', 'off/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/16MB/k250000 | on/no-heap-no-radix | timed | batch 3
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/16MB/k250000', 'on/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/16MB/k250000 | off/no-radix | timed | batch 3
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/16MB/k250000', 'off/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/16MB/k250000 | on/no-radix | timed | batch 3
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/16MB/k250000', 'on/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/16MB/k250000 | on/default | timed | batch 3
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/16MB/k250000', 'on/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/16MB/k250000 | off/default | timed | batch 3
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/16MB/k250000', 'off/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/16MB/k250000 | on/no-heap-no-radix | timed | batch 4
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/16MB/k250000', 'on/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/16MB/k250000 | off/no-heap-no-radix | timed | batch 4
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/16MB/k250000', 'off/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/16MB/k250000 | off/default | timed | batch 4
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/16MB/k250000', 'off/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/16MB/k250000 | on/default | timed | batch 4
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/16MB/k250000', 'on/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/16MB/k250000 | off/no-heap | timed | batch 4
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/16MB/k250000', 'off/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/16MB/k250000 | on/no-heap | timed | batch 4
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/16MB/k250000', 'on/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/16MB/k250000 | on/no-radix | timed | batch 4
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/16MB/k250000', 'on/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/16MB/k250000 | off/no-radix | timed | batch 4
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/16MB/k250000', 'off/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- CASE: narrow/24MB/k250000; narrow tuples; work_mem=24MB; LIMIT=250000

-- narrow/24MB/k250000 | off/default | warmup | batch 1
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/24MB/k250000', 'off/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/24MB/k250000 | on/default | warmup | batch 1
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/24MB/k250000', 'on/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/24MB/k250000 | on/no-radix | warmup | batch 1
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/24MB/k250000', 'on/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/24MB/k250000 | off/no-radix | warmup | batch 1
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/24MB/k250000', 'off/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/24MB/k250000 | off/no-heap | warmup | batch 1
SET work_mem = '24MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/24MB/k250000', 'off/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/24MB/k250000 | on/no-heap | warmup | batch 1
SET work_mem = '24MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/24MB/k250000', 'on/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/24MB/k250000 | on/no-heap-no-radix | warmup | batch 1
SET work_mem = '24MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/24MB/k250000', 'on/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/24MB/k250000 | off/no-heap-no-radix | warmup | batch 1
SET work_mem = '24MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/24MB/k250000', 'off/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/24MB/k250000 | on/default | timed | batch 1
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/24MB/k250000', 'on/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/24MB/k250000 | off/default | timed | batch 1
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/24MB/k250000', 'off/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/24MB/k250000 | off/no-radix | timed | batch 1
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/24MB/k250000', 'off/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/24MB/k250000 | on/no-radix | timed | batch 1
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/24MB/k250000', 'on/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/24MB/k250000 | off/no-heap-no-radix | timed | batch 1
SET work_mem = '24MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/24MB/k250000', 'off/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/24MB/k250000 | on/no-heap-no-radix | timed | batch 1
SET work_mem = '24MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/24MB/k250000', 'on/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/24MB/k250000 | on/no-heap | timed | batch 1
SET work_mem = '24MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/24MB/k250000', 'on/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/24MB/k250000 | off/no-heap | timed | batch 1
SET work_mem = '24MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/24MB/k250000', 'off/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/24MB/k250000 | on/no-radix | timed | batch 2
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/24MB/k250000', 'on/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/24MB/k250000 | off/no-radix | timed | batch 2
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/24MB/k250000', 'off/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/24MB/k250000 | off/no-heap | timed | batch 2
SET work_mem = '24MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/24MB/k250000', 'off/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/24MB/k250000 | on/no-heap | timed | batch 2
SET work_mem = '24MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/24MB/k250000', 'on/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/24MB/k250000 | off/default | timed | batch 2
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/24MB/k250000', 'off/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/24MB/k250000 | on/default | timed | batch 2
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/24MB/k250000', 'on/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/24MB/k250000 | on/no-heap-no-radix | timed | batch 2
SET work_mem = '24MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/24MB/k250000', 'on/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/24MB/k250000 | off/no-heap-no-radix | timed | batch 2
SET work_mem = '24MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/24MB/k250000', 'off/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/24MB/k250000 | on/no-heap | timed | batch 3
SET work_mem = '24MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/24MB/k250000', 'on/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/24MB/k250000 | off/no-heap | timed | batch 3
SET work_mem = '24MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/24MB/k250000', 'off/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/24MB/k250000 | off/no-heap-no-radix | timed | batch 3
SET work_mem = '24MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/24MB/k250000', 'off/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/24MB/k250000 | on/no-heap-no-radix | timed | batch 3
SET work_mem = '24MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/24MB/k250000', 'on/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/24MB/k250000 | off/no-radix | timed | batch 3
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/24MB/k250000', 'off/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/24MB/k250000 | on/no-radix | timed | batch 3
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/24MB/k250000', 'on/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/24MB/k250000 | on/default | timed | batch 3
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/24MB/k250000', 'on/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/24MB/k250000 | off/default | timed | batch 3
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/24MB/k250000', 'off/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/24MB/k250000 | on/no-heap-no-radix | timed | batch 4
SET work_mem = '24MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/24MB/k250000', 'on/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/24MB/k250000 | off/no-heap-no-radix | timed | batch 4
SET work_mem = '24MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/24MB/k250000', 'off/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/24MB/k250000 | off/default | timed | batch 4
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/24MB/k250000', 'off/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/24MB/k250000 | on/default | timed | batch 4
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/24MB/k250000', 'on/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/24MB/k250000 | off/no-heap | timed | batch 4
SET work_mem = '24MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/24MB/k250000', 'off/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/24MB/k250000 | on/no-heap | timed | batch 4
SET work_mem = '24MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/24MB/k250000', 'on/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/24MB/k250000 | on/no-radix | timed | batch 4
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('narrow/24MB/k250000', 'on/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- narrow/24MB/k250000 | off/no-radix | timed | batch 4
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('narrow/24MB/k250000', 'off/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- CASE: wide/4MB/k250000; wide tuples; work_mem=4MB; LIMIT=250000

-- wide/4MB/k250000 | off/default | warmup | batch 1
SET work_mem = '4MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/4MB/k250000', 'off/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/4MB/k250000 | on/default | warmup | batch 1
SET work_mem = '4MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/4MB/k250000', 'on/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/4MB/k250000 | on/no-radix | warmup | batch 1
SET work_mem = '4MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/4MB/k250000', 'on/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/4MB/k250000 | off/no-radix | warmup | batch 1
SET work_mem = '4MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/4MB/k250000', 'off/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/4MB/k250000 | off/no-heap | warmup | batch 1
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/4MB/k250000', 'off/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/4MB/k250000 | on/no-heap | warmup | batch 1
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/4MB/k250000', 'on/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/4MB/k250000 | on/no-heap-no-radix | warmup | batch 1
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/4MB/k250000', 'on/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/4MB/k250000 | off/no-heap-no-radix | warmup | batch 1
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/4MB/k250000', 'off/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/4MB/k250000 | on/default | timed | batch 1
SET work_mem = '4MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/4MB/k250000', 'on/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/4MB/k250000 | off/default | timed | batch 1
SET work_mem = '4MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/4MB/k250000', 'off/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/4MB/k250000 | off/no-radix | timed | batch 1
SET work_mem = '4MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/4MB/k250000', 'off/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/4MB/k250000 | on/no-radix | timed | batch 1
SET work_mem = '4MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/4MB/k250000', 'on/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/4MB/k250000 | off/no-heap-no-radix | timed | batch 1
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/4MB/k250000', 'off/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/4MB/k250000 | on/no-heap-no-radix | timed | batch 1
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/4MB/k250000', 'on/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/4MB/k250000 | on/no-heap | timed | batch 1
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/4MB/k250000', 'on/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/4MB/k250000 | off/no-heap | timed | batch 1
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/4MB/k250000', 'off/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/4MB/k250000 | on/no-radix | timed | batch 2
SET work_mem = '4MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/4MB/k250000', 'on/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/4MB/k250000 | off/no-radix | timed | batch 2
SET work_mem = '4MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/4MB/k250000', 'off/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/4MB/k250000 | off/no-heap | timed | batch 2
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/4MB/k250000', 'off/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/4MB/k250000 | on/no-heap | timed | batch 2
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/4MB/k250000', 'on/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/4MB/k250000 | off/default | timed | batch 2
SET work_mem = '4MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/4MB/k250000', 'off/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/4MB/k250000 | on/default | timed | batch 2
SET work_mem = '4MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/4MB/k250000', 'on/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/4MB/k250000 | on/no-heap-no-radix | timed | batch 2
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/4MB/k250000', 'on/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/4MB/k250000 | off/no-heap-no-radix | timed | batch 2
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/4MB/k250000', 'off/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/4MB/k250000 | on/no-heap | timed | batch 3
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/4MB/k250000', 'on/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/4MB/k250000 | off/no-heap | timed | batch 3
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/4MB/k250000', 'off/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/4MB/k250000 | off/no-heap-no-radix | timed | batch 3
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/4MB/k250000', 'off/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/4MB/k250000 | on/no-heap-no-radix | timed | batch 3
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/4MB/k250000', 'on/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/4MB/k250000 | off/no-radix | timed | batch 3
SET work_mem = '4MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/4MB/k250000', 'off/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/4MB/k250000 | on/no-radix | timed | batch 3
SET work_mem = '4MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/4MB/k250000', 'on/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/4MB/k250000 | on/default | timed | batch 3
SET work_mem = '4MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/4MB/k250000', 'on/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/4MB/k250000 | off/default | timed | batch 3
SET work_mem = '4MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/4MB/k250000', 'off/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/4MB/k250000 | on/no-heap-no-radix | timed | batch 4
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/4MB/k250000', 'on/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/4MB/k250000 | off/no-heap-no-radix | timed | batch 4
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/4MB/k250000', 'off/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/4MB/k250000 | off/default | timed | batch 4
SET work_mem = '4MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/4MB/k250000', 'off/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/4MB/k250000 | on/default | timed | batch 4
SET work_mem = '4MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/4MB/k250000', 'on/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/4MB/k250000 | off/no-heap | timed | batch 4
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/4MB/k250000', 'off/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/4MB/k250000 | on/no-heap | timed | batch 4
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/4MB/k250000', 'on/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/4MB/k250000 | on/no-radix | timed | batch 4
SET work_mem = '4MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/4MB/k250000', 'on/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/4MB/k250000 | off/no-radix | timed | batch 4
SET work_mem = '4MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/4MB/k250000', 'off/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- CASE: wide/8MB/k250000; wide tuples; work_mem=8MB; LIMIT=250000

-- wide/8MB/k250000 | off/default | warmup | batch 1
SET work_mem = '8MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/8MB/k250000', 'off/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/8MB/k250000 | on/default | warmup | batch 1
SET work_mem = '8MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/8MB/k250000', 'on/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/8MB/k250000 | on/no-radix | warmup | batch 1
SET work_mem = '8MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/8MB/k250000', 'on/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/8MB/k250000 | off/no-radix | warmup | batch 1
SET work_mem = '8MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/8MB/k250000', 'off/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/8MB/k250000 | off/no-heap | warmup | batch 1
SET work_mem = '8MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/8MB/k250000', 'off/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/8MB/k250000 | on/no-heap | warmup | batch 1
SET work_mem = '8MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/8MB/k250000', 'on/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/8MB/k250000 | on/no-heap-no-radix | warmup | batch 1
SET work_mem = '8MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/8MB/k250000', 'on/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/8MB/k250000 | off/no-heap-no-radix | warmup | batch 1
SET work_mem = '8MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/8MB/k250000', 'off/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/8MB/k250000 | on/default | timed | batch 1
SET work_mem = '8MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/8MB/k250000', 'on/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/8MB/k250000 | off/default | timed | batch 1
SET work_mem = '8MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/8MB/k250000', 'off/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/8MB/k250000 | off/no-radix | timed | batch 1
SET work_mem = '8MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/8MB/k250000', 'off/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/8MB/k250000 | on/no-radix | timed | batch 1
SET work_mem = '8MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/8MB/k250000', 'on/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/8MB/k250000 | off/no-heap-no-radix | timed | batch 1
SET work_mem = '8MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/8MB/k250000', 'off/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/8MB/k250000 | on/no-heap-no-radix | timed | batch 1
SET work_mem = '8MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/8MB/k250000', 'on/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/8MB/k250000 | on/no-heap | timed | batch 1
SET work_mem = '8MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/8MB/k250000', 'on/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/8MB/k250000 | off/no-heap | timed | batch 1
SET work_mem = '8MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/8MB/k250000', 'off/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/8MB/k250000 | on/no-radix | timed | batch 2
SET work_mem = '8MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/8MB/k250000', 'on/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/8MB/k250000 | off/no-radix | timed | batch 2
SET work_mem = '8MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/8MB/k250000', 'off/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/8MB/k250000 | off/no-heap | timed | batch 2
SET work_mem = '8MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/8MB/k250000', 'off/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/8MB/k250000 | on/no-heap | timed | batch 2
SET work_mem = '8MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/8MB/k250000', 'on/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/8MB/k250000 | off/default | timed | batch 2
SET work_mem = '8MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/8MB/k250000', 'off/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/8MB/k250000 | on/default | timed | batch 2
SET work_mem = '8MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/8MB/k250000', 'on/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/8MB/k250000 | on/no-heap-no-radix | timed | batch 2
SET work_mem = '8MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/8MB/k250000', 'on/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/8MB/k250000 | off/no-heap-no-radix | timed | batch 2
SET work_mem = '8MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/8MB/k250000', 'off/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/8MB/k250000 | on/no-heap | timed | batch 3
SET work_mem = '8MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/8MB/k250000', 'on/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/8MB/k250000 | off/no-heap | timed | batch 3
SET work_mem = '8MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/8MB/k250000', 'off/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/8MB/k250000 | off/no-heap-no-radix | timed | batch 3
SET work_mem = '8MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/8MB/k250000', 'off/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/8MB/k250000 | on/no-heap-no-radix | timed | batch 3
SET work_mem = '8MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/8MB/k250000', 'on/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/8MB/k250000 | off/no-radix | timed | batch 3
SET work_mem = '8MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/8MB/k250000', 'off/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/8MB/k250000 | on/no-radix | timed | batch 3
SET work_mem = '8MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/8MB/k250000', 'on/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/8MB/k250000 | on/default | timed | batch 3
SET work_mem = '8MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/8MB/k250000', 'on/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/8MB/k250000 | off/default | timed | batch 3
SET work_mem = '8MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/8MB/k250000', 'off/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/8MB/k250000 | on/no-heap-no-radix | timed | batch 4
SET work_mem = '8MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/8MB/k250000', 'on/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/8MB/k250000 | off/no-heap-no-radix | timed | batch 4
SET work_mem = '8MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/8MB/k250000', 'off/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/8MB/k250000 | off/default | timed | batch 4
SET work_mem = '8MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/8MB/k250000', 'off/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/8MB/k250000 | on/default | timed | batch 4
SET work_mem = '8MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/8MB/k250000', 'on/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/8MB/k250000 | off/no-heap | timed | batch 4
SET work_mem = '8MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/8MB/k250000', 'off/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/8MB/k250000 | on/no-heap | timed | batch 4
SET work_mem = '8MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/8MB/k250000', 'on/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/8MB/k250000 | on/no-radix | timed | batch 4
SET work_mem = '8MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/8MB/k250000', 'on/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/8MB/k250000 | off/no-radix | timed | batch 4
SET work_mem = '8MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/8MB/k250000', 'off/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- CASE: wide/16MB/k250000; wide tuples; work_mem=16MB; LIMIT=250000

-- wide/16MB/k250000 | off/default | warmup | batch 1
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/16MB/k250000', 'off/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/16MB/k250000 | on/default | warmup | batch 1
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/16MB/k250000', 'on/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/16MB/k250000 | on/no-radix | warmup | batch 1
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/16MB/k250000', 'on/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/16MB/k250000 | off/no-radix | warmup | batch 1
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/16MB/k250000', 'off/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/16MB/k250000 | off/no-heap | warmup | batch 1
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/16MB/k250000', 'off/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/16MB/k250000 | on/no-heap | warmup | batch 1
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/16MB/k250000', 'on/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/16MB/k250000 | on/no-heap-no-radix | warmup | batch 1
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/16MB/k250000', 'on/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/16MB/k250000 | off/no-heap-no-radix | warmup | batch 1
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/16MB/k250000', 'off/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/16MB/k250000 | on/default | timed | batch 1
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/16MB/k250000', 'on/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/16MB/k250000 | off/default | timed | batch 1
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/16MB/k250000', 'off/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/16MB/k250000 | off/no-radix | timed | batch 1
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/16MB/k250000', 'off/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/16MB/k250000 | on/no-radix | timed | batch 1
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/16MB/k250000', 'on/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/16MB/k250000 | off/no-heap-no-radix | timed | batch 1
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/16MB/k250000', 'off/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/16MB/k250000 | on/no-heap-no-radix | timed | batch 1
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/16MB/k250000', 'on/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/16MB/k250000 | on/no-heap | timed | batch 1
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/16MB/k250000', 'on/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/16MB/k250000 | off/no-heap | timed | batch 1
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/16MB/k250000', 'off/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/16MB/k250000 | on/no-radix | timed | batch 2
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/16MB/k250000', 'on/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/16MB/k250000 | off/no-radix | timed | batch 2
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/16MB/k250000', 'off/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/16MB/k250000 | off/no-heap | timed | batch 2
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/16MB/k250000', 'off/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/16MB/k250000 | on/no-heap | timed | batch 2
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/16MB/k250000', 'on/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/16MB/k250000 | off/default | timed | batch 2
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/16MB/k250000', 'off/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/16MB/k250000 | on/default | timed | batch 2
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/16MB/k250000', 'on/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/16MB/k250000 | on/no-heap-no-radix | timed | batch 2
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/16MB/k250000', 'on/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/16MB/k250000 | off/no-heap-no-radix | timed | batch 2
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/16MB/k250000', 'off/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/16MB/k250000 | on/no-heap | timed | batch 3
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/16MB/k250000', 'on/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/16MB/k250000 | off/no-heap | timed | batch 3
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/16MB/k250000', 'off/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/16MB/k250000 | off/no-heap-no-radix | timed | batch 3
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/16MB/k250000', 'off/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/16MB/k250000 | on/no-heap-no-radix | timed | batch 3
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/16MB/k250000', 'on/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/16MB/k250000 | off/no-radix | timed | batch 3
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/16MB/k250000', 'off/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/16MB/k250000 | on/no-radix | timed | batch 3
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/16MB/k250000', 'on/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/16MB/k250000 | on/default | timed | batch 3
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/16MB/k250000', 'on/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/16MB/k250000 | off/default | timed | batch 3
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/16MB/k250000', 'off/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/16MB/k250000 | on/no-heap-no-radix | timed | batch 4
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/16MB/k250000', 'on/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/16MB/k250000 | off/no-heap-no-radix | timed | batch 4
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/16MB/k250000', 'off/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/16MB/k250000 | off/default | timed | batch 4
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/16MB/k250000', 'off/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/16MB/k250000 | on/default | timed | batch 4
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/16MB/k250000', 'on/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/16MB/k250000 | off/no-heap | timed | batch 4
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/16MB/k250000', 'off/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/16MB/k250000 | on/no-heap | timed | batch 4
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/16MB/k250000', 'on/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/16MB/k250000 | on/no-radix | timed | batch 4
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/16MB/k250000', 'on/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/16MB/k250000 | off/no-radix | timed | batch 4
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/16MB/k250000', 'off/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- CASE: wide/24MB/k250000; wide tuples; work_mem=24MB; LIMIT=250000

-- wide/24MB/k250000 | off/default | warmup | batch 1
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/24MB/k250000', 'off/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/24MB/k250000 | on/default | warmup | batch 1
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/24MB/k250000', 'on/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/24MB/k250000 | on/no-radix | warmup | batch 1
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/24MB/k250000', 'on/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/24MB/k250000 | off/no-radix | warmup | batch 1
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/24MB/k250000', 'off/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/24MB/k250000 | off/no-heap | warmup | batch 1
SET work_mem = '24MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/24MB/k250000', 'off/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/24MB/k250000 | on/no-heap | warmup | batch 1
SET work_mem = '24MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/24MB/k250000', 'on/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/24MB/k250000 | on/no-heap-no-radix | warmup | batch 1
SET work_mem = '24MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/24MB/k250000', 'on/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/24MB/k250000 | off/no-heap-no-radix | warmup | batch 1
SET work_mem = '24MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/24MB/k250000', 'off/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/24MB/k250000 | on/default | timed | batch 1
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/24MB/k250000', 'on/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/24MB/k250000 | off/default | timed | batch 1
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/24MB/k250000', 'off/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/24MB/k250000 | off/no-radix | timed | batch 1
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/24MB/k250000', 'off/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/24MB/k250000 | on/no-radix | timed | batch 1
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/24MB/k250000', 'on/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/24MB/k250000 | off/no-heap-no-radix | timed | batch 1
SET work_mem = '24MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/24MB/k250000', 'off/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/24MB/k250000 | on/no-heap-no-radix | timed | batch 1
SET work_mem = '24MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/24MB/k250000', 'on/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/24MB/k250000 | on/no-heap | timed | batch 1
SET work_mem = '24MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/24MB/k250000', 'on/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/24MB/k250000 | off/no-heap | timed | batch 1
SET work_mem = '24MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/24MB/k250000', 'off/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/24MB/k250000 | on/no-radix | timed | batch 2
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/24MB/k250000', 'on/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/24MB/k250000 | off/no-radix | timed | batch 2
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/24MB/k250000', 'off/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/24MB/k250000 | off/no-heap | timed | batch 2
SET work_mem = '24MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/24MB/k250000', 'off/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/24MB/k250000 | on/no-heap | timed | batch 2
SET work_mem = '24MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/24MB/k250000', 'on/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/24MB/k250000 | off/default | timed | batch 2
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/24MB/k250000', 'off/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/24MB/k250000 | on/default | timed | batch 2
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/24MB/k250000', 'on/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/24MB/k250000 | on/no-heap-no-radix | timed | batch 2
SET work_mem = '24MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/24MB/k250000', 'on/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/24MB/k250000 | off/no-heap-no-radix | timed | batch 2
SET work_mem = '24MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/24MB/k250000', 'off/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/24MB/k250000 | on/no-heap | timed | batch 3
SET work_mem = '24MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/24MB/k250000', 'on/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/24MB/k250000 | off/no-heap | timed | batch 3
SET work_mem = '24MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/24MB/k250000', 'off/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/24MB/k250000 | off/no-heap-no-radix | timed | batch 3
SET work_mem = '24MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/24MB/k250000', 'off/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/24MB/k250000 | on/no-heap-no-radix | timed | batch 3
SET work_mem = '24MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/24MB/k250000', 'on/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/24MB/k250000 | off/no-radix | timed | batch 3
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/24MB/k250000', 'off/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/24MB/k250000 | on/no-radix | timed | batch 3
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/24MB/k250000', 'on/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/24MB/k250000 | on/default | timed | batch 3
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/24MB/k250000', 'on/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/24MB/k250000 | off/default | timed | batch 3
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/24MB/k250000', 'off/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/24MB/k250000 | on/no-heap-no-radix | timed | batch 4
SET work_mem = '24MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/24MB/k250000', 'on/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/24MB/k250000 | off/no-heap-no-radix | timed | batch 4
SET work_mem = '24MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/24MB/k250000', 'off/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/24MB/k250000 | off/default | timed | batch 4
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/24MB/k250000', 'off/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/24MB/k250000 | on/default | timed | batch 4
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/24MB/k250000', 'on/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/24MB/k250000 | off/no-heap | timed | batch 4
SET work_mem = '24MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/24MB/k250000', 'off/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/24MB/k250000 | on/no-heap | timed | batch 4
SET work_mem = '24MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/24MB/k250000', 'on/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/24MB/k250000 | on/no-radix | timed | batch 4
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/24MB/k250000', 'on/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/24MB/k250000 | off/no-radix | timed | batch 4
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/24MB/k250000', 'off/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- CASE: wide/32MB/k250000; wide tuples; work_mem=32MB; LIMIT=250000

-- wide/32MB/k250000 | off/default | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/32MB/k250000', 'off/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/32MB/k250000 | on/default | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/32MB/k250000', 'on/default', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/32MB/k250000 | on/no-radix | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/32MB/k250000', 'on/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/32MB/k250000 | off/no-radix | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/32MB/k250000', 'off/no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/32MB/k250000 | off/no-heap | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/32MB/k250000', 'off/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/32MB/k250000 | on/no-heap | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/32MB/k250000', 'on/no-heap', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/32MB/k250000 | on/no-heap-no-radix | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/32MB/k250000', 'on/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/32MB/k250000 | off/no-heap-no-radix | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/32MB/k250000', 'off/no-heap-no-radix', 'matrix', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/32MB/k250000 | on/default | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/32MB/k250000', 'on/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/32MB/k250000 | off/default | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/32MB/k250000', 'off/default', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/32MB/k250000 | off/no-radix | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/32MB/k250000', 'off/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/32MB/k250000 | on/no-radix | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/32MB/k250000', 'on/no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/32MB/k250000 | off/no-heap-no-radix | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/32MB/k250000', 'off/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/32MB/k250000 | on/no-heap-no-radix | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/32MB/k250000', 'on/no-heap-no-radix', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/32MB/k250000 | on/no-heap | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/32MB/k250000', 'on/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/32MB/k250000 | off/no-heap | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/32MB/k250000', 'off/no-heap', 'matrix', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/32MB/k250000 | on/no-radix | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/32MB/k250000', 'on/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/32MB/k250000 | off/no-radix | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/32MB/k250000', 'off/no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/32MB/k250000 | off/no-heap | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/32MB/k250000', 'off/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/32MB/k250000 | on/no-heap | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/32MB/k250000', 'on/no-heap', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/32MB/k250000 | off/default | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/32MB/k250000', 'off/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/32MB/k250000 | on/default | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/32MB/k250000', 'on/default', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/32MB/k250000 | on/no-heap-no-radix | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/32MB/k250000', 'on/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/32MB/k250000 | off/no-heap-no-radix | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/32MB/k250000', 'off/no-heap-no-radix', 'matrix', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/32MB/k250000 | on/no-heap | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/32MB/k250000', 'on/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/32MB/k250000 | off/no-heap | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/32MB/k250000', 'off/no-heap', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/32MB/k250000 | off/no-heap-no-radix | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/32MB/k250000', 'off/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/32MB/k250000 | on/no-heap-no-radix | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/32MB/k250000', 'on/no-heap-no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/32MB/k250000 | off/no-radix | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/32MB/k250000', 'off/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/32MB/k250000 | on/no-radix | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/32MB/k250000', 'on/no-radix', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/32MB/k250000 | on/default | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/32MB/k250000', 'on/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/32MB/k250000 | off/default | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/32MB/k250000', 'off/default', 'matrix', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/32MB/k250000 | on/no-heap-no-radix | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/32MB/k250000', 'on/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/32MB/k250000 | off/no-heap-no-radix | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/32MB/k250000', 'off/no-heap-no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/32MB/k250000 | off/default | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/32MB/k250000', 'off/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/32MB/k250000 | on/default | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/32MB/k250000', 'on/default', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/32MB/k250000 | off/no-heap | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/32MB/k250000', 'off/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/32MB/k250000 | on/no-heap | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/32MB/k250000', 'on/no-heap', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/32MB/k250000 | on/no-radix | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('wide/32MB/k250000', 'on/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- wide/32MB/k250000 | off/no-radix | timed | batch 4
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('wide/32MB/k250000', 'off/no-radix', 'matrix', 'timed', 4);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

SELECT sortbench_capture_end();
\o
SELECT sortbench_file_reset();
\copy pg_temp.sortbench_file_lines(line) FROM 'sortbench-plans.log' WITH (FORMAT csv, DELIMITER E'\x01', QUOTE E'\x02')
\pset format aligned
\pset tuples_only off
\echo '== Capture completeness =='
SELECT sortbench_file_load();
\echo '== Corrected heap memory must match ascending control; baseline may retain roots =='
SELECT * FROM sortbench_heap_checks();
\echo '== Matrix completeness, identical planner estimates and controlled settings =='
SELECT * FROM sortbench_file_checks();
\echo '== Main A/B result: release ON / OFF; below 1 means ON is faster =='
SELECT * FROM sortbench_file_ratios() WHERE scope='release';
\echo '== Execution time medians and actual sort methods; excludes warmup and diagnostics =='
SELECT * FROM sortbench_file_report() WHERE timed_samples>0;
\echo '== Strategy comparisons, separately within release OFF and ON =='
SELECT * FROM sortbench_file_ratios() WHERE scope='strategy';
\echo '== Estimated cost increments and temporary IO =='
SELECT * FROM sortbench_file_costs();
\echo '== Individual timed batches =='
SELECT * FROM pg_temp.sortbench_file_batches ORDER BY case_name,variant,batch;

-- Separate traced runs. Never included in the statistics above.
SET client_min_messages = log;
SET trace_sort = on;

\echo '== TRACE: narrow/16MB/k250000/off/default; timing excluded =='
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== TRACE: narrow/16MB/k250000/on/default; timing excluded =='
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== TRACE: narrow/16MB/k250000/off/no-heap; timing excluded =='
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== TRACE: narrow/16MB/k250000/on/no-heap; timing excluded =='
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== TRACE: narrow/24MB/k250000/off/default; timing excluded =='
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== TRACE: narrow/24MB/k250000/on/default; timing excluded =='
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== TRACE: narrow/24MB/k250000/off/no-heap; timing excluded =='
SET work_mem = '24MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== TRACE: narrow/24MB/k250000/on/no-heap; timing excluded =='
SET work_mem = '24MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== TRACE: narrow/28MB/k250000/off/default; timing excluded =='
SET work_mem = '28MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== TRACE: narrow/28MB/k250000/on/default; timing excluded =='
SET work_mem = '28MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== TRACE: narrow/28MB/k250000/off/no-heap; timing excluded =='
SET work_mem = '28MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== TRACE: narrow/28MB/k250000/on/no-heap; timing excluded =='
SET work_mem = '28MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== TRACE: narrow/32MB/k250000/off/default; timing excluded =='
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== TRACE: narrow/32MB/k250000/on/default; timing excluded =='
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== TRACE: narrow/32MB/k250000/off/no-radix; timing excluded =='
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== TRACE: narrow/32MB/k250000/on/no-radix; timing excluded =='
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== TRACE: narrow/32MB/k250000/off/no-heap; timing excluded =='
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== TRACE: narrow/32MB/k250000/on/no-heap; timing excluded =='
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== TRACE: narrow/32MB/k250000/off/no-heap-no-radix; timing excluded =='
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== TRACE: narrow/32MB/k250000/on/no-heap-no-radix; timing excluded =='
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== TRACE: narrow/1GB/k250000/off/default; timing excluded =='
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== TRACE: narrow/1GB/k250000/on/default; timing excluded =='
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== TRACE: narrow/1GB/k250000/off/no-radix; timing excluded =='
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== TRACE: narrow/1GB/k250000/on/no-radix; timing excluded =='
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== TRACE: narrow/1GB/k250000/off/no-heap; timing excluded =='
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== TRACE: narrow/1GB/k250000/on/no-heap; timing excluded =='
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== TRACE: narrow/1GB/k250000/off/no-heap-no-radix; timing excluded =='
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== TRACE: narrow/1GB/k250000/on/no-heap-no-radix; timing excluded =='
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== TRACE: wide/16MB/k250000/off/default; timing excluded =='
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== TRACE: wide/16MB/k250000/on/default; timing excluded =='
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== TRACE: wide/16MB/k250000/off/no-heap; timing excluded =='
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== TRACE: wide/16MB/k250000/on/no-heap; timing excluded =='
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== TRACE: wide/16MB/k250000/off/no-heap-no-radix; timing excluded =='
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== TRACE: wide/16MB/k250000/on/no-heap-no-radix; timing excluded =='
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== TRACE: wide/1GB/k250000/off/default; timing excluded =='
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== TRACE: wide/1GB/k250000/on/default; timing excluded =='
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== TRACE: wide/1GB/k250000/off/no-radix; timing excluded =='
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== TRACE: wide/1GB/k250000/on/no-radix; timing excluded =='
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== TRACE: wide/1GB/k250000/off/no-heap; timing excluded =='
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== TRACE: wide/1GB/k250000/on/no-heap; timing excluded =='
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== TRACE: wide/1GB/k250000/off/no-heap-no-radix; timing excluded =='
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== TRACE: wide/1GB/k250000/on/no-heap-no-radix; timing excluded =='
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== TRACE: narrow/1GB/k750000/off/default; timing excluded =='
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

\echo '== TRACE: narrow/1GB/k750000/on/default; timing excluded =='
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

\echo '== TRACE: narrow/1GB/k750000/off/no-radix; timing excluded =='
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = off;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

\echo '== TRACE: narrow/1GB/k750000/on/no-radix; timing excluded =='
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = on;
SET debug_sort_free_heap_root = on;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 750000;

SET trace_sort = off;
SET client_min_messages = warning;
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;

\else
\pset format unaligned
\pset tuples_only on
\o sortbench-plans.log
SELECT sortbench_capture_begin(102);
-- heap-check/datum/ascending/off
SET work_mem = '64MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('heap-check/datum/ascending', 'off', 'heap-release', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k
FROM sortbench_heap_ascending
ORDER BY k
LIMIT 4096;

-- heap-check/datum/ascending/on
SET work_mem = '64MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('heap-check/datum/ascending', 'on', 'heap-release', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k
FROM sortbench_heap_ascending
ORDER BY k
LIMIT 4096;

-- heap-check/datum/descending/off
SET work_mem = '64MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('heap-check/datum/descending', 'off', 'heap-release', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k
FROM sortbench_heap_descending
ORDER BY k
LIMIT 4096;

-- heap-check/datum/descending/on
SET work_mem = '64MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('heap-check/datum/descending', 'on', 'heap-release', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k
FROM sortbench_heap_descending
ORDER BY k
LIMIT 4096;

-- heap-check/datum/permuted/off
SET work_mem = '64MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('heap-check/datum/permuted', 'off', 'heap-release', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k
FROM sortbench_heap_permuted
ORDER BY k
LIMIT 4096;

-- heap-check/datum/permuted/on
SET work_mem = '64MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('heap-check/datum/permuted', 'on', 'heap-release', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k
FROM sortbench_heap_permuted
ORDER BY k
LIMIT 4096;

-- heap-check/tuple/ascending/off
SET work_mem = '64MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('heap-check/tuple/ascending', 'off', 'heap-release', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, payload
FROM sortbench_heap_ascending
ORDER BY k
LIMIT 4096;

-- heap-check/tuple/ascending/on
SET work_mem = '64MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('heap-check/tuple/ascending', 'on', 'heap-release', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, payload
FROM sortbench_heap_ascending
ORDER BY k
LIMIT 4096;

-- heap-check/tuple/descending/off
SET work_mem = '64MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('heap-check/tuple/descending', 'off', 'heap-release', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, payload
FROM sortbench_heap_descending
ORDER BY k
LIMIT 4096;

-- heap-check/tuple/descending/on
SET work_mem = '64MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('heap-check/tuple/descending', 'on', 'heap-release', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, payload
FROM sortbench_heap_descending
ORDER BY k
LIMIT 4096;

-- heap-check/tuple/permuted/off
SET work_mem = '64MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('heap-check/tuple/permuted', 'off', 'heap-release', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, payload
FROM sortbench_heap_permuted
ORDER BY k
LIMIT 4096;

-- heap-check/tuple/permuted/on
SET work_mem = '64MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('heap-check/tuple/permuted', 'on', 'heap-release', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, payload
FROM sortbench_heap_permuted
ORDER BY k
LIMIT 4096;

-- CASE: narrow/32MB/k001000; narrow tuples; work_mem=32MB; LIMIT=1000

SET client_min_messages = log;
SET trace_sort = on;

-- boundary/narrow/16MB/k250000 | on/default | diagnostic | batch 1
\echo '== BOUNDARY seq=13: boundary/narrow/16MB/k250000/on/default/batch1 =='
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/narrow/16MB/k250000', 'on/default', 'boundary', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/narrow/16MB/k250000 | on/no-heap | diagnostic | batch 1
\echo '== BOUNDARY seq=14: boundary/narrow/16MB/k250000/on/no-heap/batch1 =='
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/narrow/16MB/k250000', 'on/no-heap', 'boundary', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/narrow/16MB/k250000 | on/no-heap | diagnostic | batch 2
\echo '== BOUNDARY seq=15: boundary/narrow/16MB/k250000/on/no-heap/batch2 =='
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/narrow/16MB/k250000', 'on/no-heap', 'boundary', 'diagnostic', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/narrow/16MB/k250000 | on/default | diagnostic | batch 2
\echo '== BOUNDARY seq=16: boundary/narrow/16MB/k250000/on/default/batch2 =='
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/narrow/16MB/k250000', 'on/default', 'boundary', 'diagnostic', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/narrow/24MB/k250000 | on/default | diagnostic | batch 1
\echo '== BOUNDARY seq=17: boundary/narrow/24MB/k250000/on/default/batch1 =='
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/narrow/24MB/k250000', 'on/default', 'boundary', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/narrow/24MB/k250000 | on/no-heap | diagnostic | batch 1
\echo '== BOUNDARY seq=18: boundary/narrow/24MB/k250000/on/no-heap/batch1 =='
SET work_mem = '24MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/narrow/24MB/k250000', 'on/no-heap', 'boundary', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/narrow/24MB/k250000 | on/no-heap | diagnostic | batch 2
\echo '== BOUNDARY seq=19: boundary/narrow/24MB/k250000/on/no-heap/batch2 =='
SET work_mem = '24MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/narrow/24MB/k250000', 'on/no-heap', 'boundary', 'diagnostic', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/narrow/24MB/k250000 | on/default | diagnostic | batch 2
\echo '== BOUNDARY seq=20: boundary/narrow/24MB/k250000/on/default/batch2 =='
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/narrow/24MB/k250000', 'on/default', 'boundary', 'diagnostic', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/narrow/28MB/k250000 | on/default | diagnostic | batch 1
\echo '== BOUNDARY seq=21: boundary/narrow/28MB/k250000/on/default/batch1 =='
SET work_mem = '28MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/narrow/28MB/k250000', 'on/default', 'boundary', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/narrow/28MB/k250000 | on/no-heap | diagnostic | batch 1
\echo '== BOUNDARY seq=22: boundary/narrow/28MB/k250000/on/no-heap/batch1 =='
SET work_mem = '28MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/narrow/28MB/k250000', 'on/no-heap', 'boundary', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/narrow/28MB/k250000 | off/default | diagnostic | batch 1
\echo '== BOUNDARY seq=23: boundary/narrow/28MB/k250000/off/default/batch1 =='
SET work_mem = '28MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('boundary/narrow/28MB/k250000', 'off/default', 'boundary', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/narrow/28MB/k250000 | off/default | diagnostic | batch 2
\echo '== BOUNDARY seq=24: boundary/narrow/28MB/k250000/off/default/batch2 =='
SET work_mem = '28MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('boundary/narrow/28MB/k250000', 'off/default', 'boundary', 'diagnostic', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/narrow/28MB/k250000 | on/no-heap | diagnostic | batch 2
\echo '== BOUNDARY seq=25: boundary/narrow/28MB/k250000/on/no-heap/batch2 =='
SET work_mem = '28MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/narrow/28MB/k250000', 'on/no-heap', 'boundary', 'diagnostic', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/narrow/28MB/k250000 | on/default | diagnostic | batch 2
\echo '== BOUNDARY seq=26: boundary/narrow/28MB/k250000/on/default/batch2 =='
SET work_mem = '28MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/narrow/28MB/k250000', 'on/default', 'boundary', 'diagnostic', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/narrow/29MB/k250000 | on/default | diagnostic | batch 1
\echo '== BOUNDARY seq=27: boundary/narrow/29MB/k250000/on/default/batch1 =='
SET work_mem = '29MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/narrow/29MB/k250000', 'on/default', 'boundary', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/narrow/29MB/k250000 | on/no-heap | diagnostic | batch 1
\echo '== BOUNDARY seq=28: boundary/narrow/29MB/k250000/on/no-heap/batch1 =='
SET work_mem = '29MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/narrow/29MB/k250000', 'on/no-heap', 'boundary', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/narrow/29MB/k250000 | on/no-heap | diagnostic | batch 2
\echo '== BOUNDARY seq=29: boundary/narrow/29MB/k250000/on/no-heap/batch2 =='
SET work_mem = '29MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/narrow/29MB/k250000', 'on/no-heap', 'boundary', 'diagnostic', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/narrow/29MB/k250000 | on/default | diagnostic | batch 2
\echo '== BOUNDARY seq=30: boundary/narrow/29MB/k250000/on/default/batch2 =='
SET work_mem = '29MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/narrow/29MB/k250000', 'on/default', 'boundary', 'diagnostic', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/narrow/30MB/k250000 | on/default | diagnostic | batch 1
\echo '== BOUNDARY seq=31: boundary/narrow/30MB/k250000/on/default/batch1 =='
SET work_mem = '30MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/narrow/30MB/k250000', 'on/default', 'boundary', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/narrow/30MB/k250000 | on/no-heap | diagnostic | batch 1
\echo '== BOUNDARY seq=32: boundary/narrow/30MB/k250000/on/no-heap/batch1 =='
SET work_mem = '30MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/narrow/30MB/k250000', 'on/no-heap', 'boundary', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/narrow/30MB/k250000 | on/no-heap | diagnostic | batch 2
\echo '== BOUNDARY seq=33: boundary/narrow/30MB/k250000/on/no-heap/batch2 =='
SET work_mem = '30MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/narrow/30MB/k250000', 'on/no-heap', 'boundary', 'diagnostic', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/narrow/30MB/k250000 | on/default | diagnostic | batch 2
\echo '== BOUNDARY seq=34: boundary/narrow/30MB/k250000/on/default/batch2 =='
SET work_mem = '30MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/narrow/30MB/k250000', 'on/default', 'boundary', 'diagnostic', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/narrow/31232kB/k250000 | on/default | diagnostic | batch 1
\echo '== BOUNDARY seq=35: boundary/narrow/31232kB/k250000/on/default/batch1 =='
SET work_mem = '31232kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/narrow/31232kB/k250000', 'on/default', 'boundary', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/narrow/31232kB/k250000 | on/no-heap | diagnostic | batch 1
\echo '== BOUNDARY seq=36: boundary/narrow/31232kB/k250000/on/no-heap/batch1 =='
SET work_mem = '31232kB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/narrow/31232kB/k250000', 'on/no-heap', 'boundary', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/narrow/31232kB/k250000 | on/no-heap | diagnostic | batch 2
\echo '== BOUNDARY seq=37: boundary/narrow/31232kB/k250000/on/no-heap/batch2 =='
SET work_mem = '31232kB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/narrow/31232kB/k250000', 'on/no-heap', 'boundary', 'diagnostic', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/narrow/31232kB/k250000 | on/default | diagnostic | batch 2
\echo '== BOUNDARY seq=38: boundary/narrow/31232kB/k250000/on/default/batch2 =='
SET work_mem = '31232kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/narrow/31232kB/k250000', 'on/default', 'boundary', 'diagnostic', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/narrow/31MB/k250000 | on/default | diagnostic | batch 1
\echo '== BOUNDARY seq=39: boundary/narrow/31MB/k250000/on/default/batch1 =='
SET work_mem = '31MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/narrow/31MB/k250000', 'on/default', 'boundary', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/narrow/31MB/k250000 | on/no-heap | diagnostic | batch 1
\echo '== BOUNDARY seq=40: boundary/narrow/31MB/k250000/on/no-heap/batch1 =='
SET work_mem = '31MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/narrow/31MB/k250000', 'on/no-heap', 'boundary', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/narrow/31MB/k250000 | on/no-heap | diagnostic | batch 2
\echo '== BOUNDARY seq=41: boundary/narrow/31MB/k250000/on/no-heap/batch2 =='
SET work_mem = '31MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/narrow/31MB/k250000', 'on/no-heap', 'boundary', 'diagnostic', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/narrow/31MB/k250000 | on/default | diagnostic | batch 2
\echo '== BOUNDARY seq=42: boundary/narrow/31MB/k250000/on/default/batch2 =='
SET work_mem = '31MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/narrow/31MB/k250000', 'on/default', 'boundary', 'diagnostic', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/narrow/32256kB/k250000 | on/default | diagnostic | batch 1
\echo '== BOUNDARY seq=43: boundary/narrow/32256kB/k250000/on/default/batch1 =='
SET work_mem = '32256kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/narrow/32256kB/k250000', 'on/default', 'boundary', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/narrow/32256kB/k250000 | on/no-heap | diagnostic | batch 1
\echo '== BOUNDARY seq=44: boundary/narrow/32256kB/k250000/on/no-heap/batch1 =='
SET work_mem = '32256kB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/narrow/32256kB/k250000', 'on/no-heap', 'boundary', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/narrow/32256kB/k250000 | on/no-heap | diagnostic | batch 2
\echo '== BOUNDARY seq=45: boundary/narrow/32256kB/k250000/on/no-heap/batch2 =='
SET work_mem = '32256kB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/narrow/32256kB/k250000', 'on/no-heap', 'boundary', 'diagnostic', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/narrow/32256kB/k250000 | on/default | diagnostic | batch 2
\echo '== BOUNDARY seq=46: boundary/narrow/32256kB/k250000/on/default/batch2 =='
SET work_mem = '32256kB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/narrow/32256kB/k250000', 'on/default', 'boundary', 'diagnostic', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/narrow/32MB/k250000 | on/default | diagnostic | batch 1
\echo '== BOUNDARY seq=47: boundary/narrow/32MB/k250000/on/default/batch1 =='
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/narrow/32MB/k250000', 'on/default', 'boundary', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/narrow/32MB/k250000 | on/no-heap | diagnostic | batch 1
\echo '== BOUNDARY seq=48: boundary/narrow/32MB/k250000/on/no-heap/batch1 =='
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/narrow/32MB/k250000', 'on/no-heap', 'boundary', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/narrow/32MB/k250000 | off/default | diagnostic | batch 1
\echo '== BOUNDARY seq=49: boundary/narrow/32MB/k250000/off/default/batch1 =='
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('boundary/narrow/32MB/k250000', 'off/default', 'boundary', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/narrow/32MB/k250000 | off/default | diagnostic | batch 2
\echo '== BOUNDARY seq=50: boundary/narrow/32MB/k250000/off/default/batch2 =='
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('boundary/narrow/32MB/k250000', 'off/default', 'boundary', 'diagnostic', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/narrow/32MB/k250000 | on/no-heap | diagnostic | batch 2
\echo '== BOUNDARY seq=51: boundary/narrow/32MB/k250000/on/no-heap/batch2 =='
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/narrow/32MB/k250000', 'on/no-heap', 'boundary', 'diagnostic', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/narrow/32MB/k250000 | on/default | diagnostic | batch 2
\echo '== BOUNDARY seq=52: boundary/narrow/32MB/k250000/on/default/batch2 =='
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/narrow/32MB/k250000', 'on/default', 'boundary', 'diagnostic', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/narrow/33MB/k250000 | on/default | diagnostic | batch 1
\echo '== BOUNDARY seq=53: boundary/narrow/33MB/k250000/on/default/batch1 =='
SET work_mem = '33MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/narrow/33MB/k250000', 'on/default', 'boundary', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/narrow/33MB/k250000 | on/no-heap | diagnostic | batch 1
\echo '== BOUNDARY seq=54: boundary/narrow/33MB/k250000/on/no-heap/batch1 =='
SET work_mem = '33MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/narrow/33MB/k250000', 'on/no-heap', 'boundary', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/narrow/33MB/k250000 | on/no-heap | diagnostic | batch 2
\echo '== BOUNDARY seq=55: boundary/narrow/33MB/k250000/on/no-heap/batch2 =='
SET work_mem = '33MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/narrow/33MB/k250000', 'on/no-heap', 'boundary', 'diagnostic', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/narrow/33MB/k250000 | on/default | diagnostic | batch 2
\echo '== BOUNDARY seq=56: boundary/narrow/33MB/k250000/on/default/batch2 =='
SET work_mem = '33MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/narrow/33MB/k250000', 'on/default', 'boundary', 'diagnostic', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/narrow/36MB/k250000 | on/default | diagnostic | batch 1
\echo '== BOUNDARY seq=57: boundary/narrow/36MB/k250000/on/default/batch1 =='
SET work_mem = '36MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/narrow/36MB/k250000', 'on/default', 'boundary', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/narrow/36MB/k250000 | on/no-heap | diagnostic | batch 1
\echo '== BOUNDARY seq=58: boundary/narrow/36MB/k250000/on/no-heap/batch1 =='
SET work_mem = '36MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/narrow/36MB/k250000', 'on/no-heap', 'boundary', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/narrow/36MB/k250000 | on/no-heap | diagnostic | batch 2
\echo '== BOUNDARY seq=59: boundary/narrow/36MB/k250000/on/no-heap/batch2 =='
SET work_mem = '36MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/narrow/36MB/k250000', 'on/no-heap', 'boundary', 'diagnostic', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/narrow/36MB/k250000 | on/default | diagnostic | batch 2
\echo '== BOUNDARY seq=60: boundary/narrow/36MB/k250000/on/default/batch2 =='
SET work_mem = '36MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/narrow/36MB/k250000', 'on/default', 'boundary', 'diagnostic', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/narrow/64MB/k250000 | on/default | diagnostic | batch 1
\echo '== BOUNDARY seq=61: boundary/narrow/64MB/k250000/on/default/batch1 =='
SET work_mem = '64MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/narrow/64MB/k250000', 'on/default', 'boundary', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/narrow/64MB/k250000 | on/no-heap | diagnostic | batch 1
\echo '== BOUNDARY seq=62: boundary/narrow/64MB/k250000/on/no-heap/batch1 =='
SET work_mem = '64MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/narrow/64MB/k250000', 'on/no-heap', 'boundary', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/narrow/64MB/k250000 | on/no-heap | diagnostic | batch 2
\echo '== BOUNDARY seq=63: boundary/narrow/64MB/k250000/on/no-heap/batch2 =='
SET work_mem = '64MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/narrow/64MB/k250000', 'on/no-heap', 'boundary', 'diagnostic', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/narrow/64MB/k250000 | on/default | diagnostic | batch 2
\echo '== BOUNDARY seq=64: boundary/narrow/64MB/k250000/on/default/batch2 =='
SET work_mem = '64MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/narrow/64MB/k250000', 'on/default', 'boundary', 'diagnostic', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/narrow/1GB/k250000 | on/default | diagnostic | batch 1
\echo '== BOUNDARY seq=65: boundary/narrow/1GB/k250000/on/default/batch1 =='
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/narrow/1GB/k250000', 'on/default', 'boundary', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/narrow/1GB/k250000 | on/no-heap | diagnostic | batch 1
\echo '== BOUNDARY seq=66: boundary/narrow/1GB/k250000/on/no-heap/batch1 =='
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/narrow/1GB/k250000', 'on/no-heap', 'boundary', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/narrow/1GB/k250000 | on/no-heap | diagnostic | batch 2
\echo '== BOUNDARY seq=67: boundary/narrow/1GB/k250000/on/no-heap/batch2 =='
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/narrow/1GB/k250000', 'on/no-heap', 'boundary', 'diagnostic', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/narrow/1GB/k250000 | on/default | diagnostic | batch 2
\echo '== BOUNDARY seq=68: boundary/narrow/1GB/k250000/on/default/batch2 =='
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/narrow/1GB/k250000', 'on/default', 'boundary', 'diagnostic', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/wide/64MB/k250000 | on/default | diagnostic | batch 1
\echo '== BOUNDARY seq=69: boundary/wide/64MB/k250000/on/default/batch1 =='
SET work_mem = '64MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/wide/64MB/k250000', 'on/default', 'boundary', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/wide/64MB/k250000 | on/no-heap | diagnostic | batch 1
\echo '== BOUNDARY seq=70: boundary/wide/64MB/k250000/on/no-heap/batch1 =='
SET work_mem = '64MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/wide/64MB/k250000', 'on/no-heap', 'boundary', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/wide/64MB/k250000 | on/no-heap | diagnostic | batch 2
\echo '== BOUNDARY seq=71: boundary/wide/64MB/k250000/on/no-heap/batch2 =='
SET work_mem = '64MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/wide/64MB/k250000', 'on/no-heap', 'boundary', 'diagnostic', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/wide/64MB/k250000 | on/default | diagnostic | batch 2
\echo '== BOUNDARY seq=72: boundary/wide/64MB/k250000/on/default/batch2 =='
SET work_mem = '64MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/wide/64MB/k250000', 'on/default', 'boundary', 'diagnostic', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/wide/96MB/k250000 | on/default | diagnostic | batch 1
\echo '== BOUNDARY seq=73: boundary/wide/96MB/k250000/on/default/batch1 =='
SET work_mem = '96MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/wide/96MB/k250000', 'on/default', 'boundary', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/wide/96MB/k250000 | on/no-heap | diagnostic | batch 1
\echo '== BOUNDARY seq=74: boundary/wide/96MB/k250000/on/no-heap/batch1 =='
SET work_mem = '96MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/wide/96MB/k250000', 'on/no-heap', 'boundary', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/wide/96MB/k250000 | on/no-heap | diagnostic | batch 2
\echo '== BOUNDARY seq=75: boundary/wide/96MB/k250000/on/no-heap/batch2 =='
SET work_mem = '96MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/wide/96MB/k250000', 'on/no-heap', 'boundary', 'diagnostic', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/wide/96MB/k250000 | on/default | diagnostic | batch 2
\echo '== BOUNDARY seq=76: boundary/wide/96MB/k250000/on/default/batch2 =='
SET work_mem = '96MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/wide/96MB/k250000', 'on/default', 'boundary', 'diagnostic', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/wide/128MB/k250000 | on/default | diagnostic | batch 1
\echo '== BOUNDARY seq=77: boundary/wide/128MB/k250000/on/default/batch1 =='
SET work_mem = '128MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/wide/128MB/k250000', 'on/default', 'boundary', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/wide/128MB/k250000 | on/no-heap | diagnostic | batch 1
\echo '== BOUNDARY seq=78: boundary/wide/128MB/k250000/on/no-heap/batch1 =='
SET work_mem = '128MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/wide/128MB/k250000', 'on/no-heap', 'boundary', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/wide/128MB/k250000 | on/no-heap | diagnostic | batch 2
\echo '== BOUNDARY seq=79: boundary/wide/128MB/k250000/on/no-heap/batch2 =='
SET work_mem = '128MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/wide/128MB/k250000', 'on/no-heap', 'boundary', 'diagnostic', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/wide/128MB/k250000 | on/default | diagnostic | batch 2
\echo '== BOUNDARY seq=80: boundary/wide/128MB/k250000/on/default/batch2 =='
SET work_mem = '128MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/wide/128MB/k250000', 'on/default', 'boundary', 'diagnostic', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/wide/144MB/k250000 | on/default | diagnostic | batch 1
\echo '== BOUNDARY seq=81: boundary/wide/144MB/k250000/on/default/batch1 =='
SET work_mem = '144MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/wide/144MB/k250000', 'on/default', 'boundary', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/wide/144MB/k250000 | on/no-heap | diagnostic | batch 1
\echo '== BOUNDARY seq=82: boundary/wide/144MB/k250000/on/no-heap/batch1 =='
SET work_mem = '144MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/wide/144MB/k250000', 'on/no-heap', 'boundary', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/wide/144MB/k250000 | on/no-heap | diagnostic | batch 2
\echo '== BOUNDARY seq=83: boundary/wide/144MB/k250000/on/no-heap/batch2 =='
SET work_mem = '144MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/wide/144MB/k250000', 'on/no-heap', 'boundary', 'diagnostic', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/wide/144MB/k250000 | on/default | diagnostic | batch 2
\echo '== BOUNDARY seq=84: boundary/wide/144MB/k250000/on/default/batch2 =='
SET work_mem = '144MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/wide/144MB/k250000', 'on/default', 'boundary', 'diagnostic', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/wide/192MB/k250000 | on/default | diagnostic | batch 1
\echo '== BOUNDARY seq=85: boundary/wide/192MB/k250000/on/default/batch1 =='
SET work_mem = '192MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/wide/192MB/k250000', 'on/default', 'boundary', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/wide/192MB/k250000 | on/no-heap | diagnostic | batch 1
\echo '== BOUNDARY seq=86: boundary/wide/192MB/k250000/on/no-heap/batch1 =='
SET work_mem = '192MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/wide/192MB/k250000', 'on/no-heap', 'boundary', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/wide/192MB/k250000 | on/no-heap | diagnostic | batch 2
\echo '== BOUNDARY seq=87: boundary/wide/192MB/k250000/on/no-heap/batch2 =='
SET work_mem = '192MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/wide/192MB/k250000', 'on/no-heap', 'boundary', 'diagnostic', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/wide/192MB/k250000 | on/default | diagnostic | batch 2
\echo '== BOUNDARY seq=88: boundary/wide/192MB/k250000/on/default/batch2 =='
SET work_mem = '192MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/wide/192MB/k250000', 'on/default', 'boundary', 'diagnostic', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/wide/256MB/k250000 | on/default | diagnostic | batch 1
\echo '== BOUNDARY seq=89: boundary/wide/256MB/k250000/on/default/batch1 =='
SET work_mem = '256MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/wide/256MB/k250000', 'on/default', 'boundary', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/wide/256MB/k250000 | on/no-heap | diagnostic | batch 1
\echo '== BOUNDARY seq=90: boundary/wide/256MB/k250000/on/no-heap/batch1 =='
SET work_mem = '256MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/wide/256MB/k250000', 'on/no-heap', 'boundary', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/wide/256MB/k250000 | on/no-heap | diagnostic | batch 2
\echo '== BOUNDARY seq=91: boundary/wide/256MB/k250000/on/no-heap/batch2 =='
SET work_mem = '256MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/wide/256MB/k250000', 'on/no-heap', 'boundary', 'diagnostic', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/wide/256MB/k250000 | on/default | diagnostic | batch 2
\echo '== BOUNDARY seq=92: boundary/wide/256MB/k250000/on/default/batch2 =='
SET work_mem = '256MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/wide/256MB/k250000', 'on/default', 'boundary', 'diagnostic', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/wide/272MB/k250000 | on/default | diagnostic | batch 1
\echo '== BOUNDARY seq=93: boundary/wide/272MB/k250000/on/default/batch1 =='
SET work_mem = '272MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/wide/272MB/k250000', 'on/default', 'boundary', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/wide/272MB/k250000 | on/no-heap | diagnostic | batch 1
\echo '== BOUNDARY seq=94: boundary/wide/272MB/k250000/on/no-heap/batch1 =='
SET work_mem = '272MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/wide/272MB/k250000', 'on/no-heap', 'boundary', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/wide/272MB/k250000 | on/no-heap | diagnostic | batch 2
\echo '== BOUNDARY seq=95: boundary/wide/272MB/k250000/on/no-heap/batch2 =='
SET work_mem = '272MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/wide/272MB/k250000', 'on/no-heap', 'boundary', 'diagnostic', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/wide/272MB/k250000 | on/default | diagnostic | batch 2
\echo '== BOUNDARY seq=96: boundary/wide/272MB/k250000/on/default/batch2 =='
SET work_mem = '272MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/wide/272MB/k250000', 'on/default', 'boundary', 'diagnostic', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/wide/1GB/k250000 | on/default | diagnostic | batch 1
\echo '== BOUNDARY seq=97: boundary/wide/1GB/k250000/on/default/batch1 =='
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/wide/1GB/k250000', 'on/default', 'boundary', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/wide/1GB/k250000 | on/no-heap | diagnostic | batch 1
\echo '== BOUNDARY seq=98: boundary/wide/1GB/k250000/on/no-heap/batch1 =='
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/wide/1GB/k250000', 'on/no-heap', 'boundary', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/wide/1GB/k250000 | off/default | diagnostic | batch 1
\echo '== BOUNDARY seq=99: boundary/wide/1GB/k250000/off/default/batch1 =='
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('boundary/wide/1GB/k250000', 'off/default', 'boundary', 'diagnostic', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/wide/1GB/k250000 | off/default | diagnostic | batch 2
\echo '== BOUNDARY seq=100: boundary/wide/1GB/k250000/off/default/batch2 =='
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SELECT sortbench_capture('boundary/wide/1GB/k250000', 'off/default', 'boundary', 'diagnostic', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/wide/1GB/k250000 | on/no-heap | diagnostic | batch 2
\echo '== BOUNDARY seq=101: boundary/wide/1GB/k250000/on/no-heap/batch2 =='
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/wide/1GB/k250000', 'on/no-heap', 'boundary', 'diagnostic', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- boundary/wide/1GB/k250000 | on/default | diagnostic | batch 2
\echo '== BOUNDARY seq=102: boundary/wide/1GB/k250000/on/default/batch2 =='
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
SELECT sortbench_capture('boundary/wide/1GB/k250000', 'on/default', 'boundary', 'diagnostic', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

SET trace_sort = off;
SET client_min_messages = warning;
SELECT sortbench_capture_end();
\o
SELECT sortbench_file_reset();
\copy pg_temp.sortbench_file_lines(line) FROM 'sortbench-plans.log' WITH (FORMAT csv, DELIMITER E'\x01', QUOTE E'\x02')
\pset format aligned
\pset tuples_only off
\echo '== Capture completeness =='
SELECT sortbench_file_load();
\echo '== Round 04 environment =='
SELECT version();
SELECT name,setting,unit FROM pg_settings WHERE name IN
 ('shared_buffers','block_size','cpu_operator_cost','seq_page_cost','random_page_cost');
SELECT attname,avg_width,n_distinct,correlation FROM pg_stats
WHERE schemaname='public' AND tablename='sortbench_data' ORDER BY attname;
\echo '== Small-fixture heap memory checks =='
SELECT * FROM sortbench_heap_checks();
\echo '== Boundary sample/shape/settings checks; raises on failure =='
SELECT sortbench_boundary_check();
\echo '== Actual algorithms and estimated costs; trace timings are not benchmarks =='
SELECT * FROM sortbench_boundary_report();
\endif

\endif

SET trace_sort = off;
SET client_min_messages = warning;
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = off;
SET debug_sort_heap_on_slots = off;
