"""
Common PySpark data transformation functions.

Interview focus: DataFrame API, aggregations, joins, windows, deduplication, typing.
"""
from __future__ import annotations

from typing import Any, List, Optional, Union

from pyspark.sql import DataFrame
from pyspark.sql import functions as F
from pyspark.sql.window import Window


# --- Select & Filter ---


def select_columns(df: DataFrame, columns: List[str]) -> DataFrame:
    """Select a subset of columns."""
    return df.select(*columns)


def filter_condition(df: DataFrame, condition: Union[str, "F.Column"]) -> DataFrame:
    """Filter rows by a condition (equivalent to .where())."""
    return df.filter(condition)


def drop_columns(df: DataFrame, columns: List[str]) -> DataFrame:
    """Drop one or more columns."""
    return df.drop(*columns)


def rename_columns(df: DataFrame, rename_map: dict[str, str]) -> DataFrame:
    """Rename columns using a dict: old_name -> new_name."""
    for old, new in rename_map.items():
        df = df.withColumnRenamed(old, new)
    return df


# --- Aggregations ---


def aggregate_by(
    df: DataFrame,
    group_cols: List[str],
    agg_exprs: Optional[dict[str, Any]] = None,
    *agg_columns: Any,
) -> DataFrame:
    """
    Group by columns and apply aggregations.

    Args:
        df: Source DataFrame.
        group_cols: Columns to group by.
        agg_exprs: Optional dict of {alias: expr}, e.g. {"total": F.sum("amount")}.
        *agg_columns: Alternatively, pass F.sum("col").alias("total"), etc. directly.

    Returns:
        Aggregated DataFrame.
    """
    if agg_exprs:
        exprs = [v.alias(k) for k, v in agg_exprs.items()]
        return df.groupBy(*group_cols).agg(*exprs)
    if agg_columns:
        return df.groupBy(*group_cols).agg(*agg_columns)
    return df.groupBy(*group_cols).count()


def aggregate_by_expr(
    df: DataFrame,
    group_cols: List[str],
    *agg_exprs: Any,
) -> DataFrame:
    """
    Group by and aggregate using F.sum(), F.avg(), etc. directly.

    Example:
        aggregate_by_expr(df, ["region"], F.sum("revenue").alias("total_rev"), F.count("*").alias("cnt"))
    """
    return df.groupBy(*group_cols).agg(*agg_exprs)


# --- Joins ---


def join_dataframes(
    left: DataFrame,
    right: DataFrame,
    on: Optional[Union[str, List[str]]] = None,
    how: str = "inner",
    left_on: Optional[List[str]] = None,
    right_on: Optional[List[str]] = None,
) -> DataFrame:
    """
    Join two DataFrames.

    Args:
        left, right: DataFrames to join.
        on: Column name(s) if same in both; can be str or list.
        how: "inner", "left", "right", "full", "left_anti", "left_semi", "cross".
        left_on / right_on: Use when join key names differ (lengths must match).

    Returns:
        Joined DataFrame.
    """
    if on is not None:
        join_cols = [on] if isinstance(on, str) else list(on)
        return left.join(right, on=join_cols, how=how)
    if left_on is not None and right_on is not None:
        return left.join(
            right,
            [left[f] == right[r] for f, r in zip(left_on, right_on)],
            how=how,
        ).drop(*[right[r] for r in right_on])
    raise ValueError("Provide either 'on' or both 'left_on' and 'right_on'.")


# --- Window functions ---


def row_number_over(
    df: DataFrame,
    partition_by: List[str],
    order_by: List[Union[str, "F.Column"]],
    output_col: str = "row_num",
) -> DataFrame:
    """
    Add row number within each partition, ordered by given columns.

    Useful for deduplication (keep row_num == 1) or top-N per group.
    """
    order_cols = [F.col(c).asc() if isinstance(c, str) else c for c in order_by]
    w = Window.partitionBy(*partition_by).orderBy(*order_cols)
    return df.withColumn(output_col, F.row_number().over(w))


def rank_over(
    df: DataFrame,
    partition_by: List[str],
    order_by: List[Union[str, "F.Column"]],
    output_col: str = "rank",
) -> DataFrame:
    """Rank rows within partition (ties get same rank, gap after ties)."""
    order_cols = [F.col(c).asc() if isinstance(c, str) else c for c in order_by]
    w = Window.partitionBy(*partition_by).orderBy(*order_cols)
    return df.withColumn(output_col, F.rank().over(w))


