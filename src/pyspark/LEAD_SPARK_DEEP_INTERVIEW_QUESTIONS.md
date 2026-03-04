# Lead-Level Apache Spark: Deep Interview Questions

**Principal-level focus:** Architecture, internals, performance tuning, production design. No coding—concepts only.  
**Use:** 40–60 questions with detailed answers, real-world scenarios, common mistakes, and Lead-level expectations.

---

# Part 1: Core Architecture

---

## Q1. Walk through Spark’s execution model from your code to tasks on executors. What role does the driver play at each step?

**Answer:**  
The driver runs your application (main method / notebook). It (1) builds the logical plan from transformations, (2) passes it to the Catalyst optimizer to produce an optimized physical plan, (3) converts the physical plan into a DAG of stages, (4) splits stages into tasks (one per partition), and (5) schedules tasks to executors via the cluster manager. Executors run tasks, store shuffle data and caches, and report status back. The driver never holds the bulk of the data; it only holds metadata and the DAG. On action (e.g. `count()`, `write`), the driver triggers execution and may collect small results (e.g. `collect()`); for distributed results it coordinates where data is written.

**Real-world:** In a nightly ETL, the driver runs on a long-lived node; if the driver dies, the entire run fails and must be restarted. Understanding that the driver is single point of coordination explains why driver OOM (e.g. collecting too much or broadcasting huge tables) kills the job.

**Common mistakes:** Saying “the driver processes data” or that “data is sent to the driver for processing.” Confusing the driver with a worker.

**Lead-level:** Tie execution model to failure domains (driver vs executor), to broadcast (driver sends build side to executors), and to why driver memory and driver-side collects matter for production.

---

## Q2. What exactly is the DAG, and how do stages and tasks relate to it?

**Answer:**  
The DAG (Directed Acyclic Graph) is the logical/physical execution plan. **Vertices** are RDDs (or DataFrame partitions); **edges** are dependencies. A **narrow dependency** (e.g. map, filter) means each child partition depends on one parent partition; a **wide dependency** (e.g. shuffle from groupBy or join) means each child partition can depend on many parent partitions. Spark groups the DAG into **stages** at wide boundaries: within a stage there are only narrow dependencies, so all tasks in that stage can run independently and in parallel. A **task** is the unit of work: one task per partition in that stage, running the same code on different data. So: DAG → split at shuffles into stages → each stage has N tasks (N = number of partitions in the stage’s output RDD).

**Real-world:** In the Spark UI you see “Stage 1” (e.g. read + map + filter) then a shuffle, then “Stage 2” (e.g. aggregate). Stage 2 cannot start until Stage 1’s shuffle write is done. Debugging slow jobs often means finding which stage is slow and whether it’s skew, too many tasks, or I/O.

**Common mistakes:** Saying “one task per executor” or “one stage per transformation.” Not linking stages to shuffle boundaries.

**Lead-level:** Explain how stage boundaries affect pipelining, why a single wide transformation can dominate runtime, and how AQE can change stage boundaries (e.g. coalesce after shuffle).

---

## Q3. Why does Spark use lazy evaluation, and what are the implications for correctness and performance?

**Answer:**  
Lazy evaluation means transformations only build a lineage (graph); they do not execute until an **action** is called. Benefits: (1) **Optimization**—Catalyst can see the full plan (e.g. push filters and projections down, combine operations). (2) **Efficiency**—only the data needed for the action is computed; unused branches can be pruned. (3) **Control**—you can coalesce, repartition, or cache at the right place in the lineage. Implications: (1) **Side effects** in transformations (e.g. logging, external API calls) run multiple times if the RDD is reused (each action re-runs the lineage unless you persist). (2) **Correctness**—assuming “this runs once” in a transformation can be wrong. (3) **Debugging**—errors appear at action time, not at the line where you wrote the transformation.

**Real-world:** A job that writes and then reads from the same path in one application may see empty or partial data if the read is on a lazy path that hasn’t been triggered yet, or may re-execute the write path if there’s no persist—leading to confusion about “did my write finish?”

**Common mistakes:** Saying “lazy is always better” without mentioning side effects and recomputation. Not knowing that multiple actions on the same RDD without cache cause recomputation.

**Lead-level:** Tie lazy evaluation to persistence strategy (when to cache to avoid recomputation), to debugging (stack traces at action), and to optimizer opportunities (predicate pushdown, projection).

---

## Q4. What is the Catalyst optimizer, and what kinds of optimizations does it perform?

**Answer:**  
Catalyst is Spark’s query optimizer for the DataFrame/Dataset API. It works on a logical plan (tree of relational operators), applies **rules** in phases: (1) **Analysis**—resolve attributes, types, tables. (2) **Logical optimization**—e.g. predicate pushdown, projection pruning, constant folding, null propagation, simplifying expressions. (3) **Physical planning**—choose join algorithms (broadcast vs sort-merge), generate multiple physical plans. (4) **Cost-based optimization (CBO)**—when statistics are available, pick the plan with lower cost (e.g. join order). Output is an optimized physical plan that becomes the DAG. So Catalyst does both rule-based (e.g. push filter below join) and cost-based optimizations.

**Real-world:** Adding `df.filter("date = '2024-01-01'")` before a join can allow Catalyst to push the filter to the scan (predicate pushdown) so less data is read and shuffled. Without Catalyst (e.g. raw RDD), you’d have to do that manually.

**Common mistakes:** Saying “Catalyst optimizes SQL only” (it optimizes DataFrame/Dataset too). Not knowing that UDFs can block some optimizations (black box to Catalyst).

**Lead-level:** Name specific optimizations (predicate pushdown, column pruning, constant folding), mention that UDFs limit optimization, and link to CBO and stats (ANALYZE TABLE).

---

## Q5. What is the Tungsten engine, and how does it improve performance?

**Answer:**  
Tungsten is Spark’s internal execution backend (since 1.5/2.0). Main pieces: (1) **Off-heap memory** for certain structures to reduce GC pressure and allow larger working sets. (2) **Unsafe row format**—columnar-like in-memory layout (cache-friendly, less object overhead than Java objects). (3) **Whole-stage code generation**—instead of an iterator of operators (filter then project then …), Tungsten can generate a single tight loop (e.g. one function that does filter + project in one pass), reducing virtual calls and improving CPU cache use. So Tungsten addresses both memory (layout, off-heap) and CPU (codegen). It applies to both batch and shuffle (e.g. sort used in shuffle).

**Real-world:** Jobs that used to spend 30% in GC can see much less GC after tuning and with Tungsten’s layout; whole-stage codegen can make scan-filter-project stages several times faster.

**Common mistakes:** Confusing Tungsten with “Spark is written in C” or thinking it only applies to SQL. Not connecting it to shuffle (Tungsten also improves serialization in shuffle).

**Lead-level:** Separate “memory layout / off-heap” from “whole-stage codegen,” and mention that this is why the Structured API often beats hand-written RDD code.

---

## Q6. Explain whole-stage code generation. Why can it make a stage much faster?

**Answer:**  
Traditional execution uses a chain of iterators: each operator (e.g. Filter, Project) is a separate class; the engine calls `next()` through the chain, so each row incurs many virtual method calls and poor CPU cache locality. **Whole-stage code generation** compiles a whole pipeline (e.g. Scan + Filter + Project) into **one** generated function (e.g. Java bytecode). That function is a tight loop with no operator boundaries: one pass over the data, minimal branches, better instruction cache and CPU pipeline. So instead of N operators × M rows of virtual calls, you get one loop. It applies when the pipeline is “codegen-friendly” (no complex UDFs or features that can’t be codegen’d). In the Spark UI you may see “WholeStageCodegen” in the physical plan.

**Real-world:** A scan-filter-select stage might go from 10 minutes to 3 minutes after ensuring no UDF blocks codegen and partition count is reasonable.

**Common mistakes:** Thinking every stage is codegen’d (some fall back to interpreted). Not knowing that UDFs often disable codegen for the surrounding pipeline.

**Lead-level:** Link codegen to “why DataFrame is faster than RDD” and to the limitation that UDFs break codegen.

---

## Q7. Driver vs Executor: what runs where, and what happens when each fails?

**Answer:**  
**Driver:** Runs your `main()` / application code; holds the SparkContext/SparkSession; builds the DAG; schedules tasks; collects small results (e.g. `collect()`, `take()`); sends broadcast data to executors. Single process; if it crashes, the entire application fails. **Executor:** Runs tasks; holds cached data and shuffle files; reports heartbeats and task status to the driver. Many executors; if one fails, the driver can retry its tasks on other executors (and with dynamic allocation, request a new executor). So: “business logic and scheduling” on driver, “data and task execution” on executors. Driver OOM usually means too much data collected or a huge broadcast; executor OOM means too much data per partition or too small executor memory.

**Real-world:** A job that does `collect()` on a large result will OOM the driver. A job with severe skew will OOM or timeout a few executors (stragglers). Recovery: driver restart from cluster manager; executor failure is retried by Spark.

