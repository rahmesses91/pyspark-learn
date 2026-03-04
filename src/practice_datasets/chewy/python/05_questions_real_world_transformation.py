"""
Chewy Interview Research — Domain D: Real-World Data Transformation

SQL-like operations in Python: joins, group-by, pivot, rollup, sessions. Analytics Engineer focus.
"""

from typing import List, Dict, Any, Optional

# ---------------------------------------------------------------------------
# Dataset requirements (align with Chewy DATA_DICTIONARY where possible)
# ---------------------------------------------------------------------------

DATASETS = {
    "orders_and_products": {
        "description": "Two lists of dicts: orders (order_id, user_id, product_id, quantity) and products (product_id, name, price). Inner join on product_id.",
        "sample": [
            [{"order_id": 1, "product_id": 101, "quantity": 2}, {"order_id": 2, "product_id": 102, "quantity": 1}],
            [{"product_id": 101, "name": "Dog Food", "price": 29.99}, {"product_id": 102, "name": "Cat Toy", "price": 9.99}],
        ],
    },
    "referrals": {
        "description": "List of (user_id, referred_by_id) tuples; referred_by_id can be None. Find all users referred by a given user.",
        "sample": [[(1, None), (2, 1), (3, 1), (4, 2), (5, 1)]],
    },
    "long_format_sales": {
        "description": "List of dicts: {user_id, month, spend}. Pivot to wide: user_id -> {month: spend} or month -> {user_id: spend}.",
        "sample": [[{"user_id": 1, "month": "2024-01", "spend": 50}, {"user_id": 1, "month": "2024-02", "spend": 30}, {"user_id": 2, "month": "2024-01", "spend": 20}]],
    },
    "sales_day_store": {
        "description": "List of dicts: {day, store_id, amount}. Rollup to store level: store_id -> total amount (and optionally count).",
        "sample": [[{"day": "2024-01-01", "store_id": "A", "amount": 100}, {"day": "2024-01-01", "store_id": "B", "amount": 80}, {"day": "2024-01-02", "store_id": "A", "amount": 120}]],
    },
    "user_timestamps": {
        "description": "List of (user_id, timestamp); timestamps are datetime or sortable. Find user with longest session (max last - first per user).",
        "sample": [[(1, "2024-01-01 10:00"), (1, "2024-01-01 10:30"), (2, "2024-01-01 09:00"), (2, "2024-01-01 12:00")]],
    },
    "left_table_right_table": {
        "description": "Two lists of dicts with a join key (e.g. id). Left join: keep all left rows; add right columns where key matches.",
        "sample": [
            [{"id": 1, "name": "A"}, {"id": 2, "name": "B"}, {"id": 3, "name": "C"}],
            [{"id": 1, "score": 90}, {"id": 2, "score": 85}],
        ],
    },
    "rows_with_schema_filter": {
        "description": "List of dicts (rows) and a set of allowed values for a key (e.g. allowed_category). Filter rows where column in set.",
        "sample": [[{"id": 1, "category": "dogs"}, {"id": 2, "category": "cats"}, {"id": 3, "category": "birds"}], {"dogs", "cats"}],
    },
    "running_total_by_group": {
        "description": "List of dicts: (user_id, date, amount). Compute running total (cumulative sum) of amount per user_id, ordered by date.",
        "sample": [[{"user_id": 1, "date": "01-01", "amount": 10}, {"user_id": 1, "date": "01-02", "amount": 20}, {"user_id": 2, "date": "01-01", "amount": 5}]],
    },
    "scores_per_category": {
        "description": "List of dicts: (id, category, score). Assign dense_rank (or rank) within each category by score (desc).",
        "sample": [[{"id": 1, "category": "A", "score": 90}, {"id": 2, "category": "A", "score": 85}, {"id": 3, "category": "B", "score": 88}]],
    },
    "duplicate_keys_list": {
        "description": "List of dicts with a key field (e.g. order_id). Find and return rows where key appears more than once (duplicates).",
        "sample": [[{"order_id": 1, "amt": 10}, {"order_id": 2, "amt": 20}, {"order_id": 1, "amt": 15}]],
    },
    "two_sorted_streams": {
        "description": "Two lists of dicts, each sorted by timestamp (or id). Merge into one sorted stream (merge two sorted lists).",
        "sample": [
            [{"ts": 1, "src": "A"}, {"ts": 3, "src": "A"}],
            [{"ts": 2, "src": "B"}, {"ts": 4, "src": "B"}],
        ],
    },
    "orders_per_user_top_n": {
        "description": "List of dicts: (user_id, order_id, amount). For each user, get top N orders by amount (e.g. top 3).",
        "sample": [[{"user_id": 1, "order_id": 1, "amount": 50}, {"user_id": 1, "order_id": 2, "amount": 100}, {"user_id": 1, "order_id": 3, "amount": 30}]],
    },
    "time_between_events": {
        "description": "List of (user_id, event_type, timestamp). For each user, compute time between first and second purchase (or first two events of type X).",
        "sample": [[(1, "purchase", "10:00"), (1, "purchase", "10:45"), (2, "purchase", "11:00")]],
    },
    "events_csv_like": {
        "description": "In-memory list of event rows (e.g. from events.csv): user_id, event_time, event_type, product_id. Aggregate: count events per (user, event_type).",
        "sample": "Use events.csv schema: user_id, event_time, event_type, product_id, session_id",
    },
}

