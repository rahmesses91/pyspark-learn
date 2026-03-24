"""Banking system API (Level 1+) — contract only; implement in ``banking_system_impl.py``.

See ``question.txt`` for behavior. On CodeSignal this file is usually fixed; you edit the impl.
"""

from __future__ import annotations

from abc import ABC, abstractmethod


class BankingSystem(ABC):
    """Tokenized queries: ``[OP, timestamp, ...]`` — see Level 1–2 tests."""

    @abstractmethod
    def execute(self, query: list[str]) -> str:
        """
        Handle one query. Operations: ``CREATE_ACCOUNT``, ``DEPOSIT``, ``PAY``, ``TOP_ACTIVITY`` (Level 2).

        Unknown operation: raise ``ValueError`` (tests may assert on the message).
        """
        ...
