# HashJoin Memory Hash Table Survey

This note traces how PostgreSQL's executor builds the in-memory hash table for a `HashJoin` and how probe tuples find matching inner tuples. The main implementation lives in:

- `src/backend/executor/nodeHashjoin.c`
- `src/backend/executor/nodeHash.c`
- `src/include/executor/hashjoin.h`
- `src/include/nodes/execnodes.h`

The discussion below focuses first on the regular backend-private path, then points out the main parallel-hash differences.

## 1. The executor roles

At execution time, `ExecHashJoinImpl()` in `nodeHashjoin.c` drives a state machine for the join node. On the first entry in state `HJ_BUILD_HASHTABLE`, it:

1. Creates a `HashJoinTable` with `ExecHashTableCreate()`.
2. Runs the child `Hash` node via `MultiExecProcNode()`.
3. Moves into probing states such as `HJ_NEED_NEW_OUTER` and `HJ_SCAN_BUCKET`.

Relevant code:

- `ExecHashJoinImpl()`: `src/backend/executor/nodeHashjoin.c:225`
- `ExecHashTableCreate()`: `src/backend/executor/nodeHash.c:471`
- `MultiExecHash()` / `MultiExecPrivateHash()`: `src/backend/executor/nodeHash.c:105`, `:139`

The `HashJoinState` fields that carry probe progress are:

- `hj_HashTable`: the active hash table
- `hj_CurHashValue`: hash of the current outer tuple
- `hj_CurBucketNo`: main-table bucket number for the current outer tuple
- `hj_CurSkewBucketNo`: skew-table bucket number if skew optimization applies
- `hj_CurTuple`: last matched inner tuple in the bucket chain

See `src/include/nodes/execnodes.h:2246`.

## 2. Hash table layout in memory

`hashjoin.h` defines the stored tuple representation:

- Each hashed inner tuple is a `HashJoinTupleData`.
- It contains a `next` pointer for the bucket chain and a cached `hashvalue`.
- The actual row follows immediately afterward in `MinimalTuple` format.

Macros:

- `HJTUPLE_OVERHEAD`
- `HJTUPLE_MINTUPLE(hjtup)`

Source: `src/include/executor/hashjoin.h:89`.

The hash table itself is not one huge slab of tuples. Instead:

- The bucket array is an array of `HashJoinTuple` head pointers.
- Tuple payloads are allocated from dense 32KB chunks in `batchCxt`.
- Large tuples get their own dedicated chunk.

This chunk allocator is `dense_alloc()` in `src/backend/executor/nodeHash.c:2954`.

## 3. Memory contexts and lifetime

`ExecHashTableCreate()` sets up three memory contexts:

- `hashCxt`: join-lifetime metadata
- `batchCxt`: current batch's bucket array and tuple chunks
- `spillCxt`: temp-file buffers and spill-related state

This split is important because batch processing repeatedly tears down and rebuilds the in-memory table. `ExecHashTableReset()` simply resets `batchCxt`, reallocates a fresh bucket array, zeroes `spaceUsed`, and forgets the old chunk list.

Relevant code:

- Context setup: `src/backend/executor/nodeHash.c:561`
- Reset per batch: `src/backend/executor/nodeHash.c:2353`
- Lifetime commentary: `src/include/executor/hashjoin.h:28`

## 4. Initial sizing: buckets, batches, and memory budget

`ExecHashTableCreate()` estimates table dimensions by calling `ExecChooseHashTableSize()`.

Inputs include:

- estimated row count
- average tuple width
- whether skew optimization is possible
- whether this is parallel hash

Outputs include:

- `space_allowed`
- `nbuckets`
- `nbatch`
- `num_skew_mcvs`

Important sizing rules:

- `nbuckets` and `nbatch` are powers of two.
- Target load is about `NTUP_PER_BUCKET == 1`.
- If the estimated inner relation plus bucket headers does not fit in memory, the executor plans for multiple batches.
- In multi-batch mode, later batches spill to temporary files and are reloaded one batch at a time.