QUESTIONS: List[Dict[str, Any]] = [
    {
        "id": "D01",
        "title": "Inner Join Simulator (Hash Join)",
        "description": (
            "Given two lists of dicts (e.g. orders and products) and a join key, perform an inner join. "
            "Use a dict built from the smaller table for O(n+m) hash-join; avoid nested loop O(n*m)."
        ),
        "core_concepts": ["Hash join", "Build dict key -> row(s)", "Iterate other list and lookup"],
        "why_chewy": "Core ETL: joining orders with product/catalog data.",
        "interviewer_evaluates": "Implementing hash-join; handling multiple rows per key (one-to-many).",
        "common_mistakes": "Nested loops; not handling duplicate keys in build side.",
        "dataset_required": "orders_and_products",
    },
    {
        "id": "D02",
        "title": "Self-Join for Referrals (Who Did User X Refer?)",
        "description": (
            "Given a list of (user_id, referred_by_id), build a structure (e.g. dict: referred_by_id -> list of user_id) "
            "and answer: return all users referred by a given user_id. Handle cycles or null referred_by if present."
        ),
        "core_concepts": ["Dict of lists", "Group by referred_by_id", "Optional: cycle detection"],
        "why_chewy": "Referral programs; hierarchy of customers.",
        "interviewer_evaluates": "defaultdict(list) or setdefault; not confusing referrer with referred.",
        "common_mistakes": "Building wrong direction (user -> referrer only); not handling None.",
        "dataset_required": "referrals",
    },
    {
        "id": "D03",
        "title": "Pivot Long to Wide",
        "description": (
            "Given long-format list of dicts (e.g. user_id, month, spend), transform to wide format: "
            "e.g. dict[user_id][month] = spend, or list of dicts with one row per user and columns per month."
        ),
        "core_concepts": ["Nested dict or defaultdict", "Iterate and assign", "Optional: fill missing with 0"],
        "why_chewy": "Reporting and analytics; turning event streams into tabular format.",
        "interviewer_evaluates": "Correct nesting; handling missing (user, month) pairs.",
        "common_mistakes": "Overwriting when same (user, month) appears twice; wrong key order.",
        "dataset_required": "long_format_sales",
    },
    {
        "id": "D04",
        "title": "Rollup Aggregation (Day-Store to Store)",
        "description": (
            "Given list of dicts at (day, store_id, amount), aggregate to store level: store_id -> total amount (and optionally count of days). "
            "Use dict or defaultdict to accumulate."
        ),
        "core_concepts": ["Dictionary accumulation", "Sum per key", "Optional: count"],
        "why_chewy": "Rolling up daily sales to store or category totals.",
        "interviewer_evaluates": "Correct initialization; not resetting accumulator.",
        "common_mistakes": "Not initializing; using list and summing at end (inefficient for large data).",
        "dataset_required": "sales_day_store",
    },
    {
        "id": "D05",
        "title": "Longest Session (User with Max Time Span)",
        "description": (
            "Given list of (user_id, timestamp), compute per user the time span (max timestamp - min timestamp). "
            "Return the user_id with the longest span (or top k). One pass: dict of min/max per user."
        ),
        "core_concepts": ["Dict of min and max per user", "Single pass", "Datetime subtraction or numeric diff"],
        "why_chewy": "Session length analytics; engagement metrics.",
        "interviewer_evaluates": "One pass; handling single-event users (span 0).",
        "common_mistakes": "Multiple passes; wrong type for timestamp (string vs datetime).",
        "dataset_required": "user_timestamps",
    },
    {
        "id": "D06",
        "title": "Left Join Simulator",
        "description": (
            "Given two lists of dicts and a join key, perform a left join: every row from the left list appears once; "
            "add columns from the right row when key matches; otherwise null/missing for right columns."
        ),
        "core_concepts": ["Build dict from right table", "Iterate left and lookup", "Copy dict and update"],
        "why_chewy": "Enriching orders with optional product attributes; keeping all orders.",
        "interviewer_evaluates": "All left rows preserved; correct handling of missing key in right.",
        "common_mistakes": "Dropping left rows when no match; mutating original dicts.",
        "dataset_required": "left_table_right_table",
    },
    {
        "id": "D07",
        "title": "Filter Rows by Column in Set",
        "description": (
            "Given a list of dicts and a set of allowed values for a given column (e.g. allowed categories), "
            "return a new list of rows where the column value is in the set. Use set for O(1) lookup."
        ),
        "core_concepts": ["List comprehension", "Set membership", "Copy row dicts if needed"],
        "why_chewy": "Filtering events or products by category/segment.",
        "interviewer_evaluates": "Using set not list for allowed; handling missing key in row.",
        "common_mistakes": "Using list for allowed (O(n) per row); in-place mutation of original.",
        "dataset_required": "rows_with_schema_filter",
    },
    {
        "id": "D08",
        "title": "Running Total by Group",
        "description": (
            "Given list of dicts (user_id, date, amount), add a running_total field per user (cumulative sum of amount ordered by date). "
            "Return new list of dicts with running_total. Sort by user and date first; then accumulate per user."
        ),
        "core_concepts": ["Sort by group key and order key", "Accumulate per group", "New dict or copy"],
        "why_chewy": "Cumulative spend or order count per user over time.",
        "interviewer_evaluates": "Correct sort; resetting accumulator when user changes.",
        "common_mistakes": "Global running total instead of per user; wrong sort order.",
        "dataset_required": "running_total_by_group",
    },
    {
        "id": "D09",
        "title": "Dense Rank Within Category",
        "description": (
            "Given list of dicts (id, category, score), add a rank field: within each category, rank by score descending (1 = highest). "
            "Dense rank: ties get same rank; next rank is +1. Use sort + single pass with rank counter per category."
        ),
        "core_concepts": ["Sort by category and score desc", "Track previous (category, score) and rank", "Assign rank"],
        "why_chewy": "Top products per category; leaderboards.",
        "interviewer_evaluates": "Dense vs row_number; correct tie handling.",
        "common_mistakes": "Wrong order (asc vs desc); not resetting rank when category changes.",
        "dataset_required": "scores_per_category",
    },
    {
        "id": "D10",
        "title": "Find Rows with Duplicate Keys",
        "description": (
            "Given a list of dicts and a key field name, return all rows whose key value appears more than once. "
            "First pass: count occurrences; second pass: yield rows where count > 1 (or use dict key -> list of rows)."
        ),
        "core_concepts": ["Dict key -> list of rows or count", "Filter to count > 1"],
        "why_chewy": "Data quality: finding duplicate order or event IDs.",
        "interviewer_evaluates": "Returning full rows not just keys; efficient (one or two passes).",
        "common_mistakes": "Returning unique keys only; O(n^2) comparison.",
        "dataset_required": "duplicate_keys_list",
    },
    {
        "id": "D11",
        "title": "Merge Two Sorted Streams",
        "description": (
            "Given two lists of dicts (or tuples), each sorted by a common key (e.g. timestamp), merge into one sorted list. "
            "Two-pointer merge: maintain indices, compare, advance. Handle unequal lengths and duplicates."
        ),
        "core_concepts": ["Two pointers", "Compare and append", "Exhaust remaining"],
        "why_chewy": "Merging event streams or log files by time.",
        "interviewer_evaluates": "Clean merge loop; handling when one list is exhausted.",
        "common_mistakes": "Concatenating and re-sorting (O(n log n)); off-by-one in pointer advance.",
        "dataset_required": "two_sorted_streams",
    },
    {
        "id": "D12",
        "title": "Top N Per Group",
        "description": (
            "Given list of dicts (e.g. user_id, order_id, amount), for each user_id return the top N rows by amount (e.g. top 3). "
            "Group by user_id; sort each group by amount desc; take first N. Use defaultdict(list) + sort + slice."
        ),
        "core_concepts": ["Group by key", "Sort within group", "Slice first N"],
        "why_chewy": "Top orders per customer; top products per category.",
        "interviewer_evaluates": "Correct N; handling users with fewer than N rows.",
        "common_mistakes": "Global top N instead of per group; wrong sort order.",
        "dataset_required": "orders_per_user_top_n",
    },
    {
        "id": "D13",
        "title": "Time Between First and Second Event",
        "description": (
            "Given list of (user_id, event_type, timestamp), for each user compute the time difference between their first and second "
            "event of a given type (e.g. purchase). Return dict user_id -> timedelta or seconds. Handle users with < 2 events."
        ),
        "core_concepts": ["Filter by event_type", "Sort by user and time", "Take first two per user", "Diff"],
        "why_chewy": "Repeat purchase latency; engagement intervals.",
        "interviewer_evaluates": "Filtering by type; handling single-event users.",
        "common_mistakes": "Using all events not same type; wrong order (second - first).",
        "dataset_required": "time_between_events",
    },
    {
        "id": "D14",
        "title": "Aggregate Events by (User, Event Type)",
        "description": (
            "Given a list of event rows (user_id, event_time, event_type, product_id, ...), compute a nested structure or table: "
            "count of events per (user_id, event_type). Align with Chewy events schema; use dict or defaultdict."
        ),
        "core_concepts": ["Group by composite key (user, type)", "Count", "Dict or Counter"],
        "why_chewy": "Funnel and engagement metrics; event counts per user per type.",
        "interviewer_evaluates": "Correct key (tuple or nested dict); efficient aggregation.",
        "common_mistakes": "Wrong key structure; iterating multiple times.",
        "dataset_required": "events_csv_like",
    },
]


def get_all_questions() -> List[Dict[str, Any]]:
    return list(QUESTIONS)


def get_dataset_spec(name: str) -> Optional[Dict[str, Any]]:
    return DATASETS.get(name)
