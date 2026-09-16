\echo
\echo '== 0019: isolate radix dispatch with the same SQL and costs =='

-- Reuse six existing cells, not a new expression matrix.  On the reported
-- PG20 build: 25% at 4/16/24MB exercises external runs, 32/256MB supplies
-- heap negative controls, and 90% at 256MB exercises in-memory full sorting.
DROP VIEW IF EXISTS topnbench_algorithm_nodes;
DROP TABLE IF EXISTS topnbench_algorithm_plans;
DROP TABLE IF EXISTS topnbench_algorithm_runs;
DROP TABLE IF EXISTS topnbench_algorithm_cases;
CREATE TEMP TABLE topnbench_algorithm_cases AS
SELECT * FROM topnbench_boundary_cases
WHERE (case_name = 'cost-1-work-16' AND mem_no IN (1, 3, 4, 5, 6))
   OR (case_name = 'limit-90pct' AND mem_no = 6);
CREATE TEMP TABLE topnbench_algorithm_runs AS
SELECT 0::integer AS case_no, 0::integer AS mem_no, 0::integer AS batch,
       ''::text AS mode, r.*
FROM topnbench_compare('SELECT 1', 'SELECT 1', 'SELECT 1',
                      3, true, '4MB') r WITH NO DATA;
CREATE TEMP TABLE topnbench_algorithm_plans
    (case_no integer, mem_no integer, mode text, strategy text,
     estimated jsonb, actual jsonb,
     PRIMARY KEY (case_no, mem_no, mode, strategy));

DO $$
DECLARE
    c record;
    s record;
    b integer;
    m text;
    saved_plan jsonb;
BEGIN
    IF (SELECT count(*) FROM topnbench_algorithm_cases) <> 6 THEN
        RAISE EXCEPTION '0019 requires the six unchanged sort_boundary.sql cells';
    END IF;
    PERFORM set_config('enable_cost_based_delayed_projection', 'on', true);
    PERFORM set_config('enable_sort_tuple_width_cost', 'on', true);
    PERFORM set_config('enable_sort_datum_cost', 'on', true);
    PERFORM set_config('enable_projection_total_cost', 'on', true);
    PERFORM set_config('debug_print_projection_paths', 'off', true);
    PERFORM set_config('max_parallel_workers_per_gather', '0', true);
    PERFORM set_config('jit', 'off', true);
    PERFORM set_config('trace_sort', 'off', true);

    -- Both modes must receive identical plans and costs before execution.
    -- Omit SETTINGS: it intentionally differs between the two modes.
    FOR c IN SELECT * FROM topnbench_algorithm_cases ORDER BY case_no, mem_no LOOP
        PERFORM set_config('work_mem', c.work_mem_setting, true);
        FOREACH m IN ARRAY ARRAY['default', 'radix-disabled'] LOOP
            PERFORM set_config('debug_disable_sort_radix',
                               CASE m WHEN 'default' THEN 'off' ELSE 'on' END, true);
            FOR s IN SELECT * FROM (VALUES ('auto', c.auto_query),
                     ('late', c.manual_late_query), ('early', c.forced_early_query))
                     v(strategy, query) LOOP
                EXECUTE 'EXPLAIN (VERBOSE, COSTS ON, FORMAT JSON) ' || s.query INTO saved_plan;
                INSERT INTO topnbench_algorithm_plans
                VALUES (c.case_no, c.mem_no, m, s.strategy, saved_plan, NULL);
            END LOOP;
        END LOOP;
    END LOOP;
    IF EXISTS (
        SELECT FROM topnbench_algorithm_plans a JOIN topnbench_algorithm_plans b
        USING (case_no, mem_no, strategy)
        WHERE a.mode = 'default' AND b.mode = 'radix-disabled'
          AND a.estimated IS DISTINCT FROM b.estimated
    ) THEN
        RAISE EXCEPTION '0019 radix toggle changed a plan or its estimated costs';
    END IF;

    -- Four paired batches; reverse both cell and mode order.  The compare
    -- function rotates three forms and verifies their results in batch one.
    FOR b IN 1..4 LOOP
        FOR c IN SELECT * FROM topnbench_algorithm_cases
                 ORDER BY CASE WHEN b % 2 = 1 THEN case_no ELSE -case_no END,
                          CASE WHEN b % 2 = 1 THEN mem_no ELSE -mem_no END LOOP
            FOREACH m IN ARRAY CASE WHEN b % 2 = 1
                THEN ARRAY['default', 'radix-disabled']
                ELSE ARRAY['radix-disabled', 'default'] END LOOP
                PERFORM set_config('debug_disable_sort_radix',
                                   CASE m WHEN 'default' THEN 'off' ELSE 'on' END, true);
                INSERT INTO topnbench_algorithm_runs
                SELECT c.case_no, c.mem_no, b, m, r.*
                FROM topnbench_compare(c.auto_query, c.manual_late_query,
                                       c.forced_early_query, 3, b = 1,
                                       c.work_mem_setting) r;
            END LOOP;
        END LOOP;
    END LOOP;

    -- Trace only after ALL new timed batches finish.  An external sort may
    -- emit one dispatch per run; radix-entry is not a recursion counter.
    PERFORM set_config('client_min_messages', 'log', true);
    PERFORM set_config('trace_sort', 'on', true);
    FOR c IN SELECT * FROM topnbench_algorithm_cases ORDER BY case_no, mem_no LOOP
        PERFORM set_config('work_mem', c.work_mem_setting, true);
        FOREACH m IN ARRAY ARRAY['default', 'radix-disabled'] LOOP
            PERFORM set_config('debug_disable_sort_radix',
                               CASE m WHEN 'default' THEN 'off' ELSE 'on' END, true);
            FOR s IN SELECT * FROM (VALUES ('auto', c.auto_query),
                     ('late', c.manual_late_query), ('early', c.forced_early_query))
                     v(strategy, query) LOOP
                RAISE NOTICE '0019 BEGIN case=% work_mem=% mode=% strategy=%',
                             c.case_name, c.work_mem_setting, m, s.strategy;
                EXECUTE 'EXPLAIN (ANALYZE, VERBOSE, BUFFERS, COSTS ON, '
                        'TIMING OFF, SUMMARY ON, FORMAT JSON) ' || s.query INTO saved_plan;
                UPDATE topnbench_algorithm_plans SET actual = saved_plan
                WHERE case_no = c.case_no AND mem_no = c.mem_no
                  AND mode = m AND strategy = s.strategy;
                RAISE NOTICE '0019 END case=% work_mem=% mode=% strategy=%',
                             c.case_name, c.work_mem_setting, m, s.strategy;
            END LOOP;
        END LOOP;
    END LOOP;
