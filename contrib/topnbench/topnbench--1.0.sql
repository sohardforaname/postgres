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
    verify boolean DEFAULT true,
    plan_only boolean DEFAULT false)
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
    work_mem_setting text DEFAULT NULL,
    plan_only boolean DEFAULT false)
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

COMMENT ON FUNCTION topnbench_run(regclass, name, integer, text, boolean, boolean) IS
'Measure delayed-projection decision quality over a curated case matrix, or collect plans without execution when plan_only is true.';

COMMENT ON FUNCTION topnbench_compare(text, text, text, integer, boolean, text, boolean) IS
'Compare automatic, manually delayed, and forced-early SELECT statements, optionally under a specified work_mem; plan_only collects decisions without executing the statements.';

COMMENT ON FUNCTION topnbench_measure(text, integer, text) IS
'Measure one SELECT and report root cost, Sort metadata, and execution time.';

-- Session-local collection API. Keep analytical SQL out of benchmark.sql.
CREATE FUNCTION topnbench_explain(query text, analyze_query boolean DEFAULT false)
RETURNS jsonb
AS 'MODULE_PATHNAME', 'topnbench_explain'
LANGUAGE C VOLATILE STRICT PARALLEL UNSAFE;

CREATE FUNCTION topnbench_reset() RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
    DROP VIEW IF EXISTS pg_temp.topnbench_batches;
    DROP TABLE IF EXISTS pg_temp.topnbench_samples;
    DROP TABLE IF EXISTS pg_temp.topnbench_plans;
    DROP TABLE IF EXISTS pg_temp.topnbench_cases;
    CREATE TEMP TABLE topnbench_cases (
        id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        name text UNIQUE NOT NULL, query text NOT NULL,
        settings jsonb NOT NULL, server_version text NOT NULL,
        registered_at timestamptz NOT NULL DEFAULT clock_timestamp(),
        verified boolean NOT NULL DEFAULT false
    );
    CREATE TEMP TABLE topnbench_plans (
        case_id integer REFERENCES topnbench_cases,
        mode text CHECK (mode IN ('auto', 'early', 'late')),
        estimated jsonb NOT NULL, actual jsonb,
        PRIMARY KEY (case_id, mode)
    );
    CREATE TEMP TABLE topnbench_samples (
        case_id integer REFERENCES topnbench_cases,
        batch integer CHECK (batch BETWEEN 1 AND 6),
        mode text CHECK (mode IN ('auto', 'early', 'late')),
        sample integer CHECK (sample BETWEEN 0 AND 3),
        plan jsonb NOT NULL,
        PRIMARY KEY (case_id, batch, mode, sample)
    );
    -- Sample zero is a recorded warmup, never a timing sample.
    CREATE TEMP VIEW topnbench_batches AS
    SELECT case_id, batch, mode,
           percentile_cont(0.5) WITHIN GROUP
             (ORDER BY (plan#>>'{0,Execution Time}')::double precision) AS ms
    FROM topnbench_samples WHERE sample > 0
    GROUP BY case_id, batch, mode;
END $$;

CREATE FUNCTION topnbench_case(name text, query text,
                              work_mem_setting text DEFAULT NULL)
RETURNS text LANGUAGE plpgsql AS $$
DECLARE
    config jsonb;
BEGIN
    IF to_regclass('pg_temp.topnbench_cases') IS NULL THEN
        RAISE EXCEPTION 'call topnbench_reset() first';
    END IF;
    IF EXISTS (SELECT FROM pg_temp.topnbench_plans) THEN
        RAISE EXCEPTION 'collection has already run; reset before adding cases';
    END IF;
    IF name IS NULL OR btrim(name) = '' OR query IS NULL THEN
        RAISE EXCEPTION 'case name and SELECT must be non-null and non-empty';
    END IF;
    -- Parse and plan now: no execution, no acceptance of extra SQL statements.
    PERFORM topnbench_explain(query, false);
    SELECT jsonb_object_agg(s.name, current_setting(s.name)) INTO config
    FROM pg_settings s;
    IF work_mem_setting IS NOT NULL THEN
        config := jsonb_set(config, '{work_mem}', to_jsonb(work_mem_setting));
    END IF;
    INSERT INTO pg_temp.topnbench_cases(name, query, settings, server_version)
    VALUES (name, query, config, version());
    RETURN 'registered: ' || name;
END $$;

-- Apply only planner settings from the snapshot, never transaction/session
-- control settings. run_cases has a GUC nesting level, so these SET LOCALs
-- restore on normal return and on error.
CREATE FUNCTION topnbench_apply_settings(config jsonb) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE s record;
BEGIN
    FOR s IN SELECT * FROM jsonb_each_text(config) LOOP
        IF s.key LIKE 'enable_%' OR s.key LIKE '%_cost' OR
           s.key LIKE '%_collapse_limit' OR s.key IN
           ('work_mem', 'effective_cache_size', 'effective_io_concurrency',
            'hash_mem_multiplier', 'plan_cache_mode', 'cursor_tuple_fraction',
            'max_parallel_workers', 'max_parallel_workers_per_gather',
            'min_parallel_table_scan_size', 'min_parallel_index_scan_size',
            'parallel_leader_participation', 'debug_disable_sort_radix') THEN
            PERFORM set_config(s.key, s.value, true);
        END IF;
    END LOOP;
    -- This collector deliberately covers serial explicit Sorts only.
    PERFORM set_config('max_parallel_workers_per_gather', '0', true);
    PERFORM set_config('jit', 'off', true);
    PERFORM set_config('debug_print_projection_paths', 'off', true);
    PERFORM set_config('trace_sort', 'off', true);
    PERFORM set_config('topnbench.trace', 'off', true);
END $$;

-- Validate the supported shape before executing CTAS, and every actual plan.
-- These are ordinary Limit/Sort/Seq Scan cases, not a universal plan classifier.
CREATE FUNCTION topnbench_sort(plan jsonb, mode text) RETURNS jsonb
LANGUAGE plpgsql AS $$
DECLARE
    root jsonb := plan#>'{0,Plan}';
    s jsonb;
    scan jsonb;
    placement text;
BEGIN
    IF root->>'Node Type' IS DISTINCT FROM 'Limit' THEN
        RAISE EXCEPTION 'topnbench requires a root Limit';
    END IF;
    s := root#>'{Plans,0}';
    placement := 'early';
    IF s->>'Node Type' = 'Result' THEN
        placement := 'late';
        s := s#>'{Plans,0}';
    END IF;
    scan := s#>'{Plans,0}';
    IF s->>'Node Type' IS DISTINCT FROM 'Sort' OR
       jsonb_array_length(s->'Sort Key') IS DISTINCT FROM 1 OR
       scan->>'Node Type' IS DISTINCT FROM 'Seq Scan' OR
       scan->'Plans' IS NOT NULL OR
       (s->>'Parallel Aware')::boolean IS TRUE OR
       (scan->>'Parallel Aware')::boolean IS TRUE OR
       (placement = 'late' AND jsonb_array_length(scan->'Output') IS DISTINCT FROM 1) OR
       (placement = 'early' AND coalesce(jsonb_array_length(scan->'Output'), 0) < 2) OR
       (mode <> 'auto' AND mode IS DISTINCT FROM placement) THEN
        RAISE EXCEPTION 'topnbench unsupported or wrong placement: requested %, got %', mode, placement;
    END IF;
    IF s ? 'Actual Loops' AND
       ((s->>'Actual Loops')::numeric IS DISTINCT FROM 1 OR
        (scan->>'Actual Loops')::numeric IS DISTINCT FROM 1) THEN
        RAISE EXCEPTION 'topnbench requires one execution of Sort and Seq Scan';
    END IF;
    RETURN s;
END $$;

CREATE FUNCTION topnbench_run_cases() RETURNS text
LANGUAGE plpgsql SET work_mem FROM CURRENT AS $$
DECLARE
    c record;
    m text;
    modes text[];
    b integer;
    i integer;
    p jsonb;
    cp jsonb;
    s jsonb;
    expected_rows numeric;
    destination text;
BEGIN
    IF NOT EXISTS (SELECT FROM pg_temp.topnbench_cases) THEN
        RAISE EXCEPTION 'register at least one case first';
    END IF;
    IF EXISTS (SELECT FROM pg_temp.topnbench_plans) THEN
        RAISE EXCEPTION 'collection already contains results; reset before rerunning';
    END IF;
    -- Verify all cases before timing. CTAS preserves top-level planning;
    -- wrapping the SELECT inside EXCEPT would bypass the placement switch.
    FOR c IN SELECT * FROM pg_temp.topnbench_cases ORDER BY id LOOP
        PERFORM topnbench_apply_settings(c.settings);
        UPDATE pg_temp.topnbench_cases SET settings = settings ||
            jsonb_build_object('max_parallel_workers_per_gather', '0', 'jit', 'off',
              'debug_print_projection_paths', 'off', 'trace_sort', 'off',
              'topnbench.trace', 'off', 'debug_projection_placement', 'auto')
        WHERE id = c.id;
        FOREACH m IN ARRAY ARRAY['auto', 'early', 'late'] LOOP
            PERFORM set_config('debug_projection_placement', m, true);
            p := topnbench_explain(c.query, false);
            PERFORM topnbench_sort(p, m);
            destination := CASE m WHEN 'auto' THEN 'topnbench_reference'
                               ELSE 'topnbench_check' END;
            EXECUTE 'EXPLAIN (VERBOSE, COSTS ON, FORMAT JSON) CREATE TEMP TABLE ' ||
                    destination || ' ON COMMIT DROP AS ' || c.query INTO cp;
            IF p#>'{0,Plan}' IS DISTINCT FROM cp#>'{0,Plan}' THEN
                RAISE EXCEPTION 'verification changed SELECT plan: %, %', c.name, m;
            END IF;
            EXECUTE 'CREATE TEMP TABLE ' || destination ||
                    ' ON COMMIT DROP AS ' || c.query;
            IF m <> 'auto' THEN
                IF EXISTS (
                    (TABLE pg_temp.topnbench_reference EXCEPT ALL TABLE pg_temp.topnbench_check)
                    UNION ALL
                    (TABLE pg_temp.topnbench_check EXCEPT ALL TABLE pg_temp.topnbench_reference)
                ) THEN
                    RAISE EXCEPTION 'placements returned different rows: %, %', c.name, m;
                END IF;
                DROP TABLE pg_temp.topnbench_check;
            END IF;
            INSERT INTO pg_temp.topnbench_plans VALUES (c.id, m, p, NULL);
        END LOOP;
        DROP TABLE pg_temp.topnbench_reference;
    END LOOP;

    FOR b IN 1..6 LOOP
        modes := CASE b
            WHEN 1 THEN ARRAY['auto', 'early', 'late']
            WHEN 2 THEN ARRAY['late', 'early', 'auto']
            WHEN 3 THEN ARRAY['early', 'late', 'auto']
            WHEN 4 THEN ARRAY['auto', 'late', 'early']
            WHEN 5 THEN ARRAY['late', 'auto', 'early']
            ELSE ARRAY['early', 'auto', 'late'] END;
        FOR c IN SELECT * FROM pg_temp.topnbench_cases
                 ORDER BY CASE WHEN b % 2 = 1 THEN id ELSE -id END LOOP
            PERFORM topnbench_apply_settings(c.settings);
            FOREACH m IN ARRAY modes LOOP
                PERFORM set_config('debug_projection_placement', m, true);
                -- Warmup is sample 0; samples 1..3 contribute to the median.
                FOR i IN 0..3 LOOP
                    p := topnbench_explain(c.query, true);
                    PERFORM topnbench_sort(p, m);
                    IF NOT coalesce((p#>>'{0,Execution Time}')::double precision >= 0 AND
                                    (p#>>'{0,Execution Time}')::double precision < 'Infinity'::double precision, false) THEN
                        RAISE EXCEPTION 'missing execution time: %, %', c.name, m;
                    END IF;
                    INSERT INTO pg_temp.topnbench_samples VALUES (c.id, b, m, i, p);
                END LOOP;
            END LOOP;
        END LOOP;
    END LOOP;

    -- Diagnostic plans are not timing samples. Full JSON remains available.
    FOR c IN SELECT * FROM pg_temp.topnbench_cases ORDER BY id LOOP
        PERFORM topnbench_apply_settings(c.settings);
        expected_rows := NULL;
        FOREACH m IN ARRAY ARRAY['auto', 'early', 'late'] LOOP
            PERFORM set_config('debug_projection_placement', m, true);
            EXECUTE 'EXPLAIN (ANALYZE, VERBOSE, BUFFERS, COSTS ON, '
                    'TIMING OFF, SUMMARY ON, FORMAT JSON) ' || c.query INTO p;
            s := topnbench_sort(p, m);
            IF m = 'auto' THEN
                expected_rows := (s#>>'{Plans,0,Actual Rows}')::numeric;
            ELSIF (s#>>'{Plans,0,Actual Rows}')::numeric IS DISTINCT FROM expected_rows THEN
                RAISE EXCEPTION 'different Sort input rows: %, %', c.name, m;
            END IF;
            UPDATE pg_temp.topnbench_plans SET actual = p
            WHERE case_id = c.id AND mode = m;
        END LOOP;
        IF EXISTS (
            SELECT FROM pg_temp.topnbench_samples r
            WHERE r.case_id = c.id AND
              (topnbench_sort(r.plan, r.mode)#>>'{Plans,0,Actual Rows}')::numeric
              IS DISTINCT FROM expected_rows
        ) THEN
            RAISE EXCEPTION 'Sort input row count changed during measurement: %', c.name;
        END IF;
        UPDATE pg_temp.topnbench_cases SET verified = true WHERE id = c.id;
    END LOOP;
    RETURN format('PASS: %s cases; 3 modes; 6 batches; 3 timed samples per batch; equal results and placements verified',
                  (SELECT count(*) FROM pg_temp.topnbench_cases));
END $$;

CREATE FUNCTION topnbench_report()
RETURNS TABLE (test text, work_mem text, mode text, projection text,
              cost numeric, ms numeric, sort_width integer, sort_method text,
              space_type text, space_kb integer)
LANGUAGE plpgsql AS $$
BEGIN
    IF EXISTS (SELECT FROM pg_temp.topnbench_cases WHERE NOT verified) THEN
        RAISE EXCEPTION 'collection incomplete; call topnbench_run_cases()';
    END IF;
    RETURN QUERY
    SELECT c.name, c.settings->>'work_mem', p.mode,
           CASE WHEN p.actual#>>'{0,Plan,Plans,0,Node Type}' = 'Result'
                THEN 'late' ELSE 'early' END,
           round((p.estimated#>>'{0,Plan,Total Cost}')::numeric, 2),
           round(percentile_cont(0.5) WITHIN GROUP (ORDER BY b.ms)::numeric, 3),
           (s.plan->>'Plan Width')::integer, s.plan->>'Sort Method',
           s.plan->>'Sort Space Type', (s.plan->>'Sort Space Used')::integer
    FROM pg_temp.topnbench_cases c
    JOIN pg_temp.topnbench_plans p ON p.case_id = c.id
    JOIN pg_temp.topnbench_batches b ON b.case_id = c.id AND b.mode = p.mode
    CROSS JOIN LATERAL (SELECT topnbench_sort(p.actual, p.mode) AS plan) s
    GROUP BY c.id, c.name, c.settings, p.mode, p.estimated, p.actual, s.plan
    ORDER BY c.id, CASE p.mode WHEN 'auto' THEN 1 WHEN 'early' THEN 2 ELSE 3 END;
END $$;

CREATE FUNCTION topnbench_summary()
RETURNS TABLE (test text, auto_choice text, auto_ms numeric,
              early_ms numeric, late_ms numeric, late_over_early numeric,
              auto_over_best numeric, late_wins bigint, early_wins bigint)
LANGUAGE plpgsql AS $$
BEGIN
    IF EXISTS (SELECT FROM pg_temp.topnbench_cases WHERE NOT verified) THEN
        RAISE EXCEPTION 'collection incomplete; call topnbench_run_cases()';
    END IF;
    RETURN QUERY
    SELECT c.name,
           CASE WHEN p.actual#>>'{0,Plan,Plans,0,Node Type}' = 'Result'
                THEN 'late' ELSE 'early' END,
           round(percentile_cont(0.5) WITHIN GROUP (ORDER BY a.ms)::numeric, 3),
           round(percentile_cont(0.5) WITHIN GROUP (ORDER BY e.ms)::numeric, 3),
           round(percentile_cont(0.5) WITHIN GROUP (ORDER BY l.ms)::numeric, 3),
           round(percentile_cont(0.5) WITHIN GROUP
                 (ORDER BY l.ms / nullif(e.ms, 0))::numeric, 3),
           round(percentile_cont(0.5) WITHIN GROUP
                 (ORDER BY a.ms / nullif(least(e.ms, l.ms), 0))::numeric, 3),
           count(*) FILTER (WHERE l.ms / nullif(e.ms, 0) < 0.95),
           count(*) FILTER (WHERE l.ms / nullif(e.ms, 0) > 1.05)
    FROM pg_temp.topnbench_cases c
    JOIN pg_temp.topnbench_plans p ON p.case_id = c.id AND p.mode = 'auto'
    JOIN pg_temp.topnbench_batches a ON a.case_id = c.id AND a.mode = 'auto'
    JOIN pg_temp.topnbench_batches e ON e.case_id = c.id AND e.batch = a.batch AND e.mode = 'early'
    JOIN pg_temp.topnbench_batches l ON l.case_id = c.id AND l.batch = a.batch AND l.mode = 'late'
    GROUP BY c.id, c.name, p.actual ORDER BY c.id;
END $$;

-- One JSON record per case. Export/import is data-only: never execute the SQL
-- or apply settings from an imported archive merely to generate a report.
CREATE FUNCTION topnbench_export() RETURNS SETOF jsonb
LANGUAGE plpgsql AS $$
BEGIN
    IF EXISTS (SELECT FROM pg_temp.topnbench_cases WHERE NOT verified) THEN
        RAISE EXCEPTION 'cannot export an incomplete collection';
    END IF;
    RETURN QUERY
    SELECT jsonb_build_object('format', 'topnbench-raw', 'version', 1,
        'case', to_jsonb(c) - 'id',
        'plans', (SELECT jsonb_agg(to_jsonb(p) - 'case_id' ORDER BY p.mode)
                  FROM pg_temp.topnbench_plans p WHERE p.case_id = c.id),
        'samples', (SELECT jsonb_agg(to_jsonb(s) - 'case_id' ORDER BY s.batch, s.mode, s.sample)
                    FROM pg_temp.topnbench_samples s WHERE s.case_id = c.id))
    FROM pg_temp.topnbench_cases c ORDER BY c.id;
END $$;

CREATE FUNCTION topnbench_import(record jsonb) RETURNS text
LANGUAGE plpgsql AS $$
DECLARE
    new_id integer;
    p record;
BEGIN
    IF record->>'format' IS DISTINCT FROM 'topnbench-raw' OR
       record->>'version' IS DISTINCT FROM '1' OR
       record#>>'{case,verified}' IS DISTINCT FROM 'true' OR
       jsonb_array_length(record->'plans') IS DISTINCT FROM 3 OR
       jsonb_array_length(record->'samples') IS DISTINCT FROM 72 THEN
        RAISE EXCEPTION 'unsupported or incomplete topnbench archive record';
    END IF;
    INSERT INTO pg_temp.topnbench_cases(name, query, settings, server_version, registered_at, verified)
    SELECT x.name, x.query, x.settings, x.server_version, x.registered_at, true
    FROM jsonb_to_record(record->'case') AS x(name text, query text, settings jsonb,
        server_version text, registered_at timestamptz, verified boolean)
    RETURNING id INTO new_id;
    INSERT INTO pg_temp.topnbench_plans
    SELECT new_id, x.mode, x.estimated, x.actual
    FROM jsonb_to_recordset(record->'plans') AS x(mode text, estimated jsonb, actual jsonb);
    INSERT INTO pg_temp.topnbench_samples
    SELECT new_id, x.batch, x.mode, x.sample, x.plan
    FROM jsonb_to_recordset(record->'samples') AS x(batch integer, mode text, sample integer, plan jsonb);
    -- PKs/checks and counts establish complete coverage of all mode/batch/sample
    -- combinations. Reject invalid plans/times instead of silently dropping rows.
    FOR p IN SELECT mode, estimated, actual FROM pg_temp.topnbench_plans WHERE case_id = new_id LOOP
        PERFORM topnbench_sort(p.estimated, p.mode);
        PERFORM topnbench_sort(p.actual, p.mode);
    END LOOP;
    FOR p IN SELECT mode, plan FROM pg_temp.topnbench_samples WHERE case_id = new_id LOOP
        PERFORM topnbench_sort(p.plan, p.mode);
        IF NOT coalesce((p.plan#>>'{0,Execution Time}')::double precision >= 0 AND
                        (p.plan#>>'{0,Execution Time}')::double precision < 'Infinity'::double precision, false) THEN
            RAISE EXCEPTION 'invalid archived execution time';
        END IF;
    END LOOP;
    RETURN 'imported: ' || (record#>>'{case,name}');
END $$;

CREATE FUNCTION topnbench_check_unchanged(query text) RETURNS text
LANGUAGE plpgsql SET work_mem FROM CURRENT AS $$
DECLARE baseline jsonb; alternative jsonb; m text;
BEGIN
    PERFORM set_config('debug_projection_placement', 'auto', true);
    baseline := topnbench_explain(query, false);
    FOREACH m IN ARRAY ARRAY['early', 'late'] LOOP
        PERFORM set_config('debug_projection_placement', m, true);
        alternative := topnbench_explain(query, false);
        IF baseline IS DISTINCT FROM alternative THEN
            RAISE EXCEPTION 'placement switch changed excluded query plan: %', query;
        END IF;
    END LOOP;
    RETURN 'PASS: excluded shape unchanged';
END $$;

-- Return commands to psql \gexec so VACUUM runs as a top-level command.
CREATE FUNCTION topnbench_prepare() RETURNS SETOF text
LANGUAGE plpgsql AS $setup$
BEGIN
    RETURN NEXT $command$DROP TABLE IF EXISTS topnbench_data;
CREATE UNLOGGED TABLE topnbench_data (
 a integer NOT NULL, a_desc integer NOT NULL, a_random integer NOT NULL,
 same1 integer NOT NULL, same2 integer NOT NULL, inverse integer NOT NULL);
INSERT INTO topnbench_data
 SELECT g, 1000001-g, ((g::bigint*48271)%1000003)::integer, g, g, 1000001-g
 FROM generate_series(1,1000000) g;
ALTER TABLE topnbench_data SET (parallel_workers=2);
ANALYZE topnbench_data;
DROP TABLE IF EXISTS topnbench_width_underestimate;
CREATE UNLOGGED TABLE topnbench_width_underestimate
 (a integer NOT NULL, sort_key integer NOT NULL, payload text NOT NULL)
 WITH (autovacuum_enabled=false);
INSERT INTO topnbench_width_underestimate
 SELECT g, ((g::bigint*48271)%100003)::integer, 'x' FROM generate_series(1,100000) g;
ANALYZE topnbench_width_underestimate;
UPDATE topnbench_width_underestimate SET payload =
 md5(a::text||':1')||md5(a::text||':2')||md5(a::text||':3')||md5(a::text||':4')||
 md5(a::text||':5')||md5(a::text||':6')||md5(a::text||':7')||md5(a::text||':8');$command$;
    RETURN NEXT $command$VACUUM topnbench_width_underestimate;$command$;
    RETURN NEXT $command$DROP TABLE IF EXISTS topnbench_width_overestimate;
CREATE UNLOGGED TABLE topnbench_width_overestimate
 (a integer NOT NULL, payload text NOT NULL) WITH (autovacuum_enabled=false);
INSERT INTO topnbench_width_overestimate
 SELECT a,payload FROM topnbench_width_underestimate;
ANALYZE topnbench_width_overestimate;
UPDATE topnbench_width_overestimate SET payload='x';$command$;
    RETURN NEXT $command$VACUUM topnbench_width_overestimate;$command$;
    RETURN NEXT $command$DROP TABLE IF EXISTS topnbench_width_accurate;
CREATE UNLOGGED TABLE topnbench_width_accurate
 (LIKE topnbench_width_underestimate INCLUDING ALL);
INSERT INTO topnbench_width_accurate SELECT * FROM topnbench_width_underestimate;
ANALYZE topnbench_width_accurate;$command$;
    RETURN NEXT $command$DROP TABLE IF EXISTS topnbench_copy_width_8;
CREATE UNLOGGED TABLE topnbench_copy_width_8
 (sort_key integer NOT NULL, payload text NOT NULL);
INSERT INTO topnbench_copy_width_8
 SELECT ((g::bigint*48271)%100003)::integer,
 left(repeat(md5(g::text), 1), 8)
 FROM generate_series(1,100000) g;
ANALYZE topnbench_copy_width_8;$command$;
    RETURN NEXT $command$DROP TABLE IF EXISTS topnbench_copy_width_32;
CREATE UNLOGGED TABLE topnbench_copy_width_32
 (sort_key integer NOT NULL, payload text NOT NULL);
INSERT INTO topnbench_copy_width_32
 SELECT ((g::bigint*48271)%100003)::integer,
 left(repeat(md5(g::text), 1), 32)
 FROM generate_series(1,100000) g;
ANALYZE topnbench_copy_width_32;$command$;
    RETURN NEXT $command$DROP TABLE IF EXISTS topnbench_copy_width_96;
CREATE UNLOGGED TABLE topnbench_copy_width_96
 (sort_key integer NOT NULL, payload text NOT NULL);
INSERT INTO topnbench_copy_width_96
 SELECT ((g::bigint*48271)%100003)::integer,
 left(repeat(md5(g::text), 3), 96)
 FROM generate_series(1,100000) g;
ANALYZE topnbench_copy_width_96;$command$;
    RETURN NEXT $command$DROP TABLE IF EXISTS topnbench_copy_width_128;
CREATE UNLOGGED TABLE topnbench_copy_width_128
 (sort_key integer NOT NULL, payload text NOT NULL);
INSERT INTO topnbench_copy_width_128
 SELECT ((g::bigint*48271)%100003)::integer,
 left(repeat(md5(g::text), 4), 128)
 FROM generate_series(1,100000) g;
ANALYZE topnbench_copy_width_128;$command$;
    RETURN NEXT $command$DROP TABLE IF EXISTS topnbench_copy_width_160;
CREATE UNLOGGED TABLE topnbench_copy_width_160
 (sort_key integer NOT NULL, payload text NOT NULL);
INSERT INTO topnbench_copy_width_160
 SELECT ((g::bigint*48271)%100003)::integer,
 left(repeat(md5(g::text), 5), 160)
 FROM generate_series(1,100000) g;
ANALYZE topnbench_copy_width_160;$command$;
    RETURN NEXT $command$DROP TABLE IF EXISTS topnbench_copy_width_192;
CREATE UNLOGGED TABLE topnbench_copy_width_192
 (sort_key integer NOT NULL, payload text NOT NULL);
INSERT INTO topnbench_copy_width_192
 SELECT ((g::bigint*48271)%100003)::integer,
 left(repeat(md5(g::text), 6), 192)
 FROM generate_series(1,100000) g;
ANALYZE topnbench_copy_width_192;$command$;
    RETURN NEXT $command$DROP TABLE IF EXISTS topnbench_copy_width_256;
CREATE UNLOGGED TABLE topnbench_copy_width_256
 (sort_key integer NOT NULL, payload text NOT NULL);
INSERT INTO topnbench_copy_width_256
 SELECT ((g::bigint*48271)%100003)::integer,
 left(repeat(md5(g::text), 8), 256)
 FROM generate_series(1,100000) g;
ANALYZE topnbench_copy_width_256;$command$;
    RETURN NEXT $command$DROP TABLE IF EXISTS topnbench_copy_width_512;
CREATE UNLOGGED TABLE topnbench_copy_width_512
 (sort_key integer NOT NULL, payload text NOT NULL);
INSERT INTO topnbench_copy_width_512
 SELECT ((g::bigint*48271)%100003)::integer,
 left(repeat(md5(g::text), 16), 512)
 FROM generate_series(1,100000) g;
ANALYZE topnbench_copy_width_512;$command$;
    RETURN NEXT $command$DROP TABLE IF EXISTS topnbench_copy_width_1024;
CREATE UNLOGGED TABLE topnbench_copy_width_1024
 (sort_key integer NOT NULL, payload text NOT NULL);
INSERT INTO topnbench_copy_width_1024
 SELECT ((g::bigint*48271)%100003)::integer,
 left(repeat(md5(g::text), 32), 1024)
 FROM generate_series(1,100000) g;
ANALYZE topnbench_copy_width_1024;$command$;
    RETURN NEXT $command$DROP TABLE IF EXISTS topnbench_heap_ascending;
CREATE UNLOGGED TABLE topnbench_heap_ascending(k integer NOT NULL,payload integer NOT NULL);
INSERT INTO topnbench_heap_ascending
 SELECT k,-k FROM (SELECT g,g AS k FROM generate_series(0,8192) g) s ORDER BY g;
ANALYZE topnbench_heap_ascending;$command$;
    RETURN NEXT $command$DROP TABLE IF EXISTS topnbench_heap_descending;
CREATE UNLOGGED TABLE topnbench_heap_descending(k integer NOT NULL,payload integer NOT NULL);
INSERT INTO topnbench_heap_descending
 SELECT k,-k FROM (SELECT g,8192-g AS k FROM generate_series(0,8192) g) s ORDER BY g;
ANALYZE topnbench_heap_descending;$command$;
    RETURN NEXT $command$DROP TABLE IF EXISTS topnbench_heap_random;
CREATE UNLOGGED TABLE topnbench_heap_random(k integer NOT NULL,payload integer NOT NULL);
INSERT INTO topnbench_heap_random
 SELECT k,-k FROM (SELECT g,((g::bigint*48271)%8193)::integer AS k FROM generate_series(0,8192) g) s ORDER BY g;
ANALYZE topnbench_heap_random;$command$;
END $setup$;

CREATE FUNCTION topnbench_capture_begin(expected_samples integer DEFAULT NULL)
RETURNS text LANGUAGE plpgsql AS $$
DECLARE r text := md5(clock_timestamp()::text || random()::text || pg_backend_pid()::text);
BEGIN
    IF expected_samples < 1 THEN RAISE EXCEPTION 'expected_samples must be positive or NULL'; END IF;
    CREATE TEMP TABLE IF NOT EXISTS topnbench_capture_state(run_id text, seq bigint, expected integer);
    TRUNCATE pg_temp.topnbench_capture_state;
    INSERT INTO pg_temp.topnbench_capture_state VALUES(r, 0, expected_samples);
    RETURN 'TOPNBENCH ' || jsonb_build_object('event','begin','format',1,'run',r,
        'expected',expected_samples,'server',version(),'started',clock_timestamp())::text;
END $$;

CREATE FUNCTION topnbench_capture(case_name text, variant text,
    check_name text DEFAULT 'none', sample_kind text DEFAULT 'timed', batch_no integer DEFAULT 1)
RETURNS text LANGUAGE plpgsql AS $$
DECLARE s record; config jsonb;
BEGIN
    IF case_name IS NULL OR btrim(case_name) = '' OR variant IS NULL OR btrim(variant) = ''
       OR check_name IS NULL OR sample_kind IS NULL OR batch_no IS NULL OR batch_no < 1
       OR sample_kind NOT IN ('timed','plan','warmup','diagnostic') THEN
        RAISE EXCEPTION 'invalid capture label, sample kind or batch';
    END IF;
    UPDATE pg_temp.topnbench_capture_state SET seq = seq+1 RETURNING * INTO STRICT s;
    SELECT jsonb_object_agg(name,current_setting(name)) INTO config FROM pg_settings
    WHERE name LIKE 'enable_%' OR name LIKE 'cpu_%' OR name IN
       ('work_mem','hash_mem_multiplier','jit','max_parallel_workers',
        'max_parallel_workers_per_gather','max_worker_processes','parallel_leader_participation',
        'min_parallel_table_scan_size','min_parallel_index_scan_size','parallel_setup_cost',
        'parallel_tuple_cost','seq_page_cost','random_page_cost','effective_cache_size',
        'effective_io_concurrency','maintenance_io_concurrency','shared_buffers',
        'cursor_tuple_fraction','default_statistics_target','synchronize_seqscans',
        'debug_projection_placement','debug_disable_sort_radix','debug_print_projection_paths',
        'trace_sort','search_path');
    RETURN 'TOPNBENCH ' || jsonb_build_object('event','sample','run',s.run_id,'seq',s.seq,
        'case',case_name,'variant',variant,'check',check_name,'kind',sample_kind,
        'batch',batch_no,'settings',config)::text;
END $$;

CREATE FUNCTION topnbench_capture_end() RETURNS text LANGUAGE plpgsql AS $$
DECLARE s record;
BEGIN
    SELECT * INTO STRICT s FROM pg_temp.topnbench_capture_state;
    IF s.expected IS NOT NULL AND s.expected <> s.seq THEN
        RAISE EXCEPTION 'expected % captures, got %',s.expected,s.seq;
    END IF;
    RETURN 'TOPNBENCH ' || jsonb_build_object('event','end','run',s.run_id,'count',s.seq)::text;
END $$;

CREATE FUNCTION topnbench_file_reset() RETURNS void LANGUAGE plpgsql AS $$
BEGIN
    DROP VIEW IF EXISTS pg_temp.topnbench_file_batches;
    DROP VIEW IF EXISTS pg_temp.topnbench_file_nodes;
    DROP TABLE IF EXISTS pg_temp.topnbench_file_samples;
    DROP TABLE IF EXISTS pg_temp.topnbench_file_lines;
    DROP TABLE IF EXISTS pg_temp.topnbench_file_state;
    CREATE TEMP TABLE topnbench_file_lines(line_no bigint GENERATED ALWAYS AS IDENTITY, line text);
    CREATE TEMP TABLE topnbench_file_state(header jsonb, loaded boolean NOT NULL);
    INSERT INTO pg_temp.topnbench_file_state VALUES(NULL,false);
    CREATE TEMP TABLE topnbench_file_samples(
        sample_id bigint PRIMARY KEY, case_name text NOT NULL, variant text NOT NULL,
        check_name text NOT NULL, kind text NOT NULL, batch integer NOT NULL,
        settings jsonb NOT NULL, plan jsonb NOT NULL);
    CREATE TEMP VIEW topnbench_file_nodes AS
    WITH RECURSIVE n(sample_id,path,node) AS (
        SELECT sample_id,'0'::text,plan#>'{0,Plan}' FROM pg_temp.topnbench_file_samples
        UNION ALL
        SELECT n.sample_id,n.path||'.'||c.ord,n2
        FROM n CROSS JOIN LATERAL jsonb_array_elements(n.node->'Plans') WITH ORDINALITY c(n2,ord)
    ) SELECT * FROM n;
    CREATE TEMP VIEW topnbench_file_batches AS
    SELECT case_name,variant,batch,count(*) AS n,
        percentile_cont(0.5) WITHIN GROUP (ORDER BY (plan#>>'{0,Execution Time}')::double precision) AS ms
    FROM pg_temp.topnbench_file_samples WHERE kind='timed'
    GROUP BY case_name,variant,batch;
END $$;

-- Internal parser helper: only parses JSON and inserts data, never executes archived text.
CREATE FUNCTION topnbench_file_sample(meta jsonb, body text) RETURNS void LANGUAGE plpgsql AS $$
DECLARE p jsonb; t numeric;
BEGIN
    IF meta IS NULL OR body IS NULL OR btrim(body) = '' THEN
        RAISE EXCEPTION 'missing EXPLAIN after capture marker';
    END IF;
    BEGIN
        p := body::jsonb;
    EXCEPTION WHEN invalid_text_representation THEN
        RAISE EXCEPTION 'invalid EXPLAIN JSON for %/%',meta->>'case',meta->>'variant';
    END;
    IF jsonb_typeof(p) IS DISTINCT FROM 'array' OR jsonb_array_length(p) <> 1
       OR p#>>'{0,Plan,Node Type}' IS NULL THEN
        RAISE EXCEPTION 'expected one EXPLAIN JSON document';
    END IF;
    IF meta->>'kind' NOT IN ('timed','plan','warmup','diagnostic') OR
       coalesce(meta->>'case','') = '' OR coalesce(meta->>'variant','') = '' OR
       jsonb_typeof(meta->'settings') IS DISTINCT FROM 'object' OR
       (meta->>'batch')::integer < 1 THEN
        RAISE EXCEPTION 'invalid sample metadata';
    END IF;
    IF meta->>'kind' <> 'plan' THEN
        t := (p#>>'{0,Execution Time}')::numeric;
        IF t IS NULL OR t < 0 OR t::text IN ('NaN','Infinity','-Infinity') THEN
            RAISE EXCEPTION 'executed sample has no valid Execution Time';
        END IF;
    ELSIF p->0 ? 'Execution Time' THEN
        RAISE EXCEPTION 'plan-only sample contains execution timing';
    END IF;
    INSERT INTO pg_temp.topnbench_file_samples VALUES(
        (meta->>'seq')::bigint,meta->>'case',meta->>'variant',meta->>'check',
        meta->>'kind',(meta->>'batch')::integer,meta->'settings',p);
END $$;

CREATE FUNCTION topnbench_file_load() RETURNS text LANGUAGE plpgsql AS $$
DECLARE l record; h jsonb; m jsonb; pending jsonb; body text := ''; ended boolean := false;
        n bigint := 0; last_seq bigint := 0;
BEGIN
    IF (SELECT loaded FROM pg_temp.topnbench_file_state) THEN
        RAISE EXCEPTION 'call topnbench_file_reset before loading another file';
    END IF;
    FOR l IN SELECT * FROM pg_temp.topnbench_file_lines ORDER BY line_no LOOP
        IF coalesce(btrim(l.line),'') = '' THEN CONTINUE; END IF;
        IF ended THEN RAISE EXCEPTION 'data after end marker at line %',l.line_no; END IF;
        IF left(l.line,10) = 'TOPNBENCH ' THEN
            m := substr(l.line,11)::jsonb;
            IF pending IS NOT NULL THEN
                PERFORM topnbench_file_sample(pending,body);
                pending := NULL; body := ''; n := n+1;
            END IF;
            IF m->>'event' = 'begin' THEN
                IF h IS NOT NULL OR m->>'format' IS DISTINCT FROM '1' OR m->>'run' IS NULL THEN
                    RAISE EXCEPTION 'invalid or duplicate header';
                END IF;
                h := m;
            ELSE
                IF h IS NULL OR m->>'run' IS DISTINCT FROM h->>'run' THEN
                    RAISE EXCEPTION 'missing header or mismatched run id';
                END IF;
                IF m->>'event' = 'sample' THEN
                    IF (m->>'seq')::bigint IS DISTINCT FROM last_seq+1 THEN
                        RAISE EXCEPTION 'missing or repeated sample marker';
                    END IF;
                    last_seq := last_seq+1; pending := m;
                ELSIF m->>'event' = 'end' THEN
                    IF (m->>'count')::bigint IS DISTINCT FROM n OR n = 0 OR
                       (h->>'expected' IS NOT NULL AND (h->>'expected')::bigint <> n) THEN
                        RAISE EXCEPTION 'sample count does not match header/end marker';
                    END IF;
                    ended := true;
                ELSE RAISE EXCEPTION 'unknown marker event';
                END IF;
            END IF;
        ELSE
            IF pending IS NULL THEN RAISE EXCEPTION 'unlabelled output at line %',l.line_no; END IF;
            body := body || l.line || E'\n';
        END IF;
    END LOOP;
    IF NOT ended OR pending IS NOT NULL THEN RAISE EXCEPTION 'incomplete file: missing plan/end marker'; END IF;
    IF EXISTS (SELECT FROM pg_temp.topnbench_file_samples GROUP BY case_name,variant
               HAVING count(DISTINCT settings) <> 1 OR count(DISTINCT check_name) <> 1) THEN
        RAISE EXCEPTION 'settings/check changed under the same case/variant label; use a distinct label';
    END IF;
    IF EXISTS (SELECT FROM pg_temp.topnbench_file_samples GROUP BY case_name
               HAVING count(DISTINCT check_name) <> 1) THEN
        RAISE EXCEPTION 'check label changed within one case';
    END IF;
    UPDATE pg_temp.topnbench_file_state SET header=h,loaded=true;
    RETURN format('Imported %s labelled plans; query results have not been verified.',n);
END $$;

CREATE FUNCTION topnbench_file_ready() RETURNS void LANGUAGE plpgsql AS $$
BEGIN
    IF NOT coalesce((SELECT loaded FROM pg_temp.topnbench_file_state),false) THEN
        RAISE EXCEPTION 'load a complete capture file first';
    END IF;
END $$;

CREATE FUNCTION topnbench_file_report() RETURNS TABLE(
    case_name text, variant text, work_mem text, timed_samples bigint, batches bigint,
    median_ms numeric, root_cost_min numeric, root_cost_max numeric,
    sort_width text, sort_method text, space_type text, space_kb text)
LANGUAGE plpgsql AS $$
BEGIN
    PERFORM topnbench_file_ready();
    RETURN QUERY
    WITH summary AS (
        SELECT s.case_name,s.variant,min(s.settings->>'work_mem') AS mem,
          count(*) FILTER (WHERE s.kind='timed') AS samples,
          min((s.plan#>>'{0,Plan,Total Cost}')::numeric) AS lo,
          max((s.plan#>>'{0,Plan,Total Cost}')::numeric) AS hi
        FROM pg_temp.topnbench_file_samples s GROUP BY s.case_name,s.variant
    ), timing AS (
        SELECT b.case_name,b.variant,count(*) AS batches,
          percentile_cont(0.5) WITHIN GROUP (ORDER BY b.ms) AS ms
        FROM pg_temp.topnbench_file_batches b GROUP BY b.case_name,b.variant
    ), sorts AS (
        SELECT s.case_name,s.variant,
          string_agg(DISTINCT n.node->>'Plan Width','/') AS width,
          string_agg(DISTINCT n.node->>'Sort Method','/') AS method,
          string_agg(DISTINCT n.node->>'Sort Space Type','/') AS space,
          string_agg(DISTINCT n.node->>'Sort Space Used','/') AS kb
        FROM pg_temp.topnbench_file_samples s JOIN pg_temp.topnbench_file_nodes n USING(sample_id)
        WHERE n.node->>'Node Type' IN ('Sort','Incremental Sort') GROUP BY s.case_name,s.variant
    )
    SELECT s.case_name,s.variant,s.mem,s.samples,coalesce(t.batches,0),round(t.ms::numeric,3),
           s.lo,s.hi,n.width,n.method,n.space,n.kb
    FROM summary s LEFT JOIN timing t USING(case_name,variant) LEFT JOIN sorts n USING(case_name,variant)
    ORDER BY s.case_name,s.variant;
END $$;

CREATE FUNCTION topnbench_file_ratios() RETURNS TABLE(
    case_name text, comparison text, paired_batches bigint, median_ratio numeric,
    faster_batches bigint, slower_batches bigint)
LANGUAGE plpgsql AS $$
BEGIN
    PERFORM topnbench_file_ready();
    RETURN QUERY
    WITH pairs(num,den) AS (VALUES
        ('auto','upstream-auto'),('auto','path-only-auto'),('auto','manual-late'),
        ('manual-late','forced-early'),('late','early'),('auto','early'),('auto','late'),
        ('wide','narrow'),('sort-tuple','sort-datum'),('late-work-0','sort-datum'),('late-work-16','sort-datum'),
        ('radix-disabled/auto','default/auto'),('radix-disabled/manual-late','default/manual-late'),
        ('radix-disabled/forced-early','default/forced-early'),
        ('datum-on/auto','datum-off/auto'),('datum-on/manual-late','datum-off/manual-late'),
        ('datum-on/forced-early','datum-off/forced-early'),
        ('total-on/auto','total-off/auto'),('total-on/manual-late','total-off/manual-late'),
        ('total-on/forced-early','total-off/forced-early')),
    r AS (
        SELECT a.case_name,p.num||' / '||p.den AS label,a.ms/b.ms AS ratio
        FROM pairs p JOIN pg_temp.topnbench_file_batches a ON a.variant=p.num
        JOIN pg_temp.topnbench_file_batches b ON b.variant=p.den AND b.case_name=a.case_name
                                             AND b.batch=a.batch AND b.n=a.n
        WHERE b.ms>0
    ) SELECT r.case_name,r.label,count(*),
       round((percentile_cont(0.5) WITHIN GROUP (ORDER BY r.ratio))::numeric,3),
       count(*) FILTER (WHERE r.ratio<0.95),count(*) FILTER (WHERE r.ratio>1.05)
      FROM r GROUP BY r.case_name,r.label ORDER BY r.case_name,r.label;
END $$;

-- Compare planner-visible fields, stripping runtime counters from ANALYZE plans.
CREATE FUNCTION topnbench_file_estimate(node jsonb) RETURNS jsonb
LANGUAGE plpgsql IMMUTABLE STRICT AS $$
DECLARE result jsonb := '{}'::jsonb; kv record; child jsonb; children jsonb;
BEGIN
    FOR kv IN SELECT * FROM jsonb_each(node) LOOP
        IF kv.key = 'Plans' THEN
            children := '[]'::jsonb;
            FOR child IN SELECT * FROM jsonb_array_elements(kv.value) LOOP
                children := children || jsonb_build_array(topnbench_file_estimate(child));
            END LOOP;
            result := result || jsonb_build_object(kv.key,children);
        ELSIF kv.key !~ '^(Actual |Shared |Local |Temp |I/O |WAL |Rows Removed |Sort Method$|Sort Space |Workers$|Heap Fetches$|Memory |Full-sort Groups$|Pre-sorted Groups$)' THEN
            result := result || jsonb_build_object(kv.key,kv.value);
        END IF;
    END LOOP;
    RETURN result;
END $$;

CREATE FUNCTION topnbench_file_checks() RETURNS TABLE(case_name text, check_name text, status text)
LANGUAGE plpgsql AS $$
DECLARE c record; s record; first_plan jsonb; p jsonb; a jsonb; b jsonb; n integer;
BEGIN
    PERFORM topnbench_file_ready();
    FOR c IN SELECT f.case_name,min(f.check_name) AS check_name
             FROM pg_temp.topnbench_file_samples f GROUP BY f.case_name ORDER BY f.case_name LOOP
        case_name := c.case_name; check_name := c.check_name; status := 'not checked: EXPLAIN contains no result rows';
        SELECT count(DISTINCT f.variant) INTO n FROM pg_temp.topnbench_file_samples f WHERE f.case_name=c.case_name;
        IF c.check_name='unchanged' AND n<2 THEN
            status := 'not checked: at least two variants required'; RETURN NEXT; CONTINUE;
        ELSIF c.check_name='algorithm' AND n<>6 THEN
            status := 'not checked: all six algorithm variants required'; RETURN NEXT; CONTINUE;
        ELSIF c.check_name='same-query' AND n<>3 THEN
            status := 'not checked: auto/early/late all required'; RETURN NEXT; CONTINUE;
        ELSIF c.check_name='datum-cheaper' AND n<>4 THEN
            status := 'not checked: all four Datum guard variants required'; RETURN NEXT; CONTINUE;
        END IF;
        IF c.check_name='unchanged' THEN
            first_plan := NULL; status := 'plan unchanged';
            FOR s IN SELECT f.plan FROM pg_temp.topnbench_file_samples f WHERE f.case_name=c.case_name LOOP
                p := topnbench_file_estimate(s.plan#>'{0,Plan}');
                IF first_plan IS NOT NULL AND p IS DISTINCT FROM first_plan THEN status := 'FAIL: plan changed'; END IF;
                first_plan := p;
            END LOOP;
        ELSIF c.check_name='datum-cheaper' THEN
            SELECT f.plan#>'{0,Plan}' INTO STRICT a FROM pg_temp.topnbench_file_samples f
              WHERE f.case_name=c.case_name AND f.variant='datum-off' ORDER BY f.sample_id LIMIT 1;
            SELECT f.plan#>'{0,Plan}' INTO STRICT b FROM pg_temp.topnbench_file_samples f
              WHERE f.case_name=c.case_name AND f.variant='datum-on' ORDER BY f.sample_id LIMIT 1;
            status := CASE WHEN (b->>'Total Cost')::numeric < (a->>'Total Cost')::numeric
                           THEN 'eligible Datum cost decreased' ELSE 'FAIL: Datum cost did not decrease' END;
            SELECT f.plan#>'{0,Plan}' INTO STRICT a FROM pg_temp.topnbench_file_samples f
              WHERE f.case_name=c.case_name AND f.variant='width-off-datum-off' ORDER BY f.sample_id LIMIT 1;
            SELECT f.plan#>'{0,Plan}' INTO STRICT b FROM pg_temp.topnbench_file_samples f
              WHERE f.case_name=c.case_name AND f.variant='width-off-datum-on' ORDER BY f.sample_id LIMIT 1;
            IF a IS DISTINCT FROM b THEN status := 'FAIL: Datum cost leaked into width-cost OFF'; END IF;
        ELSIF c.check_name='same-query' THEN
            status := 'projection/serial shape checked; result values not checked';
            FOR s IN SELECT * FROM pg_temp.topnbench_file_samples f WHERE f.case_name=c.case_name LOOP
                BEGIN
                    PERFORM topnbench_sort(s.plan,s.variant);
                EXCEPTION WHEN OTHERS THEN status := 'FAIL: '||SQLERRM;
                END;
            END LOOP;
            SELECT count(DISTINCT node#>>'{Plans,0,Actual Rows}') INTO n
              FROM pg_temp.topnbench_file_nodes JOIN pg_temp.topnbench_file_samples USING(sample_id)
              WHERE topnbench_file_samples.case_name=c.case_name AND node->>'Node Type'='Sort';
            IF n<>1 THEN status := 'FAIL: inconsistent Sort input rows'; END IF;
        ELSIF c.check_name='algorithm' THEN
            status := 'planner fields unchanged across radix toggle';
            IF EXISTS (
                SELECT FROM pg_temp.topnbench_file_samples x JOIN pg_temp.topnbench_file_samples y
                  ON x.case_name=y.case_name AND x.batch=y.batch
                 AND replace(x.variant,'default/','')=replace(y.variant,'radix-disabled/','')
                WHERE x.case_name=c.case_name AND x.variant LIKE 'default/%' AND y.variant LIKE 'radix-disabled/%'
                  AND topnbench_file_estimate(x.plan#>'{0,Plan}') IS DISTINCT FROM topnbench_file_estimate(y.plan#>'{0,Plan}')
            ) THEN status := 'FAIL: radix toggle changed planner fields'; END IF;
        ELSIF c.check_name='heap' THEN
            status := 'heap plan/space checked; result keys/payloads not checked';
            FOR s IN SELECT f.sample_id,f.variant FROM pg_temp.topnbench_file_samples f
                     WHERE f.case_name=c.case_name LOOP
                SELECT count(*) INTO n FROM pg_temp.topnbench_file_nodes x
                  WHERE x.sample_id=s.sample_id AND x.node->>'Node Type' IN ('Sort','Incremental Sort');
                SELECT x.node INTO a FROM pg_temp.topnbench_file_nodes x
                  WHERE x.sample_id=s.sample_id AND x.node->>'Node Type'='Sort';
                IF n<>1 OR a->>'Sort Method' IS DISTINCT FROM 'top-N heapsort'
                   OR a->>'Sort Space Type' IS DISTINCT FROM 'Memory'
                   OR a->>'Actual Loops' IS DISTINCT FROM '1'
                   OR a#>>'{Plans,0,Node Type}' IS DISTINCT FROM 'Seq Scan'
                   OR (a#>>'{Plans,0,Actual Rows}')::numeric IS DISTINCT FROM 8193
                   OR jsonb_array_length(a#>'{Plans,0,Output}') IS DISTINCT FROM
                       (CASE WHEN s.variant='datum' THEN 1 ELSE 2 END) THEN
                    status := 'FAIL: unexpected heap execution';
                END IF;
            END LOOP;
            IF EXISTS (
                SELECT f.variant FROM pg_temp.topnbench_file_samples f
                JOIN pg_temp.topnbench_file_nodes x USING(sample_id)
                WHERE f.check_name='heap' AND x.node->>'Node Type'='Sort' GROUP BY f.variant
                HAVING count(DISTINCT x.node->>'Sort Space Used')>1
            ) THEN status := 'FAIL: heap memory depends on input order'; END IF;
        ELSIF c.check_name='shape' THEN
            status := 'Sort input shape checked; result values not checked';
            FOR s IN SELECT * FROM pg_temp.topnbench_file_samples f WHERE f.case_name=c.case_name LOOP
                SELECT count(*) INTO n FROM pg_temp.topnbench_file_nodes x
                  WHERE x.sample_id=s.sample_id AND x.node->>'Node Type' IN ('Sort','Incremental Sort');
                IF s.variant LIKE 'scan-%' THEN
                    IF n<>0 THEN status := 'FAIL: scan control unexpectedly sorted'; END IF;
                ELSE
                    SELECT x.node INTO a FROM pg_temp.topnbench_file_nodes x
                      WHERE x.sample_id=s.sample_id AND x.node->>'Node Type'='Sort';
                    IF n<>1 OR jsonb_array_length(a#>'{Plans,0,Output}') IS DISTINCT FROM
                        (CASE WHEN s.variant IN ('wide','sort-tuple') THEN 2 ELSE 1 END)
                        OR jsonb_array_length(a->'Sort Key') IS DISTINCT FROM 1 THEN
                        status := 'FAIL: unexpected Sort input shape';
                    END IF;
                    IF s.variant LIKE 'late-work-%' AND
                       s.plan#>>'{0,Plan,Plans,0,Node Type}' IS DISTINCT FROM 'Result' THEN
                        status := 'FAIL: expression was not postponed';
                    END IF;
                END IF;
            END LOOP;
        END IF;
        RETURN NEXT;
    END LOOP;
END $$;
