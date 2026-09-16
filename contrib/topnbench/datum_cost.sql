\echo
\echo '== 0015: by-value Datum Sort costing =='

-- Run after final_cost.sql and sort_representation.sql.  Reuse their tables,
-- query definitions, and runners; no new data generator or C interface.
DROP TABLE IF EXISTS topnbench_datum_guards;
CREATE TEMP TABLE topnbench_datum_guards
    (case_name text PRIMARY KEY, expect_change boolean, query text,
     plan_0014 jsonb, plan_0015 jsonb);
INSERT INTO topnbench_datum_guards(case_name, expect_change, query) VALUES
('int4', true, 'SELECT a_random FROM topnbench_data ORDER BY 1 LIMIT 250000'),
('int8', true, 'SELECT a_random::bigint FROM topnbench_data ORDER BY 1 LIMIT 250000'),
('float8', true, 'SELECT a_random::float8 FROM topnbench_data ORDER BY 1 LIMIT 250000'),
('nullable-int4', true, 'SELECT nullif(a_random % 10, 0) FROM topnbench_data ORDER BY 1 NULLS FIRST LIMIT 250000'),
('offset-int4', true, 'SELECT a_random FROM topnbench_data ORDER BY 1 LIMIT 1000 OFFSET 249000'),
('tuple-two-columns', false, 'SELECT a_random, same1 FROM topnbench_data ORDER BY 1 LIMIT 250000'),
('extra-sort-expression', false, 'SELECT a_random FROM topnbench_data ORDER BY same1 LIMIT 250000'),
('text-by-reference', false, 'SELECT a_random::text FROM topnbench_data ORDER BY 1 LIMIT 250000'),
('numeric-by-reference', false, 'SELECT a_random::numeric FROM topnbench_data ORDER BY 1 LIMIT 250000'),
('unbounded-sort', false, 'SELECT a_random FROM topnbench_data ORDER BY 1');

DO $$
DECLARE
    c record;
    old_plan jsonb;
    new_plan jsonb;