Key code:

- `ExecHashTableCreate()`: `src/backend/executor/nodeHash.c:499`
- `ExecChooseHashTableSize()`: `src/backend/executor/nodeHash.c:683`

## 5. Building the in-memory table from the inner side

The actual build loop is `MultiExecPrivateHash()`.

For each tuple from the child plan:

1. Fetch a tuple from the Hash node's outer child.
2. Evaluate the hash expression with `node->hash_expr`.
3. If the hash key is null:
   - discard it, or
   - store it in `null_tuple_store` if outer/full/right semantics later need null-extended output.
4. Otherwise:
   - check whether it belongs in a skew bucket with `ExecHashGetSkewBucket()`
   - if yes, insert into the skew hash table
   - if not, call `ExecHashTableInsert()`

Relevant loop: `src/backend/executor/nodeHash.c:139`.

### 5.1 What `ExecHashTableInsert()` does

`ExecHashTableInsert()` is the core insertion routine for non-parallel hash join.

It first computes the destination bucket and batch:

```c
ExecHashGetBucketAndBatch(hashtable, hashvalue, &bucketno, &batchno);
```

Then it chooses between two paths:

- If `batchno == curbatch`, the tuple stays in memory.
- Otherwise, it is written to the inner batch spill file for later processing.

For an in-memory insert, it:

1. Converts the slot to `MinimalTuple`.
2. Allocates a `HashJoinTuple` with `dense_alloc()`.
3. Stores `hashvalue`.
4. Copies the minimal tuple bytes inline after the header.
5. Clears the tuple's match flag.
6. Pushes the tuple onto the front of the target bucket's linked list.
7. Updates memory accounting and may trigger more batching if memory is exceeded.

Source: `src/backend/executor/nodeHash.c:1774`.

### 5.2 Why tuples are inserted at the front

Insertion is a simple singly-linked-list push:

```c
hashTuple->next.unshared = hashtable->buckets.unshared[bucketno];
hashtable->buckets.unshared[bucketno] = hashTuple;
```

So each bucket is a LIFO chain. That keeps insertion O(1) and avoids extra list management.

## 6. Mapping a hash value to bucket and batch

`ExecHashGetBucketAndBatch()` is the key routing function:

- `bucketno = hashvalue & (nbuckets - 1)`
- if `nbatch > 1`:
  - `batchno = rotate_right(hashvalue, log2_nbuckets) & (nbatch - 1)`
- else `batchno = 0`

Source: `src/backend/executor/nodeHash.c:1986`.

Two design points matter here:

- Buckets and batches must be powers of two so routing can use cheap masking.
- When `nbatch` grows at runtime, tuples may move only to later batches, never earlier ones. That property makes rebatching safe without invalidating already-processed work.

## 7. What happens when memory is exceeded

While inserting inner tuples, PostgreSQL tracks `spaceUsed` and compares it against:

- tuple memory already used
- projected bucket-array memory
- `spaceAllowed`

If the hash table grows too large, `ExecHashTableInsert()` calls `ExecHashIncreaseNumBatches()`.

That function:

1. Doubles `nbatch` unless growth has been disabled.
2. Creates or expands `innerBatchFile[]` and `outerBatchFile[]`.
3. Clears the in-memory bucket array.
4. Scans all in-memory tuple chunks.
5. Recomputes each tuple's batch with the new `nbatch`.
6. Keeps current-batch tuples in memory.
7. Spills later-batch tuples to their new batch files.

Source: `src/backend/executor/nodeHash.c:1055`.

This is the mechanism that lets the executor recover when its initial estimate was too optimistic.

## 8. Probing: how outer tuples find matches

Once the build phase ends, `ExecHashJoinImpl()` enters `HJ_NEED_NEW_OUTER`.

`ExecHashJoinOuterGetTuple()` supplies the next probe tuple:

