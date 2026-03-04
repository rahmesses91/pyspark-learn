"""
Windows and joins example: PySpark window functions and DataFrame joins.

Demonstrates:
  - Joins: inner, left, left_anti (e.g. "customers with no orders").
  - Windows: row_number (top-N / dedupe), rank, lag/lead, running sum.

Run from repo root:
  PYTHONPATH=src python -m pyspark.windows_and_joins_example
"""
from __future__ import annotations

from pyspark.sql import DataFrame
from pyspark.sql import functions as F
from pyspark.sql.window import Window

from .spark_session import spark_session_context
from .transformations import (
    join_dataframes,
    row_number_over,
    rank_over,
    lag_lead,
    deduplicate_keep_first,
)


def _create_sample_data(spark):
    """
    Build in-memory sample DataFrames for demos.

    Returns:
        (orders, customers, products) where:
          - orders: order_id, customer_id, product_id, amount, order_date
          - customers: customer_id, customer_name, region
          - products: product_id, product_name, category
    """
    orders_data = [
        (1, "c1", "p1", 100.0, "2024-01-01"),
        (2, "c1", "p2", 50.0, "2024-01-05"),
        (3, "c1", "p1", 75.0, "2024-01-10"),
        (4, "c2", "p2", 200.0, "2024-01-02"),
        (5, "c2", "p3", 90.0, "2024-01-08"),
        (6, "c3", "p1", 60.0, "2024-01-03"),
    ]
    customers_data = [
        ("c1", "Alice", "east"),
        ("c2", "Bob", "west"),
        ("c3", "Carol", "east"),
        ("c4", "Dave", "west"),  # no orders
    ]
    products_data = [
        ("p1", "Widget A", "tools"),
        ("p2", "Widget B", "tools"),
        ("p3", "Gadget C", "electronics"),
    ]
    orders = spark.createDataFrame(
        orders_data,
        ["order_id", "customer_id", "product_id", "amount", "order_date"],
    )
    customers = spark.createDataFrame(
        customers_data,
        ["customer_id", "customer_name", "region"],
    )
    products = spark.createDataFrame(
        products_data,
        ["product_id", "product_name", "category"],
    )
    return orders, customers, products


# -----------------------------------------------------------------------------
# Joins
# -----------------------------------------------------------------------------


def demo_inner_join(orders: DataFrame, customers: DataFrame) -> DataFrame:
    """
    Inner join: only rows that match in both DataFrames.

    Use when you want only (order, customer) pairs that exist in both tables.
    Customers with no orders (e.g. Dave) are excluded.

    Returns:
        DataFrame with order columns plus customer_name, region.
    """
    return join_dataframes(orders, customers, on="customer_id", how="inner")


def demo_left_join(customers: DataFrame, orders: DataFrame) -> DataFrame:
    """
    Left join: all rows from left, matched rows from right; nulls where no match.

    Use when you want "all customers, and their order info if any".
    Customers with no orders still appear, with null in order columns.

    Returns:
        DataFrame with all customers; order columns null for customers with no orders.
    """
    # Aggregate orders per customer first, then left join to customers
    from .transformations import aggregate_by_expr

    order_summary = aggregate_by_expr(
        orders,
        ["customer_id"],
        F.sum("amount").alias("total_amount"),
        F.count("*").alias("order_count"),
    )
    return join_dataframes(customers, order_summary, on="customer_id", how="left")


def demo_left_anti_join(customers: DataFrame, orders: DataFrame) -> DataFrame:
    """
    Left anti join: rows in left that have NO match in right.

    Use for "customers who never placed an order" or "products never sold".
    Equivalent to: left minus (left inner join right on key).

    Returns:
        DataFrame of customers that do not appear in orders (e.g. Dave).
    """
    return join_dataframes(customers, orders, on="customer_id", how="left_anti")


def demo_join_different_key_names(
    orders: DataFrame, products: DataFrame
) -> DataFrame:
    """
    Join when key column names differ (e.g. orders.product_id vs products.product_id).

    Uses left_on / right_on so both keys are specified explicitly.
    After join, the right key column is dropped to avoid duplication.
    """
    return join_dataframes(
        orders,
        products,
        left_on=["product_id"],
        right_on=["product_id"],
        how="left",
    )


# -----------------------------------------------------------------------------
# Window functions
# -----------------------------------------------------------------------------


