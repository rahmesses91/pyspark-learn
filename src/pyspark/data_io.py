"""
Read and write DataFrames for common formats.

Interview focus: options (header, schema, partitionBy), format choices, overwrite vs append.
"""
from __future__ import annotations

from typing import Any, Optional, Union

from pyspark.sql import DataFrame, SparkSession
from pyspark.sql.types import StructType


def read_csv(
    spark: SparkSession,
    path: str,
    header: bool = True,
    infer_schema: bool = True,
    schema: Optional[StructType] = None,
    delimiter: str = ",",
    **options: Any,
) -> DataFrame:
    """
    Read a CSV file or directory into a DataFrame.

    Args:
        spark: Active SparkSession.
        path: File or directory path (local or s3://, etc.).
        header: Use first line as header.
        infer_schema: Infer types from data; set False for all-string.
        schema: Optional explicit schema (use when infer_schema=False for performance).
        delimiter: Field delimiter.
        **options: Passed to DataFrameReader (e.g. nullValue="", dateFormat="yyyy-MM-dd").

    Returns:
        DataFrame.
    """
    reader = (
        spark.read.format("csv")
        .option("header", str(header).lower())
        .option("inferSchema", str(infer_schema).lower())
        .option("delimiter", delimiter)
    )
    if schema is not None:
        reader = reader.schema(schema)
    for k, v in options.items():
        reader = reader.option(k, v)
    return reader.load(path)


def read_parquet(
    spark: SparkSession,
    path: str,
    **options: Any,
) -> DataFrame:
    """
    Read Parquet file(s) or directory. Supports partition discovery by default.

    Args:
        spark: Active SparkSession.
        path: Path to file or directory.
        **options: Passed to DataFrameReader (e.g. mergeSchema=True for partitioned writes).
    """
    reader = spark.read.format("parquet")
    for k, v in options.items():
        reader = reader.option(k, v)
    return reader.load(path)


def read_json(
    spark: SparkSession,
    path: str,
    multi_line: bool = False,
    **options: Any,
) -> DataFrame:
    """
    Read JSON file(s). Use multi_line=True for one JSON object per line (JSONL).

    Args:
        spark: Active SparkSession.
        path: Path to file or directory.
        multi_line: If True, parse entire file as one JSON; if False, one JSON per line.
        **options: Passed to DataFrameReader.
    """
    reader = spark.read.format("json").option("multiLine", str(multi_line).lower())
    for k, v in options.items():
        reader = reader.option(k, v)
    return reader.load(path)


def write_parquet(
    df: DataFrame,
    path: str,
    mode: str = "overwrite",
    partition_by: Optional[list[str]] = None,
    **options: Any,
) -> None:
    """
    Write DataFrame to Parquet.

    Args:
        df: DataFrame to write.
        path: Output path (directory).
        mode: "overwrite", "append", "ignore", "error".
        partition_by: Column(s) to partition by (creates subdirs).
        **options: e.g. compression="snappy".
    """
    writer = df.write.format("parquet").mode(mode)
    if partition_by:
        writer = writer.partitionBy(*partition_by)
    for k, v in options.items():
        writer = writer.option(k, v)
    writer.save(path)


def write_csv(
    df: DataFrame,
    path: str,
    mode: str = "overwrite",
    header: bool = True,
    delimiter: str = ",",
    **options: Any,
) -> None:
    """
    Write DataFrame to CSV. Note: produces one or more part files (not a single file).

    Args:
        df: DataFrame to write.
        path: Output path (directory).
        mode: "overwrite", "append", "ignore", "error".
        header: Write header row.
        delimiter: Field delimiter.
        **options: Passed to DataFrameWriter.
    """
    writer = (
        df.write.format("csv")
        .mode(mode)
        .option("header", str(header).lower())
        .option("delimiter", delimiter)
    )
    for k, v in options.items():
        writer = writer.option(k, v)
    writer.save(path)


def write_table(
    df: DataFrame,
    table_name: str,
    mode: str = "overwrite",
    partition_by: Optional[list[str]] = None,
    format_or_provider: str = "parquet",
    **options: Any,
) -> None:
    """
    Write DataFrame to a Spark SQL table (e.g. Hive metastore or Spark catalog).

    Args:
        df: DataFrame to write.
        table_name: Fully qualified table name (e.g. "db.table" or "table").
        mode: "overwrite", "append", "ignore", "error".
        partition_by: Partition columns.
        format_or_provider: Table format (parquet, delta, etc.).
        **options: Table options.
    """
    writer = df.write.format(format_or_provider).mode(mode)
    if partition_by:
        writer = writer.partitionBy(*partition_by)
    for k, v in options.items():
        writer = writer.option(k, v)
    writer.saveAsTable(table_name)
