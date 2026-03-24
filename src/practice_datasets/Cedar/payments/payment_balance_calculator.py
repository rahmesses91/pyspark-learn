"""Level 2 — per-encounter charges, adjustments, and balance. Implement in ``payment_balance_calculator_impl.py``."""

from __future__ import annotations

from abc import ABC, abstractmethod


class PaymentBalanceCalculator(ABC):
    """Aggregate normalized statement lines (Level 1 dicts) and adjustments by ``encounter_id``."""

    @abstractmethod
    def __init__(self) -> None:
        ...

    @abstractmethod
    def compute_encounter_balances(
        self,
        normalized_lines: list[dict],
        adjustments: list[dict],
    ) -> list[dict]:
        """Return one row per distinct ``encounter_id`` present in ``normalized_lines``.

        Each output dict has: ``encounter_id`` (str), ``charges_cents`` (int, sum of
        ``charge_cents`` for that encounter), ``adjustments_cents`` (int, sum of
        ``amount_cents`` for matching adjustments), ``balance_cents`` (int,
        ``charges_cents + adjustments_cents``).

        Rows are sorted by ``encounter_id`` ascending (string order).

        Adjustments whose ``encounter_id`` does not appear on any input line are ignored.
        """
        ...
