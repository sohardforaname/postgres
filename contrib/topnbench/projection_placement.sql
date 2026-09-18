\echo
\echo '== 0020: same natural SQL, auto versus early-only versus late-only =='

DROP VIEW IF EXISTS topnbench_placement_nodes;
DROP TABLE IF EXISTS topnbench_placement_plans;
DROP TABLE IF EXISTS topnbench_placement_runs;
DROP TABLE IF EXISTS topnbench_placement_cases;
CREATE TEMP TABLE topnbench_placement_cases AS
SELECT * FROM topnbench_boundary_cases
WHERE case_name = 'cost-1-work-16'
   OR (case_name = 'limit-90pct' AND mem_no = 6);
CREATE TEMP TABLE topnbench_placement_runs AS
SELECT 0::integer AS case_no, 0::integer AS mem_no, 0::integer AS batch,
       ''::text AS mode, r.*
FROM topnbench_measure('SELECT 1', 3, '4MB') r WITH NO DATA;
CREATE TEMP TABLE topnbench_placement_plans
    (case_no integer, mem_no integer, mode text, estimated jsonb, actual jsonb,
     PRIMARY KEY (case_no, mem_no, mode));

DO $$
DECLARE
    c record;
    m text;
    modes text[] := ARRAY['auto', 'early', 'late'];
    b integer;
    saved_plan jsonb;
    verify_plan jsonb;
    equal_results boolean;
    target_table text;
