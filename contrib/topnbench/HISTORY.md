> 历史记录：旧文件名和命令仅供追溯。0025 已改回 psql 直接执行、扩展导入文件并统计。
> 当前运行方式请看 README.md，不再单独运行这些旧文件。

# topnbench

## 0020: compare placements without changing the SQL or sort keys

Apply after 0019, rebuild/install PostgreSQL and restart the test server.
The extension C/API is unchanged. `benchmark.sql` includes the new
`projection_placement.sql`; no separate file installation is needed beyond
applying the complete patch in the source tree.

0019 showed that disabling radix changed the early winner at 16/24MB into
late, while heap controls remained stable. It also exposed a measurement
confound: the forced-early rewrite adds sort keys and can use qsort-tuple,
while the natural early query uses qsort-single. This increment measures
both placements of the exact natural query before fitting any new costs.

The temporary enum `debug_projection_placement = auto | early | late`
defaults to auto. It filters the already-legal competing placements before
ORDERED add_path pruning, only for top-level full-Sort paths with parallel
planning disabled and no target SRFs. It does not change sort keys, costs,
target construction or the default policy. Unaffected paths and hooks keep
normal treatment, so this is not a universal force-plan facility; the test
requires the requested actual shape. Existing semantic restrictions on the
POC's early/late competition still apply.

Seven existing cells are reused: cost-1-work-16 at all six memory budgets,
and limit-90pct at 256MB. Radix is enabled throughout. Each of six batches
runs the same natural SQL in auto, early and late modes, using all six mode
orders equally and reversing cell order. There are 126 measure calls, each
with three timed samples; no rewritten early/late SQL is used for timing.
The seven-row summary reports both final Limit costs, paired time ratios,
actual methods and winner counts. Full plans and per-batch measurements
remain in TEMP tables.

Result verification executes each whole SELECT via CTAS under its own mode,
checks its root plan matches the direct SELECT, and compares stored results
with EXCEPT ALL. Wrapping the queries directly inside EXCEPT would otherwise
bypass the top-level-only switch. Guards check one sort key, one serial full
Sort over the million-row Seq Scan and the requested projection position.
Four excluded-shape plan checks cover no LIMIT, volatile output, target SRF
and a bounded subquery. All experiment-local settings restore on error or
success. Final total costs already include LIMIT and must not be prorated
again. This patch introduces no cost coefficient or memory formula changes.

### Compact output and full diagnostics

The default entrypoint suppresses routine command tags/notices, disables
planner/sort tracing and omits large detail tables. Measurements, actual-plan
collection, equivalence checks and correctness guards still execute. It
retains summaries, wrong-choice reports and PASS output. Run normally:

```
psql -X -v ON_ERROR_STOP=1 -f contrib/topnbench/benchmark.sql > topnbench-0020.log 2>&1
```

Use the existing flag for all detailed tables and tracing:

```
psql -X -v ON_ERROR_STOP=1 -v topnbench_verbose=true -f contrib/topnbench/benchmark.sql > topnbench-0020-full.log 2>&1
```

Internal tracing uses the session custom setting `topnbench.trace`, set by
the entrypoint. Standalone heap_release.sql still works without this setting;
set it to on before running that file if transition logs are required.
Trace/diagnostic executions never contribute timing samples. Historical
instructions below describing unconditional trace output predate 0020.


## 0019: separate radix dispatch from sort-memory boundaries

Apply after 0018, rebuild/install PostgreSQL and restart the test server.
This changes tuplesort.c, guc_parameters.dat and guc.h; the extension C/API
is unchanged. `benchmark.sql` includes the new `sort_algorithm.sql`.

The temporary, default-off developer GUC `debug_disable_sort_radix` skips
radix dispatch and uses the existing qsort fallback. It does not change
planner costs, comparator selection, or bounded-heap sorting. This is an
experiment switch, not a recommendation to disable radix sorting. The main
benchmark explicitly starts with the switch off.