**Common mistakes:** Saying “executors send data to the driver for processing” or “driver does the shuffle.” Confusing driver memory with executor memory when debugging OOM.

**Lead-level:** Map failure modes (driver vs executor OOM, executor lost) to causes and mitigations (reduce collect, broadcast size, skew handling, executor sizing).

---

# Part 2: Shuffling & Joins

---

## Q8. What is a shuffle in Spark, and why is it expensive? When exactly does it happen?

**Answer:**  
A **shuffle** redistributes data so that all records with the same key (for a given operation) end up on the same partition. It’s needed for **wide** operations: `groupBy`, `reduceByKey`, `join` (when neither side is broadcast), `distinct`, `repartition`, `sortByKey`, etc. Cost: (1) **Shuffle write**—each task serializes and writes its partition’s contribution to local disk (or off-heap), possibly with sorting. (2) **Network**—next-stage tasks read from remote executors. (3) **Shuffle read**—deserialize and possibly merge/sort. So you pay with disk I/O, network, and CPU. Shuffle is often the dominant cost in a job; minimizing or avoiding it (e.g. broadcast, reduce data before shuffle) is key.

**Real-world:** A `groupByKey` without aggregation shuffles all key-value pairs; `reduceByKey` can combine locally before shuffle, so it’s usually better. In SQL, a sort-merge join causes shuffle on both sides; broadcast join avoids shuffle for the large side.

**Common mistakes:** Saying “join always shuffles” (broadcast join avoids shuffling the large side). Not distinguishing shuffle write from shuffle read in the UI.

**Lead-level:** List which operations cause shuffle, explain write vs read, and tie to UI metrics (shuffle read/write size, skew).

---

## Q9. Describe sort-based shuffle and how shuffle files are produced and consumed.

**Answer:**  
**Sort-based shuffle** (default since Spark 1.2): Each map task writes its output into a single file (or a few files when there are many reducers). Data is **sorted by partition ID** (and optionally by key within partition for sort-merge join or orderBy). The file is an index + data: downstream tasks know which offset to read for their partition ID. So each mapper produces one (or a few) shuffle file(s); each reducer reads from many mappers (one segment per mapper). Benefits over the older “hash shuffle”: fewer files (no N×M small files), better for large shuffle and SSDs. **Shuffle files** are stored locally on the executor (or in off-heap); they are deleted after the job (or after retention if shuffle service is on for dynamic allocation). If an executor is lost before the consumer reads, the driver resubmits the map tasks.

**Real-world:** On a 1000×1000 task shuffle, sort-based shuffle gives 1000 map output files total (one per map task), not 1M files. Shuffle service allows executors to be removed after map phase while reducers still fetch data.

**Common mistakes:** Thinking every reducer reads the whole map output (they only read their partition IDs). Not knowing that shuffle can spill to disk if memory is full (within the map task).

**Lead-level:** Explain “one file per map task” with index, and link to shuffle service and dynamic allocation (why shuffle files must outlive the executor).

---

## Q10. When does shuffle spill to disk, and what are the performance implications?

**Answer:**  
During **shuffle write**, each task accumulates records in memory; when the in-memory buffer exceeds a threshold, it **spills** to disk (serialized). After all input is processed, the task may merge sorted spill files and the in-memory buffer to produce the final shuffle output. So spill happens when the amount of data a single map task is sending (per partition or total) exceeds the memory allocated for shuffle (e.g. `spark.shuffle.spill` enabled and buffer full). **Implications:** (1) Disk I/O during the map task—slower than pure memory. (2) If spill is huge or very frequent, the task is I/O-bound and GC may spike. (3) In the UI, “Spill (Memory)” and “Spill (Disk)” show how much was spilled. Reducing partition size (e.g. more partitions) or increasing executor memory (or shuffle memory fraction) can reduce spill.

**Real-world:** A highly skewed partition causes one map task to produce a huge amount of data for one key; that task spills a lot and becomes a straggler. Fix: salting or AQE skew split.

**Common mistakes:** Confusing “shuffle write to disk” (normal) with “spill” (overflow of in-memory buffer). Thinking spill is always bad (some spill is acceptable; excessive spill is the problem).

**Lead-level:** Distinguish normal shuffle disk write from spill, tie spill to memory pressure and skew, and mention tuning (partition count, `spark.memory.fraction`, off-heap).

---

## Q11. When do broadcast joins work well, and what are the thresholds and pitfalls?

**Answer:**  
**When they work:** One join side is **small** enough to fit in executor memory (and ideally in the broadcast size limit). The small side is sent once per executor; the large side is not shuffled. So you avoid shuffle for the big table and reduce network and stage size. **Thresholds:** `spark.sql.autoBroadcastJoinThreshold` (default 10 MB)—Spark may choose broadcast if the logical plan’s size estimate is under this. You can force broadcast with `broadcast(small_df)`. **Pitfalls:** (1) **OOM**—if the “small” table is actually large or compressed on disk but large in memory, every executor can OOM. (2) **Driver** builds the broadcast; if the table is big, driver can OOM. (3) **Broadcast timeout**—building/sending can be slow for larger tables. (4) **Stale stats**—optimizer may broadcast a table that grew. Safe approach: only broadcast when you know the size (e.g. small dimension table); monitor executor memory; use explicit `broadcast()` with known-small DataFrames.

**Real-world:** A 50 MB dimension table is usually safe to broadcast; a 500 MB “dimension” that grew can OOM all executors. Fix: increase partition count for the large side and use sort-merge, or sample the small table and check size.

**Common mistakes:** Setting `autoBroadcastJoinThreshold` very high “to be safe” and causing OOM. Not distinguishing driver vs executor memory for broadcast.

**Lead-level:** Explain driver’s role in building broadcast, give a safe size range (e.g. tens of MB), and when to prefer sort-merge over broadcast.

---

## Q12. Compare sort-merge join, broadcast join, and shuffle hash join. When does Spark choose each?

**Answer:**  
- **Broadcast join:** Small side is sent to all executors; large side is not shuffled. Chosen when one side is under broadcast threshold (or forced). No shuffle for the large side.  
- **Sort-merge join:** Both sides are shuffled by key and sorted; then merged like a merge join. Default for large–large joins. Two shuffles (one per side); robust and scalable.  
- **Shuffle hash join:** One side is shuffled and built into a in-memory hash table on each partition; the other side is shuffled and probed. Spark can use it when the build side is small enough per partition (e.g. after shuffle). In Spark 2.3+, sort-merge is default; hash join can be used in some cases (e.g. `JoinSelection` rules).  

**Selection:** Catalyst’s `JoinSelection` uses size estimates: if one side is small enough, broadcast; else sort-merge (and with AQE, may switch to broadcast at runtime if build side turns out small). Shuffle hash is used when the build side of a shuffled partition fits in memory (rarely the dominant path in modern Spark).

**Real-world:** Most large–large joins are sort-merge; adding a small lookup table and setting broadcast or threshold gives broadcast and often a big win.

**Common mistakes:** Saying “Spark always uses sort-merge” or “hash join is never used.” Not knowing AQE can change join type at runtime.

**Lead-level:** Name all three, explain sort-merge as default for large–large, and describe how AQE can optimize join strategy at runtime.

---

## Q13. How would you design join strategy selection for a pipeline with one huge fact table and several dimension tables?

**Answer:**  
**Strategy:** (1) **Broadcast** all dimensions that are small (e.g. &lt; 50–100 MB in memory)—no shuffle for the fact table for those joins. (2) For dimensions that are too large to broadcast, use **sort-merge**; optionally **repartition** the fact table once by the join key and reuse that partition for multiple joins to the same key to avoid repeated shuffles. (3) **Order of joins**—join to the most selective dimension first (or the one that reduces data most) to shrink the fact table before other joins (Catalyst may reorder with CBO if stats are present). (4) **Partitioning**—if the fact table is already partitioned by date, filter by date first to reduce data; if a dimension is bucketed by key, bucketed join can avoid shuffle. (5) **Skew**—if a dimension key is very skewed (e.g. “unknown” or “default”), consider splitting that key (e.g. salting) or handling it separately.

**Real-world:** Fact table 100 GB, dim1 10 MB, dim2 50 MB, dim3 2 GB. Broadcast dim1 and dim2; sort-merge dim3; filter fact by latest partition first; repartition fact by `dim3_key` once if you join fact to dim3 multiple times.

**Common mistakes:** Broadcasting a “dimension” that is actually large; joining without filtering first; not considering skew on a high-cardinality key.

**Lead-level:** Combine broadcast + sort-merge + partitioning + filter order + skew in a single coherent design.

---

## Q14. What are skewed joins, and what mitigation strategies would you use in production?

