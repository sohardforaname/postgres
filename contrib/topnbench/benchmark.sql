\set ON_ERROR_STOP on
\set QUIET on
\pset pager off
\pset format unaligned
\pset tuples_only on
SET search_path = public;
SET client_min_messages = warning;

-- First install the updated extension files with make install.
-- Dedicated test database: reload the same extension version.
DROP EXTENSION IF EXISTS topnbench;
CREATE EXTENSION topnbench;
SELECT topnbench_prepare()
\gexec

-- CLIENT file, relative to psql's working directory. Errors stay on stderr.
\o topnbench-plans.log
SELECT topnbench_capture_begin(1028);

-- Copy any SET + EXPLAIN below into psql to investigate it manually.
-- The capture call is only needed when recording a sample for the report.
-- Plan-only guards omit ANALYZE; timed queries use TIMING OFF.

-- case: quick/limit-0.0001pct
-- check: equivalent
SET standard_conforming_strings = on;
SET search_path = public;
SET max_parallel_workers = 2;
SET max_parallel_workers_per_gather = 0;
SET parallel_leader_participation = on;
SET min_parallel_table_scan_size = 0;
SET parallel_setup_cost = 0;
SET parallel_tuple_cost = 0;
SET synchronize_seqscans = off;
SET jit = off;
SET enable_cost_based_delayed_projection = on;
SET enable_sort_tuple_width_cost = on;
SET enable_sort_datum_cost = on;
SET enable_projection_total_cost = on;
SET debug_disable_sort_radix = off;
SET debug_projection_placement = auto;
SET debug_print_projection_paths = off;
SET trace_sort = off;
SET client_min_messages = warning;
SET work_mem = '4MB';
SET cursor_tuple_fraction = 0.1;

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('quick/limit-0.0001pct', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 1;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('quick/limit-0.0001pct', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 1;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('quick/limit-0.0001pct', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 1;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('quick/limit-0.0001pct', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 4, 1) AS e1,
       topnbench_work_cost_1(s.k, 4, 2) AS e2,
       topnbench_work_cost_1(s.k, 4, 3) AS e3,
       topnbench_work_cost_1(s.k, 4, 4) AS e4
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 1) AS s
LIMIT 1;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('quick/limit-0.0001pct', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random, e1, e2, e3, e4
LIMIT 1;

-- case: quick/limit-0.01pct
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('quick/limit-0.01pct', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 100;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('quick/limit-0.01pct', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 100;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('quick/limit-0.01pct', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 100;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('quick/limit-0.01pct', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 4, 1) AS e1,
       topnbench_work_cost_1(s.k, 4, 2) AS e2,
       topnbench_work_cost_1(s.k, 4, 3) AS e3,
       topnbench_work_cost_1(s.k, 4, 4) AS e4
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 100) AS s
LIMIT 100;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('quick/limit-0.01pct', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random, e1, e2, e3, e4
LIMIT 100;

-- case: quick/limit-1pct
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('quick/limit-1pct', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 10000;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('quick/limit-1pct', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 10000;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('quick/limit-1pct', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 10000;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('quick/limit-1pct', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 4, 1) AS e1,
       topnbench_work_cost_1(s.k, 4, 2) AS e2,
       topnbench_work_cost_1(s.k, 4, 3) AS e3,
       topnbench_work_cost_1(s.k, 4, 4) AS e4
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 10000) AS s
LIMIT 10000;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('quick/limit-1pct', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random, e1, e2, e3, e4
LIMIT 10000;

-- case: quick/limit-10pct
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('quick/limit-10pct', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 100000;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('quick/limit-10pct', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 100000;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('quick/limit-10pct', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 100000;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('quick/limit-10pct', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 4, 1) AS e1,
       topnbench_work_cost_1(s.k, 4, 2) AS e2,
       topnbench_work_cost_1(s.k, 4, 3) AS e3,
       topnbench_work_cost_1(s.k, 4, 4) AS e4
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 100000) AS s
LIMIT 100000;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('quick/limit-10pct', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random, e1, e2, e3, e4
LIMIT 100000;

-- case: quick/limit-20pct
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('quick/limit-20pct', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 200000;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('quick/limit-20pct', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 200000;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('quick/limit-20pct', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 200000;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('quick/limit-20pct', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 4, 1) AS e1,
       topnbench_work_cost_1(s.k, 4, 2) AS e2,
       topnbench_work_cost_1(s.k, 4, 3) AS e3,
       topnbench_work_cost_1(s.k, 4, 4) AS e4
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 200000) AS s
LIMIT 200000;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('quick/limit-20pct', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random, e1, e2, e3, e4
LIMIT 200000;

-- case: quick/limit-30pct
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('quick/limit-30pct', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 300000;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('quick/limit-30pct', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 300000;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('quick/limit-30pct', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 300000;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('quick/limit-30pct', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 4, 1) AS e1,
       topnbench_work_cost_1(s.k, 4, 2) AS e2,
       topnbench_work_cost_1(s.k, 4, 3) AS e3,
       topnbench_work_cost_1(s.k, 4, 4) AS e4
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 300000) AS s
LIMIT 300000;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('quick/limit-30pct', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random, e1, e2, e3, e4
LIMIT 300000;

-- case: quick/limit-40pct
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('quick/limit-40pct', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 400000;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('quick/limit-40pct', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 400000;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('quick/limit-40pct', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 400000;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('quick/limit-40pct', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 4, 1) AS e1,
       topnbench_work_cost_1(s.k, 4, 2) AS e2,
       topnbench_work_cost_1(s.k, 4, 3) AS e3,
       topnbench_work_cost_1(s.k, 4, 4) AS e4
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 400000) AS s
LIMIT 400000;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('quick/limit-40pct', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random, e1, e2, e3, e4
LIMIT 400000;

-- case: quick/limit-50pct
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('quick/limit-50pct', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 500000;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('quick/limit-50pct', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 500000;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('quick/limit-50pct', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 500000;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('quick/limit-50pct', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 4, 1) AS e1,
       topnbench_work_cost_1(s.k, 4, 2) AS e2,
       topnbench_work_cost_1(s.k, 4, 3) AS e3,
       topnbench_work_cost_1(s.k, 4, 4) AS e4
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 500000) AS s
LIMIT 500000;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('quick/limit-50pct', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random, e1, e2, e3, e4
LIMIT 500000;

-- case: quick/limit-60pct
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('quick/limit-60pct', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 600000;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('quick/limit-60pct', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 600000;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('quick/limit-60pct', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 600000;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('quick/limit-60pct', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 4, 1) AS e1,
       topnbench_work_cost_1(s.k, 4, 2) AS e2,
       topnbench_work_cost_1(s.k, 4, 3) AS e3,
       topnbench_work_cost_1(s.k, 4, 4) AS e4
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 600000) AS s
LIMIT 600000;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('quick/limit-60pct', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random, e1, e2, e3, e4
LIMIT 600000;

-- case: quick/limit-70pct
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('quick/limit-70pct', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 700000;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('quick/limit-70pct', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 700000;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('quick/limit-70pct', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 700000;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('quick/limit-70pct', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 4, 1) AS e1,
       topnbench_work_cost_1(s.k, 4, 2) AS e2,
       topnbench_work_cost_1(s.k, 4, 3) AS e3,
       topnbench_work_cost_1(s.k, 4, 4) AS e4
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 700000) AS s
LIMIT 700000;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('quick/limit-70pct', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random, e1, e2, e3, e4
LIMIT 700000;

-- case: quick/limit-80pct
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('quick/limit-80pct', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 800000;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('quick/limit-80pct', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 800000;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('quick/limit-80pct', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 800000;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('quick/limit-80pct', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 4, 1) AS e1,
       topnbench_work_cost_1(s.k, 4, 2) AS e2,
       topnbench_work_cost_1(s.k, 4, 3) AS e3,
       topnbench_work_cost_1(s.k, 4, 4) AS e4
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 800000) AS s
LIMIT 800000;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('quick/limit-80pct', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random, e1, e2, e3, e4
LIMIT 800000;

-- case: quick/limit-90pct
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('quick/limit-90pct', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 900000;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('quick/limit-90pct', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 900000;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('quick/limit-90pct', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 900000;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('quick/limit-90pct', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 4, 1) AS e1,
       topnbench_work_cost_1(s.k, 4, 2) AS e2,
       topnbench_work_cost_1(s.k, 4, 3) AS e3,
       topnbench_work_cost_1(s.k, 4, 4) AS e4
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 900000) AS s
LIMIT 900000;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('quick/limit-90pct', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random, e1, e2, e3, e4
LIMIT 900000;

-- case: quick/limit-100pct
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('quick/limit-100pct', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 1000000;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('quick/limit-100pct', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 1000000;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('quick/limit-100pct', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 1000000;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('quick/limit-100pct', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 4, 1) AS e1,
       topnbench_work_cost_1(s.k, 4, 2) AS e2,
       topnbench_work_cost_1(s.k, 4, 3) AS e3,
       topnbench_work_cost_1(s.k, 4, 4) AS e4
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 1000000) AS s
LIMIT 1000000;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('quick/limit-100pct', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random, e1, e2, e3, e4
LIMIT 1000000;

-- case: quick/steps-1
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('quick/steps-1', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 100000;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('quick/steps-1', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 100000;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('quick/steps-1', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 100000;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('quick/steps-1', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 4, 1) AS e1
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 100000) AS s
LIMIT 100000;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('quick/steps-1', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1
FROM topnbench_data
ORDER BY a_random, e1
LIMIT 100000;

-- case: quick/steps-2
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('quick/steps-2', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2
FROM topnbench_data
ORDER BY a_random
LIMIT 100000;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('quick/steps-2', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2
FROM topnbench_data
ORDER BY a_random
LIMIT 100000;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('quick/steps-2', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2
FROM topnbench_data
ORDER BY a_random
LIMIT 100000;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('quick/steps-2', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 4, 1) AS e1,
       topnbench_work_cost_1(s.k, 4, 2) AS e2
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 100000) AS s
LIMIT 100000;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('quick/steps-2', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2
FROM topnbench_data
ORDER BY a_random, e1, e2
LIMIT 100000;

-- case: quick/steps-8
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('quick/steps-8', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4,
       topnbench_work_cost_1(a_random, 4, 5) AS e5,
       topnbench_work_cost_1(a_random, 4, 6) AS e6,
       topnbench_work_cost_1(a_random, 4, 7) AS e7,
       topnbench_work_cost_1(a_random, 4, 8) AS e8
FROM topnbench_data
ORDER BY a_random
LIMIT 100000;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('quick/steps-8', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4,
       topnbench_work_cost_1(a_random, 4, 5) AS e5,
       topnbench_work_cost_1(a_random, 4, 6) AS e6,
       topnbench_work_cost_1(a_random, 4, 7) AS e7,
       topnbench_work_cost_1(a_random, 4, 8) AS e8
FROM topnbench_data
ORDER BY a_random
LIMIT 100000;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('quick/steps-8', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4,
       topnbench_work_cost_1(a_random, 4, 5) AS e5,
       topnbench_work_cost_1(a_random, 4, 6) AS e6,
       topnbench_work_cost_1(a_random, 4, 7) AS e7,
       topnbench_work_cost_1(a_random, 4, 8) AS e8
FROM topnbench_data
ORDER BY a_random
LIMIT 100000;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('quick/steps-8', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 4, 1) AS e1,
       topnbench_work_cost_1(s.k, 4, 2) AS e2,
       topnbench_work_cost_1(s.k, 4, 3) AS e3,
       topnbench_work_cost_1(s.k, 4, 4) AS e4,
       topnbench_work_cost_1(s.k, 4, 5) AS e5,
       topnbench_work_cost_1(s.k, 4, 6) AS e6,
       topnbench_work_cost_1(s.k, 4, 7) AS e7,
       topnbench_work_cost_1(s.k, 4, 8) AS e8
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 100000) AS s
LIMIT 100000;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('quick/steps-8', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4,
       topnbench_work_cost_1(a_random, 4, 5) AS e5,
       topnbench_work_cost_1(a_random, 4, 6) AS e6,
       topnbench_work_cost_1(a_random, 4, 7) AS e7,
       topnbench_work_cost_1(a_random, 4, 8) AS e8
FROM topnbench_data
ORDER BY a_random, e1, e2, e3, e4, e5, e6, e7, e8
LIMIT 100000;

-- case: quick/steps-16
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('quick/steps-16', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4,
       topnbench_work_cost_1(a_random, 4, 5) AS e5,
       topnbench_work_cost_1(a_random, 4, 6) AS e6,
       topnbench_work_cost_1(a_random, 4, 7) AS e7,
       topnbench_work_cost_1(a_random, 4, 8) AS e8,
       topnbench_work_cost_1(a_random, 4, 9) AS e9,
       topnbench_work_cost_1(a_random, 4, 10) AS e10,
       topnbench_work_cost_1(a_random, 4, 11) AS e11,
       topnbench_work_cost_1(a_random, 4, 12) AS e12,
       topnbench_work_cost_1(a_random, 4, 13) AS e13,
       topnbench_work_cost_1(a_random, 4, 14) AS e14,
       topnbench_work_cost_1(a_random, 4, 15) AS e15,
       topnbench_work_cost_1(a_random, 4, 16) AS e16
FROM topnbench_data
ORDER BY a_random
LIMIT 100000;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('quick/steps-16', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4,
       topnbench_work_cost_1(a_random, 4, 5) AS e5,
       topnbench_work_cost_1(a_random, 4, 6) AS e6,
       topnbench_work_cost_1(a_random, 4, 7) AS e7,
       topnbench_work_cost_1(a_random, 4, 8) AS e8,
       topnbench_work_cost_1(a_random, 4, 9) AS e9,
       topnbench_work_cost_1(a_random, 4, 10) AS e10,
       topnbench_work_cost_1(a_random, 4, 11) AS e11,
       topnbench_work_cost_1(a_random, 4, 12) AS e12,
       topnbench_work_cost_1(a_random, 4, 13) AS e13,
       topnbench_work_cost_1(a_random, 4, 14) AS e14,
       topnbench_work_cost_1(a_random, 4, 15) AS e15,
       topnbench_work_cost_1(a_random, 4, 16) AS e16
FROM topnbench_data
ORDER BY a_random
LIMIT 100000;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('quick/steps-16', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4,
       topnbench_work_cost_1(a_random, 4, 5) AS e5,
       topnbench_work_cost_1(a_random, 4, 6) AS e6,
       topnbench_work_cost_1(a_random, 4, 7) AS e7,
       topnbench_work_cost_1(a_random, 4, 8) AS e8,
       topnbench_work_cost_1(a_random, 4, 9) AS e9,
       topnbench_work_cost_1(a_random, 4, 10) AS e10,
       topnbench_work_cost_1(a_random, 4, 11) AS e11,
       topnbench_work_cost_1(a_random, 4, 12) AS e12,
       topnbench_work_cost_1(a_random, 4, 13) AS e13,
       topnbench_work_cost_1(a_random, 4, 14) AS e14,
       topnbench_work_cost_1(a_random, 4, 15) AS e15,
       topnbench_work_cost_1(a_random, 4, 16) AS e16
FROM topnbench_data
ORDER BY a_random
LIMIT 100000;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('quick/steps-16', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 4, 1) AS e1,
       topnbench_work_cost_1(s.k, 4, 2) AS e2,
       topnbench_work_cost_1(s.k, 4, 3) AS e3,
       topnbench_work_cost_1(s.k, 4, 4) AS e4,
       topnbench_work_cost_1(s.k, 4, 5) AS e5,
       topnbench_work_cost_1(s.k, 4, 6) AS e6,
       topnbench_work_cost_1(s.k, 4, 7) AS e7,
       topnbench_work_cost_1(s.k, 4, 8) AS e8,
       topnbench_work_cost_1(s.k, 4, 9) AS e9,
       topnbench_work_cost_1(s.k, 4, 10) AS e10,
       topnbench_work_cost_1(s.k, 4, 11) AS e11,
       topnbench_work_cost_1(s.k, 4, 12) AS e12,
       topnbench_work_cost_1(s.k, 4, 13) AS e13,
       topnbench_work_cost_1(s.k, 4, 14) AS e14,
       topnbench_work_cost_1(s.k, 4, 15) AS e15,
       topnbench_work_cost_1(s.k, 4, 16) AS e16
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 100000) AS s
LIMIT 100000;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('quick/steps-16', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4,
       topnbench_work_cost_1(a_random, 4, 5) AS e5,
       topnbench_work_cost_1(a_random, 4, 6) AS e6,
       topnbench_work_cost_1(a_random, 4, 7) AS e7,
       topnbench_work_cost_1(a_random, 4, 8) AS e8,
       topnbench_work_cost_1(a_random, 4, 9) AS e9,
       topnbench_work_cost_1(a_random, 4, 10) AS e10,
       topnbench_work_cost_1(a_random, 4, 11) AS e11,
       topnbench_work_cost_1(a_random, 4, 12) AS e12,
       topnbench_work_cost_1(a_random, 4, 13) AS e13,
       topnbench_work_cost_1(a_random, 4, 14) AS e14,
       topnbench_work_cost_1(a_random, 4, 15) AS e15,
       topnbench_work_cost_1(a_random, 4, 16) AS e16
FROM topnbench_data
ORDER BY a_random, e1, e2, e3, e4, e5, e6, e7, e8, e9, e10, e11, e12, e13, e14, e15, e16
LIMIT 100000;

-- case: quick/cost-1-work-1
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('quick/cost-1-work-1', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 1, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('quick/cost-1-work-1', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 1, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('quick/cost-1-work-1', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 1, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('quick/cost-1-work-1', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 1, 1) AS e1
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 250000) AS s
LIMIT 250000;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('quick/cost-1-work-1', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 1, 1) AS e1
FROM topnbench_data
ORDER BY a_random, e1
LIMIT 250000;

-- case: quick/cost-1-work-16
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('quick/cost-1-work-16', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('quick/cost-1-work-16', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('quick/cost-1-work-16', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('quick/cost-1-work-16', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 16, 1) AS e1
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 250000) AS s
LIMIT 250000;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('quick/cost-1-work-16', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random, e1
LIMIT 250000;

-- case: quick/cost-1-work-64
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('quick/cost-1-work-64', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 64, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('quick/cost-1-work-64', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 64, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('quick/cost-1-work-64', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 64, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('quick/cost-1-work-64', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 64, 1) AS e1
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 250000) AS s
LIMIT 250000;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('quick/cost-1-work-64', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 64, 1) AS e1
FROM topnbench_data
ORDER BY a_random, e1
LIMIT 250000;

-- case: quick/cost-10-work-1
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('quick/cost-10-work-1', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_10(a_random, 1, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('quick/cost-10-work-1', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_10(a_random, 1, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('quick/cost-10-work-1', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_10(a_random, 1, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('quick/cost-10-work-1', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_10(s.k, 1, 1) AS e1
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 250000) AS s
LIMIT 250000;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('quick/cost-10-work-1', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_10(a_random, 1, 1) AS e1
FROM topnbench_data
ORDER BY a_random, e1
LIMIT 250000;

-- case: quick/cost-10-work-16
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('quick/cost-10-work-16', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_10(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('quick/cost-10-work-16', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_10(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('quick/cost-10-work-16', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_10(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('quick/cost-10-work-16', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_10(s.k, 16, 1) AS e1
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 250000) AS s
LIMIT 250000;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('quick/cost-10-work-16', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_10(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random, e1
LIMIT 250000;

-- case: quick/cost-10-work-64
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('quick/cost-10-work-64', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_10(a_random, 64, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('quick/cost-10-work-64', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_10(a_random, 64, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('quick/cost-10-work-64', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_10(a_random, 64, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('quick/cost-10-work-64', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_10(s.k, 64, 1) AS e1
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 250000) AS s
LIMIT 250000;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('quick/cost-10-work-64', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_10(a_random, 64, 1) AS e1
FROM topnbench_data
ORDER BY a_random, e1
LIMIT 250000;

-- case: quick/cost-100-work-1
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('quick/cost-100-work-1', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_100(a_random, 1, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('quick/cost-100-work-1', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_100(a_random, 1, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('quick/cost-100-work-1', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_100(a_random, 1, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('quick/cost-100-work-1', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_100(s.k, 1, 1) AS e1
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 250000) AS s
LIMIT 250000;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('quick/cost-100-work-1', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_100(a_random, 1, 1) AS e1
FROM topnbench_data
ORDER BY a_random, e1
LIMIT 250000;

-- case: quick/cost-100-work-16
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('quick/cost-100-work-16', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_100(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('quick/cost-100-work-16', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_100(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('quick/cost-100-work-16', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_100(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('quick/cost-100-work-16', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_100(s.k, 16, 1) AS e1
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 250000) AS s
LIMIT 250000;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('quick/cost-100-work-16', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_100(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random, e1
LIMIT 250000;

-- case: quick/cost-100-work-64
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('quick/cost-100-work-64', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_100(a_random, 64, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('quick/cost-100-work-64', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_100(a_random, 64, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('quick/cost-100-work-64', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_100(a_random, 64, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('quick/cost-100-work-64', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_100(s.k, 64, 1) AS e1
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 250000) AS s
LIMIT 250000;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('quick/cost-100-work-64', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_100(a_random, 64, 1) AS e1
FROM topnbench_data
ORDER BY a_random, e1
LIMIT 250000;

-- case: quick/nested-1
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('quick/nested-1', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 100000;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('quick/nested-1', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 100000;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('quick/nested-1', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 100000;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('quick/nested-1', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 4, 1) AS e1
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 100000) AS s
LIMIT 100000;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('quick/nested-1', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1
FROM topnbench_data
ORDER BY a_random, e1
LIMIT 100000;

-- case: quick/nested-2
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('quick/nested-2', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(topnbench_work_cost_1(a_random, 4, 2), 4, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 100000;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('quick/nested-2', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(topnbench_work_cost_1(a_random, 4, 2), 4, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 100000;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('quick/nested-2', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(topnbench_work_cost_1(a_random, 4, 2), 4, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 100000;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('quick/nested-2', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(topnbench_work_cost_1(s.k, 4, 2), 4, 1) AS e1
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 100000) AS s
LIMIT 100000;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('quick/nested-2', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(topnbench_work_cost_1(a_random, 4, 2), 4, 1) AS e1
FROM topnbench_data
ORDER BY a_random, e1
LIMIT 100000;

-- case: quick/nested-4
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('quick/nested-4', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(a_random, 4, 4), 4, 3), 4, 2), 4, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 100000;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('quick/nested-4', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(a_random, 4, 4), 4, 3), 4, 2), 4, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 100000;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('quick/nested-4', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(a_random, 4, 4), 4, 3), 4, 2), 4, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 100000;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('quick/nested-4', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(s.k, 4, 4), 4, 3), 4, 2), 4, 1) AS e1
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 100000) AS s
LIMIT 100000;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('quick/nested-4', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(a_random, 4, 4), 4, 3), 4, 2), 4, 1) AS e1
FROM topnbench_data
ORDER BY a_random, e1
LIMIT 100000;

-- case: quick/nested-8
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('quick/nested-8', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(a_random, 4, 8), 4, 7), 4, 6), 4, 5), 4, 4), 4, 3), 4, 2), 4, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 100000;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('quick/nested-8', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(a_random, 4, 8), 4, 7), 4, 6), 4, 5), 4, 4), 4, 3), 4, 2), 4, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 100000;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('quick/nested-8', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(a_random, 4, 8), 4, 7), 4, 6), 4, 5), 4, 4), 4, 3), 4, 2), 4, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 100000;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('quick/nested-8', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(s.k, 4, 8), 4, 7), 4, 6), 4, 5), 4, 4), 4, 3), 4, 2), 4, 1) AS e1
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 100000) AS s
LIMIT 100000;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('quick/nested-8', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(a_random, 4, 8), 4, 7), 4, 6), 4, 5), 4, 4), 4, 3), 4, 2), 4, 1) AS e1
FROM topnbench_data
ORDER BY a_random, e1
LIMIT 100000;

-- case: quick/nested-16
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('quick/nested-16', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(a_random, 4, 16), 4, 15), 4, 14), 4, 13), 4, 12), 4, 11), 4, 10), 4, 9), 4, 8), 4, 7), 4, 6), 4, 5), 4, 4), 4, 3), 4, 2), 4, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 100000;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('quick/nested-16', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(a_random, 4, 16), 4, 15), 4, 14), 4, 13), 4, 12), 4, 11), 4, 10), 4, 9), 4, 8), 4, 7), 4, 6), 4, 5), 4, 4), 4, 3), 4, 2), 4, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 100000;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('quick/nested-16', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(a_random, 4, 16), 4, 15), 4, 14), 4, 13), 4, 12), 4, 11), 4, 10), 4, 9), 4, 8), 4, 7), 4, 6), 4, 5), 4, 4), 4, 3), 4, 2), 4, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 100000;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('quick/nested-16', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(s.k, 4, 16), 4, 15), 4, 14), 4, 13), 4, 12), 4, 11), 4, 10), 4, 9), 4, 8), 4, 7), 4, 6), 4, 5), 4, 4), 4, 3), 4, 2), 4, 1) AS e1
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 100000) AS s
LIMIT 100000;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('quick/nested-16', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(topnbench_work_cost_1(a_random, 4, 16), 4, 15), 4, 14), 4, 13), 4, 12), 4, 11), 4, 10), 4, 9), 4, 8), 4, 7), 4, 6), 4, 5), 4, 4), 4, 3), 4, 2), 4, 1) AS e1
FROM topnbench_data
ORDER BY a_random, e1
LIMIT 100000;

-- case: quick/parallel-limit-1
-- check: equivalent
SET max_parallel_workers_per_gather = 2;

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('quick/parallel-limit-1', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 1;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('quick/parallel-limit-1', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 1;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('quick/parallel-limit-1', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 1;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('quick/parallel-limit-1', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 4, 1) AS e1,
       topnbench_work_cost_1(s.k, 4, 2) AS e2,
       topnbench_work_cost_1(s.k, 4, 3) AS e3,
       topnbench_work_cost_1(s.k, 4, 4) AS e4
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 1) AS s
LIMIT 1;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('quick/parallel-limit-1', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random, e1, e2, e3, e4
LIMIT 1;

-- case: quick/parallel-limit-1pct
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('quick/parallel-limit-1pct', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 10000;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('quick/parallel-limit-1pct', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 10000;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('quick/parallel-limit-1pct', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 10000;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('quick/parallel-limit-1pct', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 4, 1) AS e1,
       topnbench_work_cost_1(s.k, 4, 2) AS e2,
       topnbench_work_cost_1(s.k, 4, 3) AS e3,
       topnbench_work_cost_1(s.k, 4, 4) AS e4
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 10000) AS s
LIMIT 10000;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('quick/parallel-limit-1pct', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random, e1, e2, e3, e4
LIMIT 10000;

-- case: quick/parallel-limit-25pct
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('quick/parallel-limit-25pct', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('quick/parallel-limit-25pct', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('quick/parallel-limit-25pct', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('quick/parallel-limit-25pct', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 4, 1) AS e1,
       topnbench_work_cost_1(s.k, 4, 2) AS e2,
       topnbench_work_cost_1(s.k, 4, 3) AS e3,
       topnbench_work_cost_1(s.k, 4, 4) AS e4
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 250000) AS s
LIMIT 250000;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('quick/parallel-limit-25pct', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random, e1, e2, e3, e4
LIMIT 250000;

-- case: quick/parallel-limit-50pct
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('quick/parallel-limit-50pct', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 500000;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('quick/parallel-limit-50pct', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 500000;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('quick/parallel-limit-50pct', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 500000;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('quick/parallel-limit-50pct', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 4, 1) AS e1,
       topnbench_work_cost_1(s.k, 4, 2) AS e2,
       topnbench_work_cost_1(s.k, 4, 3) AS e3,
       topnbench_work_cost_1(s.k, 4, 4) AS e4
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 500000) AS s
LIMIT 500000;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('quick/parallel-limit-50pct', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random, e1, e2, e3, e4
LIMIT 500000;

-- case: quick/offset-10pct-limit-1
-- check: equivalent
SET max_parallel_workers_per_gather = 0;

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('quick/offset-10pct-limit-1', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
OFFSET 100000
LIMIT 1;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('quick/offset-10pct-limit-1', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
OFFSET 100000
LIMIT 1;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('quick/offset-10pct-limit-1', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
OFFSET 100000
LIMIT 1;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('quick/offset-10pct-limit-1', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 4, 1) AS e1,
       topnbench_work_cost_1(s.k, 4, 2) AS e2,
       topnbench_work_cost_1(s.k, 4, 3) AS e3,
       topnbench_work_cost_1(s.k, 4, 4) AS e4
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 100001) AS s
OFFSET 100000
LIMIT 1;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('quick/offset-10pct-limit-1', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random, e1, e2, e3, e4
OFFSET 100000
LIMIT 1;

-- case: quick/offset-25pct-limit-1
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('quick/offset-25pct-limit-1', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
OFFSET 250000
LIMIT 1;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('quick/offset-25pct-limit-1', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
OFFSET 250000
LIMIT 1;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('quick/offset-25pct-limit-1', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
OFFSET 250000
LIMIT 1;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('quick/offset-25pct-limit-1', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 4, 1) AS e1,
       topnbench_work_cost_1(s.k, 4, 2) AS e2,
       topnbench_work_cost_1(s.k, 4, 3) AS e3,
       topnbench_work_cost_1(s.k, 4, 4) AS e4
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 250001) AS s
OFFSET 250000
LIMIT 1;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('quick/offset-25pct-limit-1', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random, e1, e2, e3, e4
OFFSET 250000
LIMIT 1;

-- case: expressions/numeric-example
-- check: equivalent
SET max_parallel_workers_per_gather = 2;

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('expressions/numeric-example', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a,
               a / (a * -1),
               a::numeric AS b,
               abs(a::numeric) / 12345.345632
        FROM topnbench_data ORDER BY a LIMIT 1;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('expressions/numeric-example', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a,
               a / (a * -1),
               a::numeric AS b,
               abs(a::numeric) / 12345.345632
        FROM topnbench_data ORDER BY a LIMIT 1;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('expressions/numeric-example', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a,
               a / (a * -1),
               a::numeric AS b,
               abs(a::numeric) / 12345.345632
        FROM topnbench_data ORDER BY a LIMIT 1;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('expressions/numeric-example', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.a,
               s.a / (s.a * -1),
               s.a::numeric AS b,
               abs(s.a::numeric) / 12345.345632
        FROM (SELECT a FROM topnbench_data ORDER BY a LIMIT 1) AS s;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('expressions/numeric-example', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a,
               a / (a * -1) AS e2,
               a::numeric AS b,
               abs(a::numeric) / 12345.345632 AS e4
        FROM topnbench_data ORDER BY a, e2, b, e4 LIMIT 1;

-- case: expressions/cheap-builtins
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('expressions/cheap-builtins', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a, a + 1 AS e1, a * 3 AS e2,
               abs(a - 500000) AS e3
        FROM topnbench_data ORDER BY a LIMIT 250000;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('expressions/cheap-builtins', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a, a + 1 AS e1, a * 3 AS e2,
               abs(a - 500000) AS e3
        FROM topnbench_data ORDER BY a LIMIT 250000;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('expressions/cheap-builtins', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a, a + 1 AS e1, a * 3 AS e2,
               abs(a - 500000) AS e3
        FROM topnbench_data ORDER BY a LIMIT 250000;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('expressions/cheap-builtins', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.a, s.a + 1 AS e1, s.a * 3 AS e2,
               abs(s.a - 500000) AS e3
        FROM (SELECT a FROM topnbench_data
              ORDER BY a LIMIT 250000) AS s;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('expressions/cheap-builtins', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a, a + 1 AS e1, a * 3 AS e2,
               abs(a - 500000) AS e3
        FROM topnbench_data ORDER BY a, e1, e2, e3 LIMIT 250000;

-- case: expressions/text-producing
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('expressions/text-producing', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a, a::text AS e1, md5(a::text) AS e2
        FROM topnbench_data ORDER BY a LIMIT 10000;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('expressions/text-producing', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a, a::text AS e1, md5(a::text) AS e2
        FROM topnbench_data ORDER BY a LIMIT 10000;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('expressions/text-producing', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a, a::text AS e1, md5(a::text) AS e2
        FROM topnbench_data ORDER BY a LIMIT 10000;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('expressions/text-producing', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.a, s.a::text AS e1, md5(s.a::text) AS e2
        FROM (SELECT a FROM topnbench_data
              ORDER BY a LIMIT 10000) AS s;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('expressions/text-producing', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a, a::text AS e1, md5(a::text) AS e2
        FROM topnbench_data ORDER BY a, e1, e2 LIMIT 10000;

-- case: estimates/rows-underestimated
-- check: equivalent
SET max_parallel_workers_per_gather = 0;
SET work_mem = '256MB';

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('estimates/rows-underestimated', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
               topnbench_work_cost_1(a_random, 16, 1) AS e1
        FROM topnbench_data
        WHERE a <= 100000 AND same1 <= 100000 AND same2 <= 100000
        ORDER BY a_random LIMIT 10000;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('estimates/rows-underestimated', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
               topnbench_work_cost_1(a_random, 16, 1) AS e1
        FROM topnbench_data
        WHERE a <= 100000 AND same1 <= 100000 AND same2 <= 100000
        ORDER BY a_random LIMIT 10000;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('estimates/rows-underestimated', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
               topnbench_work_cost_1(a_random, 16, 1) AS e1
        FROM topnbench_data
        WHERE a <= 100000 AND same1 <= 100000 AND same2 <= 100000
        ORDER BY a_random LIMIT 10000;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('estimates/rows-underestimated', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(s.k, 16, 1) AS e1
        FROM (SELECT a_random AS k
              FROM topnbench_data
              WHERE a <= 100000 AND same1 <= 100000 AND same2 <= 100000
              ORDER BY a_random LIMIT 10000) AS s;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('estimates/rows-underestimated', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
               topnbench_work_cost_1(a_random, 16, 1) AS e1
        FROM topnbench_data
        WHERE a <= 100000 AND same1 <= 100000 AND same2 <= 100000
        ORDER BY a_random, e1 LIMIT 10000;

-- case: estimates/rows-overestimated
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('estimates/rows-overestimated', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
               topnbench_work_cost_1(a_random, 16, 1) AS e1
        FROM topnbench_data
        WHERE a <= 550000 AND inverse <= 550000
        ORDER BY a_random LIMIT 50000;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('estimates/rows-overestimated', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
               topnbench_work_cost_1(a_random, 16, 1) AS e1
        FROM topnbench_data
        WHERE a <= 550000 AND inverse <= 550000
        ORDER BY a_random LIMIT 50000;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('estimates/rows-overestimated', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
               topnbench_work_cost_1(a_random, 16, 1) AS e1
        FROM topnbench_data
        WHERE a <= 550000 AND inverse <= 550000
        ORDER BY a_random LIMIT 50000;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('estimates/rows-overestimated', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(s.k, 16, 1) AS e1
        FROM (SELECT a_random AS k
              FROM topnbench_data
              WHERE a <= 550000 AND inverse <= 550000
              ORDER BY a_random LIMIT 50000) AS s;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('estimates/rows-overestimated', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
               topnbench_work_cost_1(a_random, 16, 1) AS e1
        FROM topnbench_data
        WHERE a <= 550000 AND inverse <= 550000
        ORDER BY a_random, e1 LIMIT 50000;

-- case: estimates/projection-expands-tuple
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('estimates/projection-expands-tuple', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k, repeat(md5(a_random::text), 8) AS e1
        FROM topnbench_data ORDER BY a_random LIMIT 10000;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('estimates/projection-expands-tuple', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k, repeat(md5(a_random::text), 8) AS e1
        FROM topnbench_data ORDER BY a_random LIMIT 10000;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('estimates/projection-expands-tuple', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k, repeat(md5(a_random::text), 8) AS e1
        FROM topnbench_data ORDER BY a_random LIMIT 10000;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('estimates/projection-expands-tuple', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, repeat(md5(s.k::text), 8) AS e1
        FROM (SELECT a_random AS k FROM topnbench_data
              ORDER BY a_random LIMIT 10000) AS s;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('estimates/projection-expands-tuple', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k, repeat(md5(a_random::text), 8) AS e1
        FROM topnbench_data ORDER BY a_random, e1 LIMIT 10000;

-- case: input-order/input-ascending
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('input-order/input-ascending', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a AS k,
       topnbench_work_cost_1(a, 16, 1) AS e1
FROM topnbench_data
ORDER BY a
LIMIT 250000;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('input-order/input-ascending', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a AS k,
       topnbench_work_cost_1(a, 16, 1) AS e1
FROM topnbench_data
ORDER BY a
LIMIT 250000;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('input-order/input-ascending', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a AS k,
       topnbench_work_cost_1(a, 16, 1) AS e1
FROM topnbench_data
ORDER BY a
LIMIT 250000;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('input-order/input-ascending', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 16, 1) AS e1
FROM (SELECT a AS k FROM topnbench_data
      ORDER BY a LIMIT 250000) AS s
LIMIT 250000;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('input-order/input-ascending', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a AS k,
       topnbench_work_cost_1(a, 16, 1) AS e1
FROM topnbench_data
ORDER BY a, e1
LIMIT 250000;

-- case: input-order/input-descending
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('input-order/input-descending', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_desc AS k,
       topnbench_work_cost_1(a_desc, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_desc
LIMIT 250000;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('input-order/input-descending', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_desc AS k,
       topnbench_work_cost_1(a_desc, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_desc
LIMIT 250000;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('input-order/input-descending', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_desc AS k,
       topnbench_work_cost_1(a_desc, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_desc
LIMIT 250000;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('input-order/input-descending', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 16, 1) AS e1
FROM (SELECT a_desc AS k FROM topnbench_data
      ORDER BY a_desc LIMIT 250000) AS s
LIMIT 250000;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('input-order/input-descending', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_desc AS k,
       topnbench_work_cost_1(a_desc, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_desc, e1
LIMIT 250000;

-- case: input-order/input-random
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('input-order/input-random', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('input-order/input-random', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('input-order/input-random', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('input-order/input-random', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 16, 1) AS e1
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 250000) AS s
LIMIT 250000;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('input-order/input-random', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random, e1
LIMIT 250000;

-- case: estimates/width-underestimate
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('estimates/width-underestimate', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_underestimate
ORDER BY a
LIMIT 25000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('estimates/width-underestimate', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_underestimate
ORDER BY a
LIMIT 25000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('estimates/width-underestimate', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_underestimate
ORDER BY a
LIMIT 25000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('estimates/width-underestimate', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, length(payload) AS e1
FROM (SELECT a AS k, payload FROM topnbench_width_underestimate
      ORDER BY a LIMIT 25000) AS s
LIMIT 25000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('estimates/width-underestimate', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_underestimate
ORDER BY a, e1
LIMIT 25000 OFFSET 0;

-- case: estimates/width-overestimate
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('estimates/width-overestimate', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_overestimate
ORDER BY a
LIMIT 25000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('estimates/width-overestimate', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_overestimate
ORDER BY a
LIMIT 25000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('estimates/width-overestimate', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_overestimate
ORDER BY a
LIMIT 25000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('estimates/width-overestimate', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, length(payload) AS e1
FROM (SELECT a AS k, payload FROM topnbench_width_overestimate
      ORDER BY a LIMIT 25000) AS s
LIMIT 25000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('estimates/width-overestimate', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_overestimate
ORDER BY a, e1
LIMIT 25000 OFFSET 0;

-- case: width-stale/work-mem-64kB
-- check: equivalent
SET work_mem = '64kB';

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('width-stale/work-mem-64kB', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_underestimate
ORDER BY a
LIMIT 5000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('width-stale/work-mem-64kB', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_underestimate
ORDER BY a
LIMIT 5000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('width-stale/work-mem-64kB', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_underestimate
ORDER BY a
LIMIT 5000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('width-stale/work-mem-64kB', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, length(payload) AS e1
FROM (SELECT a AS k, payload FROM topnbench_width_underestimate
      ORDER BY a LIMIT 5000) AS s
LIMIT 5000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('width-stale/work-mem-64kB', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_underestimate
ORDER BY a, e1
LIMIT 5000 OFFSET 0;

-- case: width-stale/work-mem-256kB
-- check: equivalent
SET work_mem = '256kB';

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('width-stale/work-mem-256kB', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_underestimate
ORDER BY a
LIMIT 5000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('width-stale/work-mem-256kB', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_underestimate
ORDER BY a
LIMIT 5000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('width-stale/work-mem-256kB', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_underestimate
ORDER BY a
LIMIT 5000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('width-stale/work-mem-256kB', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, length(payload) AS e1
FROM (SELECT a AS k, payload FROM topnbench_width_underestimate
      ORDER BY a LIMIT 5000) AS s
LIMIT 5000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('width-stale/work-mem-256kB', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_underestimate
ORDER BY a, e1
LIMIT 5000 OFFSET 0;

-- case: width-stale/work-mem-1MB
-- check: equivalent
SET work_mem = '1MB';

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('width-stale/work-mem-1MB', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_underestimate
ORDER BY a
LIMIT 5000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('width-stale/work-mem-1MB', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_underestimate
ORDER BY a
LIMIT 5000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('width-stale/work-mem-1MB', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_underestimate
ORDER BY a
LIMIT 5000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('width-stale/work-mem-1MB', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, length(payload) AS e1
FROM (SELECT a AS k, payload FROM topnbench_width_underestimate
      ORDER BY a LIMIT 5000) AS s
LIMIT 5000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('width-stale/work-mem-1MB', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_underestimate
ORDER BY a, e1
LIMIT 5000 OFFSET 0;

-- case: width-stale/work-mem-4MB
-- check: equivalent
SET work_mem = '4MB';

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('width-stale/work-mem-4MB', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_underestimate
ORDER BY a
LIMIT 5000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('width-stale/work-mem-4MB', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_underestimate
ORDER BY a
LIMIT 5000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('width-stale/work-mem-4MB', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_underestimate
ORDER BY a
LIMIT 5000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('width-stale/work-mem-4MB', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, length(payload) AS e1
FROM (SELECT a AS k, payload FROM topnbench_width_underestimate
      ORDER BY a LIMIT 5000) AS s
LIMIT 5000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('width-stale/work-mem-4MB', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_underestimate
ORDER BY a, e1
LIMIT 5000 OFFSET 0;

-- case: width-stale/work-mem-16MB
-- check: equivalent
SET work_mem = '16MB';

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('width-stale/work-mem-16MB', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_underestimate
ORDER BY a
LIMIT 5000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('width-stale/work-mem-16MB', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_underestimate
ORDER BY a
LIMIT 5000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('width-stale/work-mem-16MB', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_underestimate
ORDER BY a
LIMIT 5000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('width-stale/work-mem-16MB', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, length(payload) AS e1
FROM (SELECT a AS k, payload FROM topnbench_width_underestimate
      ORDER BY a LIMIT 5000) AS s
LIMIT 5000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('width-stale/work-mem-16MB', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_underestimate
ORDER BY a, e1
LIMIT 5000 OFFSET 0;

-- case: width-stale/work-mem-64MB
-- check: equivalent
SET work_mem = '64MB';

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('width-stale/work-mem-64MB', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_underestimate
ORDER BY a
LIMIT 5000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('width-stale/work-mem-64MB', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_underestimate
ORDER BY a
LIMIT 5000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('width-stale/work-mem-64MB', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_underestimate
ORDER BY a
LIMIT 5000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('width-stale/work-mem-64MB', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, length(payload) AS e1
FROM (SELECT a AS k, payload FROM topnbench_width_underestimate
      ORDER BY a LIMIT 5000) AS s
LIMIT 5000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('width-stale/work-mem-64MB', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_underestimate
ORDER BY a, e1
LIMIT 5000 OFFSET 0;

-- case: width-stale/work-mem-256MB
-- check: equivalent
SET work_mem = '256MB';

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('width-stale/work-mem-256MB', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_underestimate
ORDER BY a
LIMIT 5000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('width-stale/work-mem-256MB', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_underestimate
ORDER BY a
LIMIT 5000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('width-stale/work-mem-256MB', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_underestimate
ORDER BY a
LIMIT 5000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('width-stale/work-mem-256MB', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, length(payload) AS e1
FROM (SELECT a AS k, payload FROM topnbench_width_underestimate
      ORDER BY a LIMIT 5000) AS s
LIMIT 5000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('width-stale/work-mem-256MB', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_underestimate
ORDER BY a, e1
LIMIT 5000 OFFSET 0;

-- case: width-accurate/work-mem-64kB
-- check: equivalent
SET work_mem = '64kB';

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('width-accurate/work-mem-64kB', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_accurate
ORDER BY a
LIMIT 5000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('width-accurate/work-mem-64kB', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_accurate
ORDER BY a
LIMIT 5000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('width-accurate/work-mem-64kB', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_accurate
ORDER BY a
LIMIT 5000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('width-accurate/work-mem-64kB', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, length(payload) AS e1
FROM (SELECT a AS k, payload FROM topnbench_width_accurate
      ORDER BY a LIMIT 5000) AS s
LIMIT 5000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('width-accurate/work-mem-64kB', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_accurate
ORDER BY a, e1
LIMIT 5000 OFFSET 0;

-- case: width-accurate/work-mem-256kB
-- check: equivalent
SET work_mem = '256kB';

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('width-accurate/work-mem-256kB', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_accurate
ORDER BY a
LIMIT 5000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('width-accurate/work-mem-256kB', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_accurate
ORDER BY a
LIMIT 5000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('width-accurate/work-mem-256kB', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_accurate
ORDER BY a
LIMIT 5000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('width-accurate/work-mem-256kB', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, length(payload) AS e1
FROM (SELECT a AS k, payload FROM topnbench_width_accurate
      ORDER BY a LIMIT 5000) AS s
LIMIT 5000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('width-accurate/work-mem-256kB', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_accurate
ORDER BY a, e1
LIMIT 5000 OFFSET 0;

-- case: width-accurate/work-mem-1MB
-- check: equivalent
SET work_mem = '1MB';

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('width-accurate/work-mem-1MB', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_accurate
ORDER BY a
LIMIT 5000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('width-accurate/work-mem-1MB', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_accurate
ORDER BY a
LIMIT 5000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('width-accurate/work-mem-1MB', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_accurate
ORDER BY a
LIMIT 5000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('width-accurate/work-mem-1MB', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, length(payload) AS e1
FROM (SELECT a AS k, payload FROM topnbench_width_accurate
      ORDER BY a LIMIT 5000) AS s
LIMIT 5000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('width-accurate/work-mem-1MB', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_accurate
ORDER BY a, e1
LIMIT 5000 OFFSET 0;

-- case: width-accurate/work-mem-4MB
-- check: equivalent
SET work_mem = '4MB';

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('width-accurate/work-mem-4MB', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_accurate
ORDER BY a
LIMIT 5000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('width-accurate/work-mem-4MB', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_accurate
ORDER BY a
LIMIT 5000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('width-accurate/work-mem-4MB', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_accurate
ORDER BY a
LIMIT 5000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('width-accurate/work-mem-4MB', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, length(payload) AS e1
FROM (SELECT a AS k, payload FROM topnbench_width_accurate
      ORDER BY a LIMIT 5000) AS s
LIMIT 5000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('width-accurate/work-mem-4MB', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_accurate
ORDER BY a, e1
LIMIT 5000 OFFSET 0;

-- case: width-accurate/work-mem-16MB
-- check: equivalent
SET work_mem = '16MB';

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('width-accurate/work-mem-16MB', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_accurate
ORDER BY a
LIMIT 5000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('width-accurate/work-mem-16MB', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_accurate
ORDER BY a
LIMIT 5000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('width-accurate/work-mem-16MB', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_accurate
ORDER BY a
LIMIT 5000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('width-accurate/work-mem-16MB', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, length(payload) AS e1
FROM (SELECT a AS k, payload FROM topnbench_width_accurate
      ORDER BY a LIMIT 5000) AS s
LIMIT 5000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('width-accurate/work-mem-16MB', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_accurate
ORDER BY a, e1
LIMIT 5000 OFFSET 0;

-- case: width-accurate/work-mem-64MB
-- check: equivalent
SET work_mem = '64MB';

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('width-accurate/work-mem-64MB', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_accurate
ORDER BY a
LIMIT 5000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('width-accurate/work-mem-64MB', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_accurate
ORDER BY a
LIMIT 5000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('width-accurate/work-mem-64MB', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_accurate
ORDER BY a
LIMIT 5000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('width-accurate/work-mem-64MB', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, length(payload) AS e1
FROM (SELECT a AS k, payload FROM topnbench_width_accurate
      ORDER BY a LIMIT 5000) AS s
LIMIT 5000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('width-accurate/work-mem-64MB', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_accurate
ORDER BY a, e1
LIMIT 5000 OFFSET 0;

-- case: width-accurate/work-mem-256MB
-- check: equivalent
SET work_mem = '256MB';

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('width-accurate/work-mem-256MB', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_accurate
ORDER BY a
LIMIT 5000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('width-accurate/work-mem-256MB', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_accurate
ORDER BY a
LIMIT 5000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('width-accurate/work-mem-256MB', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_accurate
ORDER BY a
LIMIT 5000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('width-accurate/work-mem-256MB', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, length(payload) AS e1
FROM (SELECT a AS k, payload FROM topnbench_width_accurate
      ORDER BY a LIMIT 5000) AS s
LIMIT 5000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('width-accurate/work-mem-256MB', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_accurate
ORDER BY a, e1
LIMIT 5000 OFFSET 0;

-- case: early-controls/cost-1-limit-25pct/64kB
-- check: equivalent
SET work_mem = '64kB';

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('early-controls/cost-1-limit-25pct/64kB', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('early-controls/cost-1-limit-25pct/64kB', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('early-controls/cost-1-limit-25pct/64kB', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('early-controls/cost-1-limit-25pct/64kB', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_width_accurate
      ORDER BY sort_key LIMIT 25000) AS s
LIMIT 25000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('early-controls/cost-1-limit-25pct/64kB', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key, e1
LIMIT 25000 OFFSET 0;

-- case: early-controls/cost-1-limit-25pct/4MB
-- check: equivalent
SET work_mem = '4MB';

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('early-controls/cost-1-limit-25pct/4MB', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('early-controls/cost-1-limit-25pct/4MB', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('early-controls/cost-1-limit-25pct/4MB', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('early-controls/cost-1-limit-25pct/4MB', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_width_accurate
      ORDER BY sort_key LIMIT 25000) AS s
LIMIT 25000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('early-controls/cost-1-limit-25pct/4MB', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key, e1
LIMIT 25000 OFFSET 0;

-- case: early-controls/cost-1-limit-25pct/256MB
-- check: equivalent
SET work_mem = '256MB';

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('early-controls/cost-1-limit-25pct/256MB', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('early-controls/cost-1-limit-25pct/256MB', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('early-controls/cost-1-limit-25pct/256MB', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('early-controls/cost-1-limit-25pct/256MB', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_width_accurate
      ORDER BY sort_key LIMIT 25000) AS s
LIMIT 25000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('early-controls/cost-1-limit-25pct/256MB', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key, e1
LIMIT 25000 OFFSET 0;

-- case: early-controls/cost-1-limit-50pct/64kB
-- check: equivalent
SET work_mem = '64kB';

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('early-controls/cost-1-limit-50pct/64kB', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 50000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('early-controls/cost-1-limit-50pct/64kB', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 50000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('early-controls/cost-1-limit-50pct/64kB', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 50000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('early-controls/cost-1-limit-50pct/64kB', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_width_accurate
      ORDER BY sort_key LIMIT 50000) AS s
LIMIT 50000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('early-controls/cost-1-limit-50pct/64kB', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key, e1
LIMIT 50000 OFFSET 0;

-- case: early-controls/cost-1-limit-50pct/4MB
-- check: equivalent
SET work_mem = '4MB';

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('early-controls/cost-1-limit-50pct/4MB', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 50000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('early-controls/cost-1-limit-50pct/4MB', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 50000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('early-controls/cost-1-limit-50pct/4MB', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 50000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('early-controls/cost-1-limit-50pct/4MB', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_width_accurate
      ORDER BY sort_key LIMIT 50000) AS s
LIMIT 50000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('early-controls/cost-1-limit-50pct/4MB', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key, e1
LIMIT 50000 OFFSET 0;

-- case: early-controls/cost-1-limit-50pct/256MB
-- check: equivalent
SET work_mem = '256MB';

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('early-controls/cost-1-limit-50pct/256MB', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 50000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('early-controls/cost-1-limit-50pct/256MB', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 50000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('early-controls/cost-1-limit-50pct/256MB', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 50000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('early-controls/cost-1-limit-50pct/256MB', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_width_accurate
      ORDER BY sort_key LIMIT 50000) AS s
LIMIT 50000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('early-controls/cost-1-limit-50pct/256MB', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key, e1
LIMIT 50000 OFFSET 0;

-- case: early-controls/cost-1-limit-75pct/64kB
-- check: equivalent
SET work_mem = '64kB';

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('early-controls/cost-1-limit-75pct/64kB', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 75000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('early-controls/cost-1-limit-75pct/64kB', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 75000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('early-controls/cost-1-limit-75pct/64kB', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 75000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('early-controls/cost-1-limit-75pct/64kB', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_width_accurate
      ORDER BY sort_key LIMIT 75000) AS s
LIMIT 75000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('early-controls/cost-1-limit-75pct/64kB', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key, e1
LIMIT 75000 OFFSET 0;

-- case: early-controls/cost-1-limit-75pct/4MB
-- check: equivalent
SET work_mem = '4MB';

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('early-controls/cost-1-limit-75pct/4MB', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 75000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('early-controls/cost-1-limit-75pct/4MB', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 75000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('early-controls/cost-1-limit-75pct/4MB', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 75000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('early-controls/cost-1-limit-75pct/4MB', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_width_accurate
      ORDER BY sort_key LIMIT 75000) AS s
LIMIT 75000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('early-controls/cost-1-limit-75pct/4MB', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key, e1
LIMIT 75000 OFFSET 0;

-- case: early-controls/cost-1-limit-75pct/256MB
-- check: equivalent
SET work_mem = '256MB';

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('early-controls/cost-1-limit-75pct/256MB', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 75000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('early-controls/cost-1-limit-75pct/256MB', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 75000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('early-controls/cost-1-limit-75pct/256MB', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 75000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('early-controls/cost-1-limit-75pct/256MB', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_width_accurate
      ORDER BY sort_key LIMIT 75000) AS s
LIMIT 75000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('early-controls/cost-1-limit-75pct/256MB', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key, e1
LIMIT 75000 OFFSET 0;

-- case: early-controls/cost-1-limit-100pct/64kB
-- check: equivalent
SET work_mem = '64kB';

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('early-controls/cost-1-limit-100pct/64kB', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 100000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('early-controls/cost-1-limit-100pct/64kB', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 100000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('early-controls/cost-1-limit-100pct/64kB', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 100000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('early-controls/cost-1-limit-100pct/64kB', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_width_accurate
      ORDER BY sort_key LIMIT 100000) AS s
LIMIT 100000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('early-controls/cost-1-limit-100pct/64kB', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key, e1
LIMIT 100000 OFFSET 0;

-- case: early-controls/cost-1-limit-100pct/4MB
-- check: equivalent
SET work_mem = '4MB';

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('early-controls/cost-1-limit-100pct/4MB', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 100000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('early-controls/cost-1-limit-100pct/4MB', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 100000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('early-controls/cost-1-limit-100pct/4MB', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 100000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('early-controls/cost-1-limit-100pct/4MB', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_width_accurate
      ORDER BY sort_key LIMIT 100000) AS s
LIMIT 100000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('early-controls/cost-1-limit-100pct/4MB', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key, e1
LIMIT 100000 OFFSET 0;

-- case: early-controls/cost-1-limit-100pct/256MB
-- check: equivalent
SET work_mem = '256MB';

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('early-controls/cost-1-limit-100pct/256MB', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 100000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('early-controls/cost-1-limit-100pct/256MB', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 100000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('early-controls/cost-1-limit-100pct/256MB', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 100000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('early-controls/cost-1-limit-100pct/256MB', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_width_accurate
      ORDER BY sort_key LIMIT 100000) AS s
LIMIT 100000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('early-controls/cost-1-limit-100pct/256MB', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key, e1
LIMIT 100000 OFFSET 0;

-- case: early-controls/cost-100-limit-25pct/64kB
-- check: equivalent
SET work_mem = '64kB';

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('early-controls/cost-100-limit-25pct/64kB', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('early-controls/cost-100-limit-25pct/64kB', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('early-controls/cost-100-limit-25pct/64kB', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('early-controls/cost-100-limit-25pct/64kB', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_width_accurate
      ORDER BY sort_key LIMIT 25000) AS s
LIMIT 25000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('early-controls/cost-100-limit-25pct/64kB', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key, e1
LIMIT 25000 OFFSET 0;

-- case: early-controls/cost-100-limit-25pct/4MB
-- check: equivalent
SET work_mem = '4MB';

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('early-controls/cost-100-limit-25pct/4MB', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('early-controls/cost-100-limit-25pct/4MB', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('early-controls/cost-100-limit-25pct/4MB', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('early-controls/cost-100-limit-25pct/4MB', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_width_accurate
      ORDER BY sort_key LIMIT 25000) AS s
LIMIT 25000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('early-controls/cost-100-limit-25pct/4MB', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key, e1
LIMIT 25000 OFFSET 0;

-- case: early-controls/cost-100-limit-25pct/256MB
-- check: equivalent
SET work_mem = '256MB';

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('early-controls/cost-100-limit-25pct/256MB', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('early-controls/cost-100-limit-25pct/256MB', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('early-controls/cost-100-limit-25pct/256MB', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('early-controls/cost-100-limit-25pct/256MB', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_width_accurate
      ORDER BY sort_key LIMIT 25000) AS s
LIMIT 25000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('early-controls/cost-100-limit-25pct/256MB', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key, e1
LIMIT 25000 OFFSET 0;

-- case: early-controls/cost-100-limit-50pct/64kB
-- check: equivalent
SET work_mem = '64kB';

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('early-controls/cost-100-limit-50pct/64kB', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 50000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('early-controls/cost-100-limit-50pct/64kB', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 50000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('early-controls/cost-100-limit-50pct/64kB', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 50000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('early-controls/cost-100-limit-50pct/64kB', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_width_accurate
      ORDER BY sort_key LIMIT 50000) AS s
LIMIT 50000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('early-controls/cost-100-limit-50pct/64kB', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key, e1
LIMIT 50000 OFFSET 0;

-- case: early-controls/cost-100-limit-50pct/4MB
-- check: equivalent
SET work_mem = '4MB';

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('early-controls/cost-100-limit-50pct/4MB', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 50000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('early-controls/cost-100-limit-50pct/4MB', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 50000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('early-controls/cost-100-limit-50pct/4MB', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 50000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('early-controls/cost-100-limit-50pct/4MB', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_width_accurate
      ORDER BY sort_key LIMIT 50000) AS s
LIMIT 50000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('early-controls/cost-100-limit-50pct/4MB', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key, e1
LIMIT 50000 OFFSET 0;

-- case: early-controls/cost-100-limit-50pct/256MB
-- check: equivalent
SET work_mem = '256MB';

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('early-controls/cost-100-limit-50pct/256MB', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 50000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('early-controls/cost-100-limit-50pct/256MB', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 50000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('early-controls/cost-100-limit-50pct/256MB', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 50000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('early-controls/cost-100-limit-50pct/256MB', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_width_accurate
      ORDER BY sort_key LIMIT 50000) AS s
LIMIT 50000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('early-controls/cost-100-limit-50pct/256MB', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key, e1
LIMIT 50000 OFFSET 0;

-- case: early-controls/cost-100-limit-75pct/64kB
-- check: equivalent
SET work_mem = '64kB';

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('early-controls/cost-100-limit-75pct/64kB', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 75000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('early-controls/cost-100-limit-75pct/64kB', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 75000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('early-controls/cost-100-limit-75pct/64kB', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 75000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('early-controls/cost-100-limit-75pct/64kB', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_width_accurate
      ORDER BY sort_key LIMIT 75000) AS s
LIMIT 75000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('early-controls/cost-100-limit-75pct/64kB', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key, e1
LIMIT 75000 OFFSET 0;

-- case: early-controls/cost-100-limit-75pct/4MB
-- check: equivalent
SET work_mem = '4MB';

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('early-controls/cost-100-limit-75pct/4MB', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 75000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('early-controls/cost-100-limit-75pct/4MB', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 75000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('early-controls/cost-100-limit-75pct/4MB', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 75000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('early-controls/cost-100-limit-75pct/4MB', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_width_accurate
      ORDER BY sort_key LIMIT 75000) AS s
LIMIT 75000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('early-controls/cost-100-limit-75pct/4MB', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key, e1
LIMIT 75000 OFFSET 0;

-- case: early-controls/cost-100-limit-75pct/256MB
-- check: equivalent
SET work_mem = '256MB';

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('early-controls/cost-100-limit-75pct/256MB', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 75000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('early-controls/cost-100-limit-75pct/256MB', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 75000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('early-controls/cost-100-limit-75pct/256MB', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 75000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('early-controls/cost-100-limit-75pct/256MB', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_width_accurate
      ORDER BY sort_key LIMIT 75000) AS s
LIMIT 75000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('early-controls/cost-100-limit-75pct/256MB', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key, e1
LIMIT 75000 OFFSET 0;

-- case: early-controls/cost-100-limit-100pct/64kB
-- check: equivalent
SET work_mem = '64kB';

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('early-controls/cost-100-limit-100pct/64kB', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 100000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('early-controls/cost-100-limit-100pct/64kB', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 100000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('early-controls/cost-100-limit-100pct/64kB', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 100000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('early-controls/cost-100-limit-100pct/64kB', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_width_accurate
      ORDER BY sort_key LIMIT 100000) AS s
LIMIT 100000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('early-controls/cost-100-limit-100pct/64kB', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key, e1
LIMIT 100000 OFFSET 0;

-- case: early-controls/cost-100-limit-100pct/4MB
-- check: equivalent
SET work_mem = '4MB';

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('early-controls/cost-100-limit-100pct/4MB', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 100000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('early-controls/cost-100-limit-100pct/4MB', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 100000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('early-controls/cost-100-limit-100pct/4MB', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 100000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('early-controls/cost-100-limit-100pct/4MB', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_width_accurate
      ORDER BY sort_key LIMIT 100000) AS s
LIMIT 100000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('early-controls/cost-100-limit-100pct/4MB', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key, e1
LIMIT 100000 OFFSET 0;

-- case: early-controls/cost-100-limit-100pct/256MB
-- check: equivalent
SET work_mem = '256MB';

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('early-controls/cost-100-limit-100pct/256MB', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 100000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('early-controls/cost-100-limit-100pct/256MB', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 100000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('early-controls/cost-100-limit-100pct/256MB', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key
LIMIT 100000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('early-controls/cost-100-limit-100pct/256MB', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_width_accurate
      ORDER BY sort_key LIMIT 100000) AS s
LIMIT 100000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('early-controls/cost-100-limit-100pct/256MB', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_100(octet_length(payload), 0, 0) AS e1
FROM topnbench_width_accurate
ORDER BY sort_key, e1
LIMIT 100000 OFFSET 0;

-- case: copy-width/width-8-limit-1pct
-- check: equivalent
SET work_mem = '1GB';

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('copy-width/width-8-limit-1pct', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_8
ORDER BY sort_key
LIMIT 1000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('copy-width/width-8-limit-1pct', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_8
ORDER BY sort_key
LIMIT 1000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('copy-width/width-8-limit-1pct', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_8
ORDER BY sort_key
LIMIT 1000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('copy-width/width-8-limit-1pct', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_8
      ORDER BY sort_key LIMIT 1000) AS s
LIMIT 1000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('copy-width/width-8-limit-1pct', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_8
ORDER BY sort_key, e1
LIMIT 1000 OFFSET 0;

-- case: pure-sort/width-8-limit-1pct
-- check: shape

-- variant: narrow
-- sample: timed
SELECT topnbench_capture('pure-sort/width-8-limit-1pct', 'narrow', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key FROM topnbench_copy_width_8
ORDER BY sort_key LIMIT 1000;

-- variant: wide
-- sample: timed
SELECT topnbench_capture('pure-sort/width-8-limit-1pct', 'wide', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key, payload FROM topnbench_copy_width_8
ORDER BY sort_key LIMIT 1000;

-- case: copy-width/width-8-limit-25pct
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('copy-width/width-8-limit-25pct', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_8
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('copy-width/width-8-limit-25pct', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_8
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('copy-width/width-8-limit-25pct', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_8
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('copy-width/width-8-limit-25pct', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_8
      ORDER BY sort_key LIMIT 25000) AS s
LIMIT 25000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('copy-width/width-8-limit-25pct', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_8
ORDER BY sort_key, e1
LIMIT 25000 OFFSET 0;

-- case: pure-sort/width-8-limit-25pct
-- check: shape

-- variant: narrow
-- sample: timed
SELECT topnbench_capture('pure-sort/width-8-limit-25pct', 'narrow', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key FROM topnbench_copy_width_8
ORDER BY sort_key LIMIT 25000;

-- variant: wide
-- sample: timed
SELECT topnbench_capture('pure-sort/width-8-limit-25pct', 'wide', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key, payload FROM topnbench_copy_width_8
ORDER BY sort_key LIMIT 25000;

-- case: copy-width/width-8-limit-50pct
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('copy-width/width-8-limit-50pct', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_8
ORDER BY sort_key
LIMIT 50000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('copy-width/width-8-limit-50pct', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_8
ORDER BY sort_key
LIMIT 50000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('copy-width/width-8-limit-50pct', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_8
ORDER BY sort_key
LIMIT 50000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('copy-width/width-8-limit-50pct', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_8
      ORDER BY sort_key LIMIT 50000) AS s
LIMIT 50000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('copy-width/width-8-limit-50pct', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_8
ORDER BY sort_key, e1
LIMIT 50000 OFFSET 0;

-- case: pure-sort/width-8-limit-50pct
-- check: shape

-- variant: narrow
-- sample: timed
SELECT topnbench_capture('pure-sort/width-8-limit-50pct', 'narrow', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key FROM topnbench_copy_width_8
ORDER BY sort_key LIMIT 50000;

-- variant: wide
-- sample: timed
SELECT topnbench_capture('pure-sort/width-8-limit-50pct', 'wide', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key, payload FROM topnbench_copy_width_8
ORDER BY sort_key LIMIT 50000;

-- case: copy-width/width-8-limit-100pct
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('copy-width/width-8-limit-100pct', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_8
ORDER BY sort_key
LIMIT 100000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('copy-width/width-8-limit-100pct', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_8
ORDER BY sort_key
LIMIT 100000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('copy-width/width-8-limit-100pct', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_8
ORDER BY sort_key
LIMIT 100000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('copy-width/width-8-limit-100pct', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_8
      ORDER BY sort_key LIMIT 100000) AS s
LIMIT 100000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('copy-width/width-8-limit-100pct', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_8
ORDER BY sort_key, e1
LIMIT 100000 OFFSET 0;

-- case: pure-sort/width-8-limit-100pct
-- check: shape

-- variant: narrow
-- sample: timed
SELECT topnbench_capture('pure-sort/width-8-limit-100pct', 'narrow', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key FROM topnbench_copy_width_8
ORDER BY sort_key LIMIT 100000;

-- variant: wide
-- sample: timed
SELECT topnbench_capture('pure-sort/width-8-limit-100pct', 'wide', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key, payload FROM topnbench_copy_width_8
ORDER BY sort_key LIMIT 100000;

-- case: copy-width/width-32-limit-1pct
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('copy-width/width-32-limit-1pct', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_32
ORDER BY sort_key
LIMIT 1000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('copy-width/width-32-limit-1pct', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_32
ORDER BY sort_key
LIMIT 1000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('copy-width/width-32-limit-1pct', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_32
ORDER BY sort_key
LIMIT 1000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('copy-width/width-32-limit-1pct', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_32
      ORDER BY sort_key LIMIT 1000) AS s
LIMIT 1000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('copy-width/width-32-limit-1pct', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_32
ORDER BY sort_key, e1
LIMIT 1000 OFFSET 0;

-- case: pure-sort/width-32-limit-1pct
-- check: shape

-- variant: narrow
-- sample: timed
SELECT topnbench_capture('pure-sort/width-32-limit-1pct', 'narrow', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key FROM topnbench_copy_width_32
ORDER BY sort_key LIMIT 1000;

-- variant: wide
-- sample: timed
SELECT topnbench_capture('pure-sort/width-32-limit-1pct', 'wide', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key, payload FROM topnbench_copy_width_32
ORDER BY sort_key LIMIT 1000;

-- case: copy-width/width-32-limit-25pct
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('copy-width/width-32-limit-25pct', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_32
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('copy-width/width-32-limit-25pct', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_32
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('copy-width/width-32-limit-25pct', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_32
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('copy-width/width-32-limit-25pct', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_32
      ORDER BY sort_key LIMIT 25000) AS s
LIMIT 25000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('copy-width/width-32-limit-25pct', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_32
ORDER BY sort_key, e1
LIMIT 25000 OFFSET 0;

-- case: pure-sort/width-32-limit-25pct
-- check: shape

-- variant: narrow
-- sample: timed
SELECT topnbench_capture('pure-sort/width-32-limit-25pct', 'narrow', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key FROM topnbench_copy_width_32
ORDER BY sort_key LIMIT 25000;

-- variant: wide
-- sample: timed
SELECT topnbench_capture('pure-sort/width-32-limit-25pct', 'wide', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key, payload FROM topnbench_copy_width_32
ORDER BY sort_key LIMIT 25000;

-- case: copy-width/width-32-limit-50pct
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('copy-width/width-32-limit-50pct', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_32
ORDER BY sort_key
LIMIT 50000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('copy-width/width-32-limit-50pct', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_32
ORDER BY sort_key
LIMIT 50000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('copy-width/width-32-limit-50pct', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_32
ORDER BY sort_key
LIMIT 50000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('copy-width/width-32-limit-50pct', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_32
      ORDER BY sort_key LIMIT 50000) AS s
LIMIT 50000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('copy-width/width-32-limit-50pct', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_32
ORDER BY sort_key, e1
LIMIT 50000 OFFSET 0;

-- case: pure-sort/width-32-limit-50pct
-- check: shape

-- variant: narrow
-- sample: timed
SELECT topnbench_capture('pure-sort/width-32-limit-50pct', 'narrow', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key FROM topnbench_copy_width_32
ORDER BY sort_key LIMIT 50000;

-- variant: wide
-- sample: timed
SELECT topnbench_capture('pure-sort/width-32-limit-50pct', 'wide', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key, payload FROM topnbench_copy_width_32
ORDER BY sort_key LIMIT 50000;

-- case: copy-width/width-32-limit-100pct
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('copy-width/width-32-limit-100pct', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_32
ORDER BY sort_key
LIMIT 100000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('copy-width/width-32-limit-100pct', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_32
ORDER BY sort_key
LIMIT 100000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('copy-width/width-32-limit-100pct', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_32
ORDER BY sort_key
LIMIT 100000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('copy-width/width-32-limit-100pct', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_32
      ORDER BY sort_key LIMIT 100000) AS s
LIMIT 100000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('copy-width/width-32-limit-100pct', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_32
ORDER BY sort_key, e1
LIMIT 100000 OFFSET 0;

-- case: pure-sort/width-32-limit-100pct
-- check: shape

-- variant: narrow
-- sample: timed
SELECT topnbench_capture('pure-sort/width-32-limit-100pct', 'narrow', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key FROM topnbench_copy_width_32
ORDER BY sort_key LIMIT 100000;

-- variant: wide
-- sample: timed
SELECT topnbench_capture('pure-sort/width-32-limit-100pct', 'wide', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key, payload FROM topnbench_copy_width_32
ORDER BY sort_key LIMIT 100000;

-- case: copy-width/width-128-limit-1pct
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('copy-width/width-128-limit-1pct', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key
LIMIT 1000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('copy-width/width-128-limit-1pct', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key
LIMIT 1000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('copy-width/width-128-limit-1pct', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key
LIMIT 1000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('copy-width/width-128-limit-1pct', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_128
      ORDER BY sort_key LIMIT 1000) AS s
LIMIT 1000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('copy-width/width-128-limit-1pct', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key, e1
LIMIT 1000 OFFSET 0;

-- case: pure-sort/width-128-limit-1pct
-- check: shape

-- variant: narrow
-- sample: timed
SELECT topnbench_capture('pure-sort/width-128-limit-1pct', 'narrow', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key FROM topnbench_copy_width_128
ORDER BY sort_key LIMIT 1000;

-- variant: wide
-- sample: timed
SELECT topnbench_capture('pure-sort/width-128-limit-1pct', 'wide', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key, payload FROM topnbench_copy_width_128
ORDER BY sort_key LIMIT 1000;

-- case: copy-width/width-128-limit-25pct
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('copy-width/width-128-limit-25pct', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('copy-width/width-128-limit-25pct', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('copy-width/width-128-limit-25pct', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('copy-width/width-128-limit-25pct', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_128
      ORDER BY sort_key LIMIT 25000) AS s
LIMIT 25000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('copy-width/width-128-limit-25pct', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key, e1
LIMIT 25000 OFFSET 0;

-- case: pure-sort/width-128-limit-25pct
-- check: shape

-- variant: narrow
-- sample: timed
SELECT topnbench_capture('pure-sort/width-128-limit-25pct', 'narrow', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key FROM topnbench_copy_width_128
ORDER BY sort_key LIMIT 25000;

-- variant: wide
-- sample: timed
SELECT topnbench_capture('pure-sort/width-128-limit-25pct', 'wide', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key, payload FROM topnbench_copy_width_128
ORDER BY sort_key LIMIT 25000;

-- case: copy-width/width-128-limit-50pct
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('copy-width/width-128-limit-50pct', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key
LIMIT 50000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('copy-width/width-128-limit-50pct', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key
LIMIT 50000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('copy-width/width-128-limit-50pct', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key
LIMIT 50000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('copy-width/width-128-limit-50pct', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_128
      ORDER BY sort_key LIMIT 50000) AS s
LIMIT 50000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('copy-width/width-128-limit-50pct', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key, e1
LIMIT 50000 OFFSET 0;

-- case: pure-sort/width-128-limit-50pct
-- check: shape

-- variant: narrow
-- sample: timed
SELECT topnbench_capture('pure-sort/width-128-limit-50pct', 'narrow', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key FROM topnbench_copy_width_128
ORDER BY sort_key LIMIT 50000;

-- variant: wide
-- sample: timed
SELECT topnbench_capture('pure-sort/width-128-limit-50pct', 'wide', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key, payload FROM topnbench_copy_width_128
ORDER BY sort_key LIMIT 50000;

-- case: copy-width/width-128-limit-100pct
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('copy-width/width-128-limit-100pct', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key
LIMIT 100000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('copy-width/width-128-limit-100pct', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key
LIMIT 100000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('copy-width/width-128-limit-100pct', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key
LIMIT 100000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('copy-width/width-128-limit-100pct', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_128
      ORDER BY sort_key LIMIT 100000) AS s
LIMIT 100000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('copy-width/width-128-limit-100pct', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key, e1
LIMIT 100000 OFFSET 0;

-- case: pure-sort/width-128-limit-100pct
-- check: shape

-- variant: narrow
-- sample: timed
SELECT topnbench_capture('pure-sort/width-128-limit-100pct', 'narrow', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key FROM topnbench_copy_width_128
ORDER BY sort_key LIMIT 100000;

-- variant: wide
-- sample: timed
SELECT topnbench_capture('pure-sort/width-128-limit-100pct', 'wide', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key, payload FROM topnbench_copy_width_128
ORDER BY sort_key LIMIT 100000;

-- case: copy-width/width-256-limit-1pct
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('copy-width/width-256-limit-1pct', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_256
ORDER BY sort_key
LIMIT 1000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('copy-width/width-256-limit-1pct', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_256
ORDER BY sort_key
LIMIT 1000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('copy-width/width-256-limit-1pct', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_256
ORDER BY sort_key
LIMIT 1000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('copy-width/width-256-limit-1pct', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_256
      ORDER BY sort_key LIMIT 1000) AS s
LIMIT 1000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('copy-width/width-256-limit-1pct', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_256
ORDER BY sort_key, e1
LIMIT 1000 OFFSET 0;

-- case: pure-sort/width-256-limit-1pct
-- check: shape

-- variant: narrow
-- sample: timed
SELECT topnbench_capture('pure-sort/width-256-limit-1pct', 'narrow', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key FROM topnbench_copy_width_256
ORDER BY sort_key LIMIT 1000;

-- variant: wide
-- sample: timed
SELECT topnbench_capture('pure-sort/width-256-limit-1pct', 'wide', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key, payload FROM topnbench_copy_width_256
ORDER BY sort_key LIMIT 1000;

-- case: copy-width/width-256-limit-25pct
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('copy-width/width-256-limit-25pct', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_256
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('copy-width/width-256-limit-25pct', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_256
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('copy-width/width-256-limit-25pct', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_256
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('copy-width/width-256-limit-25pct', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_256
      ORDER BY sort_key LIMIT 25000) AS s
LIMIT 25000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('copy-width/width-256-limit-25pct', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_256
ORDER BY sort_key, e1
LIMIT 25000 OFFSET 0;

-- case: pure-sort/width-256-limit-25pct
-- check: shape

-- variant: narrow
-- sample: timed
SELECT topnbench_capture('pure-sort/width-256-limit-25pct', 'narrow', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key FROM topnbench_copy_width_256
ORDER BY sort_key LIMIT 25000;

-- variant: wide
-- sample: timed
SELECT topnbench_capture('pure-sort/width-256-limit-25pct', 'wide', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key, payload FROM topnbench_copy_width_256
ORDER BY sort_key LIMIT 25000;

-- case: copy-width/width-256-limit-50pct
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('copy-width/width-256-limit-50pct', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_256
ORDER BY sort_key
LIMIT 50000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('copy-width/width-256-limit-50pct', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_256
ORDER BY sort_key
LIMIT 50000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('copy-width/width-256-limit-50pct', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_256
ORDER BY sort_key
LIMIT 50000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('copy-width/width-256-limit-50pct', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_256
      ORDER BY sort_key LIMIT 50000) AS s
LIMIT 50000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('copy-width/width-256-limit-50pct', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_256
ORDER BY sort_key, e1
LIMIT 50000 OFFSET 0;

-- case: pure-sort/width-256-limit-50pct
-- check: shape

-- variant: narrow
-- sample: timed
SELECT topnbench_capture('pure-sort/width-256-limit-50pct', 'narrow', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key FROM topnbench_copy_width_256
ORDER BY sort_key LIMIT 50000;

-- variant: wide
-- sample: timed
SELECT topnbench_capture('pure-sort/width-256-limit-50pct', 'wide', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key, payload FROM topnbench_copy_width_256
ORDER BY sort_key LIMIT 50000;

-- case: copy-width/width-256-limit-100pct
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('copy-width/width-256-limit-100pct', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_256
ORDER BY sort_key
LIMIT 100000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('copy-width/width-256-limit-100pct', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_256
ORDER BY sort_key
LIMIT 100000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('copy-width/width-256-limit-100pct', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_256
ORDER BY sort_key
LIMIT 100000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('copy-width/width-256-limit-100pct', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_256
      ORDER BY sort_key LIMIT 100000) AS s
LIMIT 100000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('copy-width/width-256-limit-100pct', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_256
ORDER BY sort_key, e1
LIMIT 100000 OFFSET 0;

-- case: pure-sort/width-256-limit-100pct
-- check: shape

-- variant: narrow
-- sample: timed
SELECT topnbench_capture('pure-sort/width-256-limit-100pct', 'narrow', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key FROM topnbench_copy_width_256
ORDER BY sort_key LIMIT 100000;

-- variant: wide
-- sample: timed
SELECT topnbench_capture('pure-sort/width-256-limit-100pct', 'wide', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key, payload FROM topnbench_copy_width_256
ORDER BY sort_key LIMIT 100000;

-- case: copy-width/width-512-limit-1pct
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('copy-width/width-512-limit-1pct', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_512
ORDER BY sort_key
LIMIT 1000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('copy-width/width-512-limit-1pct', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_512
ORDER BY sort_key
LIMIT 1000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('copy-width/width-512-limit-1pct', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_512
ORDER BY sort_key
LIMIT 1000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('copy-width/width-512-limit-1pct', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_512
      ORDER BY sort_key LIMIT 1000) AS s
LIMIT 1000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('copy-width/width-512-limit-1pct', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_512
ORDER BY sort_key, e1
LIMIT 1000 OFFSET 0;

-- case: pure-sort/width-512-limit-1pct
-- check: shape

-- variant: narrow
-- sample: timed
SELECT topnbench_capture('pure-sort/width-512-limit-1pct', 'narrow', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key FROM topnbench_copy_width_512
ORDER BY sort_key LIMIT 1000;

-- variant: wide
-- sample: timed
SELECT topnbench_capture('pure-sort/width-512-limit-1pct', 'wide', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key, payload FROM topnbench_copy_width_512
ORDER BY sort_key LIMIT 1000;

-- case: copy-width/width-512-limit-25pct
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('copy-width/width-512-limit-25pct', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_512
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('copy-width/width-512-limit-25pct', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_512
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('copy-width/width-512-limit-25pct', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_512
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('copy-width/width-512-limit-25pct', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_512
      ORDER BY sort_key LIMIT 25000) AS s
LIMIT 25000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('copy-width/width-512-limit-25pct', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_512
ORDER BY sort_key, e1
LIMIT 25000 OFFSET 0;

-- case: pure-sort/width-512-limit-25pct
-- check: shape

-- variant: narrow
-- sample: timed
SELECT topnbench_capture('pure-sort/width-512-limit-25pct', 'narrow', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key FROM topnbench_copy_width_512
ORDER BY sort_key LIMIT 25000;

-- variant: wide
-- sample: timed
SELECT topnbench_capture('pure-sort/width-512-limit-25pct', 'wide', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key, payload FROM topnbench_copy_width_512
ORDER BY sort_key LIMIT 25000;

-- case: copy-width/width-512-limit-50pct
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('copy-width/width-512-limit-50pct', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_512
ORDER BY sort_key
LIMIT 50000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('copy-width/width-512-limit-50pct', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_512
ORDER BY sort_key
LIMIT 50000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('copy-width/width-512-limit-50pct', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_512
ORDER BY sort_key
LIMIT 50000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('copy-width/width-512-limit-50pct', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_512
      ORDER BY sort_key LIMIT 50000) AS s
LIMIT 50000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('copy-width/width-512-limit-50pct', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_512
ORDER BY sort_key, e1
LIMIT 50000 OFFSET 0;

-- case: pure-sort/width-512-limit-50pct
-- check: shape

-- variant: narrow
-- sample: timed
SELECT topnbench_capture('pure-sort/width-512-limit-50pct', 'narrow', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key FROM topnbench_copy_width_512
ORDER BY sort_key LIMIT 50000;

-- variant: wide
-- sample: timed
SELECT topnbench_capture('pure-sort/width-512-limit-50pct', 'wide', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key, payload FROM topnbench_copy_width_512
ORDER BY sort_key LIMIT 50000;

-- case: copy-width/width-512-limit-100pct
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('copy-width/width-512-limit-100pct', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_512
ORDER BY sort_key
LIMIT 100000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('copy-width/width-512-limit-100pct', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_512
ORDER BY sort_key
LIMIT 100000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('copy-width/width-512-limit-100pct', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_512
ORDER BY sort_key
LIMIT 100000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('copy-width/width-512-limit-100pct', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_512
      ORDER BY sort_key LIMIT 100000) AS s
LIMIT 100000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('copy-width/width-512-limit-100pct', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_512
ORDER BY sort_key, e1
LIMIT 100000 OFFSET 0;

-- case: pure-sort/width-512-limit-100pct
-- check: shape

-- variant: narrow
-- sample: timed
SELECT topnbench_capture('pure-sort/width-512-limit-100pct', 'narrow', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key FROM topnbench_copy_width_512
ORDER BY sort_key LIMIT 100000;

-- variant: wide
-- sample: timed
SELECT topnbench_capture('pure-sort/width-512-limit-100pct', 'wide', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key, payload FROM topnbench_copy_width_512
ORDER BY sort_key LIMIT 100000;

-- case: copy-width/width-1024-limit-1pct
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('copy-width/width-1024-limit-1pct', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_1024
ORDER BY sort_key
LIMIT 1000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('copy-width/width-1024-limit-1pct', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_1024
ORDER BY sort_key
LIMIT 1000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('copy-width/width-1024-limit-1pct', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_1024
ORDER BY sort_key
LIMIT 1000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('copy-width/width-1024-limit-1pct', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_1024
      ORDER BY sort_key LIMIT 1000) AS s
LIMIT 1000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('copy-width/width-1024-limit-1pct', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_1024
ORDER BY sort_key, e1
LIMIT 1000 OFFSET 0;

-- case: pure-sort/width-1024-limit-1pct
-- check: shape

-- variant: narrow
-- sample: timed
SELECT topnbench_capture('pure-sort/width-1024-limit-1pct', 'narrow', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key FROM topnbench_copy_width_1024
ORDER BY sort_key LIMIT 1000;

-- variant: wide
-- sample: timed
SELECT topnbench_capture('pure-sort/width-1024-limit-1pct', 'wide', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key, payload FROM topnbench_copy_width_1024
ORDER BY sort_key LIMIT 1000;

-- case: copy-width/width-1024-limit-25pct
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('copy-width/width-1024-limit-25pct', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_1024
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('copy-width/width-1024-limit-25pct', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_1024
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('copy-width/width-1024-limit-25pct', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_1024
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('copy-width/width-1024-limit-25pct', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_1024
      ORDER BY sort_key LIMIT 25000) AS s
LIMIT 25000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('copy-width/width-1024-limit-25pct', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_1024
ORDER BY sort_key, e1
LIMIT 25000 OFFSET 0;

-- case: pure-sort/width-1024-limit-25pct
-- check: shape

-- variant: narrow
-- sample: timed
SELECT topnbench_capture('pure-sort/width-1024-limit-25pct', 'narrow', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key FROM topnbench_copy_width_1024
ORDER BY sort_key LIMIT 25000;

-- variant: wide
-- sample: timed
SELECT topnbench_capture('pure-sort/width-1024-limit-25pct', 'wide', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key, payload FROM topnbench_copy_width_1024
ORDER BY sort_key LIMIT 25000;

-- case: copy-width/width-1024-limit-50pct
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('copy-width/width-1024-limit-50pct', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_1024
ORDER BY sort_key
LIMIT 50000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('copy-width/width-1024-limit-50pct', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_1024
ORDER BY sort_key
LIMIT 50000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('copy-width/width-1024-limit-50pct', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_1024
ORDER BY sort_key
LIMIT 50000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('copy-width/width-1024-limit-50pct', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_1024
      ORDER BY sort_key LIMIT 50000) AS s
LIMIT 50000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('copy-width/width-1024-limit-50pct', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_1024
ORDER BY sort_key, e1
LIMIT 50000 OFFSET 0;

-- case: pure-sort/width-1024-limit-50pct
-- check: shape

-- variant: narrow
-- sample: timed
SELECT topnbench_capture('pure-sort/width-1024-limit-50pct', 'narrow', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key FROM topnbench_copy_width_1024
ORDER BY sort_key LIMIT 50000;

-- variant: wide
-- sample: timed
SELECT topnbench_capture('pure-sort/width-1024-limit-50pct', 'wide', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key, payload FROM topnbench_copy_width_1024
ORDER BY sort_key LIMIT 50000;

-- case: copy-width/width-1024-limit-100pct
-- check: equivalent

-- variant: upstream-auto
-- sample: plan
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('copy-width/width-1024-limit-100pct', 'upstream-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_1024
ORDER BY sort_key
LIMIT 100000 OFFSET 0;

-- variant: path-only-auto
-- sample: plan
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('copy-width/width-1024-limit-100pct', 'path-only-auto', 'equivalent', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_1024
ORDER BY sort_key
LIMIT 100000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('copy-width/width-1024-limit-100pct', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_1024
ORDER BY sort_key
LIMIT 100000 OFFSET 0;

-- variant: manual-late
-- sample: timed
SELECT topnbench_capture('copy-width/width-1024-limit-100pct', 'manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_1024
      ORDER BY sort_key LIMIT 100000) AS s
LIMIT 100000 OFFSET 0;

-- variant: forced-early
-- sample: timed
SELECT topnbench_capture('copy-width/width-1024-limit-100pct', 'forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_1024
ORDER BY sort_key, e1
LIMIT 100000 OFFSET 0;

-- case: pure-sort/width-1024-limit-100pct
-- check: shape

-- variant: narrow
-- sample: timed
SELECT topnbench_capture('pure-sort/width-1024-limit-100pct', 'narrow', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key FROM topnbench_copy_width_1024
ORDER BY sort_key LIMIT 100000;

-- variant: wide
-- sample: timed
SELECT topnbench_capture('pure-sort/width-1024-limit-100pct', 'wide', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key, payload FROM topnbench_copy_width_1024
ORDER BY sort_key LIMIT 100000;

-- case: final-cost/width-96-limit-25pct
-- check: equivalent
SET work_mem = '64MB';

-- variant: total-off/auto
-- sample: timed
SET enable_projection_total_cost = off;
SELECT topnbench_capture('final-cost/width-96-limit-25pct', 'total-off/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_96
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: total-off/manual-late
-- sample: timed
SELECT topnbench_capture('final-cost/width-96-limit-25pct', 'total-off/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_96
      ORDER BY sort_key LIMIT 25000) AS s
ORDER BY s.k
LIMIT 25000 OFFSET 0;

-- variant: total-off/forced-early
-- sample: timed
SELECT topnbench_capture('final-cost/width-96-limit-25pct', 'total-off/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_96
ORDER BY sort_key, e1
LIMIT 25000 OFFSET 0;

-- variant: total-on/auto
-- sample: timed
SET enable_projection_total_cost = on;
SELECT topnbench_capture('final-cost/width-96-limit-25pct', 'total-on/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_96
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: total-on/manual-late
-- sample: timed
SELECT topnbench_capture('final-cost/width-96-limit-25pct', 'total-on/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_96
      ORDER BY sort_key LIMIT 25000) AS s
ORDER BY s.k
LIMIT 25000 OFFSET 0;

-- variant: total-on/forced-early
-- sample: timed
SELECT topnbench_capture('final-cost/width-96-limit-25pct', 'total-on/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_96
ORDER BY sort_key, e1
LIMIT 25000 OFFSET 0;

-- case: datum-cost/width-96-limit-25pct
-- check: equivalent

-- variant: datum-off/auto
-- sample: timed
SET enable_sort_datum_cost = off;
SELECT topnbench_capture('datum-cost/width-96-limit-25pct', 'datum-off/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_96
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: datum-off/manual-late
-- sample: timed
SELECT topnbench_capture('datum-cost/width-96-limit-25pct', 'datum-off/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_96
      ORDER BY sort_key LIMIT 25000) AS s
ORDER BY s.k
LIMIT 25000 OFFSET 0;

-- variant: datum-off/forced-early
-- sample: timed
SELECT topnbench_capture('datum-cost/width-96-limit-25pct', 'datum-off/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_96
ORDER BY sort_key, e1
LIMIT 25000 OFFSET 0;

-- variant: datum-on/auto
-- sample: timed
SET enable_sort_datum_cost = on;
SELECT topnbench_capture('datum-cost/width-96-limit-25pct', 'datum-on/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_96
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: datum-on/manual-late
-- sample: timed
SELECT topnbench_capture('datum-cost/width-96-limit-25pct', 'datum-on/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_96
      ORDER BY sort_key LIMIT 25000) AS s
ORDER BY s.k
LIMIT 25000 OFFSET 0;

-- variant: datum-on/forced-early
-- sample: timed
SELECT topnbench_capture('datum-cost/width-96-limit-25pct', 'datum-on/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_96
ORDER BY sort_key, e1
LIMIT 25000 OFFSET 0;

-- case: final-cost/width-128-limit-25pct
-- check: equivalent

-- variant: total-off/auto
-- sample: timed
SET enable_projection_total_cost = off;
SELECT topnbench_capture('final-cost/width-128-limit-25pct', 'total-off/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: total-off/manual-late
-- sample: timed
SELECT topnbench_capture('final-cost/width-128-limit-25pct', 'total-off/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_128
      ORDER BY sort_key LIMIT 25000) AS s
ORDER BY s.k
LIMIT 25000 OFFSET 0;

-- variant: total-off/forced-early
-- sample: timed
SELECT topnbench_capture('final-cost/width-128-limit-25pct', 'total-off/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key, e1
LIMIT 25000 OFFSET 0;

-- variant: total-on/auto
-- sample: timed
SET enable_projection_total_cost = on;
SELECT topnbench_capture('final-cost/width-128-limit-25pct', 'total-on/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: total-on/manual-late
-- sample: timed
SELECT topnbench_capture('final-cost/width-128-limit-25pct', 'total-on/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_128
      ORDER BY sort_key LIMIT 25000) AS s
ORDER BY s.k
LIMIT 25000 OFFSET 0;

-- variant: total-on/forced-early
-- sample: timed
SELECT topnbench_capture('final-cost/width-128-limit-25pct', 'total-on/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key, e1
LIMIT 25000 OFFSET 0;

-- case: datum-cost/width-128-limit-25pct
-- check: equivalent

-- variant: datum-off/auto
-- sample: timed
SET enable_sort_datum_cost = off;
SELECT topnbench_capture('datum-cost/width-128-limit-25pct', 'datum-off/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: datum-off/manual-late
-- sample: timed
SELECT topnbench_capture('datum-cost/width-128-limit-25pct', 'datum-off/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_128
      ORDER BY sort_key LIMIT 25000) AS s
ORDER BY s.k
LIMIT 25000 OFFSET 0;

-- variant: datum-off/forced-early
-- sample: timed
SELECT topnbench_capture('datum-cost/width-128-limit-25pct', 'datum-off/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key, e1
LIMIT 25000 OFFSET 0;

-- variant: datum-on/auto
-- sample: timed
SET enable_sort_datum_cost = on;
SELECT topnbench_capture('datum-cost/width-128-limit-25pct', 'datum-on/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: datum-on/manual-late
-- sample: timed
SELECT topnbench_capture('datum-cost/width-128-limit-25pct', 'datum-on/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_128
      ORDER BY sort_key LIMIT 25000) AS s
ORDER BY s.k
LIMIT 25000 OFFSET 0;

-- variant: datum-on/forced-early
-- sample: timed
SELECT topnbench_capture('datum-cost/width-128-limit-25pct', 'datum-on/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key, e1
LIMIT 25000 OFFSET 0;

-- case: final-cost/width-160-limit-25pct
-- check: equivalent

-- variant: total-off/auto
-- sample: timed
SET enable_projection_total_cost = off;
SELECT topnbench_capture('final-cost/width-160-limit-25pct', 'total-off/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_160
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: total-off/manual-late
-- sample: timed
SELECT topnbench_capture('final-cost/width-160-limit-25pct', 'total-off/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_160
      ORDER BY sort_key LIMIT 25000) AS s
ORDER BY s.k
LIMIT 25000 OFFSET 0;

-- variant: total-off/forced-early
-- sample: timed
SELECT topnbench_capture('final-cost/width-160-limit-25pct', 'total-off/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_160
ORDER BY sort_key, e1
LIMIT 25000 OFFSET 0;

-- variant: total-on/auto
-- sample: timed
SET enable_projection_total_cost = on;
SELECT topnbench_capture('final-cost/width-160-limit-25pct', 'total-on/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_160
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: total-on/manual-late
-- sample: timed
SELECT topnbench_capture('final-cost/width-160-limit-25pct', 'total-on/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_160
      ORDER BY sort_key LIMIT 25000) AS s
ORDER BY s.k
LIMIT 25000 OFFSET 0;

-- variant: total-on/forced-early
-- sample: timed
SELECT topnbench_capture('final-cost/width-160-limit-25pct', 'total-on/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_160
ORDER BY sort_key, e1
LIMIT 25000 OFFSET 0;

-- case: datum-cost/width-160-limit-25pct
-- check: equivalent

-- variant: datum-off/auto
-- sample: timed
SET enable_sort_datum_cost = off;
SELECT topnbench_capture('datum-cost/width-160-limit-25pct', 'datum-off/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_160
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: datum-off/manual-late
-- sample: timed
SELECT topnbench_capture('datum-cost/width-160-limit-25pct', 'datum-off/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_160
      ORDER BY sort_key LIMIT 25000) AS s
ORDER BY s.k
LIMIT 25000 OFFSET 0;

-- variant: datum-off/forced-early
-- sample: timed
SELECT topnbench_capture('datum-cost/width-160-limit-25pct', 'datum-off/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_160
ORDER BY sort_key, e1
LIMIT 25000 OFFSET 0;

-- variant: datum-on/auto
-- sample: timed
SET enable_sort_datum_cost = on;
SELECT topnbench_capture('datum-cost/width-160-limit-25pct', 'datum-on/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_160
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: datum-on/manual-late
-- sample: timed
SELECT topnbench_capture('datum-cost/width-160-limit-25pct', 'datum-on/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_160
      ORDER BY sort_key LIMIT 25000) AS s
ORDER BY s.k
LIMIT 25000 OFFSET 0;

-- variant: datum-on/forced-early
-- sample: timed
SELECT topnbench_capture('datum-cost/width-160-limit-25pct', 'datum-on/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_160
ORDER BY sort_key, e1
LIMIT 25000 OFFSET 0;

-- case: final-cost/width-192-limit-25pct
-- check: equivalent

-- variant: total-off/auto
-- sample: timed
SET enable_projection_total_cost = off;
SELECT topnbench_capture('final-cost/width-192-limit-25pct', 'total-off/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_192
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: total-off/manual-late
-- sample: timed
SELECT topnbench_capture('final-cost/width-192-limit-25pct', 'total-off/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_192
      ORDER BY sort_key LIMIT 25000) AS s
ORDER BY s.k
LIMIT 25000 OFFSET 0;

-- variant: total-off/forced-early
-- sample: timed
SELECT topnbench_capture('final-cost/width-192-limit-25pct', 'total-off/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_192
ORDER BY sort_key, e1
LIMIT 25000 OFFSET 0;

-- variant: total-on/auto
-- sample: timed
SET enable_projection_total_cost = on;
SELECT topnbench_capture('final-cost/width-192-limit-25pct', 'total-on/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_192
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: total-on/manual-late
-- sample: timed
SELECT topnbench_capture('final-cost/width-192-limit-25pct', 'total-on/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_192
      ORDER BY sort_key LIMIT 25000) AS s
ORDER BY s.k
LIMIT 25000 OFFSET 0;

-- variant: total-on/forced-early
-- sample: timed
SELECT topnbench_capture('final-cost/width-192-limit-25pct', 'total-on/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_192
ORDER BY sort_key, e1
LIMIT 25000 OFFSET 0;

-- case: datum-cost/width-192-limit-25pct
-- check: equivalent

-- variant: datum-off/auto
-- sample: timed
SET enable_sort_datum_cost = off;
SELECT topnbench_capture('datum-cost/width-192-limit-25pct', 'datum-off/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_192
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: datum-off/manual-late
-- sample: timed
SELECT topnbench_capture('datum-cost/width-192-limit-25pct', 'datum-off/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_192
      ORDER BY sort_key LIMIT 25000) AS s
ORDER BY s.k
LIMIT 25000 OFFSET 0;

-- variant: datum-off/forced-early
-- sample: timed
SELECT topnbench_capture('datum-cost/width-192-limit-25pct', 'datum-off/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_192
ORDER BY sort_key, e1
LIMIT 25000 OFFSET 0;

-- variant: datum-on/auto
-- sample: timed
SET enable_sort_datum_cost = on;
SELECT topnbench_capture('datum-cost/width-192-limit-25pct', 'datum-on/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_192
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: datum-on/manual-late
-- sample: timed
SELECT topnbench_capture('datum-cost/width-192-limit-25pct', 'datum-on/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_192
      ORDER BY sort_key LIMIT 25000) AS s
ORDER BY s.k
LIMIT 25000 OFFSET 0;

-- variant: datum-on/forced-early
-- sample: timed
SELECT topnbench_capture('datum-cost/width-192-limit-25pct', 'datum-on/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_192
ORDER BY sort_key, e1
LIMIT 25000 OFFSET 0;

-- case: final-cost/width-256-limit-25pct
-- check: equivalent

-- variant: total-off/auto
-- sample: timed
SET enable_projection_total_cost = off;
SELECT topnbench_capture('final-cost/width-256-limit-25pct', 'total-off/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_256
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: total-off/manual-late
-- sample: timed
SELECT topnbench_capture('final-cost/width-256-limit-25pct', 'total-off/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_256
      ORDER BY sort_key LIMIT 25000) AS s
ORDER BY s.k
LIMIT 25000 OFFSET 0;

-- variant: total-off/forced-early
-- sample: timed
SELECT topnbench_capture('final-cost/width-256-limit-25pct', 'total-off/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_256
ORDER BY sort_key, e1
LIMIT 25000 OFFSET 0;

-- variant: total-on/auto
-- sample: timed
SET enable_projection_total_cost = on;
SELECT topnbench_capture('final-cost/width-256-limit-25pct', 'total-on/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_256
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: total-on/manual-late
-- sample: timed
SELECT topnbench_capture('final-cost/width-256-limit-25pct', 'total-on/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_256
      ORDER BY sort_key LIMIT 25000) AS s
ORDER BY s.k
LIMIT 25000 OFFSET 0;

-- variant: total-on/forced-early
-- sample: timed
SELECT topnbench_capture('final-cost/width-256-limit-25pct', 'total-on/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_256
ORDER BY sort_key, e1
LIMIT 25000 OFFSET 0;

-- case: datum-cost/width-256-limit-25pct
-- check: equivalent

-- variant: datum-off/auto
-- sample: timed
SET enable_sort_datum_cost = off;
SELECT topnbench_capture('datum-cost/width-256-limit-25pct', 'datum-off/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_256
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: datum-off/manual-late
-- sample: timed
SELECT topnbench_capture('datum-cost/width-256-limit-25pct', 'datum-off/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_256
      ORDER BY sort_key LIMIT 25000) AS s
ORDER BY s.k
LIMIT 25000 OFFSET 0;

-- variant: datum-off/forced-early
-- sample: timed
SELECT topnbench_capture('datum-cost/width-256-limit-25pct', 'datum-off/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_256
ORDER BY sort_key, e1
LIMIT 25000 OFFSET 0;

-- variant: datum-on/auto
-- sample: timed
SET enable_sort_datum_cost = on;
SELECT topnbench_capture('datum-cost/width-256-limit-25pct', 'datum-on/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_256
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: datum-on/manual-late
-- sample: timed
SELECT topnbench_capture('datum-cost/width-256-limit-25pct', 'datum-on/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_256
      ORDER BY sort_key LIMIT 25000) AS s
ORDER BY s.k
LIMIT 25000 OFFSET 0;

-- variant: datum-on/forced-early
-- sample: timed
SELECT topnbench_capture('datum-cost/width-256-limit-25pct', 'datum-on/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_256
ORDER BY sort_key, e1
LIMIT 25000 OFFSET 0;

-- case: final-cost/width-128-limit-20pct
-- check: equivalent

-- variant: total-off/auto
-- sample: timed
SET enable_projection_total_cost = off;
SELECT topnbench_capture('final-cost/width-128-limit-20pct', 'total-off/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key
LIMIT 20000 OFFSET 0;

-- variant: total-off/manual-late
-- sample: timed
SELECT topnbench_capture('final-cost/width-128-limit-20pct', 'total-off/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_128
      ORDER BY sort_key LIMIT 20000) AS s
ORDER BY s.k
LIMIT 20000 OFFSET 0;

-- variant: total-off/forced-early
-- sample: timed
SELECT topnbench_capture('final-cost/width-128-limit-20pct', 'total-off/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key, e1
LIMIT 20000 OFFSET 0;

-- variant: total-on/auto
-- sample: timed
SET enable_projection_total_cost = on;
SELECT topnbench_capture('final-cost/width-128-limit-20pct', 'total-on/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key
LIMIT 20000 OFFSET 0;

-- variant: total-on/manual-late
-- sample: timed
SELECT topnbench_capture('final-cost/width-128-limit-20pct', 'total-on/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_128
      ORDER BY sort_key LIMIT 20000) AS s
ORDER BY s.k
LIMIT 20000 OFFSET 0;

-- variant: total-on/forced-early
-- sample: timed
SELECT topnbench_capture('final-cost/width-128-limit-20pct', 'total-on/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key, e1
LIMIT 20000 OFFSET 0;

-- case: datum-cost/width-128-limit-20pct
-- check: equivalent

-- variant: datum-off/auto
-- sample: timed
SET enable_sort_datum_cost = off;
SELECT topnbench_capture('datum-cost/width-128-limit-20pct', 'datum-off/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key
LIMIT 20000 OFFSET 0;

-- variant: datum-off/manual-late
-- sample: timed
SELECT topnbench_capture('datum-cost/width-128-limit-20pct', 'datum-off/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_128
      ORDER BY sort_key LIMIT 20000) AS s
ORDER BY s.k
LIMIT 20000 OFFSET 0;

-- variant: datum-off/forced-early
-- sample: timed
SELECT topnbench_capture('datum-cost/width-128-limit-20pct', 'datum-off/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key, e1
LIMIT 20000 OFFSET 0;

-- variant: datum-on/auto
-- sample: timed
SET enable_sort_datum_cost = on;
SELECT topnbench_capture('datum-cost/width-128-limit-20pct', 'datum-on/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key
LIMIT 20000 OFFSET 0;

-- variant: datum-on/manual-late
-- sample: timed
SELECT topnbench_capture('datum-cost/width-128-limit-20pct', 'datum-on/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_128
      ORDER BY sort_key LIMIT 20000) AS s
ORDER BY s.k
LIMIT 20000 OFFSET 0;

-- variant: datum-on/forced-early
-- sample: timed
SELECT topnbench_capture('datum-cost/width-128-limit-20pct', 'datum-on/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key, e1
LIMIT 20000 OFFSET 0;

-- case: final-cost/width-128-limit-30pct
-- check: equivalent

-- variant: total-off/auto
-- sample: timed
SET enable_projection_total_cost = off;
SELECT topnbench_capture('final-cost/width-128-limit-30pct', 'total-off/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key
LIMIT 30000 OFFSET 0;

-- variant: total-off/manual-late
-- sample: timed
SELECT topnbench_capture('final-cost/width-128-limit-30pct', 'total-off/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_128
      ORDER BY sort_key LIMIT 30000) AS s
ORDER BY s.k
LIMIT 30000 OFFSET 0;

-- variant: total-off/forced-early
-- sample: timed
SELECT topnbench_capture('final-cost/width-128-limit-30pct', 'total-off/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key, e1
LIMIT 30000 OFFSET 0;

-- variant: total-on/auto
-- sample: timed
SET enable_projection_total_cost = on;
SELECT topnbench_capture('final-cost/width-128-limit-30pct', 'total-on/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key
LIMIT 30000 OFFSET 0;

-- variant: total-on/manual-late
-- sample: timed
SELECT topnbench_capture('final-cost/width-128-limit-30pct', 'total-on/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_128
      ORDER BY sort_key LIMIT 30000) AS s
ORDER BY s.k
LIMIT 30000 OFFSET 0;

-- variant: total-on/forced-early
-- sample: timed
SELECT topnbench_capture('final-cost/width-128-limit-30pct', 'total-on/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key, e1
LIMIT 30000 OFFSET 0;

-- case: datum-cost/width-128-limit-30pct
-- check: equivalent

-- variant: datum-off/auto
-- sample: timed
SET enable_sort_datum_cost = off;
SELECT topnbench_capture('datum-cost/width-128-limit-30pct', 'datum-off/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key
LIMIT 30000 OFFSET 0;

-- variant: datum-off/manual-late
-- sample: timed
SELECT topnbench_capture('datum-cost/width-128-limit-30pct', 'datum-off/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_128
      ORDER BY sort_key LIMIT 30000) AS s
ORDER BY s.k
LIMIT 30000 OFFSET 0;

-- variant: datum-off/forced-early
-- sample: timed
SELECT topnbench_capture('datum-cost/width-128-limit-30pct', 'datum-off/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key, e1
LIMIT 30000 OFFSET 0;

-- variant: datum-on/auto
-- sample: timed
SET enable_sort_datum_cost = on;
SELECT topnbench_capture('datum-cost/width-128-limit-30pct', 'datum-on/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key
LIMIT 30000 OFFSET 0;

-- variant: datum-on/manual-late
-- sample: timed
SELECT topnbench_capture('datum-cost/width-128-limit-30pct', 'datum-on/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_128
      ORDER BY sort_key LIMIT 30000) AS s
ORDER BY s.k
LIMIT 30000 OFFSET 0;

-- variant: datum-on/forced-early
-- sample: timed
SELECT topnbench_capture('datum-cost/width-128-limit-30pct', 'datum-on/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key, e1
LIMIT 30000 OFFSET 0;

-- case: final-cost/offset-half-of-25pct
-- check: equivalent

-- variant: total-off/auto
-- sample: timed
SET enable_projection_total_cost = off;
SELECT topnbench_capture('final-cost/offset-half-of-25pct', 'total-off/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key
LIMIT 12500 OFFSET 12500;

-- variant: total-off/manual-late
-- sample: timed
SELECT topnbench_capture('final-cost/offset-half-of-25pct', 'total-off/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_128
      ORDER BY sort_key LIMIT 25000) AS s
ORDER BY s.k
LIMIT 12500 OFFSET 12500;

-- variant: total-off/forced-early
-- sample: timed
SELECT topnbench_capture('final-cost/offset-half-of-25pct', 'total-off/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key, e1
LIMIT 12500 OFFSET 12500;

-- variant: total-on/auto
-- sample: timed
SET enable_projection_total_cost = on;
SELECT topnbench_capture('final-cost/offset-half-of-25pct', 'total-on/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key
LIMIT 12500 OFFSET 12500;

-- variant: total-on/manual-late
-- sample: timed
SELECT topnbench_capture('final-cost/offset-half-of-25pct', 'total-on/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_128
      ORDER BY sort_key LIMIT 25000) AS s
ORDER BY s.k
LIMIT 12500 OFFSET 12500;

-- variant: total-on/forced-early
-- sample: timed
SELECT topnbench_capture('final-cost/offset-half-of-25pct', 'total-on/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key, e1
LIMIT 12500 OFFSET 12500;

-- case: datum-cost/offset-half-of-25pct
-- check: equivalent

-- variant: datum-off/auto
-- sample: timed
SET enable_sort_datum_cost = off;
SELECT topnbench_capture('datum-cost/offset-half-of-25pct', 'datum-off/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key
LIMIT 12500 OFFSET 12500;

-- variant: datum-off/manual-late
-- sample: timed
SELECT topnbench_capture('datum-cost/offset-half-of-25pct', 'datum-off/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_128
      ORDER BY sort_key LIMIT 25000) AS s
ORDER BY s.k
LIMIT 12500 OFFSET 12500;

-- variant: datum-off/forced-early
-- sample: timed
SELECT topnbench_capture('datum-cost/offset-half-of-25pct', 'datum-off/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key, e1
LIMIT 12500 OFFSET 12500;

-- variant: datum-on/auto
-- sample: timed
SET enable_sort_datum_cost = on;
SELECT topnbench_capture('datum-cost/offset-half-of-25pct', 'datum-on/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key
LIMIT 12500 OFFSET 12500;

-- variant: datum-on/manual-late
-- sample: timed
SELECT topnbench_capture('datum-cost/offset-half-of-25pct', 'datum-on/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_128
      ORDER BY sort_key LIMIT 25000) AS s
ORDER BY s.k
LIMIT 12500 OFFSET 12500;

-- variant: datum-on/forced-early
-- sample: timed
SELECT topnbench_capture('datum-cost/offset-half-of-25pct', 'datum-on/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key, e1
LIMIT 12500 OFFSET 12500;

-- case: final-cost/offset-most-of-25pct
-- check: equivalent

-- variant: total-off/auto
-- sample: timed
SET enable_projection_total_cost = off;
SELECT topnbench_capture('final-cost/offset-most-of-25pct', 'total-off/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key
LIMIT 1000 OFFSET 24000;

-- variant: total-off/manual-late
-- sample: timed
SELECT topnbench_capture('final-cost/offset-most-of-25pct', 'total-off/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_128
      ORDER BY sort_key LIMIT 25000) AS s
ORDER BY s.k
LIMIT 1000 OFFSET 24000;

-- variant: total-off/forced-early
-- sample: timed
SELECT topnbench_capture('final-cost/offset-most-of-25pct', 'total-off/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key, e1
LIMIT 1000 OFFSET 24000;

-- variant: total-on/auto
-- sample: timed
SET enable_projection_total_cost = on;
SELECT topnbench_capture('final-cost/offset-most-of-25pct', 'total-on/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key
LIMIT 1000 OFFSET 24000;

-- variant: total-on/manual-late
-- sample: timed
SELECT topnbench_capture('final-cost/offset-most-of-25pct', 'total-on/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_128
      ORDER BY sort_key LIMIT 25000) AS s
ORDER BY s.k
LIMIT 1000 OFFSET 24000;

-- variant: total-on/forced-early
-- sample: timed
SELECT topnbench_capture('final-cost/offset-most-of-25pct', 'total-on/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key, e1
LIMIT 1000 OFFSET 24000;

-- case: datum-cost/offset-most-of-25pct
-- check: equivalent

-- variant: datum-off/auto
-- sample: timed
SET enable_sort_datum_cost = off;
SELECT topnbench_capture('datum-cost/offset-most-of-25pct', 'datum-off/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key
LIMIT 1000 OFFSET 24000;

-- variant: datum-off/manual-late
-- sample: timed
SELECT topnbench_capture('datum-cost/offset-most-of-25pct', 'datum-off/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_128
      ORDER BY sort_key LIMIT 25000) AS s
ORDER BY s.k
LIMIT 1000 OFFSET 24000;

-- variant: datum-off/forced-early
-- sample: timed
SELECT topnbench_capture('datum-cost/offset-most-of-25pct', 'datum-off/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key, e1
LIMIT 1000 OFFSET 24000;

-- variant: datum-on/auto
-- sample: timed
SET enable_sort_datum_cost = on;
SELECT topnbench_capture('datum-cost/offset-most-of-25pct', 'datum-on/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key
LIMIT 1000 OFFSET 24000;

-- variant: datum-on/manual-late
-- sample: timed
SELECT topnbench_capture('datum-cost/offset-most-of-25pct', 'datum-on/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_128
      ORDER BY sort_key LIMIT 25000) AS s
ORDER BY s.k
LIMIT 1000 OFFSET 24000;

-- variant: datum-on/forced-early
-- sample: timed
SELECT topnbench_capture('datum-cost/offset-most-of-25pct', 'datum-on/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key, e1
LIMIT 1000 OFFSET 24000;

-- case: final-cost/expensive-limit-1pct
-- check: equivalent

-- variant: total-off/auto
-- sample: timed
SET enable_projection_total_cost = off;
SELECT topnbench_capture('final-cost/expensive-limit-1pct', 'total-off/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 128, 0) AS e1
FROM topnbench_copy_width_256
ORDER BY sort_key
LIMIT 1000 OFFSET 0;

-- variant: total-off/manual-late
-- sample: timed
SELECT topnbench_capture('final-cost/expensive-limit-1pct', 'total-off/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 128, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_256
      ORDER BY sort_key LIMIT 1000) AS s
ORDER BY s.k
LIMIT 1000 OFFSET 0;

-- variant: total-off/forced-early
-- sample: timed
SELECT topnbench_capture('final-cost/expensive-limit-1pct', 'total-off/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 128, 0) AS e1
FROM topnbench_copy_width_256
ORDER BY sort_key, e1
LIMIT 1000 OFFSET 0;

-- variant: total-on/auto
-- sample: timed
SET enable_projection_total_cost = on;
SELECT topnbench_capture('final-cost/expensive-limit-1pct', 'total-on/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 128, 0) AS e1
FROM topnbench_copy_width_256
ORDER BY sort_key
LIMIT 1000 OFFSET 0;

-- variant: total-on/manual-late
-- sample: timed
SELECT topnbench_capture('final-cost/expensive-limit-1pct', 'total-on/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 128, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_256
      ORDER BY sort_key LIMIT 1000) AS s
ORDER BY s.k
LIMIT 1000 OFFSET 0;

-- variant: total-on/forced-early
-- sample: timed
SELECT topnbench_capture('final-cost/expensive-limit-1pct', 'total-on/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 128, 0) AS e1
FROM topnbench_copy_width_256
ORDER BY sort_key, e1
LIMIT 1000 OFFSET 0;

-- case: datum-cost/expensive-limit-1pct
-- check: equivalent

-- variant: datum-off/auto
-- sample: timed
SET enable_sort_datum_cost = off;
SELECT topnbench_capture('datum-cost/expensive-limit-1pct', 'datum-off/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 128, 0) AS e1
FROM topnbench_copy_width_256
ORDER BY sort_key
LIMIT 1000 OFFSET 0;

-- variant: datum-off/manual-late
-- sample: timed
SELECT topnbench_capture('datum-cost/expensive-limit-1pct', 'datum-off/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 128, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_256
      ORDER BY sort_key LIMIT 1000) AS s
ORDER BY s.k
LIMIT 1000 OFFSET 0;

-- variant: datum-off/forced-early
-- sample: timed
SELECT topnbench_capture('datum-cost/expensive-limit-1pct', 'datum-off/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 128, 0) AS e1
FROM topnbench_copy_width_256
ORDER BY sort_key, e1
LIMIT 1000 OFFSET 0;

-- variant: datum-on/auto
-- sample: timed
SET enable_sort_datum_cost = on;
SELECT topnbench_capture('datum-cost/expensive-limit-1pct', 'datum-on/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 128, 0) AS e1
FROM topnbench_copy_width_256
ORDER BY sort_key
LIMIT 1000 OFFSET 0;

-- variant: datum-on/manual-late
-- sample: timed
SELECT topnbench_capture('datum-cost/expensive-limit-1pct', 'datum-on/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 128, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_256
      ORDER BY sort_key LIMIT 1000) AS s
ORDER BY s.k
LIMIT 1000 OFFSET 0;

-- variant: datum-on/forced-early
-- sample: timed
SELECT topnbench_capture('datum-cost/expensive-limit-1pct', 'datum-on/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 128, 0) AS e1
FROM topnbench_copy_width_256
ORDER BY sort_key, e1
LIMIT 1000 OFFSET 0;

-- case: final-cost/parallel-width-128
-- check: equivalent
SET max_parallel_workers_per_gather = 2;

-- variant: total-off/auto
-- sample: timed
SET enable_projection_total_cost = off;
SELECT topnbench_capture('final-cost/parallel-width-128', 'total-off/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: total-off/manual-late
-- sample: timed
SELECT topnbench_capture('final-cost/parallel-width-128', 'total-off/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_128
      ORDER BY sort_key LIMIT 25000) AS s
ORDER BY s.k
LIMIT 25000 OFFSET 0;

-- variant: total-off/forced-early
-- sample: timed
SELECT topnbench_capture('final-cost/parallel-width-128', 'total-off/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key, e1
LIMIT 25000 OFFSET 0;

-- variant: total-on/auto
-- sample: timed
SET enable_projection_total_cost = on;
SELECT topnbench_capture('final-cost/parallel-width-128', 'total-on/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: total-on/manual-late
-- sample: timed
SELECT topnbench_capture('final-cost/parallel-width-128', 'total-on/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_128
      ORDER BY sort_key LIMIT 25000) AS s
ORDER BY s.k
LIMIT 25000 OFFSET 0;

-- variant: total-on/forced-early
-- sample: timed
SELECT topnbench_capture('final-cost/parallel-width-128', 'total-on/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key, e1
LIMIT 25000 OFFSET 0;

-- case: datum-cost/parallel-width-128
-- check: equivalent

-- variant: datum-off/auto
-- sample: timed
SET enable_sort_datum_cost = off;
SELECT topnbench_capture('datum-cost/parallel-width-128', 'datum-off/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: datum-off/manual-late
-- sample: timed
SELECT topnbench_capture('datum-cost/parallel-width-128', 'datum-off/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_128
      ORDER BY sort_key LIMIT 25000) AS s
ORDER BY s.k
LIMIT 25000 OFFSET 0;

-- variant: datum-off/forced-early
-- sample: timed
SELECT topnbench_capture('datum-cost/parallel-width-128', 'datum-off/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key, e1
LIMIT 25000 OFFSET 0;

-- variant: datum-on/auto
-- sample: timed
SET enable_sort_datum_cost = on;
SELECT topnbench_capture('datum-cost/parallel-width-128', 'datum-on/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: datum-on/manual-late
-- sample: timed
SELECT topnbench_capture('datum-cost/parallel-width-128', 'datum-on/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_128
      ORDER BY sort_key LIMIT 25000) AS s
ORDER BY s.k
LIMIT 25000 OFFSET 0;

-- variant: datum-on/forced-early
-- sample: timed
SELECT topnbench_capture('datum-cost/parallel-width-128', 'datum-on/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key, e1
LIMIT 25000 OFFSET 0;

-- case: final-cost/parallel-width-256
-- check: equivalent

-- variant: total-off/auto
-- sample: timed
SET enable_projection_total_cost = off;
SELECT topnbench_capture('final-cost/parallel-width-256', 'total-off/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_256
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: total-off/manual-late
-- sample: timed
SELECT topnbench_capture('final-cost/parallel-width-256', 'total-off/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_256
      ORDER BY sort_key LIMIT 25000) AS s
ORDER BY s.k
LIMIT 25000 OFFSET 0;

-- variant: total-off/forced-early
-- sample: timed
SELECT topnbench_capture('final-cost/parallel-width-256', 'total-off/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_256
ORDER BY sort_key, e1
LIMIT 25000 OFFSET 0;

-- variant: total-on/auto
-- sample: timed
SET enable_projection_total_cost = on;
SELECT topnbench_capture('final-cost/parallel-width-256', 'total-on/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_256
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: total-on/manual-late
-- sample: timed
SELECT topnbench_capture('final-cost/parallel-width-256', 'total-on/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_256
      ORDER BY sort_key LIMIT 25000) AS s
ORDER BY s.k
LIMIT 25000 OFFSET 0;

-- variant: total-on/forced-early
-- sample: timed
SELECT topnbench_capture('final-cost/parallel-width-256', 'total-on/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_256
ORDER BY sort_key, e1
LIMIT 25000 OFFSET 0;

-- case: datum-cost/parallel-width-256
-- check: equivalent

-- variant: datum-off/auto
-- sample: timed
SET enable_sort_datum_cost = off;
SELECT topnbench_capture('datum-cost/parallel-width-256', 'datum-off/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_256
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: datum-off/manual-late
-- sample: timed
SELECT topnbench_capture('datum-cost/parallel-width-256', 'datum-off/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_256
      ORDER BY sort_key LIMIT 25000) AS s
ORDER BY s.k
LIMIT 25000 OFFSET 0;

-- variant: datum-off/forced-early
-- sample: timed
SELECT topnbench_capture('datum-cost/parallel-width-256', 'datum-off/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_256
ORDER BY sort_key, e1
LIMIT 25000 OFFSET 0;

-- variant: datum-on/auto
-- sample: timed
SET enable_sort_datum_cost = on;
SELECT topnbench_capture('datum-cost/parallel-width-256', 'datum-on/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_256
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: datum-on/manual-late
-- sample: timed
SELECT topnbench_capture('datum-cost/parallel-width-256', 'datum-on/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM (SELECT sort_key AS k, payload FROM topnbench_copy_width_256
      ORDER BY sort_key LIMIT 25000) AS s
ORDER BY s.k
LIMIT 25000 OFFSET 0;

-- variant: datum-on/forced-early
-- sample: timed
SELECT topnbench_capture('datum-cost/parallel-width-256', 'datum-on/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_256
ORDER BY sort_key, e1
LIMIT 25000 OFFSET 0;

-- case: final-cost/cost-1-work-1
-- check: equivalent
SET max_parallel_workers_per_gather = 0;
SET work_mem = '4MB';

-- variant: total-off/auto
-- sample: timed
SET enable_projection_total_cost = off;
SELECT topnbench_capture('final-cost/cost-1-work-1', 'total-off/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 1, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: total-off/manual-late
-- sample: timed
SELECT topnbench_capture('final-cost/cost-1-work-1', 'total-off/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 1, 1) AS e1
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 250000) AS s
LIMIT 250000;

-- variant: total-off/forced-early
-- sample: timed
SELECT topnbench_capture('final-cost/cost-1-work-1', 'total-off/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 1, 1) AS e1
FROM topnbench_data
ORDER BY a_random, e1
LIMIT 250000;

-- variant: total-on/auto
-- sample: timed
SET enable_projection_total_cost = on;
SELECT topnbench_capture('final-cost/cost-1-work-1', 'total-on/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 1, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: total-on/manual-late
-- sample: timed
SELECT topnbench_capture('final-cost/cost-1-work-1', 'total-on/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 1, 1) AS e1
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 250000) AS s
LIMIT 250000;

-- variant: total-on/forced-early
-- sample: timed
SELECT topnbench_capture('final-cost/cost-1-work-1', 'total-on/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 1, 1) AS e1
FROM topnbench_data
ORDER BY a_random, e1
LIMIT 250000;

-- case: datum-cost/cost-1-work-1
-- check: equivalent

-- variant: datum-off/auto
-- sample: timed
SET enable_sort_datum_cost = off;
SELECT topnbench_capture('datum-cost/cost-1-work-1', 'datum-off/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 1, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: datum-off/manual-late
-- sample: timed
SELECT topnbench_capture('datum-cost/cost-1-work-1', 'datum-off/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 1, 1) AS e1
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 250000) AS s
LIMIT 250000;

-- variant: datum-off/forced-early
-- sample: timed
SELECT topnbench_capture('datum-cost/cost-1-work-1', 'datum-off/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 1, 1) AS e1
FROM topnbench_data
ORDER BY a_random, e1
LIMIT 250000;

-- variant: datum-on/auto
-- sample: timed
SET enable_sort_datum_cost = on;
SELECT topnbench_capture('datum-cost/cost-1-work-1', 'datum-on/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 1, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: datum-on/manual-late
-- sample: timed
SELECT topnbench_capture('datum-cost/cost-1-work-1', 'datum-on/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 1, 1) AS e1
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 250000) AS s
LIMIT 250000;

-- variant: datum-on/forced-early
-- sample: timed
SELECT topnbench_capture('datum-cost/cost-1-work-1', 'datum-on/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 1, 1) AS e1
FROM topnbench_data
ORDER BY a_random, e1
LIMIT 250000;

-- case: final-cost/cost-1-work-16
-- check: equivalent

-- variant: total-off/auto
-- sample: timed
SET enable_projection_total_cost = off;
SELECT topnbench_capture('final-cost/cost-1-work-16', 'total-off/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: total-off/manual-late
-- sample: timed
SELECT topnbench_capture('final-cost/cost-1-work-16', 'total-off/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 16, 1) AS e1
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 250000) AS s
LIMIT 250000;

-- variant: total-off/forced-early
-- sample: timed
SELECT topnbench_capture('final-cost/cost-1-work-16', 'total-off/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random, e1
LIMIT 250000;

-- variant: total-on/auto
-- sample: timed
SET enable_projection_total_cost = on;
SELECT topnbench_capture('final-cost/cost-1-work-16', 'total-on/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: total-on/manual-late
-- sample: timed
SELECT topnbench_capture('final-cost/cost-1-work-16', 'total-on/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 16, 1) AS e1
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 250000) AS s
LIMIT 250000;

-- variant: total-on/forced-early
-- sample: timed
SELECT topnbench_capture('final-cost/cost-1-work-16', 'total-on/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random, e1
LIMIT 250000;

-- case: datum-cost/cost-1-work-16
-- check: equivalent

-- variant: datum-off/auto
-- sample: timed
SET enable_sort_datum_cost = off;
SELECT topnbench_capture('datum-cost/cost-1-work-16', 'datum-off/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: datum-off/manual-late
-- sample: timed
SELECT topnbench_capture('datum-cost/cost-1-work-16', 'datum-off/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 16, 1) AS e1
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 250000) AS s
LIMIT 250000;

-- variant: datum-off/forced-early
-- sample: timed
SELECT topnbench_capture('datum-cost/cost-1-work-16', 'datum-off/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random, e1
LIMIT 250000;

-- variant: datum-on/auto
-- sample: timed
SET enable_sort_datum_cost = on;
SELECT topnbench_capture('datum-cost/cost-1-work-16', 'datum-on/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: datum-on/manual-late
-- sample: timed
SELECT topnbench_capture('datum-cost/cost-1-work-16', 'datum-on/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 16, 1) AS e1
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 250000) AS s
LIMIT 250000;

-- variant: datum-on/forced-early
-- sample: timed
SELECT topnbench_capture('datum-cost/cost-1-work-16', 'datum-on/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random, e1
LIMIT 250000;

-- case: final-cost/cost-1-work-64
-- check: equivalent

-- variant: total-off/auto
-- sample: timed
SET enable_projection_total_cost = off;
SELECT topnbench_capture('final-cost/cost-1-work-64', 'total-off/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 64, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: total-off/manual-late
-- sample: timed
SELECT topnbench_capture('final-cost/cost-1-work-64', 'total-off/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 64, 1) AS e1
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 250000) AS s
LIMIT 250000;

-- variant: total-off/forced-early
-- sample: timed
SELECT topnbench_capture('final-cost/cost-1-work-64', 'total-off/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 64, 1) AS e1
FROM topnbench_data
ORDER BY a_random, e1
LIMIT 250000;

-- variant: total-on/auto
-- sample: timed
SET enable_projection_total_cost = on;
SELECT topnbench_capture('final-cost/cost-1-work-64', 'total-on/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 64, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: total-on/manual-late
-- sample: timed
SELECT topnbench_capture('final-cost/cost-1-work-64', 'total-on/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 64, 1) AS e1
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 250000) AS s
LIMIT 250000;

-- variant: total-on/forced-early
-- sample: timed
SELECT topnbench_capture('final-cost/cost-1-work-64', 'total-on/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 64, 1) AS e1
FROM topnbench_data
ORDER BY a_random, e1
LIMIT 250000;

-- case: datum-cost/cost-1-work-64
-- check: equivalent

-- variant: datum-off/auto
-- sample: timed
SET enable_sort_datum_cost = off;
SELECT topnbench_capture('datum-cost/cost-1-work-64', 'datum-off/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 64, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: datum-off/manual-late
-- sample: timed
SELECT topnbench_capture('datum-cost/cost-1-work-64', 'datum-off/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 64, 1) AS e1
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 250000) AS s
LIMIT 250000;

-- variant: datum-off/forced-early
-- sample: timed
SELECT topnbench_capture('datum-cost/cost-1-work-64', 'datum-off/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 64, 1) AS e1
FROM topnbench_data
ORDER BY a_random, e1
LIMIT 250000;

-- variant: datum-on/auto
-- sample: timed
SET enable_sort_datum_cost = on;
SELECT topnbench_capture('datum-cost/cost-1-work-64', 'datum-on/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 64, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: datum-on/manual-late
-- sample: timed
SELECT topnbench_capture('datum-cost/cost-1-work-64', 'datum-on/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 64, 1) AS e1
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 250000) AS s
LIMIT 250000;

-- variant: datum-on/forced-early
-- sample: timed
SELECT topnbench_capture('datum-cost/cost-1-work-64', 'datum-on/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 64, 1) AS e1
FROM topnbench_data
ORDER BY a_random, e1
LIMIT 250000;

-- case: final-cost/limit-90pct
-- check: equivalent

-- variant: total-off/auto
-- sample: timed
SET enable_projection_total_cost = off;
SELECT topnbench_capture('final-cost/limit-90pct', 'total-off/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 900000;

-- variant: total-off/manual-late
-- sample: timed
SELECT topnbench_capture('final-cost/limit-90pct', 'total-off/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 4, 1) AS e1,
       topnbench_work_cost_1(s.k, 4, 2) AS e2,
       topnbench_work_cost_1(s.k, 4, 3) AS e3,
       topnbench_work_cost_1(s.k, 4, 4) AS e4
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 900000) AS s
LIMIT 900000;

-- variant: total-off/forced-early
-- sample: timed
SELECT topnbench_capture('final-cost/limit-90pct', 'total-off/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random, e1, e2, e3, e4
LIMIT 900000;

-- variant: total-on/auto
-- sample: timed
SET enable_projection_total_cost = on;
SELECT topnbench_capture('final-cost/limit-90pct', 'total-on/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 900000;

-- variant: total-on/manual-late
-- sample: timed
SELECT topnbench_capture('final-cost/limit-90pct', 'total-on/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 4, 1) AS e1,
       topnbench_work_cost_1(s.k, 4, 2) AS e2,
       topnbench_work_cost_1(s.k, 4, 3) AS e3,
       topnbench_work_cost_1(s.k, 4, 4) AS e4
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 900000) AS s
LIMIT 900000;

-- variant: total-on/forced-early
-- sample: timed
SELECT topnbench_capture('final-cost/limit-90pct', 'total-on/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random, e1, e2, e3, e4
LIMIT 900000;

-- case: datum-cost/limit-90pct
-- check: equivalent

-- variant: datum-off/auto
-- sample: timed
SET enable_sort_datum_cost = off;
SELECT topnbench_capture('datum-cost/limit-90pct', 'datum-off/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 900000;

-- variant: datum-off/manual-late
-- sample: timed
SELECT topnbench_capture('datum-cost/limit-90pct', 'datum-off/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 4, 1) AS e1,
       topnbench_work_cost_1(s.k, 4, 2) AS e2,
       topnbench_work_cost_1(s.k, 4, 3) AS e3,
       topnbench_work_cost_1(s.k, 4, 4) AS e4
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 900000) AS s
LIMIT 900000;

-- variant: datum-off/forced-early
-- sample: timed
SELECT topnbench_capture('datum-cost/limit-90pct', 'datum-off/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random, e1, e2, e3, e4
LIMIT 900000;

-- variant: datum-on/auto
-- sample: timed
SET enable_sort_datum_cost = on;
SELECT topnbench_capture('datum-cost/limit-90pct', 'datum-on/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 900000;

-- variant: datum-on/manual-late
-- sample: timed
SELECT topnbench_capture('datum-cost/limit-90pct', 'datum-on/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 4, 1) AS e1,
       topnbench_work_cost_1(s.k, 4, 2) AS e2,
       topnbench_work_cost_1(s.k, 4, 3) AS e3,
       topnbench_work_cost_1(s.k, 4, 4) AS e4
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 900000) AS s
LIMIT 900000;

-- variant: datum-on/forced-early
-- sample: timed
SELECT topnbench_capture('datum-cost/limit-90pct', 'datum-on/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random, e1, e2, e3, e4
LIMIT 900000;

-- case: representation/limit-250000/4MB
-- check: shape

-- variant: scan-one
-- sample: timed
SELECT topnbench_capture('representation/limit-250000/4MB', 'scan-one', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random FROM topnbench_data;

-- variant: scan-two
-- sample: timed
SELECT topnbench_capture('representation/limit-250000/4MB', 'scan-two', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random, same1 FROM topnbench_data;

-- variant: sort-datum
-- sample: timed
SELECT topnbench_capture('representation/limit-250000/4MB', 'sort-datum', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random FROM topnbench_data
ORDER BY a_random LIMIT 250000;

-- variant: sort-tuple
-- sample: timed
SELECT topnbench_capture('representation/limit-250000/4MB', 'sort-tuple', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random, same1 FROM topnbench_data
ORDER BY a_random LIMIT 250000;

-- variant: late-work-0
-- sample: timed
SELECT topnbench_capture('representation/limit-250000/4MB', 'late-work-0', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random, topnbench_work_cost_100(a_random, 0, 1) AS e1
FROM topnbench_data ORDER BY a_random LIMIT 250000;

-- variant: late-work-16
-- sample: timed
SELECT topnbench_capture('representation/limit-250000/4MB', 'late-work-16', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random, topnbench_work_cost_100(a_random, 16, 1) AS e1
FROM topnbench_data ORDER BY a_random LIMIT 250000;

-- case: representation/limit-250000/256MB
-- check: shape
SET work_mem = '256MB';

-- variant: scan-one
-- sample: timed
SELECT topnbench_capture('representation/limit-250000/256MB', 'scan-one', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random FROM topnbench_data;

-- variant: scan-two
-- sample: timed
SELECT topnbench_capture('representation/limit-250000/256MB', 'scan-two', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random, same1 FROM topnbench_data;

-- variant: sort-datum
-- sample: timed
SELECT topnbench_capture('representation/limit-250000/256MB', 'sort-datum', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random FROM topnbench_data
ORDER BY a_random LIMIT 250000;

-- variant: sort-tuple
-- sample: timed
SELECT topnbench_capture('representation/limit-250000/256MB', 'sort-tuple', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random, same1 FROM topnbench_data
ORDER BY a_random LIMIT 250000;

-- variant: late-work-0
-- sample: timed
SELECT topnbench_capture('representation/limit-250000/256MB', 'late-work-0', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random, topnbench_work_cost_100(a_random, 0, 1) AS e1
FROM topnbench_data ORDER BY a_random LIMIT 250000;

-- variant: late-work-16
-- sample: timed
SELECT topnbench_capture('representation/limit-250000/256MB', 'late-work-16', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random, topnbench_work_cost_100(a_random, 16, 1) AS e1
FROM topnbench_data ORDER BY a_random LIMIT 250000;

-- case: representation/limit-900000/4MB
-- check: shape
SET work_mem = '4MB';

-- variant: scan-one
-- sample: timed
SELECT topnbench_capture('representation/limit-900000/4MB', 'scan-one', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random FROM topnbench_data;

-- variant: scan-two
-- sample: timed
SELECT topnbench_capture('representation/limit-900000/4MB', 'scan-two', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random, same1 FROM topnbench_data;

-- variant: sort-datum
-- sample: timed
SELECT topnbench_capture('representation/limit-900000/4MB', 'sort-datum', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random FROM topnbench_data
ORDER BY a_random LIMIT 900000;

-- variant: sort-tuple
-- sample: timed
SELECT topnbench_capture('representation/limit-900000/4MB', 'sort-tuple', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random, same1 FROM topnbench_data
ORDER BY a_random LIMIT 900000;

-- variant: late-work-0
-- sample: timed
SELECT topnbench_capture('representation/limit-900000/4MB', 'late-work-0', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random, topnbench_work_cost_100(a_random, 0, 1) AS e1
FROM topnbench_data ORDER BY a_random LIMIT 900000;

-- variant: late-work-16
-- sample: timed
SELECT topnbench_capture('representation/limit-900000/4MB', 'late-work-16', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random, topnbench_work_cost_100(a_random, 16, 1) AS e1
FROM topnbench_data ORDER BY a_random LIMIT 900000;

-- case: representation/limit-900000/256MB
-- check: shape
SET work_mem = '256MB';

-- variant: scan-one
-- sample: timed
SELECT topnbench_capture('representation/limit-900000/256MB', 'scan-one', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random FROM topnbench_data;

-- variant: scan-two
-- sample: timed
SELECT topnbench_capture('representation/limit-900000/256MB', 'scan-two', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random, same1 FROM topnbench_data;

-- variant: sort-datum
-- sample: timed
SELECT topnbench_capture('representation/limit-900000/256MB', 'sort-datum', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random FROM topnbench_data
ORDER BY a_random LIMIT 900000;

-- variant: sort-tuple
-- sample: timed
SELECT topnbench_capture('representation/limit-900000/256MB', 'sort-tuple', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random, same1 FROM topnbench_data
ORDER BY a_random LIMIT 900000;

-- variant: late-work-0
-- sample: timed
SELECT topnbench_capture('representation/limit-900000/256MB', 'late-work-0', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random, topnbench_work_cost_100(a_random, 0, 1) AS e1
FROM topnbench_data ORDER BY a_random LIMIT 900000;

-- variant: late-work-16
-- sample: timed
SELECT topnbench_capture('representation/limit-900000/256MB', 'late-work-16', 'shape', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random, topnbench_work_cost_100(a_random, 16, 1) AS e1
FROM topnbench_data ORDER BY a_random LIMIT 900000;

-- case: boundary/cost-1-work-16/4MB
-- check: equivalent
SET work_mem = '4MB';

-- variant: datum-off/auto
-- sample: timed
SET enable_sort_datum_cost = off;
SELECT topnbench_capture('boundary/cost-1-work-16/4MB', 'datum-off/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: datum-off/manual-late
-- sample: timed
SELECT topnbench_capture('boundary/cost-1-work-16/4MB', 'datum-off/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 16, 1) AS e1
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 250000) AS s
LIMIT 250000;

-- variant: datum-off/forced-early
-- sample: timed
SELECT topnbench_capture('boundary/cost-1-work-16/4MB', 'datum-off/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random, e1
LIMIT 250000;

-- variant: datum-on/auto
-- sample: timed
SET enable_sort_datum_cost = on;
SELECT topnbench_capture('boundary/cost-1-work-16/4MB', 'datum-on/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: datum-on/manual-late
-- sample: timed
SELECT topnbench_capture('boundary/cost-1-work-16/4MB', 'datum-on/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 16, 1) AS e1
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 250000) AS s
LIMIT 250000;

-- variant: datum-on/forced-early
-- sample: timed
SELECT topnbench_capture('boundary/cost-1-work-16/4MB', 'datum-on/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random, e1
LIMIT 250000;

-- case: algorithm/cost-1-work-16/4MB
-- check: algorithm

-- variant: default/auto
-- sample: timed
SELECT topnbench_capture('algorithm/cost-1-work-16/4MB', 'default/auto', 'algorithm', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: default/manual-late
-- sample: timed
SELECT topnbench_capture('algorithm/cost-1-work-16/4MB', 'default/manual-late', 'algorithm', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 16, 1) AS e1
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 250000) AS s
LIMIT 250000;

-- variant: default/forced-early
-- sample: timed
SELECT topnbench_capture('algorithm/cost-1-work-16/4MB', 'default/forced-early', 'algorithm', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random, e1
LIMIT 250000;

-- variant: radix-disabled/auto
-- sample: timed
SET debug_disable_sort_radix = on;
SELECT topnbench_capture('algorithm/cost-1-work-16/4MB', 'radix-disabled/auto', 'algorithm', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: radix-disabled/manual-late
-- sample: timed
SELECT topnbench_capture('algorithm/cost-1-work-16/4MB', 'radix-disabled/manual-late', 'algorithm', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 16, 1) AS e1
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 250000) AS s
LIMIT 250000;

-- variant: radix-disabled/forced-early
-- sample: timed
SELECT topnbench_capture('algorithm/cost-1-work-16/4MB', 'radix-disabled/forced-early', 'algorithm', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random, e1
LIMIT 250000;

-- case: boundary/cost-1-work-16/8MB
-- check: equivalent
SET debug_disable_sort_radix = off;
SET work_mem = '8MB';

-- variant: datum-off/auto
-- sample: timed
SET enable_sort_datum_cost = off;
SELECT topnbench_capture('boundary/cost-1-work-16/8MB', 'datum-off/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: datum-off/manual-late
-- sample: timed
SELECT topnbench_capture('boundary/cost-1-work-16/8MB', 'datum-off/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 16, 1) AS e1
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 250000) AS s
LIMIT 250000;

-- variant: datum-off/forced-early
-- sample: timed
SELECT topnbench_capture('boundary/cost-1-work-16/8MB', 'datum-off/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random, e1
LIMIT 250000;

-- variant: datum-on/auto
-- sample: timed
SET enable_sort_datum_cost = on;
SELECT topnbench_capture('boundary/cost-1-work-16/8MB', 'datum-on/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: datum-on/manual-late
-- sample: timed
SELECT topnbench_capture('boundary/cost-1-work-16/8MB', 'datum-on/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 16, 1) AS e1
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 250000) AS s
LIMIT 250000;

-- variant: datum-on/forced-early
-- sample: timed
SELECT topnbench_capture('boundary/cost-1-work-16/8MB', 'datum-on/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random, e1
LIMIT 250000;

-- case: boundary/cost-1-work-16/16MB
-- check: equivalent
SET work_mem = '16MB';

-- variant: datum-off/auto
-- sample: timed
SET enable_sort_datum_cost = off;
SELECT topnbench_capture('boundary/cost-1-work-16/16MB', 'datum-off/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: datum-off/manual-late
-- sample: timed
SELECT topnbench_capture('boundary/cost-1-work-16/16MB', 'datum-off/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 16, 1) AS e1
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 250000) AS s
LIMIT 250000;

-- variant: datum-off/forced-early
-- sample: timed
SELECT topnbench_capture('boundary/cost-1-work-16/16MB', 'datum-off/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random, e1
LIMIT 250000;

-- variant: datum-on/auto
-- sample: timed
SET enable_sort_datum_cost = on;
SELECT topnbench_capture('boundary/cost-1-work-16/16MB', 'datum-on/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: datum-on/manual-late
-- sample: timed
SELECT topnbench_capture('boundary/cost-1-work-16/16MB', 'datum-on/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 16, 1) AS e1
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 250000) AS s
LIMIT 250000;

-- variant: datum-on/forced-early
-- sample: timed
SELECT topnbench_capture('boundary/cost-1-work-16/16MB', 'datum-on/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random, e1
LIMIT 250000;

-- case: algorithm/cost-1-work-16/16MB
-- check: algorithm

-- variant: default/auto
-- sample: timed
SELECT topnbench_capture('algorithm/cost-1-work-16/16MB', 'default/auto', 'algorithm', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: default/manual-late
-- sample: timed
SELECT topnbench_capture('algorithm/cost-1-work-16/16MB', 'default/manual-late', 'algorithm', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 16, 1) AS e1
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 250000) AS s
LIMIT 250000;

-- variant: default/forced-early
-- sample: timed
SELECT topnbench_capture('algorithm/cost-1-work-16/16MB', 'default/forced-early', 'algorithm', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random, e1
LIMIT 250000;

-- variant: radix-disabled/auto
-- sample: timed
SET debug_disable_sort_radix = on;
SELECT topnbench_capture('algorithm/cost-1-work-16/16MB', 'radix-disabled/auto', 'algorithm', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: radix-disabled/manual-late
-- sample: timed
SELECT topnbench_capture('algorithm/cost-1-work-16/16MB', 'radix-disabled/manual-late', 'algorithm', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 16, 1) AS e1
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 250000) AS s
LIMIT 250000;

-- variant: radix-disabled/forced-early
-- sample: timed
SELECT topnbench_capture('algorithm/cost-1-work-16/16MB', 'radix-disabled/forced-early', 'algorithm', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random, e1
LIMIT 250000;

-- case: boundary/cost-1-work-16/24MB
-- check: equivalent
SET debug_disable_sort_radix = off;
SET work_mem = '24MB';

-- variant: datum-off/auto
-- sample: timed
SET enable_sort_datum_cost = off;
SELECT topnbench_capture('boundary/cost-1-work-16/24MB', 'datum-off/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: datum-off/manual-late
-- sample: timed
SELECT topnbench_capture('boundary/cost-1-work-16/24MB', 'datum-off/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 16, 1) AS e1
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 250000) AS s
LIMIT 250000;

-- variant: datum-off/forced-early
-- sample: timed
SELECT topnbench_capture('boundary/cost-1-work-16/24MB', 'datum-off/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random, e1
LIMIT 250000;

-- variant: datum-on/auto
-- sample: timed
SET enable_sort_datum_cost = on;
SELECT topnbench_capture('boundary/cost-1-work-16/24MB', 'datum-on/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: datum-on/manual-late
-- sample: timed
SELECT topnbench_capture('boundary/cost-1-work-16/24MB', 'datum-on/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 16, 1) AS e1
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 250000) AS s
LIMIT 250000;

-- variant: datum-on/forced-early
-- sample: timed
SELECT topnbench_capture('boundary/cost-1-work-16/24MB', 'datum-on/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random, e1
LIMIT 250000;

-- case: algorithm/cost-1-work-16/24MB
-- check: algorithm

-- variant: default/auto
-- sample: timed
SELECT topnbench_capture('algorithm/cost-1-work-16/24MB', 'default/auto', 'algorithm', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: default/manual-late
-- sample: timed
SELECT topnbench_capture('algorithm/cost-1-work-16/24MB', 'default/manual-late', 'algorithm', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 16, 1) AS e1
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 250000) AS s
LIMIT 250000;

-- variant: default/forced-early
-- sample: timed
SELECT topnbench_capture('algorithm/cost-1-work-16/24MB', 'default/forced-early', 'algorithm', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random, e1
LIMIT 250000;

-- variant: radix-disabled/auto
-- sample: timed
SET debug_disable_sort_radix = on;
SELECT topnbench_capture('algorithm/cost-1-work-16/24MB', 'radix-disabled/auto', 'algorithm', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: radix-disabled/manual-late
-- sample: timed
SELECT topnbench_capture('algorithm/cost-1-work-16/24MB', 'radix-disabled/manual-late', 'algorithm', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 16, 1) AS e1
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 250000) AS s
LIMIT 250000;

-- variant: radix-disabled/forced-early
-- sample: timed
SELECT topnbench_capture('algorithm/cost-1-work-16/24MB', 'radix-disabled/forced-early', 'algorithm', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random, e1
LIMIT 250000;

-- case: boundary/cost-1-work-16/32MB
-- check: equivalent
SET debug_disable_sort_radix = off;
SET work_mem = '32MB';

-- variant: datum-off/auto
-- sample: timed
SET enable_sort_datum_cost = off;
SELECT topnbench_capture('boundary/cost-1-work-16/32MB', 'datum-off/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: datum-off/manual-late
-- sample: timed
SELECT topnbench_capture('boundary/cost-1-work-16/32MB', 'datum-off/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 16, 1) AS e1
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 250000) AS s
LIMIT 250000;

-- variant: datum-off/forced-early
-- sample: timed
SELECT topnbench_capture('boundary/cost-1-work-16/32MB', 'datum-off/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random, e1
LIMIT 250000;

-- variant: datum-on/auto
-- sample: timed
SET enable_sort_datum_cost = on;
SELECT topnbench_capture('boundary/cost-1-work-16/32MB', 'datum-on/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: datum-on/manual-late
-- sample: timed
SELECT topnbench_capture('boundary/cost-1-work-16/32MB', 'datum-on/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 16, 1) AS e1
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 250000) AS s
LIMIT 250000;

-- variant: datum-on/forced-early
-- sample: timed
SELECT topnbench_capture('boundary/cost-1-work-16/32MB', 'datum-on/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random, e1
LIMIT 250000;

-- case: algorithm/cost-1-work-16/32MB
-- check: algorithm

-- variant: default/auto
-- sample: timed
SELECT topnbench_capture('algorithm/cost-1-work-16/32MB', 'default/auto', 'algorithm', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: default/manual-late
-- sample: timed
SELECT topnbench_capture('algorithm/cost-1-work-16/32MB', 'default/manual-late', 'algorithm', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 16, 1) AS e1
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 250000) AS s
LIMIT 250000;

-- variant: default/forced-early
-- sample: timed
SELECT topnbench_capture('algorithm/cost-1-work-16/32MB', 'default/forced-early', 'algorithm', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random, e1
LIMIT 250000;

-- variant: radix-disabled/auto
-- sample: timed
SET debug_disable_sort_radix = on;
SELECT topnbench_capture('algorithm/cost-1-work-16/32MB', 'radix-disabled/auto', 'algorithm', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: radix-disabled/manual-late
-- sample: timed
SELECT topnbench_capture('algorithm/cost-1-work-16/32MB', 'radix-disabled/manual-late', 'algorithm', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 16, 1) AS e1
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 250000) AS s
LIMIT 250000;

-- variant: radix-disabled/forced-early
-- sample: timed
SELECT topnbench_capture('algorithm/cost-1-work-16/32MB', 'radix-disabled/forced-early', 'algorithm', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random, e1
LIMIT 250000;

-- case: boundary/cost-1-work-16/256MB
-- check: equivalent
SET debug_disable_sort_radix = off;
SET work_mem = '256MB';

-- variant: datum-off/auto
-- sample: timed
SET enable_sort_datum_cost = off;
SELECT topnbench_capture('boundary/cost-1-work-16/256MB', 'datum-off/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: datum-off/manual-late
-- sample: timed
SELECT topnbench_capture('boundary/cost-1-work-16/256MB', 'datum-off/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 16, 1) AS e1
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 250000) AS s
LIMIT 250000;

-- variant: datum-off/forced-early
-- sample: timed
SELECT topnbench_capture('boundary/cost-1-work-16/256MB', 'datum-off/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random, e1
LIMIT 250000;

-- variant: datum-on/auto
-- sample: timed
SET enable_sort_datum_cost = on;
SELECT topnbench_capture('boundary/cost-1-work-16/256MB', 'datum-on/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: datum-on/manual-late
-- sample: timed
SELECT topnbench_capture('boundary/cost-1-work-16/256MB', 'datum-on/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 16, 1) AS e1
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 250000) AS s
LIMIT 250000;

-- variant: datum-on/forced-early
-- sample: timed
SELECT topnbench_capture('boundary/cost-1-work-16/256MB', 'datum-on/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random, e1
LIMIT 250000;

-- case: algorithm/cost-1-work-16/256MB
-- check: algorithm

-- variant: default/auto
-- sample: timed
SELECT topnbench_capture('algorithm/cost-1-work-16/256MB', 'default/auto', 'algorithm', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: default/manual-late
-- sample: timed
SELECT topnbench_capture('algorithm/cost-1-work-16/256MB', 'default/manual-late', 'algorithm', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 16, 1) AS e1
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 250000) AS s
LIMIT 250000;

-- variant: default/forced-early
-- sample: timed
SELECT topnbench_capture('algorithm/cost-1-work-16/256MB', 'default/forced-early', 'algorithm', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random, e1
LIMIT 250000;

-- variant: radix-disabled/auto
-- sample: timed
SET debug_disable_sort_radix = on;
SELECT topnbench_capture('algorithm/cost-1-work-16/256MB', 'radix-disabled/auto', 'algorithm', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: radix-disabled/manual-late
-- sample: timed
SELECT topnbench_capture('algorithm/cost-1-work-16/256MB', 'radix-disabled/manual-late', 'algorithm', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 16, 1) AS e1
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 250000) AS s
LIMIT 250000;

-- variant: radix-disabled/forced-early
-- sample: timed
SELECT topnbench_capture('algorithm/cost-1-work-16/256MB', 'radix-disabled/forced-early', 'algorithm', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random, e1
LIMIT 250000;

-- case: boundary/limit-90pct/4MB
-- check: equivalent
SET debug_disable_sort_radix = off;
SET work_mem = '4MB';

-- variant: datum-off/auto
-- sample: timed
SET enable_sort_datum_cost = off;
SELECT topnbench_capture('boundary/limit-90pct/4MB', 'datum-off/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 900000;

-- variant: datum-off/manual-late
-- sample: timed
SELECT topnbench_capture('boundary/limit-90pct/4MB', 'datum-off/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 4, 1) AS e1,
       topnbench_work_cost_1(s.k, 4, 2) AS e2,
       topnbench_work_cost_1(s.k, 4, 3) AS e3,
       topnbench_work_cost_1(s.k, 4, 4) AS e4
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 900000) AS s
LIMIT 900000;

-- variant: datum-off/forced-early
-- sample: timed
SELECT topnbench_capture('boundary/limit-90pct/4MB', 'datum-off/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random, e1, e2, e3, e4
LIMIT 900000;

-- variant: datum-on/auto
-- sample: timed
SET enable_sort_datum_cost = on;
SELECT topnbench_capture('boundary/limit-90pct/4MB', 'datum-on/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 900000;

-- variant: datum-on/manual-late
-- sample: timed
SELECT topnbench_capture('boundary/limit-90pct/4MB', 'datum-on/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 4, 1) AS e1,
       topnbench_work_cost_1(s.k, 4, 2) AS e2,
       topnbench_work_cost_1(s.k, 4, 3) AS e3,
       topnbench_work_cost_1(s.k, 4, 4) AS e4
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 900000) AS s
LIMIT 900000;

-- variant: datum-on/forced-early
-- sample: timed
SELECT topnbench_capture('boundary/limit-90pct/4MB', 'datum-on/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random, e1, e2, e3, e4
LIMIT 900000;

-- case: boundary/limit-90pct/8MB
-- check: equivalent
SET work_mem = '8MB';

-- variant: datum-off/auto
-- sample: timed
SET enable_sort_datum_cost = off;
SELECT topnbench_capture('boundary/limit-90pct/8MB', 'datum-off/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 900000;

-- variant: datum-off/manual-late
-- sample: timed
SELECT topnbench_capture('boundary/limit-90pct/8MB', 'datum-off/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 4, 1) AS e1,
       topnbench_work_cost_1(s.k, 4, 2) AS e2,
       topnbench_work_cost_1(s.k, 4, 3) AS e3,
       topnbench_work_cost_1(s.k, 4, 4) AS e4
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 900000) AS s
LIMIT 900000;

-- variant: datum-off/forced-early
-- sample: timed
SELECT topnbench_capture('boundary/limit-90pct/8MB', 'datum-off/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random, e1, e2, e3, e4
LIMIT 900000;

-- variant: datum-on/auto
-- sample: timed
SET enable_sort_datum_cost = on;
SELECT topnbench_capture('boundary/limit-90pct/8MB', 'datum-on/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 900000;

-- variant: datum-on/manual-late
-- sample: timed
SELECT topnbench_capture('boundary/limit-90pct/8MB', 'datum-on/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 4, 1) AS e1,
       topnbench_work_cost_1(s.k, 4, 2) AS e2,
       topnbench_work_cost_1(s.k, 4, 3) AS e3,
       topnbench_work_cost_1(s.k, 4, 4) AS e4
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 900000) AS s
LIMIT 900000;

-- variant: datum-on/forced-early
-- sample: timed
SELECT topnbench_capture('boundary/limit-90pct/8MB', 'datum-on/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random, e1, e2, e3, e4
LIMIT 900000;

-- case: boundary/limit-90pct/16MB
-- check: equivalent
SET work_mem = '16MB';

-- variant: datum-off/auto
-- sample: timed
SET enable_sort_datum_cost = off;
SELECT topnbench_capture('boundary/limit-90pct/16MB', 'datum-off/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 900000;

-- variant: datum-off/manual-late
-- sample: timed
SELECT topnbench_capture('boundary/limit-90pct/16MB', 'datum-off/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 4, 1) AS e1,
       topnbench_work_cost_1(s.k, 4, 2) AS e2,
       topnbench_work_cost_1(s.k, 4, 3) AS e3,
       topnbench_work_cost_1(s.k, 4, 4) AS e4
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 900000) AS s
LIMIT 900000;

-- variant: datum-off/forced-early
-- sample: timed
SELECT topnbench_capture('boundary/limit-90pct/16MB', 'datum-off/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random, e1, e2, e3, e4
LIMIT 900000;

-- variant: datum-on/auto
-- sample: timed
SET enable_sort_datum_cost = on;
SELECT topnbench_capture('boundary/limit-90pct/16MB', 'datum-on/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 900000;

-- variant: datum-on/manual-late
-- sample: timed
SELECT topnbench_capture('boundary/limit-90pct/16MB', 'datum-on/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 4, 1) AS e1,
       topnbench_work_cost_1(s.k, 4, 2) AS e2,
       topnbench_work_cost_1(s.k, 4, 3) AS e3,
       topnbench_work_cost_1(s.k, 4, 4) AS e4
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 900000) AS s
LIMIT 900000;

-- variant: datum-on/forced-early
-- sample: timed
SELECT topnbench_capture('boundary/limit-90pct/16MB', 'datum-on/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random, e1, e2, e3, e4
LIMIT 900000;

-- case: boundary/limit-90pct/24MB
-- check: equivalent
SET work_mem = '24MB';

-- variant: datum-off/auto
-- sample: timed
SET enable_sort_datum_cost = off;
SELECT topnbench_capture('boundary/limit-90pct/24MB', 'datum-off/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 900000;

-- variant: datum-off/manual-late
-- sample: timed
SELECT topnbench_capture('boundary/limit-90pct/24MB', 'datum-off/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 4, 1) AS e1,
       topnbench_work_cost_1(s.k, 4, 2) AS e2,
       topnbench_work_cost_1(s.k, 4, 3) AS e3,
       topnbench_work_cost_1(s.k, 4, 4) AS e4
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 900000) AS s
LIMIT 900000;

-- variant: datum-off/forced-early
-- sample: timed
SELECT topnbench_capture('boundary/limit-90pct/24MB', 'datum-off/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random, e1, e2, e3, e4
LIMIT 900000;

-- variant: datum-on/auto
-- sample: timed
SET enable_sort_datum_cost = on;
SELECT topnbench_capture('boundary/limit-90pct/24MB', 'datum-on/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 900000;

-- variant: datum-on/manual-late
-- sample: timed
SELECT topnbench_capture('boundary/limit-90pct/24MB', 'datum-on/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 4, 1) AS e1,
       topnbench_work_cost_1(s.k, 4, 2) AS e2,
       topnbench_work_cost_1(s.k, 4, 3) AS e3,
       topnbench_work_cost_1(s.k, 4, 4) AS e4
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 900000) AS s
LIMIT 900000;

-- variant: datum-on/forced-early
-- sample: timed
SELECT topnbench_capture('boundary/limit-90pct/24MB', 'datum-on/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random, e1, e2, e3, e4
LIMIT 900000;

-- case: boundary/limit-90pct/32MB
-- check: equivalent
SET work_mem = '32MB';

-- variant: datum-off/auto
-- sample: timed
SET enable_sort_datum_cost = off;
SELECT topnbench_capture('boundary/limit-90pct/32MB', 'datum-off/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 900000;

-- variant: datum-off/manual-late
-- sample: timed
SELECT topnbench_capture('boundary/limit-90pct/32MB', 'datum-off/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 4, 1) AS e1,
       topnbench_work_cost_1(s.k, 4, 2) AS e2,
       topnbench_work_cost_1(s.k, 4, 3) AS e3,
       topnbench_work_cost_1(s.k, 4, 4) AS e4
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 900000) AS s
LIMIT 900000;

-- variant: datum-off/forced-early
-- sample: timed
SELECT topnbench_capture('boundary/limit-90pct/32MB', 'datum-off/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random, e1, e2, e3, e4
LIMIT 900000;

-- variant: datum-on/auto
-- sample: timed
SET enable_sort_datum_cost = on;
SELECT topnbench_capture('boundary/limit-90pct/32MB', 'datum-on/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 900000;

-- variant: datum-on/manual-late
-- sample: timed
SELECT topnbench_capture('boundary/limit-90pct/32MB', 'datum-on/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 4, 1) AS e1,
       topnbench_work_cost_1(s.k, 4, 2) AS e2,
       topnbench_work_cost_1(s.k, 4, 3) AS e3,
       topnbench_work_cost_1(s.k, 4, 4) AS e4
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 900000) AS s
LIMIT 900000;

-- variant: datum-on/forced-early
-- sample: timed
SELECT topnbench_capture('boundary/limit-90pct/32MB', 'datum-on/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random, e1, e2, e3, e4
LIMIT 900000;

-- case: boundary/limit-90pct/256MB
-- check: equivalent
SET work_mem = '256MB';

-- variant: datum-off/auto
-- sample: timed
SET enable_sort_datum_cost = off;
SELECT topnbench_capture('boundary/limit-90pct/256MB', 'datum-off/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 900000;

-- variant: datum-off/manual-late
-- sample: timed
SELECT topnbench_capture('boundary/limit-90pct/256MB', 'datum-off/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 4, 1) AS e1,
       topnbench_work_cost_1(s.k, 4, 2) AS e2,
       topnbench_work_cost_1(s.k, 4, 3) AS e3,
       topnbench_work_cost_1(s.k, 4, 4) AS e4
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 900000) AS s
LIMIT 900000;

-- variant: datum-off/forced-early
-- sample: timed
SELECT topnbench_capture('boundary/limit-90pct/256MB', 'datum-off/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random, e1, e2, e3, e4
LIMIT 900000;

-- variant: datum-on/auto
-- sample: timed
SET enable_sort_datum_cost = on;
SELECT topnbench_capture('boundary/limit-90pct/256MB', 'datum-on/auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 900000;

-- variant: datum-on/manual-late
-- sample: timed
SELECT topnbench_capture('boundary/limit-90pct/256MB', 'datum-on/manual-late', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 4, 1) AS e1,
       topnbench_work_cost_1(s.k, 4, 2) AS e2,
       topnbench_work_cost_1(s.k, 4, 3) AS e3,
       topnbench_work_cost_1(s.k, 4, 4) AS e4
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 900000) AS s
LIMIT 900000;

-- variant: datum-on/forced-early
-- sample: timed
SELECT topnbench_capture('boundary/limit-90pct/256MB', 'datum-on/forced-early', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random, e1, e2, e3, e4
LIMIT 900000;

-- case: algorithm/limit-90pct/256MB
-- check: algorithm

-- variant: default/auto
-- sample: timed
SELECT topnbench_capture('algorithm/limit-90pct/256MB', 'default/auto', 'algorithm', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 900000;

-- variant: default/manual-late
-- sample: timed
SELECT topnbench_capture('algorithm/limit-90pct/256MB', 'default/manual-late', 'algorithm', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 4, 1) AS e1,
       topnbench_work_cost_1(s.k, 4, 2) AS e2,
       topnbench_work_cost_1(s.k, 4, 3) AS e3,
       topnbench_work_cost_1(s.k, 4, 4) AS e4
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 900000) AS s
LIMIT 900000;

-- variant: default/forced-early
-- sample: timed
SELECT topnbench_capture('algorithm/limit-90pct/256MB', 'default/forced-early', 'algorithm', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random, e1, e2, e3, e4
LIMIT 900000;

-- variant: radix-disabled/auto
-- sample: timed
SET debug_disable_sort_radix = on;
SELECT topnbench_capture('algorithm/limit-90pct/256MB', 'radix-disabled/auto', 'algorithm', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 900000;

-- variant: radix-disabled/manual-late
-- sample: timed
SELECT topnbench_capture('algorithm/limit-90pct/256MB', 'radix-disabled/manual-late', 'algorithm', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT s.k,
       topnbench_work_cost_1(s.k, 4, 1) AS e1,
       topnbench_work_cost_1(s.k, 4, 2) AS e2,
       topnbench_work_cost_1(s.k, 4, 3) AS e3,
       topnbench_work_cost_1(s.k, 4, 4) AS e4
FROM (SELECT a_random AS k FROM topnbench_data
      ORDER BY a_random LIMIT 900000) AS s
LIMIT 900000;

-- variant: radix-disabled/forced-early
-- sample: timed
SELECT topnbench_capture('algorithm/limit-90pct/256MB', 'radix-disabled/forced-early', 'algorithm', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random, e1, e2, e3, e4
LIMIT 900000;

-- case: regression/stale-width-256kB
-- check: equivalent
SET debug_disable_sort_radix = off;
SET work_mem = '256kB';

-- variant: upstream-auto
-- sample: timed
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('regression/stale-width-256kB', 'upstream-auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_underestimate
ORDER BY a
LIMIT 5000 OFFSET 0;

-- variant: path-only-auto
-- sample: timed
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('regression/stale-width-256kB', 'path-only-auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_underestimate
ORDER BY a
LIMIT 5000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('regression/stale-width-256kB', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_underestimate
ORDER BY a
LIMIT 5000 OFFSET 0;

-- case: regression/accurate-width-256kB
-- check: equivalent

-- variant: upstream-auto
-- sample: timed
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('regression/accurate-width-256kB', 'upstream-auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_accurate
ORDER BY a
LIMIT 5000 OFFSET 0;

-- variant: path-only-auto
-- sample: timed
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('regression/accurate-width-256kB', 'path-only-auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_accurate
ORDER BY a
LIMIT 5000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('regression/accurate-width-256kB', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a AS k, length(payload) AS e1
FROM topnbench_width_accurate
ORDER BY a
LIMIT 5000 OFFSET 0;

-- case: regression/copy-width-128-limit25
-- check: equivalent
SET work_mem = '1GB';

-- variant: upstream-auto
-- sample: timed
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('regression/copy-width-128-limit25', 'upstream-auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: path-only-auto
-- sample: timed
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('regression/copy-width-128-limit25', 'path-only-auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('regression/copy-width-128-limit25', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- case: regression/copy-width-256-limit25
-- check: equivalent

-- variant: upstream-auto
-- sample: timed
SET enable_cost_based_delayed_projection = off;
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('regression/copy-width-256-limit25', 'upstream-auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_256
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: path-only-auto
-- sample: timed
SET enable_cost_based_delayed_projection = on;
SELECT topnbench_capture('regression/copy-width-256-limit25', 'path-only-auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_256
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- variant: auto
-- sample: timed
SET enable_sort_tuple_width_cost = on;
SELECT topnbench_capture('regression/copy-width-256-limit25', 'auto', 'equivalent', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_256
ORDER BY sort_key
LIMIT 25000 OFFSET 0;

-- case: same-query/cost-1-work-16/4MB
-- check: same-query
SET work_mem = '4MB';

-- variant: auto
-- sample: timed
SELECT topnbench_capture('same-query/cost-1-work-16/4MB', 'auto', 'same-query', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: early
-- sample: timed
SET debug_projection_placement = early;
SELECT topnbench_capture('same-query/cost-1-work-16/4MB', 'early', 'same-query', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: late
-- sample: timed
SET debug_projection_placement = late;
SELECT topnbench_capture('same-query/cost-1-work-16/4MB', 'late', 'same-query', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- case: same-query/cost-1-work-16/8MB
-- check: same-query
SET debug_projection_placement = auto;
SET work_mem = '8MB';

-- variant: auto
-- sample: timed
SELECT topnbench_capture('same-query/cost-1-work-16/8MB', 'auto', 'same-query', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: early
-- sample: timed
SET debug_projection_placement = early;
SELECT topnbench_capture('same-query/cost-1-work-16/8MB', 'early', 'same-query', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: late
-- sample: timed
SET debug_projection_placement = late;
SELECT topnbench_capture('same-query/cost-1-work-16/8MB', 'late', 'same-query', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- case: same-query/cost-1-work-16/16MB
-- check: same-query
SET debug_projection_placement = auto;
SET work_mem = '16MB';

-- variant: auto
-- sample: timed
SELECT topnbench_capture('same-query/cost-1-work-16/16MB', 'auto', 'same-query', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: early
-- sample: timed
SET debug_projection_placement = early;
SELECT topnbench_capture('same-query/cost-1-work-16/16MB', 'early', 'same-query', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: late
-- sample: timed
SET debug_projection_placement = late;
SELECT topnbench_capture('same-query/cost-1-work-16/16MB', 'late', 'same-query', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- case: same-query/cost-1-work-16/24MB
-- check: same-query
SET debug_projection_placement = auto;
SET work_mem = '24MB';

-- variant: auto
-- sample: timed
SELECT topnbench_capture('same-query/cost-1-work-16/24MB', 'auto', 'same-query', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: early
-- sample: timed
SET debug_projection_placement = early;
SELECT topnbench_capture('same-query/cost-1-work-16/24MB', 'early', 'same-query', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: late
-- sample: timed
SET debug_projection_placement = late;
SELECT topnbench_capture('same-query/cost-1-work-16/24MB', 'late', 'same-query', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- case: same-query/cost-1-work-16/32MB
-- check: same-query
SET debug_projection_placement = auto;
SET work_mem = '32MB';

-- variant: auto
-- sample: timed
SELECT topnbench_capture('same-query/cost-1-work-16/32MB', 'auto', 'same-query', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: early
-- sample: timed
SET debug_projection_placement = early;
SELECT topnbench_capture('same-query/cost-1-work-16/32MB', 'early', 'same-query', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: late
-- sample: timed
SET debug_projection_placement = late;
SELECT topnbench_capture('same-query/cost-1-work-16/32MB', 'late', 'same-query', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- case: same-query/cost-1-work-16/256MB
-- check: same-query
SET debug_projection_placement = auto;
SET work_mem = '256MB';

-- variant: auto
-- sample: timed
SELECT topnbench_capture('same-query/cost-1-work-16/256MB', 'auto', 'same-query', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: early
-- sample: timed
SET debug_projection_placement = early;
SELECT topnbench_capture('same-query/cost-1-work-16/256MB', 'early', 'same-query', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: late
-- sample: timed
SET debug_projection_placement = late;
SELECT topnbench_capture('same-query/cost-1-work-16/256MB', 'late', 'same-query', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- case: same-query/cost-1-work-16/1GB
-- check: same-query
SET debug_projection_placement = auto;
SET work_mem = '1GB';

-- variant: auto
-- sample: timed
SELECT topnbench_capture('same-query/cost-1-work-16/1GB', 'auto', 'same-query', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: early
-- sample: timed
SET debug_projection_placement = early;
SELECT topnbench_capture('same-query/cost-1-work-16/1GB', 'early', 'same-query', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- variant: late
-- sample: timed
SET debug_projection_placement = late;
SELECT topnbench_capture('same-query/cost-1-work-16/1GB', 'late', 'same-query', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;

-- case: same-query/limit-90pct/256MB
-- check: same-query
SET debug_projection_placement = auto;
SET work_mem = '256MB';

-- variant: auto
-- sample: timed
SELECT topnbench_capture('same-query/limit-90pct/256MB', 'auto', 'same-query', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 900000;

-- variant: early
-- sample: timed
SET debug_projection_placement = early;
SELECT topnbench_capture('same-query/limit-90pct/256MB', 'early', 'same-query', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 900000;

-- variant: late
-- sample: timed
SET debug_projection_placement = late;
SELECT topnbench_capture('same-query/limit-90pct/256MB', 'late', 'same-query', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 4, 1) AS e1,
       topnbench_work_cost_1(a_random, 4, 2) AS e2,
       topnbench_work_cost_1(a_random, 4, 3) AS e3,
       topnbench_work_cost_1(a_random, 4, 4) AS e4
FROM topnbench_data
ORDER BY a_random
LIMIT 900000;

-- case: scope/subquery
-- check: unchanged
SET debug_projection_placement = auto;
SET work_mem = '64MB';

-- variant: total-off
-- sample: plan
SET enable_projection_total_cost = off;
SELECT topnbench_capture('scope/subquery', 'total-off', 'unchanged', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT * FROM (SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128 ORDER BY sort_key LIMIT 25000) s;

-- variant: total-on
-- sample: plan
SET enable_projection_total_cost = on;
SELECT topnbench_capture('scope/subquery', 'total-on', 'unchanged', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT * FROM (SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128 ORDER BY sort_key LIMIT 25000) s;

-- case: scope/with-ties
-- check: unchanged

-- variant: total-off
-- sample: plan
SET enable_projection_total_cost = off;
SELECT topnbench_capture('scope/with-ties', 'total-off', 'unchanged', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128 ORDER BY sort_key FETCH FIRST 25000 ROWS WITH TIES;

-- variant: total-on
-- sample: plan
SET enable_projection_total_cost = on;
SELECT topnbench_capture('scope/with-ties', 'total-on', 'unchanged', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128 ORDER BY sort_key FETCH FIRST 25000 ROWS WITH TIES;

-- case: scope/limit-zero
-- check: unchanged

-- variant: total-off
-- sample: plan
SET enable_projection_total_cost = off;
SELECT topnbench_capture('scope/limit-zero', 'total-off', 'unchanged', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128 ORDER BY sort_key LIMIT 0;

-- variant: total-on
-- sample: plan
SET enable_projection_total_cost = on;
SELECT topnbench_capture('scope/limit-zero', 'total-on', 'unchanged', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128 ORDER BY sort_key LIMIT 0;

-- case: scope/limit-all
-- check: unchanged

-- variant: total-off
-- sample: plan
SET enable_projection_total_cost = off;
SELECT topnbench_capture('scope/limit-all', 'total-off', 'unchanged', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128 ORDER BY sort_key LIMIT ALL;

-- variant: total-on
-- sample: plan
SET enable_projection_total_cost = on;
SELECT topnbench_capture('scope/limit-all', 'total-on', 'unchanged', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key AS k, topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1
FROM topnbench_copy_width_128 ORDER BY sort_key LIMIT ALL;

-- case: scope/volatile
-- check: unchanged

-- variant: total-off
-- sample: plan
SET enable_projection_total_cost = off;
SELECT topnbench_capture('scope/volatile', 'total-off', 'unchanged', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key, random() FROM topnbench_copy_width_128 ORDER BY sort_key LIMIT 25000;

-- variant: total-on
-- sample: plan
SET enable_projection_total_cost = on;
SELECT topnbench_capture('scope/volatile', 'total-on', 'unchanged', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key, random() FROM topnbench_copy_width_128 ORDER BY sort_key LIMIT 25000;

-- case: scope/srf
-- check: unchanged

-- variant: total-off
-- sample: plan
SET enable_projection_total_cost = off;
SELECT topnbench_capture('scope/srf', 'total-off', 'unchanged', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key, generate_series(1,2) FROM topnbench_copy_width_128 ORDER BY sort_key LIMIT 25000;

-- variant: total-on
-- sample: plan
SET enable_projection_total_cost = on;
SELECT topnbench_capture('scope/srf', 'total-on', 'unchanged', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT sort_key, generate_series(1,2) FROM topnbench_copy_width_128 ORDER BY sort_key LIMIT 25000;

-- case: datum-guard/int4
-- check: datum-cheaper
SET work_mem = '4MB';

-- variant: datum-off
-- sample: plan
SET enable_sort_datum_cost = off;
SELECT topnbench_capture('datum-guard/int4', 'datum-off', 'datum-cheaper', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random FROM topnbench_data ORDER BY 1 LIMIT 250000;

-- variant: datum-on
-- sample: plan
SET enable_sort_datum_cost = on;
SELECT topnbench_capture('datum-guard/int4', 'datum-on', 'datum-cheaper', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random FROM topnbench_data ORDER BY 1 LIMIT 250000;

-- variant: width-off-datum-on
-- sample: plan
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('datum-guard/int4', 'width-off-datum-on', 'datum-cheaper', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random FROM topnbench_data ORDER BY 1 LIMIT 250000;

-- variant: width-off-datum-off
-- sample: plan
SET enable_sort_datum_cost = off;
SELECT topnbench_capture('datum-guard/int4', 'width-off-datum-off', 'datum-cheaper', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random FROM topnbench_data ORDER BY 1 LIMIT 250000;

-- case: datum-guard/int8
-- check: datum-cheaper
SET enable_sort_tuple_width_cost = on;
SET enable_sort_datum_cost = on;

-- variant: datum-off
-- sample: plan
SET enable_sort_datum_cost = off;
SELECT topnbench_capture('datum-guard/int8', 'datum-off', 'datum-cheaper', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random::bigint FROM topnbench_data ORDER BY 1 LIMIT 250000;

-- variant: datum-on
-- sample: plan
SET enable_sort_datum_cost = on;
SELECT topnbench_capture('datum-guard/int8', 'datum-on', 'datum-cheaper', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random::bigint FROM topnbench_data ORDER BY 1 LIMIT 250000;

-- variant: width-off-datum-on
-- sample: plan
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('datum-guard/int8', 'width-off-datum-on', 'datum-cheaper', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random::bigint FROM topnbench_data ORDER BY 1 LIMIT 250000;

-- variant: width-off-datum-off
-- sample: plan
SET enable_sort_datum_cost = off;
SELECT topnbench_capture('datum-guard/int8', 'width-off-datum-off', 'datum-cheaper', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random::bigint FROM topnbench_data ORDER BY 1 LIMIT 250000;

-- case: datum-guard/float8
-- check: datum-cheaper
SET enable_sort_tuple_width_cost = on;
SET enable_sort_datum_cost = on;

-- variant: datum-off
-- sample: plan
SET enable_sort_datum_cost = off;
SELECT topnbench_capture('datum-guard/float8', 'datum-off', 'datum-cheaper', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random::float8 FROM topnbench_data ORDER BY 1 LIMIT 250000;

-- variant: datum-on
-- sample: plan
SET enable_sort_datum_cost = on;
SELECT topnbench_capture('datum-guard/float8', 'datum-on', 'datum-cheaper', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random::float8 FROM topnbench_data ORDER BY 1 LIMIT 250000;

-- variant: width-off-datum-on
-- sample: plan
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('datum-guard/float8', 'width-off-datum-on', 'datum-cheaper', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random::float8 FROM topnbench_data ORDER BY 1 LIMIT 250000;

-- variant: width-off-datum-off
-- sample: plan
SET enable_sort_datum_cost = off;
SELECT topnbench_capture('datum-guard/float8', 'width-off-datum-off', 'datum-cheaper', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random::float8 FROM topnbench_data ORDER BY 1 LIMIT 250000;

-- case: datum-guard/nullable-int4
-- check: datum-cheaper
SET enable_sort_tuple_width_cost = on;
SET enable_sort_datum_cost = on;

-- variant: datum-off
-- sample: plan
SET enable_sort_datum_cost = off;
SELECT topnbench_capture('datum-guard/nullable-int4', 'datum-off', 'datum-cheaper', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT nullif(a_random % 10, 0) FROM topnbench_data ORDER BY 1 NULLS FIRST LIMIT 250000;

-- variant: datum-on
-- sample: plan
SET enable_sort_datum_cost = on;
SELECT topnbench_capture('datum-guard/nullable-int4', 'datum-on', 'datum-cheaper', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT nullif(a_random % 10, 0) FROM topnbench_data ORDER BY 1 NULLS FIRST LIMIT 250000;

-- variant: width-off-datum-on
-- sample: plan
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('datum-guard/nullable-int4', 'width-off-datum-on', 'datum-cheaper', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT nullif(a_random % 10, 0) FROM topnbench_data ORDER BY 1 NULLS FIRST LIMIT 250000;

-- variant: width-off-datum-off
-- sample: plan
SET enable_sort_datum_cost = off;
SELECT topnbench_capture('datum-guard/nullable-int4', 'width-off-datum-off', 'datum-cheaper', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT nullif(a_random % 10, 0) FROM topnbench_data ORDER BY 1 NULLS FIRST LIMIT 250000;

-- case: datum-guard/offset-int4
-- check: datum-cheaper
SET enable_sort_tuple_width_cost = on;
SET enable_sort_datum_cost = on;

-- variant: datum-off
-- sample: plan
SET enable_sort_datum_cost = off;
SELECT topnbench_capture('datum-guard/offset-int4', 'datum-off', 'datum-cheaper', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random FROM topnbench_data ORDER BY 1 LIMIT 1000 OFFSET 249000;

-- variant: datum-on
-- sample: plan
SET enable_sort_datum_cost = on;
SELECT topnbench_capture('datum-guard/offset-int4', 'datum-on', 'datum-cheaper', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random FROM topnbench_data ORDER BY 1 LIMIT 1000 OFFSET 249000;

-- variant: width-off-datum-on
-- sample: plan
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('datum-guard/offset-int4', 'width-off-datum-on', 'datum-cheaper', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random FROM topnbench_data ORDER BY 1 LIMIT 1000 OFFSET 249000;

-- variant: width-off-datum-off
-- sample: plan
SET enable_sort_datum_cost = off;
SELECT topnbench_capture('datum-guard/offset-int4', 'width-off-datum-off', 'datum-cheaper', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random FROM topnbench_data ORDER BY 1 LIMIT 1000 OFFSET 249000;

-- case: datum-guard/tuple-two-columns
-- check: unchanged
SET enable_sort_tuple_width_cost = on;
SET enable_sort_datum_cost = on;

-- variant: datum-off
-- sample: plan
SET enable_sort_datum_cost = off;
SELECT topnbench_capture('datum-guard/tuple-two-columns', 'datum-off', 'unchanged', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random, same1 FROM topnbench_data ORDER BY 1 LIMIT 250000;

-- variant: datum-on
-- sample: plan
SET enable_sort_datum_cost = on;
SELECT topnbench_capture('datum-guard/tuple-two-columns', 'datum-on', 'unchanged', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random, same1 FROM topnbench_data ORDER BY 1 LIMIT 250000;

-- case: datum-guard-width-off/tuple-two-columns
-- check: unchanged

-- variant: width-off-datum-on
-- sample: plan
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('datum-guard-width-off/tuple-two-columns', 'width-off-datum-on', 'unchanged', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random, same1 FROM topnbench_data ORDER BY 1 LIMIT 250000;

-- variant: width-off-datum-off
-- sample: plan
SET enable_sort_datum_cost = off;
SELECT topnbench_capture('datum-guard-width-off/tuple-two-columns', 'width-off-datum-off', 'unchanged', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random, same1 FROM topnbench_data ORDER BY 1 LIMIT 250000;

-- case: datum-guard/extra-sort-expression
-- check: unchanged
SET enable_sort_tuple_width_cost = on;
SET enable_sort_datum_cost = on;

-- variant: datum-off
-- sample: plan
SET enable_sort_datum_cost = off;
SELECT topnbench_capture('datum-guard/extra-sort-expression', 'datum-off', 'unchanged', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random FROM topnbench_data ORDER BY same1 LIMIT 250000;

-- variant: datum-on
-- sample: plan
SET enable_sort_datum_cost = on;
SELECT topnbench_capture('datum-guard/extra-sort-expression', 'datum-on', 'unchanged', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random FROM topnbench_data ORDER BY same1 LIMIT 250000;

-- case: datum-guard-width-off/extra-sort-expression
-- check: unchanged

-- variant: width-off-datum-on
-- sample: plan
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('datum-guard-width-off/extra-sort-expression', 'width-off-datum-on', 'unchanged', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random FROM topnbench_data ORDER BY same1 LIMIT 250000;

-- variant: width-off-datum-off
-- sample: plan
SET enable_sort_datum_cost = off;
SELECT topnbench_capture('datum-guard-width-off/extra-sort-expression', 'width-off-datum-off', 'unchanged', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random FROM topnbench_data ORDER BY same1 LIMIT 250000;

-- case: datum-guard/text-by-reference
-- check: unchanged
SET enable_sort_tuple_width_cost = on;
SET enable_sort_datum_cost = on;

-- variant: datum-off
-- sample: plan
SET enable_sort_datum_cost = off;
SELECT topnbench_capture('datum-guard/text-by-reference', 'datum-off', 'unchanged', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random::text FROM topnbench_data ORDER BY 1 LIMIT 250000;

-- variant: datum-on
-- sample: plan
SET enable_sort_datum_cost = on;
SELECT topnbench_capture('datum-guard/text-by-reference', 'datum-on', 'unchanged', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random::text FROM topnbench_data ORDER BY 1 LIMIT 250000;

-- case: datum-guard-width-off/text-by-reference
-- check: unchanged

-- variant: width-off-datum-on
-- sample: plan
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('datum-guard-width-off/text-by-reference', 'width-off-datum-on', 'unchanged', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random::text FROM topnbench_data ORDER BY 1 LIMIT 250000;

-- variant: width-off-datum-off
-- sample: plan
SET enable_sort_datum_cost = off;
SELECT topnbench_capture('datum-guard-width-off/text-by-reference', 'width-off-datum-off', 'unchanged', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random::text FROM topnbench_data ORDER BY 1 LIMIT 250000;

-- case: datum-guard/numeric-by-reference
-- check: unchanged
SET enable_sort_tuple_width_cost = on;
SET enable_sort_datum_cost = on;

-- variant: datum-off
-- sample: plan
SET enable_sort_datum_cost = off;
SELECT topnbench_capture('datum-guard/numeric-by-reference', 'datum-off', 'unchanged', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random::numeric FROM topnbench_data ORDER BY 1 LIMIT 250000;

-- variant: datum-on
-- sample: plan
SET enable_sort_datum_cost = on;
SELECT topnbench_capture('datum-guard/numeric-by-reference', 'datum-on', 'unchanged', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random::numeric FROM topnbench_data ORDER BY 1 LIMIT 250000;

-- case: datum-guard-width-off/numeric-by-reference
-- check: unchanged

-- variant: width-off-datum-on
-- sample: plan
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('datum-guard-width-off/numeric-by-reference', 'width-off-datum-on', 'unchanged', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random::numeric FROM topnbench_data ORDER BY 1 LIMIT 250000;

-- variant: width-off-datum-off
-- sample: plan
SET enable_sort_datum_cost = off;
SELECT topnbench_capture('datum-guard-width-off/numeric-by-reference', 'width-off-datum-off', 'unchanged', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random::numeric FROM topnbench_data ORDER BY 1 LIMIT 250000;

-- case: datum-guard/unbounded-sort
-- check: unchanged
SET enable_sort_tuple_width_cost = on;
SET enable_sort_datum_cost = on;

-- variant: datum-off
-- sample: plan
SET enable_sort_datum_cost = off;
SELECT topnbench_capture('datum-guard/unbounded-sort', 'datum-off', 'unchanged', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random FROM topnbench_data ORDER BY 1;

-- variant: datum-on
-- sample: plan
SET enable_sort_datum_cost = on;
SELECT topnbench_capture('datum-guard/unbounded-sort', 'datum-on', 'unchanged', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random FROM topnbench_data ORDER BY 1;

-- case: datum-guard-width-off/unbounded-sort
-- check: unchanged

-- variant: width-off-datum-on
-- sample: plan
SET enable_sort_tuple_width_cost = off;
SELECT topnbench_capture('datum-guard-width-off/unbounded-sort', 'width-off-datum-on', 'unchanged', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random FROM topnbench_data ORDER BY 1;

-- variant: width-off-datum-off
-- sample: plan
SET enable_sort_datum_cost = off;
SELECT topnbench_capture('datum-guard-width-off/unbounded-sort', 'width-off-datum-off', 'unchanged', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random FROM topnbench_data ORDER BY 1;

-- case: placement-guard/no-limit
-- check: unchanged
SET enable_sort_tuple_width_cost = on;
SET enable_sort_datum_cost = on;

-- variant: auto
-- sample: plan
SELECT topnbench_capture('placement-guard/no-limit', 'auto', 'unchanged', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random, a_random+1 FROM topnbench_data ORDER BY a_random;

-- variant: early
-- sample: plan
SET debug_projection_placement = early;
SELECT topnbench_capture('placement-guard/no-limit', 'early', 'unchanged', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random, a_random+1 FROM topnbench_data ORDER BY a_random;

-- variant: late
-- sample: plan
SET debug_projection_placement = late;
SELECT topnbench_capture('placement-guard/no-limit', 'late', 'unchanged', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random, a_random+1 FROM topnbench_data ORDER BY a_random;

-- case: placement-guard/volatile
-- check: unchanged
SET debug_projection_placement = auto;

-- variant: auto
-- sample: plan
SELECT topnbench_capture('placement-guard/volatile', 'auto', 'unchanged', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random, random() FROM topnbench_data ORDER BY a_random LIMIT 10;

-- variant: early
-- sample: plan
SET debug_projection_placement = early;
SELECT topnbench_capture('placement-guard/volatile', 'early', 'unchanged', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random, random() FROM topnbench_data ORDER BY a_random LIMIT 10;

-- variant: late
-- sample: plan
SET debug_projection_placement = late;
SELECT topnbench_capture('placement-guard/volatile', 'late', 'unchanged', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random, random() FROM topnbench_data ORDER BY a_random LIMIT 10;

-- case: placement-guard/srf
-- check: unchanged
SET debug_projection_placement = auto;

-- variant: auto
-- sample: plan
SELECT topnbench_capture('placement-guard/srf', 'auto', 'unchanged', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random, generate_series(1,2) FROM topnbench_data ORDER BY a_random LIMIT 10;

-- variant: early
-- sample: plan
SET debug_projection_placement = early;
SELECT topnbench_capture('placement-guard/srf', 'early', 'unchanged', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random, generate_series(1,2) FROM topnbench_data ORDER BY a_random LIMIT 10;

-- variant: late
-- sample: plan
SET debug_projection_placement = late;
SELECT topnbench_capture('placement-guard/srf', 'late', 'unchanged', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT a_random, generate_series(1,2) FROM topnbench_data ORDER BY a_random LIMIT 10;

-- case: placement-guard/subquery
-- check: unchanged
SET debug_projection_placement = auto;

-- variant: auto
-- sample: plan
SELECT topnbench_capture('placement-guard/subquery', 'auto', 'unchanged', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT * FROM (SELECT a_random, topnbench_work_cost_1(a_random,16,1) AS e1 FROM topnbench_data ORDER BY a_random LIMIT 10) s;

-- variant: early
-- sample: plan
SET debug_projection_placement = early;
SELECT topnbench_capture('placement-guard/subquery', 'early', 'unchanged', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT * FROM (SELECT a_random, topnbench_work_cost_1(a_random,16,1) AS e1 FROM topnbench_data ORDER BY a_random LIMIT 10) s;

-- variant: late
-- sample: plan
SET debug_projection_placement = late;
SELECT topnbench_capture('placement-guard/subquery', 'late', 'unchanged', 'plan');
EXPLAIN (VERBOSE, FORMAT JSON)
SELECT * FROM (SELECT a_random, topnbench_work_cost_1(a_random,16,1) AS e1 FROM topnbench_data ORDER BY a_random LIMIT 10) s;

-- case: heap-release/ascending
-- check: heap
SET debug_projection_placement = auto;
SET work_mem = '64MB';

-- variant: datum
-- sample: diagnostic
SELECT topnbench_capture('heap-release/ascending', 'datum', 'heap', 'diagnostic');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k FROM topnbench_heap_ascending
ORDER BY k LIMIT 4096;

-- variant: tuple
-- sample: diagnostic
SELECT topnbench_capture('heap-release/ascending', 'tuple', 'heap', 'diagnostic');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, payload FROM topnbench_heap_ascending
ORDER BY k, payload LIMIT 4096;

-- case: heap-release/descending
-- check: heap

-- variant: datum
-- sample: diagnostic
SELECT topnbench_capture('heap-release/descending', 'datum', 'heap', 'diagnostic');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k FROM topnbench_heap_descending
ORDER BY k LIMIT 4096;

-- variant: tuple
-- sample: diagnostic
SELECT topnbench_capture('heap-release/descending', 'tuple', 'heap', 'diagnostic');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, payload FROM topnbench_heap_descending
ORDER BY k, payload LIMIT 4096;

-- case: heap-release/random
-- check: heap

-- variant: datum
-- sample: diagnostic
SELECT topnbench_capture('heap-release/random', 'datum', 'heap', 'diagnostic');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k FROM topnbench_heap_random
ORDER BY k LIMIT 4096;

-- variant: tuple
-- sample: diagnostic
SELECT topnbench_capture('heap-release/random', 'tuple', 'heap', 'diagnostic');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT k, payload FROM topnbench_heap_random
ORDER BY k, payload LIMIT 4096;

-- Close/flush the client file BEFORE importing it.
SELECT topnbench_capture_end();
\o
SELECT topnbench_file_reset();
-- One physical line per row; JSON backslashes and quotes remain unchanged.
\copy topnbench_file_lines(line) FROM 'topnbench-plans.log' WITH (FORMAT csv, DELIMITER E'\x01', QUOTE E'\x02')
SELECT topnbench_file_load();
\pset tuples_only off
\pset format aligned
SELECT * FROM topnbench_file_report();
SELECT * FROM topnbench_file_ratios();
SELECT * FROM topnbench_file_checks();
