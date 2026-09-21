BEGIN;

SET LOCAL jit = off;
SET LOCAL work_mem = '32MB';
SET LOCAL enable_partitionwise_aggregate = on;
SET LOCAL enable_parallel_append = on;
SET LOCAL max_parallel_workers_per_gather = 2;
SET LOCAL min_parallel_table_scan_size = 0;
SET LOCAL min_parallel_index_scan_size = 0;
SET LOCAL parallel_setup_cost = 0;
SET LOCAL parallel_tuple_cost = 0;

-- 确认本次实际使用的配置。
SELECT name, setting, unit
FROM pg_settings
WHERE name IN (
    'jit',
    'work_mem',
    'enable_partitionwise_aggregate',
    'enable_parallel_append',
    'max_worker_processes',
    'max_parallel_workers',
    'max_parallel_workers_per_gather',
    'min_parallel_table_scan_size',
    'min_parallel_index_scan_size',
    'parallel_setup_cost',
    'parallel_tuple_cost'
)
ORDER BY name;

-- 1. IMMUTABLE 昂贵函数只出现在输出中。
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, SETTINGS, TIMING OFF)
SELECT bucket, id, sg_review.slow_i(payload)
FROM sg_review.part_heap
GROUP BY bucket, id;

-- 2. VOLATILE 昂贵函数只出现在输出中。
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, SETTINGS, TIMING OFF)
SELECT bucket, id, sg_review.slow_v(payload)
FROM sg_review.part_heap
GROUP BY bucket, id;

-- 3. 无 GROUP BY 的对照。
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, SETTINGS, TIMING OFF)
SELECT bucket, id, sg_review.slow_i(payload)
FROM sg_review.part_heap;

-- 4. 无 GROUP BY 的 VOLATILE 对照。
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, SETTINGS, TIMING OFF)
SELECT bucket, id, sg_review.slow_v(payload)
FROM sg_review.part_heap;

-- 5. 另一个候选：没有匹配索引顺序的排序。
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, SETTINGS, TIMING OFF)
SELECT bucket, id, rank_key
FROM sg_review.part_heap
GROUP BY bucket, id, rank_key
ORDER BY rank_key + 1;

ROLLBACK;