BEGIN
    IF (SELECT count(*) FROM topnbench_placement_cases) <> 7 THEN
        RAISE EXCEPTION '0020 requires seven existing boundary cells';
    END IF;
    PERFORM set_config('enable_cost_based_delayed_projection', 'on', true);
    PERFORM set_config('enable_sort_tuple_width_cost', 'on', true);
    PERFORM set_config('enable_sort_datum_cost', 'on', true);
    PERFORM set_config('enable_projection_total_cost', 'on', true);
    PERFORM set_config('debug_disable_sort_radix', 'off', true);
    PERFORM set_config('debug_print_projection_paths', 'off', true);
    PERFORM set_config('trace_sort', 'off', true);
    PERFORM set_config('max_parallel_workers_per_gather', '0', true);
    PERFORM set_config('jit', 'off', true);

    -- Excluded query shapes must retain their exact plans in every mode.
    FOR c IN SELECT * FROM (VALUES
        ('unbounded', 'SELECT a_random, a_random + 1 FROM topnbench_data ORDER BY a_random'),
        ('volatile', 'SELECT a_random, random() FROM topnbench_data ORDER BY a_random LIMIT 10'),
        ('srf', 'SELECT a_random, generate_series(1, 2) FROM topnbench_data ORDER BY a_random LIMIT 10'),
        ('subquery', 'SELECT * FROM (SELECT a_random, a_random + 1 AS v FROM topnbench_data ORDER BY a_random LIMIT 10) s OFFSET 0')
    ) v(name, query) LOOP
        PERFORM set_config('debug_projection_placement', 'auto', true);
        EXECUTE 'EXPLAIN (VERBOSE, COSTS ON, FORMAT JSON) ' || c.query INTO saved_plan;
        FOREACH m IN ARRAY ARRAY['early', 'late'] LOOP
            PERFORM set_config('debug_projection_placement', m, true);
            EXECUTE 'EXPLAIN (VERBOSE, COSTS ON, FORMAT JSON) ' || c.query INTO verify_plan;
            IF saved_plan IS DISTINCT FROM verify_plan THEN
                RAISE EXCEPTION '0020 switch changed excluded shape: %, %', c.name, m;
            END IF;
        END LOOP;
    END LOOP;

    -- Execute each complete SELECT at top level under its own placement.
    -- Comparing rewritten subqueries would bypass the top-level-only switch.
    -- CTAS preserves that planner scope; require the identical root plan.
    FOR c IN SELECT * FROM topnbench_placement_cases ORDER BY case_no, mem_no LOOP
        PERFORM set_config('work_mem', c.work_mem_setting, true);
        FOREACH m IN ARRAY modes LOOP
            PERFORM set_config('debug_projection_placement', m, true);
            EXECUTE 'EXPLAIN (VERBOSE, COSTS ON, FORMAT JSON) ' || c.auto_query INTO saved_plan;
            target_table := CASE m WHEN 'auto' THEN 'topnbench_placement_reference'
                                 ELSE 'topnbench_placement_check' END;
            EXECUTE 'EXPLAIN (VERBOSE, COSTS ON, FORMAT JSON) CREATE TEMP TABLE ' ||
                    target_table || ' ON COMMIT DROP AS ' || c.auto_query INTO verify_plan;
            IF saved_plan->0->'Plan' IS DISTINCT FROM verify_plan->0->'Plan' THEN
                RAISE EXCEPTION '0020 verification changed the planned SELECT: %, %, %',
                                c.case_name, c.work_mem_setting, m;
            END IF;
            EXECUTE 'CREATE TEMP TABLE ' || target_table ||
                    ' ON COMMIT DROP AS ' || c.auto_query;
            IF m <> 'auto' THEN
                SELECT NOT EXISTS (
                    (TABLE topnbench_placement_reference EXCEPT ALL TABLE topnbench_placement_check)
                    UNION ALL
                    (TABLE topnbench_placement_check EXCEPT ALL TABLE topnbench_placement_reference)
                ) INTO equal_results;
                IF NOT equal_results THEN
                    RAISE EXCEPTION '0020 placements returned different rows: %, %, %',
                                    c.case_name, c.work_mem_setting, m;
                END IF;
                DROP TABLE topnbench_placement_check;
            END IF;
            INSERT INTO topnbench_placement_plans
            VALUES (c.case_no, c.mem_no, m, saved_plan, NULL);
        END LOOP;
        DROP TABLE topnbench_placement_reference;
    END LOOP;

    -- Six batches balance all six mode orders. Reverse cell order too.
    -- topnbench_measure executes exactly c.auto_query in every mode.
    FOR b IN 1..6 LOOP
        modes := CASE b
            WHEN 1 THEN ARRAY['auto', 'early', 'late']
            WHEN 2 THEN ARRAY['late', 'early', 'auto']
            WHEN 3 THEN ARRAY['early', 'late', 'auto']
            WHEN 4 THEN ARRAY['auto', 'late', 'early']
            WHEN 5 THEN ARRAY['late', 'auto', 'early']
            ELSE ARRAY['early', 'auto', 'late'] END;
        FOR c IN SELECT * FROM topnbench_placement_cases
                 ORDER BY CASE WHEN b % 2 = 1 THEN case_no ELSE -case_no END,
                          CASE WHEN b % 2 = 1 THEN mem_no ELSE -mem_no END LOOP
            FOREACH m IN ARRAY modes LOOP
                PERFORM set_config('debug_projection_placement', m, true);
                INSERT INTO topnbench_placement_runs
                SELECT c.case_no, c.mem_no, b, m, r.*
                FROM topnbench_measure(c.auto_query, 3, c.work_mem_setting) r;
            END LOOP;
        END LOOP;
    END LOOP;

    -- Actual plans are collected after timing; full JSON remains in TEMP.
    FOR c IN SELECT * FROM topnbench_placement_cases ORDER BY case_no, mem_no LOOP
        PERFORM set_config('work_mem', c.work_mem_setting, true);
        FOREACH m IN ARRAY ARRAY['auto', 'early', 'late'] LOOP
            PERFORM set_config('debug_projection_placement', m, true);
            EXECUTE 'EXPLAIN (ANALYZE, VERBOSE, BUFFERS, COSTS ON, '
                    'TIMING OFF, FORMAT JSON) ' || c.auto_query INTO saved_plan;
            UPDATE topnbench_placement_plans SET actual = saved_plan
            WHERE case_no = c.case_no AND mem_no = c.mem_no AND mode = m;
        END LOOP;
    END LOOP;
END $$;

CREATE TEMP VIEW topnbench_placement_nodes AS
WITH RECURSIVE nodes(case_no, mem_no, mode, node) AS (
    SELECT case_no, mem_no, mode, actual->0->'Plan' FROM topnbench_placement_plans
    UNION ALL
    SELECT n.case_no, n.mem_no, n.mode, c.node
    FROM nodes n CROSS JOIN LATERAL jsonb_array_elements(n.node->'Plans') c(node)
)
SELECT * FROM nodes;

DO $$
DECLARE
    p record;
    s jsonb;