**Answer:**  
**Skewed join:** A few keys have much more data than others. After shuffle, a few partitions get a huge share of data; tasks for those partitions are stragglers (slow or OOM). **Mitigations:** (1) **Broadcast** the skewed side if it’s small (e.g. one key with lots of rows but small total size). (2) **Salting:** Add a random suffix to the key so the heavy key is split across many partitions (e.g. `key || "_" || rand(0, N)`), join, then aggregate again by original key. (3) **Split:** Identify hot keys (e.g. from stats or sampling); filter into “hot” and “normal,” join hot with a dedicated strategy (e.g. broadcast or salt), join normal with standard join, union. (4) **AQE skew join** (Spark 3): enable `spark.sql.adaptive.skewJoin.enabled`; AQE can split skewed partitions and run additional tasks so one partition’s work is parallelized. (5) **Increase shuffle partitions** so that even skewed keys are split across more tasks (helps only if the key has many distinct values; one huge key still lands in one partition without salting).

**Real-world:** A join on `user_id` where 5% of users have 80% of events causes a few tasks to take hours. Salting `user_id` (e.g. 10 salts) spreads that 80% across 10 partitions; after join you aggregate by `user_id` again.

**Common mistakes:** Only increasing shuffle partitions (doesn’t fix one-key skew). Salting without a second aggregation step (wrong results). Not measuring skew before and after.

**Lead-level:** Describe at least two strategies (e.g. salt + AQE), when each applies, and how to detect skew (UI, stats).

---

## Q15. How does Adaptive Query Execution (AQE) change join and shuffle behavior?

**Answer:**  
**AQE** (Spark 3+) re-optimizes the query at runtime using statistics from completed stages. (1) **Coalesce shuffle partitions:** After a shuffle, if many partitions are small, AQE can coalesce them so the next stage has fewer, larger tasks (less overhead). (2) **Join strategy:** If the plan said sort-merge but the build side turns out small after a filter, AQE can switch to broadcast join. (3) **Skew join:** AQE can detect skewed partitions (e.g. by size) and split them into multiple tasks so the skewed partition is processed in parallel. So: same application code can get fewer shuffle partitions, better join type, and automatic skew handling. Enable with `spark.sql.adaptive.enabled=true` (default in Spark 3).

**Real-world:** A job that used to need manual `repartition(2000)` might run well with default 200 and AQE coalescing; a skewed join might complete without custom salting when AQE skew join is on.

**Common mistakes:** Disabling AQE “because we tune manually” (you can still tune; AQE adds a safety net). Not knowing that AQE works at runtime (so plan in UI can differ from initial plan).

**Lead-level:** List the three main AQE features (coalesce, join switch, skew) and when to rely on AQE vs when to still tune (e.g. known skew with custom salt).

---

# Part 3: Partitioning

---

## Q16. Narrow vs wide transformations: define them and explain impact on scheduling and failure recovery.

**Answer:**  
**Narrow:** Each output partition depends on at most one input partition (e.g. `map`, `filter`, `mapPartitions`). No shuffle; data stays on the same executor. Pipeline can run in one stage; failure can be recovered by re-running only the lost partition’s tasks. **Wide:** Each output partition can depend on many input partitions (e.g. `groupBy`, `join`, `distinct`). Requires shuffle; failure in a wide stage may require re-running the entire stage (all map tasks, then all reduce tasks). So narrow = cheap, local, easy recovery; wide = expensive, global, stage boundary.

**Real-world:** A job with 10 narrow maps then 1 groupBy has 2 stages; the groupBy stage is the one to optimize (shuffle, skew). Recovery of one failed executor in the first stage only re-runs those map tasks.

**Common mistakes:** Calling `reduceByKey` narrow (it’s wide). Saying “wide means more data” (it means dependency pattern, not size).

**Lead-level:** Tie to DAG/stages and to why we minimize wide ops and optimize shuffle.

---

## Q17. Repartition vs coalesce: when to use each, and what are the exact semantics?

**Answer:**  
**Repartition(n):** Full shuffle; data is redistributed into `n` partitions using a hash partitioner (default). Use when you need **more** partitions (e.g. after a filter that left few rows) or when you want to **balance** data (e.g. before a write to get even file sizes). **Coalesce(n):** No full shuffle; Spark **merges** existing partitions so total count goes down to `n`. No data movement across executors for the merge; some executors may end up with multiple partitions. Use when **reducing** partition count (e.g. before writing 1 or 10 files). Coalesce cannot increase partitions; repartition can increase or decrease but always does a shuffle. So: “reduce partitions without shuffle” → coalesce; “increase or rebalance” → repartition.

**Real-world:** Writing to a single file: `coalesce(1)` (or `repartition(1)` if you insist on a single partition, at shuffle cost). After reading 1000 partitions and filtering to 1% of data, `repartition(100)` can balance work for the next stage.

**Common mistakes:** Using `repartition(1)` to “merge files” without considering the shuffle cost. Using coalesce to “balance” (it only merges; it doesn’t rebalance).

**Lead-level:** Explain that coalesce merges (possibly unevenly); repartition rebalances; give production examples for both.

---

## Q18. When would you use a custom partitioner (e.g. range or custom Python/RDD partitioner)?

**Answer:**  
**Hash partitioner (default):** `key.hashCode() % numPartitions`; even spread if keys are uniform; skewed if some keys dominate. **Range partitioner:** Partitions by key order (e.g. range of values per partition); useful for range queries, sort order, or when you want contiguous keys in the same partition. **Custom partitioner (RDD):** You implement `getPartition(key)` so you can assign keys to partitions by custom logic (e.g. keep certain keys together, or avoid known hot keys). Use when: (1) You need range partitioning (e.g. downstream merge or range scan). (2) You know key distribution and want to avoid skew (e.g. custom partitioner that spreads hot keys). (3) Domain-specific grouping (e.g. partition by tenant in a multi-tenant app). DataFrame API doesn’t expose custom partitioners directly; you use RDD or repartition by expression (e.g. `repartitionByRange` or `df.repartition(n, "key")` which uses hash).

**Real-world:** Writing data that will be queried by time range: `repartitionByRange(n, "ts")` so each partition holds a time range and readers can skip partitions. Custom RDD partitioner to put “premium” tenants in dedicated partitions for isolation.

**Common mistakes:** Thinking DataFrame has a generic “custom partitioner” API (it’s hash or range by column). Using range when hash would suffice and is cheaper.

**Lead-level:** Compare hash vs range; when to use range; mention RDD custom partitioner for edge cases and DataFrame’s `repartitionByRange`.

---

## Q19. How do you choose optimal partition size and count for a large job?

**Answer:**  
**Guidelines:** (1) **Partition size:** Aim for roughly 100 MB–1 GB per partition (Spark’s default block size and many docs suggest this range). Too small → many small tasks (scheduling overhead, small files); too large → fewer tasks (underutilized cluster), risk of OOM or spill per task. (2) **Count:** `total_data_size / target_partition_size`; cap by cluster parallelism (e.g. 2–4× total cores). (3) **Shuffle partitions:** `spark.sql.shuffle.partitions`—same idea; too high → many small tasks; too low → few big tasks. AQE can coalesce, so you can start with a higher number. (4) **Input:** HDFS/Parquet often have one partition per file/split; if you have 10,000 small files, you get 10,000 tasks unless you coalesce or use a reader that combines files. So: compute desired partition count from data size and target size; adjust for skew (more partitions can help); use AQE to coalesce if needed.

**Real-world:** 500 GB input, 500 executors × 4 cores = 2000 cores. Target 256 MB per partition → ~2000 partitions; set shuffle partitions to 2000 or 4000 and let AQE coalesce.

**Common mistakes:** Using a fixed “200” or “1000” without considering data size. Ignoring that input partitioning (many small files) can create too many tasks.

**Lead-level:** Give a formula (size/count), tie to cores and task overhead, and mention AQE and input file layout.

---

## Q20. What is the small-files problem, and how do you prevent or fix it?

**Answer:**  
**Problem:** Writing (or reading) many small files causes: (1) Many tasks (one per partition/file), so scheduling and driver overhead. (2) Poor compression and scan efficiency. (3) In HDFS/S3, Namenode or listing overhead. So “small files” = too many small partitions/files. **Prevention:** (1) **On write:** Use `coalesce(n)` or `repartition(n)` before write so you write `n` partitions (and thus `n` files per partition column value if partitioned). (2) **Partition count:** Don’t use 10,000 shuffle partitions if the output is 1 GB total. (3) **Streaming:** Use batch sizing or trigger interval so each batch writes a reasonable amount. **Fix (existing data):** (1) **Compaction job:** Read small files, coalesce, rewrite (e.g. by partition). (2) **Layout:** Use a table format (Delta, Iceberg) that supports compaction or multiple files per partition. (3) **Query-time:** Some engines can combine small files when reading (e.g. Spark’s file listing can be tuned); but fixing the write is better.

**Real-world:** A streaming job writing every 1 minute with 200 partitions produces 200 small files per minute; after a day you have millions of tiny files. Fix: increase batch interval or coalesce before write; run a nightly compaction.

**Common mistakes:** Only increasing coalesce without considering partition columns (e.g. coalesce(1) for a partitioned table loses parallelism per partition). Writing one file per partition value and having high cardinality partition columns.

**Lead-level:** Distinguish “too many partitions” from “too many files” (e.g. partition columns × partition count); suggest compaction and prevention in pipeline design.

