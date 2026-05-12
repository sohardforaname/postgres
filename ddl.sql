\echo 'HashJoin alt-table benchmark scaffold'
\echo 'Run with psql after building a backend that includes enable_hashjoin_alt_table.'

\set ON_ERROR_STOP 1
\timing on

SET client_min_messages = warning;
SET enable_mergejoin = off;
SET enable_nestloop = off;
SET enable_hashjoin = on;

CREATE OR REPLACE FUNCTION bench_setup_int4_unique(inner_rows int, outer_rows int, miss_ratio float8)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
	DROP TABLE IF EXISTS inner_unique_int4;
	DROP TABLE IF EXISTS outer_unique_int4;

	CREATE TABLE inner_unique_int4 AS
	SELECT g AS k, g AS payload
	FROM generate_series(1, inner_rows) AS g;

	CREATE TABLE outer_unique_int4 AS
	SELECT CASE
			 WHEN g <= outer_rows * (1.0 - miss_ratio) THEN ((g - 1) % inner_rows) + 1
			 ELSE inner_rows + g
		   END AS k,
		   g AS payload
	FROM generate_series(1, outer_rows) AS g;

	ANALYZE inner_unique_int4;
	ANALYZE outer_unique_int4;
END;
$$;

CREATE OR REPLACE FUNCTION bench_setup_int4_dup(inner_distinct int, dup_per_key int,
												 outer_rows int, miss_ratio float8)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
	DROP TABLE IF EXISTS inner_dup_int4;
	DROP TABLE IF EXISTS outer_dup_int4;

	CREATE TABLE inner_dup_int4 AS
	SELECT k, g AS payload
	FROM generate_series(1, inner_distinct) AS k,
		 generate_series(1, dup_per_key) AS g;

	CREATE TABLE outer_dup_int4 AS
	SELECT CASE
			 WHEN g <= outer_rows * (1.0 - miss_ratio) THEN ((g - 1) % inner_distinct) + 1
			 ELSE inner_distinct + g
		   END AS k,
		   g AS payload
	FROM generate_series(1, outer_rows) AS g;

	ANALYZE inner_dup_int4;
	ANALYZE outer_dup_int4;
END;
$$;

CREATE OR REPLACE FUNCTION bench_setup_int8_unique(inner_rows int, outer_rows int, miss_ratio float8)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
	DROP TABLE IF EXISTS inner_unique_int8;
	DROP TABLE IF EXISTS outer_unique_int8;

	CREATE TABLE inner_unique_int8 AS
	SELECT g::bigint AS k, g::bigint AS payload
	FROM generate_series(1, inner_rows) AS g;

	CREATE TABLE outer_unique_int8 AS
	SELECT CASE
			 WHEN g <= outer_rows * (1.0 - miss_ratio) THEN (((g - 1) % inner_rows) + 1)::bigint
			 ELSE (inner_rows + g)::bigint
		   END AS k,
		   g::bigint AS payload
	FROM generate_series(1, outer_rows) AS g;

	ANALYZE inner_unique_int8;
	ANALYZE outer_unique_int8;
END;
$$;

CREATE OR REPLACE FUNCTION bench_setup_text_unique(inner_rows int, outer_rows int, miss_ratio float8)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
	DROP TABLE IF EXISTS inner_unique_text;
	DROP TABLE IF EXISTS outer_unique_text;

	CREATE TABLE inner_unique_text AS
	SELECT 'k' || g::text AS k, repeat(md5(g::text), 2) AS payload
	FROM generate_series(1, inner_rows) AS g;

	CREATE TABLE outer_unique_text AS
	SELECT CASE
			 WHEN g <= outer_rows * (1.0 - miss_ratio) THEN 'k' || ((((g - 1) % inner_rows) + 1))::text
			 ELSE 'missing_' || g::text
		   END AS k,
		   repeat(md5((g * 17)::text), 2) AS payload
	FROM generate_series(1, outer_rows) AS g;

	ANALYZE inner_unique_text;
	ANALYZE outer_unique_text;
END;
$$;

CREATE OR REPLACE FUNCTION bench_setup_int4_skew(inner_rows int, outer_rows int,
												  hot_keys int, hot_frac float8,
												  miss_ratio float8)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
	DROP TABLE IF EXISTS inner_skew_int4;
	DROP TABLE IF EXISTS outer_skew_int4;

	CREATE TABLE inner_skew_int4 AS
	SELECT g AS k, g AS payload
	FROM generate_series(1, inner_rows) AS g;

	CREATE TABLE outer_skew_int4 AS
	SELECT CASE
			 WHEN g > outer_rows * (1.0 - miss_ratio) THEN inner_rows + g
			 WHEN g <= outer_rows * hot_frac THEN ((g - 1) % hot_keys) + 1
			 ELSE hot_keys + (((g - 1) % GREATEST(inner_rows - hot_keys, 1)) + 1)
		   END AS k,
		   g AS payload
	FROM generate_series(1, outer_rows) AS g;

	ANALYZE inner_skew_int4;
	ANALYZE outer_skew_int4;
END;
$$;

CREATE OR REPLACE FUNCTION bench_setup_text_skew(inner_rows int, outer_rows int,
												  hot_keys int, hot_frac float8,
												  miss_ratio float8)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
	DROP TABLE IF EXISTS inner_skew_text;
	DROP TABLE IF EXISTS outer_skew_text;

	CREATE TABLE inner_skew_text AS
	SELECT 'k' || g::text AS k, repeat(md5(g::text), 2) AS payload
	FROM generate_series(1, inner_rows) AS g;

	CREATE TABLE outer_skew_text AS
	SELECT CASE
			 WHEN g > outer_rows * (1.0 - miss_ratio) THEN 'missing_' || g::text
			 WHEN g <= outer_rows * hot_frac THEN 'k' || ((((g - 1) % hot_keys) + 1))::text
			 ELSE 'k' || (hot_keys + (((g - 1) % GREATEST(inner_rows - hot_keys, 1)) + 1))::text
		   END AS k,
		   repeat(md5((g * 31)::text), 2) AS payload
	FROM generate_series(1, outer_rows) AS g;

	ANALYZE inner_skew_text;
	ANALYZE outer_skew_text;
END;
$$;