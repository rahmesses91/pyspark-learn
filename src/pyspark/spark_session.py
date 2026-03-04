"""
Spark session initialization and lifecycle utilities.

Interview focus: SparkSession builder, config, local vs cluster, resource tuning.
"""
from __future__ import annotations

from typing import Any, Optional

from pyspark.sql import SparkSession


def get_spark_session(
    app_name: str = "PySparkApp",
    master: str = "local[*]",
    config: Optional[dict[str, Any]] = None,
    **kwargs: Any,
) -> SparkSession:
    """
    Get or create a SparkSession with optional configuration.

    Args:
        app_name: Application name (shows in Spark UI).
        master: Spark master URL. Use "local[*]" for local (all cores), "local" for single thread.
        config: Optional dict of Spark config keys/values (e.g. {"spark.sql.shuffle.partitions": "200"}).
        **kwargs: Passed to SparkSession.builder (e.g. config(key, value)).

    Returns:
        SparkSession instance.

    Example:
        >>> spark = get_spark_session("MyETL", config={"spark.sql.shuffle.partitions": "8"})
    """
    builder = (
        SparkSession.builder.appName(app_name)
        .master(master)
        .config("spark.sql.adaptive.enabled", "true")
    )
    if config:
        for k, v in config.items():
            builder = builder.config(k, str(v))
    for k, v in kwargs.items():
        builder = builder.config(k, v)
    return builder.getOrCreate()


def stop_spark_session(spark: SparkSession) -> None:
    """Stop the given SparkSession and underlying SparkContext."""
    spark.stop()


def spark_session_context(
    app_name: str = "PySparkApp",
    master: str = "local[*]",
    config: Optional[dict[str, Any]] = None,
    **kwargs: Any,
):
    """
    Context manager that creates a SparkSession and stops it on exit.

    Example:
        with spark_session_context("BatchJob") as spark:
            df = spark.read.parquet("path/to/data")
            df.show()
    """
    spark = get_spark_session(app_name=app_name, master=master, config=config, **kwargs)
    try:
        yield spark
    finally:
        stop_spark_session(spark)
