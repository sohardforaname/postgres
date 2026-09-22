-- FULL JOIN rewrite tests.
-- Run: psql -X -f benchmark.sql > benchmark.out 2>&1
-- Every pass value must be 1; marked EXPECTED ERROR cases are intentional.
-- Add -v fj_test_file_fdw=1 to enable optional file_fdw tests.
\set ON_ERROR_STOP on
\pset pager off
\timing on
\if :{?fj_test_file_fdw}
\else
\set fj_test_file_fdw false
\endif
\set fj_rls_ran false
\set fj_fdw_ran false
BEGIN;
CREATE SCHEMA fj_rewrite_test;
SET LOCAL search_path = fj_rewrite_test, pg_catalog;
SET LOCAL jit = off;
SET LOCAL max_parallel_workers_per_gather = 0;
SET LOCAL enable_full_join_rewrite = off;
SET LOCAL enable_hashjoin = on;
SET LOCAL enable_mergejoin = on;
SET LOCAL enable_nestloop = on;

CREATE TABLE a(id int, k int, v numeric(12,2), txt text COLLATE "C", flag boolean);
CREATE TABLE b(LIKE a);
INSERT INTO a VALUES
 (1,1,10,'alpha',true), (2,1,20,'ALPHA',false),
 (3,2,NULL,'beta',NULL), (4,NULL,40,NULL,true),
 (5,NULL,NULL,'null-key',NULL), (6,3,-5,'gamma',false),
 (7,5,0,'',true), (8,6,12,'same',true),
 (8,6,12,'same',true), (NULL,NULL,NULL,NULL,NULL),
 (NULL,NULL,NULL,NULL,NULL), (9,-1,25,'under_score',false);
INSERT INTO b VALUES
 (11,1,15,'alpha',true), (12,1,30,'ALPHA',NULL),
 (13,2,3,'beta',false), (14,NULL,45,NULL,true),
 (15,NULL,NULL,'null-key',NULL), (16,4,-7,'delta',false),
 (17,5,0,'',true), (18,6,12,'same',true),
 (18,6,12,'same',true), (NULL,NULL,NULL,NULL,NULL),
 (NULL,NULL,NULL,NULL,NULL), (19,-1,25,'underXscore',false);
CREATE TABLE empty_input(LIKE a);
CREATE TABLE c(id int, k int);
INSERT INTO c VALUES (101,1),(102,2),(103,4),(104,9),(105,NULL),(106,1);
ANALYZE a;
ANALYZE b;
ANALYZE c;

