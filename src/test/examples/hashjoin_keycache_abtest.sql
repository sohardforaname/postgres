-- Standalone HashJoin key-cache A/B test.
-- Run this file with psql against a fresh database.  It intentionally has no
-- DROP/TRUNCATE cleanup so that the resulting tables remain available for
-- follow-up inspection.

\set ON_ERROR_STOP on
\timing on

SET client_min_messages = warning;
SET jit = off;
SET max_parallel_workers_per_gather = 0;
SET enable_hashjoin = on;
SET enable_mergejoin = off;
SET enable_nestloop = off;
SET enable_parallel_hash = off;
SET join_collapse_limit = 1;
SET work_mem = '1GB';
SET hash_mem_multiplier = 1.0;

CREATE SCHEMA hj_keycache_abtest;

-- DDL: one larger outer relation and three smaller inner relations.  The
-- payload makes materializing the full hash tuple more expensive than
-- comparing the four-byte join key.
CREATE TABLE hj_keycache_abtest.hj_a
(
    id integer NOT NULL,
    payload text NOT NULL
);

CREATE TABLE hj_keycache_abtest.hj_b
(
    id integer NOT NULL,
    payload text NOT NULL
);

CREATE TABLE hj_keycache_abtest.hj_c
(
    id integer NOT NULL,
    payload text NOT NULL
);

CREATE TABLE hj_keycache_abtest.hj_d
(
    id integer NOT NULL,
    payload text NOT NULL
);

-- DML: A has twice as many keys as the other tables, so half of the outer
-- probes miss while the joins still use simple integer equality.
INSERT INTO hj_keycache_abtest.hj_a
SELECT i, repeat(md5(i::text), 8)
FROM generate_series(1, 400000) AS s(i);

INSERT INTO hj_keycache_abtest.hj_b
SELECT i, repeat(md5(i::text), 8)
FROM generate_series(1, 200000) AS s(i);

INSERT INTO hj_keycache_abtest.hj_c
SELECT i, repeat(md5(i::text), 8)
FROM generate_series(1, 200000) AS s(i);

INSERT INTO hj_keycache_abtest.hj_d
SELECT i, repeat(md5(i::text), 8)
FROM generate_series(1, 200000) AS s(i);

-- Statistics phase.
ANALYZE hj_keycache_abtest.hj_a;
ANALYZE hj_keycache_abtest.hj_b;
ANALYZE hj_keycache_abtest.hj_c;
ANALYZE hj_keycache_abtest.hj_d;

-- Each pair runs the same query with the key cache enabled and disabled.
-- EXPLAIN ANALYZE reports Execution Time and also lets us verify Batches: 1.
\echo '2-table join: keycache=on'
SET enable_hashjoin_keycache = on;
EXPLAIN (ANALYZE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT count(*), sum(length(a.payload) + length(b.payload))
FROM hj_keycache_abtest.hj_a AS a
JOIN hj_keycache_abtest.hj_b AS b ON a.id = b.id;

\echo '2-table join: keycache=off'
SET enable_hashjoin_keycache = off;
EXPLAIN (ANALYZE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT count(*), sum(length(a.payload) + length(b.payload))
FROM hj_keycache_abtest.hj_a AS a
JOIN hj_keycache_abtest.hj_b AS b ON a.id = b.id;

\echo '3-table join: keycache=on'
SET enable_hashjoin_keycache = on;
EXPLAIN (ANALYZE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT count(*), sum(length(a.payload) + length(b.payload) + length(c.payload))
FROM hj_keycache_abtest.hj_a AS a
JOIN hj_keycache_abtest.hj_b AS b ON a.id = b.id
JOIN hj_keycache_abtest.hj_c AS c ON b.id = c.id;

\echo '3-table join: keycache=off'
SET enable_hashjoin_keycache = off;
EXPLAIN (ANALYZE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT count(*), sum(length(a.payload) + length(b.payload) + length(c.payload))
FROM hj_keycache_abtest.hj_a AS a
JOIN hj_keycache_abtest.hj_b AS b ON a.id = b.id
JOIN hj_keycache_abtest.hj_c AS c ON b.id = c.id;

\echo '4-table join: keycache=on'
SET enable_hashjoin_keycache = on;
EXPLAIN (ANALYZE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT count(*), sum(length(a.payload) + length(b.payload) +
                       length(c.payload) + length(d.payload))
FROM hj_keycache_abtest.hj_a AS a
JOIN hj_keycache_abtest.hj_b AS b ON a.id = b.id
JOIN hj_keycache_abtest.hj_c AS c ON b.id = c.id
JOIN hj_keycache_abtest.hj_d AS d ON c.id = d.id;

\echo '4-table join: keycache=off'
SET enable_hashjoin_keycache = off;
EXPLAIN (ANALYZE, BUFFERS, TIMING OFF, SUMMARY ON)
SELECT count(*), sum(length(a.payload) + length(b.payload) +
                       length(c.payload) + length(d.payload))
FROM hj_keycache_abtest.hj_a AS a
JOIN hj_keycache_abtest.hj_b AS b ON a.id = b.id
JOIN hj_keycache_abtest.hj_c AS c ON b.id = c.id
JOIN hj_keycache_abtest.hj_d AS d ON c.id = d.id;
