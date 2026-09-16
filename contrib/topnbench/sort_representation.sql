\echo
\echo '== Sort representation and post-Sort projection controls =='

-- Reuse the same million-row heap and unique leading key as the quick matrix.
-- A second live Var keeps the tuple variant from becoming a one-column Sort.
-- COST 100 encourages a post-Sort Result for the last two variants. It is a
-- placement aid, not a claim about the actual cost of zero/16 work rounds.
DROP VIEW IF EXISTS topnbench_representation_nodes;
DROP TABLE IF EXISTS topnbench_representation_runs;
DROP TABLE IF EXISTS topnbench_representation_plans;
DROP TABLE IF EXISTS topnbench_representation_cases;
CREATE TEMP TABLE topnbench_representation_cases AS
SELECT l.id * 2 + m.id AS case_id, l.limit_rows, m.work_mem_setting,
       v.variant_no, v.variant, v.sort_columns,
       CASE v.variant_no
           WHEN 1 THEN 'SELECT a_random FROM topnbench_data'
           WHEN 2 THEN 'SELECT a_random, same1 FROM topnbench_data'
           WHEN 3 THEN format('SELECT a_random FROM topnbench_data ORDER BY a_random LIMIT %s', l.limit_rows)
           WHEN 4 THEN format('SELECT a_random, same1 FROM topnbench_data ORDER BY a_random LIMIT %s', l.limit_rows)
           ELSE format('SELECT a_random, topnbench_work_cost_100(a_random, %s, 1) AS e1 '
                       'FROM topnbench_data ORDER BY a_random LIMIT %s',
                       CASE v.variant_no WHEN 5 THEN 0 ELSE 16 END, l.limit_rows)
       END AS query
FROM (VALUES (0, 250000), (1, 900000)) l(id, limit_rows)
CROSS JOIN (VALUES (1, '4MB'), (2, '256MB')) m(id, work_mem_setting)
CROSS JOIN (VALUES (1, 'scan-one', 0), (2, 'scan-two', 0),
                   (3, 'sort-datum', 1), (4, 'sort-tuple', 2),
                   (5, 'late-work-0', 1), (6, 'late-work-16', 1))
    v(variant_no, variant, sort_columns);

CREATE TEMP TABLE topnbench_representation_runs AS
SELECT 0::integer AS case_id, 0::integer AS variant_no, 0::integer AS batch, r.*
FROM topnbench_measure('SELECT 1', 3, '4MB') r WITH NO DATA;
CREATE TEMP TABLE topnbench_representation_plans
    (case_id integer, variant_no integer, plan jsonb,
     PRIMARY KEY (case_id, variant_no));

-- All settings are local to this DO statement's transaction. Neither this
-- section's timed runs nor its diagnostic executions enable core tracing.
DO $$
DECLARE
    c record;
    v record;
    b integer;
    p jsonb;
BEGIN
    PERFORM set_config('max_parallel_workers_per_gather', '0', true);
    PERFORM set_config('jit', 'off', true);
    PERFORM set_config('debug_print_projection_paths', 'off', true);
    PERFORM set_config('enable_cost_based_delayed_projection', 'on', true);
    PERFORM set_config('enable_sort_tuple_width_cost', 'on', true);
    PERFORM set_config('enable_projection_total_cost', 'on', true);
    FOR c IN SELECT DISTINCT case_id, work_mem_setting
             FROM topnbench_representation_cases ORDER BY case_id LOOP
        -- Six rotations put every variant in every ordinal position once.
        FOR b IN 1..6 LOOP
            FOR v IN SELECT * FROM topnbench_representation_cases
                     WHERE case_id = c.case_id
                     ORDER BY (variant_no - b + 6) % 6 LOOP
                INSERT INTO topnbench_representation_runs
                SELECT c.case_id, v.variant_no, b, r.*
                FROM topnbench_measure(v.query, 3, c.work_mem_setting) r;
            END LOOP;
        END LOOP;
    END LOOP;

    -- Inspect actual Sort method, input target and I/O after ALL timing.
    FOR v IN SELECT * FROM topnbench_representation_cases
             ORDER BY case_id, variant_no LOOP
        PERFORM set_config('work_mem', v.work_mem_setting, true);
        EXECUTE 'EXPLAIN (ANALYZE, VERBOSE, BUFFERS, COSTS ON, '
                'TIMING OFF, SUMMARY ON, FORMAT JSON) ' || v.query INTO p;
        INSERT INTO topnbench_representation_plans VALUES (v.case_id, v.variant_no, p);
    END LOOP;
