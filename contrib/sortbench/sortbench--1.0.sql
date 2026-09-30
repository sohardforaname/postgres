-- Use a dedicated test database. The fixture is deliberately stored inline.
CREATE FUNCTION sortbench_prepare() RETURNS SETOF text LANGUAGE plpgsql AS $prepare$
BEGIN
    IF EXISTS (SELECT FROM pg_settings WHERE name IN
        ('enable_sort_tuple_width_cost','enable_cost_based_delayed_projection','enable_sort_datum_cost')) THEN
        RAISE EXCEPTION 'Use the independent sorting branch';
    END IF;
    IF current_setting('debug_sort_heap_on_slots',true) IS NULL OR
       current_setting('debug_sort_free_heap_root',true) IS NULL OR
       current_setting('debug_disable_sort_bounded',true) IS NULL OR
       current_setting('debug_disable_sort_radix',true) IS NULL THEN
        RAISE EXCEPTION 'Rebuild/install/restart with the round-05 slots A/B kernel patch first';
    END IF;
    RETURN NEXT $command$
DROP TABLE IF EXISTS public.sortbench_data;
CREATE UNLOGGED TABLE public.sortbench_data (
    k integer NOT NULL, small_payload text NOT NULL, large_payload text NOT NULL);
ALTER TABLE public.sortbench_data ALTER COLUMN small_payload SET STORAGE PLAIN;
ALTER TABLE public.sortbench_data ALTER COLUMN large_payload SET STORAGE PLAIN;
INSERT INTO public.sortbench_data
SELECT ((g::bigint * 48271) % 1000003)::integer,
       substr(md5(g::text), 1, 8), repeat(md5(g::text), 8)
FROM generate_series(1, 1000000) g;
ALTER TABLE public.sortbench_data ALTER COLUMN k SET STATISTICS 1000;
ANALYZE public.sortbench_data;
$command$;
    RETURN NEXT 'VACUUM public.sortbench_data;';
    RETURN NEXT $fixtures$
CREATE TEMP TABLE sortbench_cases(name text PRIMARY KEY,payload text,mem text,k integer);
INSERT INTO sortbench_cases VALUES
('narrow/32MB/k001000','narrow','32MB',1000),
('narrow/32MB/k010000','narrow','32MB',10000),
('narrow/32MB/k050000','narrow','32MB',50000),
('narrow/32MB/k100000','narrow','32MB',100000),
('narrow/32MB/k250000','narrow','32MB',250000),
('narrow/32MB/k500000','narrow','32MB',500000),
('narrow/32MB/k750000','narrow','32MB',750000),
('narrow/1GB/k001000','narrow','1GB',1000),
('narrow/1GB/k010000','narrow','1GB',10000),
('narrow/1GB/k050000','narrow','1GB',50000),
('narrow/1GB/k100000','narrow','1GB',100000),
('narrow/1GB/k250000','narrow','1GB',250000),
('narrow/1GB/k500000','narrow','1GB',500000),
('narrow/1GB/k750000','narrow','1GB',750000),
('wide/1GB/k001000','wide','1GB',1000),
('wide/1GB/k010000','wide','1GB',10000),
('wide/1GB/k050000','wide','1GB',50000),
('wide/1GB/k100000','wide','1GB',100000),
('wide/1GB/k250000','wide','1GB',250000),
('wide/1GB/k500000','wide','1GB',500000),
('wide/1GB/k750000','wide','1GB',750000),
('narrow/4MB/k250000','narrow','4MB',250000),
('narrow/8MB/k250000','narrow','8MB',250000),
('narrow/16MB/k250000','narrow','16MB',250000),
('narrow/24MB/k250000','narrow','24MB',250000),
('wide/4MB/k250000','wide','4MB',250000),
('wide/8MB/k250000','wide','8MB',250000),
('wide/16MB/k250000','wide','16MB',250000),
('wide/24MB/k250000','wide','24MB',250000),
('wide/32MB/k250000','wide','32MB',250000);

CREATE TEMP TABLE sortbench_boundary_cases(
    name text PRIMARY KEY, payload text NOT NULL, mem text NOT NULL,
    k integer NOT NULL, variants text[] NOT NULL);
INSERT INTO sortbench_boundary_cases VALUES
('boundary/narrow/16MB/k250000','narrow','16MB',250000,ARRAY['on/default','on/no-heap']),
('boundary/narrow/24MB/k250000','narrow','24MB',250000,ARRAY['on/default','on/no-heap']),
('boundary/narrow/28MB/k250000','narrow','28MB',250000,ARRAY['on/default','on/no-heap','off/default']),
('boundary/narrow/29MB/k250000','narrow','29MB',250000,ARRAY['on/default','on/no-heap']),
('boundary/narrow/30MB/k250000','narrow','30MB',250000,ARRAY['on/default','on/no-heap']),
('boundary/narrow/31232kB/k250000','narrow','31232kB',250000,ARRAY['on/default','on/no-heap']),
('boundary/narrow/31MB/k250000','narrow','31MB',250000,ARRAY['on/default','on/no-heap']),
('boundary/narrow/32256kB/k250000','narrow','32256kB',250000,ARRAY['on/default','on/no-heap']),
('boundary/narrow/32MB/k250000','narrow','32MB',250000,ARRAY['on/default','on/no-heap','off/default']),
('boundary/narrow/33MB/k250000','narrow','33MB',250000,ARRAY['on/default','on/no-heap']),
('boundary/narrow/36MB/k250000','narrow','36MB',250000,ARRAY['on/default','on/no-heap']),
('boundary/narrow/64MB/k250000','narrow','64MB',250000,ARRAY['on/default','on/no-heap']),
('boundary/narrow/1GB/k250000','narrow','1GB',250000,ARRAY['on/default','on/no-heap']),
('boundary/wide/64MB/k250000','wide','64MB',250000,ARRAY['on/default','on/no-heap']),
('boundary/wide/96MB/k250000','wide','96MB',250000,ARRAY['on/default','on/no-heap']),
('boundary/wide/128MB/k250000','wide','128MB',250000,ARRAY['on/default','on/no-heap']),
('boundary/wide/144MB/k250000','wide','144MB',250000,ARRAY['on/default','on/no-heap']),
('boundary/wide/192MB/k250000','wide','192MB',250000,ARRAY['on/default','on/no-heap']),
('boundary/wide/256MB/k250000','wide','256MB',250000,ARRAY['on/default','on/no-heap']),
('boundary/wide/272MB/k250000','wide','272MB',250000,ARRAY['on/default','on/no-heap']),
('boundary/wide/1GB/k250000','wide','1GB',250000,ARRAY['on/default','on/no-heap','off/default']);

CREATE TEMP TABLE sortbench_slots_cases(
    name text PRIMARY KEY, payload text, mem text, k integer, variants text[]);
