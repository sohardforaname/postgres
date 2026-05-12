# HashJoin SwissTable-Inspired Experimental Path Design

## 1. Goal

This document proposes a low-risk implementation plan for experimenting with a SwissTable-inspired lookup layout inside PostgreSQL `HashJoin`, without committing to a full redesign of hash join storage.

The guiding constraints are:

- no semantic change to join results
- no early disruption to batching, outer join behavior, or match tracking
- easy fallback to the current bucket-chain implementation
- instrumentation must remain truthful
- early phases should stay serial and one-batch only

The design intentionally treats this as an experimental alternative path, not as a replacement for the existing `HashJoinTable` implementation.

## 2. Non-goals

This design does not try to do the following in early phases:

- replace `HashJoinTuple` storage
- change `MinimalTuple` ownership or memory-context rules
- support parallel hash in the experimental path
- support multi-batch execution in the experimental path
- redesign skew hash handling
- change `ExecHashIncreaseNumBatches()` semantics

## 3. High-level approach

The safest way to borrow from SwissTable is to change only the candidate-discovery structure for the active in-memory table.

We keep:

- current `HashJoinTuple` payload layout
- current `dense_alloc()` storage in `batchCxt`
- current tuple match flags
- current serial build/probe state machine

We experiment with replacing:

- `buckets.unshared[bucketno] -> linked list head`

with:

- an alternative slot directory that maps probe hashes to a candidate list head

In early phases, the alternative layout does not need to be fully SwissTable. It only needs to move toward that design while staying easy to reason about and easy to disable.

## 4. Phase 1: no semantic change, only add an experimental path

### 4.1 Scope

Phase 1 adds a new alternative bucket layout inside `HashJoinTable`, but enables it only when all of the following are true:

- serial hash join
- `nbatch == 1`
- no parallel hash
- experimental path explicitly enabled

All other cases use the existing implementation unchanged.

### 4.2 Activation policy

Add a narrow experimental gate, preferably a GUC or developer-only switch such as:

- `enable_hashjoin_alt_table = off|on`

The path should also check runtime eligibility:

- `hashtable->parallel_state == NULL`
- `hashtable->nbatch == 1`
- skew path either disabled, or explicitly routed to fallback

Recommended rule:

- if any unsupported feature is detected, silently use the old implementation

That gives us a clean fallback and keeps correctness risk low.

### 4.3 Data structure changes

Extend `HashJoinTableData` with an implementation selector and alternative-layout storage.

Example sketch:

```c
typedef enum HashJoinLookupLayout
{
	HJ_LOOKUP_CHAINED,
	HJ_LOOKUP_ALT_SLOTS
} HashJoinLookupLayout;

typedef struct HashJoinAltSlotData
{
	uint8		ctrl;		/* empty/full/tombstone/special */
	uint8		h2;			/* short fingerprint from hashvalue */
	uint16		pad;
	uint32		hashvalue;	/* full hash for exact match/recheck */
	HashJoinTuple head;		/* head of tuple list for this slot */
} HashJoinAltSlotData;

typedef struct HashJoinAltTableData
{
	int			nslots;
	int			used_slots;
	HashJoinAltSlotData *slots;
} HashJoinAltTableData;
```

And in `HashJoinTableData`:

```c
HashJoinLookupLayout lookup_layout;
HashJoinAltTableData alt;
```

This is deliberately conservative:

- the alternative slot still points to existing `HashJoinTuple`
- duplicate tuples still hang off a linked list
- the old bucket-chain layout remains intact and available

### 4.4 Why Phase 1 should not start with full open addressing of tuples

For a low-risk landing, Phase 1 should avoid:

- moving tuples inline into slots
- changing tuple lifetimes
- replacing duplicate handling

Instead, it should only replace the "find candidate list head" step.

That means:

- build path still allocates `HashJoinTuple` exactly as today
- probe path still walks a linked list of `HashJoinTuple`
- only the top-level directory changes