END $$;

CREATE TEMP VIEW topnbench_algorithm_nodes AS
WITH RECURSIVE nodes(case_no, mem_no, mode, strategy, node) AS (
    SELECT case_no, mem_no, mode, strategy, actual->0->'Plan'
    FROM topnbench_algorithm_plans
    UNION ALL
    SELECT n.case_no, n.mem_no, n.mode, n.strategy, c.node
    FROM nodes n CROSS JOIN LATERAL jsonb_array_elements(n.node->'Plans') c(node)
)
SELECT * FROM nodes;

DO $$
DECLARE
    p record;
    s jsonb;
BEGIN
    IF (SELECT count(*) FROM topnbench_algorithm_runs) <> 48 OR
       EXISTS (SELECT FROM topnbench_algorithm_runs
               WHERE launched_workers IS DISTINCT FROM 0
                  OR planner_choice IS NULL OR planner_choice NOT IN ('early', 'late')) THEN
        RAISE EXCEPTION '0019 expected 48 serial, classified measurements';
    END IF;
    FOR p IN SELECT * FROM topnbench_algorithm_plans LOOP
        IF (SELECT count(*) FROM topnbench_algorithm_nodes n
            WHERE n.case_no = p.case_no AND n.mem_no = p.mem_no
              AND n.mode = p.mode AND n.strategy = p.strategy
              AND n.node->>'Node Type' IN ('Sort', 'Incremental Sort')) <> 1 THEN
            RAISE EXCEPTION '0019 expected one Sort: %, %, %, %',
                            p.case_no, p.mem_no, p.mode, p.strategy;
        END IF;
        SELECT n.node INTO STRICT s FROM topnbench_algorithm_nodes n
        WHERE n.case_no = p.case_no AND n.mem_no = p.mem_no
          AND n.mode = p.mode AND n.strategy = p.strategy
          AND n.node->>'Node Type' IN ('Sort', 'Incremental Sort');
        IF s->>'Node Type' IS DISTINCT FROM 'Sort' OR
           (s->>'Actual Loops')::numeric IS DISTINCT FROM 1 OR
           s->>'Sort Method' IS NULL OR
           (p.strategy = 'late' AND
            jsonb_array_length(s#>'{Plans,0,Output}') IS DISTINCT FROM 1) OR
           (p.strategy = 'early' AND
            coalesce(jsonb_array_length(s#>'{Plans,0,Output}'), 0) < 2) THEN
            RAISE EXCEPTION '0019 unexpected Sort shape: %, %, %, %',
                            p.case_no, p.mem_no, p.mode, p.strategy;
        END IF;
    END LOOP;
    IF EXISTS (
        SELECT FROM topnbench_algorithm_nodes a JOIN topnbench_algorithm_nodes b
        USING (case_no, mem_no, strategy)
        WHERE a.mode = 'default' AND b.mode = 'radix-disabled'
          AND a.node->>'Node Type' = 'Sort' AND b.node->>'Node Type' = 'Sort'
          AND (a.node->>'Sort Method' IS DISTINCT FROM b.node->>'Sort Method'
               OR a.node#>'{Plans,0,Actual Rows}' IS DISTINCT FROM b.node#>'{Plans,0,Actual Rows}')
    ) THEN
        RAISE EXCEPTION '0019 changed the Sort method category or input row count';
    END IF;
END $$;

\echo '== 0019 paired algorithm results: disabled/default, greater than 1 is slower =='
WITH pairs AS (
    SELECT a.case_no, a.mem_no, a.batch, a.planner_choice,
           a.auto_median_ms AS default_auto, b.auto_median_ms AS disabled_auto,
           a.manual_late_median_ms AS default_late, b.manual_late_median_ms AS disabled_late,
           a.forced_early_median_ms AS default_early, b.forced_early_median_ms AS disabled_early,
           b.auto_median_ms / nullif(a.auto_median_ms, 0) AS auto_ratio,
           b.manual_late_median_ms / nullif(a.manual_late_median_ms, 0) AS late_ratio,
           b.forced_early_median_ms / nullif(a.forced_early_median_ms, 0) AS early_ratio,
           a.actual_winner AS default_winner, b.actual_winner AS disabled_winner,
           a.manual_late_sort_method AS late_method, a.forced_early_sort_method AS early_method
    FROM topnbench_algorithm_runs a JOIN topnbench_algorithm_runs b
    USING (case_no, mem_no, batch)
    WHERE a.mode = 'default' AND b.mode = 'radix-disabled'
)
SELECT c.case_name, c.work_mem_setting,
       string_agg(DISTINCT p.planner_choice, '/') AS planner_choice,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY default_auto)::numeric, 3) AS default_auto_ms,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY disabled_auto)::numeric, 3) AS disabled_auto_ms,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY auto_ratio)::numeric, 3) AS auto_ratio,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY default_late)::numeric, 3) AS default_late_ms,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY disabled_late)::numeric, 3) AS disabled_late_ms,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY late_ratio)::numeric, 3) AS late_ratio,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY default_early)::numeric, 3) AS default_early_ms,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY disabled_early)::numeric, 3) AS disabled_early_ms,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY early_ratio)::numeric, 3) AS early_ratio,
       count(*) FILTER (WHERE auto_ratio < 0.95) AS faster_batches,
       count(*) FILTER (WHERE auto_ratio > 1.05) AS slower_batches,
       string_agg(DISTINCT default_winner, '/') AS default_winner,
       string_agg(DISTINCT disabled_winner, '/') AS disabled_winner,
       string_agg(DISTINCT late_method, '/') AS late_method,
       string_agg(DISTINCT early_method, '/') AS early_method
