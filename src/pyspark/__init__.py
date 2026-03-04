"""
PySpark utilities: session management, transformations, and I/O.

Usage:
    from src.pyspark import get_spark_session
    from src.pyspark.transformations import aggregate_by_expr, join_dataframes
    from src.pyspark.data_io import read_parquet, write_parquet
"""
from .transformations import (
    add_current_ts,
    add_literal_column,
    aggregate_by,
    aggregate_by_expr,
    cast_columns,
    deduplicate_keep_first,
    deduplicate_keep_last,
    drop_columns,
    drop_duplicates,
    drop_nulls,
    fill_nulls,
    filter_condition,
    join_dataframes,
    lag_lead,
    pivot_column,
    rank_over,
    rename_columns,
    row_number_over,
    select_columns,
)
from .spark_session import get_spark_session, spark_session_context, stop_spark_session
from .data_io import (
    read_csv,
    read_json,
    read_parquet,
    write_csv,
    write_parquet,
    write_table,
)

__all__ = [
    "get_spark_session",
    "stop_spark_session",
    "spark_session_context",
    "select_columns",
    "filter_condition",
    "drop_columns",
    "rename_columns",
    "aggregate_by",
    "aggregate_by_expr",
    "join_dataframes",
    "row_number_over",
    "rank_over",
    "lag_lead",
    "drop_duplicates",
    "deduplicate_keep_first",
    "deduplicate_keep_last",
    "pivot_column",
    "cast_columns",
    "fill_nulls",
    "drop_nulls",
    "add_literal_column",
    "add_current_ts",
    "read_csv",
    "read_parquet",
    "read_json",
    "write_parquet",
    "write_csv",
    "write_table",
]
