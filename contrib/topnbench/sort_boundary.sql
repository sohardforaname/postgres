\echo
\echo '== 0016: fixed queries across work_mem boundaries =='

-- Reuse final_cost.sql's exact queries.  Only work_mem and the Datum costing
-- switch vary; both policies retain the same tuple-width/final-total rules.
DROP VIEW IF EXISTS topnbench_boundary_sorts;
DROP VIEW IF EXISTS topnbench_boundary_nodes;
DROP TABLE IF EXISTS topnbench_boundary_plans;
DROP TABLE IF EXISTS topnbench_boundary_runs;
DROP TABLE IF EXISTS topnbench_boundary_cases;
CREATE TEMP TABLE topnbench_boundary_cases AS
SELECT c.case_no, c.case_name, c.limit_rows, c.offset_rows,
       c.auto_query, c.manual_late_query, c.forced_early_query,
       m.mem_no, m.work_mem_setting
FROM topnbench_final_cases c
CROSS JOIN (VALUES (1, '4MB'), (2, '8MB'), (3, '16MB'),
                   (4, '24MB'), (5, '32MB'), (6, '256MB')) m(mem_no, work_mem_setting)
WHERE c.case_name IN ('cost-1-work-16', 'limit-90pct');

CREATE TEMP TABLE topnbench_boundary_runs AS
SELECT 0::integer AS case_no, 0::integer AS mem_no, 0::integer AS batch,
       ''::text AS policy, r.*
FROM topnbench_compare('SELECT 1', 'SELECT 1', 'SELECT 1',
                      3, true, '4MB') r WITH NO DATA;
CREATE TEMP TABLE topnbench_boundary_plans
    (case_no integer, mem_no integer, policy text, strategy text, plan jsonb,
     PRIMARY KEY (case_no, mem_no, policy, strategy));

DO $$
DECLARE
    c record;
    s record;
    b integer;
    p text;
    saved_plan jsonb;
BEGIN
    IF (SELECT count(*) FROM topnbench_boundary_cases) <> 12 OR
       (SELECT count(DISTINCT case_name) FROM topnbench_boundary_cases) <> 2 OR
       EXISTS (SELECT FROM topnbench_boundary_cases
               WHERE offset_rows <> 0 OR limit_rows <= 0) THEN
        RAISE EXCEPTION '0016 requires the two unchanged final_cost.sql cases';
    END IF;
    IF (SELECT atttypid FROM pg_attribute WHERE attrelid = 'topnbench_data'::regclass
        AND attname = 'a_random' AND NOT attisdropped) IS DISTINCT FROM 'int4'::regtype THEN
        RAISE EXCEPTION '0016 expects the existing int4 sort key';
    END IF;
    PERFORM set_config('enable_cost_based_delayed_projection', 'on', true);
    PERFORM set_config('enable_sort_tuple_width_cost', 'on', true);
    PERFORM set_config('enable_projection_total_cost', 'on', true);
    PERFORM set_config('debug_print_projection_paths', 'off', true);
    PERFORM set_config('max_parallel_workers_per_gather', '0', true);
    PERFORM set_config('jit', 'off', true);

    -- Reverse cell order and alternate policy order between batches.  Each
    -- policy runs first twice; topnbench_compare rotates the three forms.
    FOR b IN 1..4 LOOP
        FOR c IN SELECT * FROM topnbench_boundary_cases
                 ORDER BY CASE WHEN b % 2 = 1 THEN case_no ELSE -case_no END,
                          CASE WHEN b % 2 = 1 THEN mem_no ELSE -mem_no END LOOP
            FOREACH p IN ARRAY CASE WHEN b % 2 = 1
                THEN ARRAY['0014', '0015'] ELSE ARRAY['0015', '0014'] END LOOP
                PERFORM set_config('enable_sort_datum_cost',
                                   CASE p WHEN '0015' THEN 'on' ELSE 'off' END, true);
                INSERT INTO topnbench_boundary_runs
                SELECT c.case_no, c.mem_no, b, p, r.*
                FROM topnbench_compare(c.auto_query, c.manual_late_query,
                                       c.forced_early_query, 3, b = 1,
                                       c.work_mem_setting) r;
            END LOOP;
        END LOOP;
    END LOOP;

    -- ALL timed batches finish before these instrumented diagnostic runs.
    -- Store both policies and all three forms, including full actual plans.
    FOR c IN SELECT * FROM topnbench_boundary_cases ORDER BY case_no, mem_no LOOP
        PERFORM set_config('work_mem', c.work_mem_setting, true);
        FOREACH p IN ARRAY ARRAY['0014', '0015'] LOOP
            PERFORM set_config('enable_sort_datum_cost',
                               CASE p WHEN '0015' THEN 'on' ELSE 'off' END, true);
            FOR s IN SELECT * FROM (VALUES ('auto', c.auto_query),
                     ('late', c.manual_late_query), ('early', c.forced_early_query))
                     v(strategy, query) LOOP
                EXECUTE 'EXPLAIN (ANALYZE, VERBOSE, BUFFERS, COSTS ON, '
                        'TIMING OFF, SUMMARY ON, FORMAT JSON) ' || s.query INTO saved_plan;
                INSERT INTO topnbench_boundary_plans
                VALUES (c.case_no, c.mem_no, p, s.strategy, saved_plan);
            END LOOP;
        END LOOP;
    END LOOP;