### 4.5 Build path changes

In `ExecHashTableCreate()`:

- allocate old `buckets.unshared` as today for the default path
- if the experimental path is selected, allocate `alt.slots` instead

In `ExecHashTableInsert()`:

- old path: unchanged
- alt path:
  - compute probe group / slot from `hashvalue`
  - find or create a matching slot
  - prepend tuple to `slot->head`

### 4.6 Probe path changes

Do not rewrite `ExecHashJoinImpl()` in Phase 1.

Instead:

- preserve `hj_CurHashValue`, `hj_CurTuple`, `hj_CurBucketNo`
- add an optional `hj_CurAltSlotNo` if needed
- branch inside `ExecScanHashBucket()` or add a sibling helper such as `ExecScanHashBucketAlt()`

Recommended shape:

```c
if (hashtable->lookup_layout == HJ_LOOKUP_ALT_SLOTS)
	return ExecScanHashBucketAlt(hjstate, econtext);
else
	return ExecScanHashBucket(hjstate, econtext);
```

This keeps the state machine stable and localizes the experiment to build/probe internals.

### 4.7 Fallback rules

Fallback to the old path if:

- `nbatch > 1`
- `parallel_state != NULL`
- skew optimization is active and we do not support it yet
- the alternative allocator/setup fails an invariant

This should be automatic, not user-visible as an error.

## 5. Phase 2: slot stores `hashvalue + tuple list head`

### 5.1 Goal

Phase 2 makes the alternative slot representation explicit:

- slot does not directly own tuple payload
- slot stores metadata and a `HashJoinTuple` list head only
- tuple storage remains in current executor-managed contexts

This is the most important safety boundary for the experiment.

### 5.2 Why not store `MinimalTuple` directly in slots

Do not store `MinimalTuple` inline inside the alternative slot array.

Reasons:

- tuple widths are variable
- slot migration/rehash becomes much harder
- memory-context ownership becomes less obvious
- `HeapTupleHeaderHasMatch` must continue to refer to stable tuple storage

Keeping tuple storage unchanged means:

- `dense_alloc()` can remain the allocator
- `HJTUPLE_MINTUPLE()` keeps working
- all existing tuple-level semantics remain valid

### 5.3 Proposed slot contract

Each alternative slot represents one hash identity bucket in the experimental directory:

- `ctrl`: control byte, for empty/full/deleted states
- `h2`: short hash fingerprint
- `hashvalue`: full hash for exact compare
- `head`: head of duplicate tuple list

This gives us a hybrid model:

- SwissTable-like metadata scanning
- PostgreSQL-style duplicate chain storage

That is likely the best compromise for early implementation.

### 5.4 Duplicate handling

When inserting a tuple:

1. derive `h2` from `hashvalue`
2. probe for a slot whose control byte is occupied and whose `hashvalue` matches
3. if found, prepend tuple to `slot->head`
4. otherwise claim an empty slot and initialize it

This preserves current duplicate semantics:

- one slot per distinct hash identity encountered in the active table
- zero or more tuples chained under that slot

Note that hash equality is still not join equality. Probe still needs:

- full `hashvalue` check
- `hashclauses` evaluation

### 5.5 Memory-context safety

This phase must preserve the current lifetime split:

- slot directory in `batchCxt`
- tuple payloads in `batchCxt`
- join-lifetime metadata in `hashCxt`
- spill state in `spillCxt`

That makes reset behavior simple:

- `ExecHashTableReset()` frees both the slot directory and the tuple chunks by resetting `batchCxt`
- no extra ownership graph is introduced

### 5.6 Suggested helper API

Add explicit helpers so the alternative path stays isolated:

- `ExecHashAltTableAlloc()`
- `ExecHashAltTableInsert()`
- `ExecHashAltTableLookupFirst()`
- `ExecHashAltTableLookupNext()`
- `ExecHashAltTableReset()`