END $$;

CREATE TEMP VIEW topnbench_representation_nodes AS
WITH RECURSIVE nodes(case_id, variant_no, node_path, node) AS (
    SELECT case_id, variant_no, ARRAY[0], plan->0->'Plan'
    FROM topnbench_representation_plans
    UNION ALL
    SELECT n.case_id, n.variant_no, n.node_path || c.ordinality::integer, c.node
    FROM nodes n
    CROSS JOIN LATERAL jsonb_array_elements(n.node->'Plans')
        WITH ORDINALITY c(node, ordinality)
)
SELECT * FROM nodes;

-- Do not silently call an unintended plan a Datum/tuple/Result experiment.
-- The representation is derived from the Sort child's actual plan target,
-- using the same one-column condition as ExecInitSort, not from Sort Key count.
DO $$
DECLARE
    c record;
    s jsonb;
    count_sorts integer;
BEGIN
    FOR c IN SELECT d.*, p.plan FROM topnbench_representation_cases d
             JOIN topnbench_representation_plans p USING (case_id, variant_no) LOOP
        SELECT count(*) INTO count_sorts FROM topnbench_representation_nodes n
        WHERE n.case_id = c.case_id AND n.variant_no = c.variant_no
          AND n.node->>'Node Type' IN ('Sort', 'Incremental Sort');
        IF (c.sort_columns = 0 AND count_sorts <> 0) OR
           (c.sort_columns > 0 AND count_sorts <> 1) THEN
            RAISE EXCEPTION 'Unexpected Sort count in case %, %', c.case_id, c.variant;
        END IF;
        IF c.sort_columns > 0 THEN
            SELECT n.node INTO STRICT s FROM topnbench_representation_nodes n
            WHERE n.case_id = c.case_id AND n.variant_no = c.variant_no
              AND n.node->>'Node Type' IN ('Sort', 'Incremental Sort');
            IF s->>'Node Type' IS DISTINCT FROM 'Sort'
               OR jsonb_array_length(s#>'{Plans,0,Output}') IS DISTINCT FROM c.sort_columns
               OR jsonb_array_length(s->'Sort Key') IS DISTINCT FROM 1 THEN
                RAISE EXCEPTION 'Unexpected Sort input in case %, %: %', c.case_id, c.variant, s;
            END IF;
        END IF;
        IF c.variant_no >= 5 AND
           c.plan#>>'{0,Plan,Plans,0,Node Type}' IS DISTINCT FROM 'Result' THEN
            RAISE EXCEPTION 'Expected Limit/Result/Sort in case %, %', c.case_id, c.variant;
        END IF;
    END LOOP;
END $$;

\echo '== Pure Sort: paired tuple/Datum times and matched scan controls =='
-- Subtract matched full scans to expose a useful proxy for incremental work.
-- This is NOT an exclusive Sort-node time: output delivery and memory behavior
-- also differ. Keep negative/noisy differences visible; do not clamp them.
WITH pairs AS (
    SELECT d.case_id, d.batch, d.total_cost AS datum_cost, t.total_cost AS tuple_cost,
           d.median_ms AS datum_ms, t.median_ms AS tuple_ms,
           t.median_ms / nullif(d.median_ms, 0) AS ratio,
           d.median_ms - s1.median_ms AS datum_minus_scan,
           t.median_ms - s2.median_ms AS tuple_minus_scan
    FROM topnbench_representation_runs d
    JOIN topnbench_representation_runs t USING (case_id, batch)
    JOIN topnbench_representation_runs s1 USING (case_id, batch)
    JOIN topnbench_representation_runs s2 USING (case_id, batch)
    WHERE d.variant_no = 3 AND t.variant_no = 4
      AND s1.variant_no = 1 AND s2.variant_no = 2
)
SELECT c.limit_rows, c.work_mem_setting,
       round(min(p.datum_cost)::numeric, 3) AS datum_cost,
       round(min(p.tuple_cost)::numeric, 3) AS tuple_cost,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY p.datum_ms)::numeric, 3) AS datum_ms,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY p.tuple_ms)::numeric, 3) AS tuple_ms,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY p.ratio)::numeric, 3) AS tuple_vs_datum,
       count(*) FILTER (WHERE p.ratio > 1.05) AS tuple_slower_batches,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY p.datum_minus_scan)::numeric, 3) AS datum_minus_scan_ms,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY p.tuple_minus_scan)::numeric, 3) AS tuple_minus_scan_ms