---

## Q21. What is data locality, and how does Spark use it?

**Answer:**  
**Data locality** means running a task on the executor that already has the task’s input data (e.g. same node as the HDFS block or same executor that has the cached RDD). Spark’s scheduler prefers **PROCESS_LOCAL** (data on same JVM), then **NODE_LOCAL** (same node), then **RACK_LOCAL**, then **ANY**. So for a stage that reads from HDFS or from cache, the driver tries to assign tasks to executors that hold that data to avoid network transfer. After a shuffle, data is distributed; the next stage’s tasks must read from wherever the shuffle files were written (often different executors), so locality is less ideal. For cache: if an executor is lost, cached blocks are gone; recomputation may happen with no locality. **Lead implication:** Locality is best for the first stage (read) and for cached RDDs; shuffle stages are network-bound by design.

**Real-world:** Reading from HDFS, tasks are often NODE_LOCAL; after a shuffle, tasks are ANY. Keeping a reused DataFrame in cache improves locality for subsequent stages that consume it.

**Common mistakes:** Saying “Spark always runs on the same node as data” (shuffle breaks that). Ignoring that cache eviction or executor loss forces recomputation and may lose locality.

**Lead-level:** List locality levels and when they apply; tie to cache and shuffle; mention speculative execution when locality is not possible.

---

# Part 4: Performance Tuning

---

## Q22. How is executor memory split between execution and storage (caching)? What is the implication for OOM?

**Answer:**  
Executor heap is divided into: (1) **Execution memory**—used for shuffles, joins, aggregations (e.g. sort buffers, hash tables). (2) **Storage memory**—used for cache/persist (RDD/DataFrame blocks). The boundary is **unified** (Spark 1.6+): execution can borrow from storage (evicting cached blocks if needed), and storage can borrow from execution when execution doesn’t need it. So they share one pool. **Implications:** (1) If you cache a lot, execution has less room → more spill or OOM during shuffle/agg. (2) If a task’s execution needs more than the available memory (e.g. one partition is huge or skewed), you get OOM or heavy spill. (3) Config: `spark.memory.fraction` (default 0.6) is the share of heap for this unified pool; the rest is for user code, metadata, etc. `spark.memory.storageFraction` is the minimum reserved for storage (default 0.5 of the pool). So OOM can be “execution” (shuffle/agg) or “storage” (cache), but both use the same pool.

**Real-world:** A job that caches a 20 GB DataFrame on 10 executors with 8 GB heap each will evict or OOM; reduce cache or increase executor memory. A single skewed partition that holds 2 GB in a hash table can OOM a 4 GB executor.

**Common mistakes:** Thinking “storage” and “execution” are separate fixed pools. Not sizing executors with both shuffle and cache in mind.

**Lead-level:** Explain unified memory; name the configs; tie OOM to both shuffle/cache and to skew.

---

## Q23. How does garbage collection affect Spark jobs, and how would you mitigate GC pressure?

**Answer:**  
Long GC pauses stop task threads; the driver may mark the executor as unresponsive and kill it, or the task simply runs longer. **Causes:** (1) Too many short-lived objects (e.g. row-by-row processing in a UDF). (2) Large heaps with limited GC tuning. (3) Cache holding many objects. **Mitigations:** (1) **Reduce object creation:** Prefer DataFrame operations over RDD of objects; avoid UDFs that allocate per row when possible. (2) **Tungsten:** Uses binary/off-heap layout, reducing Java object count. (3) **Executor sizing:** Not too large (e.g. up to ~8–16 GB per executor often recommended so GC doesn’t take too long). (4) **GC tuning:** Use G1GC; tune pause time and heap regions. (5) **Off-heap:** For shuffle and cache, off-heap can reduce GC (configurable). (6) **Cache:** Serialized cache (e.g. `MEMORY_AND_DISK_SER`) uses fewer objects. Monitor with GC logs and Spark UI (GC time per task).

**Real-world:** A Python UDF that creates a dict per row causes huge GC in the JVM that runs the Python worker; replacing with a Spark SQL expression or a vectorized UDF reduces GC and speeds up the job.

**Common mistakes:** Blaming “Spark” for GC without checking UDFs or object allocation. Setting executor memory very high (e.g. 64 GB) without GC tuning.

**Lead-level:** Link GC to object allocation (UDFs, RDD vs DataFrame), executor size, and off-heap/serialized cache.

---

## Q24. Kryo vs Java serialization: when does it matter, and what are the trade-offs?

**Answer:**  
**Java serialization:** Default for RDD; verbose and slow; rarely optimal. **Kryo:** Faster and smaller; used by default for DataFrame/Dataset shuffle and cache in modern Spark. You can set `spark.serializer=org.apache.spark.serializer.KryoSerializer` for RDDs and register classes for Kryo to avoid storing full class names. **When it matters:** (1) Shuffle: large shuffle data benefits from smaller serialized size (less network and disk). (2) Cache: same. (3) RDD of custom objects: register those classes with Kryo. **Trade-offs:** Kryo is not human-readable; registration is needed for best performance and to avoid large serialized names. For DataFrame/Dataset, Spark uses internal serialization (e.g. Tungsten); Kryo may still apply to some internal structures or to RDD. In practice, use Kryo for RDD; for DataFrame, focus on partition size and format rather than serializer.

**Real-world:** An RDD of domain objects with Kryo and registered classes can reduce shuffle size by 2× and speed up the job. For DataFrame-only pipelines, the gain is smaller but still useful in some setups.

**Common mistakes:** Enabling Kryo without registering classes (Kryo still works but stores class names). Thinking Kryo fixes skew or algorithm choice (it only reduces serialization cost).

**Lead-level:** Explain where serialization is used (shuffle, cache, broadcast); when to use Kryo and registration; DataFrame vs RDD.

---

## Q25. Explain persistence levels (e.g. MEMORY_ONLY, MEMORY_AND_DISK_SER). When would you choose each?

**Answer:**  
Common levels: **MEMORY_ONLY:** Cached in heap only; if evicted, recomputed. **MEMORY_AND_DISK:** Spill to disk when evicted; read from disk when needed. **MEMORY_ONLY_SER / MEMORY_AND_DISK_SER:** Serialized form (smaller, fewer objects, less GC; deserialize on read). **DISK_ONLY:** Only on disk. **OFF_HEAP:** Stored off-heap (if enabled). **Choice:** (1) Reuse multiple times, fits in memory → MEMORY_ONLY or MEMORY_ONLY_SER. (2) Reuse but might not fit → MEMORY_AND_DISK_SER (avoid OOM, still faster than recompute). (3) Large, reused → MEMORY_AND_DISK_SER or DISK_ONLY. (4) GC pressure → prefer _SER. (5) Critical path, must not recompute → MEMORY_AND_DISK so eviction doesn’t trigger recompute. Unpersist when no longer needed to free resources.

**Real-world:** A 50 GB DataFrame reused 3 times: MEMORY_ONLY would OOM; MEMORY_AND_DISK_SER caches what fits and spills the rest; first run is slower, next runs are faster for cached portions.

**Common mistakes:** Caching everything “to be safe” and causing OOM or eviction storms. Not unpersisting; using MEMORY_ONLY for data that doesn’t fit.

**Lead-level:** Match storage level to size, reuse count, and GC; mention unpersist and monitoring cache hit/eviction.

---

## Q26. What is checkpointing, and when would you use it instead of or with cache?

**Answer:**  
**Checkpointing** writes the RDD/DataFrame to reliable storage (e.g. HDFS) and breaks the lineage. On failure, Spark reads from checkpoint instead of recomputing from the beginning. **When to use:** (1) Long lineages (e.g. many iterations) where recomputation would be very expensive. (2) When you need to truncate lineage to avoid stack overflow or plan size issues. (3) With streaming (checkpoint for offset and state). **Checkpoint vs cache:** Cache is in-memory (or disk) but keeps lineage; eviction triggers recompute. Checkpoint is on durable storage and **removes** lineage; no recompute from before checkpoint. So: checkpoint = durability + lineage truncation; cache = speed + reuse. You can use both (e.g. cache for speed, checkpoint for long chains). **Cost:** Checkpoint is a full write and read; use sparingly (e.g. once per N iterations).

**Real-world:** ML iterative algorithm with 100 iterations: checkpoint every 10 iterations so failure only redoes 10 steps, not 100. Streaming: checkpoint directory stores offsets and state for exactly-once and recovery.

**Common mistakes:** Checkpointing every RDD (expensive and unnecessary). Confusing checkpoint with cache (checkpoint doesn’t speed up the first run; it helps recovery and lineage).

**Lead-level:** Explain lineage truncation and durability; when to checkpoint in batch (long lineage) vs streaming (required); checkpoint vs cache.

---

## Q27. How would you debug and resolve executor OOM issues?