Six existing cells are reused: cost-1-work-16 at 4/16/24/32/256MB and
limit-90pct at 256MB. These include external-run sorting, in-memory full
sorting and heap negative controls on the reported PG20 build. Each cell
runs four paired batches, alternating mode and cell order, with three timed
runs per query form and first-batch result checks in both modes: 48 compare
calls in total. The planner policy stays at the full current POC throughout.

Before timing, 36 plain JSON plans must match exactly across modes, including
estimated costs. After all timed batches, 36 traced actual plans must retain
the same Sort method category and input row count. Projection shapes and
serial execution are checked. All settings inside the experiment are local
and restore on success or error. The script requires the TEMP fixtures from
final_cost.sql and sort_boundary.sql; run benchmark.sql in one psql session.

The summary reports paired disabled/default ratios for auto, late and early;
values above one mean disabling radix was slower. It also reports winners
in each mode. Four batches are a repeatability check, not a significance
test. Per-batch data and both sets of plans remain in TEMP tables.

With trace_sort on, `sort dispatch:` records radix-entry, qsort-single or
qsort-tuple at the existing dispatch point. An external sort can produce
several messages, one per run. radix-entry means entry into radix_sort_tuple;
that routine can return for presorted data or use qsort internally. EXPLAIN
can still say quicksort when radix dispatch was used. A bounded heap does
not use this dispatch. Diagnostic timings are excluded from the comparison.

Use the 16/24MB external-early versus heap-late cells to see whether algorithm
choice explains part of the early win. Check the 32/256MB heap cells for
noise, and the 90%/256MB full-sort cell for representation-dependent effects.
No CPU coefficients or planner memory formulas are changed by this patch.


## 0018: release the root discarded during heap construction

Apply after 0017, rebuild/install PostgreSQL and restart the test server.
No extension rebuild is needed. `benchmark.sql` includes the new
`heap_release.sql`; keep capturing stdout and stderr in the same log.

The replacement branch in make_bounded_heap() previously overwrote the old
root without releasing its separately allocated tuple. The replacement
helper only rearranges SortTuple entries. Free the old root first, as the
normal TSS_BOUNDED input path already does. By-value Datum sorts have no
separate tuple to free. Sorting results, costing and method selection are
not intentionally changed; discarded allocations no longer remain until
the sort context is reset. Memory reporting and runtime can change.

The new focused check uses 8193 fixed-width rows and LIMIT 4096, in ascending,
descending and permuted input order. Heap construction occurs on the final
input row. Ascending order discards every additional input; descending order
replaces every old root; the permutation exercises both branches. Both a
one-column Datum Sort and a two-column tuple Sort are checked. It verifies
all returned keys in order and each tuple payload, requires an actual serial
top-N heap over a Seq Scan, then compares memory with the ascending control.
The reported extra_vs_ascending_kb must be zero for all six cases. This
comparison avoids assuming the allocator's chunk size or server word size.

Six traced EXPLAIN ANALYZE executions occur after the existing timing phases.
BEGIN/END markers and 0017's bounded-input/bounded-ready logs expose the
release; diagnostic execution times are not benchmark samples. For the
earlier million-row random case, inspect whether bounded-ready tuple_bytes
falls from 16931360 to 10000000 on the same build/layout. Existing boundary
tests remain in place to measure any runtime effects independently.

Unlike the earlier diagnostic scripts, heap_release.sql is self-contained
and also runs on an unpatched server to reproduce the failure:

```
psql -X -v ON_ERROR_STOP=1 -f contrib/topnbench/heap_release.sql > heap-release.log 2>&1
```

The test uses its own TEMP tables and no extension functions or POC GUCs.
Settings are local to each DO transaction and restore on success or error.
Run on a test instance; the rest of benchmark.sql still rebuilds its fixtures.

## 0017: explain the executor's sort-memory boundary

Apply on top of 0016. Rebuild/install PostgreSQL and restart the test server:
this increment changes `tuplesort.c`, so installing the extension alone is
not sufficient. No extension C/API change or new GUC is needed. The patch
includes `sort_memory.sql`, and `benchmark.sql` runs it last. Capture both
stdout and stderr, for example:

```
psql -X -v ON_ERROR_STOP=1 -f contrib/topnbench/benchmark.sql > topnbench-0017.log 2>&1
```

0016 found that the same 25%-LIMIT query changes winners as work_mem changes.
At 16/24MB, early projection with an external sort beat late projection with
a bounded heap. Also, an estimated K-row footprint that fits work_mem did not
guarantee a bounded heap: tuplesort can exhaust array slots without LACKMEM()
becoming true. Increasing estimated tuple bytes alone can change the selected
path without fixing the CPU cost difference between these algorithms.
Therefore 0017 gathers the missing transition evidence before changing costs.
The planner, sorting decisions and 0015 cost formulas are unchanged.

The existing `trace_sort` switch now emits `sort memory:` lines at:

* `bounded-input`: immediately before converting the accumulated input to a heap;
* `bounded-ready`: immediately after that conversion, with K retained tuples;
* `external-input`: immediately before allocating tapes for the first spill;
* `in-memory-input`: at end of input, before the serial in-memory sort.

Each line gives the current tuple count, bound (-1 if unbounded), array capacity,
`slots_full` and `memory_full`, allowed/used/available bytes, allocated array
bytes, bytes occupied by live array entries, and separately accounted tuple
bytes (also averaged over the current tuples). `memory_full` means LACKMEM(),
i.e. negative available bytes, not merely zero bytes. Array bytes include its
allocation overhead and unused capacity; live bytes are count * sizeof(SortTuple).
For a by-value Datum input, separate tuple bytes should be zero. For a tuple
input, this component includes the charge passed by tuplesort_puttupleslot(),
including its allocator size class/overhead when using an AllocSet context.
These are tuplesort's memory-accounting values, not process RSS, allocator
context totals, or a high-water measurement over the whole execution.

Read each `external-input` line to distinguish slot exhaustion from LACKMEM(),
and check whether the count had reached K or 2*K. Compare `bounded-input` with
`bounded-ready` to see how retaining a larger array affects memory after the
heap has shrunk. This does not assume that replacing K with 2*K is a correct
general planner model. Logs are emitted only when trace_sort is enabled;
there are no new per-tuple counters or calls to inspect memory on the normal
untraced path. Ordinary trace_sort output remains available too.

The benchmark reuses the two fixed query triples and six work_mem points from
0016. After ALL timed sections, it executes just the late and early forms once
per cell: 24 diagnostic EXPLAIN ANALYZE executions, no additional timed matrix.
Each is bracketed by `0017 BEGIN/END` markers; trace_sort is enabled only inside
that interval. Full JSON plans are stored in the TEMP topnbench_memory_plans
table. A 24-row report compares the original 0016 model with the observed method
and memory/disk space; it does not use instrumented execution times as samples.
Different observed methods are reported, not asserted away. Serial one-Sort
shape checks still fail on unexpected plans. All diagnostic GUC changes use
transaction-local settings and unwind on errors as well as normal completion.
The entry point explicitly disables trace_sort before timing begins.

The SQL phase needs the TEMP tables created by sort_boundary.sql, so it cannot
run alone in a new session. If BEGIN/END markers appear without `sort memory:`
lines, the running backend is probably still an older build; SQL alone cannot
verify that this logging-only core change has been installed.

## 0016: work_mem boundaries with fixed queries

Apply on top of 0015 and run `benchmark.sql` as usual. This increment changes
only SQL and documentation; no backend or extension rebuild is needed.
The entry point includes the new `sort_boundary.sql` after `datum_cost.sql`.
Keep all included SQL files alongside benchmark.sql. This script reuses TEMP
catalogs from final_cost.sql and cannot run alone in a fresh psql session.

Two existing query triples (`cost-1-work-16` and `limit-90pct`) are held fixed
while work_mem varies over 4/8/16/24/32/256MB. These cells span the current
model's retained-memory and full-input boundaries for one million rows.
The script runs both 0014 and 0015 costing policies in four paired batches,
reversing cell order and alternating policy order. Each existing compare call
performs warmup and three rotated samples; first batches verify equivalent
results. This adds 96 compare calls across 12 cells, not another broad matrix.
Serial execution, JIT and tracing settings are controlled locally and restored.