- in batch 0, directly from the outer child plan
- in later batches, from `outerBatchFile[curbatch]`

For each outer tuple:

1. compute `hashvalue` from `hj_OuterHash`
2. discard or defer null-key tuples as required by join semantics
3. compute `hj_CurBucketNo` and `batchno`
4. optionally compute a skew bucket number
5. if the tuple belongs to a later batch, spill it to `outerBatchFile[batchno]`
6. otherwise switch to `HJ_SCAN_BUCKET`

Key code:

- outer tuple fetch: `src/backend/executor/nodeHashjoin.c:1110`
- state-machine transition to probing: `src/backend/executor/nodeHashjoin.c:435`

## 9. Scanning a bucket chain

`ExecScanHashBucket()` performs the actual lookup inside the in-memory hash table.

It starts from:

- `hj_CurTuple->next` if continuing a previous scan, or
- the skew bucket head if skew applies, or
- `buckets.unshared[hj_CurBucketNo]` otherwise

Then it walks the linked list:

1. compare cached `hashTuple->hashvalue` against the current outer hash value
2. if equal, materialize the inner tuple into `hj_HashTupleSlot`
3. set `econtext->ecxt_innertuple`
4. evaluate `hjclauses` with `ExecQualAndReset()`
5. if the hash clauses pass, store the matching `HashJoinTuple` in `hj_CurTuple` and return success
6. otherwise continue down the chain

Source: `src/backend/executor/nodeHash.c:2018`.

Two layers of filtering are involved:

- `ExecScanHashBucket()` checks the hash join key clauses (`hashclauses`).
- Back in `ExecHashJoinImpl()`, the node then evaluates `joinqual` and `otherqual` before deciding whether to emit the joined row.

See `src/backend/executor/nodeHashjoin.c:536`.

## 10. Match tracking

When a probe tuple satisfies `joinqual`, `ExecHashJoinImpl()`:

- marks the outer tuple as matched with `hj_MatchedOuter = true`
- sets the match flag inside the matched inner tuple header if not already set

That per-inner-tuple flag is later used for right/full joins and unmatched-inner scans.

Source: `src/backend/executor/nodeHashjoin.c:580`.

## 11. Multi-batch execution after spills

When the current batch is exhausted, `ExecHashJoinNewBatch()` advances to the next batch.

Its main work is:

1. close no-longer-needed batch files
2. skip batches that can be proven irrelevant
3. set `curbatch`
4. call `ExecHashTableReset()`
5. reload the current inner batch file
6. reinsert those tuples with `ExecHashTableInsert()`
7. rewind the matching outer batch file

Source: `src/backend/executor/nodeHashjoin.c:1279`.

Notice that reloading an inner batch still uses normal insertion logic, so tuples can be pushed further forward again if `nbatch` grows a second time while processing later batches.

## 12. Parallel Hash differences

The broad algorithm is the same, but the storage and coordination differ:

- the hash table is shared in dynamic shared memory
- batch 0 can be allocated up front by one worker
- tuples for later batches live in shared tuplestores instead of per-backend temp files
- probing uses `ExecParallelScanHashBucket()`, which walks shared tuple chains via `ExecParallelHashFirstTuple()` / `ExecParallelHashNextTuple()`

Key entry points:

- `MultiExecParallelHash()`: `src/backend/executor/nodeHash.c:234`
- `ExecParallelHashTableInsert()`: `src/backend/executor/nodeHash.c:1865`
- `ExecParallelScanHashBucket()`: `src/backend/executor/nodeHash.c:2079`
- `ExecParallelHashJoinNewBatch()`: `src/backend/executor/nodeHashjoin.c:1420`

The important conceptual difference is that parallel hash keeps the same bucketed-probe model, but replaces backend-private arrays and `BufFile` batches with shared-memory coordination objects and barriers.

## 13. End-to-end summary

