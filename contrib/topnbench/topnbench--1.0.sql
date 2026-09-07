\echo Use "CREATE EXTENSION topnbench" to load this file. \quit

CREATE FUNCTION topnbench_work_cost_1(integer, integer, integer)
RETURNS integer
AS 'MODULE_PATHNAME', 'topnbench_work'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE COST 1;

CREATE FUNCTION topnbench_work_cost_10(integer, integer, integer)
RETURNS integer
AS 'MODULE_PATHNAME', 'topnbench_work'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE COST 10;

CREATE FUNCTION topnbench_work_cost_100(integer, integer, integer)
RETURNS integer
AS 'MODULE_PATHNAME', 'topnbench_work'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE FUNCTION topnbench_run(
    relation regclass,
    key_column name DEFAULT 'a',
    iterations integer DEFAULT 3,
    profile text DEFAULT 'quick',
    verify boolean DEFAULT true)
RETURNS TABLE (
    case_name text,
    input_rows bigint,
    offset_rows bigint,
    limit_rows bigint,
    sort_rows bigint,
    selectivity double precision,
    expression_shape text,
    target_count integer,
    expression_steps integer,
    declared_cost integer,
    work_rounds integer,
    requested_workers integer,
    launched_workers integer,
    auto_plan_nodes text,
    estimated_sort_rows double precision,
    actual_sort_input_rows double precision,
    row_estimation_ratio double precision,
    estimated_sort_width integer,
    sort_method text,
    sort_space_type text,
    sort_space_used_kb double precision,
    planner_choice text,
    auto_min_ms double precision,
    auto_median_ms double precision,
    manual_late_min_ms double precision,
    manual_late_median_ms double precision,
    forced_early_min_ms double precision,
    forced_early_median_ms double precision,
    actual_winner text,
    planner_choice_correct boolean,
    auto_regression_ratio double precision,
    choice_regression_ratio double precision,
    late_vs_early_speedup double precision,
    cost_model_choice text,
    cost_model_correct boolean,
    structural_model_choice text,
    structural_model_correct boolean,
    manual_late_sort_method text,
    manual_late_sort_space_type text,
    manual_late_sort_space_used_kb double precision,
    forced_early_sort_method text,
    forced_early_sort_space_type text,
    forced_early_sort_space_used_kb double precision,
    decision_class text,
    auto_sort_output text,
    manual_late_sort_output text,
    forced_early_sort_output text,
    lower_limit_cost_choice text,
    costs_within_1pct boolean,
    early_startup_cost double precision,
    early_total_cost double precision,
    early_limit_cost double precision,
    early_sort_rows double precision,
    early_sort_width integer,
    late_startup_cost double precision,
    late_total_cost double precision,
    late_limit_cost double precision,
    late_sort_rows double precision,
    late_sort_width integer,
    estimated_late_vs_early_cost double precision)
AS 'MODULE_PATHNAME', 'topnbench_run'
LANGUAGE C VOLATILE PARALLEL UNSAFE;

CREATE FUNCTION topnbench_compare(
    auto_query text,
    manual_late_query text,
    forced_early_query text,
    iterations integer DEFAULT 5,
    verify boolean DEFAULT true,
    work_mem_setting text DEFAULT NULL)
RETURNS TABLE (
    auto_plan_nodes text,
    launched_workers integer,
    estimated_sort_rows double precision,
    actual_sort_input_rows double precision,
    row_estimation_ratio double precision,
    estimated_sort_width integer,
    sort_method text,
    sort_space_type text,
    sort_space_used_kb double precision,
    planner_choice text,
    auto_min_ms double precision,
    auto_median_ms double precision,
    manual_late_min_ms double precision,
    manual_late_median_ms double precision,
    forced_early_min_ms double precision,
    forced_early_median_ms double precision,
    actual_winner text,
    planner_choice_correct boolean,
    auto_regression_ratio double precision,
    choice_regression_ratio double precision,
    late_vs_early_speedup double precision,
    manual_late_sort_method text,
    manual_late_sort_space_type text,
    manual_late_sort_space_used_kb double precision,
    forced_early_sort_method text,
    forced_early_sort_space_type text,
    forced_early_sort_space_used_kb double precision,
    decision_class text,
    auto_sort_output text,
    manual_late_sort_output text,
    forced_early_sort_output text,
    lower_limit_cost_choice text,
    costs_within_1pct boolean,
    early_startup_cost double precision,
    early_total_cost double precision,
    early_limit_cost double precision,
    early_sort_rows double precision,
    early_sort_width integer,
    late_startup_cost double precision,
    late_total_cost double precision,
    late_limit_cost double precision,
    late_sort_rows double precision,
    late_sort_width integer,
    estimated_late_vs_early_cost double precision)
AS 'MODULE_PATHNAME', 'topnbench_compare'
LANGUAGE C VOLATILE PARALLEL UNSAFE;

CREATE FUNCTION topnbench_measure(
    query text,
    iterations integer DEFAULT 5,
    work_mem_setting text DEFAULT NULL)
RETURNS TABLE (
    plan_nodes text,
    launched_workers integer,
    startup_cost double precision,
    total_cost double precision,
    estimated_sort_rows double precision,
    actual_sort_input_rows double precision,
    estimated_sort_width integer,
    sort_method text,
    sort_space_type text,
    sort_space_used_kb double precision,
    minimum_ms double precision,
    median_ms double precision)
AS 'MODULE_PATHNAME', 'topnbench_measure'
LANGUAGE C VOLATILE PARALLEL UNSAFE;

COMMENT ON FUNCTION topnbench_run(regclass, name, integer, text, boolean) IS
'Measure delayed-projection decision quality over a curated case matrix.';

COMMENT ON FUNCTION topnbench_compare(text, text, text, integer, boolean, text) IS
'Compare automatic, manually delayed, and forced-early SELECT statements, optionally under a specified work_mem, rotating execution order and reporting minimum and median execution times.';

COMMENT ON FUNCTION topnbench_measure(text, integer, text) IS
'Measure one SELECT and report root cost, Sort metadata, and execution time.';
