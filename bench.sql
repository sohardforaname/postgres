\set ON_ERROR_STOP 1
\timing on

SET max_parallel_workers_per_gather = 0;
SET client_min_messages = warning;
SET enable_mergejoin = off;
SET enable_nestloop = off;
SET enable_hashjoin = on;
\o /dev/null

\echo ''
\echo 'Benchmark hygiene: VACUUM FREEZE + CHECKPOINT after setup reduces dirty-buffer noise in the first measured query.'

\echo ''
\echo 'Case 1: int4 unique, hit-heavy, one-batch'
SET work_mem = '256MB';
SET hash_mem_multiplier = 2;
SELECT bench_setup_int4_unique(2000000, 2000000, 0.05);
VACUUM (FREEZE, ANALYZE) inner_unique_int4;
VACUUM (FREEZE, ANALYZE) outer_unique_int4;
CHECKPOINT;

SET enable_hashjoin_alt_table = off;
SELECT count(*) FROM outer_unique_int4 o JOIN inner_unique_int4 i USING (k);
SET enable_hashjoin_alt_table = on;
SELECT count(*) FROM outer_unique_int4 o JOIN inner_unique_int4 i USING (k);
SET enable_hashjoin_alt_table = off;
SELECT count(*) FROM outer_unique_int4 o JOIN inner_unique_int4 i USING (k);
SET enable_hashjoin_alt_table = on;
SELECT count(*) FROM outer_unique_int4 o JOIN inner_unique_int4 i USING (k);
SET enable_hashjoin_alt_table = off;
SELECT count(*) FROM outer_unique_int4 o JOIN inner_unique_int4 i USING (k);
SET enable_hashjoin_alt_table = on;
SELECT count(*) FROM outer_unique_int4 o JOIN inner_unique_int4 i USING (k);

\echo ''
\echo 'Case 2: int4 unique, missing-heavy, one-batch'
SELECT bench_setup_int4_unique(2000000, 2000000, 0.95);
VACUUM (FREEZE, ANALYZE) inner_unique_int4;
VACUUM (FREEZE, ANALYZE) outer_unique_int4;
CHECKPOINT;

SET enable_hashjoin_alt_table = off;
SELECT count(*) FROM outer_unique_int4 o JOIN inner_unique_int4 i USING (k);
SET enable_hashjoin_alt_table = on;
SELECT count(*) FROM outer_unique_int4 o JOIN inner_unique_int4 i USING (k);
SET enable_hashjoin_alt_table = off;
SELECT count(*) FROM outer_unique_int4 o JOIN inner_unique_int4 i USING (k);
SET enable_hashjoin_alt_table = on;
SELECT count(*) FROM outer_unique_int4 o JOIN inner_unique_int4 i USING (k);
SET enable_hashjoin_alt_table = off;
SELECT count(*) FROM outer_unique_int4 o JOIN inner_unique_int4 i USING (k);
SET enable_hashjoin_alt_table = on;
SELECT count(*) FROM outer_unique_int4 o JOIN inner_unique_int4 i USING (k);

\echo ''
\echo 'Case 3: int4 low-duplicate, hit-heavy, one-batch'
SELECT bench_setup_int4_dup(200000, 4, 2000000, 0.05);
VACUUM (FREEZE, ANALYZE) inner_dup_int4;
VACUUM (FREEZE, ANALYZE) outer_dup_int4;
CHECKPOINT;

SET enable_hashjoin_alt_table = off;
SELECT count(*) FROM outer_dup_int4 o JOIN inner_dup_int4 i USING (k);
SET enable_hashjoin_alt_table = on;
SELECT count(*) FROM outer_dup_int4 o JOIN inner_dup_int4 i USING (k);
SET enable_hashjoin_alt_table = off;
SELECT count(*) FROM outer_dup_int4 o JOIN inner_dup_int4 i USING (k);
SET enable_hashjoin_alt_table = on;
SELECT count(*) FROM outer_dup_int4 o JOIN inner_dup_int4 i USING (k);
SET enable_hashjoin_alt_table = off;
SELECT count(*) FROM outer_dup_int4 o JOIN inner_dup_int4 i USING (k);
SET enable_hashjoin_alt_table = on;
SELECT count(*) FROM outer_dup_int4 o JOIN inner_dup_int4 i USING (k);