**Answer:**  
**Diagnosis:** (1) Spark UI: which stage and which tasks (all or a few)? (2) If a few tasks use much more memory → skew. (3) If every task is large → partition too big or too much data per task. (4) Check “Spill (Memory/Disk)” and GC time. **Resolutions:** (1) **Skew:** Salting, AQE skew join, or split hot keys. (2) **Partition size:** Increase partition count (`repartition`, `shuffle.partitions`) so each task handles less data. (3) **Executor memory:** Increase (within reason; very large heaps worsen GC). (4) **Execution memory:** Increase `spark.memory.fraction` if you don’t need much cache. (5) **Off-heap:** Enable for shuffle/cache to reduce heap pressure. (6) **Algorithm:** Avoid operations that hold large structures per partition (e.g. large hash table); use streaming aggregation or reduce data before shuffle. (7) **Broadcast:** If you’re broadcasting something large, reduce it or use sort-merge. (8) **Cache:** Reduce what you cache or use MEMORY_AND_DISK_SER so eviction doesn’t OOM.

**Real-world:** OOM in a single task in a join stage → skew; add salt or enable AQE skew join. OOM in every task of an aggregation stage → increase partitions or executor memory.

**Common mistakes:** Only increasing memory without fixing skew or partition count. Not distinguishing “one task OOM” (skew) from “all tasks OOM” (partition size or memory).

**Lead-level:** Systematic diagnosis (UI, spill, GC); list of mitigations tied to root cause; production playbook.

---

## Q28. How do you size executors (cores, memory) for a production cluster?

**Answer:**  
**Cores per executor:** Typically 4–8. Too many cores per executor can lead to poor locality (fewer executors) and more contention; too few underutilize the node. **Memory per executor:** Balance: (1) Enough for shuffle and aggregation (execution memory). (2) Room for cache if used. (3) Not so large that GC pauses are huge (e.g. 8–16 GB is common). **Total:** `num_executors × cores × memory` should match cluster capacity; leave some for OS and other services. **Dynamic allocation:** Min/max executors and cores per executor; scale with backlog. **YARN:** Consider `yarn.nodemanager.resource.memory-mb` and `vcores`; request executors that fit (e.g. one executor per node or multiple smaller executors). **Rule of thumb:** Start with 4–8 cores, 8–16 GB per executor; tune based on task duration, spill, and OOM. Avoid one executor with all memory (no parallelism) and avoid thousands of 1-core executors (overhead).

**Real-world:** 10 nodes, 32 cores, 128 GB each. Option: 10 executors × 8 cores × 32 GB (leave ~32 GB per node for OS/YARN). Or 20 executors × 4 cores × 16 GB for more parallelism and smaller GC.

**Common mistakes:** One executor per cluster or one core per executor. Ignoring dynamic allocation and over-provisioning.

**Lead-level:** Give a sizing formula; mention dynamic allocation, YARN constraints, and trade-offs (cores vs executors vs memory).

---

## Q29. What is dynamic allocation, and what must be configured for it to work correctly with shuffle?

**Answer:**  
**Dynamic allocation** allows Spark to request and release executors based on load. When there are many pending tasks, it requests more executors; when idle, it can release them. **Shuffle requirement:** When a map stage writes shuffle files and then executors are released before the reduce stage runs, the reduce stage needs those shuffle files. So **external shuffle service** (or equivalent) must be enabled: shuffle files are served by a process that outlives the executor (e.g. YARN NodeManager or a dedicated daemon). Then the executor can be removed; reducers fetch shuffle data from the shuffle service. Without it, releasing executors that hold shuffle files would cause fetch failures. **Config:** Enable `spark.dynamicAllocation.enabled`; set min/max executors and initial number; ensure shuffle service is running and `spark.shuffle.service.enabled=true` (for YARN).

**Real-world:** Batch workload with varying size: dynamic allocation scales up for large runs and scales down when idle, saving cost. Shuffle service is mandatory so that scale-down doesn’t break in-flight jobs.

**Common mistakes:** Enabling dynamic allocation without shuffle service and seeing fetch failures. Not setting initial executors and waiting long for the first wave of tasks.

**Lead-level:** Explain why shuffle service is required; name the configs; tie to cost and elasticity.

---

# Part 5: Data Skew

---

## Q30. What are the main causes of data skew in practice?

**Answer:**  
(1) **Key distribution:** A few keys have most of the data (e.g. “unknown” or “default” in a dimension; a few super-users or products). (2) **Partition key choice:** Partitioning or grouping by a column that is skewed (e.g. `country` when one country has 80% of rows). (3) **Join key:** Join on a column where one value appears in a large fraction of rows (e.g. null or a sentinel). (4) **Time:** All data in one partition when partitioned by day and one day is huge. (5) **Data source:** Input already skewed (e.g. one huge file or one Kafka partition hot). So skew is both “which key” and “how we use it” (partition, join, groupBy).

**Real-world:** Events table partitioned by `user_id`; 0.1% of users generate 40% of events → a few partitions are huge. Aggregation by `country` where “US” is 60% of rows → one partition dominates.

**Common mistakes:** Assuming data is uniform. Not checking key distribution before choosing partition or join keys.

**Lead-level:** List causes (key, partition key, join key, time, source); tie to detection and design (choice of keys, salting, AQE).

---

## Q31. How would you detect skew in a running job and in the data before the job?

**Answer:**  
**In a running job:** (1) Spark UI: look at task duration and shuffle read/write per task in the problematic stage; a few tasks with much higher metrics indicate skew. (2) Event log: aggregate bytes read/write per task; plot distribution. (3) Logs: “speculative” task duplicates often indicate stragglers (skew). **Before the job:** (1) **Sample and aggregate:** `df.groupBy(join_key).count()` and check max/min/percentiles; or run a small Spark job that only does the groupBy and collects stats. (2) **Statistics:** If using CBO, `ANALYZE TABLE` and check histogram or distinct count per key column. (3) **Domain knowledge:** Identify likely hot keys (e.g. “unknown,” “default,” top 10 users). (4) **Partition listing:** If data is partitioned, list partition sizes (e.g. by date) to see if one partition is huge. Use this to decide salting factor, AQE, or partition key.

**Real-world:** Before a big join, run `df.select(join_key).groupBy(join_key).count().orderBy(F.desc("count")).show(20)` to see top keys; if top key is 100× the median, plan for skew.

**Common mistakes:** Only looking at UI after the job fails; not profiling key distribution in development.

**Lead-level:** Combine UI/event-log diagnosis with proactive key-distribution analysis and stats.

---

## Q32. Explain salting for skew in detail: how you apply it, and how you preserve correctness.

**Answer:**  
**Idea:** Spread a hot key across many partitions by appending a random (or deterministic) suffix—e.g. `key_salted = key || "_" || (rand() * N)` or `key || "_" || (hash(secondary_col) % N)`. Each of the N salted keys gets ~1/N of the data for that logical key. **Apply:** (1) On the large table: add a salt column (e.g. 0..N-1) and use `(key, salt)` as the join/group key. (2) On the small table (if joined): replicate each row N times with salt 0..N-1 (expand small side by N). (3) Join on `(key, salt)`. (4) If you only need to aggregate: after the salted aggregation, aggregate again by `key` to get the final result. **Correctness:** For join: each row on the large side joins with the small side exactly once (one salt value). For aggregation: first aggregation is per (key, salt); second sums/counts by key. **N choice:** N should be at least the ratio of max key size to median (e.g. if one key has 100× more rows, N ≥ 10–20).

**Real-world:** Join fact (skewed on `user_id`) with dim (user attributes). Salt fact with 20 salts; replicate dim 20 times with salt 0..19; join on (user_id, salt); no second aggregation needed if you only need the joined rows. For groupBy user_id sum(amount): salt, aggregate by (user_id, salt), then sum by user_id.

**Common mistakes:** Salting only one side of a join without replicating the other (wrong results). Forgetting the second aggregation when doing salted groupBy. Choosing N=2 when skew is 100×.

**Lead-level:** Full recipe for join and for aggregation; correctness argument; choosing N.

---

## Q33. What are skew hints (e.g. in Spark 3), and how do they interact with AQE?

**Answer:**  
**Skew hints** (e.g. `SKEWJOIN`) allow the user to tell Spark that a table has skew on certain keys. Syntax (conceptually): hint that table X is skewed on column(s) Y. Spark can then use this in planning (e.g. choose a join strategy that handles skew) or pass it to AQE. **Interaction with AQE:** AQE can detect skew at runtime (by partition size); when skew join is enabled, AQE splits skewed partitions. A skew hint can help when: (1) Stats are missing so AQE doesn’t know in advance. (2) You want to force skew handling for a specific join. So hint = declarative; AQE = runtime detection. Together: hint can ensure a join is considered for skew optimization even without stats; AQE then does the actual split at runtime if it sees skew. (Exact syntax and support depend on Spark version; concept is “tell the optimizer about skew.”)

**Real-world:** You know from experience that `orders` joined on `customer_id` is skewed; you add a skew hint so the optimizer (and AQE) treat it as skewed even if table stats are stale.

**Common mistakes:** Relying only on hints without AQE or salting (hints may only influence strategy). Not measuring after enabling to confirm improvement.