-- 001. integer equality; many-to-many matches, duplicate rows and NULL keys
\echo 'CASE 001: integer equality; many-to-many matches, duplicate rows and NULL keys'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k;
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k;
SELECT '001' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 002. two equality clauses
\echo 'CASE 002: two equality clauses'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k AND a.flag = b.flag;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k AND a.flag = b.flag;
SELECT '002' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 003. equality plus inequality residual
\echo 'CASE 003: equality plus inequality residual'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k AND a.v < b.v;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k AND a.v < b.v;
SELECT '003' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 004. equality plus left-only residual
\echo 'CASE 004: equality plus left-only residual'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k AND a.v > 10;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k AND a.v > 10;
SELECT '004' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 005. equality plus right-only residual
\echo 'CASE 005: equality plus right-only residual'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k AND b.v > 20;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k AND b.v > 20;
SELECT '005' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 006. equality plus non-strict residual
\echo 'CASE 006: equality plus non-strict residual'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k AND (a.flag IS NULL OR b.flag IS NULL);
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k AND (a.flag IS NULL OR b.flag IS NULL);
SELECT '006' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 007. equality plus CASE residual
\echo 'CASE 007: equality plus CASE residual'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k AND CASE WHEN a.v IS NULL THEN true ELSE a.v <= b.v END;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k AND CASE WHEN a.v IS NULL THEN true ELSE a.v <= b.v END;
SELECT '007' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 008. equality plus OR residual
\echo 'CASE 008: equality plus OR residual'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k AND (a.v < b.v OR a.txt = b.txt);
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k AND (a.v < b.v OR a.txt = b.txt);
SELECT '008' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 009. equality plus NOT residual
\echo 'CASE 009: equality plus NOT residual'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k AND NOT (a.flag AND b.flag);
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k AND NOT (a.flag AND b.flag);
SELECT '009' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 010. arithmetic equality
\echo 'CASE 010: arithmetic equality'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k + 1 = b.k - 1;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k + 1 = b.k - 1;
SELECT '010' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 011. function equality
\echo 'CASE 011: function equality'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON lower(a.txt) = lower(b.txt);
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON lower(a.txt) = lower(b.txt);
SELECT '011' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 012. explicit cast equality
\echo 'CASE 012: explicit cast equality'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k::bigint = b.k::numeric;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k::bigint = b.k::numeric;
SELECT '012' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 013. non-strict COALESCE equality matches NULL keys
\echo 'CASE 013: non-strict COALESCE equality matches NULL keys'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON coalesce(a.k,-1) = coalesce(b.k,-1);
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON coalesce(a.k,-1) = coalesce(b.k,-1);
SELECT '013' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 014. row equality
\echo 'CASE 014: row equality'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON ROW(a.k,a.flag) = ROW(b.k,b.flag);
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON ROW(a.k,a.flag) = ROW(b.k,b.flag);
SELECT '014' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 015. numeric equality
\echo 'CASE 015: numeric equality'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.v = b.v;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.v = b.v;
SELECT '015' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 016. boolean equality
\echo 'CASE 016: boolean equality'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.flag = b.flag;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.flag = b.flag;
SELECT '016' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 017. collated text equality
\echo 'CASE 017: collated text equality'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.txt COLLATE "C" = b.txt COLLATE "C";
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.txt COLLATE "C" = b.txt COLLATE "C";
SELECT '017' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 018. strict NULLIF expressions
\echo 'CASE 018: strict NULLIF expressions'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON nullif(a.k,1) = nullif(b.k,1);
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON nullif(a.k,1) = nullif(b.k,1);
SELECT '018' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 019. constant TRUE
\echo 'CASE 019: constant TRUE'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON true;
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON true;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON true;
SELECT '019' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 020. constant FALSE
\echo 'CASE 020: constant FALSE'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON false;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON false;
SELECT '020' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 021. constant UNKNOWN
\echo 'CASE 021: constant UNKNOWN'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON NULL::boolean;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON NULL::boolean;
SELECT '021' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 022. hash equality and stable expression
\echo 'CASE 022: hash equality and stable expression'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k AND CURRENT_DATE = CURRENT_DATE;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k AND CURRENT_DATE = CURRENT_DATE;
SELECT '022' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 023. scalar sublink in ON
\echo 'CASE 023: scalar sublink in ON'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k AND a.v >= (SELECT min(v) FROM c CROSS JOIN (VALUES (0::numeric)) AS t(v));
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k AND a.v >= (SELECT min(v) FROM c CROSS JOIN (VALUES (0::numeric)) AS t(v));
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k AND a.v >= (SELECT min(v) FROM c CROSS JOIN (VALUES (0::numeric)) AS t(v));
SELECT '023' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 024. correlated EXISTS in ON
\echo 'CASE 024: correlated EXISTS in ON'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k AND EXISTS (SELECT 1 FROM c WHERE c.k = a.k);
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k AND EXISTS (SELECT 1 FROM c WHERE c.k = a.k);
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k AND EXISTS (SELECT 1 FROM c WHERE c.k = a.k);
SELECT '024' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 025. correlated NOT EXISTS in ON
\echo 'CASE 025: correlated NOT EXISTS in ON'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k AND NOT EXISTS (SELECT 1 FROM c WHERE c.k = b.k AND c.id > 105);
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k AND NOT EXISTS (SELECT 1 FROM c WHERE c.k = b.k AND c.id > 105);
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k AND NOT EXISTS (SELECT 1 FROM c WHERE c.k = b.k AND c.id > 105);
SELECT '025' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 026. null-safe IS NOT DISTINCT FROM
\echo 'CASE 026: null-safe IS NOT DISTINCT FROM'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a INNER JOIN b ON a.k IS NOT DISTINCT FROM b.k
UNION ALL
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, NULL::int AS bid, NULL::int AS bk, NULL::numeric(12,2) AS bv, NULL::text AS btxt, NULL::boolean AS bflag
FROM a WHERE NOT EXISTS (SELECT 1 FROM b WHERE a.k IS NOT DISTINCT FROM b.k)
UNION ALL
SELECT NULL::int AS aid, NULL::int AS ak, NULL::numeric(12,2) AS av, NULL::text AS atxt, NULL::boolean AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM b WHERE NOT EXISTS (SELECT 1 FROM a WHERE a.k IS NOT DISTINCT FROM b.k);
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k IS NOT DISTINCT FROM b.k;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k IS NOT DISTINCT FROM b.k;
SELECT '026' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 027. IS DISTINCT FROM
\echo 'CASE 027: IS DISTINCT FROM'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a INNER JOIN b ON a.k IS DISTINCT FROM b.k
UNION ALL
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, NULL::int AS bid, NULL::int AS bk, NULL::numeric(12,2) AS bv, NULL::text AS btxt, NULL::boolean AS bflag
FROM a WHERE NOT EXISTS (SELECT 1 FROM b WHERE a.k IS DISTINCT FROM b.k)
UNION ALL
SELECT NULL::int AS aid, NULL::int AS ak, NULL::numeric(12,2) AS av, NULL::text AS atxt, NULL::boolean AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM b WHERE NOT EXISTS (SELECT 1 FROM a WHERE a.k IS DISTINCT FROM b.k);
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k IS DISTINCT FROM b.k;
SELECT '027' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 028. strict less-than
\echo 'CASE 028: strict less-than'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a INNER JOIN b ON a.k < b.k
UNION ALL
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, NULL::int AS bid, NULL::int AS bk, NULL::numeric(12,2) AS bv, NULL::text AS btxt, NULL::boolean AS bflag
FROM a WHERE NOT EXISTS (SELECT 1 FROM b WHERE a.k < b.k)
UNION ALL
SELECT NULL::int AS aid, NULL::int AS ak, NULL::numeric(12,2) AS av, NULL::text AS atxt, NULL::boolean AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM b WHERE NOT EXISTS (SELECT 1 FROM a WHERE a.k < b.k);
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k < b.k;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k < b.k;
SELECT '028' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 029. strict greater-or-equal
\echo 'CASE 029: strict greater-or-equal'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a INNER JOIN b ON a.v >= b.v
UNION ALL
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, NULL::int AS bid, NULL::int AS bk, NULL::numeric(12,2) AS bv, NULL::text AS btxt, NULL::boolean AS bflag
FROM a WHERE NOT EXISTS (SELECT 1 FROM b WHERE a.v >= b.v)
UNION ALL
SELECT NULL::int AS aid, NULL::int AS ak, NULL::numeric(12,2) AS av, NULL::text AS atxt, NULL::boolean AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM b WHERE NOT EXISTS (SELECT 1 FROM a WHERE a.v >= b.v);
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.v >= b.v;
SELECT '029' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 030. not equal
\echo 'CASE 030: not equal'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a INNER JOIN b ON a.k <> b.k
UNION ALL
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, NULL::int AS bid, NULL::int AS bk, NULL::numeric(12,2) AS bv, NULL::text AS btxt, NULL::boolean AS bflag
FROM a WHERE NOT EXISTS (SELECT 1 FROM b WHERE a.k <> b.k)
UNION ALL
SELECT NULL::int AS aid, NULL::int AS ak, NULL::numeric(12,2) AS av, NULL::text AS atxt, NULL::boolean AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM b WHERE NOT EXISTS (SELECT 1 FROM a WHERE a.k <> b.k);
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k <> b.k;
SELECT '030' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 031. range predicate
\echo 'CASE 031: range predicate'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a INNER JOIN b ON a.k BETWEEN b.k - 1 AND b.k + 1
UNION ALL
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, NULL::int AS bid, NULL::int AS bk, NULL::numeric(12,2) AS bv, NULL::text AS btxt, NULL::boolean AS bflag
FROM a WHERE NOT EXISTS (SELECT 1 FROM b WHERE a.k BETWEEN b.k - 1 AND b.k + 1)
UNION ALL
SELECT NULL::int AS aid, NULL::int AS ak, NULL::numeric(12,2) AS av, NULL::text AS atxt, NULL::boolean AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM b WHERE NOT EXISTS (SELECT 1 FROM a WHERE a.k BETWEEN b.k - 1 AND b.k + 1);
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k BETWEEN b.k - 1 AND b.k + 1;
SELECT '031' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 032. OR of two equalities
\echo 'CASE 032: OR of two equalities'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a INNER JOIN b ON a.k = b.k OR a.txt = b.txt
UNION ALL
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, NULL::int AS bid, NULL::int AS bk, NULL::numeric(12,2) AS bv, NULL::text AS btxt, NULL::boolean AS bflag
FROM a WHERE NOT EXISTS (SELECT 1 FROM b WHERE a.k = b.k OR a.txt = b.txt)
UNION ALL
SELECT NULL::int AS aid, NULL::int AS ak, NULL::numeric(12,2) AS av, NULL::text AS atxt, NULL::boolean AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM b WHERE NOT EXISTS (SELECT 1 FROM a WHERE a.k = b.k OR a.txt = b.txt);
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k OR a.txt = b.txt;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k OR a.txt = b.txt;
SELECT '032' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 033. IS TRUE around equality
\echo 'CASE 033: IS TRUE around equality'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a INNER JOIN b ON (a.k = b.k) IS TRUE
UNION ALL
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, NULL::int AS bid, NULL::int AS bk, NULL::numeric(12,2) AS bv, NULL::text AS btxt, NULL::boolean AS bflag
FROM a WHERE NOT EXISTS (SELECT 1 FROM b WHERE (a.k = b.k) IS TRUE)
UNION ALL
SELECT NULL::int AS aid, NULL::int AS ak, NULL::numeric(12,2) AS av, NULL::text AS atxt, NULL::boolean AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM b WHERE NOT EXISTS (SELECT 1 FROM a WHERE (a.k = b.k) IS TRUE);
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON (a.k = b.k) IS TRUE;
SELECT '033' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 034. IS NOT FALSE accepts UNKNOWN
\echo 'CASE 034: IS NOT FALSE accepts UNKNOWN'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a INNER JOIN b ON (a.k = b.k) IS NOT FALSE
UNION ALL
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, NULL::int AS bid, NULL::int AS bk, NULL::numeric(12,2) AS bv, NULL::text AS btxt, NULL::boolean AS bflag
FROM a WHERE NOT EXISTS (SELECT 1 FROM b WHERE (a.k = b.k) IS NOT FALSE)
UNION ALL
SELECT NULL::int AS aid, NULL::int AS ak, NULL::numeric(12,2) AS av, NULL::text AS atxt, NULL::boolean AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM b WHERE NOT EXISTS (SELECT 1 FROM a WHERE (a.k = b.k) IS NOT FALSE);
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON (a.k = b.k) IS NOT FALSE;
SELECT '034' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 035. IS UNKNOWN around equality
\echo 'CASE 035: IS UNKNOWN around equality'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a INNER JOIN b ON (a.k = b.k) IS UNKNOWN
UNION ALL
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, NULL::int AS bid, NULL::int AS bk, NULL::numeric(12,2) AS bv, NULL::text AS btxt, NULL::boolean AS bflag
FROM a WHERE NOT EXISTS (SELECT 1 FROM b WHERE (a.k = b.k) IS UNKNOWN)
UNION ALL
SELECT NULL::int AS aid, NULL::int AS ak, NULL::numeric(12,2) AS av, NULL::text AS atxt, NULL::boolean AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM b WHERE NOT EXISTS (SELECT 1 FROM a WHERE (a.k = b.k) IS UNKNOWN);
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON (a.k = b.k) IS UNKNOWN;
SELECT '035' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 036. non-strict CASE join predicate
\echo 'CASE 036: non-strict CASE join predicate'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a INNER JOIN b ON CASE WHEN a.k IS NULL THEN b.k IS NULL ELSE a.k = b.k END
UNION ALL
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, NULL::int AS bid, NULL::int AS bk, NULL::numeric(12,2) AS bv, NULL::text AS btxt, NULL::boolean AS bflag
FROM a WHERE NOT EXISTS (SELECT 1 FROM b WHERE CASE WHEN a.k IS NULL THEN b.k IS NULL ELSE a.k = b.k END)
UNION ALL
SELECT NULL::int AS aid, NULL::int AS ak, NULL::numeric(12,2) AS av, NULL::text AS atxt, NULL::boolean AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM b WHERE NOT EXISTS (SELECT 1 FROM a WHERE CASE WHEN a.k IS NULL THEN b.k IS NULL ELSE a.k = b.k END);
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON CASE WHEN a.k IS NULL THEN b.k IS NULL ELSE a.k = b.k END;
SELECT '036' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 037. left-only predicate
\echo 'CASE 037: left-only predicate'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a INNER JOIN b ON a.v > 10
UNION ALL
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, NULL::int AS bid, NULL::int AS bk, NULL::numeric(12,2) AS bv, NULL::text AS btxt, NULL::boolean AS bflag
FROM a WHERE NOT EXISTS (SELECT 1 FROM b WHERE a.v > 10)
UNION ALL
SELECT NULL::int AS aid, NULL::int AS ak, NULL::numeric(12,2) AS av, NULL::text AS atxt, NULL::boolean AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM b WHERE NOT EXISTS (SELECT 1 FROM a WHERE a.v > 10);
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.v > 10;
SELECT '037' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 038. right-only predicate
\echo 'CASE 038: right-only predicate'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a INNER JOIN b ON b.v < 20
UNION ALL
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, NULL::int AS bid, NULL::int AS bk, NULL::numeric(12,2) AS bv, NULL::text AS btxt, NULL::boolean AS bflag
FROM a WHERE NOT EXISTS (SELECT 1 FROM b WHERE b.v < 20)
UNION ALL
SELECT NULL::int AS aid, NULL::int AS ak, NULL::numeric(12,2) AS av, NULL::text AS atxt, NULL::boolean AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM b WHERE NOT EXISTS (SELECT 1 FROM a WHERE b.v < 20);
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON b.v < 20;
SELECT '038' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 039. left-only IS NULL matches actual NULL-key rows
\echo 'CASE 039: left-only IS NULL matches actual NULL-key rows'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a INNER JOIN b ON a.k IS NULL
UNION ALL
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, NULL::int AS bid, NULL::int AS bk, NULL::numeric(12,2) AS bv, NULL::text AS btxt, NULL::boolean AS bflag
FROM a WHERE NOT EXISTS (SELECT 1 FROM b WHERE a.k IS NULL)
UNION ALL
SELECT NULL::int AS aid, NULL::int AS ak, NULL::numeric(12,2) AS av, NULL::text AS atxt, NULL::boolean AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM b WHERE NOT EXISTS (SELECT 1 FROM a WHERE a.k IS NULL);
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k IS NULL;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k IS NULL;
SELECT '039' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 040. both-side NULL disjunction
\echo 'CASE 040: both-side NULL disjunction'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a INNER JOIN b ON a.k IS NULL OR b.k IS NULL
UNION ALL
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, NULL::int AS bid, NULL::int AS bk, NULL::numeric(12,2) AS bv, NULL::text AS btxt, NULL::boolean AS bflag
FROM a WHERE NOT EXISTS (SELECT 1 FROM b WHERE a.k IS NULL OR b.k IS NULL)
UNION ALL
SELECT NULL::int AS aid, NULL::int AS ak, NULL::numeric(12,2) AS av, NULL::text AS atxt, NULL::boolean AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM b WHERE NOT EXISTS (SELECT 1 FROM a WHERE a.k IS NULL OR b.k IS NULL);
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k IS NULL OR b.k IS NULL;
SELECT '040' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 041. non-equality negation
\echo 'CASE 041: non-equality negation'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a INNER JOIN b ON NOT (a.k <= b.k)
UNION ALL
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, NULL::int AS bid, NULL::int AS bk, NULL::numeric(12,2) AS bv, NULL::text AS btxt, NULL::boolean AS bflag
FROM a WHERE NOT EXISTS (SELECT 1 FROM b WHERE NOT (a.k <= b.k))
UNION ALL
SELECT NULL::int AS aid, NULL::int AS ak, NULL::numeric(12,2) AS av, NULL::text AS atxt, NULL::boolean AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM b WHERE NOT EXISTS (SELECT 1 FROM a WHERE NOT (a.k <= b.k));
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON NOT (a.k <= b.k);
SELECT '041' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 042. IN predicate
\echo 'CASE 042: IN predicate'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a INNER JOIN b ON a.k IN (b.k,b.k + 1)
UNION ALL
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, NULL::int AS bid, NULL::int AS bk, NULL::numeric(12,2) AS bv, NULL::text AS btxt, NULL::boolean AS bflag
FROM a WHERE NOT EXISTS (SELECT 1 FROM b WHERE a.k IN (b.k,b.k + 1))
UNION ALL
SELECT NULL::int AS aid, NULL::int AS ak, NULL::numeric(12,2) AS av, NULL::text AS atxt, NULL::boolean AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM b WHERE NOT EXISTS (SELECT 1 FROM a WHERE a.k IN (b.k,b.k + 1));
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k IN (b.k,b.k + 1);
SELECT '042' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 043. text LIKE
\echo 'CASE 043: text LIKE'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a INNER JOIN b ON a.txt LIKE b.txt
UNION ALL
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, NULL::int AS bid, NULL::int AS bk, NULL::numeric(12,2) AS bv, NULL::text AS btxt, NULL::boolean AS bflag
FROM a WHERE NOT EXISTS (SELECT 1 FROM b WHERE a.txt LIKE b.txt)
UNION ALL
SELECT NULL::int AS aid, NULL::int AS ak, NULL::numeric(12,2) AS av, NULL::text AS atxt, NULL::boolean AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM b WHERE NOT EXISTS (SELECT 1 FROM a WHERE a.txt LIKE b.txt);
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.txt LIKE b.txt;
SELECT '043' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 044. regular expression
\echo 'CASE 044: regular expression'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a INNER JOIN b ON a.txt ~ b.txt
UNION ALL
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, NULL::int AS bid, NULL::int AS bk, NULL::numeric(12,2) AS bv, NULL::text AS btxt, NULL::boolean AS bflag
FROM a WHERE NOT EXISTS (SELECT 1 FROM b WHERE a.txt ~ b.txt)
UNION ALL
SELECT NULL::int AS aid, NULL::int AS ak, NULL::numeric(12,2) AS av, NULL::text AS atxt, NULL::boolean AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM b WHERE NOT EXISTS (SELECT 1 FROM a WHERE a.txt ~ b.txt);
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.txt ~ b.txt;
SELECT '044' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 045. boolean disjunction
\echo 'CASE 045: boolean disjunction'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a INNER JOIN b ON a.flag OR b.flag
UNION ALL
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, NULL::int AS bid, NULL::int AS bk, NULL::numeric(12,2) AS bv, NULL::text AS btxt, NULL::boolean AS bflag
FROM a WHERE NOT EXISTS (SELECT 1 FROM b WHERE a.flag OR b.flag)
UNION ALL
SELECT NULL::int AS aid, NULL::int AS ak, NULL::numeric(12,2) AS av, NULL::text AS atxt, NULL::boolean AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM b WHERE NOT EXISTS (SELECT 1 FROM a WHERE a.flag OR b.flag);
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.flag OR b.flag;
SELECT '045' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 046. row null-safe equality
\echo 'CASE 046: row null-safe equality'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a INNER JOIN b ON ROW(a.k,a.flag) IS NOT DISTINCT FROM ROW(b.k,b.flag)
UNION ALL
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, NULL::int AS bid, NULL::int AS bk, NULL::numeric(12,2) AS bv, NULL::text AS btxt, NULL::boolean AS bflag
FROM a WHERE NOT EXISTS (SELECT 1 FROM b WHERE ROW(a.k,a.flag) IS NOT DISTINCT FROM ROW(b.k,b.flag))
UNION ALL
SELECT NULL::int AS aid, NULL::int AS ak, NULL::numeric(12,2) AS av, NULL::text AS atxt, NULL::boolean AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM b WHERE NOT EXISTS (SELECT 1 FROM a WHERE ROW(a.k,a.flag) IS NOT DISTINCT FROM ROW(b.k,b.flag));
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON ROW(a.k,a.flag) IS NOT DISTINCT FROM ROW(b.k,b.flag);
SELECT '046' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 047. constant arithmetic join predicate
\echo 'CASE 047: constant arithmetic join predicate'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a INNER JOIN b ON coalesce(a.v,0) + coalesce(b.v,0) > 30
UNION ALL
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, NULL::int AS bid, NULL::int AS bk, NULL::numeric(12,2) AS bv, NULL::text AS btxt, NULL::boolean AS bflag
FROM a WHERE NOT EXISTS (SELECT 1 FROM b WHERE coalesce(a.v,0) + coalesce(b.v,0) > 30)
UNION ALL
SELECT NULL::int AS aid, NULL::int AS ak, NULL::numeric(12,2) AS av, NULL::text AS atxt, NULL::boolean AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM b WHERE NOT EXISTS (SELECT 1 FROM a WHERE coalesce(a.v,0) + coalesce(b.v,0) > 30);
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON coalesce(a.v,0) + coalesce(b.v,0) > 30;
SELECT '047' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 048. WHERE left strict filter
\echo 'CASE 048: WHERE left strict filter'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE a.v > 10;
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE a.v > 10;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE a.v > 10;
SELECT '048' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 049. WHERE right strict filter
\echo 'CASE 049: WHERE right strict filter'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE b.v > 10;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE b.v > 10;
SELECT '049' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 050. WHERE both sides strict
\echo 'CASE 050: WHERE both sides strict'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE a.v > 10 AND b.v > 10;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE a.v > 10 AND b.v > 10;
SELECT '050' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 051. WHERE left nullable key IS NULL
\echo 'CASE 051: WHERE left nullable key IS NULL'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE a.k IS NULL;
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE a.k IS NULL;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE a.k IS NULL;
SELECT '051' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 052. WHERE right nullable key IS NULL
\echo 'CASE 052: WHERE right nullable key IS NULL'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE b.k IS NULL;
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE b.k IS NULL;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE b.k IS NULL;
SELECT '052' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 053. WHERE both keys IS NULL
\echo 'CASE 053: WHERE both keys IS NULL'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE a.k IS NULL AND b.k IS NULL;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE a.k IS NULL AND b.k IS NULL;
SELECT '053' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 054. WHERE left IS NOT NULL
\echo 'CASE 054: WHERE left IS NOT NULL'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE a.id IS NOT NULL;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE a.id IS NOT NULL;
SELECT '054' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 055. WHERE right IS NOT NULL
\echo 'CASE 055: WHERE right IS NOT NULL'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE b.id IS NOT NULL;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE b.id IS NOT NULL;
SELECT '055' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 056. WHERE null-preserving OR
\echo 'CASE 056: WHERE null-preserving OR'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE a.k IS NULL OR b.v > 20;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE a.k IS NULL OR b.v > 20;
SELECT '056' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 057. WHERE cross-input OR
\echo 'CASE 057: WHERE cross-input OR'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE a.v > 20 OR b.v > 20;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE a.v > 20 OR b.v > 20;
SELECT '057' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 058. WHERE COALESCE of both inputs
\echo 'CASE 058: WHERE COALESCE of both inputs'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE coalesce(a.k,b.k) >= 3;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE coalesce(a.k,b.k) >= 3;
SELECT '058' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 059. WHERE IS DISTINCT FROM
\echo 'CASE 059: WHERE IS DISTINCT FROM'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE a.v IS DISTINCT FROM b.v;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE a.v IS DISTINCT FROM b.v;
SELECT '059' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 060. WHERE IS NOT DISTINCT FROM
\echo 'CASE 060: WHERE IS NOT DISTINCT FROM'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE a.v IS NOT DISTINCT FROM b.v;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE a.v IS NOT DISTINCT FROM b.v;
SELECT '060' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 061. WHERE boolean IS NOT TRUE
\echo 'CASE 061: WHERE boolean IS NOT TRUE'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE a.flag IS NOT TRUE;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE a.flag IS NOT TRUE;
SELECT '061' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 062. WHERE boolean UNKNOWN
\echo 'CASE 062: WHERE boolean UNKNOWN'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE (a.flag AND b.flag) IS UNKNOWN;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE (a.flag AND b.flag) IS UNKNOWN;
SELECT '062' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 063. WHERE NOT
\echo 'CASE 063: WHERE NOT'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE NOT (a.v < b.v);
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE NOT (a.v < b.v);
SELECT '063' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 064. WHERE CASE
\echo 'CASE 064: WHERE CASE'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE CASE WHEN a.k IS NULL THEN b.v > 10 ELSE a.v > 10 END;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE CASE WHEN a.k IS NULL THEN b.v > 10 ELSE a.v > 10 END;
SELECT '064' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 065. WHERE rejects all previously matched pairs
\echo 'CASE 065: WHERE rejects all previously matched pairs'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE a.k = 1 AND b.k IS NULL;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE a.k = 1 AND b.k IS NULL;
SELECT '065' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 066. WHERE TRUE
\echo 'CASE 066: WHERE TRUE'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE true;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE true;
SELECT '066' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 067. WHERE FALSE
\echo 'CASE 067: WHERE FALSE'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE false;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE false;
SELECT '067' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 068. WHERE UNKNOWN
\echo 'CASE 068: WHERE UNKNOWN'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE NULL::boolean;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE NULL::boolean;
SELECT '068' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 069. WHERE scalar subquery
\echo 'CASE 069: WHERE scalar subquery'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE coalesce(a.k,b.k) >= (SELECT min(k) FROM c);
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE coalesce(a.k,b.k) >= (SELECT min(k) FROM c);
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE coalesce(a.k,b.k) >= (SELECT min(k) FROM c);
SELECT '069' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 070. WHERE correlated EXISTS
\echo 'CASE 070: WHERE correlated EXISTS'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE EXISTS (SELECT 1 FROM c WHERE c.k = coalesce(a.k,b.k));
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE EXISTS (SELECT 1 FROM c WHERE c.k = coalesce(a.k,b.k));
SELECT '070' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 071. WHERE correlated NOT EXISTS
\echo 'CASE 071: WHERE correlated NOT EXISTS'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE NOT EXISTS (SELECT 1 FROM c WHERE c.k = a.k);
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE NOT EXISTS (SELECT 1 FROM c WHERE c.k = a.k);
SELECT '071' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 072. WHERE IN
\echo 'CASE 072: WHERE IN'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE coalesce(a.k,b.k) IN (SELECT k FROM c);
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE coalesce(a.k,b.k) IN (SELECT k FROM c);
SELECT '072' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 073. WHERE NOT IN with NULL in subquery
\echo 'CASE 073: WHERE NOT IN with NULL in subquery'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE coalesce(a.k,b.k) NOT IN (SELECT k FROM c);
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE coalesce(a.k,b.k) NOT IN (SELECT k FROM c);
SELECT '073' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 074. WHERE nested correlated sublinks
\echo 'CASE 074: WHERE nested correlated sublinks'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE EXISTS (SELECT 1 FROM c WHERE EXISTS (SELECT 1 FROM c d WHERE d.k = a.k AND d.id = c.id));
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE EXISTS (SELECT 1 FROM c WHERE EXISTS (SELECT 1 FROM c d WHERE d.k = a.k AND d.id = c.id));
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE EXISTS (SELECT 1 FROM c WHERE EXISTS (SELECT 1 FROM c d WHERE d.k = a.k AND d.id = c.id));
SELECT '074' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 075. WHERE whole named table row IS NULL
\echo 'CASE 075: WHERE whole named table row IS NULL'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE a IS NULL;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE a IS NULL;
SELECT '075' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 076. WHERE whole named table row IS NOT NULL
\echo 'CASE 076: WHERE whole named table row IS NOT NULL'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE b IS NOT NULL;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k
WHERE b IS NOT NULL;
SELECT '076' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 077. null-safe join followed by NULL-key WHERE
\echo 'CASE 077: null-safe join followed by NULL-key WHERE'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT * FROM (
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a INNER JOIN b ON a.k IS NOT DISTINCT FROM b.k
UNION ALL
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, NULL::int AS bid, NULL::int AS bk, NULL::numeric(12,2) AS bv, NULL::text AS btxt, NULL::boolean AS bflag
FROM a WHERE NOT EXISTS (SELECT 1 FROM b WHERE a.k IS NOT DISTINCT FROM b.k)
UNION ALL
SELECT NULL::int AS aid, NULL::int AS ak, NULL::numeric(12,2) AS av, NULL::text AS atxt, NULL::boolean AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM b WHERE NOT EXISTS (SELECT 1 FROM a WHERE a.k IS NOT DISTINCT FROM b.k)
) AS j WHERE ak IS NULL;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT * FROM (
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k IS NOT DISTINCT FROM b.k
) AS j WHERE ak IS NULL;
SELECT '077' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 078. OR join followed by right NULL filter
\echo 'CASE 078: OR join followed by right NULL filter'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT * FROM (
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a INNER JOIN b ON a.k = b.k OR a.txt = b.txt
UNION ALL
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, NULL::int AS bid, NULL::int AS bk, NULL::numeric(12,2) AS bv, NULL::text AS btxt, NULL::boolean AS bflag
FROM a WHERE NOT EXISTS (SELECT 1 FROM b WHERE a.k = b.k OR a.txt = b.txt)
UNION ALL
SELECT NULL::int AS aid, NULL::int AS ak, NULL::numeric(12,2) AS av, NULL::text AS atxt, NULL::boolean AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM b WHERE NOT EXISTS (SELECT 1 FROM a WHERE a.k = b.k OR a.txt = b.txt)
) AS j WHERE bid IS NULL;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT * FROM (
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k = b.k OR a.txt = b.txt
) AS j WHERE bid IS NULL;
SELECT '078' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 079. range join followed by OR filter
\echo 'CASE 079: range join followed by OR filter'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT * FROM (
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a INNER JOIN b ON a.k < b.k
UNION ALL
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, NULL::int AS bid, NULL::int AS bk, NULL::numeric(12,2) AS bv, NULL::text AS btxt, NULL::boolean AS bflag
FROM a WHERE NOT EXISTS (SELECT 1 FROM b WHERE a.k < b.k)
UNION ALL
SELECT NULL::int AS aid, NULL::int AS ak, NULL::numeric(12,2) AS av, NULL::text AS atxt, NULL::boolean AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM b WHERE NOT EXISTS (SELECT 1 FROM a WHERE a.k < b.k)
) AS j WHERE ak IS NULL OR bv > 20;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT * FROM (
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k < b.k
) AS j WHERE ak IS NULL OR bv > 20;
SELECT '079' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 080. non-strict join followed by both NULL filters
\echo 'CASE 080: non-strict join followed by both NULL filters'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT * FROM (
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a INNER JOIN b ON (a.k = b.k) IS NOT FALSE
UNION ALL
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, NULL::int AS bid, NULL::int AS bk, NULL::numeric(12,2) AS bv, NULL::text AS btxt, NULL::boolean AS bflag
FROM a WHERE NOT EXISTS (SELECT 1 FROM b WHERE (a.k = b.k) IS NOT FALSE)
UNION ALL
SELECT NULL::int AS aid, NULL::int AS ak, NULL::numeric(12,2) AS av, NULL::text AS atxt, NULL::boolean AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM b WHERE NOT EXISTS (SELECT 1 FROM a WHERE (a.k = b.k) IS NOT FALSE)
) AS j WHERE ak IS NULL AND bk IS NULL;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT * FROM (
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON (a.k = b.k) IS NOT FALSE
) AS j WHERE ak IS NULL AND bk IS NULL;
SELECT '080' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 081. inequality join followed by rejecting matched rows
\echo 'CASE 081: inequality join followed by rejecting matched rows'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT * FROM (
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a INNER JOIN b ON a.k < b.k
UNION ALL
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, NULL::int AS bid, NULL::int AS bk, NULL::numeric(12,2) AS bv, NULL::text AS btxt, NULL::boolean AS bflag
FROM a WHERE NOT EXISTS (SELECT 1 FROM b WHERE a.k < b.k)
UNION ALL
SELECT NULL::int AS aid, NULL::int AS ak, NULL::numeric(12,2) AS av, NULL::text AS atxt, NULL::boolean AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM b WHERE NOT EXISTS (SELECT 1 FROM a WHERE a.k < b.k)
) AS j WHERE ak = 1 AND bk IS NULL;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT * FROM (
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k < b.k
) AS j WHERE ak = 1 AND bk IS NULL;
SELECT '081' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 082. USING key including coalesced output and original side keys
\echo 'CASE 082: USING key including coalesced output and original side keys'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT k, a.k AS ak, b.k AS bk, a.id AS aid, b.id AS bid FROM a FULL JOIN b USING (k);
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT k, a.k AS ak, b.k AS bk, a.id AS aid, b.id AS bid FROM a FULL JOIN b USING (k);
CREATE TEMP TABLE actual AS
SELECT k, a.k AS ak, b.k AS bk, a.id AS aid, b.id AS bid FROM a FULL JOIN b USING (k);
SELECT '082' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 083. USING two columns
\echo 'CASE 083: USING two columns'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT k, flag, a.id AS aid, b.id AS bid FROM a FULL JOIN b USING (k,flag);
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT k, flag, a.id AS aid, b.id AS bid FROM a FULL JOIN b USING (k,flag);
SELECT '083' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 084. NATURAL FULL JOIN with duplicate identical rows
\echo 'CASE 084: NATURAL FULL JOIN with duplicate identical rows'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT * FROM a NATURAL FULL JOIN b;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT * FROM a NATURAL FULL JOIN b;
SELECT '084' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 085. aliased join with renamed columns
\echo 'CASE 085: aliased join with renamed columns'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT j.xk,j.xaid,j.xbid FROM (a FULL JOIN b USING (k)) AS j(xk,xaid,xv,xtxt,xflag,xbid,yv,ytxt,yflag);
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT j.xk,j.xaid,j.xbid FROM (a FULL JOIN b USING (k)) AS j(xk,xaid,xv,xtxt,xflag,xbid,yv,ytxt,yflag);
SELECT '085' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 086. NULL-sensitive projection stays above union
\echo 'CASE 086: NULL-sensitive projection stays above union'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid,b.id AS bid,coalesce(a.v,99)+coalesce(b.v,88) AS n, CASE WHEN a.k IS NULL THEN 'missing-or-null' ELSE a.txt END AS label FROM a FULL JOIN b ON a.k=b.k;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid,b.id AS bid,coalesce(a.v,99)+coalesce(b.v,88) AS n, CASE WHEN a.k IS NULL THEN 'missing-or-null' ELSE a.txt END AS label FROM a FULL JOIN b ON a.k=b.k;
SELECT '086' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 087. named composite table rows and field extraction
\echo 'CASE 087: named composite table rows and field extraction'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a AS ar,b AS br,(a).k AS ak,(b).k AS bk FROM a FULL JOIN b ON a.k=b.k;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a AS ar,b AS br,(a).k AS ak,(b).k AS bk FROM a FULL JOIN b ON a.k=b.k;
SELECT '087' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 088. system columns survive remapping
\echo 'CASE 088: system columns survive remapping'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.ctid AS actid,b.ctid AS bctid,a.tableoid AS aoid,b.tableoid AS boid FROM a FULL JOIN b ON a.k=b.k;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.ctid AS actid,b.ctid AS bctid,a.tableoid AS aoid,b.tableoid AS boid FROM a FULL JOIN b ON a.k=b.k;
SELECT '088' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 089. no referenced columns; multiplicity only
\echo 'CASE 089: no referenced columns; multiplicity only'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT 1 AS n FROM a FULL JOIN b ON a.k=b.k;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT 1 AS n FROM a FULL JOIN b ON a.k=b.k;
SELECT '089' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 090. count star dummy projection
\echo 'CASE 090: count star dummy projection'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT count(*) AS n FROM a FULL JOIN b ON a.k=b.k;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT count(*) AS n FROM a FULL JOIN b ON a.k=b.k;
SELECT '090' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 091. count star false join
\echo 'CASE 091: count star false join'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT count(*) AS n FROM a FULL JOIN b ON false;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT count(*) AS n FROM a FULL JOIN b ON false;
SELECT '091' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 092. grouping, aggregates, FILTER and HAVING above union
\echo 'CASE 092: grouping, aggregates, FILTER and HAVING above union'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT coalesce(a.k,b.k) AS k,count(*) AS n,count(a.v) AS na,sum(b.v) AS sb,count(*) FILTER (WHERE a.id IS NULL) AS nu FROM a FULL JOIN b ON a.k=b.k GROUP BY coalesce(a.k,b.k) HAVING count(*) >= 2;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT coalesce(a.k,b.k) AS k,count(*) AS n,count(a.v) AS na,sum(b.v) AS sb,count(*) FILTER (WHERE a.id IS NULL) AS nu FROM a FULL JOIN b ON a.k=b.k GROUP BY coalesce(a.k,b.k) HAVING count(*) >= 2;
SELECT '092' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 093. GROUPING SETS and RTE_GROUP remapping
\echo 'CASE 093: GROUPING SETS and RTE_GROUP remapping'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.k AS ak,b.k AS bk,GROUPING(a.k,b.k) AS g,count(*) AS n FROM a FULL JOIN b ON a.k=b.k GROUP BY GROUPING SETS ((a.k,b.k),(a.k),());
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT a.k AS ak,b.k AS bk,GROUPING(a.k,b.k) AS g,count(*) AS n FROM a FULL JOIN b ON a.k=b.k GROUP BY GROUPING SETS ((a.k,b.k),(a.k),());
CREATE TEMP TABLE actual AS
SELECT a.k AS ak,b.k AS bk,GROUPING(a.k,b.k) AS g,count(*) AS n FROM a FULL JOIN b ON a.k=b.k GROUP BY GROUPING SETS ((a.k,b.k),(a.k),());
SELECT '093' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 094. DISTINCT above full join
\echo 'CASE 094: DISTINCT above full join'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT DISTINCT a.k AS ak,b.k AS bk FROM a FULL JOIN b ON a.k=b.k;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT DISTINCT a.k AS ak,b.k AS bk FROM a FULL JOIN b ON a.k=b.k;
SELECT '094' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 095. ORDER BY LIMIT OFFSET above union
\echo 'CASE 095: ORDER BY LIMIT OFFSET above union'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid,b.id AS bid,a.k AS ak,b.k AS bk FROM a FULL JOIN b ON a.k=b.k ORDER BY aid NULLS FIRST,bid NULLS FIRST,ak,bk LIMIT 9 OFFSET 3;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid,b.id AS bid,a.k AS ak,b.k AS bk FROM a FULL JOIN b ON a.k=b.k ORDER BY aid NULLS FIRST,bid NULLS FIRST,ak,bk LIMIT 9 OFFSET 3;
SELECT '095' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 096. LIMIT WITH TIES above union
\echo 'CASE 096: LIMIT WITH TIES above union'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.k AS ak,b.k AS bk FROM a FULL JOIN b ON a.k=b.k ORDER BY coalesce(a.k,b.k) NULLS FIRST FETCH FIRST 3 ROWS WITH TIES;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.k AS ak,b.k AS bk FROM a FULL JOIN b ON a.k=b.k ORDER BY coalesce(a.k,b.k) NULLS FIRST FETCH FIRST 3 ROWS WITH TIES;
SELECT '096' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 097. window aggregates above union
\echo 'CASE 097: window aggregates above union'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.k AS ak,b.k AS bk,count(*) OVER (PARTITION BY coalesce(a.k,b.k)) AS n,dense_rank() OVER (ORDER BY coalesce(a.k,b.k) NULLS FIRST) AS r FROM a FULL JOIN b ON a.k=b.k;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.k AS ak,b.k AS bk,count(*) OVER (PARTITION BY coalesce(a.k,b.k)) AS n,dense_rank() OVER (ORDER BY coalesce(a.k,b.k) NULLS FIRST) AS r FROM a FULL JOIN b ON a.k=b.k;
SELECT '097' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 098. set returning projection above union
\echo 'CASE 098: set returning projection above union'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.k AS ak,b.k AS bk,generate_series(1,2) AS n FROM a FULL JOIN b ON a.k=b.k;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.k AS ak,b.k AS bk,generate_series(1,2) AS n FROM a FULL JOIN b ON a.k=b.k;
SELECT '098' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 099. correlated scalar subquery in target
\echo 'CASE 099: correlated scalar subquery in target'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid,b.id AS bid,(SELECT count(*) FROM c WHERE c.k = coalesce(a.k,b.k)) AS n FROM a FULL JOIN b ON a.k=b.k;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid,b.id AS bid,(SELECT count(*) FROM c WHERE c.k = coalesce(a.k,b.k)) AS n FROM a FULL JOIN b ON a.k=b.k;
SELECT '099' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 100. full join inside correlated scalar subquery
\echo 'CASE 100: full join inside correlated scalar subquery'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT c.id,(SELECT count(*) FROM a FULL JOIN b ON a.k=b.k AND a.k=c.k) AS n FROM c;
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT c.id,(SELECT count(*) FROM a FULL JOIN b ON a.k=b.k AND a.k=c.k) AS n FROM c;
CREATE TEMP TABLE actual AS
SELECT c.id,(SELECT count(*) FROM a FULL JOIN b ON a.k=b.k AND a.k=c.k) AS n FROM c;
SELECT '100' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 101. full join inside LATERAL query with outer parameters
\echo 'CASE 101: full join inside LATERAL query with outer parameters'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT c.id,s.n FROM c CROSS JOIN LATERAL (SELECT count(*) AS n FROM a FULL JOIN b ON a.k=b.k AND b.k=c.k) s;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT c.id,s.n FROM c CROSS JOIN LATERAL (SELECT count(*) AS n FROM a FULL JOIN b ON a.k=b.k AND b.k=c.k) s;
SELECT '101' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 102. two levels of enclosing query references
\echo 'CASE 102: two levels of enclosing query references'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT c.id,(SELECT (SELECT count(*) FROM a FULL JOIN b ON a.k=b.k AND a.k=c.k AND b.id>=d.id) FROM c d WHERE d.id=101) AS n FROM c;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT c.id,(SELECT (SELECT count(*) FROM a FULL JOIN b ON a.k=b.k AND a.k=c.k AND b.id>=d.id) FROM c d WHERE d.id=101) AS n FROM c;
SELECT '102' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 103. full join below inner join
\echo 'CASE 103: full join below inner join'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid,b.id AS bid,c.id AS cid FROM (a FULL JOIN b ON a.k=b.k) JOIN c ON c.k=coalesce(a.k,b.k);
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT a.id AS aid,b.id AS bid,c.id AS cid FROM (a FULL JOIN b ON a.k=b.k) JOIN c ON c.k=coalesce(a.k,b.k);
CREATE TEMP TABLE actual AS
SELECT a.id AS aid,b.id AS bid,c.id AS cid FROM (a FULL JOIN b ON a.k=b.k) JOIN c ON c.k=coalesce(a.k,b.k);
SELECT '103' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 104. full join on nullable side of left join; ancestor nullingrels
\echo 'CASE 104: full join on nullable side of left join; ancestor nullingrels'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT c.id AS cid,a.id AS aid,b.id AS bid FROM c LEFT JOIN (a FULL JOIN b ON a.k=b.k) ON c.k=coalesce(a.k,b.k);
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT c.id AS cid,a.id AS aid,b.id AS bid FROM c LEFT JOIN (a FULL JOIN b ON a.k=b.k) ON c.k=coalesce(a.k,b.k);
CREATE TEMP TABLE actual AS
SELECT c.id AS cid,a.id AS aid,b.id AS bid FROM c LEFT JOIN (a FULL JOIN b ON a.k=b.k) ON c.k=coalesce(a.k,b.k);
SELECT '104' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 105. full join on preserved side of left join
\echo 'CASE 105: full join on preserved side of left join'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid,b.id AS bid,c.id AS cid FROM (a FULL JOIN b ON a.k=b.k) LEFT JOIN c ON c.k=coalesce(a.k,b.k);
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid,b.id AS bid,c.id AS cid FROM (a FULL JOIN b ON a.k=b.k) LEFT JOIN c ON c.k=coalesce(a.k,b.k);
SELECT '105' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 106. full join under right join
\echo 'CASE 106: full join under right join'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid,b.id AS bid,c.id AS cid FROM (a FULL JOIN b ON a.k=b.k) RIGHT JOIN c ON c.k=coalesce(a.k,b.k);
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid,b.id AS bid,c.id AS cid FROM (a FULL JOIN b ON a.k=b.k) RIGHT JOIN c ON c.k=coalesce(a.k,b.k);
SELECT '106' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 107. nested FULL joins left associative
\echo 'CASE 107: nested FULL joins left associative'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid,b.id AS bid,c.id AS cid FROM (a FULL JOIN b ON a.k=b.k) FULL JOIN c ON c.k=coalesce(a.k,b.k);
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT a.id AS aid,b.id AS bid,c.id AS cid FROM (a FULL JOIN b ON a.k=b.k) FULL JOIN c ON c.k=coalesce(a.k,b.k);
CREATE TEMP TABLE actual AS
SELECT a.id AS aid,b.id AS bid,c.id AS cid FROM (a FULL JOIN b ON a.k=b.k) FULL JOIN c ON c.k=coalesce(a.k,b.k);
SELECT '107' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 108. nested FULL joins right associative
\echo 'CASE 108: nested FULL joins right associative'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid,b.id AS bid,c.id AS cid FROM a FULL JOIN (b FULL JOIN c ON b.k=c.k) ON a.k=coalesce(b.k,c.k);
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid,b.id AS bid,c.id AS cid FROM a FULL JOIN (b FULL JOIN c ON b.k=c.k) ON a.k=coalesce(b.k,c.k);
SELECT '108' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 109. FULL join input contains LEFT join
\echo 'CASE 109: FULL join input contains LEFT join'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid,b.id AS bid,c.id AS cid FROM (a LEFT JOIN c ON a.k=c.k) FULL JOIN b ON a.k=b.k;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid,b.id AS bid,c.id AS cid FROM (a LEFT JOIN c ON a.k=c.k) FULL JOIN b ON a.k=b.k;
SELECT '109' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 110. FULL join input contains RIGHT join
\echo 'CASE 110: FULL join input contains RIGHT join'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid,b.id AS bid,c.id AS cid FROM a FULL JOIN (b RIGHT JOIN c ON b.k=c.k) ON a.k=c.k;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid,b.id AS bid,c.id AS cid FROM a FULL JOIN (b RIGHT JOIN c ON b.k=c.k) ON a.k=c.k;
SELECT '110' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 111. sibling FULL joins in a join tree
\echo 'CASE 111: sibling FULL joins in a join tree'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid,b.id AS bid,d.id AS did,e.id AS eid FROM (a FULL JOIN b ON a.k=b.k) CROSS JOIN (a d FULL JOIN b e ON d.k=e.k) WHERE coalesce(a.k,b.k)=coalesce(d.k,e.k);
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid,b.id AS bid,d.id AS did,e.id AS eid FROM (a FULL JOIN b ON a.k=b.k) CROSS JOIN (a d FULL JOIN b e ON d.k=e.k) WHERE coalesce(a.k,b.k)=coalesce(d.k,e.k);
SELECT '111' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 112. derived UNION ALL input
\echo 'CASE 112: derived UNION ALL input'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT x.id AS aid,b.id AS bid FROM (SELECT id,k FROM a UNION ALL SELECT id,k FROM a WHERE k IS NULL) x FULL JOIN b ON x.k=b.k;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT x.id AS aid,b.id AS bid FROM (SELECT id,k FROM a UNION ALL SELECT id,k FROM a WHERE k IS NULL) x FULL JOIN b ON x.k=b.k;
SELECT '112' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 113. filtered subquery input
\echo 'CASE 113: filtered subquery input'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT x.id AS aid,b.id AS bid FROM (SELECT * FROM a WHERE v>10) x FULL JOIN b ON x.k=b.k;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT x.id AS aid,b.id AS bid FROM (SELECT * FROM a WHERE v>10) x FULL JOIN b ON x.k=b.k;
SELECT '113' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 114. GUARD: aggregate subquery input
\echo 'CASE 114: GUARD: aggregate subquery input'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT x.k,b.id,x.n FROM (SELECT k,count(*) AS n FROM a GROUP BY k) x FULL JOIN b ON x.k=b.k;
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT x.k,b.id,x.n FROM (SELECT k,count(*) AS n FROM a GROUP BY k) x FULL JOIN b ON x.k=b.k;
CREATE TEMP TABLE actual AS
SELECT x.k,b.id,x.n FROM (SELECT k,count(*) AS n FROM a GROUP BY k) x FULL JOIN b ON x.k=b.k;
SELECT '114' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 115. VALUES inputs
\echo 'CASE 115: VALUES inputs'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT x.k AS xk,y.k AS yk FROM (VALUES (1),(1),(NULL::int),(2)) x(k) FULL JOIN (VALUES (1),(NULL::int),(3),(3)) y(k) ON x.k=y.k;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT x.k AS xk,y.k AS yk FROM (VALUES (1),(1),(NULL::int),(2)) x(k) FULL JOIN (VALUES (1),(NULL::int),(3),(3)) y(k) ON x.k=y.k;
SELECT '115' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 116. empty left input
\echo 'CASE 116: empty left input'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT e.id AS aid,b.id AS bid FROM empty_input e FULL JOIN b ON e.k=b.k;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT e.id AS aid,b.id AS bid FROM empty_input e FULL JOIN b ON e.k=b.k;
SELECT '116' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 117. empty right input
\echo 'CASE 117: empty right input'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid,e.id AS bid FROM a FULL JOIN empty_input e ON a.k=e.k;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid,e.id AS bid FROM a FULL JOIN empty_input e ON a.k=e.k;
SELECT '117' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 118. both inputs empty
\echo 'CASE 118: both inputs empty'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT e.id AS aid,f.id AS bid FROM empty_input e FULL JOIN empty_input f ON e.k=f.k;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT e.id AS aid,f.id AS bid FROM empty_input e FULL JOIN empty_input f ON e.k=f.k;
SELECT '118' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 119. empty left with constant TRUE
\echo 'CASE 119: empty left with constant TRUE'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT e.id AS aid,b.id AS bid FROM empty_input e FULL JOIN b ON true;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT e.id AS aid,b.id AS bid FROM empty_input e FULL JOIN b ON true;
SELECT '119' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 120. empty right with constant TRUE
\echo 'CASE 120: empty right with constant TRUE'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid,e.id AS bid FROM a FULL JOIN empty_input e ON true;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid,e.id AS bid FROM a FULL JOIN empty_input e ON true;
SELECT '120' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

