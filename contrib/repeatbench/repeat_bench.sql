CREATE OR REPLACE FUNCTION repeat_bench_sql(max_output_bytes bigint DEFAULT 268435456,
										iterations int DEFAULT 10,
										empty_source_count int DEFAULT 10000000)
RETURNS TABLE (output_mb numeric,
			   source_len int,
			   repeat_count bigint,
			   best_ms numeric,
			   ns_per_byte numeric)
LANGUAGE plpgsql AS $$
DECLARE
	source_lengths	int[] := ARRAY[1, 10, 100, 1024, 4096, 16384, 65536,
								   262144, 1048576];
	size_divisors	int[] := ARRAY[16, 4, 1];
	divisor			int;
	cur_len			int;
	cur_count		bigint;
	target_bytes	bigint;
	source			text;
	sink			text;
	started_at		timestamptz;
	elapsed_ms		numeric;
	best_elapsed	numeric;
BEGIN
	-- repeat() rejects any result larger than MaxAllocSize (1GB - 1) counting
	-- the varlena header, so asking for more than that only produces errors.
	-- Clamping here also keeps every repeat count comfortably inside int4.
	max_output_bytes := least(max_output_bytes, 1073741819);

	-- Zero-length source: no bytes are ever copied.
	source := '';
	best_elapsed := NULL;
	FOR i IN 1 .. iterations LOOP
		started_at := clock_timestamp();
		sink := repeat(source, empty_source_count);
		elapsed_ms := extract(epoch FROM clock_timestamp() - started_at) * 1000;
		IF best_elapsed IS NULL OR elapsed_ms < best_elapsed THEN
			best_elapsed := elapsed_ms;
		END IF;
	END LOOP;
	output_mb := 0.0;
	source_len := 0;
	repeat_count := empty_source_count;
	best_ms := round(best_elapsed, 4);
	ns_per_byte := NULL;		-- no bytes produced, so the ratio is undefined
	RETURN NEXT;

	FOREACH divisor IN ARRAY size_divisors LOOP
		target_bytes := greatest(max_output_bytes / divisor, 1048576);

		FOREACH cur_len IN ARRAY source_lengths LOOP
			cur_count := greatest(target_bytes / cur_len, 1);
			source := repeat('x', cur_len);

			best_elapsed := NULL;
			FOR i IN 1 .. iterations LOOP
				started_at := clock_timestamp();
				sink := repeat(source, cur_count::int);
				elapsed_ms := extract(epoch FROM clock_timestamp() - started_at) * 1000;
				IF best_elapsed IS NULL OR elapsed_ms < best_elapsed THEN
					best_elapsed := elapsed_ms;
				END IF;
			END LOOP;
			sink := NULL;

			output_mb := round((cur_len::numeric * cur_count) / 1048576, 1);
			source_len := cur_len;
			repeat_count := cur_count;
			best_ms := round(best_elapsed, 4);
			ns_per_byte := round((best_elapsed * 1000000) /
								 (cur_len::numeric * cur_count), 4);
			RETURN NEXT;
		END LOOP;
	END LOOP;
END $$;

\timing on
SELECT * FROM repeat_bench_sql();