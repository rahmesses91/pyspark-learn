# PySpark — Lead Data Engineer Interview Prep

This package provides reusable Spark session setup, data transformations, and I/O helpers. Use it to practice and reference common patterns in interviews.

## Layout

| Module | Purpose |
|--------|--------|
| `spark_session.py` | Create/configure SparkSession, context manager for clean shutdown |
| `transformations.py` | Select, filter, agg, join, window, dedupe, pivot, null handling |
| `data_io.py` | Read/write CSV, Parquet, JSON; write to tables |

## Setup

Install dependencies (use a venv): `pip install -r requirements.txt` from the repo root. Then run examples with `PYTHONPATH=src python -m pyspark.example_etl`.

## Quick start

```python
from pyspark.sql import functions as F
from src.pyspark import get_spark_session, read_csv, aggregate_by_expr, write_parquet

spark = get_spark_session("MyJob", config={"spark.sql.shuffle.partitions": "8"})
df = read_csv(spark, "data/input.csv")
agg = aggregate_by_expr(df, ["region"], 
    F.sum("revenue").alias("total_rev"), 
    F.count("*").alias("cnt"))
write_parquet(agg, "data/output")
spark.stop()
```

Or with context manager:

```python
from src.pyspark import spark_session_context, read_parquet, transformations

with spark_session_context("BatchJob") as spark:
    df = read_parquet(spark, "path/to/data")
    out = transformations.deduplicate_keep_first(df, ["id"], ["updated_at"])
    out.show()
```

## Interview topics to know

### 1. SparkSession & execution model
- **SparkSession**: Single entry point (Spark 2+); replaces SparkContext + SQLContext.
- **Driver vs executors**: Driver runs your script and schedules tasks; executors run tasks and hold data.
- **Lazy evaluation**: Transformations (e.g. `filter`, `select`) build a DAG; actions (e.g. `count()`, `show()`, `write`) trigger execution.
- **Narrow vs wide dependencies**: Narrow = map-like (e.g. filter); wide = shuffle (e.g. groupBy, join). Affects partitioning and failure recovery.

### 2. Partitioning & shuffle
- **Partitions**: Data is split into partitions; one task per partition per stage.
- **shuffle.partitions**: Number of output partitions after a shuffle (e.g. after `groupBy` or join). Tune for cluster size and data size.
- **partitionBy** on write: Writes data into subdirectories by key; enables partition pruning on read.
- **coalesce vs repartition**: `coalesce` reduces partitions (no full shuffle); `repartition` does a full shuffle. Use coalesce when reducing, repartition when increasing or balancing.

### 3. DataFrame API (vs RDD / SQL)
- **Structured API**: DataFrame/Dataset — catalyst optimizer, columnar execution, often faster than RDD.
- **Select, filter, withColumn, drop**: Column operations; use `F.col("x")`, `F.when/otherwise`, `F.expr()` for SQL-like expressions.
- **Aggregations**: `groupBy(...).agg(F.sum("col"), F.count("*"), F.avg("col"))`; know `count(*)` vs `count(col)` (nulls).
- **Joins**: inner, left, right, full, left_anti, left_semi; broadcast for small side; avoid Cartesian products.

### 4. Window functions
- **Partition + order**: `Window.partitionBy("key").orderBy("ts")`.
- **row_number(), rank(), dense_rank()**: Dedupe (row_number), ranking with gaps (rank) or no gaps (dense_rank).
- **lag/lead**: Access previous/next row; default for missing row.
- **Running sums**: `F.sum("amount").over(Window.partitionBy("id").orderBy("dt").rowsBetween(Window.unboundedPreceding, Window.currentRow))`.

### 5. Deduplication strategies
- **dropDuplicates(subset)**: Keeps first occurrence (order not guaranteed unless you sort first).
- **Window + row_number**: Order by desired columns, filter `row_number() == 1` for deterministic “keep first” or “keep last”.

### 6. Read/write & formats
- **Parquet**: Columnar, predicate pushdown, good compression; default for many data lakes.
- **CSV**: Schema inference or explicit schema; options for header, delimiter, nullValue.
- **Write modes**: overwrite, append, ignore, error.
- **Partitioned writes**: `partitionBy("date", "region")` for partition pruning and efficient overwrites of a subset.

### 7. Performance & tuning
- **Broadcast join**: For small dimension table, `broadcast(df)` or `spark.conf.set("spark.sql.autoBroadcastJoinThreshold", ...)`.
- **Adaptive Query Execution (AQE)**: Coalesce shuffle partitions, optimize skew joins; usually keep enabled.
- **Caching**: `df.cache()` or `persist()` when reused; understand storage levels and when to unpersist.
- **Skew**: Skewed keys cause slow tasks; techniques: salting, two-phase agg, broadcast if one side is small.

### 8. Testing & local dev
- **local[*]**: Run locally using all cores; good for scripts and small datasets.
- **Unit tests**: Use small in-memory DataFrames; avoid starting a real cluster when possible (e.g. pytest with `local[*]` or mock).

### 9. SQL vs DataFrame
- **spark.sql("SELECT ...")**: Same engine; use when query is clearer in SQL or for compatibility.
- **Temp views**: `df.createOrReplaceTempView("t")` then `spark.sql("SELECT * FROM t")`.

### 10. Lead-level topics
- **Incremental processing**: Read only new partitions or use watermarks (streaming); idempotent writes.
- **Schema evolution**: Merge schema on read; Delta Lake or similar for ACID and schema evolution.
- **Resource configuration**: Executor memory, cores, dynamic allocation; tuning for cost and SLA.
- **Monitoring**: Spark UI (stages, tasks, shuffle read/write); identifying skew and spill.

## Lead-level interview prep (concepts only)

- **`LEAD_SPARK_INTERVIEW_QUESTIONS.md`** — 30 conceptual Q&As on shuffling, partitioning, broadcast joins, data skew, execution model, tuning, reliability, file formats, and debugging. No code.
- **`LEAD_SPARK_DEEP_INTERVIEW_QUESTIONS.md`** — 50 deep, Principal-level Q&As: architecture (DAG, Catalyst, Tungsten, whole-stage codegen), shuffling & joins (sort-based shuffle, spill, broadcast/sort-merge, skew, AQE), partitioning (narrow/wide, repartition/coalesce, custom partitioners, small files, locality), performance (memory, GC, serialization, cache, checkpoint, OOM, executor sizing, dynamic allocation), data skew (causes, detection, salting, hints), Spark SQL (pushdown, pruning, bucketing, Parquet vs ORC, CBO), streaming (micro-batch, watermark, exactly-once, checkpoint), production (design at scale, failure recovery, idempotency, monitoring, anti-patterns, when not to use Spark). Each answer includes real-world scenario, common mistakes, and Lead-level expectations. Ends with recurring patterns, Senior vs Lead differentiation, and a 2-week revision roadmap.

## Example scripts

- **`example_etl.py`** — Minimal ETL: session, in-memory DataFrame, filter, aggregate, show.
- **`windows_and_joins_example.py`** — Windows (row_number, rank, lag/lead, running sum) and joins (inner, left, left_anti, different key names). Run: `PYTHONPATH=src python -m pyspark.windows_and_joins_example`.