\echo ''
\echo 'Case 4: int4 high-duplicate, hit-heavy, one-batch'
SELECT bench_setup_int4_dup(20000, 64, 2000000, 0.05);
VACUUM (FREEZE, ANALYZE) inner_dup_int4;
VACUUM (FREEZE, ANALYZE) outer_dup_int4;
CHECKPOINT;

SET enable_hashjoin_alt_table = off;
SELECT count(*) FROM outer_dup_int4 o JOIN inner_dup_int4 i USING (k);
SET enable_hashjoin_alt_table = on;
SELECT count(*) FROM outer_dup_int4 o JOIN inner_dup_int4 i USING (k);
SET enable_hashjoin_alt_table = off;
SELECT count(*) FROM outer_dup_int4 o JOIN inner_dup_int4 i USING (k);
SET enable_hashjoin_alt_table = on;
SELECT count(*) FROM outer_dup_int4 o JOIN inner_dup_int4 i USING (k);
SET enable_hashjoin_alt_table = off;
SELECT count(*) FROM outer_dup_int4 o JOIN inner_dup_int4 i USING (k);
SET enable_hashjoin_alt_table = on;
SELECT count(*) FROM outer_dup_int4 o JOIN inner_dup_int4 i USING (k);

\echo ''
\echo 'Case 5: int8 unique, missing-heavy, one-batch'
SELECT bench_setup_int8_unique(2000000, 2000000, 0.95);
VACUUM (FREEZE, ANALYZE) inner_unique_int8;
VACUUM (FREEZE, ANALYZE) outer_unique_int8;
CHECKPOINT;

SET enable_hashjoin_alt_table = off;
SELECT count(*) FROM outer_unique_int8 o JOIN inner_unique_int8 i USING (k);
SET enable_hashjoin_alt_table = on;
SELECT count(*) FROM outer_unique_int8 o JOIN inner_unique_int8 i USING (k);
SET enable_hashjoin_alt_table = off;
SELECT count(*) FROM outer_unique_int8 o JOIN inner_unique_int8 i USING (k);
SET enable_hashjoin_alt_table = on;
SELECT count(*) FROM outer_unique_int8 o JOIN inner_unique_int8 i USING (k);
SET enable_hashjoin_alt_table = off;
SELECT count(*) FROM outer_unique_int8 o JOIN inner_unique_int8 i USING (k);
SET enable_hashjoin_alt_table = on;
SELECT count(*) FROM outer_unique_int8 o JOIN inner_unique_int8 i USING (k);

\echo ''
\echo 'Case 6: text unique, missing-heavy, one-batch'
SELECT bench_setup_text_unique(200000, 200000, 0.95);
VACUUM (FREEZE, ANALYZE) inner_unique_text;
VACUUM (FREEZE, ANALYZE) outer_unique_text;
CHECKPOINT;

SET enable_hashjoin_alt_table = off;
SELECT count(*) FROM outer_unique_text o JOIN inner_unique_text i USING (k);
SET enable_hashjoin_alt_table = on;
SELECT count(*) FROM outer_unique_text o JOIN inner_unique_text i USING (k);
SET enable_hashjoin_alt_table = off;
SELECT count(*) FROM outer_unique_text o JOIN inner_unique_text i USING (k);
SET enable_hashjoin_alt_table = on;
SELECT count(*) FROM outer_unique_text o JOIN inner_unique_text i USING (k);
SET enable_hashjoin_alt_table = off;
SELECT count(*) FROM outer_unique_text o JOIN inner_unique_text i USING (k);
SET enable_hashjoin_alt_table = on;
SELECT count(*) FROM outer_unique_text o JOIN inner_unique_text i USING (k);

\echo ''
\echo 'Case 7: int4 skew, hot-hit-heavy, one-batch'
SET work_mem = '256MB';
SET hash_mem_multiplier = 2;
SELECT bench_setup_int4_skew(2000000, 2000000, 16, 0.80, 0.05);
VACUUM (FREEZE, ANALYZE) inner_skew_int4;
VACUUM (FREEZE, ANALYZE) outer_skew_int4;
CHECKPOINT;

