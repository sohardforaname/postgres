# topnbench

`topnbench` is a standalone PostgreSQL benchmark extension for delayed
projection in `ORDER BY ... LIMIT` queries.  It follows the method used by
Jan Nidzwetzki's `repeatbench`: validate equivalent strategies before timing,
rotate execution order to reduce cache-order bias, run fixed boundary cases,
and report the minimum observed time.

Methodology reference: [pgsql-hackers: Speed up repeat() for larger counts](https://www.postgresql.org/message-id/flat/tencent_C5BBECF985A270FBC49463EDAF722CD5E005%40qq.com)

This is benchmark code, not code intended for PostgreSQL commit.

## Build

```sh
make PG_CONFIG=/path/to/pg_config
make PG_CONFIG=/path/to/pg_config install
```

Then run:

```sh
psql -X -f benchmark.sql postgres
```

Run the same script against an unpatched PostgreSQL build and the patched
build.  `late_speedup` is `auto_ms / manual_late_ms`, so a value greater than
1 means the hand-written delayed form was faster.  On a successful planner
patch, `auto_ms` should approach `manual_late_ms` in the cases where delaying
projection is profitable.  The reported values are executor times from
`EXPLAIN (ANALYZE, TIMING OFF, FORMAT JSON)`; planning and result rendering
are excluded.

## What the matrix varies

- LIMIT selectivity from one part per million through 50% in the quick set
- 1, 4, 8, or 16 projected expressions
- declared per-expression `procost` of 1, 2, 5, or 10
- serial execution and `max_parallel_workers_per_gather = 2`

The C expressions perform deterministic CPU work scaled approximately with
their declared cost.  All functions remain below PostgreSQL's historical
per-expression "expensive" cutoff, allowing the aggregate-cost/Top-N rule to
be exercised.

`auto_plan_nodes` is a compact preorder fingerprint extracted from the JSON
plan.  `launched_workers` is the maximum `Workers Launched` value reported by
the automatic plan.  `forced_early_ms` is measured by adding every projected
expression as a secondary sort key.  This gives each expression a
`sortgroupref`, forcing evaluation below the Sort while preserving parallel
Sort/Gather Merge topology.  Since these expressions are deterministic
functions of the leading key, this does not change ordering among equal keys.
`late_vs_early_speedup` is
`forced_early_ms / manual_late_ms` and isolates the benefit of delaying the
projection.

## Profiles and custom expressions

```sql
SELECT * FROM topnbench_run('topnbench_data', 'a', 5, 'full', true);
```

Use `topnbench_compare()` to benchmark any pair of equivalent SELECTs.  The
first should be the natural query and the second its manually delayed form:

```sql
SELECT * FROM topnbench_compare(
  'SELECT a, expensive(a) FROM t ORDER BY a LIMIT 100',
  'SELECT s.a, expensive(s.a)
     FROM (SELECT a FROM t ORDER BY a LIMIT 100) AS s
    ORDER BY s.a',
  'SELECT a, expensive(a) AS e
     FROM t ORDER BY a, e LIMIT 100',
  5,
  true);
```

The function rejects multiple statements, non-SELECT statements, `SELECT
INTO`, and row-locking clauses.  Benchmark only side-effect-free expressions.

For faster exploratory runs, pass `false` as the final argument to skip the
`EXCEPT ALL` equivalence check.  Keep verification enabled for results shared
on pgsql-hackers.
