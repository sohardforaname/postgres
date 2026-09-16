\echo
\echo '== 0017: actual memory at sort-method transitions (not timed) =='

-- Run after sort_boundary.sql in the same session.  Reuse its exact queries
-- and estimates; this phase does not add another timing matrix or cost model.
DROP VIEW IF EXISTS topnbench_memory_nodes;
DROP TABLE IF EXISTS topnbench_memory_plans;
CREATE TEMP TABLE topnbench_memory_plans
    (case_no integer, mem_no integer, strategy text, plan jsonb,
     PRIMARY KEY (case_no, mem_no, strategy));

DO $$
DECLARE
    c record;
    s record;
    saved_plan jsonb;
BEGIN
    IF (SELECT count(*) FROM topnbench_boundary_cases) <> 12 OR
       (SELECT count(*) FROM topnbench_boundary_runs) <> 96 OR
       (SELECT count(*) FROM topnbench_boundary_plans) <> 72 THEN
        RAISE EXCEPTION '0017 requires the completed 0016 boundary phase';
    END IF;
    PERFORM set_config('enable_cost_based_delayed_projection', 'on', true);
    PERFORM set_config('enable_sort_tuple_width_cost', 'on', true);
    PERFORM set_config('enable_sort_datum_cost', 'on', true);
    PERFORM set_config('enable_projection_total_cost', 'on', true);
    PERFORM set_config('debug_print_projection_paths', 'off', true);
    PERFORM set_config('max_parallel_workers_per_gather', '0', true);
    PERFORM set_config('jit', 'off', true);
    PERFORM set_config('client_min_messages', 'log', true);
    PERFORM set_config('trace_sort', 'off', true);

    FOR c IN SELECT * FROM topnbench_boundary_cases ORDER BY case_no, mem_no LOOP
        PERFORM set_config('work_mem', c.work_mem_setting, true);
        FOR s IN SELECT * FROM (VALUES ('late', c.manual_late_query),
                                       ('early', c.forced_early_query))
                               v(strategy, query) LOOP
            RAISE NOTICE '0017 BEGIN case=% work_mem=% strategy=%',
                         c.case_name, c.work_mem_setting, s.strategy;
            -- Trace only the target query, not SQL used to assemble reports.
            PERFORM set_config('trace_sort', 'on', true);
            EXECUTE 'EXPLAIN (ANALYZE, VERBOSE, BUFFERS, COSTS ON, '
                    'TIMING OFF, SUMMARY ON, FORMAT JSON) ' || s.query INTO saved_plan;
            PERFORM set_config('trace_sort', 'off', true);
            RAISE NOTICE '0017 END case=% work_mem=% strategy=%',
                         c.case_name, c.work_mem_setting, s.strategy;
            INSERT INTO topnbench_memory_plans
            VALUES (c.case_no, c.mem_no, s.strategy, saved_plan);
        END LOOP;
    END LOOP;
END $$;

CREATE TEMP VIEW topnbench_memory_nodes AS
WITH RECURSIVE nodes(case_no, mem_no, strategy, node) AS (
    SELECT case_no, mem_no, strategy, plan->0->'Plan'
    FROM topnbench_memory_plans
    UNION ALL
    SELECT n.case_no, n.mem_no, n.strategy, c.node
    FROM nodes n CROSS JOIN LATERAL jsonb_array_elements(n.node->'Plans') c(node)
)
SELECT * FROM nodes;

DO $$
DECLARE
    p record;
    s jsonb;
BEGIN
    IF (SELECT count(*) FROM topnbench_memory_plans) <> 24 OR
       EXISTS (SELECT FROM topnbench_memory_nodes
               WHERE node->>'Node Type' IN ('Gather', 'Gather Merge')) THEN
        RAISE EXCEPTION '0017 expected 24 serial diagnostic plans';
    END IF;
    FOR p IN SELECT * FROM topnbench_memory_plans LOOP
        IF (SELECT count(*) FROM topnbench_memory_nodes n
            WHERE n.case_no = p.case_no AND n.mem_no = p.mem_no
              AND n.strategy = p.strategy
              AND n.node->>'Node Type' IN ('Sort', 'Incremental Sort')) <> 1 THEN
            RAISE EXCEPTION '0017 expected one Sort: %, %, %',
                            p.case_no, p.mem_no, p.strategy;
        END IF;
        SELECT n.node INTO STRICT s FROM topnbench_memory_nodes n
        WHERE n.case_no = p.case_no AND n.mem_no = p.mem_no
          AND n.strategy = p.strategy
          AND n.node->>'Node Type' IN ('Sort', 'Incremental Sort');
        IF s->>'Node Type' IS DISTINCT FROM 'Sort' OR
           (s->>'Actual Loops')::numeric IS DISTINCT FROM 1 OR
           (p.strategy = 'late' AND
            jsonb_array_length(s#>'{Plans,0,Output}') IS DISTINCT FROM 1) OR
           (p.strategy = 'early' AND
            coalesce(jsonb_array_length(s#>'{Plans,0,Output}'), 0) < 2) THEN
            RAISE EXCEPTION '0017 unexpected Sort shape: %, %, %',
                            p.case_no, p.mem_no, p.strategy;
        END IF;
    END LOOP;
END $$;

\echo '== 0017 estimates versus observed space; transition details are in sort memory logs =='
-- The 0016 proxy remains an estimate. Disk space is not memory consumption;
-- memory fields below stay NULL for an external sort. Trace lines supply the
-- actual pre-spill accounting, which EXPLAIN does not retain for disk sorts.
SELECT c.case_name, c.work_mem_setting, n.strategy,
       n.node->>'Plan Width' AS estimated_width,
       n.node#>>'{Plans,0,Actual Rows}' AS actual_input_rows,
       round(b.model_retained_bytes::numeric / 1048576, 2) AS model_retained_mb,
       b.predicted_method,
       n.node->>'Sort Method' AS observed_method,
       b.predicted_method = n.node->>'Sort Method' AS method_matches,
       b.observed_method = n.node->>'Sort Method' AS same_method_as_0016,
       CASE WHEN n.node->>'Sort Space Type' = 'Memory'
            THEN round((n.node->>'Sort Space Used')::numeric / 1024, 2)
       END AS observed_memory_mb,
       CASE WHEN n.node->>'Sort Space Type' = 'Disk'
            THEN round((n.node->>'Sort Space Used')::numeric / 1024, 2)
       END AS observed_disk_mb,
       n.node->>'Temp Read Blocks' AS temp_read,
       n.node->>'Temp Written Blocks' AS temp_written
FROM topnbench_memory_nodes n
JOIN topnbench_boundary_cases c USING (case_no, mem_no)
JOIN topnbench_boundary_sorts b USING (case_no, mem_no, strategy)
WHERE n.node->>'Node Type' = 'Sort' AND b.policy = '0015'
ORDER BY c.case_no, c.mem_no, n.strategy;

\echo '0017 complete. Each BEGIN/END block should contain a sort memory: transition= line.'
\echo 'If those lines are absent, check that the patched backend was installed and restarted.'
