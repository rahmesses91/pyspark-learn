"""
Minimal ETL example: Spark session, read CSV, aggregate, write Parquet.

Run from repo root (with PYTHONPATH=src) or from src:
  python -m pyspark.example_etl
  PYTHONPATH=src python src/pyspark/example_etl.py
"""
from pyspark.sql import functions as F

from .spark_session import spark_session_context
from .data_io import read_csv, write_parquet
from .transformations import aggregate_by_expr, select_columns, filter_condition


def run_example():
    with spark_session_context("ExampleETL", config={"spark.sql.shuffle.partitions": "4"}) as spark:
        # Create small in-memory dataset for demo (no external file needed)
        data = [
            ("east", "2024-01-01", 100),
            ("east", "2024-01-02", 150),
            ("west", "2024-01-01", 80),
            ("west", "2024-01-02", 120),
        ]
        df = spark.createDataFrame(data, ["region", "date", "revenue"])
        df.show()

        # Transform: filter and aggregate
        filtered = filter_condition(df, F.col("revenue") >= 90)
        agg = aggregate_by_expr(
            filtered,
            ["region"],
            F.sum("revenue").alias("total_revenue"),
            F.count("*").alias("transaction_count"),
        )
        agg.show()

        # Optional: write to local path (comment out if you don't want disk I/O)
        # write_parquet(agg, "output/example_etl", mode="overwrite")

    print("Example ETL completed.")


if __name__ == "__main__":
    run_example()
