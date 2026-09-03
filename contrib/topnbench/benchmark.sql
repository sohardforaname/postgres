\set ON_ERROR_STOP on
\pset pager off
\timing on

DROP EXTENSION IF EXISTS topnbench;
CREATE EXTENSION IF NOT EXISTS topnbench;

DROP TABLE IF EXISTS topnbench_data;
CREATE UNLOGGED TABLE topnbench_data (a integer NOT NULL);
INSERT INTO topnbench_data
SELECT g FROM generate_series(1, 1000000) AS g;
ALTER TABLE topnbench_data SET (parallel_workers = 2);
ANALYZE topnbench_data;

-- The quick profile is a curated 16-case matrix.  Run this unchanged on
-- master and on the patched server, then diff/save the result tables.
SELECT *
FROM topnbench_run('topnbench_data', 'a', 3, 'quick', true);

-- The motivating numeric expression, measured without returning all rows.
SELECT *
FROM topnbench_compare(
    $q$
    SELECT a,
           a / (a * -1),
           a::numeric AS b,
           abs(a::numeric) / 12345.345632
    FROM topnbench_data
    ORDER BY a
    LIMIT 1
    $q$,
    $q$
    SELECT s.a,
           s.a / (s.a * -1),
           s.a::numeric AS b,
           abs(s.a::numeric) / 12345.345632
    FROM (
        SELECT a
        FROM topnbench_data
        ORDER BY a
        LIMIT 1
    ) AS s
    ORDER BY s.a
    $q$,
    $q$
    SELECT a,
           a / (a * -1) AS e2,
           a::numeric AS b,
           abs(a::numeric) / 12345.345632 AS e4
    FROM topnbench_data
    ORDER BY a, e2, b, e4
    LIMIT 1
    $q$,
    5,
    true);
