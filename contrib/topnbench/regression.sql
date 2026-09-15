-- Loaded by benchmark.sql after its result-table schemas are available.
-- These few cases are measured under every policy, unlike the broad matrix.
DROP VIEW IF EXISTS topnbench_regression_pairs;
DROP VIEW IF EXISTS topnbench_regression_nodes;
DROP TABLE IF EXISTS topnbench_regression_runs;
DROP TABLE IF EXISTS topnbench_regression_plans;
DROP TABLE IF EXISTS topnbench_regression_inputs;
CREATE TEMP TABLE topnbench_regression_runs AS
SELECT 0::integer AS batch, r.*
FROM topnbench_supplemental_results AS r WITH NO DATA;

CREATE TEMP TABLE topnbench_regression_plans
(
    case_name text,
    policy text,
    strategy text,
    plan jsonb,
    PRIMARY KEY (case_name, policy, strategy)
);

CREATE TEMP TABLE topnbench_regression_inputs
(
    case_name text PRIMARY KEY,
    source_table text,
    input_rows bigint,
    statistics_width integer,
    actual_width numeric,
    work_mem text,
    auto_sql text,
    late_sql text,
    early_sql text
);

-- Calls must precede any ANALYZE that would repair deliberately stale stats.
-- SET jit establishes a function GUC scope; all local changes below are
-- restored on both success and error, without replacing caller defaults.
CREATE OR REPLACE FUNCTION pg_temp.topnbench_diagnose(wanted_case text, source_table regclass)
RETURNS void LANGUAGE plpgsql
SET jit = off
AS $fn$
DECLARE
    d record;
    batch_no integer;
    turn_no integer;
    policy_no integer;
    policy_name text;
    strategy_no integer;
    statement text;
    saved_plan jsonb;
    saved_mem text := current_setting('work_mem');
    saved_messages text := current_setting('client_min_messages');
    policies text[] := ARRAY['master', 'path-only', 'patched'];
    strategies text[] := ARRAY['auto', 'late', 'early'];
BEGIN
    SELECT * INTO STRICT d FROM topnbench_case_definitions
    WHERE case_name = wanted_case;

    PERFORM set_config('work_mem', coalesce(d.work_mem_setting, saved_mem), true);
    PERFORM set_config('debug_print_projection_paths', 'off', true);
    EXECUTE format(
        'INSERT INTO topnbench_regression_inputs '
        'SELECT $1, $2, count(*), '
        '(SELECT avg_width FROM pg_stats '
        ' WHERE schemaname = $3 AND tablename = $4 AND attname = ''payload''), '
        'avg(pg_column_size(payload)), $5, $6, $7, $8 FROM %s', source_table)
    USING wanted_case, source_table::text,
          (SELECT n.nspname FROM pg_class c JOIN pg_namespace n
           ON n.oid = c.relnamespace WHERE c.oid = source_table),
          (SELECT relname FROM pg_class WHERE oid = source_table),
          current_setting('work_mem'), d.auto_query,
          d.manual_late_query, d.forced_early_query;

    -- Six batches use all policy permutations, balancing order and position.
    -- Each batch has one warmup and three rotated samples per strategy.
    FOR batch_no IN 1..6 LOOP
        FOR turn_no IN 0..2 LOOP
            policy_no := ((batch_no - 1) % 3 +
                          CASE WHEN batch_no <= 3 THEN turn_no
                               ELSE 3 - turn_no END) % 3 + 1;
            policy_name := policies[policy_no];
            PERFORM set_config('enable_cost_based_delayed_projection',
                               CASE WHEN policy_no = 1 THEN 'off' ELSE 'on' END, true);
            PERFORM set_config('enable_sort_tuple_width_cost',
                               CASE WHEN policy_no = 3 THEN 'on' ELSE 'off' END, true);
            INSERT INTO topnbench_regression_runs
            SELECT batch_no, policy_name, d.case_order, d.phase,
                   d.category, d.case_name, c.*
            FROM topnbench_compare(d.auto_query, d.manual_late_query,
                    d.forced_early_query, 3, batch_no = 1,
                    d.work_mem_setting, false) AS c;
        END LOOP;
    END LOOP;

    -- Collect untimed diagnostic executions AFTER the timed batches.  Preserve
    -- full plans for topology checks and print relevant nodes in the report.
    FOR policy_no IN 1..3 LOOP
        policy_name := policies[policy_no];
        PERFORM set_config('enable_cost_based_delayed_projection',
                           CASE WHEN policy_no = 1 THEN 'off' ELSE 'on' END, true);
        PERFORM set_config('enable_sort_tuple_width_cost',
                           CASE WHEN policy_no = 3 THEN 'on' ELSE 'off' END, true);
        -- One fresh, plan-only natural query per policy.  Keep core tracing
        -- outside all timing loops and exclude the rewritten strategies.
        RAISE NOTICE 'topn-trace BEGIN case=% policy=%', wanted_case, policy_name;
        PERFORM set_config('client_min_messages', 'debug1', true);
        PERFORM set_config('debug_print_projection_paths', 'on', true);
        EXECUTE 'EXPLAIN (COSTS ON, FORMAT JSON) ' || d.auto_query INTO saved_plan;
        PERFORM set_config('debug_print_projection_paths', 'off', true);
        PERFORM set_config('client_min_messages', saved_messages, true);
        RAISE NOTICE 'topn-trace END case=% policy=%', wanted_case, policy_name;

        FOR strategy_no IN 1..3 LOOP
            statement := CASE strategy_no
                WHEN 1 THEN d.auto_query
                WHEN 2 THEN d.manual_late_query
                ELSE d.forced_early_query END;
            EXECUTE 'EXPLAIN (ANALYZE, VERBOSE, BUFFERS, COSTS ON, '
                    'TIMING OFF, SUMMARY ON, FORMAT JSON) ' || statement
            INTO saved_plan;
            INSERT INTO topnbench_regression_plans
            VALUES (wanted_case, policy_name, strategies[strategy_no], saved_plan);
        END LOOP;
    END LOOP;
END
$fn$;