INSERT INTO sortbench_slots_cases VALUES
('slots/narrow/16MB/k250000','narrow','16MB',250000,ARRAY['off/default','on/default','off/no-radix','on/no-radix','off/no-heap','on/no-heap']),
('slots/narrow/24MB/k250000','narrow','24MB',250000,ARRAY['off/default','on/default','off/no-radix','on/no-radix']),
('slots/narrow/28MB/k250000','narrow','28MB',250000,ARRAY['off/default','on/default','off/no-radix','on/no-radix']),
('slots/narrow/29MB/k250000','narrow','29MB',250000,ARRAY['off/default','on/default','off/no-radix','on/no-radix']),
('slots/narrow/30MB/k250000','narrow','30MB',250000,ARRAY['off/default','on/default','off/no-radix','on/no-radix']),
('slots/narrow/31232kB/k250000','narrow','31232kB',250000,ARRAY['off/default','on/default','off/no-radix','on/no-radix']),
('slots/narrow/31MB/k250000','narrow','31MB',250000,ARRAY['off/default','on/default']),
('slots/narrow/32256kB/k250000','narrow','32256kB',250000,ARRAY['off/default','on/default']),
('slots/narrow/32MB/k250000','narrow','32MB',250000,ARRAY['off/default','on/default','off/no-heap','on/no-heap']),
('slots/narrow/33MB/k250000','narrow','33MB',250000,ARRAY['off/default','on/default']),
('slots/narrow/36MB/k250000','narrow','36MB',250000,ARRAY['off/default','on/default']),
('slots/narrow/64MB/k250000','narrow','64MB',250000,ARRAY['off/default','on/default']),
('slots/narrow/1GB/k250000','narrow','1GB',250000,ARRAY['off/default','on/default']),
('slots/wide/64MB/k250000','wide','64MB',250000,ARRAY['off/default','on/default']),
('slots/wide/96MB/k250000','wide','96MB',250000,ARRAY['off/default','on/default']),
('slots/wide/128MB/k250000','wide','128MB',250000,ARRAY['off/default','on/default']),
('slots/wide/144MB/k250000','wide','144MB',250000,ARRAY['off/default','on/default','off/no-radix','on/no-radix','off/no-heap','on/no-heap']),
('slots/wide/192MB/k250000','wide','192MB',250000,ARRAY['off/default','on/default','off/no-radix','on/no-radix']),
('slots/wide/256MB/k250000','wide','256MB',250000,ARRAY['off/default','on/default','off/no-radix','on/no-radix']),
('slots/wide/272MB/k250000','wide','272MB',250000,ARRAY['off/default','on/default']),
('slots/wide/1GB/k250000','wide','1GB',250000,ARRAY['off/default','on/default']);
CREATE TEMP TABLE sortbench_slots_nulls(k integer,payload integer NOT NULL);
INSERT INTO sortbench_slots_nulls
SELECT CASE WHEN g%37=0 THEN NULL ELSE g%101 END,g
FROM generate_series(8192,0,-1) g;
ANALYZE sortbench_slots_nulls;
CREATE TEMP TABLE sortbench_slots_small(
    name text PRIMARY KEY, representation text, relation_name text,
    k integer, offset_rows integer, nkeys integer);
INSERT INTO sortbench_slots_small VALUES
('slots-check/datum/ascending/k3500','datum','sortbench_heap_ascending',3500,0,1),
('slots-check/datum/descending/k3500','datum','sortbench_heap_descending',3500,0,1),
('slots-check/datum/permuted/k3500','datum','sortbench_heap_permuted',3500,0,1),
('slots-check/tuple/ascending/k1200','tuple','sortbench_heap_ascending',1200,0,1),
('slots-check/tuple/descending/k1200','tuple','sortbench_heap_descending',1200,0,1),
('slots-check/tuple/permuted/k1200','tuple','sortbench_heap_permuted',1200,0,1),
('slots-check/tuple/edge/k2046','tuple','sortbench_heap_permuted',2046,0,1),
('slots-check/tuple/edge/k2047','tuple','sortbench_heap_permuted',2047,0,1),
('slots-check/tuple/edge/k2048','tuple','sortbench_heap_permuted',2048,0,1),
('slots-check/tuple/offset','tuple','sortbench_heap_descending',1000,200,1),
('slots-check/nulls-first','nulls-first','sortbench_slots_nulls',1200,0,2),
('slots-check/nulls-last','nulls-last','sortbench_slots_nulls',1200,0,2);
CREATE TEMP TABLE sortbench_heap_ascending(k integer NOT NULL,payload integer NOT NULL);
INSERT INTO sortbench_heap_ascending SELECT k,-k FROM
    (SELECT g,g AS k FROM generate_series(0,8192) g) s ORDER BY g;
ANALYZE sortbench_heap_ascending;
CREATE TEMP TABLE sortbench_heap_descending(k integer NOT NULL,payload integer NOT NULL);
INSERT INTO sortbench_heap_descending SELECT k,-k FROM
    (SELECT g,8192-g AS k FROM generate_series(0,8192) g) s ORDER BY g;
ANALYZE sortbench_heap_descending;
CREATE TEMP TABLE sortbench_heap_permuted(k integer NOT NULL,payload integer NOT NULL);
INSERT INTO sortbench_heap_permuted SELECT k,-k FROM
    (SELECT g,((g::bigint*48271)%8193)::integer AS k FROM generate_series(0,8192) g) s ORDER BY g;
ANALYZE sortbench_heap_permuted;
    $fixtures$;
END $prepare$;

CREATE FUNCTION sortbench_capture_begin(expected_samples integer DEFAULT NULL)
RETURNS text LANGUAGE plpgsql AS $$
DECLARE r text := md5(clock_timestamp()::text || random()::text || pg_backend_pid()::text);
BEGIN
    IF expected_samples < 1 THEN RAISE EXCEPTION 'expected_samples must be positive or NULL'; END IF;
    CREATE TEMP TABLE IF NOT EXISTS sortbench_capture_state(run_id text, seq bigint, expected integer);
    TRUNCATE pg_temp.sortbench_capture_state;
    INSERT INTO pg_temp.sortbench_capture_state VALUES(r, 0, expected_samples);
    RETURN 'SORTBENCH ' || jsonb_build_object('event','begin','format',1,'run',r,
        'expected',expected_samples,'server',version(),'started',clock_timestamp())::text;
END $$;

CREATE FUNCTION sortbench_capture(case_name text, variant text,
    check_name text DEFAULT 'none', sample_kind text DEFAULT 'timed', batch_no integer DEFAULT 1)
