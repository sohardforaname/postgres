-- Single test entrypoint. Run after rebuilding/installing and restarting PostgreSQL.
-- psql -X -d sort_test -f contrib/sortbench/benchmark.sql > sortbench-report.txt 2>&1
-- Recreates the sortbench extension and public.sortbench_data in a dedicated test database.
-- OFF preserves baseline heap-root retention; ON releases replaced roots.
-- All measured SELECTs are literal. Markers only label the next EXPLAIN.
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