The in-memory HashJoin table is a bucket array whose entries point to linked lists of `HashJoinTuple` records allocated from dense per-batch chunks. Building works by hashing inner tuples, routing each one to a bucket and batch, storing current-batch tuples in memory, and spilling later-batch tuples. Probing works by hashing each outer tuple the same way, locating the correct bucket, and walking that bucket's chain while checking cached hash values and join-key quals before evaluating the rest of the join conditions.

That design gives PostgreSQL:

- O(1)-style bucket insertion
- fast bucket selection with power-of-two masking
- safe runtime rebatching when memory estimates are wrong
- reuse of the same lookup path for first-batch and reloaded-batch probing

## 14. Could HashJoin use a SwissTable-style design?

Yes, in principle, but it would be a meaningful redesign rather than a local optimization.

Here "SwissTable" means the open-addressing family used by Abseil and related hash tables:

- metadata bytes ("control bytes") stored separately from payloads
- SIMD-friendly scans over small groups of slots
- robin-hood style or related probe-discipline choices
- very fast negative lookups and reduced pointer chasing for successful lookups

PostgreSQL's current `HashJoin` table is almost the opposite:

- separate bucket head array
- linked chains of `HashJoinTuple`
- payload stored out-of-line in dense chunks
- explicit batch spilling and rebatching

So the question is not "can we replace one lookup primitive with another?" but "can the executor's whole hash-join storage model be adapted to open addressing?"

## 15. Where SwissTable could help

For an in-memory, single-batch join, a SwissTable-like layout has some attractive properties.

### 15.1 Faster bucket probing

The current lookup path in `ExecScanHashBucket()` walks a pointer chain:

- load bucket head
- follow `next` pointers
- compare cached hash values
- materialize candidate tuples
- evaluate hash clauses

That can suffer from cache misses when chains are long or tuples are scattered across chunks.

A SwissTable-like table could improve this by:

- scanning compact control bytes first
- rejecting most non-matches before touching tuple payloads
- reducing branchy pointer chasing
- making negative probes especially cheap

This is most appealing for inner joins where a large share of probes find no match, or only a small number of candidates.

### 15.2 Better CPU cache locality

The current design stores tuple payloads densely, which is good, but the linked-list topology still makes traversal less cache-friendly than a compact slot array. A SwissTable-style slot directory could keep:

- control bytes
- short hash fingerprints
- payload references or inline payload descriptors

close together, improving locality during probe.

### 15.3 Potentially simpler bucket growth

When `nbatch == 1`, PostgreSQL already has logic to grow the logical bucket count. A SwissTable-style array could, in theory, support growth by rebuilding into a larger slot array, which may be simpler than managing both linked chains and bucket heads.

## 16. Where SwissTable clashes with PostgreSQL HashJoin

The harder part is not lookup speed. It is fitting SwissTable into PostgreSQL's executor constraints.

### 16.1 Multiple matches per join key are common

Hash join is not a key-value map. A single hash key often corresponds to many inner tuples.

SwissTable is most natural for:

- set membership
- unique-key maps
- low-multiplicity associative containers

PostgreSQL hash join needs a multimap. That means each slot would need to represent either:

- one tuple, with duplicate keys occupying many independent slots, or
- a head entry pointing to an overflow structure containing duplicates

The first option makes lookup more awkward because the executor must continue scanning after the first equal key. The second option reintroduces an auxiliary chain or vector, which gives back some of the current design's complexity.

### 16.2 Tuples are variable-width executor objects

The current layout handles arbitrary `MinimalTuple` sizes naturally:

- allocate a `HashJoinTuple`
- copy the tuple bytes after the header
- link it into the bucket chain

A SwissTable-style design would not want large variable-width tuples inline in the slot array because that would:

- bloat probe groups
- reduce SIMD density
- complicate deletion or relocation during rehash

So in practice the slot would probably still point at tuple storage in chunks. That means the main gain would come from replacing bucket chains with compact probe metadata, not from eliminating indirect payload access entirely.

### 16.3 Rebatching is much less natural with open addressing