SET enable_hashjoin_alt_table = off;
SELECT count(*) FROM outer_skew_int4 o JOIN inner_skew_int4 i USING (k);
SET enable_hashjoin_alt_table = on;
SELECT count(*) FROM outer_skew_int4 o JOIN inner_skew_int4 i USING (k);
SET enable_hashjoin_alt_table = off;
SELECT count(*) FROM outer_skew_int4 o JOIN inner_skew_int4 i USING (k);
SET enable_hashjoin_alt_table = on;
SELECT count(*) FROM outer_skew_int4 o JOIN inner_skew_int4 i USING (k);
SET enable_hashjoin_alt_table = off;
SELECT count(*) FROM outer_skew_int4 o JOIN inner_skew_int4 i USING (k);
SET enable_hashjoin_alt_table = on;
SELECT count(*) FROM outer_skew_int4 o JOIN inner_skew_int4 i USING (k);

\echo ''
\echo 'Case 8: int4 skew, hot-hit-heavy with misses, one-batch'
SELECT bench_setup_int4_skew(2000000, 2000000, 8, 0.90, 0.30);
VACUUM (FREEZE, ANALYZE) inner_skew_int4;
VACUUM (FREEZE, ANALYZE) outer_skew_int4;
CHECKPOINT;

SET enable_hashjoin_alt_table = off;
SELECT count(*) FROM outer_skew_int4 o JOIN inner_skew_int4 i USING (k);
SET enable_hashjoin_alt_table = on;
SELECT count(*) FROM outer_skew_int4 o JOIN inner_skew_int4 i USING (k);
SET enable_hashjoin_alt_table = off;
SELECT count(*) FROM outer_skew_int4 o JOIN inner_skew_int4 i USING (k);
SET enable_hashjoin_alt_table = on;
SELECT count(*) FROM outer_skew_int4 o JOIN inner_skew_int4 i USING (k);
SET enable_hashjoin_alt_table = off;
SELECT count(*) FROM outer_skew_int4 o JOIN inner_skew_int4 i USING (k);
SET enable_hashjoin_alt_table = on;
SELECT count(*) FROM outer_skew_int4 o JOIN inner_skew_int4 i USING (k);

\echo ''
\echo 'Case 9: text skew, one-batch'
SELECT bench_setup_text_skew(200000, 200000, 8, 0.85, 0.10);
VACUUM (FREEZE, ANALYZE) inner_skew_text;
VACUUM (FREEZE, ANALYZE) outer_skew_text;
CHECKPOINT;

SET enable_hashjoin_alt_table = off;
SELECT count(*) FROM outer_skew_text o JOIN inner_skew_text i USING (k);
SET enable_hashjoin_alt_table = on;
SELECT count(*) FROM outer_skew_text o JOIN inner_skew_text i USING (k);
SET enable_hashjoin_alt_table = off;
SELECT count(*) FROM outer_skew_text o JOIN inner_skew_text i USING (k);
SET enable_hashjoin_alt_table = on;
SELECT count(*) FROM outer_skew_text o JOIN inner_skew_text i USING (k);
SET enable_hashjoin_alt_table = off;
SELECT count(*) FROM outer_skew_text o JOIN inner_skew_text i USING (k);
SET enable_hashjoin_alt_table = on;
SELECT count(*) FROM outer_skew_text o JOIN inner_skew_text i USING (k);

\echo ''
\echo 'Case 10: forced multi-batch fallback'
SET work_mem = '64kB';
SET hash_mem_multiplier = 1;
SELECT bench_setup_int4_unique(2000000, 2000000, 0.05);
VACUUM (FREEZE, ANALYZE) inner_unique_int4;
VACUUM (FREEZE, ANALYZE) outer_unique_int4;
CHECKPOINT;

SET enable_hashjoin_alt_table = off;
SELECT count(*) FROM outer_unique_int4 o JOIN inner_unique_int4 i USING (k);
SET enable_hashjoin_alt_table = on;
SELECT count(*) FROM outer_unique_int4 o JOIN inner_unique_int4 i USING (k);
SET enable_hashjoin_alt_table = off;
SELECT count(*) FROM outer_unique_int4 o JOIN inner_unique_int4 i USING (k);
SET enable_hashjoin_alt_table = on;
SELECT count(*) FROM outer_unique_int4 o JOIN inner_unique_int4 i USING (k);
SET enable_hashjoin_alt_table = off;
SELECT count(*) FROM outer_unique_int4 o JOIN inner_unique_int4 i USING (k);
SET enable_hashjoin_alt_table = on;
SELECT count(*) FROM outer_unique_int4 o JOIN inner_unique_int4 i USING (k);