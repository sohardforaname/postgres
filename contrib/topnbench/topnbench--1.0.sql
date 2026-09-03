\echo Use "CREATE EXTENSION topnbench" to load this file. \quit

CREATE FUNCTION topnbench_cost_1(integer)
RETURNS integer
AS 'MODULE_PATHNAME', 'topnbench_cost_1'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE COST 1;

CREATE FUNCTION topnbench_cost_2(integer)
RETURNS integer
AS 'MODULE_PATHNAME', 'topnbench_cost_2'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE COST 2;

CREATE FUNCTION topnbench_cost_5(integer)
RETURNS integer
AS 'MODULE_PATHNAME', 'topnbench_cost_5'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE COST 5;

CREATE FUNCTION topnbench_cost_10(integer)
RETURNS integer
AS 'MODULE_PATHNAME', 'topnbench_cost_10'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE COST 10;

CREATE FUNCTION topnbench_run(
    relation regclass,
    key_column name DEFAULT 'a',
    iterations integer DEFAULT 3,
    profile text DEFAULT 'quick',
    verify boolean DEFAULT true)
RETURNS TABLE (
    input_rows bigint,
    limit_rows bigint,
    selectivity double precision,
    expression_count integer,
    expression_cost integer,
    requested_workers integer,
    launched_workers integer,
    auto_plan_nodes text,
    auto_ms double precision,
    manual_late_ms double precision,
    forced_early_ms double precision,
    late_speedup double precision,
    late_vs_early_speedup double precision,
    winner text)
AS 'MODULE_PATHNAME', 'topnbench_run'
LANGUAGE C VOLATILE PARALLEL UNSAFE;

CREATE FUNCTION topnbench_compare(
    auto_query text,
    manual_late_query text,
    forced_early_query text,
    iterations integer DEFAULT 5,
    verify boolean DEFAULT true)
RETURNS TABLE (
    auto_plan_nodes text,
    launched_workers integer,
    auto_ms double precision,
    manual_late_ms double precision,
    forced_early_ms double precision,
    late_speedup double precision,
    late_vs_early_speedup double precision,
    winner text)
AS 'MODULE_PATHNAME', 'topnbench_compare'
LANGUAGE C VOLATILE PARALLEL UNSAFE;

COMMENT ON FUNCTION topnbench_run(regclass, name, integer, text, boolean) IS
'Compare planner-selected and manually delayed projection over a fixed case matrix.';

COMMENT ON FUNCTION topnbench_compare(text, text, text, integer, boolean) IS
'Compare automatic, manually delayed, and forced-early SELECT statements, rotating execution order and reporting minimum execution time.';