CREATE TABLE pa (LIKE a) PARTITION BY RANGE (k);
CREATE TABLE pa_low PARTITION OF pa FOR VALUES FROM (MINVALUE) TO (3);
CREATE TABLE pa_high PARTITION OF pa FOR VALUES FROM (3) TO (MAXVALUE);
CREATE TABLE pa_null PARTITION OF pa DEFAULT;
INSERT INTO pa SELECT * FROM a;
CREATE TABLE pb (LIKE b) PARTITION BY RANGE (k);
CREATE TABLE pb_low PARTITION OF pb FOR VALUES FROM (MINVALUE) TO (3);
CREATE TABLE pb_high PARTITION OF pb FOR VALUES FROM (3) TO (MAXVALUE);
CREATE TABLE pb_null PARTITION OF pb DEFAULT;
INSERT INTO pb SELECT * FROM b;
ANALYZE pa;
ANALYZE pb;
CREATE TABLE ia (LIKE a);
CREATE TABLE ia_child () INHERITS (ia);
INSERT INTO ia SELECT * FROM a WHERE id<=3;
INSERT INTO ia_child SELECT * FROM a WHERE id>3 OR id IS NULL;

-- 121. partitioned left input
\echo 'CASE 121: partitioned left input'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT pa.id AS aid,b.id AS bid,pa.tableoid AS source_table_oid FROM pa FULL JOIN b ON pa.k=b.k;
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT pa.id AS aid,b.id AS bid,pa.tableoid AS source_table_oid FROM pa FULL JOIN b ON pa.k=b.k;
CREATE TEMP TABLE actual AS
SELECT pa.id AS aid,b.id AS bid,pa.tableoid AS source_table_oid FROM pa FULL JOIN b ON pa.k=b.k;
SELECT '121' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 122. partitioned both sides; partitionwise join enabled
\echo 'CASE 122: partitioned both sides; partitionwise join enabled'
SET LOCAL enable_partitionwise_join = on;
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT pa.id AS aid,pb.id AS bid FROM pa FULL JOIN pb ON pa.k=pb.k;
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT pa.id AS aid,pb.id AS bid FROM pa FULL JOIN pb ON pa.k=pb.k;
CREATE TEMP TABLE actual AS
SELECT pa.id AS aid,pb.id AS bid FROM pa FULL JOIN pb ON pa.k=pb.k;
SELECT '122' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;
SET LOCAL enable_partitionwise_join = off;

