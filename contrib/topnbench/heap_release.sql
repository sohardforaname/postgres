\set ON_ERROR_STOP on
\echo
\echo '== 0018: bounded-heap release checks (not timed) =='

-- Self-contained: no extension functions or earlier TEMP tables are needed.
-- N = 2*K+1 makes heap construction happen on the last input row. At 64MB
-- both representations can grow their arrays identically without spilling.
DROP VIEW IF EXISTS topnbench_heap_release_nodes;
DROP TABLE IF EXISTS topnbench_heap_release_results;
DROP TABLE IF EXISTS topnbench_heap_release_input;
CREATE TEMP TABLE topnbench_heap_release_input (k integer NOT NULL, payload integer NOT NULL);
CREATE TEMP TABLE topnbench_heap_release_results
    (input_order text, variant text, keys_ok boolean, payload_ok boolean, plan jsonb,
     PRIMARY KEY (input_order, variant));

DO $$
DECLARE
    ord text;
    variant text;
    query text;
    actual_keys integer[];
    expected_keys integer[];
    payload_ok boolean;
    saved_plan jsonb;
BEGIN
    PERFORM set_config('work_mem', '64MB', true);
    PERFORM set_config('max_parallel_workers_per_gather', '0', true);
    PERFORM set_config('synchronize_seqscans', 'off', true);
    PERFORM set_config('jit', 'off', true);
    PERFORM set_config('trace_sort', 'off', true);
    PERFORM set_config('client_min_messages',
                CASE WHEN current_setting('topnbench.trace', true) = 'on'
                     THEN 'log' ELSE 'warning' END, true);
    SELECT array_agg(g ORDER BY g) INTO expected_keys FROM generate_series(0, 4095) g;

    FOREACH ord IN ARRAY ARRAY['ascending', 'descending', 'random'] LOOP
        TRUNCATE topnbench_heap_release_input;
        INSERT INTO topnbench_heap_release_input
        SELECT k, -k FROM
            (SELECT g, CASE ord WHEN 'ascending' THEN g
                         WHEN 'descending' THEN 8192 - g
                         ELSE ((g::bigint * 48271) % 8193)::integer END AS k
             FROM generate_series(0, 8192) g) s ORDER BY g;
        ANALYZE topnbench_heap_release_input;
        IF (SELECT count(DISTINCT k) FROM topnbench_heap_release_input) <> 8193 THEN
            RAISE EXCEPTION '0018 input must be a permutation of 0..8192';
        END IF;

        FOREACH variant IN ARRAY ARRAY['datum', 'tuple'] LOOP
            query := CASE variant WHEN 'datum'
                THEN 'SELECT k FROM topnbench_heap_release_input ORDER BY k LIMIT 4096'
                ELSE 'SELECT k, payload FROM topnbench_heap_release_input ORDER BY k, payload LIMIT 4096'
                END;
            -- Check all keys in returned order, not just a checksum/count.
            EXECUTE format('SELECT array_agg(k), bool_and(%s) FROM (%s) s',
                           CASE variant WHEN 'tuple' THEN 'payload = -k' ELSE 'true' END,
                           query) INTO actual_keys, payload_ok;
            IF actual_keys IS DISTINCT FROM expected_keys OR payload_ok IS DISTINCT FROM true THEN
                RAISE EXCEPTION '0018 incorrect top-K result: %, %', ord, variant;
            END IF;

            RAISE NOTICE '0018 BEGIN order=% variant=% N=8193 K=4096', ord, variant;
            PERFORM set_config('trace_sort',
                CASE WHEN current_setting('topnbench.trace', true) = 'on'
                     THEN 'on' ELSE 'off' END, true);
            EXECUTE 'EXPLAIN (ANALYZE, VERBOSE, BUFFERS, COSTS OFF, '
                    'TIMING OFF, SUMMARY ON, FORMAT JSON) ' || query INTO saved_plan;
            PERFORM set_config('trace_sort', 'off', true);
            RAISE NOTICE '0018 END order=% variant=%', ord, variant;
            INSERT INTO topnbench_heap_release_results
            VALUES (ord, variant, true, payload_ok, saved_plan);
        END LOOP;
    END LOOP;
