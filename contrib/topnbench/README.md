# topnbench

## 0014: Sort representation and projection controls

Apply on top of 0013 and run `benchmark.sql` as usual. This is a SQL-only
increment: no backend or extension rebuild is needed. No costs, coefficients
or planner rules change. The entry point also runs `sort_representation.sql`.
If the previous benchmark's `topnbench_data` and extension are still installed,
the new script can also be run directly with psql and ON_ERROR_STOP enabled.

The new section reuses `topnbench_data`, testing LIMIT 250,000 and 900,000 at
4MB and 256MB work_mem. Six query forms run in each cell: full one-/two-column
scans, one-column Datum Sort, two-column tuple Sort, and the same one-column
Sort followed by COST 100 function calls with zero or 16 work rounds. Every
Sort has only one ordering key; the number of carried columns distinguishes
the representations. COST 100 is a placement aid, not a calibrated work cost.

Six batches rotate all six forms through every measurement position. Each
call has one warmup and three timed samples, using existing topnbench_measure.
This adds 144 measurement calls and 24 diagnostic executions. Core tracing is
off throughout this section. Local settings are restored at its end.

After timing, actual diagnostic plans must show one/two Sort input columns as
specified and a Result above Sort for the projection controls. Unexpected
shapes raise an error. The intended memory/disk regimes are NOT assumed: the
report shows observed Sort methods, memory/disk usage and temporary I/O, and
also lists the method captured in each measurement call's warmup. If a regime
differs, interpret that cell according to the observed method before fitting
any coefficient. Full plans and per-batch results remain in session tables.

`tuple_vs_datum` compares paired total execution times. `*_minus_scan_ms`
subtract matched full-scan times as a proxy for incremental sorting work,
not exclusive Sort-node time. Projection deltas include Result dispatch,
function calls, expression work and an extra output column; they cannot by
themselves identify cpu_tuple_cost. Negative deltas remain visible as noise.
Use the per-batch table to judge repeatability rather than fitting constants
from one aggregate ratio. These results complement the existing width and
early-winner controls; they do not resolve stale statistics automatically.

## 0013: cleanup and benefit-loss diagnostics

Apply 0013 on top of the functional 0012. Rebuild/install both PostgreSQL and
topnbench, then restart the server. SQL function signatures are unchanged.
This patch shares existing sorting and measurement code; it does not change
the 0012 candidate-selection policy or width-cost coefficients.

The usual `benchmark.sql` entry point now includes four additional paired
cases: `cost-1-work-1`, `cost-1-work-16`, `cost-1-work-64`, and `limit-90pct`.
Their expression parameters come from the quick-matrix result rows; their
`work_mem` is captured before the quick matrix runs. They reuse the same
four-batch runner as the 12 boundary cases. Labels `0011` and `0012` describe
the comparison policies, toggled in the same rebuilt backend.

Read `new_vs_old` for the direct natural-query comparison with 0011. The broad
matrix's `unchanged-miss` is relative to upstream, so it can hide benefits lost
since 0011. The new section prints per-batch times, candidate costs and exact
queries for these four cases. It also saves their eight untimed natural-query
plans in the session's `topnbench_final_plans` table.

## Candidate selection trace

The temporary `debug_print_projection_paths` GUC is
off by default and does not alter costs, fuzz factors, or path selection.

Run the usual entry point, capturing both output streams:

```sh
psql -X -v ON_ERROR_STOP=1 -f contrib/topnbench/benchmark.sql > topnbench.log 2>&1
```

After the timed batches, each of the four regression probes runs one additional
plan-only natural-query EXPLAIN for each policy.  Only these twelve EXPLAINs
enable DEBUG1 tracing in that section; the four benefit-loss cases add eight
more untimed EXPLAINs. Read the `topn-trace BEGIN/END` markers:

* `ordered-surviving`: real ORDERED paths after that stage's hook;
* `ordered-component`: the unary components of each such candidate, with
  estimated rows, width, startup/total and target startup/per-tuple costs;
* `final-proposed`: each path with Limit attached, immediately before add_path;
* `final-compare`: the actual fuzzy comparison and accept/remove decisions
  between two LimitPaths inside add_path;
* `final-surviving`: paths remaining after the FINAL-stage hook;
* `selected`: the exact best_path passed to create_plan, after initPlan costs
  and set_cheapest.  The preceding line prints the actual selection fraction.

`ordered_id` links a final path to its ORDERED ancestor within that one planning
run (zero means unmatched).  It is not comparable between queries.  Shapes are
Path shapes, so a Projection may later be absorbed into a scan plan.  `Other`
ends the bounded unary walk; it is not a failed placement classification.
Startup/total values on a final path already include Limit/OFFSET adjustments;
do not interpolate or apply the LIMIT fraction a second time.

In `final-compare`, `fuzzy` names the result at the existing 1.01 fuzz factor.
`keys` is the PathKeysComparison enum (0 equal, 1 new better, 2 old better,
3 different); -1 means cost comparison skipped the key comparison.
`accept_new` describes that pair's decision, not necessarily the result after
all competitors; `remove_old` describes removal of that particular old path.
The observer records no paths that were pruned before the ORDERED hook.
It does not infer a pruning reason merely because two total costs are close.

