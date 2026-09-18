\echo
\echo '== Regression probes: data and settings =='
SELECT version();
SELECT name, setting, unit FROM pg_settings
WHERE name IN ('cpu_operator_cost', 'cpu_tuple_cost', 'seq_page_cost',
               'random_page_cost', 'effective_cache_size', 'shared_buffers',
               'block_size', 'track_io_timing', 'default_statistics_target')
ORDER BY name;
SELECT case_name, input_rows, statistics_width,
       round(actual_width, 2) AS actual_width, work_mem
FROM topnbench_regression_inputs ORDER BY case_name;

\echo '== Regression probes: six independent timing batches per policy =='
-- Dispersion here is between batch medians, not a confidence interval.
SELECT case_name, policy, count(*) AS batches,
       string_agg(DISTINCT planner_choice, ',') AS choices,
       count(*) FILTER (WHERE actual_winner = 'early') AS early_wins,
       count(*) FILTER (WHERE actual_winner = 'late') AS late_wins,
       count(*) FILTER (WHERE actual_winner = 'tie') AS ties,
       round(min(auto_median_ms)::numeric, 3) AS auto_min_ms,
       round((percentile_cont(0.5) WITHIN GROUP
             (ORDER BY auto_median_ms))::numeric, 3) AS auto_median_ms,
       round(max(auto_median_ms)::numeric, 3) AS auto_max_ms,
       round((percentile_cont(0.5) WITHIN GROUP
             (ORDER BY manual_late_median_ms))::numeric, 3) AS late_ms,
       round((percentile_cont(0.5) WITHIN GROUP
             (ORDER BY forced_early_median_ms))::numeric, 3) AS early_ms
FROM topnbench_regression_runs
GROUP BY case_name, policy ORDER BY case_name, policy;

CREATE TEMP VIEW topnbench_regression_pairs AS
SELECT p.case_name, p.batch,
       m.auto_median_ms AS master_ms, o.auto_median_ms AS path_ms,
       p.auto_median_ms AS patched_ms,
       o.auto_median_ms / nullif(m.auto_median_ms, 0) AS path_vs_master,
       p.auto_median_ms / nullif(m.auto_median_ms, 0) AS patched_vs_master,
       p.manual_late_median_ms / nullif(p.forced_early_median_ms, 0) AS late_vs_early,
       m.planner_choice AS master_choice,
       o.planner_choice AS path_choice, p.planner_choice AS patched_choice
FROM topnbench_regression_runs p
JOIN topnbench_regression_runs m USING (case_name, batch)
JOIN topnbench_regression_runs o USING (case_name, batch)
WHERE p.policy = 'patched' AND m.policy = 'master' AND o.policy = 'path-only';

\echo '== Natural-query ratios (>1 means slower): no placement-to-time mapping =='
SELECT case_name, batch, master_choice, path_choice, patched_choice,
       round(master_ms::numeric, 3) AS master_ms,
       round(path_ms::numeric, 3) AS path_ms,
       round(patched_ms::numeric, 3) AS patched_ms,
       round(path_vs_master::numeric, 4) AS path_vs_master,
       round(patched_vs_master::numeric, 4) AS patched_vs_master,
       round(late_vs_early::numeric, 4) AS patched_late_vs_early
FROM topnbench_regression_pairs ORDER BY case_name, batch;

\echo '== Repeatability (3% band; descriptive, not a significance test) =='
SELECT case_name, count(*) AS batches,
       count(*) FILTER (WHERE patched_vs_master > 1.03) AS patched_slower_batches,
       count(*) FILTER (WHERE patched_vs_master < 1.0 / 1.03) AS patched_faster_batches,
       count(*) FILTER (WHERE late_vs_early > 1.03) AS early_winner_batches,
       count(*) FILTER (WHERE late_vs_early < 1.0 / 1.03) AS late_winner_batches,
       round(min(patched_vs_master)::numeric, 4) AS min_ratio,
       round((percentile_cont(0.5) WITHIN GROUP
             (ORDER BY patched_vs_master))::numeric, 4) AS median_ratio,
       round(max(patched_vs_master)::numeric, 4) AS max_ratio
FROM topnbench_regression_pairs GROUP BY case_name ORDER BY case_name;

\if :topnbench_verbose
\echo '== Surviving automatic-query candidate costs (one row per distinct decision) =='
\echo 'Final selection is traced earlier between topn-trace BEGIN/END markers (capture stderr too).'
-- Rewritten-query root costs are intentionally not used as candidate costs.
SELECT DISTINCT case_name, policy, planner_choice, lower_limit_cost_choice,
       costs_within_1pct,
       early_startup_cost, early_total_cost, early_limit_cost,
       early_sort_rows, early_sort_width,
       late_startup_cost, late_total_cost, late_limit_cost,
       late_sort_rows, late_sort_width
FROM topnbench_regression_runs ORDER BY case_name, policy;

CREATE TEMP VIEW topnbench_regression_nodes AS
WITH RECURSIVE nodes AS
(
    SELECT case_name, policy, strategy, ARRAY[0]::bigint[] AS node_path,
           plan->0->'Plan' AS node
    FROM topnbench_regression_plans
    UNION ALL
    SELECT n.case_name, n.policy, n.strategy, n.node_path || c.ord, c.child
    FROM nodes n CROSS JOIN LATERAL
         jsonb_array_elements(n.node->'Plans') WITH ORDINALITY c(child, ord)
)
SELECT * FROM nodes;

\echo '== Plan topology and Sort I/O: diagnostic executions after timing =='
-- Buffer counters include descendants: do not sum them across nodes.
SELECT case_name, policy, strategy, node_path,
       (SELECT string_agg(n2.node->>'Node Type', ' > ' ORDER BY n2.node_path)
        FROM topnbench_regression_nodes n2
        WHERE n2.case_name = n.case_name AND n2.policy = n.policy
          AND n2.strategy = n.strategy) AS topology,
       node->>'Plan Rows' AS est_rows, node->>'Plan Width' AS est_width,
       node->'Plans'->0->>'Actual Rows' AS input_rows,
       node->>'Actual Rows' AS output_rows, node->>'Actual Loops' AS loops,
       node->>'Startup Cost' AS sort_startup,
       node->>'Total Cost' AS sort_total,
       node->>'Sort Method' AS sort_method,
       node->>'Sort Space Type' AS space_type,
       node->>'Sort Space Used' AS space_kb,
       node->>'Temp Read Blocks' AS temp_read,
       node->>'Temp Written Blocks' AS temp_written,
       node->>'Shared Read Blocks' AS shared_read
FROM topnbench_regression_nodes n
WHERE node->>'Node Type' = 'Sort'
ORDER BY case_name, policy, strategy, node_path;

\echo '== Exact reproduction SQL (input statistics must match the snapshot above) =='
SELECT case_name, source_table, work_mem, auto_sql
FROM topnbench_regression_inputs ORDER BY case_name;

\if :topnbench_verbose
SELECT case_name, late_sql, early_sql FROM topnbench_regression_inputs
ORDER BY case_name;
SELECT case_name, policy, strategy, jsonb_pretty(plan) AS full_plan
FROM topnbench_regression_plans ORDER BY case_name, policy, strategy;
\endif

\endif

\echo '== Regression diagnostics complete =='