After ALL timing, 72 EXPLAIN ANALYZE diagnostics collect both policies and
all three query forms. Full JSON plans are retained in TEMP tables. Guards
require the intended int4 key, one serial Sort, a single-column late input,
and a multi-column early input. An unexpected Sort algorithm does not fail:
it is evidence to inspect. Summary and individual-batch reports show natural
query ratios, actual early/late winners, wrong-choice counts, candidate costs,
and the sort methods recorded during measurement warmups. A 5% band is a
repeatability aid, not a statistical confidence interval.

The diagnostic report independently replays the current cost model's method
branch on each plan's estimates. It explicitly assumes the present x86_64
layout: MAXALIGN=8, aligned heap header=24, SortTuple=24, and Datum plus length
word=12. Other server banners have NULL predictions. These are model sizes, not
measured allocation totals; capacity growth, tape buffers and the executor's
online bounded-heap transition are not simulated. Both policies use their
own size assumptions. Temp I/O and reported memory/disk space are observed
separately. `quicksort` is the EXPLAIN method label and may include specialized
integer/radix sorting; matching labels do not validate comparison CPU costs.

Read mismatches first to identify missing memory/algorithm-boundary effects.
For cells with matching methods but wrong early/late choices, investigate CPU
and projection costs rather than fitting a global Datum discount. These are
projection queries, not isolated Sort CPU benchmarks. Missing candidate costs
still indicate that the hook did not observe both placements after pruning.
No 0015 costs, coefficients, planner rules, GUCs or C interfaces are changed.


## 0015: by-value Datum Sort sizes

Apply on top of 0014. Rebuild/install PostgreSQL and restart the test server.
`cost_sort()` has one additional boolean argument; in-tree callers, including
postgres_fdw, are updated. Rebuild any external extension using that internal
planner API. topnbench.c and the extension SQL function interface are unchanged.
Run `benchmark.sql` as usual; it also includes `datum_cost.sql` automatically.

This step recognizes bounded explicit SortPaths whose single by-value target
expression matches their sole sort key. This includes int4 and other by-value
types without assuming their comparison functions cost the same. Extra resjunk
sort expressions, by-reference values, unbounded Sorts, IncrementalSort and
sorts costed implicitly for joins/append retain the previous model.

For eligible Sorts, input and retained memory use `sizeof(SortTuple)` per row,
while temporary-file volume uses `sizeof(Datum) + sizeof(unsigned int)` per
row. Initial run counts use memory bytes, not tape bytes. This omits allocation
slack, tape buffers, NULL savings and random-access trailing length words;
it is a forward-scan approximation, not an exact executor memory simulator.
The separate MinimalTuple copying term is zero for by-value Datum input;
the existing resident-memory term and comparison/extraction CPU costs remain.
There is no fitted comparison discount, and no change to Result or expression
costs. In-memory CPU gaps and top-N/quicksort differences remain open questions.

The temporary `enable_sort_datum_cost` switch defaults to on and only acts
when `enable_sort_tuple_width_cost` is also on. Turning only the new switch off
restores 0014's costs without removing the existing width model. Existing
master/path-only runs remain unaffected. The older 0011/0012 labels in
`final_cost.sql` identify comparison rules, now with the current sort model;
use the new 0014/0015 section for the direct comparison of this patch.

`datum_cost.sql` adds ten plan guards: int4, int8, float8, nullable int4,
OFFSET, two-column tuples, an extra sort expression, text, numeric and an
unbounded sort. Excluded shapes must retain exactly the same plan, and the
new switch must have no effect with width-cost disabled. Six existing queries
(four lost-benefit cases and the 128/256-byte early controls) then run in four
paired batches under both policies, with equivalence checks, warmups, and
rotated timing samples. This adds 48 compare calls, not another broad matrix.
The report shows both individual batches and paired median ratios; 5% bands
are descriptive thresholds, not confidence intervals. Missing candidate costs
still mean that a placement did not survive to the observing hook.


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