**Lead-level:** Explain purpose of hints; that AQE can work without them (runtime detection) but hints can help when stats are missing; mention version-specific support.

---

# Part 6: Spark SQL & Optimization

---

## Q34. What is predicate pushdown, and how do you get it (or lose it)?

**Answer:**  
**Predicate pushdown** means pushing filter predicates down to the data source so that only data satisfying the filter is read (e.g. skip row groups in Parquet, or partition directories when the filter is on the partition column). Spark’s Catalyst pushes predicates into the logical plan for supported sources (Parquet, ORC, JDBC with dialect, etc.). **Get it:** (1) Use a source that supports pushdown (Parquet, ORC). (2) Write filters in a way Catalyst can understand (e.g. `col("date") == "2024-01-01"` or SQL). (3) Partition the data by the filtered column so the reader can skip entire partitions. **Lose it:** (1) Use a UDF in the filter (Catalyst can’t push UDF into the source). (2) Use a complex expression the source doesn’t support. (3) Read through a layer that doesn’t implement pushdown. So: pushdown = less I/O and faster; design schema and filters to enable it.

**Real-world:** Filter on `date` after read without partition pruning reads all files; same filter on a table partitioned by `date` causes partition pruning and much less I/O.

**Common mistakes:** Assuming all filters are pushed down (UDFs and some expressions are not). Not partitioning by commonly filtered columns.

**Lead-level:** Explain what pushdown is; which sources support it; how UDFs and partitioning affect it.

---

## Q35. What is column pruning, and why does it matter for wide tables?

**Answer:**  
**Column pruning** means reading only the columns that are needed for the query (and the rest are never read). In Parquet/ORC, each column is stored separately (or in column groups), so the reader can read only required column chunks. Catalyst pushes “select” down so the scan only requests those columns. **Why it matters:** Wide tables (hundreds of columns): without pruning, reading 100 columns when the query uses 5 wastes I/O and memory. With pruning, only 5 columns are read. So: design queries to select only needed columns; avoid `SELECT *` when you don’t need all columns; use formats that support columnar read (Parquet, ORC).

**Real-world:** A 500-column table where each query uses 10 columns: column pruning reduces read size by ~50× and speeds up scans significantly.

**Common mistakes:** Using `SELECT *` and then dropping columns in Spark (still reads everything). Not using columnar formats.

**Lead-level:** Tie to columnar formats and to query design (select list, avoid *).

---

## Q36. How does partition pruning work with partitioned tables (e.g. by date)?

**Answer:**  
When data is written with `partitionBy("date")` (and optionally other columns), the layout is e.g. `path/date=2024-01-01/`, `path/date=2024-01-02/`, etc. When you read with a filter like `date = '2024-01-01'`, Catalyst can translate this into a **partition pruning** constraint: only list and read directories (or partition metadata) that match. So the reader doesn’t scan other partition paths at all. This requires: (1) Data laid out by that partition column. (2) Filter on the same column (or expression that can be translated to partition bounds). (3) A catalog or listing that respects partition structure (e.g. Hive metastore, or Spark’s native partition discovery). **Order:** Filter pushdown on partition columns → list only matching partitions → read only those files. So partition pruning is a form of predicate pushdown specialized to partition columns and directory layout.

**Real-world:** Table partitioned by (year, month, day); query `WHERE date = '2024-01-15'` only touches one partition path; query `WHERE year = 2024` only touches that year’s partitions.

**Common mistakes:** Filtering on a non-partition column and expecting partition pruning (only partition columns prune). Using a UDF on the partition column (may prevent pruning).

**Lead-level:** Explain directory layout, filter on partition column, and interaction with predicate pushdown and catalog.

---

## Q37. What is bucketing, and when is it useful compared to partitioning?

**Answer:**  
**Bucketing** (e.g. Hive/Spark bucketing) hashes a column (or set of columns) into a fixed number of buckets and writes each bucket to one or more files. So data with the same bucket key (e.g. `user_id`) lands in the same set of files. **Use cases:** (1) **Bucketed join:** When both sides are bucketed by the same key and with the same number of buckets, Spark can join without shuffle (each bucket is read and joined locally). (2) **Pre-clustering:** Data is organized by key for range scans or aggregations. **Vs partitioning:** Partitioning (e.g. by date) creates directories and enables partition pruning; bucketing doesn’t create top-level directories but clusters data within a partition (or table). So you can have `partitionBy("date")` and `bucketBy("user_id", 256)`: prune by date, then within a date, data is clustered by user_id for efficient join or aggregation. **Limitation:** Bucketing must be respected at write time (e.g. DataFrame write with bucketBy); not all operations preserve bucketing. Spark 3 has improved bucketing support (e.g. bucketed read/write, sort-merge join without shuffle when both sides bucketed).

**Real-world:** Two large tables joined on `user_id`; both bucketed by `user_id` with 512 buckets; join can be shuffle-free (bucket-to-bucket). Without bucketing, same join would shuffle both sides.

**Common mistakes:** Thinking bucketing and partitioning are the same. Expecting bucketed join when only one side is bucketed or bucket counts differ.

**Lead-level:** Compare bucketing vs partitioning; when bucketed join applies; mention write and compatibility (Spark 3).

---

## Q38. Parquet vs ORC: what are the trade-offs in a Spark context?

**Answer:**  
Both are **columnar**, support predicate pushdown and column pruning, and are splittable. **Parquet:** Very widely supported (Spark, Presto, Athena, etc.); good compression (e.g. Snappy, GZIP); nested types supported; default in many Spark projects. **ORC:** Often better compression and faster in Hive/Spark for some workloads; supports ACID and more indexing (e.g. bloom filters) in some implementations; less universal outside the Hive ecosystem. **Trade-offs:** (1) **Ecosystem:** Parquet is the “safe” choice for portability. (2) **Performance:** Benchmark on your data; ORC can be faster for certain scans. (3) **Features:** If you need ACID or advanced indexing, ORC (or Delta/Iceberg on top of Parquet) may be relevant. (4) **Spark:** Both are first-class; choose based on existing data, tooling, and benchmarks.

**Real-world:** Lakehouse on S3 with Spark and Athena: Parquet for maximum compatibility. Hive warehouse with Spark: ORC is common and may give better compression.

**Common mistakes:** Saying “ORC is always faster” or “Parquet is always better” without context. Ignoring ecosystem and tooling.

**Lead-level:** Compare both; mention compression, pushdown, ecosystem, and when to choose each (or Delta/Iceberg on Parquet).

---

## Q39. How do statistics and cost-based optimization (CBO) affect Spark SQL plans?

**Answer:**  
**Statistics:** Table/column stats (row count, size, distinct count, min/max, histograms) let the optimizer estimate cardinality and cost. **CBO:** Catalyst can generate multiple physical plans and choose the one with lower estimated cost (e.g. join order, broadcast vs sort-merge). So: with stats, join order might change (e.g. join the small table first); broadcast might be chosen when the build side is small. **Gathering stats:** `ANALYZE TABLE t COMPUTE STATISTICS` (and optionally `FOR COLUMNS col1, col2`). Without stats, Spark uses heuristics and defaults (e.g. broadcast threshold based on plan size estimate). **Limitation:** Stats can be stale; for very dynamic tables, CBO may be wrong. So: use CBO for stable or periodically refreshed tables; run ANALYZE after large loads; monitor plan changes.

**Real-world:** After loading a new partition, run ANALYZE so the next day’s queries get a better join order and broadcast choice. A table that grows 10× without re-analyze might get the wrong join strategy.

**Common mistakes:** Never running ANALYZE and wondering why broadcast isn’t chosen. Assuming CBO is always right (stale stats can hurt).

**Lead-level:** Explain stats + CBO; how to collect stats; when CBO helps (join order, broadcast); caveat of stale stats.

---

# Part 7: Streaming

---

## Q40. Micro-batch vs continuous processing in Structured Streaming: what are the differences and when to use which?

**Answer:**  
**Micro-batch (default):** Spark treats the stream as a series of small batches. At each trigger (e.g. every 5 seconds), it processes all available data as one batch (one or more Spark jobs). Latency is on the order of seconds; exactly-once is achieved by writing offsets and output atomically. **Continuous processing:** Lower latency (milliseconds); the query runs as a long-running task that processes records as they arrive. Supported for a subset of operations (e.g. map-like); not all sources and sinks support it. **When to use:** Micro-batch: most ETL, exactly-once with any sink, robust and well-tested. Continuous: when you need sub-second latency and your pipeline is supported (e.g. simple map-filter to Kafka). For lead roles, micro-batch is the default; continuous is for low-latency edge cases.

**Real-world:** Real-time dashboard with 1-minute delay: micro-batch with 1-minute trigger. Sub-second alerting on a simple filter: consider continuous if the stack supports it.

**Common mistakes:** Assuming “streaming” always means continuous. Not checking which sources/sinks support continuous.

**Lead-level:** Compare latency and semantics; when to choose each; limitations of continuous.

---

## Q41. What is watermarking in Structured Streaming, and how does it relate to late data and state?