-- 123. partition pruning under WHERE
\echo 'CASE 123: partition pruning under WHERE'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT pa.id AS aid,pb.id AS bid FROM pa FULL JOIN pb ON pa.k=pb.k WHERE pa.k>=3;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT pa.id AS aid,pb.id AS bid FROM pa FULL JOIN pb ON pa.k=pb.k WHERE pa.k>=3;
SELECT '123' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 124. inheritance input and tableoid
\echo 'CASE 124: inheritance input and tableoid'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT ia.id AS aid,b.id AS bid,ia.tableoid AS source_table_oid FROM ia FULL JOIN b ON ia.k=b.k;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT ia.id AS aid,b.id AS bid,ia.tableoid AS source_table_oid FROM ia FULL JOIN b ON ia.k=b.k;
SELECT '124' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 125. ONLY input
\echo 'CASE 125: ONLY input'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT ia.id AS aid,b.id AS bid FROM ONLY ia FULL JOIN b ON ia.k=b.k;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT ia.id AS aid,b.id AS bid FROM ONLY ia FULL JOIN b ON ia.k=b.k;
SELECT '125' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

CREATE DOMAIN dkey AS int NOT NULL CHECK (VALUE >= 0);
CREATE TABLE typed_a(id int, k dkey, n numeric, f float8, ts timestamp, tz timestamptz,
                     arr int[], js jsonb, u uuid, dropped text);
