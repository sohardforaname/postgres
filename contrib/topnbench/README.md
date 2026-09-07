# topnbench

`topnbench` is a standalone PostgreSQL benchmark extension for projection
placement in `ORDER BY ... LIMIT` queries.  It is designed to answer two
different questions:

1. How much faster is late projection for a particular query?
2. How reliably does a planner rule choose between early and late projection,
   especially when catalog function costs are inaccurate?

This is benchmark code, not code intended for PostgreSQL commit.

## Build and run

```sh
make PG_CONFIG=/path/to/pg_config
make PG_CONFIG=/path/to/pg_config install
psql -X -f benchmark.sql postgres
```

The default report is compact.  Add `-v topnbench_verbose=true` to print every
per-case row, candidate-path diagnostic, and raw width-calibration point.

`benchmark.sql` drops and recreates the extension, a one-million-row main
table, two smaller width-estimation tables, and six accurately analyzed width
tables.  The POC patch provides temporary
`enable_cost_based_delayed_projection` and
`enable_sort_tuple_width_cost` GUCs.  Every case runs under three policies:

- `master`: both GUCs off, reproducing the upstream planner;
- `path-only`: delayed-projection paths on, width-sensitive Sort cost off;
- `patched`: both features on.

This separates the effect of constructing two competing projection paths from
the effect of the new Sort cost, using one backend without cross-build timing
noise.  Both GUCs are development aids and are not intended for a commit-ready
patch.

The extension script must be named `topnbench--1.0.sql` because PostgreSQL's
extension loader requires a versioned installation script.  That is only the
extension packaging version: the extension, module, directory, and C source
are all named `topnbench` and `topnbench.c`.

## Compared strategies

Every case compares three equivalent statements:

- `auto`: the natural query, allowing the planner to choose projection
  placement;
- `manual-late`: a subquery that performs the bounded Sort before evaluating
  the target expressions;
- `forced-early`: the target expressions are secondary sort keys, forcing
  their evaluation below Sort without changing the order established by the
  unique leading key.

Before timing, `EXCEPT ALL` verifies that all three statements return the same
multiset.  Each statement gets an untimed warmup.  Timed executions use a
rotating order, and both minimum and median executor time are reported from
`EXPLAIN (ANALYZE, VERBOSE, TIMING OFF, FORMAT JSON)`.

The first Sort node's complete, whitespace-normalized `Output` array is
compared with the corresponding arrays from the manual-late and forced-early
plans.  Bare relation qualifiers are ignored so that, for example, `a` and
`topnbench_data.a` compare equal.  A match with exactly one baseline identifies
the automatic plan as `late` or `early`; ambiguous and unrecognized cases are
reported as `unknown`.
The three signatures are included in the output for diagnosing unknown cases.
This expression-level comparison is necessary because a late plan may still
carry several source Vars through Sort.
The same JSON plan supplies estimated Sort input rows and width, actual input
rows, Sort method, space type, and space used.  Row counts are multiplied by
the Sort/child loop counts so parallel cases are reported on an aggregate
basis.  `row_estimation_ratio` is left NULL for parallel plans because a path's
per-worker row estimate incorporates PostgreSQL's parallel divisor and is not
directly comparable with launched-worker execution totals.  Sort method and
space are also reported separately for the manual-late and forced-early
strategies, which makes in-memory versus spill behavior visible.

## Decision-quality fields

`actual_winner` compares the median `manual-late` and `forced-early` times.
Results within 3% are marked `tie`; correctness is NULL for ties and unknown
plans.  This avoids treating timing noise near a crossover point as a planner
failure.

`decision_class` reports `correct`, `false-late`, `false-early`, `tie`, or
`unknown` directly.  A false-late is especially important for a delayed-
projection patch; the policy comparison determines whether it was newly
introduced by the POC or already existed under the upstream policy.

`choice_regression_ratio` is the time of the strategy selected by the planner
divided by the faster strategy's time.  It is 1 for a perfect choice and shows
the cost of a wrong decision directly.  `auto_regression_ratio` performs the
same comparison using the natural query's measured time.