**Answer:**  
**Watermark** is a threshold on event time: “data older than (max event time seen − delay) will not be processed.” You set it per streaming query (e.g. `withWatermark("event_time", "10 minutes")`). **Purpose:** (1) **Late data:** Events that arrive after the watermark can be dropped (or put in a side output, depending on API) so the engine doesn’t hold state forever. (2) **State:** For aggregations and joins, Spark can drop state for keys that are older than the watermark, so state size is bounded. Without a watermark, late data would require unbounded state. **Trade-off:** Large delay = more late data accepted but more state. Small delay = less state but more late data dropped. So watermark enables bounded state and defined semantics for “late” events.

**Real-world:** Aggregation by hour with 24-hour watermark: state for a key is kept for 24 hours after the latest event time seen; then it’s dropped. Events 25 hours late are dropped.

**Common mistakes:** Setting watermark too low and dropping valid late data. Not setting watermark and seeing state grow unbounded (or job failing).

**Lead-level:** Explain event time vs processing time; how watermark bounds state and handles late data; tuning the delay.

---

## Q42. How does Structured Streaming achieve exactly-once semantics for sinks (e.g. file, Kafka)?

**Answer:**  
**General idea:** (1) **Offsets** for the source are tracked (in checkpoint or external store). (2) **Output** is written in an **idempotent** or **transactional** way so that re-running the same batch produces the same result (no duplicates). **File sink:** Each micro-batch writes to a unique path (e.g. partition + batch id); checkpoint records which batch IDs are committed. On restart, only uncommitted batches are re-run; committed output is not rewritten. So exactly-once: each batch is written once; retries write the same batch id again (overwrite or same path). **Kafka:** Spark uses Kafka transactional API (or idempotent producer) so that writing the same batch twice results in the same offsets and no duplicate messages to Kafka. **Checkpoint:** Checkpoint stores source offsets and batch metadata; after a crash, the driver replays from the last committed offset and re-runs only the last incomplete batch (output must be idempotent/transactional).

**Real-world:** File sink with checkpoint: if the job dies after writing batch 5 but before updating checkpoint, on restart it will re-run batch 5 and overwrite the same output directory—so exactly-once for the sink. Kafka sink: transactional write so duplicate run doesn’t double-publish.

**Common mistakes:** Assuming all sinks are exactly-once (some are at-least-once). Not making the sink idempotent when using a custom sink.

**Lead-level:** Explain offset tracking + idempotent/transactional write; how file and Kafka achieve it; role of checkpoint.

---

## Q43. Why is checkpointing critical in streaming, and what happens if you change the query without a new checkpoint?

**Answer:**  
**Checkpoint** stores: (1) Source offsets (e.g. Kafka offsets, file listing). (2) Batch IDs and commit metadata. (3) State (for stateful operators). On restart, Spark reads the checkpoint and resumes from the last committed batch and state. **Critical:** Without checkpoint, the job doesn’t know which data was processed; it would re-read from the beginning or from the source’s default, causing duplicates or missed data. State would be lost (e.g. aggregations wrong). **Changing the query:** If you change the query (e.g. add a column, change aggregation) but keep the same checkpoint directory, the new logic may be incompatible with the saved state/offsets. Result: errors or wrong results. So: for a **non-compatible** change, use a **new checkpoint directory** (and optionally a new output path) so the new query starts fresh. For compatible changes (e.g. adding a filter that doesn’t affect state schema), some changes may work; but in production, treat query changes as a new application with a new checkpoint unless you’ve tested recovery.

**Real-world:** You add a new aggregation to the streaming query and restart with the same checkpoint; the state schema doesn’t match and the job fails. Fix: start with a new checkpoint (and accept reprocessing or use a separate job for new logic).

**Common mistakes:** Reusing the same checkpoint after a logic change and expecting it to work. Not backing up or documenting checkpoint location.

**Lead-level:** Explain what checkpoint stores; why it’s required; what “change query” means for checkpoint (new checkpoint or compatible change only).

---

# Part 8: Production & Design

---

## Q44. How would you design a Spark job that processes billions of rows reliably and within SLA?

**Answer:**  
**Design:** (1) **Partitioning:** Partition by a key that matches filters (e.g. date) so you can prune and process incrementally; size partitions so each is 100 MB–1 GB. (2) **Incremental where possible:** Process only new data (e.g. new partitions, or watermark in streaming); avoid full scan if not needed. (3) **Shuffle:** Tune `shuffle.partitions` and use AQE; avoid skew (salting, AQE skew join). (4) **Resources:** Right-size executors and use dynamic allocation; ensure enough memory to avoid spill and OOM. (5) **Idempotency:** Write by partition (or use merge) so re-runs don’t duplicate; checkpoint in streaming. (6) **Monitoring:** Track duration, shuffle size, failed tasks, skew; alert on SLA breach. (7) **Failure:** Retry with backoff; design so one partition’s failure doesn’t force full recompute (e.g. partition-level retry or overwrite-by-partition). (8) **Testing:** Run on a sample or recent partition; validate row counts and key metrics before full run.

**Real-world:** Nightly job: read only last 2 days’ partitions (prune); repartition by key for join; write with partitionBy(date); overwrite only those partitions; monitor duration and alert if > 2 hours.

**Common mistakes:** One huge job with no partitioning or incremental strategy. No idempotency (re-run doubles data). No monitoring.

**Lead-level:** End-to-end design: partitioning, incremental, shuffle/skew, resources, idempotency, monitoring, failure handling.

---

## Q45. How does Spark handle executor and driver failure, and what is your responsibility for recovery?

**Answer:**  
**Executor failure:** The driver gets a failure notification; it resubmits the failed stage’s tasks (possibly on other executors). If the stage had shuffle, map tasks may need to be re-run so shuffle files are recreated (unless shuffle service kept the files). So Spark retries tasks and stages; your job can succeed after executor failure if retries succeed. **Driver failure:** The application exits; there is no in-process recovery. **Your responsibility:** (1) **Cluster manager:** Run the driver in a managed way (YARN, K8s) so that when the driver dies, the cluster restarts it (or a new driver) and re-runs the application. (2) **Idempotency:** Ensure that re-running the job (from the start or from checkpoint in streaming) doesn’t corrupt output (overwrite-by-partition, merge, or checkpoint). (3) **Observability:** Log and monitor so you know when and why the driver or executors failed. So: Spark handles task/executor retry; you handle driver restart and idempotent output.

**Real-world:** YARN restarts the driver; the job runs again from the beginning; because the job overwrites only today’s partition, the second run just overwrites the same partition (idempotent).

**Common mistakes:** Assuming the driver is fault-tolerant by default. Not making output idempotent and getting duplicates on retry.

**Lead-level:** Separate Spark’s retry (executor/task) from driver restart (external); stress idempotency and cluster manager role.

---

## Q46. How do you design for idempotency in batch and streaming?

**Answer:**  
**Batch:** (1) **Partition overwrite:** Write output partitioned by business key (e.g. date); each run overwrites only the partitions it computed. Re-run = same partitions overwritten, same result. (2) **Merge/upsert:** Use a format that supports merge (Delta, Iceberg); write with merge by key so re-run updates the same rows. (3) **Deduplication on read:** If the sink is append-only, store a high-water mark or batch id and deduplicate when reading (e.g. window + row_number by key). **Streaming:** (1) **Checkpoint + idempotent sink:** Checkpoint marks which batches are committed; sink must write each batch idempotently (same batch id = same output, e.g. overwrite or transactional). (2) **Exactly-once sinks:** Use sinks that support transactional or idempotent write (file with unique path per batch, Kafka transactional). So: idempotency = same run twice → same output; design the write path (and optionally read path) to enforce that.

**Real-world:** Batch: write to `output/date=2024-01-15/`; re-run overwrites only that path. Streaming: each batch writes to `output/date=.../batch_id=...`; checkpoint records batch_id; retry rewrites same batch_id (overwrite).

**Common mistakes:** Append-only sink with no dedup or overwrite (re-run duplicates). Not tying checkpoint to sink semantics in streaming.

**Lead-level:** Give at least two patterns (partition overwrite, merge); include streaming checkpoint + idempotent sink.

---

## Q47. What would you monitor and log in production Spark jobs, and why?

**Answer:**  
**Monitor:** (1) **Job/stage duration**—SLA, trend. (2) **Failed tasks/stages**—retries, OOM, fetch failures. (3) **Shuffle read/write**—size and skew (max/median per task). (4) **GC time**—high GC can indicate memory pressure. (5) **Spill**—memory and disk spill. (6) **Resource:** CPU, memory usage; dynamic allocation metrics. (7) **Data quality:** row counts, nulls, key distribution (e.g. from a small sample or post-job validation). **Log:** (1) **Application start/end**—config, partition or range processed. (2) **Per-batch or per-partition:** count, min/max key, errors. (3) **Failures:** exception type, stage/task id, partition. (4) **Business metrics:** records written, distinct keys (if cheap). Use structured logging (JSON) and ship to a central system; correlate with Spark UI and event logs. **Why:** Detect regression (duration, failure rate); debug (skew, OOM, spill); audit (what was run, what was written).

