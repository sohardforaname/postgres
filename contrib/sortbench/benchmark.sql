-- Independent sorting experiment; no delayed-projection expressions.
-- Run from a writable directory: psql -X -v ON_ERROR_STOP=1 -f benchmark.sql > sortbench-report.txt 2>&1
-- Every measured query is literal and can be copied with its preceding SETs.
-- Marker calls only label the immediately following EXPLAIN.
\set ON_ERROR_STOP on
\set QUIET on
\timing off
\pset pager off
SET client_min_messages = warning;
CREATE EXTENSION IF NOT EXISTS sortbench;
SELECT sortbench_prepare()
\gexec
SET max_parallel_workers_per_gather = 0;
SET max_parallel_workers = 0;
SET jit = off;
SET synchronize_seqscans = off;
SET trace_sort = off;
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
\pset format unaligned
\pset tuples_only on
\o sortbench-plans.log
SELECT sortbench_capture_begin(128);

-- heap/narrow/4MB | default | warmup | batch 1
SET work_mem = '4MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/narrow/4MB', 'default', 'serial-sort', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/narrow/4MB | no-heap | warmup | batch 1
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/narrow/4MB', 'no-heap', 'serial-sort', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/narrow/4MB | no-heap | timed | batch 1
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/narrow/4MB', 'no-heap', 'serial-sort', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/narrow/4MB | default | timed | batch 1
SET work_mem = '4MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/narrow/4MB', 'default', 'serial-sort', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/narrow/4MB | default | timed | batch 2
SET work_mem = '4MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/narrow/4MB', 'default', 'serial-sort', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/narrow/4MB | no-heap | timed | batch 2
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/narrow/4MB', 'no-heap', 'serial-sort', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/narrow/4MB | no-heap | timed | batch 3
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/narrow/4MB', 'no-heap', 'serial-sort', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/narrow/4MB | default | timed | batch 3
SET work_mem = '4MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/narrow/4MB', 'default', 'serial-sort', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/narrow/8MB | default | warmup | batch 1
SET work_mem = '8MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/narrow/8MB', 'default', 'serial-sort', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/narrow/8MB | no-heap | warmup | batch 1
SET work_mem = '8MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/narrow/8MB', 'no-heap', 'serial-sort', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/narrow/8MB | no-heap | timed | batch 1
SET work_mem = '8MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/narrow/8MB', 'no-heap', 'serial-sort', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/narrow/8MB | default | timed | batch 1
SET work_mem = '8MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/narrow/8MB', 'default', 'serial-sort', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/narrow/8MB | default | timed | batch 2
SET work_mem = '8MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/narrow/8MB', 'default', 'serial-sort', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/narrow/8MB | no-heap | timed | batch 2
SET work_mem = '8MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/narrow/8MB', 'no-heap', 'serial-sort', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/narrow/8MB | no-heap | timed | batch 3
SET work_mem = '8MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/narrow/8MB', 'no-heap', 'serial-sort', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/narrow/8MB | default | timed | batch 3
SET work_mem = '8MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/narrow/8MB', 'default', 'serial-sort', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/narrow/16MB | default | warmup | batch 1
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/narrow/16MB', 'default', 'serial-sort', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/narrow/16MB | no-heap | warmup | batch 1
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/narrow/16MB', 'no-heap', 'serial-sort', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/narrow/16MB | no-heap | timed | batch 1
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/narrow/16MB', 'no-heap', 'serial-sort', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/narrow/16MB | default | timed | batch 1
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/narrow/16MB', 'default', 'serial-sort', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/narrow/16MB | default | timed | batch 2
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/narrow/16MB', 'default', 'serial-sort', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/narrow/16MB | no-heap | timed | batch 2
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/narrow/16MB', 'no-heap', 'serial-sort', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/narrow/16MB | no-heap | timed | batch 3
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/narrow/16MB', 'no-heap', 'serial-sort', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/narrow/16MB | default | timed | batch 3
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/narrow/16MB', 'default', 'serial-sort', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/narrow/24MB | default | warmup | batch 1
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/narrow/24MB', 'default', 'serial-sort', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/narrow/24MB | no-heap | warmup | batch 1
SET work_mem = '24MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/narrow/24MB', 'no-heap', 'serial-sort', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/narrow/24MB | no-heap | timed | batch 1
SET work_mem = '24MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/narrow/24MB', 'no-heap', 'serial-sort', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/narrow/24MB | default | timed | batch 1
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/narrow/24MB', 'default', 'serial-sort', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/narrow/24MB | default | timed | batch 2
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/narrow/24MB', 'default', 'serial-sort', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/narrow/24MB | no-heap | timed | batch 2
SET work_mem = '24MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/narrow/24MB', 'no-heap', 'serial-sort', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/narrow/24MB | no-heap | timed | batch 3
SET work_mem = '24MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/narrow/24MB', 'no-heap', 'serial-sort', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/narrow/24MB | default | timed | batch 3
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/narrow/24MB', 'default', 'serial-sort', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/narrow/32MB | default | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/narrow/32MB', 'default', 'serial-sort', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/narrow/32MB | no-heap | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/narrow/32MB', 'no-heap', 'serial-sort', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/narrow/32MB | no-heap | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/narrow/32MB', 'no-heap', 'serial-sort', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/narrow/32MB | default | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/narrow/32MB', 'default', 'serial-sort', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/narrow/32MB | default | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/narrow/32MB', 'default', 'serial-sort', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/narrow/32MB | no-heap | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/narrow/32MB', 'no-heap', 'serial-sort', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/narrow/32MB | no-heap | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/narrow/32MB', 'no-heap', 'serial-sort', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/narrow/32MB | default | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/narrow/32MB', 'default', 'serial-sort', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/narrow/1GB | default | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/narrow/1GB', 'default', 'serial-sort', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/narrow/1GB | no-heap | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/narrow/1GB', 'no-heap', 'serial-sort', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/narrow/1GB | no-heap | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/narrow/1GB', 'no-heap', 'serial-sort', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/narrow/1GB | default | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/narrow/1GB', 'default', 'serial-sort', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/narrow/1GB | default | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/narrow/1GB', 'default', 'serial-sort', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/narrow/1GB | no-heap | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/narrow/1GB', 'no-heap', 'serial-sort', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/narrow/1GB | no-heap | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/narrow/1GB', 'no-heap', 'serial-sort', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/narrow/1GB | default | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/narrow/1GB', 'default', 'serial-sort', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/wide/4MB | default | warmup | batch 1
SET work_mem = '4MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/wide/4MB', 'default', 'serial-sort', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/wide/4MB | no-heap | warmup | batch 1
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/wide/4MB', 'no-heap', 'serial-sort', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/wide/4MB | no-heap | timed | batch 1
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/wide/4MB', 'no-heap', 'serial-sort', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/wide/4MB | default | timed | batch 1
SET work_mem = '4MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/wide/4MB', 'default', 'serial-sort', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/wide/4MB | default | timed | batch 2
SET work_mem = '4MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/wide/4MB', 'default', 'serial-sort', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/wide/4MB | no-heap | timed | batch 2
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/wide/4MB', 'no-heap', 'serial-sort', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/wide/4MB | no-heap | timed | batch 3
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/wide/4MB', 'no-heap', 'serial-sort', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/wide/4MB | default | timed | batch 3
SET work_mem = '4MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/wide/4MB', 'default', 'serial-sort', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/wide/8MB | default | warmup | batch 1
SET work_mem = '8MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/wide/8MB', 'default', 'serial-sort', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/wide/8MB | no-heap | warmup | batch 1
SET work_mem = '8MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/wide/8MB', 'no-heap', 'serial-sort', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/wide/8MB | no-heap | timed | batch 1
SET work_mem = '8MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/wide/8MB', 'no-heap', 'serial-sort', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/wide/8MB | default | timed | batch 1
SET work_mem = '8MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/wide/8MB', 'default', 'serial-sort', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/wide/8MB | default | timed | batch 2
SET work_mem = '8MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/wide/8MB', 'default', 'serial-sort', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/wide/8MB | no-heap | timed | batch 2
SET work_mem = '8MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/wide/8MB', 'no-heap', 'serial-sort', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/wide/8MB | no-heap | timed | batch 3
SET work_mem = '8MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/wide/8MB', 'no-heap', 'serial-sort', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/wide/8MB | default | timed | batch 3
SET work_mem = '8MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/wide/8MB', 'default', 'serial-sort', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/wide/16MB | default | warmup | batch 1
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/wide/16MB', 'default', 'serial-sort', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/wide/16MB | no-heap | warmup | batch 1
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/wide/16MB', 'no-heap', 'serial-sort', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/wide/16MB | no-heap | timed | batch 1
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/wide/16MB', 'no-heap', 'serial-sort', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/wide/16MB | default | timed | batch 1
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/wide/16MB', 'default', 'serial-sort', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/wide/16MB | default | timed | batch 2
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/wide/16MB', 'default', 'serial-sort', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/wide/16MB | no-heap | timed | batch 2
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/wide/16MB', 'no-heap', 'serial-sort', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/wide/16MB | no-heap | timed | batch 3
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/wide/16MB', 'no-heap', 'serial-sort', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/wide/16MB | default | timed | batch 3
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/wide/16MB', 'default', 'serial-sort', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/wide/24MB | default | warmup | batch 1
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/wide/24MB', 'default', 'serial-sort', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/wide/24MB | no-heap | warmup | batch 1
SET work_mem = '24MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/wide/24MB', 'no-heap', 'serial-sort', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/wide/24MB | no-heap | timed | batch 1
SET work_mem = '24MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/wide/24MB', 'no-heap', 'serial-sort', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/wide/24MB | default | timed | batch 1
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/wide/24MB', 'default', 'serial-sort', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/wide/24MB | default | timed | batch 2
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/wide/24MB', 'default', 'serial-sort', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/wide/24MB | no-heap | timed | batch 2
SET work_mem = '24MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/wide/24MB', 'no-heap', 'serial-sort', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/wide/24MB | no-heap | timed | batch 3
SET work_mem = '24MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/wide/24MB', 'no-heap', 'serial-sort', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/wide/24MB | default | timed | batch 3
SET work_mem = '24MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/wide/24MB', 'default', 'serial-sort', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/wide/32MB | default | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/wide/32MB', 'default', 'serial-sort', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/wide/32MB | no-heap | warmup | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/wide/32MB', 'no-heap', 'serial-sort', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/wide/32MB | no-heap | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/wide/32MB', 'no-heap', 'serial-sort', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/wide/32MB | default | timed | batch 1
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/wide/32MB', 'default', 'serial-sort', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/wide/32MB | default | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/wide/32MB', 'default', 'serial-sort', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/wide/32MB | no-heap | timed | batch 2
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/wide/32MB', 'no-heap', 'serial-sort', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/wide/32MB | no-heap | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/wide/32MB', 'no-heap', 'serial-sort', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/wide/32MB | default | timed | batch 3
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/wide/32MB', 'default', 'serial-sort', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/wide/1GB | default | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/wide/1GB', 'default', 'serial-sort', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/wide/1GB | no-heap | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/wide/1GB', 'no-heap', 'serial-sort', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/wide/1GB | no-heap | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/wide/1GB', 'no-heap', 'serial-sort', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/wide/1GB | default | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/wide/1GB', 'default', 'serial-sort', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/wide/1GB | default | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/wide/1GB', 'default', 'serial-sort', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/wide/1GB | no-heap | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/wide/1GB', 'no-heap', 'serial-sort', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/wide/1GB | no-heap | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/wide/1GB', 'no-heap', 'serial-sort', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- heap/wide/1GB | default | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('heap/wide/1GB', 'default', 'serial-sort', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- radix/narrow/4MB | no-heap | warmup | batch 1
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('radix/narrow/4MB', 'no-heap', 'serial-sort', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- radix/narrow/4MB | no-heap-no-radix | warmup | batch 1
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SELECT sortbench_capture('radix/narrow/4MB', 'no-heap-no-radix', 'serial-sort', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- radix/narrow/4MB | no-heap-no-radix | timed | batch 1
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SELECT sortbench_capture('radix/narrow/4MB', 'no-heap-no-radix', 'serial-sort', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- radix/narrow/4MB | no-heap | timed | batch 1
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('radix/narrow/4MB', 'no-heap', 'serial-sort', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- radix/narrow/4MB | no-heap | timed | batch 2
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('radix/narrow/4MB', 'no-heap', 'serial-sort', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- radix/narrow/4MB | no-heap-no-radix | timed | batch 2
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SELECT sortbench_capture('radix/narrow/4MB', 'no-heap-no-radix', 'serial-sort', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- radix/narrow/4MB | no-heap-no-radix | timed | batch 3
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SELECT sortbench_capture('radix/narrow/4MB', 'no-heap-no-radix', 'serial-sort', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- radix/narrow/4MB | no-heap | timed | batch 3
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('radix/narrow/4MB', 'no-heap', 'serial-sort', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- radix/narrow/1GB | no-heap | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('radix/narrow/1GB', 'no-heap', 'serial-sort', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- radix/narrow/1GB | no-heap-no-radix | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SELECT sortbench_capture('radix/narrow/1GB', 'no-heap-no-radix', 'serial-sort', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- radix/narrow/1GB | no-heap-no-radix | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SELECT sortbench_capture('radix/narrow/1GB', 'no-heap-no-radix', 'serial-sort', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- radix/narrow/1GB | no-heap | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('radix/narrow/1GB', 'no-heap', 'serial-sort', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- radix/narrow/1GB | no-heap | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('radix/narrow/1GB', 'no-heap', 'serial-sort', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- radix/narrow/1GB | no-heap-no-radix | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SELECT sortbench_capture('radix/narrow/1GB', 'no-heap-no-radix', 'serial-sort', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- radix/narrow/1GB | no-heap-no-radix | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SELECT sortbench_capture('radix/narrow/1GB', 'no-heap-no-radix', 'serial-sort', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- radix/narrow/1GB | no-heap | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('radix/narrow/1GB', 'no-heap', 'serial-sort', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- radix/wide/4MB | no-heap | warmup | batch 1
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('radix/wide/4MB', 'no-heap', 'serial-sort', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- radix/wide/4MB | no-heap-no-radix | warmup | batch 1
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SELECT sortbench_capture('radix/wide/4MB', 'no-heap-no-radix', 'serial-sort', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- radix/wide/4MB | no-heap-no-radix | timed | batch 1
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SELECT sortbench_capture('radix/wide/4MB', 'no-heap-no-radix', 'serial-sort', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- radix/wide/4MB | no-heap | timed | batch 1
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('radix/wide/4MB', 'no-heap', 'serial-sort', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- radix/wide/4MB | no-heap | timed | batch 2
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('radix/wide/4MB', 'no-heap', 'serial-sort', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- radix/wide/4MB | no-heap-no-radix | timed | batch 2
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SELECT sortbench_capture('radix/wide/4MB', 'no-heap-no-radix', 'serial-sort', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- radix/wide/4MB | no-heap-no-radix | timed | batch 3
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SELECT sortbench_capture('radix/wide/4MB', 'no-heap-no-radix', 'serial-sort', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- radix/wide/4MB | no-heap | timed | batch 3
SET work_mem = '4MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('radix/wide/4MB', 'no-heap', 'serial-sort', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- radix/wide/1GB | no-heap | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('radix/wide/1GB', 'no-heap', 'serial-sort', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- radix/wide/1GB | no-heap-no-radix | warmup | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SELECT sortbench_capture('radix/wide/1GB', 'no-heap-no-radix', 'serial-sort', 'warmup', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- radix/wide/1GB | no-heap-no-radix | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SELECT sortbench_capture('radix/wide/1GB', 'no-heap-no-radix', 'serial-sort', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- radix/wide/1GB | no-heap | timed | batch 1
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('radix/wide/1GB', 'no-heap', 'serial-sort', 'timed', 1);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- radix/wide/1GB | no-heap | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('radix/wide/1GB', 'no-heap', 'serial-sort', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- radix/wide/1GB | no-heap-no-radix | timed | batch 2
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SELECT sortbench_capture('radix/wide/1GB', 'no-heap-no-radix', 'serial-sort', 'timed', 2);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- radix/wide/1GB | no-heap-no-radix | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
SELECT sortbench_capture('radix/wide/1GB', 'no-heap-no-radix', 'serial-sort', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

-- radix/wide/1GB | no-heap | timed | batch 3
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
SELECT sortbench_capture('radix/wide/1GB', 'no-heap', 'serial-sort', 'timed', 3);
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

SELECT sortbench_capture_end();
\o
-- Client-side file import: no server filesystem access or superuser file-read privilege.
SELECT sortbench_file_reset();
\copy pg_temp.sortbench_file_lines(line) FROM 'sortbench-plans.log' WITH (FORMAT csv, DELIMITER E'\x01', QUOTE E'\x02')
\pset format aligned
\pset tuples_only off
\echo '== Capture completeness; EXPLAIN does not verify result values =='
SELECT sortbench_file_load();
\echo '== Plan shape, unchanged estimates, and toggle checks =='
SELECT * FROM sortbench_file_checks();
\echo '== Timed samples: median of three paired batches; warmups excluded =='
SELECT * FROM sortbench_file_report();
\echo '== Paired runtime ratios: > 1 means numerator is slower =='
SELECT * FROM sortbench_file_ratios();
\echo '== Estimated Sort increments and actual temporary block IO =='
SELECT * FROM sortbench_file_costs();

-- Diagnostics run AFTER all timed samples and are excluded from statistics.
-- The phase snapshots are tuplesort accounting, not peak process RSS.
-- radix-entry describes dispatch; the radix routine can use quicksort internally.
SET client_min_messages = log;
SET trace_sort = on;

\echo '== TRACE: narrow/16MB/default; ignore this run timing =='
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== TRACE: narrow/16MB/no-heap; ignore this run timing =='
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== TRACE: narrow/32MB/default; ignore this run timing =='
SET work_mem = '32MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== TRACE: narrow/32MB/no-heap; ignore this run timing =='
SET work_mem = '32MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== TRACE: narrow/1GB/default; ignore this run timing =='
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== TRACE: narrow/1GB/no-heap; ignore this run timing =='
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT k, small_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== TRACE: wide/16MB/default; ignore this run timing =='
SET work_mem = '16MB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== TRACE: wide/16MB/no-heap; ignore this run timing =='
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== TRACE: wide/1GB/default; ignore this run timing =='
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== TRACE: wide/1GB/no-heap; ignore this run timing =='
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = off;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== TRACE: wide/16MB/no-heap-no-radix; ignore this run timing =='
SET work_mem = '16MB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

\echo '== TRACE: wide/1GB/no-heap-no-radix; ignore this run timing =='
SET work_mem = '1GB';
SET debug_disable_sort_bounded = on;
SET debug_disable_sort_radix = on;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT k, large_payload
FROM public.sortbench_data
ORDER BY k
LIMIT 250000;

SET trace_sort = off;
SET client_min_messages = warning;
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
