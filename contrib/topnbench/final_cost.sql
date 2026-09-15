\echo
\echo '== Complete-result candidate comparison: 0011 versus 0012 =='

-- Run after benchmark.sql setup.  Reuse its 128/256-byte relations and add
-- only the widths needed to bracket the observed FINAL pruning boundary.
DO $$
DECLARE
    w integer;
    t text;
BEGIN
    FOREACH w IN ARRAY ARRAY[96, 160, 192] LOOP
        t := format('topnbench_copy_width_%s', w);
        EXECUTE format('DROP TABLE IF EXISTS %I', t);
        EXECUTE format('CREATE UNLOGGED TABLE %I '
                       '(sort_key integer NOT NULL, payload text NOT NULL)', t);
        EXECUTE format('INSERT INTO %I SELECT '
                       '((g::bigint * 48271) %% 100003)::integer, '
                       'left(repeat(md5(g::text), %s), %s) '
                       'FROM generate_series(1, 100000) g', t, (w + 31) / 32, w);
        EXECUTE format('ANALYZE %I', t);
    END LOOP;
END $$;

DROP TABLE IF EXISTS topnbench_final_cases;
CREATE TEMP TABLE topnbench_final_cases AS
WITH cases(case_no, case_name, width_bytes, limit_rows, offset_rows,
           workers, rounds) AS (
    VALUES
    (1,  'width-96-limit-25pct',  96, 25000, 0, 0, 0),
    (2,  'width-128-limit-25pct', 128, 25000, 0, 0, 0),
    (3,  'width-160-limit-25pct', 160, 25000, 0, 0, 0),
    (4,  'width-192-limit-25pct', 192, 25000, 0, 0, 0),
    (5,  'width-256-limit-25pct', 256, 25000, 0, 0, 0),
    (6,  'width-128-limit-20pct', 128, 20000, 0, 0, 0),
    (7,  'width-128-limit-30pct', 128, 30000, 0, 0, 0),
    (8,  'offset-half-of-25pct',  128, 12500, 12500, 0, 0),
    (9,  'offset-most-of-25pct',  128, 1000, 24000, 0, 0),
    (10, 'expensive-limit-1pct',  256, 1000, 0, 0, 128),
    (11, 'parallel-width-128',   128, 25000, 0, 2, 0),
    (12, 'parallel-width-256',   256, 25000, 0, 2, 0)
), expressions AS (
    SELECT *, format('topnbench_copy_width_%s', width_bytes) AS relname,
           format('topnbench_work_cost_1(octet_length(payload), %s, 0)',
                  rounds) AS expr
    FROM cases
)
SELECT case_no, case_name, width_bytes, limit_rows, offset_rows, workers,
       format('SELECT sort_key AS k, %s AS e1 FROM %I '
              'ORDER BY sort_key LIMIT %s OFFSET %s',
              expr, relname, limit_rows, offset_rows) AS auto_query,
       -- Keep projection below the *outer* OFFSET, so this control evaluates
       -- offset+limit expressions, like the natural post-Sort projection.
       -- It is deliberately not the after-OFFSET subquery rewrite.
       format('SELECT s.k, %s AS e1 FROM '
              '(SELECT sort_key AS k, payload FROM %I '
              'ORDER BY sort_key LIMIT %s) s '
              'ORDER BY s.k LIMIT %s OFFSET %s',
              expr, relname, offset_rows + limit_rows,
              limit_rows, offset_rows) AS manual_late_query,
       format('SELECT sort_key AS k, %s AS e1 FROM %I '
              'ORDER BY sort_key, e1 LIMIT %s OFFSET %s',
              expr, relname, limit_rows, offset_rows) AS forced_early_query
FROM expressions;

DROP TABLE IF EXISTS topnbench_final_runs;
CREATE TEMP TABLE topnbench_final_runs AS
SELECT 0::integer AS case_no, ''::text AS case_name, 0::integer AS batch,
       ''::text AS policy, c.*
FROM topnbench_compare('SELECT 1', 'SELECT 1', 'SELECT 1',
                      1, false, '64MB', true) c
WITH NO DATA;

-- SET LOCAL settings expire with this DO statement's transaction.  No trace
-- logging in timed runs.  Both policies retain the same width-cost formula.
DO $$
DECLARE
    c record;
    b integer;
    p text;
BEGIN
    PERFORM set_config('enable_cost_based_delayed_projection', 'on', true);
    PERFORM set_config('enable_sort_tuple_width_cost', 'on', true);
    PERFORM set_config('debug_print_projection_paths', 'off', true);
    PERFORM set_config('jit', 'off', true);
    PERFORM set_config('min_parallel_table_scan_size', '0', true);
    PERFORM set_config('parallel_setup_cost', '0', true);
    PERFORM set_config('parallel_tuple_cost', '0', true);
    FOR c IN SELECT * FROM topnbench_final_cases ORDER BY case_no LOOP
        PERFORM set_config('max_parallel_workers_per_gather', c.workers::text, true);
        FOR b IN 1..4 LOOP
            FOREACH p IN ARRAY CASE WHEN b % 2 = 1
                THEN ARRAY['0011', '0012'] ELSE ARRAY['0012', '0011'] END
            LOOP
                PERFORM set_config('enable_projection_total_cost',
                                   CASE p WHEN '0012' THEN 'on' ELSE 'off' END, true);
                INSERT INTO topnbench_final_runs
                SELECT c.case_no, c.case_name, b, p, r.*
                FROM topnbench_compare(c.auto_query, c.manual_late_query,
                                       c.forced_early_query, 3, b = 1, '64MB') r;
            END LOOP;
        END LOOP;
    END LOOP;
