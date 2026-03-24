"""Level 3 — waterfall payment allocation. Implement in ``payment_allocator_impl.py``."""

from __future__ import annotations

from abc import ABC, abstractmethod


class PaymentAllocator(ABC):
    """Apply payments to per-encounter balances in ascending ``encounter_id`` order (waterfall)."""

    @abstractmethod
    def __init__(self, patient_id: str, encounter_balances: list[dict]) -> None:
        """``encounter_balances`` rows match Level 2 output (at least ``encounter_id``, ``balance_cents``)."""
        ...

    @abstractmethod
    def allocate(self, payment_cents: int) -> dict:
        """Apply up to ``payment_cents`` across encounters with remaining balance.

        Returns ``{"allocations": [{"encounter_id": str, "applied_cents": int}, ...], "unapplied_cents": int}``.
        Allocation order follows ascending string order of ``encounter_id``. Remaining balances are updated
        in memory for subsequent calls. Raises ``ValueError`` if ``payment_cents`` is negative.
        """
        ...
    