This reduces accidental entanglement with the old path.

## 6. Phase 3: instrumentation must stay accurate

### 6.1 Goal

The experimental path must not distort executor accounting or `EXPLAIN ANALYZE`.

Specifically, the reported values for:

- `spaceUsed`
- `spacePeak`
- `nbuckets`
- `nbatch`

must remain meaningful and comparable to the old path.

### 6.2 `spaceUsed` / `spacePeak`

Today, `spaceUsed` mostly tracks:

- tuple memory in the in-memory table
- bucket-array memory at reporting time

For the alternative layout, include:

- slot directory bytes
- tuple chunk bytes
- any extra metadata arrays

Recommended accounting rule:

- charge slot directory allocation immediately
- charge tuple payload exactly as current path does
- update `spacePeak` after each insertion or resize

### 6.3 `nbuckets` meaning

The existing code and `EXPLAIN` naturally speak in terms of `Buckets`.

For the experimental path, avoid changing that user-facing meaning in early phases.

Recommended approach:

- keep `hashtable->nbuckets` as the user-visible capacity metric
- if the alt structure has `nslots`, choose `nslots` from `nbuckets` deterministically
- report `nbuckets` in a way that remains comparable to the existing implementation

If the slot directory has a different cardinality than the old bucket count, document the mapping clearly in code comments, but do not silently make `Buckets:` incomparable in `EXPLAIN`.

### 6.4 `nbatch` must stay semantically exact

Because Phase 1 and 2 only enable the alternative path for `nbatch == 1`, instrumentation should continue reporting:

- actual `nbatch`
- actual fallback when the path is ineligible

The experimental path must not fake one-batch behavior. If the join becomes multi-batch, it must fall back before execution enters that unsupported state, or disable the experimental path at create time.

### 6.5 EXPLAIN ANALYZE output

`EXPLAIN ANALYZE` should remain honest and familiar.

Recommended additions:

- keep existing output exactly as-is for user-visible fields
- optionally add a developer/debug field only if the project wants it later, such as:
  - `Hash Lookup Layout: alt-slots`

But do not make phase-3 success depend on adding new output. The primary goal is "no distortion."

### 6.6 Validation checklist

For instrumentation, compare experimental and old paths on the same one-batch workload:

- row counts identical
- join output identical
- `nbatch` identical
- `Buckets` within expected configured mapping
- `Memory Usage` not obviously undercounted

## 7. Phase 4: benchmark design

### 7.1 Benchmark goal

The benchmark should answer one narrow question:

Does the alternative lookup layout improve probe/build CPU behavior enough on one-batch workloads to justify further work?

And one broader question:

How much of that benefit disappears once workloads become duplicate-heavy or multi-batch?

### 7.2 Dimensions to cover

The benchmark matrix should include:

- unique key
- low duplicate
- high duplicate
- missing-heavy probe
- hit-heavy probe
- `int4`
- `int8`
- `text`
- one-batch
- forced multi-batch

### 7.3 Core workload classes

#### A. Unique key

Inner side:

- one tuple per join key

Why:

- best case for metadata-driven lookup
- minimal duplicate-chain cost

Expected result:

- experimental path has its best chance to win here

#### B. Low duplicate

Inner side:

- small fanout per key, for example 2 to 4 tuples

Why:

- realistic mixed case
- tests whether slot-level filtering still helps when tuple chains exist

#### C. High duplicate

Inner side:

- many tuples per key, for example 32, 128, or more

Why:

- stresses the fact that `HashJoin` is a multimap
- likely weakens SwissTable-style benefits because candidate discovery is no longer the dominant cost

Expected result:

- improvements should shrink
- may even regress due to slot metadata overhead

#### D. Missing-heavy probe

Outer side:

- many probe keys absent from the inner side

Why:

- best case for fast negative lookup
- important if the alternative path uses compact metadata scanning effectively