ALTER TABLE typed_a DROP COLUMN dropped;
CREATE TABLE typed_b(LIKE typed_a);
INSERT INTO typed_a VALUES
 (1,1,'NaN','NaN','2020-01-01','2020-01-01 UTC',ARRAY[1,NULL],'{"k":1}','00000000-0000-0000-0000-000000000001'),
 (2,2,'Infinity','Infinity','infinity','infinity',ARRAY[2,3],'{"k":2}','00000000-0000-0000-0000-000000000002'),
 (3,3,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO typed_b VALUES
 (11,1,'NaN','NaN','2020-01-01','2019-12-31 19:00-05',ARRAY[1,NULL],'{"k":1}','00000000-0000-0000-0000-000000000001'),
 (12,4,'-Infinity','-Infinity','-infinity','-infinity',ARRAY[3,4],'{"k":4}','00000000-0000-0000-0000-000000000004'),
 (13,5,NULL,NULL,NULL,NULL,NULL,NULL,NULL);

-- 126. NOT NULL domain and typed NULL padding
\echo 'CASE 126: NOT NULL domain and typed NULL padding'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT x.id AS aid,y.id AS bid,x.k AS ak,y.k AS bk,x.k AS av,y.k AS bv FROM typed_a x FULL JOIN typed_b y ON x.k=y.k;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT x.id AS aid,y.id AS bid,x.k AS ak,y.k AS bk,x.k AS av,y.k AS bv FROM typed_a x FULL JOIN typed_b y ON x.k=y.k;
SELECT '126' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 127. numeric NaN and Infinity
\echo 'CASE 127: numeric NaN and Infinity'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT x.id AS aid,y.id AS bid,x.k AS ak,y.k AS bk,x.n AS av,y.n AS bv FROM typed_a x FULL JOIN typed_b y ON x.n=y.n;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT x.id AS aid,y.id AS bid,x.k AS ak,y.k AS bk,x.n AS av,y.n AS bv FROM typed_a x FULL JOIN typed_b y ON x.n=y.n;
SELECT '127' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 128. float NaN and Infinity
\echo 'CASE 128: float NaN and Infinity'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT x.id AS aid,y.id AS bid,x.k AS ak,y.k AS bk,x.f AS av,y.f AS bv FROM typed_a x FULL JOIN typed_b y ON x.f=y.f;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT x.id AS aid,y.id AS bid,x.k AS ak,y.k AS bk,x.f AS av,y.f AS bv FROM typed_a x FULL JOIN typed_b y ON x.f=y.f;
SELECT '128' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 129. timestamp
\echo 'CASE 129: timestamp'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT x.id AS aid,y.id AS bid,x.k AS ak,y.k AS bk,x.ts AS av,y.ts AS bv FROM typed_a x FULL JOIN typed_b y ON x.ts=y.ts;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT x.id AS aid,y.id AS bid,x.k AS ak,y.k AS bk,x.ts AS av,y.ts AS bv FROM typed_a x FULL JOIN typed_b y ON x.ts=y.ts;
SELECT '129' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 130. timestamptz
\echo 'CASE 130: timestamptz'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT x.id AS aid,y.id AS bid,x.k AS ak,y.k AS bk,x.tz AS av,y.tz AS bv FROM typed_a x FULL JOIN typed_b y ON x.tz=y.tz;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT x.id AS aid,y.id AS bid,x.k AS ak,y.k AS bk,x.tz AS av,y.tz AS bv FROM typed_a x FULL JOIN typed_b y ON x.tz=y.tz;
SELECT '130' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 131. array equality and NULL elements
\echo 'CASE 131: array equality and NULL elements'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT x.id AS aid,y.id AS bid,x.k AS ak,y.k AS bk,x.arr AS av,y.arr AS bv FROM typed_a x FULL JOIN typed_b y ON x.arr=y.arr;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT x.id AS aid,y.id AS bid,x.k AS ak,y.k AS bk,x.arr AS av,y.arr AS bv FROM typed_a x FULL JOIN typed_b y ON x.arr=y.arr;
SELECT '131' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 132. jsonb equality
\echo 'CASE 132: jsonb equality'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT x.id AS aid,y.id AS bid,x.k AS ak,y.k AS bk,x.js AS av,y.js AS bv FROM typed_a x FULL JOIN typed_b y ON x.js=y.js;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT x.id AS aid,y.id AS bid,x.k AS ak,y.k AS bk,x.js AS av,y.js AS bv FROM typed_a x FULL JOIN typed_b y ON x.js=y.js;
SELECT '132' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 133. uuid equality
\echo 'CASE 133: uuid equality'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT x.id AS aid,y.id AS bid,x.k AS ak,y.k AS bk,x.u AS av,y.u AS bv FROM typed_a x FULL JOIN typed_b y ON x.u=y.u;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT x.id AS aid,y.id AS bid,x.k AS ak,y.k AS bk,x.u AS av,y.u AS bv FROM typed_a x FULL JOIN typed_b y ON x.u=y.u;
SELECT '133' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 134. dropped column and whole row named composite
\echo 'CASE 134: dropped column and whole row named composite'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT x AS ar,y AS br FROM typed_a x FULL JOIN typed_b y ON x.k=y.k;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT x AS ar,y AS br FROM typed_a x FULL JOIN typed_b y ON x.k=y.k;
SELECT '134' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 135. json extraction in join condition
\echo 'CASE 135: json extraction in join condition'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT x.id AS aid,y.id AS bid FROM typed_a x FULL JOIN typed_b y ON (x.js->>'k')::int=(y.js->>'k')::int;
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT x.id AS aid,y.id AS bid FROM typed_a x FULL JOIN typed_b y ON (x.js->>'k')::int=(y.js->>'k')::int;
SELECT '135' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 136. hash join disabled; merge left and anti joins
\echo 'CASE 136: hash join disabled; merge left and anti joins'
SET LOCAL enable_hashjoin = off; SET LOCAL enable_mergejoin = on;
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k=b.k;
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k=b.k;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k=b.k;
SELECT '136' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;
SET LOCAL enable_hashjoin = on;

-- 137. merge join disabled; hash left and anti joins
\echo 'CASE 137: merge join disabled; hash left and anti joins'
SET LOCAL enable_mergejoin = off; SET LOCAL enable_hashjoin = on;
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k=b.k;
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k=b.k;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k=b.k;
SELECT '137' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;
SET LOCAL enable_mergejoin = on;

-- 138. nested loop only for rewritten non-equality joins
\echo 'CASE 138: nested loop only for rewritten non-equality joins'
SET LOCAL enable_hashjoin = off; SET LOCAL enable_mergejoin = off;
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a INNER JOIN b ON a.k<b.k
UNION ALL
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, NULL::int AS bid, NULL::int AS bk, NULL::numeric(12,2) AS bv, NULL::text AS btxt, NULL::boolean AS bflag
FROM a WHERE NOT EXISTS (SELECT 1 FROM b WHERE a.k<b.k)
UNION ALL
SELECT NULL::int AS aid, NULL::int AS ak, NULL::numeric(12,2) AS av, NULL::text AS atxt, NULL::boolean AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM b WHERE NOT EXISTS (SELECT 1 FROM a WHERE a.k<b.k);
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k<b.k;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k<b.k;
SELECT '138' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;
SET LOCAL enable_hashjoin = on; SET LOCAL enable_mergejoin = on;

-- 139. join collapse limits set to one
\echo 'CASE 139: join collapse limits set to one'
SET LOCAL join_collapse_limit = 1; SET LOCAL from_collapse_limit = 1;
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid,b.id AS bid,c.id AS cid FROM (a FULL JOIN b ON a.k=b.k) JOIN c ON c.k=coalesce(a.k,b.k);
SET LOCAL enable_full_join_rewrite = on;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid,b.id AS bid,c.id AS cid FROM (a FULL JOIN b ON a.k=b.k) JOIN c ON c.k=coalesce(a.k,b.k);
SELECT '139' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;
SET LOCAL join_collapse_limit = 8; SET LOCAL from_collapse_limit = 8;

-- 140. GUARD: volatile ON predicate
\echo 'CASE 140: GUARD: volatile ON predicate'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k=b.k AND random()>=0;
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k=b.k AND random()>=0;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k=b.k AND random()>=0;
SELECT '140' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 141. GUARD: volatile expression in input target
\echo 'CASE 141: GUARD: volatile expression in input target'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT x.id AS aid,b.id AS bid FROM (SELECT a.*,random() AS r FROM a) x FULL JOIN b ON x.k=b.k AND x.r>=0;
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT x.id AS aid,b.id AS bid FROM (SELECT a.*,random() AS r FROM a) x FULL JOIN b ON x.k=b.k AND x.r>=0;
CREATE TEMP TABLE actual AS
SELECT x.id AS aid,b.id AS bid FROM (SELECT a.*,random() AS r FROM a) x FULL JOIN b ON x.k=b.k AND x.r>=0;
SELECT '141' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 142. GUARD: volatile WHERE inside input subquery
\echo 'CASE 142: GUARD: volatile WHERE inside input subquery'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT x.id AS aid,b.id AS bid FROM (SELECT * FROM a WHERE random()>=0) x FULL JOIN b ON x.k=b.k;
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT x.id AS aid,b.id AS bid FROM (SELECT * FROM a WHERE random()>=0) x FULL JOIN b ON x.k=b.k;
CREATE TEMP TABLE actual AS
SELECT x.id AS aid,b.id AS bid FROM (SELECT * FROM a WHERE random()>=0) x FULL JOIN b ON x.k=b.k;
SELECT '142' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 143. GUARD: omitted volatile default argument
\echo 'CASE 143: GUARD: omitted volatile default argument'
CREATE SEQUENCE side_effect;
CREATE FUNCTION default_arg(x bigint DEFAULT nextval('side_effect')) RETURNS bigint LANGUAGE SQL STABLE AS 'SELECT x';
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k=b.k AND default_arg()>0;
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k=b.k AND default_arg()>0;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k=b.k AND default_arg()>0;
SELECT '143' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 144. GUARD: domain coercion may execute volatile CHECK
\echo 'CASE 144: GUARD: domain coercion may execute volatile CHECK'
CREATE DOMAIN checked_int AS int CHECK(nextval('side_effect')>0);
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k=b.k AND a.id::checked_int=b.id::checked_int;
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k=b.k AND a.id::checked_int=b.id::checked_int;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k=b.k AND a.id::checked_int=b.id::checked_int;
SELECT '144' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 145. GUARD: MATERIALIZED CTE reference
\echo 'CASE 145: GUARD: MATERIALIZED CTE reference'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
WITH x AS MATERIALIZED (SELECT * FROM a) SELECT x.id AS aid,b.id AS bid FROM x FULL JOIN b ON x.k=b.k;
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
WITH x AS MATERIALIZED (SELECT * FROM a) SELECT x.id AS aid,b.id AS bid FROM x FULL JOIN b ON x.k=b.k;
CREATE TEMP TABLE actual AS
WITH x AS MATERIALIZED (SELECT * FROM a) SELECT x.id AS aid,b.id AS bid FROM x FULL JOIN b ON x.k=b.k;
SELECT '145' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 146. GUARD: NOT MATERIALIZED CTE reference
\echo 'CASE 146: GUARD: NOT MATERIALIZED CTE reference'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
WITH x AS NOT MATERIALIZED (SELECT * FROM a) SELECT x.id AS aid,b.id AS bid FROM x FULL JOIN b ON x.k=b.k;
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
WITH x AS NOT MATERIALIZED (SELECT * FROM a) SELECT x.id AS aid,b.id AS bid FROM x FULL JOIN b ON x.k=b.k;
CREATE TEMP TABLE actual AS
WITH x AS NOT MATERIALIZED (SELECT * FROM a) SELECT x.id AS aid,b.id AS bid FROM x FULL JOIN b ON x.k=b.k;
SELECT '146' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 147. FULL JOIN inside a CTE definition
\echo 'CASE 147: FULL JOIN inside a CTE definition'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
WITH x AS MATERIALIZED (SELECT a.id AS aid,b.id AS bid FROM a FULL JOIN b ON a.k=b.k) SELECT * FROM x;
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
WITH x AS MATERIALIZED (SELECT a.id AS aid,b.id AS bid FROM a FULL JOIN b ON a.k=b.k) SELECT * FROM x;
CREATE TEMP TABLE actual AS
WITH x AS MATERIALIZED (SELECT a.id AS aid,b.id AS bid FROM a FULL JOIN b ON a.k=b.k) SELECT * FROM x;
SELECT '147' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 148. GUARD: LATERAL input
\echo 'CASE 148: GUARD: LATERAL input'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT x.id AS aid,b.id AS bid FROM (SELECT a.id,a.k,c.id AS cid FROM a LEFT JOIN LATERAL (SELECT c.id FROM c WHERE c.k=a.k OFFSET 0) c ON true) x FULL JOIN b ON x.k=b.k;
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT x.id AS aid,b.id AS bid FROM (SELECT a.id,a.k,c.id AS cid FROM a LEFT JOIN LATERAL (SELECT c.id FROM c WHERE c.k=a.k OFFSET 0) c ON true) x FULL JOIN b ON x.k=b.k;
CREATE TEMP TABLE actual AS
SELECT x.id AS aid,b.id AS bid FROM (SELECT a.id,a.k,c.id AS cid FROM a LEFT JOIN LATERAL (SELECT c.id FROM c WHERE c.k=a.k OFFSET 0) c ON true) x FULL JOIN b ON x.k=b.k;
SELECT '148' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 149. GUARD: input LIMIT
\echo 'CASE 149: GUARD: input LIMIT'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT x.id AS aid,b.id AS bid FROM (SELECT * FROM a ORDER BY id NULLS FIRST,k,v,txt,flag LIMIT 5) x FULL JOIN b ON x.k=b.k;
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT x.id AS aid,b.id AS bid FROM (SELECT * FROM a ORDER BY id NULLS FIRST,k,v,txt,flag LIMIT 5) x FULL JOIN b ON x.k=b.k;
CREATE TEMP TABLE actual AS
SELECT x.id AS aid,b.id AS bid FROM (SELECT * FROM a ORDER BY id NULLS FIRST,k,v,txt,flag LIMIT 5) x FULL JOIN b ON x.k=b.k;
SELECT '149' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 150. GUARD: input OFFSET
\echo 'CASE 150: GUARD: input OFFSET'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT x.id AS aid,b.id AS bid FROM (SELECT * FROM a OFFSET 0) x FULL JOIN b ON x.k=b.k;
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT x.id AS aid,b.id AS bid FROM (SELECT * FROM a OFFSET 0) x FULL JOIN b ON x.k=b.k;
CREATE TEMP TABLE actual AS
SELECT x.id AS aid,b.id AS bid FROM (SELECT * FROM a OFFSET 0) x FULL JOIN b ON x.k=b.k;
SELECT '150' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 151. GUARD: input DISTINCT
\echo 'CASE 151: GUARD: input DISTINCT'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT x.id AS aid,b.id AS bid FROM (SELECT DISTINCT * FROM a) x FULL JOIN b ON x.k=b.k;
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT x.id AS aid,b.id AS bid FROM (SELECT DISTINCT * FROM a) x FULL JOIN b ON x.k=b.k;
CREATE TEMP TABLE actual AS
SELECT x.id AS aid,b.id AS bid FROM (SELECT DISTINCT * FROM a) x FULL JOIN b ON x.k=b.k;
SELECT '151' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 152. GUARD: order-sensitive aggregate in input
\echo 'CASE 152: GUARD: order-sensitive aggregate in input'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT x.k,b.id,x.ids FROM (SELECT k,array_agg(id) AS ids FROM a GROUP BY k) x FULL JOIN b ON x.k=b.k;
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT x.k,b.id,x.ids FROM (SELECT k,array_agg(id) AS ids FROM a GROUP BY k) x FULL JOIN b ON x.k=b.k;
CREATE TEMP TABLE actual AS
SELECT x.k,b.id,x.ids FROM (SELECT k,array_agg(id) AS ids FROM a GROUP BY k) x FULL JOIN b ON x.k=b.k;
SELECT '152' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 153. GUARD: input UNION DISTINCT
\echo 'CASE 153: GUARD: input UNION DISTINCT'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT x.k,b.id FROM (SELECT k FROM a UNION SELECT k FROM c) x FULL JOIN b ON x.k=b.k;
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT x.k,b.id FROM (SELECT k FROM a UNION SELECT k FROM c) x FULL JOIN b ON x.k=b.k;
CREATE TEMP TABLE actual AS
SELECT x.k,b.id FROM (SELECT k FROM a UNION SELECT k FROM c) x FULL JOIN b ON x.k=b.k;
SELECT '153' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 154. GUARD: input window function
\echo 'CASE 154: GUARD: input window function'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT x.id AS aid,b.id AS bid,x.n FROM (SELECT a.*,count(*) OVER () AS n FROM a) x FULL JOIN b ON x.k=b.k;
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT x.id AS aid,b.id AS bid,x.n FROM (SELECT a.*,count(*) OVER () AS n FROM a) x FULL JOIN b ON x.k=b.k;
CREATE TEMP TABLE actual AS
SELECT x.id AS aid,b.id AS bid,x.n FROM (SELECT a.*,count(*) OVER () AS n FROM a) x FULL JOIN b ON x.k=b.k;
SELECT '154' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 155. GUARD: input set-returning target
\echo 'CASE 155: GUARD: input set-returning target'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT x.id AS aid,b.id AS bid,x.n FROM (SELECT a.*,generate_series(1,2) AS n FROM a) x FULL JOIN b ON x.k=b.k;
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT x.id AS aid,b.id AS bid,x.n FROM (SELECT a.*,generate_series(1,2) AS n FROM a) x FULL JOIN b ON x.k=b.k;
CREATE TEMP TABLE actual AS
SELECT x.id AS aid,b.id AS bid,x.n FROM (SELECT a.*,generate_series(1,2) AS n FROM a) x FULL JOIN b ON x.k=b.k;
SELECT '155' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 156. GUARD: function RTE
\echo 'CASE 156: GUARD: function RTE'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT x.k,b.id FROM generate_series(1,5) x(k) FULL JOIN b ON x.k=b.k;
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT x.k,b.id FROM generate_series(1,5) x(k) FULL JOIN b ON x.k=b.k;
CREATE TEMP TABLE actual AS
SELECT x.k,b.id FROM generate_series(1,5) x(k) FULL JOIN b ON x.k=b.k;
SELECT '156' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 157. GUARD: TABLESAMPLE even with REPEATABLE
\echo 'CASE 157: GUARD: TABLESAMPLE even with REPEATABLE'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid,b.id AS bid FROM a TABLESAMPLE SYSTEM (100) REPEATABLE (1) FULL JOIN b ON a.k=b.k;
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT a.id AS aid,b.id AS bid FROM a TABLESAMPLE SYSTEM (100) REPEATABLE (1) FULL JOIN b ON a.k=b.k;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid,b.id AS bid FROM a TABLESAMPLE SYSTEM (100) REPEATABLE (1) FULL JOIN b ON a.k=b.k;
SELECT '157' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 158. GUARD: locked input subquery
\echo 'CASE 158: GUARD: locked input subquery'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT x.id AS aid,b.id AS bid FROM (SELECT * FROM a FOR SHARE) x FULL JOIN b ON x.k=b.k;
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT x.id AS aid,b.id AS bid FROM (SELECT * FROM a FOR SHARE) x FULL JOIN b ON x.k=b.k;
CREATE TEMP TABLE actual AS
SELECT x.id AS aid,b.id AS bid FROM (SELECT * FROM a FOR SHARE) x FULL JOIN b ON x.k=b.k;
SELECT '158' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 159. GUARD: security barrier view
\echo 'CASE 159: GUARD: security barrier view'
CREATE VIEW secured_a WITH (security_barrier=true) AS SELECT * FROM a WHERE v>=0;
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT x.id AS aid,b.id AS bid FROM secured_a x FULL JOIN b ON x.k=b.k;
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT x.id AS aid,b.id AS bid FROM secured_a x FULL JOIN b ON x.k=b.k;
CREATE TEMP TABLE actual AS
SELECT x.id AS aid,b.id AS bid FROM secured_a x FULL JOIN b ON x.k=b.k;
SELECT '159' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 160. GUARD: anonymous whole-row join alias
\echo 'CASE 160: GUARD: anonymous whole-row join alias'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT row_to_json(j)::jsonb AS jr FROM (a FULL JOIN b USING (k)) j;
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT row_to_json(j)::jsonb AS jr FROM (a FULL JOIN b USING (k)) j;
CREATE TEMP TABLE actual AS
SELECT row_to_json(j)::jsonb AS jr FROM (a FULL JOIN b USING (k)) j;
SELECT '160' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 161. GUARD: anonymous whole-row join alias nulled by parent
\echo 'CASE 161: GUARD: anonymous whole-row join alias nulled by parent'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT c.id,row_to_json(j)::jsonb AS jr FROM c LEFT JOIN (a FULL JOIN b USING (k)) j ON j.k=c.k;
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT c.id,row_to_json(j)::jsonb AS jr FROM c LEFT JOIN (a FULL JOIN b USING (k)) j ON j.k=c.k;
CREATE TEMP TABLE actual AS
SELECT c.id,row_to_json(j)::jsonb AS jr FROM c LEFT JOIN (a FULL JOIN b USING (k)) j ON j.k=c.k;
SELECT '161' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- Sequence calls in ON must not be doubled. Same query, same unchanged plan.
\echo 'SIDE EFFECT: volatile ON must retain call count'
SET LOCAL enable_full_join_rewrite = off;
ALTER SEQUENCE side_effect RESTART WITH 1;
CREATE TEMP TABLE expected AS SELECT a.id AS aid,b.id AS bid FROM a FULL JOIN b
 ON a.k=b.k AND nextval('side_effect')>0;
CREATE TEMP TABLE expected_calls AS SELECT last_value,is_called FROM side_effect;
SET LOCAL enable_full_join_rewrite = on;
ALTER SEQUENCE side_effect RESTART WITH 1;
CREATE TEMP TABLE actual AS SELECT a.id AS aid,b.id AS bid FROM a FULL JOIN b
 ON a.k=b.k AND nextval('side_effect')>0;
SELECT 1 / ((count(*)=0)::int) AS pass FROM (
 (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual) UNION ALL
 (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) d;
SELECT 1 / ((e.last_value=s.last_value AND e.is_called=s.is_called)::int) AS pass
 FROM expected_calls e CROSS JOIN side_effect s;
DROP TABLE expected,actual,expected_calls;

-- Defaults are not expanded yet at the rewrite point.
\echo 'SIDE EFFECT: omitted volatile default must retain call count'
SET LOCAL enable_full_join_rewrite = off;
ALTER SEQUENCE side_effect RESTART WITH 1;
CREATE TEMP TABLE expected AS SELECT a.id AS aid,b.id AS bid FROM a FULL JOIN b
 ON a.k=b.k AND default_arg()>0;
CREATE TEMP TABLE expected_calls AS SELECT last_value,is_called FROM side_effect;
SET LOCAL enable_full_join_rewrite = on;
ALTER SEQUENCE side_effect RESTART WITH 1;
CREATE TEMP TABLE actual AS SELECT a.id AS aid,b.id AS bid FROM a FULL JOIN b
 ON a.k=b.k AND default_arg()>0;
SELECT 1 / ((count(*)=0)::int) AS pass FROM (
 (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual) UNION ALL
 (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) d;
SELECT 1 / ((e.last_value=s.last_value AND e.is_called=s.is_called)::int) AS pass
 FROM expected_calls e CROSS JOIN side_effect s;
DROP TABLE expected,actual,expected_calls;

-- Volatile output is outside the duplicated subtree, once per output row.
\echo 'SIDE EFFECT: volatile target remains above UNION ALL'
SET LOCAL enable_full_join_rewrite = off;
ALTER SEQUENCE side_effect RESTART WITH 1;
CREATE TEMP TABLE expected AS SELECT nextval('side_effect') AS n
 FROM a FULL JOIN b ON a.k=b.k;
SET LOCAL enable_full_join_rewrite = on;
ALTER SEQUENCE side_effect RESTART WITH 1;
EXPLAIN (VERBOSE,COSTS OFF) SELECT nextval('side_effect') AS n
 FROM a FULL JOIN b ON a.k=b.k;
CREATE TEMP TABLE actual AS SELECT nextval('side_effect') AS n
 FROM a FULL JOIN b ON a.k=b.k;
SELECT 1 / ((count(*)=0)::int) AS pass FROM (
 (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual) UNION ALL
 (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) d;
DROP TABLE expected,actual;

-- 162. volatile WHERE above full join retains result bag
\echo 'CASE 162: volatile WHERE above full join retains result bag'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k=b.k
WHERE random()>=0;
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k=b.k
WHERE random()>=0;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid, a.k AS ak, a.v AS av, a.txt AS atxt, a.flag AS aflag, b.id AS bid, b.k AS bk, b.v AS bv, b.txt AS btxt, b.flag AS bflag
FROM a FULL JOIN b ON a.k=b.k
WHERE random()>=0;
SELECT '162' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 163. GUARD: recursive statement
\echo 'CASE 163: GUARD: recursive statement'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
WITH RECURSIVE r(k) AS (VALUES (1) UNION ALL SELECT k+1 FROM r WHERE k<2) SELECT a.id AS aid,b.id AS bid FROM a FULL JOIN b ON a.k=b.k WHERE coalesce(a.k,b.k) IN (SELECT k FROM r);
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
WITH RECURSIVE r(k) AS (VALUES (1) UNION ALL SELECT k+1 FROM r WHERE k<2) SELECT a.id AS aid,b.id AS bid FROM a FULL JOIN b ON a.k=b.k WHERE coalesce(a.k,b.k) IN (SELECT k FROM r);
CREATE TEMP TABLE actual AS
WITH RECURSIVE r(k) AS (VALUES (1) UNION ALL SELECT k+1 FROM r WHERE k<2) SELECT a.id AS aid,b.id AS bid FROM a FULL JOIN b ON a.k=b.k WHERE coalesce(a.k,b.k) IN (SELECT k FROM r);
SELECT '163' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 164. expansion budget: ninth independent FULL JOIN remains native
\echo 'CASE 164: expansion budget: ninth independent FULL JOIN remains native'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT count(*) AS n FROM
((VALUES (1)) x1(k) FULL JOIN (VALUES (2)) y1(k) ON x1.k=y1.k) CROSS JOIN
((VALUES (1)) x2(k) FULL JOIN (VALUES (2)) y2(k) ON x2.k=y2.k) CROSS JOIN
((VALUES (1)) x3(k) FULL JOIN (VALUES (2)) y3(k) ON x3.k=y3.k) CROSS JOIN
((VALUES (1)) x4(k) FULL JOIN (VALUES (2)) y4(k) ON x4.k=y4.k) CROSS JOIN
((VALUES (1)) x5(k) FULL JOIN (VALUES (2)) y5(k) ON x5.k=y5.k) CROSS JOIN
((VALUES (1)) x6(k) FULL JOIN (VALUES (2)) y6(k) ON x6.k=y6.k) CROSS JOIN
((VALUES (1)) x7(k) FULL JOIN (VALUES (2)) y7(k) ON x7.k=y7.k) CROSS JOIN
((VALUES (1)) x8(k) FULL JOIN (VALUES (2)) y8(k) ON x8.k=y8.k) CROSS JOIN
((VALUES (1)) x9(k) FULL JOIN (VALUES (2)) y9(k) ON x9.k=y9.k);
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT count(*) AS n FROM
((VALUES (1)) x1(k) FULL JOIN (VALUES (2)) y1(k) ON x1.k=y1.k) CROSS JOIN
((VALUES (1)) x2(k) FULL JOIN (VALUES (2)) y2(k) ON x2.k=y2.k) CROSS JOIN
((VALUES (1)) x3(k) FULL JOIN (VALUES (2)) y3(k) ON x3.k=y3.k) CROSS JOIN
((VALUES (1)) x4(k) FULL JOIN (VALUES (2)) y4(k) ON x4.k=y4.k) CROSS JOIN
((VALUES (1)) x5(k) FULL JOIN (VALUES (2)) y5(k) ON x5.k=y5.k) CROSS JOIN
((VALUES (1)) x6(k) FULL JOIN (VALUES (2)) y6(k) ON x6.k=y6.k) CROSS JOIN
((VALUES (1)) x7(k) FULL JOIN (VALUES (2)) y7(k) ON x7.k=y7.k) CROSS JOIN
((VALUES (1)) x8(k) FULL JOIN (VALUES (2)) y8(k) ON x8.k=y8.k) CROSS JOIN
((VALUES (1)) x9(k) FULL JOIN (VALUES (2)) y9(k) ON x9.k=y9.k);
CREATE TEMP TABLE actual AS
SELECT count(*) AS n FROM
((VALUES (1)) x1(k) FULL JOIN (VALUES (2)) y1(k) ON x1.k=y1.k) CROSS JOIN
((VALUES (1)) x2(k) FULL JOIN (VALUES (2)) y2(k) ON x2.k=y2.k) CROSS JOIN
((VALUES (1)) x3(k) FULL JOIN (VALUES (2)) y3(k) ON x3.k=y3.k) CROSS JOIN
((VALUES (1)) x4(k) FULL JOIN (VALUES (2)) y4(k) ON x4.k=y4.k) CROSS JOIN
((VALUES (1)) x5(k) FULL JOIN (VALUES (2)) y5(k) ON x5.k=y5.k) CROSS JOIN
((VALUES (1)) x6(k) FULL JOIN (VALUES (2)) y6(k) ON x6.k=y6.k) CROSS JOIN
((VALUES (1)) x7(k) FULL JOIN (VALUES (2)) y7(k) ON x7.k=y7.k) CROSS JOIN
((VALUES (1)) x8(k) FULL JOIN (VALUES (2)) y8(k) ON x8.k=y8.k) CROSS JOIN
((VALUES (1)) x9(k) FULL JOIN (VALUES (2)) y9(k) ON x9.k=y9.k);
SELECT '164' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

CREATE TABLE large_a AS SELECT g AS id,g%500 AS k FROM generate_series(1,20000) g;
CREATE TABLE large_b AS SELECT g AS id,g%700 AS k FROM generate_series(1,20000) g;
ANALYZE large_a;
ANALYZE large_b;

-- 165. parallel-capable regular-table inputs and aggregate
\echo 'CASE 165: parallel-capable regular-table inputs and aggregate'
SET LOCAL max_parallel_workers_per_gather = 2; SET LOCAL min_parallel_table_scan_size = 0; SET LOCAL parallel_setup_cost = 0; SET LOCAL parallel_tuple_cost = 0;
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT coalesce(x.k,y.k) AS k,count(*) AS n,sum(coalesce(x.id,0)::bigint+coalesce(y.id,0)) AS s FROM large_a x FULL JOIN large_b y ON x.k=y.k GROUP BY coalesce(x.k,y.k);
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT coalesce(x.k,y.k) AS k,count(*) AS n,sum(coalesce(x.id,0)::bigint+coalesce(y.id,0)) AS s FROM large_a x FULL JOIN large_b y ON x.k=y.k GROUP BY coalesce(x.k,y.k);
CREATE TEMP TABLE actual AS
SELECT coalesce(x.k,y.k) AS k,count(*) AS n,sum(coalesce(x.id,0)::bigint+coalesce(y.id,0)) AS s FROM large_a x FULL JOIN large_b y ON x.k=y.k GROUP BY coalesce(x.k,y.k);
SELECT '165' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;
SET LOCAL max_parallel_workers_per_gather = 0;

-- 166. low work_mem; hash batching
\echo 'CASE 166: low work_mem; hash batching'
SET LOCAL work_mem = '64kB'; SET LOCAL enable_mergejoin = off;
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT coalesce(x.k,y.k) AS k,count(*) AS n FROM large_a x FULL JOIN large_b y ON x.k=y.k GROUP BY coalesce(x.k,y.k);
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT coalesce(x.k,y.k) AS k,count(*) AS n FROM large_a x FULL JOIN large_b y ON x.k=y.k GROUP BY coalesce(x.k,y.k);
CREATE TEMP TABLE actual AS
SELECT coalesce(x.k,y.k) AS k,count(*) AS n FROM large_a x FULL JOIN large_b y ON x.k=y.k GROUP BY coalesce(x.k,y.k);
SELECT '166' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;
RESET work_mem; SET LOCAL enable_mergejoin = on;

-- Additional guard / mixed-scope cases. The EXPLAIN expectations below refer
-- to the named join, not to every join in the statement. Other safe FULL joins
-- may still be rewritten. Bag checks alone do not prove that a guard fired.

-- 167. MIXED: eligible sibling before volatile ON sibling
\echo 'CASE 167: MIXED: eligible sibling before volatile ON sibling'
\echo 'PLAN: a/b should use Append; x/y should retain Full Join.'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid,b.id AS bid,x.id AS xid,y.id AS yid FROM (a FULL JOIN b ON a.k=b.k) CROSS JOIN (c x FULL JOIN c y ON x.k=y.k AND random()>=0);
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT a.id AS aid,b.id AS bid,x.id AS xid,y.id AS yid FROM (a FULL JOIN b ON a.k=b.k) CROSS JOIN (c x FULL JOIN c y ON x.k=y.k AND random()>=0);
CREATE TEMP TABLE actual AS
SELECT a.id AS aid,b.id AS bid,x.id AS xid,y.id AS yid FROM (a FULL JOIN b ON a.k=b.k) CROSS JOIN (c x FULL JOIN c y ON x.k=y.k AND random()>=0);
SELECT '167' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 168. MIXED: volatile sibling before eligible sibling
\echo 'CASE 168: MIXED: volatile sibling before eligible sibling'
\echo 'PLAN: skipping x/y must not prevent rewriting a/b.'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid,b.id AS bid,x.id AS xid,y.id AS yid FROM (c x FULL JOIN c y ON x.k=y.k AND random()>=0) CROSS JOIN (a FULL JOIN b ON a.k=b.k);
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT a.id AS aid,b.id AS bid,x.id AS xid,y.id AS yid FROM (c x FULL JOIN c y ON x.k=y.k AND random()>=0) CROSS JOIN (a FULL JOIN b ON a.k=b.k);
CREATE TEMP TABLE actual AS
SELECT a.id AS aid,b.id AS bid,x.id AS xid,y.id AS yid FROM (c x FULL JOIN c y ON x.k=y.k AND random()>=0) CROSS JOIN (a FULL JOIN b ON a.k=b.k);
SELECT '168' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 169. MIXED: eligible child below volatile ancestor FULL JOIN
\echo 'CASE 169: MIXED: eligible child below volatile ancestor FULL JOIN'
\echo 'PLAN: inner a/b should use Append; outer join to c remains Full.'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid,b.id AS bid,c.id AS cid FROM (a FULL JOIN b ON a.k=b.k) FULL JOIN c ON coalesce(a.k,b.k)=c.k AND random()>=0;
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT a.id AS aid,b.id AS bid,c.id AS cid FROM (a FULL JOIN b ON a.k=b.k) FULL JOIN c ON coalesce(a.k,b.k)=c.k AND random()>=0;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid,b.id AS bid,c.id AS cid FROM (a FULL JOIN b ON a.k=b.k) FULL JOIN c ON coalesce(a.k,b.k)=c.k AND random()>=0;
SELECT '169' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 170. GUARD: volatile child prevents duplicating its entire parent input
\echo 'CASE 170: GUARD: volatile child prevents duplicating its entire parent input'
\echo 'PLAN: both Full Joins remain; neither subtree may be duplicated.'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid,b.id AS bid,c.id AS cid FROM (a FULL JOIN b ON a.k=b.k AND random()>=0) FULL JOIN c ON coalesce(a.k,b.k)=c.k;
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT a.id AS aid,b.id AS bid,c.id AS cid FROM (a FULL JOIN b ON a.k=b.k AND random()>=0) FULL JOIN c ON coalesce(a.k,b.k)=c.k;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid,b.id AS bid,c.id AS cid FROM (a FULL JOIN b ON a.k=b.k AND random()>=0) FULL JOIN c ON coalesce(a.k,b.k)=c.k;
SELECT '170' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 171. MIXED: FULL JOIN within LIMIT may rewrite but its parent must skip
\echo 'CASE 171: MIXED: FULL JOIN within LIMIT may rewrite but its parent must skip'
\echo 'PLAN: Append below Limit; Full Join above Limit.'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT x.aid,x.bid,c.id AS cid FROM (SELECT a.id AS aid,b.id AS bid,coalesce(a.k,b.k) AS k FROM a FULL JOIN b ON a.k=b.k ORDER BY a.id NULLS FIRST,b.id NULLS FIRST LIMIT 5) x FULL JOIN c ON x.k=c.k;
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT x.aid,x.bid,c.id AS cid FROM (SELECT a.id AS aid,b.id AS bid,coalesce(a.k,b.k) AS k FROM a FULL JOIN b ON a.k=b.k ORDER BY a.id NULLS FIRST,b.id NULLS FIRST LIMIT 5) x FULL JOIN c ON x.k=c.k;
CREATE TEMP TABLE actual AS
SELECT x.aid,x.bid,c.id AS cid FROM (SELECT a.id AS aid,b.id AS bid,coalesce(a.k,b.k) AS k FROM a FULL JOIN b ON a.k=b.k ORDER BY a.id NULLS FIRST,b.id NULLS FIRST LIMIT 5) x FULL JOIN c ON x.k=c.k;
SELECT '171' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 172. MIXED: non-equi eligible sibling must really rewrite
\echo 'CASE 172: MIXED: non-equi eligible sibling must really rewrite'
\echo 'PLAN: non-equi a/b must rewrite to succeed; volatile x/y stays Full.'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT s.aid,s.bid,x.id AS xid,y.id AS yid FROM (SELECT a.id AS aid,b.id AS bid FROM a INNER JOIN b ON a.k<b.k UNION ALL SELECT a.id,NULL::int FROM a WHERE NOT EXISTS (SELECT 1 FROM b WHERE a.k<b.k) UNION ALL SELECT NULL::int,b.id FROM b WHERE NOT EXISTS (SELECT 1 FROM a WHERE a.k<b.k)) s CROSS JOIN (c x FULL JOIN c y ON x.k=y.k AND random()>=0);
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT s.aid,s.bid,x.id AS xid,y.id AS yid FROM (SELECT a.id AS aid,b.id AS bid FROM a FULL JOIN b ON a.k<b.k) s CROSS JOIN (c x FULL JOIN c y ON x.k=y.k AND random()>=0);
CREATE TEMP TABLE actual AS
SELECT s.aid,s.bid,x.id AS xid,y.id AS yid FROM (SELECT a.id AS aid,b.id AS bid FROM a FULL JOIN b ON a.k<b.k) s CROSS JOIN (c x FULL JOIN c y ON x.k=y.k AND random()>=0);
SELECT '172' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 173. GUARD: volatile function hidden in an ON sublink
\echo 'CASE 173: GUARD: volatile function hidden in an ON sublink'
\echo 'PLAN: retain Full Join; volatility is inside the correlated SubLink.'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid,b.id AS bid FROM a FULL JOIN b ON a.k=b.k AND EXISTS (SELECT 1 FROM c WHERE c.k=a.k AND random()>=0);
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT a.id AS aid,b.id AS bid FROM a FULL JOIN b ON a.k=b.k AND EXISTS (SELECT 1 FROM c WHERE c.k=a.k AND random()>=0);
CREATE TEMP TABLE actual AS
SELECT a.id AS aid,b.id AS bid FROM a FULL JOIN b ON a.k=b.k AND EXISTS (SELECT 1 FROM c WHERE c.k=a.k AND random()>=0);
SELECT '173' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 174. GUARD: omitted volatile default hidden in an input subquery
\echo 'CASE 174: GUARD: omitted volatile default hidden in an input subquery'
\echo 'PLAN: retain Full Join; default_arg expands to nextval later.'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT x.id AS aid,b.id AS bid FROM (SELECT a.*,default_arg() AS n FROM a) x FULL JOIN b ON x.k=b.k AND x.n>0;
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT x.id AS aid,b.id AS bid FROM (SELECT a.*,default_arg() AS n FROM a) x FULL JOIN b ON x.k=b.k AND x.n>0;
CREATE TEMP TABLE actual AS
SELECT x.id AS aid,b.id AS bid FROM (SELECT a.*,default_arg() AS n FROM a) x FULL JOIN b ON x.k=b.k AND x.n>0;
SELECT '174' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 175. GUARD: whole-row anonymous alias conservatively blocks query-level siblings
\echo 'CASE 175: GUARD: whole-row anonymous alias conservatively blocks query-level siblings'
\echo 'PLAN: this prototype applies the anonymous-record guard to the whole query level.'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT row_to_json(j)::jsonb AS jr,x.id AS xid,y.id AS yid FROM (a FULL JOIN b USING(k)) j CROSS JOIN (c x FULL JOIN c y ON x.k=y.k);
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT row_to_json(j)::jsonb AS jr,x.id AS xid,y.id AS yid FROM (a FULL JOIN b USING(k)) j CROSS JOIN (c x FULL JOIN c y ON x.k=y.k);
CREATE TEMP TABLE actual AS
SELECT row_to_json(j)::jsonb AS jr,x.id AS xid,y.id AS yid FROM (a FULL JOIN b USING(k)) j CROSS JOIN (c x FULL JOIN c y ON x.k=y.k);
SELECT '175' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 176. MIXED: security barrier input and eligible sibling
\echo 'CASE 176: MIXED: security barrier input and eligible sibling'
\echo 'PLAN: s/b stays Full; x/y should use Append.'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT s.id AS aid,b.id AS bid,x.id AS xid,y.id AS yid FROM (secured_a s FULL JOIN b ON s.k=b.k) CROSS JOIN (c x FULL JOIN c y ON x.k=y.k);
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT s.id AS aid,b.id AS bid,x.id AS xid,y.id AS yid FROM (secured_a s FULL JOIN b ON s.k=b.k) CROSS JOIN (c x FULL JOIN c y ON x.k=y.k);
CREATE TEMP TABLE actual AS
SELECT s.id AS aid,b.id AS bid,x.id AS xid,y.id AS yid FROM (secured_a s FULL JOIN b ON s.k=b.k) CROSS JOIN (c x FULL JOIN c y ON x.k=y.k);
SELECT '176' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 177. GUARD: INTERSECT input
\echo 'CASE 177: GUARD: INTERSECT input'
\echo 'PLAN: retain Full Join above INTERSECT.'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT s.k,b.id FROM (SELECT k FROM a INTERSECT SELECT k FROM c) s FULL JOIN b ON s.k=b.k;
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT s.k,b.id FROM (SELECT k FROM a INTERSECT SELECT k FROM c) s FULL JOIN b ON s.k=b.k;
CREATE TEMP TABLE actual AS
SELECT s.k,b.id FROM (SELECT k FROM a INTERSECT SELECT k FROM c) s FULL JOIN b ON s.k=b.k;
SELECT '177' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 178. GUARD: EXCEPT ALL input
\echo 'CASE 178: GUARD: EXCEPT ALL input'
\echo 'PLAN: retain Full Join above EXCEPT ALL.'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT s.k,b.id FROM (SELECT k FROM a EXCEPT ALL SELECT k FROM c) s FULL JOIN b ON s.k=b.k;
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT s.k,b.id FROM (SELECT k FROM a EXCEPT ALL SELECT k FROM c) s FULL JOIN b ON s.k=b.k;
CREATE TEMP TABLE actual AS
SELECT s.k,b.id FROM (SELECT k FROM a EXCEPT ALL SELECT k FROM c) s FULL JOIN b ON s.k=b.k;
SELECT '178' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- G01 volatile ON: both settings must preserve native unsupported-FULL error.
\echo 'EXPECTED ERROR: G01 volatile ON, rewrite=off; SQLSTATE must be 0A000'
SET LOCAL enable_full_join_rewrite = off;
SAVEPOINT fj_expected_error;
\set ON_ERROR_STOP off
SELECT count(*) FROM a FULL JOIN b ON a.k<b.k AND nextval('side_effect')>0;
\set fj_guard_sqlstate :SQLSTATE
\set ON_ERROR_STOP on
ROLLBACK TO SAVEPOINT fj_expected_error;
SELECT 'G01 volatile ON/off' AS guard_case,
       :'fj_guard_sqlstate' AS observed_sqlstate,
       1 / ((:'fj_guard_sqlstate' = '0A000')::int) AS pass;
RELEASE SAVEPOINT fj_expected_error;
\echo 'EXPECTED ERROR: G01 volatile ON, rewrite=on; SQLSTATE must be 0A000'
SET LOCAL enable_full_join_rewrite = on;
SAVEPOINT fj_expected_error;
\set ON_ERROR_STOP off
SELECT count(*) FROM a FULL JOIN b ON a.k<b.k AND nextval('side_effect')>0;
\set fj_guard_sqlstate :SQLSTATE
\set ON_ERROR_STOP on
ROLLBACK TO SAVEPOINT fj_expected_error;
SELECT 'G01 volatile ON/on' AS guard_case,
       :'fj_guard_sqlstate' AS observed_sqlstate,
       1 / ((:'fj_guard_sqlstate' = '0A000')::int) AS pass;
RELEASE SAVEPOINT fj_expected_error;

-- G02 omitted volatile default: both settings must preserve native unsupported-FULL error.
\echo 'EXPECTED ERROR: G02 omitted volatile default, rewrite=off; SQLSTATE must be 0A000'
SET LOCAL enable_full_join_rewrite = off;
SAVEPOINT fj_expected_error;
\set ON_ERROR_STOP off
SELECT count(*) FROM a FULL JOIN b ON a.k<b.k AND default_arg()>0;
\set fj_guard_sqlstate :SQLSTATE
\set ON_ERROR_STOP on
ROLLBACK TO SAVEPOINT fj_expected_error;
SELECT 'G02 omitted volatile default/off' AS guard_case,
       :'fj_guard_sqlstate' AS observed_sqlstate,
       1 / ((:'fj_guard_sqlstate' = '0A000')::int) AS pass;
RELEASE SAVEPOINT fj_expected_error;
\echo 'EXPECTED ERROR: G02 omitted volatile default, rewrite=on; SQLSTATE must be 0A000'
SET LOCAL enable_full_join_rewrite = on;
SAVEPOINT fj_expected_error;
\set ON_ERROR_STOP off
SELECT count(*) FROM a FULL JOIN b ON a.k<b.k AND default_arg()>0;
\set fj_guard_sqlstate :SQLSTATE
\set ON_ERROR_STOP on
ROLLBACK TO SAVEPOINT fj_expected_error;
SELECT 'G02 omitted volatile default/on' AS guard_case,
       :'fj_guard_sqlstate' AS observed_sqlstate,
       1 / ((:'fj_guard_sqlstate' = '0A000')::int) AS pass;
RELEASE SAVEPOINT fj_expected_error;

-- G03 volatile input: both settings must preserve native unsupported-FULL error.
\echo 'EXPECTED ERROR: G03 volatile input, rewrite=off; SQLSTATE must be 0A000'
SET LOCAL enable_full_join_rewrite = off;
SAVEPOINT fj_expected_error;
\set ON_ERROR_STOP off
SELECT count(*) FROM (SELECT a.*,random() AS r FROM a) x FULL JOIN b ON x.k<b.k AND x.r>=0;
\set fj_guard_sqlstate :SQLSTATE
\set ON_ERROR_STOP on
ROLLBACK TO SAVEPOINT fj_expected_error;
SELECT 'G03 volatile input/off' AS guard_case,
       :'fj_guard_sqlstate' AS observed_sqlstate,
       1 / ((:'fj_guard_sqlstate' = '0A000')::int) AS pass;
RELEASE SAVEPOINT fj_expected_error;
\echo 'EXPECTED ERROR: G03 volatile input, rewrite=on; SQLSTATE must be 0A000'
SET LOCAL enable_full_join_rewrite = on;
SAVEPOINT fj_expected_error;
\set ON_ERROR_STOP off
SELECT count(*) FROM (SELECT a.*,random() AS r FROM a) x FULL JOIN b ON x.k<b.k AND x.r>=0;
\set fj_guard_sqlstate :SQLSTATE
\set ON_ERROR_STOP on
ROLLBACK TO SAVEPOINT fj_expected_error;
SELECT 'G03 volatile input/on' AS guard_case,
       :'fj_guard_sqlstate' AS observed_sqlstate,
       1 / ((:'fj_guard_sqlstate' = '0A000')::int) AS pass;
RELEASE SAVEPOINT fj_expected_error;

-- RLS fixtures: a superuser would otherwise silently bypass row security.
-- The test role and grants exist only until this transaction rolls back.
SELECT current_user AS original_role, rolsuper AS is_superuser,
       (rolbypassrls AND NOT rolsuper) AS skip_rls
FROM pg_roles WHERE rolname=current_user
\gset fj_
\if :fj_skip_rls
\echo 'SKIP RLS group: current non-superuser has BYPASSRLS; use a superuser or ordinary owner.'
\else
CREATE TABLE rls_a (LIKE a);
CREATE TABLE rls_b (LIKE b);
CREATE TABLE rls_sub (LIKE a);
INSERT INTO rls_a SELECT * FROM a;
INSERT INTO rls_b SELECT * FROM b;
INSERT INTO rls_sub SELECT * FROM a;
ALTER TABLE rls_a ENABLE ROW LEVEL SECURITY;
ALTER TABLE rls_a FORCE ROW LEVEL SECURITY;
ALTER TABLE rls_b ENABLE ROW LEVEL SECURITY;
ALTER TABLE rls_b FORCE ROW LEVEL SECURITY;
ALTER TABLE rls_sub ENABLE ROW LEVEL SECURITY;
ALTER TABLE rls_sub FORCE ROW LEVEL SECURITY;
CREATE POLICY visible_a ON rls_a USING (k<=2 OR k IS NULL);
CREATE POLICY visible_b ON rls_b USING (k>=2 OR k IS NULL);
CREATE POLICY visible_sub ON rls_sub USING
 (EXISTS (SELECT 1 FROM fj_rewrite_test.c WHERE c.k=rls_sub.k));
\if :fj_is_superuser
CREATE ROLE fj_rewrite_rls_subject NOLOGIN NOSUPERUSER NOBYPASSRLS;
GRANT USAGE ON SCHEMA fj_rewrite_test TO fj_rewrite_rls_subject;
GRANT SELECT ON a,b,c,rls_a,rls_b,rls_sub TO fj_rewrite_rls_subject;
GRANT TEMPORARY ON DATABASE :"DBNAME" TO fj_rewrite_rls_subject;
SET LOCAL ROLE fj_rewrite_rls_subject;
\endif
SET LOCAL row_security = on;
SELECT current_user AS rls_role,
       1 / ((row_security_active('rls_a') AND row_security_active('rls_b')
             AND row_security_active('rls_sub'))::int) AS pass;
SELECT 1 / ((count(*)=8)::int) AS pass FROM rls_a;
SELECT 1 / ((count(*)=9)::int) AS pass FROM rls_b;
SELECT 1 / ((count(*)=3)::int) AS pass FROM rls_sub;
\set fj_rls_ran true

-- 179. RLS: protected left input with duplicate and NULL-key rows
\echo 'CASE 179: RLS: protected left input with duplicate and NULL-key rows'
\echo 'PLAN: retain Full Join and the visible_a policy filter.'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT r.id AS aid,b.id AS bid,r.k AS ak,b.k AS bk FROM rls_a r FULL JOIN b ON r.k=b.k;
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT r.id AS aid,b.id AS bid,r.k AS ak,b.k AS bk FROM rls_a r FULL JOIN b ON r.k=b.k;
CREATE TEMP TABLE actual AS
SELECT r.id AS aid,b.id AS bid,r.k AS ak,b.k AS bk FROM rls_a r FULL JOIN b ON r.k=b.k;
SELECT '179' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 180. RLS: protected right input and NULL-preserving WHERE
\echo 'CASE 180: RLS: protected right input and NULL-preserving WHERE'
\echo 'PLAN: retain protected input; WHERE must see only policy-visible rows.'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid,r.id AS bid FROM a FULL JOIN rls_b r ON a.k=r.k WHERE a.k IS NULL OR r.k>=2;
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT a.id AS aid,r.id AS bid FROM a FULL JOIN rls_b r ON a.k=r.k WHERE a.k IS NULL OR r.k>=2;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid,r.id AS bid FROM a FULL JOIN rls_b r ON a.k=r.k WHERE a.k IS NULL OR r.k>=2;
SELECT '180' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 181. RLS: different policies on both inputs
\echo 'CASE 181: RLS: different policies on both inputs'
\echo 'PLAN: retain Full Join and both policy filters.'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT x.id AS aid,y.id AS bid,x.k AS ak,y.k AS bk FROM rls_a x FULL JOIN rls_b y ON x.k=y.k;
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT x.id AS aid,y.id AS bid,x.k AS ak,y.k AS bk FROM rls_a x FULL JOIN rls_b y ON x.k=y.k;
CREATE TEMP TABLE actual AS
SELECT x.id AS aid,y.id AS bid,x.k AS ak,y.k AS bk FROM rls_a x FULL JOIN rls_b y ON x.k=y.k;
SELECT '181' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 182. RLS: policy contains correlated EXISTS
\echo 'CASE 182: RLS: policy contains correlated EXISTS'
\echo 'PLAN: preserve policy SubLink/semijoin and protected Full Join.'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT r.id AS aid,b.id AS bid FROM rls_sub r FULL JOIN b ON r.k=b.k;
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT r.id AS aid,b.id AS bid FROM rls_sub r FULL JOIN b ON r.k=b.k;
CREATE TEMP TABLE actual AS
SELECT r.id AS aid,b.id AS bid FROM rls_sub r FULL JOIN b ON r.k=b.k;
SELECT '182' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 183. MIXED RLS: protected sibling and eligible ordinary sibling
\echo 'CASE 183: MIXED RLS: protected sibling and eligible ordinary sibling'
\echo 'PLAN: r/b stays Full with policy filter; ordinary x/y should use Append.'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT r.id AS aid,b.id AS bid,x.id AS xid,y.id AS yid FROM (rls_a r FULL JOIN b ON r.k=b.k) CROSS JOIN (c x FULL JOIN c y ON x.k=y.k);
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT r.id AS aid,b.id AS bid,x.id AS xid,y.id AS yid FROM (rls_a r FULL JOIN b ON r.k=b.k) CROSS JOIN (c x FULL JOIN c y ON x.k=y.k);
CREATE TEMP TABLE actual AS
SELECT r.id AS aid,b.id AS bid,x.id AS xid,y.id AS yid FROM (rls_a r FULL JOIN b ON r.k=b.k) CROSS JOIN (c x FULL JOIN c y ON x.k=y.k);
SELECT '183' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- G04 active RLS input: both settings must preserve native unsupported-FULL error.
\echo 'EXPECTED ERROR: G04 active RLS input, rewrite=off; SQLSTATE must be 0A000'
SET LOCAL enable_full_join_rewrite = off;
SAVEPOINT fj_expected_error;
\set ON_ERROR_STOP off
SELECT count(*) FROM rls_a r FULL JOIN b ON r.k<b.k;
\set fj_guard_sqlstate :SQLSTATE
\set ON_ERROR_STOP on
ROLLBACK TO SAVEPOINT fj_expected_error;
SELECT 'G04 active RLS input/off' AS guard_case,
       :'fj_guard_sqlstate' AS observed_sqlstate,
       1 / ((:'fj_guard_sqlstate' = '0A000')::int) AS pass;
RELEASE SAVEPOINT fj_expected_error;
\echo 'EXPECTED ERROR: G04 active RLS input, rewrite=on; SQLSTATE must be 0A000'
SET LOCAL enable_full_join_rewrite = on;
SAVEPOINT fj_expected_error;
\set ON_ERROR_STOP off
SELECT count(*) FROM rls_a r FULL JOIN b ON r.k<b.k;
\set fj_guard_sqlstate :SQLSTATE
\set ON_ERROR_STOP on
ROLLBACK TO SAVEPOINT fj_expected_error;
SELECT 'G04 active RLS input/on' AS guard_case,
       :'fj_guard_sqlstate' AS observed_sqlstate,
       1 / ((:'fj_guard_sqlstate' = '0A000')::int) AS pass;
RELEASE SAVEPOINT fj_expected_error;

\if :fj_is_superuser
SET LOCAL ROLE :"fj_original_role";
\endif
\endif

-- Optional FDW cases. This is a local deterministic foreign scan, not a
-- postgres_fdw loopback connection that needs authentication or committed data.
-- The program merely prints five fixed CSV rows, including duplicates/NULLs.
\if :fj_test_file_fdw
SELECT rolsuper AND EXISTS (SELECT 1 FROM pg_available_extensions
                           WHERE name='file_fdw') AS can_file_fdw
FROM pg_roles WHERE rolname=current_user
\gset fj_
\if :fj_can_file_fdw
CREATE EXTENSION IF NOT EXISTS file_fdw;
CREATE SERVER fj_rewrite_file_server FOREIGN DATA WRAPPER file_fdw;
CREATE FOREIGN TABLE foreign_input(id int,k int)
 SERVER fj_rewrite_file_server
 OPTIONS (program 'printf ''1,1\n2,1\n3,\n4,4\n4,4\n''', format 'csv');
SELECT 1 / ((count(*)=5)::int) AS pass FROM foreign_input;
SELECT 1 / ((count(*)=1)::int) AS pass FROM foreign_input WHERE k IS NULL;
SELECT 1 / ((count(*)=2)::int) AS pass FROM foreign_input WHERE id=4 AND k=4;
\set fj_fdw_ran true

-- 184. FDW: foreign left input with duplicate and NULL-key rows
\echo 'CASE 184: FDW: foreign left input with duplicate and NULL-key rows'
\echo 'PLAN: retain Full Join with Foreign Scan.'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT f.id AS fid,b.id AS bid,f.k AS fk,b.k AS bk FROM foreign_input f FULL JOIN b ON f.k=b.k;
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT f.id AS fid,b.id AS bid,f.k AS fk,b.k AS bk FROM foreign_input f FULL JOIN b ON f.k=b.k;
CREATE TEMP TABLE actual AS
SELECT f.id AS fid,b.id AS bid,f.k AS fk,b.k AS bk FROM foreign_input f FULL JOIN b ON f.k=b.k;
SELECT '184' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 185. FDW: foreign right input and NULL-preserving WHERE
\echo 'CASE 185: FDW: foreign right input and NULL-preserving WHERE'
\echo 'PLAN: retain protected Foreign Scan input.'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT a.id AS aid,f.id AS fid FROM a FULL JOIN foreign_input f ON a.k=f.k WHERE a.k IS NULL OR f.k=4;
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT a.id AS aid,f.id AS fid FROM a FULL JOIN foreign_input f ON a.k=f.k WHERE a.k IS NULL OR f.k=4;
CREATE TEMP TABLE actual AS
SELECT a.id AS aid,f.id AS fid FROM a FULL JOIN foreign_input f ON a.k=f.k WHERE a.k IS NULL OR f.k=4;
SELECT '185' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 186. FDW: both inputs foreign
\echo 'CASE 186: FDW: both inputs foreign'
\echo 'PLAN: retain Full Join with two Foreign Scans.'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT x.id AS xid,y.id AS yid,x.k AS xk,y.k AS yk FROM foreign_input x FULL JOIN foreign_input y ON x.k=y.k;
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT x.id AS xid,y.id AS yid,x.k AS xk,y.k AS yk FROM foreign_input x FULL JOIN foreign_input y ON x.k=y.k;
CREATE TEMP TABLE actual AS
SELECT x.id AS xid,y.id AS yid,x.k AS xk,y.k AS yk FROM foreign_input x FULL JOIN foreign_input y ON x.k=y.k;
SELECT '186' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- 187. MIXED FDW: foreign sibling and eligible local sibling
\echo 'CASE 187: MIXED FDW: foreign sibling and eligible local sibling'
\echo 'PLAN: f/b stays Full; local x/y should use Append.'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS
SELECT f.id AS fid,b.id AS bid,x.id AS xid,y.id AS yid FROM (foreign_input f FULL JOIN b ON f.k=b.k) CROSS JOIN (c x FULL JOIN c y ON x.k=y.k);
SET LOCAL enable_full_join_rewrite = on;
EXPLAIN (VERBOSE, COSTS OFF)
SELECT f.id AS fid,b.id AS bid,x.id AS xid,y.id AS yid FROM (foreign_input f FULL JOIN b ON f.k=b.k) CROSS JOIN (c x FULL JOIN c y ON x.k=y.k);
CREATE TEMP TABLE actual AS
SELECT f.id AS fid,b.id AS bid,x.id AS xid,y.id AS yid FROM (foreign_input f FULL JOIN b ON f.k=b.k) CROSS JOIN (c x FULL JOIN c y ON x.k=y.k);
SELECT '187' AS case_id, 1 / ((count(*) = 0)::int) AS pass
FROM (
  (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)
  UNION ALL
  (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) AS difference;
DROP TABLE expected, actual;

-- G05 foreign input: both settings must preserve native unsupported-FULL error.
\echo 'EXPECTED ERROR: G05 foreign input, rewrite=off; SQLSTATE must be 0A000'
SET LOCAL enable_full_join_rewrite = off;
SAVEPOINT fj_expected_error;
\set ON_ERROR_STOP off
SELECT count(*) FROM foreign_input f FULL JOIN b ON f.k<b.k;
\set fj_guard_sqlstate :SQLSTATE
\set ON_ERROR_STOP on
ROLLBACK TO SAVEPOINT fj_expected_error;
SELECT 'G05 foreign input/off' AS guard_case,
       :'fj_guard_sqlstate' AS observed_sqlstate,
       1 / ((:'fj_guard_sqlstate' = '0A000')::int) AS pass;
RELEASE SAVEPOINT fj_expected_error;
\echo 'EXPECTED ERROR: G05 foreign input, rewrite=on; SQLSTATE must be 0A000'
SET LOCAL enable_full_join_rewrite = on;
SAVEPOINT fj_expected_error;
\set ON_ERROR_STOP off
SELECT count(*) FROM foreign_input f FULL JOIN b ON f.k<b.k;
\set fj_guard_sqlstate :SQLSTATE
\set ON_ERROR_STOP on
ROLLBACK TO SAVEPOINT fj_expected_error;
SELECT 'G05 foreign input/on' AS guard_case,
       :'fj_guard_sqlstate' AS observed_sqlstate,
       1 / ((:'fj_guard_sqlstate' = '0A000')::int) AS pass;
RELEASE SAVEPOINT fj_expected_error;

\else
\echo 'SKIP FDW group: requires superuser and available file_fdw extension.'
\endif
\else
\echo 'SKIP FDW group: enable with psql -v fj_test_file_fdw=1 on a server with POSIX printf.'
\endif

-- Prepared parameters: inspect generic and custom plans separately.
\echo 'PREPARED: generic and custom plans'
SET LOCAL enable_full_join_rewrite = off;
CREATE TEMP TABLE expected AS SELECT a.id AS aid,b.id AS bid
 FROM a FULL JOIN b ON a.k=b.k AND a.v>=10 WHERE coalesce(a.k,b.k)>=2;
SET LOCAL enable_full_join_rewrite = on;
PREPARE fj_parameterized(numeric,int) AS SELECT a.id AS aid,b.id AS bid
 FROM a FULL JOIN b ON a.k=b.k AND a.v>=$1 WHERE coalesce(a.k,b.k)>=$2;
SET LOCAL plan_cache_mode = force_generic_plan;
EXPLAIN (VERBOSE,COSTS OFF) EXECUTE fj_parameterized(10,2);
CREATE TEMP TABLE actual AS EXECUTE fj_parameterized(10,2);
SELECT 1 / ((count(*)=0)::int) AS pass FROM (
 (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual) UNION ALL
 (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) d;
DROP TABLE actual;
SET LOCAL plan_cache_mode = force_custom_plan;
EXPLAIN (VERBOSE,COSTS OFF) EXECUTE fj_parameterized(10,2);
CREATE TEMP TABLE actual AS EXECUTE fj_parameterized(10,2);
SELECT 1 / ((count(*)=0)::int) AS pass FROM (
 (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual) UNION ALL
 (SELECT * FROM actual EXCEPT ALL SELECT * FROM expected)
) d;
DROP TABLE expected,actual;
DEALLOCATE fj_parameterized;
RESET plan_cache_mode;

-- No SELECT rewrite inside DML statements: inspect a plan without executing it.
\echo 'GUARD: INSERT statement retains ordinary FULL JOIN'
CREATE TABLE sink(aid int,bid int);
EXPLAIN (VERBOSE,COSTS OFF)
INSERT INTO sink SELECT a.id,b.id FROM a FULL JOIN b ON a.k=b.k;

\echo 'GUARD: data-modifying CTE retains ordinary FULL JOIN'
EXPLAIN (VERBOSE,COSTS OFF)
WITH changed AS (INSERT INTO sink VALUES (1,1) RETURNING *)
SELECT a.id AS aid,b.id AS bid FROM a FULL JOIN b ON a.k=b.k;

-- Independent cardinality checks, including all-null physical duplicate rows.
\echo 'FIXED CARDINALITIES: duplicate and NULL semantics'
SELECT 1 / ((count(*)=21)::int) AS pass FROM a FULL JOIN b ON a.k=b.k;
SELECT 1 / ((count(*)=29)::int) AS pass FROM a FULL JOIN b ON a.k IS NOT DISTINCT FROM b.k;
SELECT 1 / ((count(*)=24)::int) AS pass FROM a FULL JOIN b ON false;
SELECT 1 / ((count(*)=24)::int) AS pass FROM a FULL JOIN b ON NULL::boolean;
SELECT 1 / ((count(*)=144)::int) AS pass FROM a FULL JOIN b ON true;

ROLLBACK;
\echo 'RLS group executed:' :fj_rls_ran
\echo 'FDW group executed:' :fj_fdw_ran
\echo 'ALL EXECUTED BAG, SIDE-EFFECT AND EXPECTED-ERROR CHECKS PASSED; inspect EXPLAIN and SKIP messages too.'