**Real-world:** Alert when job duration > 2× baseline or when any task fails 3 times; log partition counts and row counts per partition to detect skew in the next run.

**Common mistakes:** Only monitoring “job finished” and not duration or failure rate. Not logging enough to debug (e.g. which partition failed).

**Lead-level:** List metrics (duration, failure, shuffle, spill, GC, data); logging (config, partition, errors); tie to alerting and debugging.

---

## Q48. What are common Spark anti-patterns you have seen, and how would you fix them?

**Answer:**  
(1) **Collecting large result to driver:** `collect()` or `take(n)` with large n → driver OOM. Fix: write to storage, stream, or aggregate in distributed way. (2) **Broadcasting too large a table:** OOM on all executors. Fix: check size; use sort-merge or salting. (3) **Skew ignored:** One key dominates; stragglers. Fix: salting, AQE skew join, or split hot keys. (4) **Too many small tasks:** Thousands of tiny partitions (e.g. many small files). Fix: coalesce or repartition before processing; tune shuffle partitions. (5) **No partition pruning:** Full scan when filter could prune. Fix: partition by filter column; avoid UDF on partition column. (6) **Cache everything:** OOM or eviction storm. Fix: cache only what’s reused; unpersist when done. (7) **Single partition for write:** `coalesce(1)` for huge data → one huge task, OOM or slow. Fix: coalesce to a reasonable number or repartition. (8) **UDF for simple logic:** Loses predicate pushdown and codegen. Fix: use built-in or expr(). (9) **No idempotency:** Re-run duplicates data. Fix: partition overwrite or merge. (10) **Joining without filtering first:** Shuffle and join on full table. Fix: filter early to reduce data.

**Real-world:** Job that did `df.filter(...).collect()` to get a list and then broadcast it: the filter result was 10 GB → driver OOM. Fix: write filter result to a small table and broadcast that table, or use a join instead of collect+broadcast.

**Common mistakes:** Listing only one or two anti-patterns. Not giving a concrete fix for each.

**Lead-level:** List many anti-patterns with causes and fixes; tie to production impact (OOM, skew, latency, correctness).

---

## Q49. When should you NOT use Spark? What alternatives or designs would you consider?

**Answer:**  
**When not to use Spark:** (1) **Very small data:** Single-node (e.g. pandas, Polars) is simpler and faster; Spark overhead (scheduling, startup) doesn’t pay off. (2) **Low-latency single-record or simple lookups:** Use a database or cache; Spark is batch-oriented. (3) **Ad-hoc interactive SQL on already-indexed data:** A dedicated query engine (Presto, Trino, Athena, Dremio) may be better tuned and cheaper for many small queries. (4) **When the team or ecosystem doesn’t support it:** Operational cost and expertise matter. (5) **Strict real-time with complex state:** Sometimes a stream processor (Flink, Kafka Streams) is a better fit for very low latency and complex state. (6) **Data already in a warehouse with good SQL:** Pushing everything to Spark can add complexity; warehouse-native pipelines may suffice. **Alternatives:** Single-node (pandas, DuckDB) for small data; Presto/Trino/Athena for interactive SQL; Flink/Kafka Streams for low-latency streaming; warehouse-native ETL (dbt, Snowflake, BigQuery) when the data lives there.

**Real-world:** 10 GB daily batch that runs in 5 minutes on a single big machine: moving to Spark adds complexity without benefit. A 10 TB join that needs skew handling: Spark (or similar) is appropriate.

**Common mistakes:** “Spark for everything.” Not considering operational cost and team skills.

**Lead-level:** Give clear “don’t use” cases (size, latency, use case, ecosystem); suggest alternatives; tie to total cost and fit.

---

## Q50. Scenario: A production job that used to run in 30 minutes now takes 4 hours. The input data size and schema are unchanged. How do you approach debugging?

**Answer:**  
**Approach:** (1) **Confirm the premise:** Check that input size and schema really haven’t changed (e.g. row count, partition count, file count). Sometimes “same schema” hides more partitions or more files (small-file problem). (2) **Spark UI / event log:** Compare with a baseline run. Which stage got slower? Is it one stage (e.g. join or aggregation) or many? (3) **Task distribution:** Look at task duration and shuffle read/write. If a few tasks are 10× slower, it’s skew (data or key distribution changed). (4) **Data distribution:** Sample key distribution (e.g. groupBy key, count). Did a key become hot? (5) **Cluster and config:** Any config or Spark version change? Cluster smaller or noisier? (6) **External factors:** Source/sink slower (e.g. S3 throttling); shared cluster; network. (7) **Hypothesis and fix:** If skew → salting or AQE. If more partitions → coalesce or tune shuffle partitions. If more small files → coalesce on read or compaction. Re-run with fix and measure.

**Real-world:** “Unchanged” input actually has 10× more small files (new writer); job now has 10× more tasks in the first stage. Fix: coalesce after read or increase reader parallelism and reduce downstream partitions.

**Common mistakes:** Only restarting or adding executors without finding the root cause. Assuming “data unchanged” without verifying.

**Lead-level:** Structured debugging (verify premise → UI → task distribution → data/cluster/config → hypothesis → fix and measure); mention skew, small files, and config.

---

# Part 9: Summary and Differentiation

---

## Recurring patterns across topics

- **Shuffle is the main cost:** Minimize (filter, project, broadcast), tune partition count, handle skew.
- **Partitioning drives parallelism and I/O:** Right size and count; avoid too many small files; use partition pruning.
- **Memory is shared (execution + storage):** Size executors and cache with both in mind; watch spill and GC.
- **Skew breaks parallelism:** Detect (UI, key distribution), mitigate (salt, AQE, split), design keys wisely.
- **Optimizer and format matter:** Catalyst, predicate/partition/column pruning, stats/CBO; use columnar formats.
- **Reliability = idempotency + retry:** Partition overwrite or merge; checkpoint in streaming; cluster manager restarts driver.
- **Observability:** Monitor duration, failure, shuffle, spill; log config and partition-level info for debugging.

---

## What differentiates Senior vs Lead-level Spark knowledge

| Area | Senior | Lead |
|------|--------|------|
| **Architecture** | Can explain driver/executor and stages | Explains DAG, Catalyst, Tungsten, and how they affect tuning and failure |
| **Shuffle/joins** | Knows what shuffle is and broadcast vs sort-merge | Designs join strategy for multi-table pipelines; handles skew with salting and AQE |
| **Partitioning** | Uses repartition/coalesce | Designs partition key, size, and count; addresses small-file and locality |
| **Tuning** | Adjusts memory and shuffle partitions | Systematically tunes memory, GC, serialization, persistence, and executor sizing |
| **Skew** | Has heard of salting | Detects skew (UI + data), applies salt correctly, uses AQE and hints |
| **Production** | Writes jobs that work | Designs for scale, idempotency, failure recovery, monitoring, and SLA |
| **Trade-offs** | Knows “broadcast is faster” | Explains when not to broadcast, when not to use Spark, and cost of each choice |

A **Lead** ties concepts to **production outcomes** (reliability, SLA, cost), **designs** pipelines and partitioning, **debugs** systematically, and **makes trade-offs** (e.g. complexity vs latency, Spark vs other engines).

---

## 2-week deep revision roadmap

**Week 1 – Core and execution**  
- **Day 1–2:** Execution model (driver, executor, DAG, stages, tasks); lazy evaluation; narrow vs wide. Re-read Spark architecture docs; draw a DAG for a sample job.  
- **Day 3:** Catalyst (phases, predicate pushdown, column pruning); Tungsten and whole-stage codegen. Run a query and look at the physical plan (explain).  
- **Day 4:** Shuffle (when, why, sort-based shuffle, spill); shuffle read/write in the UI.  
- **Day 5:** Joins (broadcast, sort-merge, shuffle hash); join strategy; AQE (coalesce, join switch, skew).  

**Week 2 – Tuning, skew, production**  
- **Day 6:** Partitioning (repartition, coalesce, custom, range); partition size and count; small-file problem; locality.  
- **Day 7:** Memory (execution vs storage, unified); GC; serialization; persistence levels; checkpointing; OOM debugging; executor sizing; dynamic allocation.  
- **Day 8:** Data skew (causes, detection, salting step-by-step, AQE skew, hints).  
- **Day 9:** Spark SQL (predicate/partition/column pruning, bucketing, Parquet vs ORC, stats/CBO). Streaming (micro-batch vs continuous, watermark, exactly-once, checkpoint).  
- **Day 10:** Production (design for billions of rows, failure recovery, idempotency, monitoring, logging, anti-patterns, when not to use Spark). Scenario: “Job got 4× slower” debugging path.  

**Ongoing:** Run jobs (or use history server), inspect UI and event logs, and tie every concept to a real metric or decision.

---

*End of document. Use this for deep revision and to calibrate Lead-level depth (architecture, trade-offs, production design, and systematic debugging).*