END $$;

CREATE TEMP VIEW topnbench_boundary_nodes AS
WITH RECURSIVE nodes(case_no, mem_no, policy, strategy, node_path, node) AS (
    SELECT case_no, mem_no, policy, strategy, ARRAY[0], plan->0->'Plan'
    FROM topnbench_boundary_plans
    UNION ALL
    SELECT n.case_no, n.mem_no, n.policy, n.strategy,
           n.node_path || c.ordinality::integer, c.node
    FROM nodes n CROSS JOIN LATERAL jsonb_array_elements(n.node->'Plans')
        WITH ORDINALITY c(node, ordinality)
)
SELECT * FROM nodes;

-- Ensure the size proxy below is applied only to the intended serial Sorts.
-- Do not assert the observed sorting algorithm: disagreement is a result.
DO $$
DECLARE
    p record;
    s jsonb;
BEGIN
    IF EXISTS (SELECT FROM topnbench_boundary_runs
               WHERE launched_workers <> 0 OR planner_choice NOT IN ('early', 'late')
                  OR planner_choice IS NULL) THEN
        RAISE EXCEPTION 'Unexpected parallel or unclassified boundary measurement';
    END IF;
    FOR p IN SELECT * FROM topnbench_boundary_plans LOOP
        IF (SELECT count(*) FROM topnbench_boundary_nodes n
            WHERE n.case_no = p.case_no AND n.mem_no = p.mem_no
              AND n.policy = p.policy AND n.strategy = p.strategy
              AND n.node->>'Node Type' IN ('Sort', 'Incremental Sort')) <> 1 THEN
            RAISE EXCEPTION 'Expected one Sort: case %, memory %, %, %',
                            p.case_no, p.mem_no, p.policy, p.strategy;
        END IF;
        SELECT n.node INTO STRICT s FROM topnbench_boundary_nodes n
        WHERE n.case_no = p.case_no AND n.mem_no = p.mem_no
          AND n.policy = p.policy AND n.strategy = p.strategy
          AND n.node->>'Node Type' IN ('Sort', 'Incremental Sort');
        IF s->>'Node Type' IS DISTINCT FROM 'Sort' OR
           (s->>'Actual Loops')::numeric IS DISTINCT FROM 1 OR
           (p.strategy = 'late' AND
            jsonb_array_length(s#>'{Plans,0,Output}') IS DISTINCT FROM 1) OR
           (p.strategy = 'early' AND
            coalesce(jsonb_array_length(s#>'{Plans,0,Output}'), 0) < 2) THEN
            RAISE EXCEPTION 'Unexpected boundary Sort shape: %, %, %, %',
                            p.case_no, p.mem_no, p.policy, p.strategy;
        END IF;
    END LOOP;
END $$;

-- Replay ONLY the sort-method branch of the current 0014/0015 cost model.
-- These are model bytes, not measured memory.  64-bit layout assumptions:
-- MAXALIGN=8, aligned HeapTupleHeader=24, SortTuple=24, Datum+tape length=12.
-- The one-column input in these fixed queries is the int4 key verified above.
-- No inferred branch is reported for an unrecognized server layout. Array
-- growth slack, tape buffers and the executor's online heap transition are
-- intentionally not simulated. Do not fit CPU coefficients from this proxy.
CREATE TEMP VIEW topnbench_boundary_sorts AS
WITH inputs AS (
    SELECT n.*, c.case_name, c.limit_rows, c.work_mem_setting,
           greatest((n.node->>'Plan Rows')::double precision, 2) AS model_rows,
           pg_size_bytes(c.work_mem_setting)::double precision AS memory_budget,
           jsonb_array_length(n.node#>'{Plans,0,Output}') AS input_columns,
           CASE WHEN version() LIKE '% on x86_64-%64-bit%' THEN
               CASE WHEN n.policy = '0015' AND
                              jsonb_array_length(n.node#>'{Plans,0,Output}') = 1
                    THEN 24.0 ELSE ceil((n.node->>'Plan Width')::numeric / 8) * 8 + 24 END
           END AS model_row_bytes
    FROM topnbench_boundary_nodes n JOIN topnbench_boundary_cases c USING (case_no, mem_no)
    WHERE n.node->>'Node Type' = 'Sort'
), sizes AS (
    SELECT *, model_rows * model_row_bytes AS model_input_bytes,
           least(model_rows, limit_rows) * model_row_bytes AS model_retained_bytes,
           model_rows * CASE WHEN model_row_bytes IS NULL THEN NULL
                            WHEN policy = '0015' AND input_columns = 1
                            THEN 12.0 ELSE model_row_bytes END AS model_tape_bytes
    FROM inputs
), methods AS (
    SELECT *, CASE WHEN model_row_bytes IS NULL THEN NULL
              WHEN model_retained_bytes > memory_budget THEN 'external merge'
              WHEN model_rows > 2 * least(model_rows, limit_rows)
                   OR model_input_bytes > memory_budget THEN 'top-N heapsort'
              ELSE 'quicksort' END AS predicted_method
    FROM sizes
)
SELECT *, node->>'Sort Method' AS observed_method,
       predicted_method = node->>'Sort Method' AS method_matches
FROM methods;

\echo '== 0016 paired policy results: same SQL, varying work_mem =='
WITH pairs AS (
    SELECT o.case_no, o.mem_no, o.batch,
           o.planner_choice AS old_choice, n.planner_choice AS new_choice,
           o.auto_median_ms AS old_ms, n.auto_median_ms AS new_ms,
           n.auto_median_ms / nullif(o.auto_median_ms, 0) AS ratio,
           n.manual_late_median_ms AS late_ms, n.forced_early_median_ms AS early_ms,
           n.actual_winner, n.planner_choice_correct,
           n.sort_method, n.manual_late_sort_method, n.forced_early_sort_method
    FROM topnbench_boundary_runs o JOIN topnbench_boundary_runs n
      USING (case_no, mem_no, batch)
    WHERE o.policy = '0014' AND n.policy = '0015'
)
SELECT c.case_name, c.work_mem_setting,
       string_agg(DISTINCT p.old_choice, '/') AS choice_0014,
       string_agg(DISTINCT p.new_choice, '/') AS choice_0015,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY p.old_ms)::numeric, 3) AS ms_0014,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY p.new_ms)::numeric, 3) AS ms_0015,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY p.ratio)::numeric, 3) AS new_vs_old,
       count(*) FILTER (WHERE p.ratio < 0.95) AS faster_batches,
       count(*) FILTER (WHERE p.ratio > 1.05) AS slower_batches,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY p.late_ms)::numeric, 3) AS late_ms,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY p.early_ms)::numeric, 3) AS early_ms,
       string_agg(DISTINCT p.actual_winner, '/') AS actual_winners,
       count(*) FILTER (WHERE p.planner_choice_correct = false) AS wrong_batches,
       string_agg(DISTINCT p.sort_method, '/') AS auto_methods,
       string_agg(DISTINCT p.manual_late_sort_method, '/') AS late_methods,
       string_agg(DISTINCT p.forced_early_sort_method, '/') AS early_methods