Expected result:

- likely strongest probe-side benefit

#### E. Hit-heavy probe

Outer side:

- most probe keys exist in the inner side

Why:

- tests successful lookup cost, tuple materialization cost, and duplicate traversal cost

### 7.4 Data types

#### `int4`

Why:

- smallest common fixed-width case
- reduces confounding from datatype overhead

#### `int8`

Why:

- still fixed-width, but slightly larger and common in analytical workloads

#### `text`

Why:

- more realistic varlena key path
- lets us see whether key hashing/materialization cost dominates the lookup layout change

### 7.5 One-batch vs forced multi-batch

#### One-batch

This is the primary target for the experimental path.

Use:

- enough `work_mem`
- moderate relation sizes

Measure:

- total execution time
- join node time if possible
- memory usage accounting

#### Forced multi-batch

Even though the experimental path is not meant to support multi-batch yet, this workload still matters.

Purpose:

- verify correct fallback
- show whether benchmark gains disappear once the join is forced out of the supported one-batch regime

Expected behavior:

- experimental path disabled or falls back
- semantics identical
- instrumentation remains correct

### 7.6 Suggested benchmark measurements

For each workload:

- planning chosen join type
- execution time
- rows produced
- `Buckets`
- `Batches`
- `Memory Usage`
- optional perf counters if available:
  - cycles
  - instructions
  - branches
  - branch misses
  - cache misses

The most valuable comparisons are:

- old path vs alt path on the same one-batch workload
- alt path eligible vs ineligible
- unique vs duplicate-heavy
- missing-heavy vs hit-heavy

### 7.7 Example benchmark matrix

Keep the first round small and disciplined.

Suggested matrix:

1. `int4`, unique, hit-heavy, one-batch
2. `int4`, unique, missing-heavy, one-batch
3. `int4`, low-duplicate, hit-heavy, one-batch
4. `int4`, high-duplicate, hit-heavy, one-batch
5. `int8`, unique, missing-heavy, one-batch
6. `text`, unique, missing-heavy, one-batch
7. `text`, low-duplicate, hit-heavy, one-batch
8. `int4`, unique, forced multi-batch fallback

That is enough to tell whether the experiment is promising before expanding the matrix.

## 8. Recommended implementation order

### Step 1

Add layout selector and fallback gate:

- new enum in `HashJoinTableData`
- experimental GUC or compile-time guard
- one-batch serial-only activation

### Step 2

Add alternative slot array allocation/reset:

- allocate in `batchCxt`
- reset through existing `ExecHashTableReset()` flow

### Step 3

Implement insertion:

- slot lookup by hash
- create/find slot
- prepend `HashJoinTuple` to `slot->head`

### Step 4

Implement probe helper:

- lookup slot by `hashvalue`
- iterate `slot->head`
- reuse current `ExecQualAndReset()` logic

### Step 5

Hook instrumentation:

- include slot-directory bytes
- preserve `spacePeak`
- validate `EXPLAIN ANALYZE`

### Step 6

Build benchmark scripts and collect first numbers.

Only after that should we consider:

- skew support
- multi-batch support
- more aggressive SwissTable features such as SIMD group scans

## 9. Risk summary

The main risks are:

- hidden semantic coupling with skew or unmatched-tuple paths
- undercounting memory in the alternative layout
- duplicate-heavy workloads erasing lookup benefits
- adding too much complexity before proving the one-batch case

The best mitigation is to keep the early design hybrid and narrow:

- directory experiment only
- tuple storage unchanged
- serial one-batch only
- automatic fallback everywhere else

## 10. Bottom line

The right implementation strategy is not a full SwissTable rewrite. It is a contained experiment:

- new lookup layout
- old tuple storage
- old join semantics
- old path always available

If Phase 1 through 4 show clear wins on one-batch workloads, then we can decide whether it is worth pursuing a deeper design in later work.