The generated matrix also reports two deliberately simple predictions:

```text
late when weight * (input_rows - sort_rows) > 10 * sort_rows
```

For `cost_model_choice`, `weight` is the number of function calls multiplied
by their declared `procost`.  For `structural_model_choice`, it is just the
number of function-call nodes.  These fields do not claim that either model is
correct; they make it possible to compare their failures and worst regressions
on the same measurements.

`sort_rows` is `OFFSET + LIMIT`, capped at the input row count.  The manual
late form deliberately evaluates its projection for that many rows, matching
the placement available to the planner between Sort and Limit.

## Synthetic workload

The SQL names `topnbench_work_cost_1`, `topnbench_work_cost_10`, and
`topnbench_work_cost_100` all call the same C function.  A separate argument
controls the actual number of CPU-work rounds.  This permits both directions
of cost error to be tested:

- identical real work with different declared costs;
- different real work with the same declared cost.

The matrix also compares several independent target expressions with a single
nested expression containing the same number of calls.  The early-winner
controls pass `octet_length(payload)` through the COST 1 and COST 100 aliases
with zero work rounds, reusing the same implementation while replacing a wide
source value with a narrow projected result before Sort.

## Profiles

The default `quick` profile is a curated matrix covering tiny LIMIT values and
every 10% point from 10% through 100%, expression steps, a 3-by-3 grid of
declared `procost` versus real work, nested expressions, parallel execution,
and OFFSET.  It is intended for frequent master-versus-patch comparisons.

The `confidence` profile adds denser cases around candidate decision
boundaries:

```sql
SELECT *
FROM topnbench_run('topnbench_data', 'a', 7, 'confidence', true);
```

It is intentionally not a full Cartesian product.  Add targeted cases after a
run reveals a crossover or a bad decision.

## Supplemental cases in benchmark.sql

After the generated profile, `benchmark.sql` builds a temporary case catalog.
Each definition has a stable order, execution phase, reporting category, the
three equivalent query forms, an iteration count, and an optional `work_mem`
setting.  This keeps the query definitions separate from execution and avoids
duplicating them for the upstream and POC policies.

The catalog contains representative and adversarial cases that deliberately
separate planner inputs from execution reality:

- the motivating numeric expression, cheap built-ins, and text-producing
  expressions under normal parallel settings;
- ascending, descending, and pseudo-random physical input order;
- cardinality underestimation and overestimation from correlated predicates;
- stale width statistics in both directions;
- a projection that expands a narrow input tuple;
- the underestimated-wide case across `work_mem` values from `64kB` through
  `256MB`, exposing the in-memory/spill crossover;
- the same `work_mem` sweep after refreshing width statistics, separating
  costing behavior from failures caused by stale `avg_width`;
- early-winner controls that project a 260-byte payload to a four-byte integer
  using a pseudo-random sort key, crossing the two synthetic function costs,
  four LIMIT fractions, and three `work_mem` values;
- an accurately analyzed in-memory width sweep from 8 through 1024 payload
  bytes, with fixed row count, expression work, and `work_mem`.  Its 100%
  LIMIT cases evaluate the expression for every row in both placements and
  therefore isolate the cost of copying differently sized Sort tuples; the
  smaller LIMITs exercise the crossover between that cost and avoided
  expression work.

The same six tables also feed a pure Sort calibration.  It compares
`SELECT sort_key ... ORDER BY ... LIMIT` with an otherwise identical query
that carries `payload` through Sort.  There are no computed target expressions,
so the cost and time deltas isolate width-sensitive Sort work from expression
evaluation and Result-node overhead.  The compact report shows the first width
that is at least 10% slower, the worst time ratio, and the correlation between
estimated and measured deltas for each LIMIT fraction.

The supplemental catalog is executed in three phases so that normal parallel
settings, deliberately stale statistics, and repaired width statistics cannot
be mixed accidentally.  Cases are summarized by category as well as for the
complete suite.  Wide diagnostics are printed only for regressions, unchanged
misses, and inconclusive cases; projection signatures are printed only when a
plan cannot be classified.  A final combined summary covers both the quick and
supplemental suites, making the total number of newly introduced regressions
visible in one row.  The category and combined summaries also count actual
late winners, early winners, and ties, so a one-sided workload is immediately
obvious.