FROM pairs p JOIN topnbench_boundary_cases c USING (case_no, mem_no)
GROUP BY c.case_no, c.mem_no, c.case_name, c.work_mem_setting ORDER BY c.case_no, c.mem_no;

\if :topnbench_verbose
\echo '== 0016 predicted versus observed Sort branch (diagnostic executions) =='
SELECT case_name, work_mem_setting, policy, strategy, input_columns,
       node->>'Plan Rows' AS estimated_rows, node#>>'{Plans,0,Actual Rows}' AS actual_input_rows,
       node->>'Plan Width' AS estimated_width,
       round(model_input_bytes::numeric / 1048576, 2) AS model_input_mb,
       round(model_retained_bytes::numeric / 1048576, 2) AS model_retained_mb,
       round(model_tape_bytes::numeric / 1048576, 2) AS model_tape_mb,
       predicted_method, observed_method, method_matches,
       node->>'Sort Space Type' AS space_type, node->>'Sort Space Used' AS space_kb,
       node->>'Temp Read Blocks' AS temp_read, node->>'Temp Written Blocks' AS temp_written
FROM topnbench_boundary_sorts ORDER BY case_no, mem_no, policy, strategy;

\echo '== 0016 individual paired batches and surviving candidate costs =='
SELECT c.case_name, c.work_mem_setting, o.batch,
       o.planner_choice AS choice_0014, n.planner_choice AS choice_0015,
       round(o.auto_median_ms::numeric, 3) AS ms_0014,
       round(n.auto_median_ms::numeric, 3) AS ms_0015,
       round((n.auto_median_ms / nullif(o.auto_median_ms, 0))::numeric, 3) AS new_vs_old,
       round(o.early_limit_cost::numeric, 3) AS early_cost_0014,
       round(o.late_limit_cost::numeric, 3) AS late_cost_0014,
       round(n.early_limit_cost::numeric, 3) AS early_cost_0015,
       round(n.late_limit_cost::numeric, 3) AS late_cost_0015
FROM topnbench_boundary_runs o JOIN topnbench_boundary_runs n USING (case_no, mem_no, batch)
JOIN topnbench_boundary_cases c USING (case_no, mem_no)
WHERE o.policy = '0014' AND n.policy = '0015' ORDER BY c.case_no, c.mem_no, o.batch;

-- Preserve exact reproduction SQL without repeating it for every memory cell.
SELECT DISTINCT case_name, limit_rows, auto_query, manual_late_query, forced_early_query
FROM topnbench_boundary_cases ORDER BY case_name;

\endif
