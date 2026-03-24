"""Level 2 — **your implementation** (editable). The interface in ``banking_activity.py`` is the locked contract."""

from __future__ import annotations

from banking_activity import BankingActivity


class BankingActivityImpl(BankingActivity):
    def __init__(self) -> None:
        pass

    def parse_top_activity_query(self, query: list[str]) -> tuple[int, int]:
        if len(query) != 3:
            raise ValueError(f"TOP_ACTIVITY query must have length 3, got {query!r}")
        if query[0] != "TOP_ACTIVITY":
            raise ValueError(f"expected TOP_ACTIVITY query, got {query!r}")
        ts = int(query[1])
        n = int(query[2])
        if n < 0:
            raise ValueError(f"TOP_ACTIVITY n must be non-negative, got {n!r}")
        return ts, n

    def format_top_activity_response(self, ranked: list[tuple[str, int]]) -> str:
        if not ranked:
            return ""
        return ", ".join(f"{account_id}({total})" for account_id, total in ranked)