def demo_row_number(orders: DataFrame) -> DataFrame:
    """
    Row number within partition: assign 1, 2, 3, ... per group in order.

    Use for:
      - Deduplication: keep row_num == 1 after ordering by "latest" or "preferred".
      - Top-N per group: e.g. "last 3 orders per customer" (filter row_num <= 3
        after ordering by date desc).

    Returns:
        Orders with row_num per (customer_id), ordered by order_date.
    """
    return row_number_over(
        orders,
        partition_by=["customer_id"],
        order_by=["order_date"],
        output_col="row_num",
    )


def demo_rank(orders: DataFrame) -> DataFrame:
    """
    Rank within partition: same value for ties, then skip (1, 2, 2, 4, ...).

    Use when you need "rank by amount" and ties get the same rank with a gap
    after. For no gap use dense_rank(); for unique ordering use row_number().

    Returns:
        Orders with rank per (customer_id) by amount descending (highest = 1).
    """
    return rank_over(
        orders,
        partition_by=["customer_id"],
        order_by=[F.col("amount").desc()],
        output_col="rank_by_amount",
    )


def demo_lag_lead(orders: DataFrame) -> DataFrame:
    """
    Lag: previous row's value; lead: next row's value (within partition and order).

    Use for:
      - Period-over-period: compare to previous day/week.
      - Gaps: "next_order_date" minus "order_date" = days between orders.

    Returns:
        Orders with prev_amount (lag 1) and next_amount (lead 1) per customer by date.
    """
    with_lag = lag_lead(
        orders,
        "amount",
        partition_by=["customer_id"],
        order_by=["order_date"],
        offset=1,
        output_col="prev_amount",
        lag=True,
    )
    return lag_lead(
        with_lag,
        "amount",
        partition_by=["customer_id"],
        order_by=["order_date"],
        offset=1,
        output_col="next_amount",
        lag=False,
    )


def demo_running_sum(orders: DataFrame) -> DataFrame:
    """
    Running (cumulative) sum within partition: sum of all rows up to current row.

    Uses a window with rowsBetween(Window.unboundedPreceding, Window.currentRow)
    so the frame is "from partition start to current row".

    Use for: cumulative revenue per customer, running balance, YTD metrics.

    Returns:
        Orders with cumulative amount per (customer_id) ordered by order_date.
    """
    w = (
        Window.partitionBy("customer_id")
        .orderBy(F.col("order_date").asc())
        .rowsBetween(Window.unboundedPreceding, Window.currentRow)
    )
    return orders.withColumn("running_sum_amount", F.sum("amount").over(w))


def demo_deduplicate_keep_latest_order(orders: DataFrame) -> DataFrame:
    """
    Deduplicate by key, keeping one row per key (e.g. "latest order per customer").

    Implemented as: partition by key, order by date desc, keep row_number == 1.
    Uses the transformation deduplicate_keep_last(key_columns, order_by).

    Returns:
        One row per customer_id: the row with the latest order_date.
    """
    return deduplicate_keep_last(
        orders,
        key_columns=["customer_id"],
        order_by=["order_date"],
    )


# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------


def run_all():
    """Run join and window demos and print sample output."""
    with spark_session_context(
        "WindowsAndJoinsExample",
        config={"spark.sql.shuffle.partitions": "4"},
    ) as spark:
        orders, customers, products = _create_sample_data(spark)

        print("=== Sample input: orders ===")
        orders.show()

        print("=== Joins ===")
        print("--- Inner join (orders + customers) ---")
        demo_inner_join(orders, customers).show()

        print("--- Left join (all customers + order summary) ---")
        demo_left_join(customers, orders).show()

        print("--- Left anti (customers with NO orders) ---")
        demo_left_anti_join(customers, orders).show()

        print("--- Join with different key names (orders + products) ---")
        demo_join_different_key_names(orders, products).show()

        print("=== Windows ===")
        print("--- Row number per customer by date ---")
        demo_row_number(orders).show()

        print("--- Rank by amount per customer (desc) ---")
        demo_rank(orders).show()

        print("--- Lag / lead amount per customer by date ---")
        demo_lag_lead(orders).show()

        print("--- Running sum amount per customer by date ---")
        demo_running_sum(orders).show()

        print("--- Deduplicate: keep latest order per customer ---")
        demo_deduplicate_keep_latest_order(orders).show()

    print("Windows and joins example completed.")


if __name__ == "__main__":
    run_all()