FROM pairs p JOIN topnbench_algorithm_cases c USING (case_no, mem_no)
GROUP BY c.case_no, c.mem_no, c.case_name, c.work_mem_setting ORDER BY c.case_no, c.mem_no;

\echo '== 0019 actual method categories; radix dispatch is in the BEGIN/END trace =='
SELECT c.case_name, c.work_mem_setting, n.mode, n.strategy,
       n.node->>'Sort Method' AS method, n.node->>'Sort Space Type' AS space_type,
       n.node->>'Sort Space Used' AS space_kb,
       n.node->>'Temp Read Blocks' AS temp_read, n.node->>'Temp Written Blocks' AS temp_written
FROM topnbench_algorithm_nodes n JOIN topnbench_algorithm_cases c USING (case_no, mem_no)
WHERE n.node->>'Node Type' = 'Sort' ORDER BY c.case_no, c.mem_no, n.mode, n.strategy;

-- Exact measurements remain available for follow-up analysis; no timing
-- assertions turn a noisy performance result into a correctness failure.
SELECT c.case_name, c.work_mem_setting, r.batch, r.mode, r.planner_choice,
       round(r.auto_median_ms::numeric, 3) AS auto_ms,
       round(r.manual_late_median_ms::numeric, 3) AS late_ms,
       round(r.forced_early_median_ms::numeric, 3) AS early_ms, r.actual_winner
FROM topnbench_algorithm_runs r JOIN topnbench_algorithm_cases c USING (case_no, mem_no)
ORDER BY c.case_no, c.mem_no, r.batch, r.mode;