END $$;

CREATE TEMP VIEW topnbench_heap_release_nodes AS
WITH RECURSIVE nodes(input_order, variant, node) AS (
    SELECT input_order, variant, plan->0->'Plan' FROM topnbench_heap_release_results
    UNION ALL
    SELECT n.input_order, n.variant, c.node FROM nodes n
    CROSS JOIN LATERAL jsonb_array_elements(n.node->'Plans') c(node)
)
SELECT * FROM nodes;

-- Fail if the executor took a different path, rather than calling it a pass.
DO $$
DECLARE
    r record;
    s jsonb;
BEGIN
    IF (SELECT count(*) FROM topnbench_heap_release_results) <> 6 OR
       EXISTS (SELECT FROM topnbench_heap_release_nodes
               WHERE node->>'Node Type' IN ('Gather', 'Gather Merge')) THEN
        RAISE EXCEPTION '0018 requires six serial plans';
    END IF;
    FOR r IN SELECT * FROM topnbench_heap_release_results LOOP
        IF (SELECT count(*) FROM topnbench_heap_release_nodes n
            WHERE n.input_order = r.input_order AND n.variant = r.variant
              AND n.node->>'Node Type' IN ('Sort', 'Incremental Sort')) <> 1 THEN
            RAISE EXCEPTION '0018 expected one Sort: %, %', r.input_order, r.variant;
        END IF;
        SELECT n.node INTO STRICT s FROM topnbench_heap_release_nodes n
        WHERE n.input_order = r.input_order AND n.variant = r.variant
          AND n.node->>'Node Type' IN ('Sort', 'Incremental Sort');
        IF s->>'Sort Method' IS DISTINCT FROM 'top-N heapsort' OR
           s->>'Sort Space Type' IS DISTINCT FROM 'Memory' OR
           s#>>'{Plans,0,Node Type}' IS DISTINCT FROM 'Seq Scan' OR
           (s#>>'{Plans,0,Actual Rows}')::numeric IS DISTINCT FROM 8193 OR
           (s->>'Actual Loops')::numeric IS DISTINCT FROM 1 OR
           jsonb_array_length(s#>'{Plans,0,Output}') IS DISTINCT FROM
               (CASE r.variant WHEN 'datum' THEN 1 ELSE 2 END) THEN
            RAISE EXCEPTION '0018 unexpected sort execution: %, %', r.input_order, r.variant;
        END IF;
    END LOOP;
END $$;

SELECT r.input_order, r.variant, r.keys_ok, r.payload_ok,
       n.node->>'Sort Method' AS method,
       (n.node->>'Sort Space Used')::integer AS memory_kb,
       (n.node->>'Sort Space Used')::integer -
           (a.node->>'Sort Space Used')::integer AS extra_vs_ascending_kb
FROM topnbench_heap_release_results r
JOIN topnbench_heap_release_nodes n USING (input_order, variant)
JOIN topnbench_heap_release_nodes a ON a.variant = r.variant AND a.input_order = 'ascending'
WHERE n.node->>'Node Type' = 'Sort' AND a.node->>'Node Type' = 'Sort'
ORDER BY r.variant, r.input_order;

-- Identical fixed-width data, N, K and array growth: memory must not depend
-- on how often heap construction replaces its root. No assumed chunk size
-- or 32/64-bit structure sizes are baked into this comparison.
DO $$
BEGIN
    IF EXISTS (SELECT variant FROM topnbench_heap_release_nodes
               WHERE node->>'Node Type' = 'Sort' GROUP BY variant
               HAVING max((node->>'Sort Space Used')::integer) <>
                      min((node->>'Sort Space Used')::integer)) THEN
        RAISE EXCEPTION '0018 heap memory depends on input order; inspect root release/build';
    END IF;
END $$;
\echo '0018 PASS: ordered results, payloads, heap execution and memory checks passed.'