def lag_lead(
    df: DataFrame,
    col_name: str,
    partition_by: List[str],
    order_by: List[str],
    offset: int = 1,
    default: Any = None,
    lag: bool = True,
    output_col: Optional[str] = None,
) -> DataFrame:
    """
    Add lag or lead column.

    Args:
        col_name: Column to lag/lead.
        partition_by: Partition spec.
        order_by: Order spec.
        offset: Number of rows back (lag) or forward (lead).
        default: Default when no previous/next row.
        lag: If True use lag, else lead.
        output_col: Name for new column (default: col_lag_N or col_lead_N).
    """
    order_cols = [F.col(c).asc() if isinstance(c, str) else c for c in order_by]
    w = Window.partitionBy(*partition_by).orderBy(*order_cols)
    name = output_col or f"{col_name}_{'lag' if lag else 'lead'}_{offset}"
    fn = F.lag(F.col(col_name), offset, default) if lag else F.lead(F.col(col_name), offset, default)
    return df.withColumn(name, fn.over(w))


# --- Deduplication ---


def drop_duplicates(
    df: DataFrame,
    subset: Optional[List[str]] = None,
    keep: str = "first",
) -> DataFrame:
    """
    Remove duplicate rows.

    Args:
        subset: Columns to consider for duplicates; None = all columns.
        keep: "first" or "last" — which row to keep per duplicate key.
    """
    return df.dropDuplicates(subset=subset)  # PySpark uses first by default; "last" needs window
    # For "last": use row_number_over then filter row_num == 1 on reversed order.


def deduplicate_keep_first(
    df: DataFrame,
    key_columns: List[str],
    order_by: List[str],
) -> DataFrame:
    """
    Deduplicate by key_columns, keeping the first row per key after ordering by order_by.
    """
    with_row = row_number_over(df, partition_by=key_columns, order_by=order_by, output_col="_rn")
    return with_row.filter(F.col("_rn") == 1).drop("_rn")


def deduplicate_keep_last(
    df: DataFrame,
    key_columns: List[str],
    order_by: List[str],
) -> DataFrame:
    """Deduplicate by key_columns, keeping the last row per key (by order_by)."""
    with_row = row_number_over(
        df,
        partition_by=key_columns,
        order_by=[F.col(c).desc() for c in order_by],
        output_col="_rn",
    )
    return with_row.filter(F.col("_rn") == 1).drop("_rn")


# --- Pivot ---


def pivot_column(
    df: DataFrame,
    group_cols: List[str],
    pivot_col: str,
    value_col: str,
    agg_func: str = "sum",
) -> DataFrame:
    """
    Pivot pivot_col values into columns, aggregating value_col.

    Example: pivot_column(df, ["id"], "metric", "value") -> columns id, metric_a, metric_b, ...
    """
    return df.groupBy(*group_cols).pivot(pivot_col).agg(F.expr(agg_func + "(" + value_col + ")"))


# --- Type & casting ---


def cast_columns(df: DataFrame, cast_map: dict[str, str]) -> DataFrame:
    """
    Cast columns to types. cast_map: {col_name: type_string}, e.g. {"amount": "double"}.
    """
    for col_name, type_str in cast_map.items():
        df = df.withColumn(col_name, F.col(col_name).cast(type_str))
    return df


# --- Null handling ---


def fill_nulls(df: DataFrame, fill_map: dict[str, Any]) -> DataFrame:
    """Fill nulls with given values. fill_map: {col_name: value}."""
    return df.fillna(fill_map)


def drop_nulls(df: DataFrame, subset: Optional[List[str]] = None) -> DataFrame:
    """Drop rows with null in given columns; if subset is None, drop if any column is null."""
    return df.dropna(subset=subset)


# --- Simple withColumn helpers ---


def add_literal_column(df: DataFrame, col_name: str, value: Any) -> DataFrame:
    """Add a column with a constant value."""
    return df.withColumn(col_name, F.lit(value))


def add_current_ts(df: DataFrame, col_name: str = "ingestion_ts") -> DataFrame:
    """Add current timestamp column."""
    return df.withColumn(col_name, F.current_timestamp())
