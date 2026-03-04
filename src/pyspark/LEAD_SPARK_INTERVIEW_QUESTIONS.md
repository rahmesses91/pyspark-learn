# Spark Interview Questions — Lead Data Engineer

Concept-focused questions on shuffling, partitioning, joins, skew, tuning, and execution. No code; concepts only.

---

## Table of contents

| Section | Questions |
|---------|-----------|
| [Shuffling](#shuffling) | 1–3 |
| [Partitioning](#partitioning) | 4–7 |
| [Broadcast Joins](#broadcast-joins) | 8–10 |
| [Data Skew](#data-skew) | 11–14 |
| [Execution Model & DAG](#execution-model-dag) | 15–17 |
| [Tuning & Configuration](#tuning-configuration) | 18–20 |
| [Reliability & Correctness](#reliability-correctness) | 21–23 |
| [File Formats & I/O](#file-formats-io) | 24–26 |
| [Miscellaneous (Lead-Level)](#miscellaneous-lead-level) | 27–30 |

---

<a id="shuffling"></a>
## Shuffling

**1. What is a shuffle in Spark, and when does it occur?**

A shuffle is the process of redistributing data across partitions so that records with the same key end up on the same partition. It occurs on *wide* operations: `groupBy`, `reduceByKey`, `join` (when both sides are not co-partitioned), `distinct`, `repartition`, and aggregations that require data from multiple partitions. Shuffle involves writing data from executors to disk (or off-heap) and reading it back on other executors, so it is expensive in I/O and network. Narrow operations (e.g. `map`, `filter`) do not shuffle; they work within each partition.

**2. How does shuffle affect performance and how would you reduce shuffle cost?**

Shuffle is one of the main bottlenecks: network transfer, serialization, disk I/O, and the number of tasks in the next stage. To reduce cost: (1) Minimize shuffle—filter and project early so less data is shuffled. (2) Tune `spark.sql.shuffle.partitions` (and AQE) so you don’t have too many small tasks or too few large ones. (3) Use broadcast for small join sides to avoid shuffling the small table. (4) Pre-partition or coalesce before multiple wide operations where it makes sense. (5) Use appropriate file formats and compression to reduce data size.

**3. What is shuffle read and shuffle write in the Spark UI?**

*Shuffle write*: Data written by each task in a stage before the shuffle (often to local disk or off-heap). *Shuffle read*: Data read by each task in the next stage from other executors after the shuffle. Large skew in shuffle read/write across tasks indicates data skew. High total shuffle size relative to input suggests the job is shuffle-heavy and may need optimization (e.g. broadcast, better partitioning, or reducing data before wide operations).

---

<a id="partitioning"></a>
## Partitioning

**4. What is a partition, and how does Spark use partitions during execution?**

A partition is a logical chunk of the dataset. Spark schedules one task per partition per stage; each task runs on an executor and processes only that partition’s data. The number and size of partitions determine parallelism and task granularity. Too many partitions cause scheduling and small-task overhead; too few underutilize the cluster. Input partitioning comes from the data source (e.g. one partition per HDFS block); after shuffles, partitioning is determined by the shuffle partitioner (e.g. hash or range).

**5. Explain coalesce vs repartition. When would you use each?**

*Repartition(n)*: Full shuffle; data is redistributed into `n` partitions. Use when you need to *increase* the number of partitions (e.g. after a heavy filter that left few partitions) or to *balance* data across partitions (e.g. before a write). *Coalesce(n)*: No full shuffle; it only merges existing partitions so the number goes down to `n`. Use when *reducing* partition count (e.g. before writing a small number of files). Coalesce cannot increase partitions; repartition can increase or decrease but at the cost of a shuffle.

**6. What is partition pruning, and how do you get it when reading and writing?**

Partition pruning means skipping entire partitions (files or directories) that cannot contain data matching the query (e.g. filter on partition columns). On *read*: use a layout that matches your filters (e.g. `partitionBy("date", "region")` on write), then filter on those columns so the reader can list and read only matching partition paths. On *write*: writing with `partitionBy(...)` creates a directory per partition key; downstream readers that filter on those keys can skip non-matching partitions. Good partition column choice (cardinality, query patterns) is critical for lead-level design.

**7. How does Spark partition data after a groupBy or join?**

After a wide operation like `groupBy` or join, Spark applies a *partitioner* (default is hash for groupBy/join keys). Records with the same key go to the same partition. The number of output partitions is controlled by `spark.sql.shuffle.partitions` (and in Spark 3, AQE can coalesce or split them). So post-shuffle partitioning is hash-based by key, and partition count is configurable (and AQE-adjusted).

---

<a id="broadcast-joins"></a>
## Broadcast Joins

**8. What is a broadcast join, and when should you use it?**

In a broadcast join, the smaller side of the join is sent in full to every executor (once per executor), so the large side does not need to be shuffled to match the small side. Use it when one side is small enough to fit in executor memory (and within broadcast limits). Benefits: no shuffle for the large table on that join, fewer tasks, and often much faster. If the “small” table is too large, you get OOM or broadcast timeout; use a size threshold (e.g. `spark.sql.autoBroadcastJoinThreshold`) or explicit `broadcast(df)` only when you know the size is safe.

**9. How does Spark decide to use a broadcast join, and how can you force it?**

Spark’s optimizer uses statistics (size in bytes) and the config `spark.sql.autoBroadcastJoinThreshold` (default 10MB). If the estimated size of one side is under the threshold, Spark can choose broadcast join. You can *force* broadcast by wrapping the small DataFrame: `broadcast(small_df)` in the join. For lead-level control: set the threshold for the environment, use `broadcast()` for known-small dimension tables, and monitor executor memory when increasing threshold or broadcasting larger tables.

**10. What are the risks of broadcasting a table that is too large?**

Risks: (1) Out-of-memory on the driver or executors (each executor holds a full copy). (2) Broadcast can be slower than a shuffle join if the “small” table is large (serialization and network to all executors). (3) Broadcast timeout if building/sending the table takes too long. Mitigation: only broadcast when the table is provably small; use metrics or sampling to validate size; tune `spark.sql.autoBroadcastJoinThreshold` and executor memory accordingly.

---

<a id="data-skew"></a>
## Data Skew

**11. What is data skew, and why is it a problem?**

Data skew is when some keys (or partitions) have much more data than others. After a shuffle, a few partitions get most of the data, so a few tasks run much longer than the rest. The stage’s wall-clock time is dominated by these stragglers, so parallelism is wasted and the job is slow. Skew is common with high-cardinality keys that have a long tail (e.g. a few very active user IDs or dates).

**12. How do you detect skew in a Spark job?**

(1) Spark UI: look at task runtimes and shuffle read/write per task; a few tasks with much higher read/write or duration indicate skew. (2) Distribution of bytes per partition (e.g. from event logs or custom metrics). (3) Domain knowledge: keys known to have uneven distribution (e.g. popular products, default or null keys). (4) Sampling the key distribution before designing the job (e.g. count by key and check max/min/percentiles).

**13. What strategies can you use to mitigate skew in joins or aggregations?**

- **Broadcast**: If the skewed key set or one join side is small, broadcast it to avoid shuffling the large side for those keys.  
- **Salting (adding a random suffix to keys)**: Split heavy keys into multiple sub-keys (e.g. `key || "_" || rand(0, N)`), join/aggregate, then combine. This spreads the load across more partitions.  
- **Two-phase aggregation**: First aggregate with a salt (e.g. `key + salt`), then aggregate again by original key to get final results.  
- **Isolate and process skewed keys separately**: Filter into “skewed” and “normal,” process skewed with broadcast or salting, normal with standard join/agg, then union.  
- **Increase partitions**: Sometimes helps (e.g. more shuffle partitions) but does not fix severe skew by itself; combined with salting it can help.

**14. How does salting help with skew? Explain at a high level.**

Salting adds a random component to the key so that one logical key is spread across many partition keys. Example: key `"user_123"` (huge) becomes `"user_123_0"`, `"user_123_1"`, … `"user_123_N"`. Each salted key has less data, so more tasks can work in parallel. After the salted join or aggregation, you aggregate again by the original key to get the final result. Trade-off: more rounds of shuffle and more code, but much better balance and often a big win for highly skewed keys.

---

<a id="execution-model-dag"></a>
## Execution Model & DAG

**15. What is the difference between a transformation and an action? How does that relate to lazy evaluation?**

*Transformations* (e.g. `filter`, `select`, `groupBy`, `join`) define the lineage (DAG) and do not run immediately. *Actions* (e.g. `count`, `collect`, `show`, `write`) trigger execution: Spark optimizes the full DAG and runs stages. Lazy evaluation allows combining and optimizing many transformations (e.g. predicate pushdown, projection) before any work is done; it also means that side effects or multiple actions can cause the same upstream transformations to be recomputed unless you cache/persist.

**16. What are narrow vs wide dependencies, and why do they matter?**

*Narrow*: Each partition of the child depends on at most one partition of the parent (e.g. `map`, `filter`). No shuffle; failure recovery can recompute only the lost partition. *Wide*: A child partition can depend on many parent partitions (e.g. `groupBy`, `join`). Requires shuffle; failure may require recomputing a whole stage. Lead-level impact: wide stages are where you focus on shuffle size, skew, and partition count; narrow stages are easier to scale and recover.

**17. How does Spark schedule stages and tasks?**

Spark builds a DAG of stages. Stages are separated by shuffle boundaries (wide dependencies). Within a stage, tasks are independent (narrow): one task per partition. Stages run in order; within a stage, tasks run in parallel on available executors. So: first all tasks of stage 1 run, then shuffle, then all tasks of stage 2 run, and so on. Scheduling is done by the driver; tasks are sent to executors that have the required data (for shuffle read) or that are free.

---

<a id="tuning-configuration"></a>
## Tuning & Configuration

**18. What key configs would you tune for a large Spark job (e.g. executor memory, shuffle partitions, dynamic allocation)?**

- **Executor memory and cores**: Balance size (to avoid GC and OOM) with parallelism (more cores = more tasks per executor).  
- **`spark.sql.shuffle.partitions`**: Match to cluster size and data size; too high = many small tasks; too low = few large, slow tasks. AQE can adjust at runtime.  
- **Dynamic allocation**: `spark.dynamicAllocation.enabled` to scale executors with load; set min/max and shuffle service so executors can be removed without losing shuffle files.  
- **Memory and execution**: `spark.memory.fraction`, `spark.memory.storageFraction` (caching vs execution); consider off-heap for large shuffles.  
- **Broadcast**: `spark.sql.autoBroadcastJoinThreshold` for automatic broadcast; increase only if small tables are known to be safe.  
- **Adaptive Query Execution (AQE)**: Keep enabled (Spark 3) for coalescing shuffle partitions, handling skew, and optimizing joins.

**19. What is Adaptive Query Execution (AQE), and what problems does it address?**

AQE (Spark 3+) re-optimizes the query plan at runtime using statistics from completed stages. It can: (1) Coalesce shuffle partitions so the next stage doesn’t have too many small partitions. (2) Convert sort-merge join to broadcast join if the build side turns out small. (3) Optimize skewed joins by splitting skewed partitions (salting-like behavior). This reduces the need to guess shuffle partitions and helps with skew and join strategy without changing application code.

**20. When would you use cache() or persist(), and what are the pitfalls?**

Use when a DataFrame (or RDD) is reused multiple times (e.g. branched logic, iterative algorithms, or multiple actions on the same lineage). *Pitfalls*: (1) Caching uses memory (or disk); too much can cause eviction or OOM. (2) Cached data is recomputed if evicted; plan for stability (e.g. enough memory or disk). (3) Not unpersisting can hold resources until the application ends. (4) Cache is not shared across jobs or applications. For lead-level design: cache only what is reused, choose storage level (memory, disk, serialized), and unpersist when no longer needed.

---

<a id="reliability-correctness"></a>
## Reliability & Correctness

**21. What does “at least once” vs “exactly once” mean in the context of Spark writes?**

*At least once*: Tasks may be retried on failure, so some data may be written more than once; downstream systems may see duplicates. *Exactly once*: Despite retries, each record is written once (e.g. idempotent writes or transactional output). Spark’s task retry can re-execute a write task; to get exactly-once semantics you need idempotent writes (e.g. overwrite by key/partition) or a sink that supports transactions (e.g. Delta Lake). Lead-level pipelines often require exactly-once or deterministic deduplication on read.

**22. How would you design an incremental pipeline so that re-runs are safe (idempotent)?**

(1) **Partitioned overwrite**: Write output by partition (e.g. date); each run overwrites only the partitions it recomputed, so re-running the same day overwrites the same partition. (2) **Merge/upsert**: Use a format that supports merge (e.g. Delta, Iceberg) and merge by business key so re-runs update rather than duplicate. (3) **Deduplication on read**: If the sink is append-only, maintain a high-water mark or key set and deduplicate when reading (e.g. window + row_number). (4) **Deterministic keys**: Ensure same input always produces same output keys/partitions so overwrite is predictable.

**23. Why might you see duplicate or missing records when writing to a partitioned table with multiple tasks?**

Duplicates: If the write is append-only and tasks are retried, retried tasks can append the same data again. Or if the same partition is written by more than one task (e.g. wrong partition key or race), you get overlapping data. Missing: If a task fails after the driver thinks the job succeeded (rare), or if partition pruning or predicate pushdown excludes data that should be in scope. Mitigation: use overwrite-by-partition or transactional/merge writes; ensure partition keys are deterministic and that only one writer owns each partition per run.

---

<a id="file-formats-io"></a>
## File Formats & I/O

**24. Why is Parquet often preferred over CSV for large-scale Spark workloads?**

Parquet is columnar: (1) Better compression (same type in each column). (2) Predicate pushdown: only needed column chunks (and row groups) are read. (3) Schema embedded in the file; no inference pass. (4) Splittable and efficient for nested data. CSV is row-based, typically needs full scan and schema inference, and is less compact. For analytics and lakehouse patterns, Parquet (or similar columnar formats) is the default choice at lead level.

**25. What is predicate pushdown, and how does it affect job performance?**

Predicate pushdown means pushing filters down to the data source so that only data satisfying the filter is read (e.g. skip row groups in Parquet, or partition directories when partition columns are filtered). It reduces I/O and data passed to Spark. To benefit: (1) Use formats that support it (Parquet, ORC, etc.). (2) Filter on partition columns when data is partitioned by those columns. (3) Push filters in the logical plan (Spark does this for many sources); avoid breaking it (e.g. with UDFs that the optimizer cannot push down).

**26. What are the trade-offs of writing many small files vs few large files?**

*Many small files*: Overhead in listing, opening, and scheduling; small tasks; possible small-file problem in HDFS/S3. *Few large files*: Fewer tasks, less parallelism; large partitions can cause spill, OOM, or stragglers. Lead-level approach: aim for a reasonable file size (e.g. hundreds of MB to low GB per file) and partition count; use coalesce/repartition before write to control number and size; use AQE or post-processing (compaction jobs) to merge small files if the source produces many small partitions.

---

<a id="miscellaneous-lead-level"></a>
## Miscellaneous (Lead-Level)

**27. How would you approach debugging a Spark job that is slow or failing?**

(1) **Spark UI**: Identify the slow stage and the slow tasks; check shuffle read/write, task duration distribution (skew?), and spill. (2) **Event log**: Analyze with Spark History Server or tools for skew and bottlenecks. (3) **Logic**: Check for Cartesian products, unnecessary shuffles, or missing filters. (4) **Data**: Sample key distribution for skew; check for nulls or bad keys. (5) **Config**: Review executor memory, shuffle partitions, broadcast threshold, and AQE. (6) **Resource**: Check executor/driver OOM, GC, and cluster capacity.

**28. What is the role of the driver in a Spark application, and what happens if the driver fails?**

The driver runs the user code, builds the DAG, schedules tasks, and coordinates executors. If the driver fails, the application fails; executors are lost or reassigned. There is no automatic driver failover in standard Spark; for production you use cluster managers (e.g. YARN, K8s) to restart the driver and rerun the job, or run the driver in a fault-tolerant way (e.g. Spark on K8s with restarts). For streaming, use checkpointing so that after a driver restart, the streaming job can resume from the last checkpoint.

**29. When would you choose Spark over a distributed SQL engine (e.g. Trino, Dremio) or the other way around?**

*Spark*: Complex multi-step pipelines, custom logic (UDFs, ML, iterative algorithms), full control over partitioning and execution, and when you want one engine for batch, streaming, and ML. *Distributed SQL*: Ad-hoc queries, low-latency interactive analytics, and when the workload is mostly SQL and the data is in a format/catalog the engine optimizes for. Lead-level decision: use Spark for production ETL/ML pipelines and orchestrated batch; use a SQL engine for interactive query and reporting, unless the team standardizes on Spark SQL for everything.

**30. What is the small-file problem, and how can you mitigate it?**

Reading or writing many small files causes: (1) Lots of tasks (one per file or more). (2) Overhead in listing and opening files. (3) Poor compression and scan efficiency. *Mitigation*: (1) On write: coalesce or repartition so you write fewer, larger files. (2) On read: use formats that support file grouping or use a layout that groups data (e.g. partitioned tables). (3) Compaction jobs: periodically merge small files into larger ones (e.g. by partition). (4) Streaming: use micro-batch sizing or triggers to avoid writing tiny batches.

---

*Use this document to rehearse concepts and tie them to real tuning and design decisions (partitioning, join strategy, skew handling, idempotent writes).*
