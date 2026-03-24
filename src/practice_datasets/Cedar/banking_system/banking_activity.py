"""Level 2 — ``TOP_ACTIVITY`` parsing and response formatting. Implement in ``banking_activity_impl.py``."""

from __future__ import annotations

from abc import ABC, abstractmethod


class BankingActivity(ABC):
    """Helpers for ``TOP_ACTIVITY`` queries (see ``question.txt``, ``tests/level_2_tests.py``)."""

    @abstractmethod
    def __init__(self) -> None:
        ...

    @abstractmethod
    def parse_top_activity_query(self, query: list[str]) -> tuple[int, int]:
        """Parse ``["TOP_ACTIVITY", "<timestamp>", "<n>"]`` into ``(timestamp, n)``.

        Raise ``ValueError`` if the query shape is invalid or ``n`` is negative.
        """
        ...

    @abstractmethod
    def format_top_activity_response(self, ranked: list[tuple[str, int]]) -> str:
        """Build the exact ``TOP_ACTIVITY`` string from ordered ``(account_id, activity_total)`` pairs.

        Join with comma + single space; empty ``ranked`` → ``\"\"``. Ordering rules are in ``question.txt``.
        """
        ...