FROM pairs p JOIN topnbench_representation_cases c ON c.case_id = p.case_id AND c.variant_no = 3
GROUP BY c.case_id, c.limit_rows, c.work_mem_setting ORDER BY c.case_id;

\echo '== Late projection: total incremental work above the same Datum Sort =='
-- The measured delta includes Result dispatch, the C call, expression work
-- and the extra output column. It does NOT isolate cpu_tuple_cost. COST 100
-- is used only to keep projection late and deliberately overstates cheap work.
WITH pairs AS (
    SELECT d.case_id, p.variant_no, d.batch,
           p.total_cost - d.total_cost AS estimated_delta,
           p.median_ms - d.median_ms AS delta_ms,
           p.median_ms / nullif(d.median_ms, 0) AS ratio
    FROM topnbench_representation_runs d JOIN topnbench_representation_runs p
      USING (case_id, batch)
    WHERE d.variant_no = 3 AND p.variant_no IN (5, 6)
)
SELECT c.limit_rows, c.work_mem_setting, c.variant,
       round(min(p.estimated_delta)::numeric, 3) AS estimated_delta,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY p.delta_ms)::numeric, 3) AS projection_delta_ms,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY p.ratio)::numeric, 3) AS projection_vs_bare_sort
FROM pairs p JOIN topnbench_representation_cases c USING (case_id, variant_no)
GROUP BY c.case_id, c.limit_rows, c.work_mem_setting, c.variant_no, c.variant
ORDER BY c.case_id, c.variant_no;

\echo '== Observed Sort inputs and I/O (diagnostic executions, not timed samples) =='
SELECT c.limit_rows, c.work_mem_setting, c.variant,
       jsonb_array_length(n.node#>'{Plans,0,Output}') AS sort_input_columns,
       n.node#>'{Plans,0,Output}' AS sort_input,
       n.node->>'Plan Width' AS estimated_width,
       n.node#>>'{Plans,0,Actual Rows}' AS input_rows,
       n.node->>'Actual Rows' AS output_rows,
       n.node->>'Sort Method' AS method, n.node->>'Sort Space Type' AS space_type,
       n.node->>'Sort Space Used' AS space_kb,
       n.node->>'Temp Read Blocks' AS temp_read,
       n.node->>'Temp Written Blocks' AS temp_written
FROM topnbench_representation_nodes n JOIN topnbench_representation_cases c
  USING (case_id, variant_no)
WHERE n.node->>'Node Type' = 'Sort' ORDER BY c.case_id, c.variant_no;

\echo '== Per-batch times and observed methods: check dispersion before fitting costs =='
SELECT c.limit_rows, c.work_mem_setting, c.variant, r.batch,
       round(r.median_ms::numeric, 3) AS median_ms,
       r.plan_nodes, r.sort_method, r.sort_space_type
FROM topnbench_representation_runs r JOIN topnbench_representation_cases c
  USING (case_id, variant_no) ORDER BY c.case_id, r.batch, c.variant_no;