END $$;

-- These are paired *natural query* times, not estimated times inferred from
-- the early/late controls.  Four batches diagnose repeatability, not statistical
-- significance.  The controls still show whether either policy missed a winner.
WITH pairs AS (
    SELECT o.case_no, o.case_name, o.batch,
           o.planner_choice AS old_choice, n.planner_choice AS new_choice,
           o.auto_median_ms AS old_ms, n.auto_median_ms AS new_ms,
           n.auto_median_ms / nullif(o.auto_median_ms, 0) AS ratio,
           n.manual_late_median_ms AS late_ms,
           n.forced_early_median_ms AS early_ms,
           o.launched_workers AS old_workers, n.launched_workers AS new_workers
    FROM topnbench_final_runs o JOIN topnbench_final_runs n
      USING (case_no, case_name, batch)
    WHERE o.policy = '0011' AND n.policy = '0012'
)
SELECT case_name, string_agg(DISTINCT old_choice, '/') AS choice_0011,
       string_agg(DISTINCT new_choice, '/') AS choice_0012,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY old_ms)::numeric, 3) AS ms_0011,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY new_ms)::numeric, 3) AS ms_0012,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY ratio)::numeric, 3) AS new_vs_old,
       count(*) FILTER (WHERE ratio > 1.05) AS slower_batches,
       count(*) FILTER (WHERE ratio < 0.95) AS faster_batches,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY late_ms)::numeric, 3) AS late_ms,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY early_ms)::numeric, 3) AS early_ms,
       min(old_workers) AS min_workers_0011, min(new_workers) AS min_workers_0012
FROM pairs GROUP BY case_no, case_name ORDER BY case_no;

\echo '== Scope guards: plan must stay unchanged =='

DROP TABLE IF EXISTS topnbench_final_guards;
CREATE TEMP TABLE topnbench_final_guards(case_name text, unchanged boolean);
DO $$
DECLARE
    q text := 'SELECT sort_key AS k, '
              'topnbench_work_cost_1(octet_length(payload), 0, 0) AS e1 '
              'FROM topnbench_copy_width_128 ORDER BY sort_key';
    c record;
    old_plan jsonb;
    new_plan jsonb;
BEGIN
    PERFORM set_config('enable_cost_based_delayed_projection', 'on', true);
    PERFORM set_config('enable_sort_tuple_width_cost', 'on', true);
    PERFORM set_config('debug_print_projection_paths', 'off', true);
    PERFORM set_config('max_parallel_workers_per_gather', '0', true);
    PERFORM set_config('work_mem', '64MB', true);
    FOR c IN
        SELECT * FROM (VALUES
            ('cursor-1pct', '0.01', 'DECLARE topnbench_guard NO SCROLL CURSOR FOR ' || q || ' LIMIT 25000'),
            ('cursor-10pct', '0.1', 'DECLARE topnbench_guard NO SCROLL CURSOR FOR ' || q || ' LIMIT 25000'),
            ('subquery', '0.1', 'SELECT * FROM (' || q || ' LIMIT 25000) s'),
            ('with-ties', '0.1', q || ' FETCH FIRST 25000 ROWS WITH TIES'),
            ('limit-zero', '0.1', q || ' LIMIT 0'),
            ('limit-all', '0.1', q || ' LIMIT ALL'),
            ('volatile', '0.1', 'SELECT sort_key, random() FROM topnbench_copy_width_128 ORDER BY sort_key LIMIT 25000'),
            ('srf', '0.1', 'SELECT sort_key, generate_series(1,2) FROM topnbench_copy_width_128 ORDER BY sort_key LIMIT 25000')
        ) v(case_name, cursor_fraction, query)
    LOOP
        PERFORM set_config('cursor_tuple_fraction', c.cursor_fraction, true);
        PERFORM set_config('enable_projection_total_cost', 'off', true);
        EXECUTE 'EXPLAIN (FORMAT JSON, VERBOSE) ' || c.query INTO old_plan;
        PERFORM set_config('enable_projection_total_cost', 'on', true);
        EXECUTE 'EXPLAIN (FORMAT JSON, VERBOSE) ' || c.query INTO new_plan;
        INSERT INTO topnbench_final_guards VALUES (c.case_name, old_plan = new_plan);
        IF old_plan IS DISTINCT FROM new_plan THEN
            RAISE EXCEPTION 'complete-result policy changed excluded case %', c.case_name;
        END IF;
    END LOOP;
END $$;
SELECT * FROM topnbench_final_guards ORDER BY case_name;