Today, if memory pressure forces `nbatch` to grow, `ExecHashIncreaseNumBatches()` can:

1. rescan all in-memory tuples
2. recompute their batch number
3. keep current-batch tuples
4. spill later-batch tuples

This works cleanly because tuples live in chunk storage and bucket membership is just linked-list topology layered on top.

With SwissTable-style open addressing, the in-memory placement of each tuple is tied much more tightly to the table's slot geometry. Rebatching would likely require:

- scanning every occupied slot
- copying or reinserting survivors into a fresh slot array
- handling tombstone/control-byte state carefully

That is possible, but it makes the already-complex rebatching path more intrusive.

### 16.4 Outer/full/right join match tracking still needs tuple identity

PostgreSQL marks matched inner tuples by setting a flag in the tuple header:

- see the logic in `ExecHashJoinImpl()` discussed above

That is convenient because tuple identity persists independent of bucket structure. A SwissTable design would still need stable tuple objects, or some equivalent match bitmap keyed to stable tuple IDs. So the executor would still need durable per-tuple state outside just the control-byte array.

### 16.5 Load factor constraints may fight work_mem

SwissTable-style tables usually want a bounded load factor to preserve probe performance. PostgreSQL hash join already operates close to memory limits and sometimes survives by:

- spilling later batches
- accepting imperfect load behavior
- dynamically changing batch count

A SwissTable design might need more slack space in the active table than the current chained design, which could:

- increase memory pressure in `work_mem`
- trigger batching sooner
- reduce or erase the expected CPU win for some workloads

### 16.6 Skew optimization does not fit cleanly

The current design has a separate skew table for selected MCVs. That already creates a two-path lookup model:

- skew bucket
- regular hash table

It is not impossible to retain that with SwissTable, but the design becomes less elegant. You would likely end up with:

- one SwissTable-like structure for regular tuples
- one special structure for skew tuples

which reduces the simplicity benefit.

## 17. A more realistic hybrid design

If PostgreSQL wanted to borrow from SwissTable, the most plausible path is probably not "replace everything with open addressing." A better fit may be a hybrid:

- keep tuple payloads in dense batch-owned chunks
- keep batch spilling and rebatching logic
- keep stable tuple objects for match flags
- replace the bucket-head-plus-chain lookup structure with a compact metadata directory

For example, each active batch might use:

- a control-byte array
- a slot array storing short hash fingerprints plus a pointer or offset to `HashJoinTuple`
- probing by group scan rather than linked-list traversal

That would preserve:

- current tuple storage and lifetime rules
- spill/reload model
- match-flag semantics

while improving:

- negative probe speed
- cache locality during candidate discovery

In other words, the "SwissTable" influence would mainly be on candidate indexing, not on tuple ownership.

## 18. What would be hardest to get right

The highest-risk areas in a PostgreSQL implementation would be:

- duplicate-key behavior for joins with many equal keys
- memory accounting under `work_mem`
- interaction with dynamic `nbatch` growth
- preserving outer/right/full join unmatched-tuple semantics
- keeping the parallel-hash path efficient and not much more complicated

Parallel hash is especially important here. The current parallel implementation already has shared-memory allocation, repartitioning, and barrier choreography. A SwissTable-like open-addressed structure in shared memory would likely be significantly more delicate than the current shared bucket-chain design.

## 19. Bottom line

Using SwissTable ideas in `HashJoin` is plausible, especially for the in-memory probe structure, and it could improve CPU efficiency on lookup-heavy workloads. But a full SwissTable replacement is not a drop-in fit for PostgreSQL's executor because `HashJoin` is:

- a multimap, not a simple key-value table
- batch-spilling and rebatching aware
- built around variable-width `MinimalTuple` payloads
- dependent on stable per-tuple match state

So the best design direction is probably:

- keep PostgreSQL's current tuple storage and batch model
- borrow SwissTable-style control-byte/group-probe ideas for candidate discovery

rather than trying to force the whole join table into a conventional SwissTable container model.