Component costs include descendants; target costs describe the expressions,
not an additional charge to add to the path total. Use parent/child differences
to investigate costing, and follow the final Limit cost without applying its
fraction twice. `total_only` identifies which comparison policy was used.

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
the effect of the new Sort cost.  The master and path-only policies use plain
`EXPLAIN`; only the patched policy executes the three strategies.  Consequently
every case has one measured winner, and all three planner decisions are scored
against exactly the same timings.  Both GUCs are development aids and are not
intended for a commit-ready patch.

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

Before the patched-policy timing pass, `EXCEPT ALL` verifies that all three
statements return the same multiset.  Each statement gets an untimed warmup.
Timed executions use a rotating order, and both minimum and median executor
time are reported from
`EXPLAIN (ANALYZE, VERBOSE, TIMING OFF, FORMAT JSON)`.  A `plan_only` argument
is available on `topnbench_run()` and `topnbench_compare()` for the two policy
passes that need decisions but no execution; all execution-only output columns
are NULL in that mode.

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
`inconclusive`.  A case is inconclusive when a plan cannot be classified or the
single measured winner is a tie.  Strategy speedups use the late and early
timings from the patched run, so every choice is compared under the same run
conditions.  `path_only_effect` classifies the change from master to path-only;
`width_cost_effect` classifies the change from path-only to patched.  Together
they show which half of the POC changed each decision.

## Experimental Sort width cost

The default script also runs four focused regression probes: the 128-byte
and 256-byte payloads at LIMIT 25%, and the 256kB work_mem query before and
after refreshing width statistics.  `regression.sql` defines the runner and
`regression_report.sql` prints the results; both are included automatically
with psql's `\ir`.  Keep them next to `benchmark.sql` and run the latter as
usual.  These probes do not add cases to the 110-case broad-matrix summary.

Unlike the broad matrix, every policy executes every strategy in these
probes.  Six batches rotate policy order; each call performs a warmup and
three rotated timing samples per strategy.  Equivalence is checked in the
first batch under each policy.  The stale-width probe runs before ANALYZE;
the repaired probe uses the same table after ANALYZE.  The source width,
query text, and effective work_mem are recorded at probe time.

The report shows batch dispersion, actual natural-query time ratios against
master, early/late winners, and surviving automatic-query candidate costs.
Ratios above one mean slower.  The 3% band is a descriptive noise threshold,
not a confidence interval or a statistical significance test.  Natural-query
ratios can include other plan changes; inspect the recorded topology before
attributing the difference solely to projection placement.  Before/after
ANALYZE is also separated in time, so use within-phase policy comparisons.

After timing, separate EXPLAIN ANALYZE executions record complete JSON plans
with BUFFERS and TIMING OFF.  The compact report prints Sort costs, width,
input/output rows, method, memory/disk space, and temporary I/O; verbose mode
also prints full JSON.  These snapshots are diagnostic executions, not the
timed samples.  Buffer counts include descendants and must not be summed
across nodes.  A missing candidate means path pruning/classification did not
expose it; it is not evidence of zero cost.  Temporary diagnostic tables are
available until the psql session ends.

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

## Complete-result comparison experiment (0012)

Rebuild and install the backend after applying this patch on top of 0011,
then restart it before running `benchmark.sql`.  The extension C ABI is
unchanged.  The normal script also runs `final_cost.sql` automatically.

`enable_projection_total_cost` is a temporary, default-on switch.  With both
existing POC switches on, turning this new switch off restores the 0011 final
candidate comparison; it does **not** restore the upstream planner.

The change applies only when the POC built alternative projection targets for
a top-level SELECT with a constant-folded positive ordinary LIMIT, a known OFFSET, and
an incoming tuple fraction of zero (expected complete consumption).  It
compares final LimitPaths by total cost without using startup cost to break a
total-cost tie.  LimitPath already accounts for OFFSET and LIMIT: no second
fraction is applied.  Disabled nodes, pathkeys, parameterization, row count,
parallel safety, and both existing fuzz factors retain their usual roles.
Partial-result cursors, subqueries, WITH TIES, and unknown bounds retain the
old comparison.  A cursor configured for full consumption can use the new
comparison.  The width-cost formula and its coefficients are unchanged.

`final_cost.sql` adds 12 targeted cases: widths 96/128/160/192/256 at 25%,
128 bytes at 20%/30%, two OFFSET splits with the same 25,000 consumed rows,
one high-work/low-LIMIT control, and two cases requesting two parallel workers.
Each case alternates 0011/0012 order over four batches, with three timed runs
per strategy per batch.  The first batch verifies result equality under each
policy.  All three query forms use the same unique leading sort key.
The OFFSET late control deliberately evaluates the skipped rows too.

The summary reports paired natural-query time ratios (`new_vs_old`, lower is
better), batches differing by more than 5%, early/late control timings, and
the minimum workers actually launched by each policy.  A parallel case with
zero launched workers is not evidence about parallel execution.  Four batches
are a repeatability check, not a significance test.  Per-batch results remain
in `topnbench_final_runs` for the session.

Eight plan-equality guards cover partial-result cursors (1% and 10%), a
bounded subquery, WITH TIES, LIMIT 0/ALL, a volatile expression, and an SRF.
They abort if toggling the new switch changes an excluded case's plan.
These checks do not establish that the cost model predicts every winner;
in particular, the stale-width/spill regression remains a separate issue.

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

The seventh argument requests plans only.  It ignores the iteration and
verification work while retaining the same row type, with runtime fields set
to NULL:

```sql
SELECT * FROM topnbench_compare(auto_sql, late_sql, early_sql,
                                5, false, '64kB', true);
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