RETURNS text LANGUAGE plpgsql AS $$
DECLARE s record; config jsonb;
BEGIN
    IF case_name IS NULL OR btrim(case_name) = '' OR variant IS NULL OR btrim(variant) = ''
       OR check_name IS NULL OR sample_kind IS NULL OR batch_no IS NULL OR batch_no < 1
       OR sample_kind NOT IN ('timed','plan','warmup','diagnostic') THEN
        RAISE EXCEPTION 'invalid capture label, sample kind or batch';
    END IF;
    UPDATE pg_temp.sortbench_capture_state SET seq = seq+1 RETURNING * INTO STRICT s;
    SELECT jsonb_object_agg(name,current_setting(name)) INTO config FROM pg_settings
    WHERE name LIKE 'enable_%' OR name LIKE 'cpu_%' OR name IN
       ('work_mem','hash_mem_multiplier','jit','max_parallel_workers',
        'max_parallel_workers_per_gather','max_worker_processes','parallel_leader_participation',
        'min_parallel_table_scan_size','min_parallel_index_scan_size','parallel_setup_cost',
        'parallel_tuple_cost','seq_page_cost','random_page_cost','effective_cache_size',
        'effective_io_concurrency','maintenance_io_concurrency','shared_buffers',
        'cursor_tuple_fraction','default_statistics_target','synchronize_seqscans',
        'debug_disable_sort_bounded','debug_disable_sort_radix','debug_sort_free_heap_root',
        'debug_sort_heap_on_slots',
        'trace_sort','search_path');
    RETURN 'SORTBENCH ' || jsonb_build_object('event','sample','run',s.run_id,'seq',s.seq,
        'case',case_name,'variant',variant,'check',check_name,'kind',sample_kind,
        'batch',batch_no,'settings',config)::text;
END $$;

CREATE FUNCTION sortbench_capture_end() RETURNS text LANGUAGE plpgsql AS $$
DECLARE s record;
BEGIN
    SELECT * INTO STRICT s FROM pg_temp.sortbench_capture_state;
    IF s.expected IS NOT NULL AND s.expected <> s.seq THEN
        RAISE EXCEPTION 'expected % captures, got %',s.expected,s.seq;
    END IF;
    RETURN 'SORTBENCH ' || jsonb_build_object('event','end','run',s.run_id,'count',s.seq)::text;
END $$;