BEGIN
    PERFORM set_config('enable_sort_tuple_width_cost', 'on', true);
    PERFORM set_config('enable_cost_based_delayed_projection', 'on', true);
    PERFORM set_config('enable_projection_total_cost', 'on', true);
    PERFORM set_config('debug_print_projection_paths', 'off', true);
    PERFORM set_config('max_parallel_workers_per_gather', '0', true);
    PERFORM set_config('jit', 'off', true);
    PERFORM set_config('work_mem', '4MB', true);
    FOR c IN SELECT * FROM topnbench_datum_guards ORDER BY case_name LOOP
        PERFORM set_config('enable_sort_datum_cost', 'off', true);
        EXECUTE 'EXPLAIN (VERBOSE, COSTS ON, FORMAT JSON) ' || c.query INTO old_plan;
        PERFORM set_config('enable_sort_datum_cost', 'on', true);
        EXECUTE 'EXPLAIN (VERBOSE, COSTS ON, FORMAT JSON) ' || c.query INTO new_plan;
        IF c.expect_change THEN
            IF (new_plan#>>'{0,Plan,Total Cost}')::numeric >=
               (old_plan#>>'{0,Plan,Total Cost}')::numeric OR
               new_plan#>>'{0,Plan,Plans,0,Node Type}' IS DISTINCT FROM 'Sort' OR
               jsonb_array_length(new_plan#>'{0,Plan,Plans,0,Plans,0,Output}') IS DISTINCT FROM 1 THEN
                RAISE EXCEPTION 'Expected cheaper one-column Sort: %', c.case_name;
            END IF;
        ELSIF old_plan IS DISTINCT FROM new_plan THEN
            RAISE EXCEPTION 'Datum costing changed excluded case: %', c.case_name;
        END IF;
        UPDATE topnbench_datum_guards SET plan_0014 = old_plan, plan_0015 = new_plan
        WHERE case_name = c.case_name;
        -- Width-cost OFF is the existing master/path-only baseline.  The new
        -- switch must have no effect there, even for an eligible Datum Sort.
        PERFORM set_config('enable_sort_tuple_width_cost', 'off', true);
        EXECUTE 'EXPLAIN (VERBOSE, COSTS ON, FORMAT JSON) ' || c.query INTO old_plan;
        PERFORM set_config('enable_sort_datum_cost', 'off', true);
        EXECUTE 'EXPLAIN (VERBOSE, COSTS ON, FORMAT JSON) ' || c.query INTO new_plan;
        IF old_plan IS DISTINCT FROM new_plan THEN
            RAISE EXCEPTION 'Datum costing leaked into width-cost OFF: %', c.case_name;
        END IF;
        PERFORM set_config('enable_sort_tuple_width_cost', 'on', true);
    END LOOP;
END $$;

SELECT case_name, expect_change,
       plan_0014#>>'{0,Plan,Total Cost}' AS cost_0014,
       plan_0015#>>'{0,Plan,Total Cost}' AS cost_0015
FROM topnbench_datum_guards ORDER BY case_name;

DROP TABLE IF EXISTS topnbench_datum_runs;
CREATE TEMP TABLE topnbench_datum_runs AS
SELECT 0::integer AS case_no, ''::text AS case_name, 0::integer AS batch,
       ''::text AS policy, c.*
FROM topnbench_compare('SELECT 1', 'SELECT 1', 'SELECT 1',
                      3, true, '4MB') c WITH NO DATA;

-- Four lost-benefit cases plus two early-winner controls.  Four batches put
-- both policies first twice; each call rotates three timing samples after
-- warmup.  Both policies use the same final-total and tuple-width costing.
DO $$
DECLARE
    c record;
    b integer;
    p text;
BEGIN
    PERFORM set_config('enable_cost_based_delayed_projection', 'on', true);
    PERFORM set_config('enable_sort_tuple_width_cost', 'on', true);
    PERFORM set_config('enable_projection_total_cost', 'on', true);
    PERFORM set_config('debug_print_projection_paths', 'off', true);
    PERFORM set_config('jit', 'off', true);
    PERFORM set_config('max_parallel_workers_per_gather', '0', true);
    FOR c IN SELECT * FROM topnbench_final_cases
             WHERE case_no > 12 OR case_name IN
                 ('width-128-limit-25pct', 'width-256-limit-25pct')
             ORDER BY case_no LOOP
        FOR b IN 1..4 LOOP
            FOREACH p IN ARRAY CASE WHEN b % 2 = 1
                THEN ARRAY['0014', '0015'] ELSE ARRAY['0015', '0014'] END LOOP
                PERFORM set_config('enable_sort_datum_cost',
                                   CASE p WHEN '0015' THEN 'on' ELSE 'off' END, true);
                INSERT INTO topnbench_datum_runs
                SELECT c.case_no, c.case_name, b, p, r.*
                FROM topnbench_compare(c.auto_query, c.manual_late_query,
                                       c.forced_early_query, 3, b = 1,
                                       c.work_mem_setting) r;
            END LOOP;
        END LOOP;
    END LOOP;
END $$;

\echo '== 0014 versus 0015: paired natural queries (>1 means slower) =='
WITH pairs AS (
    SELECT o.case_no, o.case_name, o.batch,
           o.planner_choice AS old_choice, n.planner_choice AS new_choice,
           o.auto_median_ms AS old_ms, n.auto_median_ms AS new_ms,
           n.auto_median_ms / nullif(o.auto_median_ms, 0) AS ratio,
           n.manual_late_median_ms AS late_ms, n.forced_early_median_ms AS early_ms
    FROM topnbench_datum_runs o JOIN topnbench_datum_runs n
      USING (case_no, case_name, batch)
    WHERE o.policy = '0014' AND n.policy = '0015'
)
SELECT case_name, string_agg(DISTINCT old_choice, '/') AS choice_0014,
       string_agg(DISTINCT new_choice, '/') AS choice_0015,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY old_ms)::numeric, 3) AS ms_0014,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY new_ms)::numeric, 3) AS ms_0015,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY ratio)::numeric, 3) AS new_vs_old,
       count(*) FILTER (WHERE ratio > 1.05) AS slower_batches,
       count(*) FILTER (WHERE ratio < 0.95) AS faster_batches,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY late_ms)::numeric, 3) AS late_ms,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY early_ms)::numeric, 3) AS early_ms
FROM pairs GROUP BY case_no, case_name ORDER BY case_no;

\echo '== 0015 paired batches and surviving candidate estimates =='
SELECT o.case_name, o.batch, o.planner_choice AS choice_0014,
       n.planner_choice AS choice_0015,
       round(o.auto_median_ms::numeric, 3) AS ms_0014,
       round(n.auto_median_ms::numeric, 3) AS ms_0015,
       round((n.auto_median_ms / nullif(o.auto_median_ms, 0))::numeric, 3) AS new_vs_old,
       round(o.early_limit_cost::numeric, 3) AS early_cost_0014,
       round(o.late_limit_cost::numeric, 3) AS late_cost_0014,
       round(n.early_limit_cost::numeric, 3) AS early_cost_0015,
       round(n.late_limit_cost::numeric, 3) AS late_cost_0015
FROM topnbench_datum_runs o JOIN topnbench_datum_runs n USING (case_no, case_name, batch)
WHERE o.policy = '0014' AND n.policy = '0015' ORDER BY o.case_no, o.batch;