BEGIN
    IF (SELECT count(*) FROM topnbench_placement_runs) <> 126 OR
       EXISTS (SELECT FROM topnbench_placement_runs WHERE launched_workers IS DISTINCT FROM 0) THEN
        RAISE EXCEPTION '0020 expected 126 serial natural-query measurements';
    END IF;
    FOR p IN SELECT * FROM topnbench_placement_plans LOOP
        IF (SELECT count(*) FROM topnbench_placement_nodes n
            WHERE n.case_no = p.case_no AND n.mem_no = p.mem_no AND n.mode = p.mode
              AND n.node->>'Node Type' IN ('Sort', 'Incremental Sort')) <> 1 THEN
            RAISE EXCEPTION '0020 expected one full Sort: %, %, %', p.case_no, p.mem_no, p.mode;
        END IF;
        SELECT node INTO STRICT s FROM topnbench_placement_nodes n
        WHERE n.case_no = p.case_no AND n.mem_no = p.mem_no AND n.mode = p.mode
          AND n.node->>'Node Type' IN ('Sort', 'Incremental Sort');
        IF s->>'Node Type' IS DISTINCT FROM 'Sort' OR
           (s->>'Actual Loops')::numeric IS DISTINCT FROM 1 OR
           jsonb_array_length(s->'Sort Key') IS DISTINCT FROM 1 OR
           s#>>'{Plans,0,Node Type}' IS DISTINCT FROM 'Seq Scan' OR
           (s#>>'{Plans,0,Actual Rows}')::numeric IS DISTINCT FROM 1000000 OR
           (p.mode = 'early' AND coalesce(jsonb_array_length(s#>'{Plans,0,Output}'), 0) < 2) OR
           (p.mode = 'late' AND jsonb_array_length(s#>'{Plans,0,Output}') IS DISTINCT FROM 1) THEN
            RAISE EXCEPTION '0020 placement/key/input guard failed: %, %, %', p.case_no, p.mem_no, p.mode;
        END IF;
    END LOOP;
END $$;

\echo '== 0020 natural placement costs and timings (six paired batches) =='
WITH pairs AS (
    SELECT a.case_no, a.mem_no, a.batch, a.median_ms AS auto_ms,
           e.median_ms AS early_ms, l.median_ms AS late_ms,
           l.median_ms / nullif(e.median_ms, 0) AS late_vs_early,
           a.median_ms / nullif(least(e.median_ms, l.median_ms), 0) AS auto_vs_best
    FROM topnbench_placement_runs a
    JOIN topnbench_placement_runs e USING (case_no, mem_no, batch)
    JOIN topnbench_placement_runs l USING (case_no, mem_no, batch)
    WHERE a.mode = 'auto' AND e.mode = 'early' AND l.mode = 'late'
)
SELECT c.case_name, c.work_mem_setting,
       CASE WHEN jsonb_array_length(s.node#>'{Plans,0,Output}') = 1 THEN 'late' ELSE 'early' END AS auto_choice,
       round((e.estimated#>>'{0,Plan,Total Cost}')::numeric, 3) AS early_final_cost,
       round((l.estimated#>>'{0,Plan,Total Cost}')::numeric, 3) AS late_final_cost,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY p.auto_ms)::numeric, 3) AS auto_ms,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY p.early_ms)::numeric, 3) AS early_ms,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY p.late_ms)::numeric, 3) AS late_ms,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY p.late_vs_early)::numeric, 3) AS late_vs_early,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY p.auto_vs_best)::numeric, 3) AS auto_vs_best,
       count(*) FILTER (WHERE p.late_vs_early < 0.95) AS late_wins,
       count(*) FILTER (WHERE p.late_vs_early > 1.05) AS early_wins,
       es.node->>'Sort Method' AS early_method, ls.node->>'Sort Method' AS late_method
FROM pairs p JOIN topnbench_placement_cases c USING (case_no, mem_no)
JOIN topnbench_placement_plans e ON e.case_no = p.case_no AND e.mem_no = p.mem_no AND e.mode = 'early'
JOIN topnbench_placement_plans l ON l.case_no = p.case_no AND l.mem_no = p.mem_no AND l.mode = 'late'
JOIN topnbench_placement_nodes s ON s.case_no = p.case_no AND s.mem_no = p.mem_no
                                  AND s.mode = 'auto' AND s.node->>'Node Type' = 'Sort'
JOIN topnbench_placement_nodes es ON es.case_no = p.case_no AND es.mem_no = p.mem_no
                                   AND es.mode = 'early' AND es.node->>'Node Type' = 'Sort'
JOIN topnbench_placement_nodes ls ON ls.case_no = p.case_no AND ls.mem_no = p.mem_no
                                   AND ls.mode = 'late' AND ls.node->>'Node Type' = 'Sort'
GROUP BY c.case_no, c.mem_no, c.case_name, c.work_mem_setting, s.node, e.estimated, l.estimated, es.node, ls.node
ORDER BY c.case_no, c.mem_no;

\if :topnbench_verbose
SELECT c.case_name, c.work_mem_setting, r.*
FROM topnbench_placement_runs r JOIN topnbench_placement_cases c USING (case_no, mem_no)
ORDER BY c.case_no, c.mem_no, r.batch, r.mode;
\endif
\echo '0020 PASS: same SQL, one sort key, requested placements and equal results verified.'