Both `topnbench_choice_comparison` and
`topnbench_supplemental_comparison` classify each upstream-versus-POC decision
as `improvement`, `regression`, `unchanged-correct`, `unchanged-miss`, or
`inconclusive`.  A case is inconclusive when either plan cannot be classified,
either run reports a tie, or the measured winner changes between the two runs.
Strategy speedups use the late and early timings from the POC run, so both
choices are compared under the same run conditions.
The same tables contain `width_cost_effect`, which performs the identical
classification between `path-only` and `patched`.  This is the direct answer
to whether the width term improved or regressed a decision.

## Experimental Sort width cost

The POC models two kinds of memory work in `cost_tuplesort()`:

```text
cpu_operator_cost *
    (input_bytes / 1024 + resident_bytes / 64)
```

`input_bytes` represents touching/copying every tuple presented to tuplesort.
`resident_bytes` represents the bounded result retained in memory and is
capped at `work_mem` when the sort spills; width-dependent spill I/O is already
charged by the existing costing code.  The divisors are calibration points,
not proposed final constants.  `topnbench_measure()` and the pure Sort matrix
exist specifically to test whether the two terms track measured executor work
before tuning those values further.

## Candidate path costs

While the extension is loaded, it chains PostgreSQL's
`create_upper_paths_hook`.  During each automatic benchmark query it inspects
the top-level `UPPERREL_ORDERED` pathlist after normal path pruning and records
the cheapest surviving early- and late-projection candidates.  This requires
no additional backend patch: the values are taken from the exact Paths built
by the POC in the same planning invocation.

For each placement, the result reports the Path's `startup_cost`, `total_cost`,
and the rows and width entering Sort.  `early_limit_cost` and
`late_limit_cost` linearly interpolate between startup and total cost using
`root->limit_tuples / path->rows`; `root->limit_tuples` already represents
`OFFSET + LIMIT`.  This is the estimated amount of the candidate consumed by
the upper Limit.  `lower_limit_cost_choice` names the candidate with the lower
interpolated cost.  It is a numeric diagnostic rather than a reconstruction
of `add_path()`'s full path tournament.  `costs_within_1pct` identifies the
cases in which the two costs are inside the standard 1% fuzz range and another
path property can decide which candidate survives.
`estimated_late_vs_early_cost` is the ratio of late's interpolated cost to
early's.

The final report prints these fields only for regressions, unchanged misses,
and inconclusive cases.  A missing placement is reported as NULL and makes
`lower_limit_cost_choice` `unknown`; this means that no recognizable surviving
Path of that shape reached the hook, rather than that its cost was zero.

## Custom expressions

Use `topnbench_compare()` for real expressions.  Supply the natural, manually
late, and forced-early forms:

```sql
SELECT * FROM topnbench_compare(
  'SELECT a, expensive(a) FROM t ORDER BY a LIMIT 100',
  'SELECT s.a, expensive(s.a)
     FROM (SELECT a FROM t ORDER BY a LIMIT 100) AS s',
  'SELECT a, expensive(a) AS e
     FROM t ORDER BY a, e LIMIT 100',
  7,
  true);
```

An optional sixth argument runs all three statements with a specific
`work_mem` value without changing the surrounding session setting:

```sql
SELECT * FROM topnbench_compare(auto_sql, late_sql, early_sql,
                                5, true, '64kB');
```

The function rejects multiple statements, non-SELECT statements, `SELECT
INTO`, and row-locking clauses.  Benchmark only side-effect-free expressions.
Keep verification enabled for results shared on pgsql-hackers.

For a single query without early/late rewrites, use `topnbench_measure()`:

```sql
SELECT * FROM topnbench_measure(
  'SELECT sort_key, payload FROM t ORDER BY sort_key LIMIT 1000',
  7,
  '1GB');
```

It reports root startup/total cost, Sort rows, width, method and memory, plus
minimum and median execution time.