CREATE FUNCTION sortbench_file_reset() RETURNS void LANGUAGE plpgsql AS $$
BEGIN
    DROP VIEW IF EXISTS pg_temp.sortbench_file_batches;
    DROP VIEW IF EXISTS pg_temp.sortbench_file_nodes;
    DROP TABLE IF EXISTS pg_temp.sortbench_file_samples;
    DROP TABLE IF EXISTS pg_temp.sortbench_file_lines;
    DROP TABLE IF EXISTS pg_temp.sortbench_file_state;
    CREATE TEMP TABLE sortbench_file_lines(line_no bigint GENERATED ALWAYS AS IDENTITY, line text);
    CREATE TEMP TABLE sortbench_file_state(header jsonb, loaded boolean NOT NULL);
    INSERT INTO pg_temp.sortbench_file_state VALUES(NULL,false);
    CREATE TEMP TABLE sortbench_file_samples(
        sample_id bigint PRIMARY KEY, case_name text NOT NULL, variant text NOT NULL,
        check_name text NOT NULL, kind text NOT NULL, batch integer NOT NULL,
        settings jsonb NOT NULL, plan jsonb NOT NULL);
    CREATE TEMP VIEW sortbench_file_nodes AS
    WITH RECURSIVE n(sample_id,path,node) AS (
        SELECT sample_id,'0'::text,plan#>'{0,Plan}' FROM pg_temp.sortbench_file_samples
        UNION ALL
        SELECT n.sample_id,n.path||'.'||c.ord,n2
        FROM n CROSS JOIN LATERAL jsonb_array_elements(n.node->'Plans') WITH ORDINALITY c(n2,ord)
    ) SELECT * FROM n;
    CREATE TEMP VIEW sortbench_file_batches AS
    SELECT case_name,variant,batch,count(*) AS n,
        percentile_cont(0.5) WITHIN GROUP (ORDER BY (plan#>>'{0,Execution Time}')::double precision) AS ms
    FROM pg_temp.sortbench_file_samples WHERE kind='timed'
    GROUP BY case_name,variant,batch;
END $$;

-- Internal parser helper: only parses JSON and inserts data, never executes archived text.
CREATE FUNCTION sortbench_file_sample(meta jsonb, body text) RETURNS void LANGUAGE plpgsql AS $$
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
    INSERT INTO pg_temp.sortbench_file_samples VALUES(
        (meta->>'seq')::bigint,meta->>'case',meta->>'variant',meta->>'check',
        meta->>'kind',(meta->>'batch')::integer,meta->'settings',p);
END $$;

CREATE FUNCTION sortbench_file_load() RETURNS text LANGUAGE plpgsql AS $$
DECLARE l record; h jsonb; m jsonb; pending jsonb; body text := ''; ended boolean := false;
        n bigint := 0; last_seq bigint := 0;
BEGIN
    IF (SELECT loaded FROM pg_temp.sortbench_file_state) THEN
        RAISE EXCEPTION 'call sortbench_file_reset before loading another file';
    END IF;
    FOR l IN SELECT * FROM pg_temp.sortbench_file_lines ORDER BY line_no LOOP
        IF coalesce(btrim(l.line),'') = '' THEN CONTINUE; END IF;
        IF ended THEN RAISE EXCEPTION 'data after end marker at line %',l.line_no; END IF;
        IF left(l.line,10) = 'SORTBENCH ' THEN
            m := substr(l.line,11)::jsonb;
            IF pending IS NOT NULL THEN
                PERFORM sortbench_file_sample(pending,body);
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
    IF EXISTS (SELECT FROM pg_temp.sortbench_file_samples GROUP BY case_name,variant
               HAVING count(DISTINCT settings) <> 1 OR count(DISTINCT check_name) <> 1) THEN
        RAISE EXCEPTION 'settings/check changed under the same case/variant label; use a distinct label';
    END IF;
    IF EXISTS (SELECT FROM pg_temp.sortbench_file_samples GROUP BY case_name
               HAVING count(DISTINCT check_name) <> 1) THEN
        RAISE EXCEPTION 'check label changed within one case';
    END IF;
    UPDATE pg_temp.sortbench_file_state SET header=h,loaded=true;
    RETURN format('Imported %s labelled plans; query results have not been verified.',n);
END $$;

CREATE FUNCTION sortbench_file_ready() RETURNS void LANGUAGE plpgsql AS $$
BEGIN
    IF NOT coalesce((SELECT loaded FROM pg_temp.sortbench_file_state),false) THEN
        RAISE EXCEPTION 'load a complete capture file first';
    END IF;
END $$;

CREATE FUNCTION sortbench_file_report() RETURNS TABLE(
    case_name text, variant text, work_mem text, timed_samples bigint, batches bigint,
    median_ms numeric, root_cost_min numeric, root_cost_max numeric,
    sort_width text, sort_method text, space_type text, space_kb text)
LANGUAGE plpgsql AS $$
BEGIN
    PERFORM sortbench_file_ready();
    RETURN QUERY
    WITH summary AS (
        SELECT s.case_name,s.variant,min(s.settings->>'work_mem') AS mem,
          count(*) FILTER (WHERE s.kind='timed') AS samples,
          min((s.plan#>>'{0,Plan,Total Cost}')::numeric) AS lo,
          max((s.plan#>>'{0,Plan,Total Cost}')::numeric) AS hi
        FROM pg_temp.sortbench_file_samples s GROUP BY s.case_name,s.variant
    ), timing AS (
        SELECT b.case_name,b.variant,count(*) AS batches,
          percentile_cont(0.5) WITHIN GROUP (ORDER BY b.ms) AS ms
        FROM pg_temp.sortbench_file_batches b GROUP BY b.case_name,b.variant
    ), sorts AS (
        SELECT s.case_name,s.variant,
          string_agg(DISTINCT n.node->>'Plan Width','/') AS width,
          string_agg(DISTINCT n.node->>'Sort Method','/') AS method,
          string_agg(DISTINCT n.node->>'Sort Space Type','/') AS space,
          string_agg(DISTINCT n.node->>'Sort Space Used','/') AS kb
        FROM pg_temp.sortbench_file_samples s JOIN pg_temp.sortbench_file_nodes n USING(sample_id)
        WHERE n.node->>'Node Type' IN ('Sort','Incremental Sort') GROUP BY s.case_name,s.variant
    )
    SELECT s.case_name,s.variant,s.mem,s.samples,coalesce(t.batches,0),round(t.ms::numeric,3),
           s.lo,s.hi,n.width,n.method,n.space,n.kb
    FROM summary s LEFT JOIN timing t USING(case_name,variant) LEFT JOIN sorts n USING(case_name,variant)
    ORDER BY s.case_name,s.variant;
END $$;

-- Compare planner-visible fields, stripping runtime counters from ANALYZE plans.
CREATE FUNCTION sortbench_file_estimate(node jsonb) RETURNS jsonb
LANGUAGE plpgsql IMMUTABLE STRICT AS $$
DECLARE result jsonb := '{}'::jsonb; kv record; child jsonb; children jsonb;
BEGIN
    FOR kv IN SELECT * FROM jsonb_each(node) LOOP
        IF kv.key = 'Plans' THEN
            children := '[]'::jsonb;
            FOR child IN SELECT * FROM jsonb_array_elements(kv.value) LOOP
                children := children || jsonb_build_array(sortbench_file_estimate(child));
            END LOOP;
            result := result || jsonb_build_object(kv.key,children);
        ELSIF kv.key !~ '^(Actual |Shared |Local |Temp |I/O |WAL |Rows Removed |Sort Method$|Sort Space |Workers$|Heap Fetches$|Memory |Full-sort Groups$|Pre-sorted Groups$)' THEN
            result := result || jsonb_build_object(kv.key,kv.value);
        END IF;
    END LOOP;
    RETURN result;
END $$;


-- Incremental estimated Sort costs; runtime remains whole-query Execution Time.
CREATE FUNCTION sortbench_file_costs() RETURNS TABLE(
    case_name text, variant text, estimated_input_rows text, estimated_width text,
    sort_startup_added text, sort_run_cost text,
    temp_read_blocks text, temp_written_blocks text)
LANGUAGE plpgsql AS $$
BEGIN
    PERFORM sortbench_file_ready();
    RETURN QUERY SELECT s.case_name,s.variant,
        string_agg(DISTINCT n.node#>>'{Plans,0,Plan Rows}','/'),
        string_agg(DISTINCT n.node->>'Plan Width','/'),
        string_agg(DISTINCT ((n.node->>'Startup Cost')::numeric -
                            (n.node#>>'{Plans,0,Total Cost}')::numeric)::text,'/'),
        string_agg(DISTINCT ((n.node->>'Total Cost')::numeric -
                            (n.node->>'Startup Cost')::numeric)::text,'/'),
        string_agg(DISTINCT n.node->>'Temp Read Blocks','/'),
        string_agg(DISTINCT n.node->>'Temp Written Blocks','/')
    FROM pg_temp.sortbench_file_samples s JOIN pg_temp.sortbench_file_nodes n USING(sample_id)
    WHERE s.kind='timed' AND n.node->>'Node Type'='Sort'
    GROUP BY s.case_name,s.variant ORDER BY s.case_name,s.variant;
END $$;
-- Round 2 uses the existing parser and report, with a four-strategy manifest.
CREATE FUNCTION sortbench_file_checks() RETURNS TABLE(case_name text, status text)
LANGUAGE plpgsql AS $$
DECLARE v text; c record; s record; p jsonb; a jsonb; first_plan jsonb; expected_settings jsonb;
BEGIN
    PERFORM sortbench_file_ready();
    FOR c IN SELECT * FROM pg_temp.sortbench_cases ORDER BY name LOOP
        case_name := c.name;
        status := 'OK: eight variants, four timed batches, one warmup; estimates/shape/settings match';
        first_plan := NULL;
        expected_settings := NULL;
        IF (SELECT count(*) FROM pg_temp.sortbench_file_samples f WHERE f.case_name=c.name) <> 40
           OR (SELECT count(DISTINCT f.variant) FROM pg_temp.sortbench_file_samples f WHERE f.case_name=c.name) <> 8
           OR EXISTS (
               SELECT FROM pg_temp.sortbench_file_samples f WHERE f.case_name=c.name
               GROUP BY f.variant HAVING count(*) FILTER (WHERE kind='warmup' AND batch=1) <> 1
                 OR count(*) FILTER (WHERE kind='timed') <> 4
                 OR count(DISTINCT batch) FILTER (WHERE kind='timed' AND batch BETWEEN 1 AND 4) <> 4
           ) THEN status := 'FAIL: incomplete or duplicate samples'; END IF;
        FOR s IN SELECT * FROM pg_temp.sortbench_file_samples f WHERE f.case_name=c.name LOOP
            p := sortbench_file_estimate(s.plan#>'{0,Plan}');
            IF first_plan IS NOT NULL AND p IS DISTINCT FROM first_plan THEN
                status := 'FAIL: planner fields changed across execution-only toggles';
            END IF;
            first_plan := p;
            p := s.settings - 'debug_disable_sort_bounded' - 'debug_disable_sort_radix' - 'debug_sort_free_heap_root';
            v := split_part(s.variant,'/',2);
            IF expected_settings IS NOT NULL AND p IS DISTINCT FROM expected_settings THEN
                status := 'FAIL: other captured settings changed';
            END IF;
            expected_settings := p;
            a := s.plan#>'{0,Plan,Plans,0}';
            IF s.plan#>>'{0,Plan,Node Type}' IS DISTINCT FROM 'Limit'
               OR (s.plan#>>'{0,Plan,Actual Rows}')::numeric IS DISTINCT FROM c.k
               OR (s.plan#>>'{0,Plan,Plan Rows}')::numeric IS DISTINCT FROM c.k
               OR a->>'Node Type' IS DISTINCT FROM 'Sort'
               OR (a->>'Actual Loops')::numeric IS DISTINCT FROM 1
               OR jsonb_array_length(a->'Sort Key') IS DISTINCT FROM 1
               OR a#>>'{Plans,0,Node Type}' IS DISTINCT FROM 'Seq Scan'
               OR (a#>>'{Plans,0,Actual Rows}')::numeric IS DISTINCT FROM 1000000
               OR (a#>>'{Plans,0,Plan Rows}')::numeric IS DISTINCT FROM 1000000
               OR (a#>>'{Plans,0,Actual Loops}')::numeric IS DISTINCT FROM 1
               OR jsonb_array_length(a#>'{Plans,0,Output}') IS DISTINCT FROM 2
               OR a#>>'{Plans,0,Relation Name}' IS DISTINCT FROM 'sortbench_data' THEN
                status := 'FAIL: unexpected plan shape or row estimates/actuals';
            END IF;
            IF s.settings->>'debug_disable_sort_bounded'='on' AND a->>'Sort Method'='top-N heapsort' THEN
                status := 'FAIL: heap used while disabled';
            END IF;
            IF v NOT IN ('default','no-radix','no-heap','no-heap-no-radix')
               OR (s.settings->>'debug_disable_sort_bounded') IS DISTINCT FROM
                  (CASE WHEN v IN ('no-heap','no-heap-no-radix') THEN 'on' ELSE 'off' END)
               OR (s.settings->>'debug_disable_sort_radix') IS DISTINCT FROM
                  (CASE WHEN v IN ('no-radix','no-heap-no-radix') THEN 'on' ELSE 'off' END)
               OR split_part(s.variant,'/',1) NOT IN ('off','on')
               OR (s.settings->>'debug_sort_free_heap_root') IS DISTINCT FROM split_part(s.variant,'/',1)
               OR pg_size_bytes(s.settings->>'work_mem') IS DISTINCT FROM pg_size_bytes(c.mem)
               OR s.settings->>'trace_sort' IS DISTINCT FROM 'off'
               OR s.settings->>'max_parallel_workers_per_gather' IS DISTINCT FROM '0'
               OR s.settings->>'jit' IS DISTINCT FROM 'off'
               OR s.settings->>'synchronize_seqscans' IS DISTINCT FROM 'off' THEN
                status := 'FAIL: unexpected strategy or timing settings';
            END IF;
        END LOOP;
        RETURN NEXT;
    END LOOP;
    IF EXISTS (SELECT FROM pg_temp.sortbench_file_samples f WHERE f.check_name <> 'heap-release' AND NOT EXISTS
               (SELECT FROM pg_temp.sortbench_cases m WHERE m.name=f.case_name)) THEN
        case_name := 'unexpected-case'; status := 'FAIL: captured case missing from manifest'; RETURN NEXT;
    END IF;
END $$;


-- The query is written literally in benchmark.sql; this only validates its array.
CREATE FUNCTION sortbench_assert_result(actual text[], tuple_mode boolean)
RETURNS text LANGUAGE plpgsql AS $$
DECLARE expected text[];
BEGIN
    SELECT array_agg(CASE WHEN tuple_mode THEN format('(%s,%s)',g,-g)
                         ELSE g::text END ORDER BY g) INTO expected
    FROM generate_series(0,4095) g;
    IF actual IS DISTINCT FROM expected THEN
        RAISE EXCEPTION 'Wrong ordered keys/payloads with heap release %',
                        current_setting('debug_sort_free_heap_root');
    END IF;
    RETURN 'OK: 4096 ordered keys/payloads';
END $$;

CREATE FUNCTION sortbench_heap_checks() RETURNS TABLE(
    case_name text, release_mode text, method text, memory_kb integer, status text)
LANGUAGE plpgsql AS $$
DECLARE s record; a jsonb; ncols integer; ref_kb integer;
BEGIN
    PERFORM sortbench_file_ready();
    IF (SELECT count(*) FROM pg_temp.sortbench_file_samples f WHERE f.check_name='heap-release')<>12
       OR (SELECT count(DISTINCT (f.case_name,f.variant)) FROM pg_temp.sortbench_file_samples f
           WHERE f.check_name='heap-release')<>12 THEN
        RAISE EXCEPTION 'Expected 12 distinct heap-release diagnostic plans';
    END IF;
    FOR s IN SELECT * FROM pg_temp.sortbench_file_samples f
             WHERE f.check_name='heap-release' ORDER BY f.case_name,f.variant LOOP
        case_name := s.case_name; release_mode := s.variant;
        ncols := CASE WHEN split_part(s.case_name,'/',2)='datum' THEN 1 ELSE 2 END;
        a := s.plan#>'{0,Plan,Plans,0}';
        method := a->>'Sort Method'; memory_kb := (a->>'Sort Space Used')::integer;
        IF s.case_name NOT IN ('heap-check/datum/ascending','heap-check/datum/descending','heap-check/datum/permuted',
                              'heap-check/tuple/ascending','heap-check/tuple/descending','heap-check/tuple/permuted')
           OR s.variant NOT IN ('off','on') OR s.kind<>'diagnostic'
           OR s.settings->>'debug_sort_free_heap_root' IS DISTINCT FROM s.variant
           OR s.settings->>'debug_disable_sort_bounded' IS DISTINCT FROM 'off'
           OR s.settings->>'debug_disable_sort_radix' IS DISTINCT FROM 'off'
           OR s.settings->>'max_parallel_workers_per_gather' IS DISTINCT FROM '0'
           OR s.settings->>'jit' IS DISTINCT FROM 'off'
           OR s.settings->>'trace_sort' IS DISTINCT FROM 'off'
           OR pg_size_bytes(s.settings->>'work_mem') IS DISTINCT FROM pg_size_bytes('64MB')
           OR s.plan#>>'{0,Plan,Node Type}' IS DISTINCT FROM 'Limit'
           OR (s.plan#>>'{0,Plan,Actual Rows}')::numeric IS DISTINCT FROM 4096
           OR method IS DISTINCT FROM 'top-N heapsort'
           OR (a->>'Actual Loops')::numeric IS DISTINCT FROM 1
           OR a->>'Sort Space Type' IS DISTINCT FROM 'Memory'
           OR (a#>>'{Plans,0,Actual Rows}')::numeric IS DISTINCT FROM 8193
           OR a#>>'{Plans,0,Node Type}' IS DISTINCT FROM 'Seq Scan'
           OR jsonb_array_length(a#>'{Plans,0,Output}') IS DISTINCT FROM ncols THEN
            RAISE EXCEPTION 'Unexpected heap-check shape/settings for %/%',s.case_name,s.variant;
        END IF;
        SELECT (f.plan#>>'{0,Plan,Plans,0,Sort Space Used}')::integer INTO STRICT ref_kb
        FROM pg_temp.sortbench_file_samples f
        WHERE f.case_name='heap-check/'||split_part(s.case_name,'/',2)||'/ascending'
          AND f.variant=s.variant;
        IF s.variant='on' AND memory_kb<>ref_kb THEN
            RAISE EXCEPTION 'Fixed heap memory depends on input order: % (% vs % kB)',s.case_name,memory_kb,ref_kb;
        END IF;
        status := CASE WHEN s.variant='on' THEN 'OK: memory matches ascending control'
                       ELSE format('baseline: %s kB extra vs ascending',memory_kb-ref_kb) END;
        RETURN NEXT;
    END LOOP;
END $$;

CREATE FUNCTION sortbench_file_ratios() RETURNS TABLE(
    case_name text, scope text, comparison text, paired_batches bigint,
    median_ratio numeric, min_ratio numeric, max_ratio numeric,
    faster_batches bigint, slower_batches bigint)
LANGUAGE plpgsql AS $$
BEGIN
    PERFORM sortbench_file_ready();
    RETURN QUERY
    WITH strategies(v) AS (VALUES ('default'),('no-radix'),('no-heap'),('no-heap-no-radix')),
    algorithm_pairs(num,den) AS (VALUES
        ('no-heap','default'),('no-heap-no-radix','no-radix'),
        ('no-radix','default'),('no-heap-no-radix','no-heap')),
    pairs(scope,num,den) AS (
        SELECT 'release','on/'||v,'off/'||v FROM strategies
        UNION ALL
        SELECT 'strategy',mode||'/'||num,mode||'/'||den
        FROM algorithm_pairs CROSS JOIN (VALUES ('off'),('on')) m(mode)
    ), r AS (
        SELECT a.case_name,p.scope,p.num||' / '||p.den AS label,a.ms/b.ms AS ratio
        FROM pairs p JOIN pg_temp.sortbench_file_batches a ON a.variant=p.num
        JOIN pg_temp.sortbench_file_batches b ON b.variant=p.den
            AND b.case_name=a.case_name AND b.batch=a.batch
        WHERE a.n=1 AND b.n=1 AND b.ms>0
    ) SELECT r.case_name,r.scope,r.label,count(*),
        round((percentile_cont(0.5) WITHIN GROUP (ORDER BY r.ratio))::numeric,3),
        round(min(r.ratio)::numeric,3),round(max(r.ratio)::numeric,3),
        count(*) FILTER (WHERE r.ratio<0.95),count(*) FILTER (WHERE r.ratio>1.05)
      FROM r GROUP BY r.case_name,r.scope,r.label ORDER BY r.case_name,r.scope,r.label;
END $$;

-- Round 04: report-only diagnostics; no EXPLAIN cost is treated as milliseconds.
CREATE FUNCTION sortbench_boundary_check() RETURNS text LANGUAGE plpgsql AS $$
DECLARE c record; s record; a jsonb; p jsonb;
        first_plan jsonb; first_settings jsonb; expected_count integer;
BEGIN
    PERFORM sortbench_file_ready();
    SELECT sum(cardinality(m.variants)*2)::integer INTO expected_count
    FROM pg_temp.sortbench_boundary_cases m;
    IF (SELECT count(*) FROM pg_temp.sortbench_file_samples f
        WHERE f.check_name='boundary') IS DISTINCT FROM expected_count
       OR EXISTS (SELECT FROM pg_temp.sortbench_file_samples f
                  WHERE f.check_name NOT IN ('boundary','heap-release')) THEN
        RAISE EXCEPTION 'Boundary sample count or check labels do not match manifest';
    END IF;
    IF EXISTS (
        SELECT FROM pg_temp.sortbench_file_samples f
        WHERE f.check_name='boundary' AND NOT EXISTS (
            SELECT FROM pg_temp.sortbench_boundary_cases m
            WHERE m.name=f.case_name AND f.variant=ANY(m.variants))) THEN
        RAISE EXCEPTION 'Unknown boundary case or variant';
    END IF;
    FOR c IN SELECT * FROM pg_temp.sortbench_boundary_cases m ORDER BY m.name LOOP
        IF EXISTS (
            SELECT FROM unnest(c.variants) AS v(variant)
            CROSS JOIN generate_series(1,2) AS b(batch)
            WHERE (SELECT count(*) FROM pg_temp.sortbench_file_samples f
                   WHERE f.check_name='boundary' AND f.case_name=c.name
                     AND f.variant=v.variant AND f.batch=b.batch
                     AND f.kind='diagnostic') <> 1) THEN
            RAISE EXCEPTION 'Missing or duplicate boundary sample: %',c.name;
        END IF;
        first_plan := NULL;
        first_settings := NULL;
        FOR s IN SELECT * FROM pg_temp.sortbench_file_samples f
                 WHERE f.check_name='boundary' AND f.case_name=c.name LOOP
            p := sortbench_file_estimate(s.plan#>'{0,Plan}');
            IF first_plan IS NOT NULL AND p IS DISTINCT FROM first_plan THEN
                RAISE EXCEPTION 'Planner fields changed within boundary case: %',c.name;
            END IF;
            first_plan := p;
            p := s.settings - 'debug_disable_sort_bounded' - 'debug_sort_free_heap_root';
            IF first_settings IS NOT NULL AND p IS DISTINCT FROM first_settings THEN
                RAISE EXCEPTION 'Other settings changed within boundary case: %',c.name;
            END IF;
            first_settings := p;
            a := s.plan#>'{0,Plan,Plans,0}';
            IF s.plan#>>'{0,Plan,Node Type}' IS DISTINCT FROM 'Limit'
               OR (s.plan#>>'{0,Plan,Actual Rows}')::numeric IS DISTINCT FROM c.k
               OR (s.plan#>>'{0,Plan,Plan Rows}')::numeric IS DISTINCT FROM c.k
               OR (s.plan#>>'{0,Plan,Actual Loops}')::numeric IS DISTINCT FROM 1
               OR a->>'Node Type' IS DISTINCT FROM 'Sort'
               OR (a->>'Actual Loops')::numeric IS DISTINCT FROM 1
               OR jsonb_array_length(a->'Sort Key') IS DISTINCT FROM 1
               OR a#>>'{Plans,0,Node Type}' IS DISTINCT FROM 'Seq Scan'
               OR a#>>'{Plans,0,Relation Name}' IS DISTINCT FROM 'sortbench_data'
               OR (a#>>'{Plans,0,Actual Rows}')::numeric IS DISTINCT FROM 1000000
               OR (a#>>'{Plans,0,Plan Rows}')::numeric IS DISTINCT FROM 1000000
               OR (a#>>'{Plans,0,Actual Loops}')::numeric IS DISTINCT FROM 1
               OR jsonb_array_length(a#>'{Plans,0,Output}') IS DISTINCT FROM 2
               OR (a->>'Actual Rows')::numeric IS DISTINCT FROM c.k
               OR coalesce(a->>'Sort Method','') NOT IN
                   ('top-N heapsort','quicksort','external sort','external merge')
               OR coalesce(a->>'Sort Space Type','') NOT IN ('Memory','Disk') THEN
                RAISE EXCEPTION 'Unexpected boundary plan shape: %/%',c.name,s.variant;
            END IF;
            IF s.settings->>'debug_disable_sort_bounded' IS DISTINCT FROM
                   (CASE WHEN split_part(s.variant,'/',2)='no-heap' THEN 'on' ELSE 'off' END)
               OR s.settings->>'debug_sort_free_heap_root' IS DISTINCT FROM split_part(s.variant,'/',1)
               OR s.settings->>'debug_disable_sort_radix' IS DISTINCT FROM 'off'
               OR s.settings->>'max_parallel_workers_per_gather' IS DISTINCT FROM '0'
               OR s.settings->>'max_parallel_workers' IS DISTINCT FROM '0'
               OR s.settings->>'jit' IS DISTINCT FROM 'off'
               OR s.settings->>'synchronize_seqscans' IS DISTINCT FROM 'off'
               OR s.settings->>'trace_sort' IS DISTINCT FROM 'on'
               OR pg_size_bytes(s.settings->>'work_mem') IS DISTINCT FROM pg_size_bytes(c.mem)
               OR (split_part(s.variant,'/',2)='no-heap' AND a->>'Sort Method'='top-N heapsort') THEN
                RAISE EXCEPTION 'Unexpected boundary settings/method: %/%',c.name,s.variant;
            END IF;
        END LOOP;
    END LOOP;
    RETURN format('OK: %s boundary plans; two diagnostic repeats per case/variant',expected_count);
END $$;

CREATE FUNCTION sortbench_boundary_report() RETURNS TABLE(
    case_name text, variant text, samples bigint, estimated_rows numeric,
    estimated_width integer, allowed_bytes bigint, methods text,
    space_type text, min_space_kb integer, max_space_kb integer,
    sort_startup_added numeric, sort_run_cost numeric,
    min_temp_read bigint, max_temp_read bigint,
    min_temp_written bigint, max_temp_written bigint)
LANGUAGE plpgsql AS $$
BEGIN
    PERFORM sortbench_boundary_check();
    RETURN QUERY
    WITH d AS (
        SELECT f.*, f.plan#>'{0,Plan,Plans,0}' AS a
        FROM pg_temp.sortbench_file_samples f WHERE f.check_name='boundary'
    )
    SELECT d.case_name,d.variant,count(*),
        min((d.a#>>'{Plans,0,Plan Rows}')::numeric),
        min((d.a->>'Plan Width')::integer),
        min(pg_size_bytes(d.settings->>'work_mem')),
        string_agg(DISTINCT d.a->>'Sort Method','/'),
        string_agg(DISTINCT d.a->>'Sort Space Type','/'),
        min((d.a->>'Sort Space Used')::integer),max((d.a->>'Sort Space Used')::integer),
        min((d.a->>'Startup Cost')::numeric - (d.a#>>'{Plans,0,Total Cost}')::numeric),
        min((d.a->>'Total Cost')::numeric - (d.a->>'Startup Cost')::numeric),
        min((d.a->>'Temp Read Blocks')::bigint),max((d.a->>'Temp Read Blocks')::bigint),
        min((d.a->>'Temp Written Blocks')::bigint),max((d.a->>'Temp Written Blocks')::bigint)
    FROM d GROUP BY d.case_name,d.variant ORDER BY d.case_name,d.variant;
END $$;

-- Build the entire reference array before slicing: no bounded reference sort.
CREATE FUNCTION sortbench_slots_assert(actual text[], representation text,
    result_rows integer, offset_rows integer DEFAULT 0)
RETURNS text LANGUAGE plpgsql AS $$
DECLARE expected text[];
BEGIN
    IF representation NOT IN ('datum','tuple','nulls-first','nulls-last') OR
       result_rows<1 OR offset_rows<0 OR result_rows+offset_rows>8193 THEN
        RAISE EXCEPTION 'Invalid slots correctness manifest';
    END IF;
    IF representation IN ('datum','tuple') THEN
        SELECT array_agg(CASE WHEN representation='datum' THEN g::text
                             ELSE ROW(g,-g)::text END ORDER BY g)
        INTO expected FROM generate_series(0,8192) g;
    ELSIF representation='nulls-first' THEN
        SELECT array_agg(ROW(k,g)::text ORDER BY k NULLS FIRST,g) INTO expected
        FROM (SELECT g,CASE WHEN g%37=0 THEN NULL ELSE g%101 END AS k
              FROM generate_series(0,8192) g) q;
    ELSE
        SELECT array_agg(ROW(k,g)::text ORDER BY k NULLS LAST,g) INTO expected
        FROM (SELECT g,CASE WHEN g%37=0 THEN NULL ELSE g%101 END AS k
              FROM generate_series(0,8192) g) q;
    END IF;
    IF actual IS DISTINCT FROM expected[offset_rows+1:offset_rows+result_rows] THEN
        RAISE EXCEPTION 'Wrong ordered result: representation=%, limit=%, offset=%, slots=%',
            representation,result_rows,offset_rows,current_setting('debug_sort_heap_on_slots');
    END IF;
    RETURN format('OK: %s ordered values, offset %s',result_rows,offset_rows);
END $$;

CREATE FUNCTION sortbench_slots_expected() RETURNS TABLE(
    case_name text, variant text, kind text, batch integer, check_name text)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    WITH v AS (
        SELECT m.name,x.v FROM pg_temp.sortbench_slots_cases m
        CROSS JOIN LATERAL unnest(m.variants) AS x(v)
    )
    SELECT v.name,v.v,'warmup'::text,1,'slots-matrix'::text FROM v
    UNION ALL
    SELECT v.name,v.v,'timed',b.n,'slots-matrix' FROM v CROSS JOIN generate_series(1,4) b(n)
    UNION ALL
    SELECT v.name||'/trace',v.v,'diagnostic',1,'slots-trace' FROM v
    UNION ALL
    SELECT m.name,x.v,'diagnostic',1,'slots-small' FROM pg_temp.sortbench_slots_small m
    CROSS JOIN (VALUES ('off/default'::text),('on/default')) x(v);
END $$;

CREATE FUNCTION sortbench_slots_check() RETURNS text LANGUAGE plpgsql AS $$
DECLARE c record; s record; a jsonb; p jsonb; first_plan jsonb; first_settings jsonb;
        total_count integer; changed_count integer;
BEGIN
    PERFORM sortbench_file_ready();
    SELECT count(*)::integer INTO total_count FROM sortbench_slots_expected();
    IF EXISTS (
        WITH actual AS (
            SELECT f.case_name,f.variant,f.kind,f.batch,f.check_name,count(*) AS n
            FROM pg_temp.sortbench_file_samples f GROUP BY 1,2,3,4,5
        )
        SELECT FROM sortbench_slots_expected() e FULL JOIN actual a
        USING(case_name,variant,kind,batch,check_name)
        WHERE e.case_name IS NULL OR a.n IS DISTINCT FROM 1::bigint
    ) THEN RAISE EXCEPTION 'Slots capture does not match manifest: missing/duplicate/unknown samples'; END IF;

    FOR c IN
        SELECT m.name,m.mem,m.k,0 AS offset_rows,1000000 AS input_rows,
               'sortbench_data'::text AS relation_name,2 AS ncols,1 AS nkeys
        FROM pg_temp.sortbench_slots_cases m
        UNION ALL
        SELECT m.name,'128kB',m.k,m.offset_rows,8193,m.relation_name,
               CASE WHEN m.representation='datum' THEN 1 ELSE 2 END,m.nkeys
        FROM pg_temp.sortbench_slots_small m
    LOOP
        first_plan := NULL; first_settings := NULL;
        FOR s IN SELECT * FROM pg_temp.sortbench_file_samples f
                 WHERE f.case_name=c.name OR f.case_name=c.name||'/trace' LOOP
            p := sortbench_file_estimate(s.plan#>'{0,Plan}');
            IF first_plan IS NOT NULL AND p IS DISTINCT FROM first_plan THEN
                RAISE EXCEPTION 'Planner fields changed within slots case: %',c.name;
            END IF;
            first_plan := p;
            p := s.settings - 'debug_sort_heap_on_slots' - 'debug_disable_sort_bounded'
                            - 'debug_disable_sort_radix' - 'trace_sort';
            IF first_settings IS NOT NULL AND p IS DISTINCT FROM first_settings THEN
                RAISE EXCEPTION 'Other settings changed within slots case: %',c.name;
            END IF;
            first_settings := p;
            a := s.plan#>'{0,Plan,Plans,0}';
            IF s.plan#>>'{0,Plan,Node Type}' IS DISTINCT FROM 'Limit'
               OR (s.plan#>>'{0,Plan,Actual Rows}')::numeric IS DISTINCT FROM c.k
               OR (s.plan#>>'{0,Plan,Plan Rows}')::numeric IS DISTINCT FROM c.k
               OR (s.plan#>>'{0,Plan,Actual Loops}')::numeric IS DISTINCT FROM 1
               OR a->>'Node Type' IS DISTINCT FROM 'Sort'
               OR (a->>'Actual Rows')::numeric IS DISTINCT FROM c.k+c.offset_rows
               OR (a->>'Actual Loops')::numeric IS DISTINCT FROM 1
               OR jsonb_array_length(a->'Sort Key') IS DISTINCT FROM c.nkeys
               OR a#>>'{Plans,0,Node Type}' IS DISTINCT FROM 'Seq Scan'
               OR a#>>'{Plans,0,Relation Name}' IS DISTINCT FROM c.relation_name
               OR (a#>>'{Plans,0,Actual Rows}')::numeric IS DISTINCT FROM c.input_rows
               OR (a#>>'{Plans,0,Plan Rows}')::numeric IS DISTINCT FROM c.input_rows
               OR (a#>>'{Plans,0,Actual Loops}')::numeric IS DISTINCT FROM 1
               OR jsonb_array_length(a#>'{Plans,0,Output}') IS DISTINCT FROM c.ncols
               OR coalesce(a->>'Sort Method','') NOT IN
                   ('top-N heapsort','quicksort','external sort','external merge')
               OR coalesce(a->>'Sort Space Type','') NOT IN ('Memory','Disk') THEN
                RAISE EXCEPTION 'Unexpected slots plan shape: %/%',s.case_name,s.variant;
            END IF;
            IF s.settings->>'debug_sort_heap_on_slots' IS DISTINCT FROM split_part(s.variant,'/',1)
               OR s.settings->>'debug_sort_free_heap_root' IS DISTINCT FROM 'on'
               OR s.settings->>'debug_disable_sort_bounded' IS DISTINCT FROM
                   (CASE WHEN split_part(s.variant,'/',2)='no-heap' THEN 'on' ELSE 'off' END)
               OR s.settings->>'debug_disable_sort_radix' IS DISTINCT FROM
                   (CASE WHEN split_part(s.variant,'/',2)='no-radix' THEN 'on' ELSE 'off' END)
               OR s.settings->>'trace_sort' IS DISTINCT FROM
                   (CASE WHEN s.check_name='slots-trace' THEN 'on' ELSE 'off' END)
               OR s.settings->>'max_parallel_workers_per_gather' IS DISTINCT FROM '0'
               OR s.settings->>'max_parallel_workers' IS DISTINCT FROM '0'
               OR s.settings->>'jit' IS DISTINCT FROM 'off'
               OR s.settings->>'synchronize_seqscans' IS DISTINCT FROM 'off'
               OR pg_size_bytes(s.settings->>'work_mem') IS DISTINCT FROM pg_size_bytes(c.mem)
               OR (split_part(s.variant,'/',2)='no-heap' AND a->>'Sort Method'='top-N heapsort') THEN
                RAISE EXCEPTION 'Unexpected slots settings/method: %/%',s.case_name,s.variant;
            END IF;
        END LOOP;
    END LOOP;
    -- A negative control: the new switch must not bypass disable-bounded.
    IF EXISTS (
        SELECT FROM pg_temp.sortbench_file_samples a
        JOIN pg_temp.sortbench_file_samples b
          ON b.case_name=a.case_name AND b.kind=a.kind AND b.batch=a.batch
         AND b.variant='off/no-heap'
        WHERE a.variant='on/no-heap' AND
          a.plan#>>'{0,Plan,Plans,0,Sort Method}' IS DISTINCT FROM
          b.plan#>>'{0,Plan,Plans,0,Sort Method}'
    ) THEN RAISE EXCEPTION 'Slots switch changed the disabled-heap control method'; END IF;
    SELECT count(DISTINCT a.case_name)::integer INTO changed_count
    FROM pg_temp.sortbench_file_samples a JOIN pg_temp.sortbench_file_samples b
      ON b.case_name=a.case_name AND b.kind=a.kind AND b.batch=a.batch AND b.variant='off/default'
    WHERE a.variant='on/default' AND a.kind='timed'
      AND a.plan#>>'{0,Plan,Plans,0,Sort Method}'='top-N heapsort'
      AND b.plan#>>'{0,Plan,Plans,0,Sort Space Type}'='Disk';
    IF changed_count=0 THEN
        RAISE EXCEPTION 'No disk-to-heap transition exercised; inspect trace and binary/fixture';
    END IF;
    RETURN format('OK: %s plans; %s default cases changed from disk to heap',total_count,changed_count);
END $$;

CREATE FUNCTION sortbench_slots_ratios() RETURNS TABLE(
    case_name text, strategy text, paired_batches bigint, median_ratio numeric,
    min_ratio numeric, max_ratio numeric, faster_batches bigint, slower_batches bigint)
LANGUAGE plpgsql AS $$
BEGIN
    PERFORM sortbench_slots_check();
    RETURN QUERY
    WITH r AS (
        SELECT a.case_name,split_part(a.variant,'/',2) AS strategy,a.ms/b.ms AS ratio
        FROM pg_temp.sortbench_file_batches a JOIN pg_temp.sortbench_file_batches b
          ON a.case_name=b.case_name AND a.batch=b.batch
         AND b.variant='off/'||split_part(a.variant,'/',2)
        WHERE split_part(a.variant,'/',1)='on' AND a.n=1 AND b.n=1 AND b.ms>0
    )
    SELECT r.case_name,r.strategy,count(*),
        round((percentile_cont(0.5) WITHIN GROUP (ORDER BY r.ratio))::numeric,3),
        round(min(r.ratio)::numeric,3),round(max(r.ratio)::numeric,3),
        count(*) FILTER (WHERE r.ratio<0.95),count(*) FILTER (WHERE r.ratio>1.05)
    FROM r GROUP BY r.case_name,r.strategy ORDER BY r.case_name,r.strategy;
END $$;
