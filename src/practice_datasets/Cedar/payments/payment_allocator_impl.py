"""Level 3 — **your implementation**. See ``payment_allocator.py`` and ``INSTRUCTIONS.md``."""

from __future__ import annotations

from payment_allocator import PaymentAllocator


class PaymentAllocatorImpl(PaymentAllocator):
    def __init__(self, patient_id: str, encounter_balances: list[dict]) -> None:
        self._patient_id = patient_id
        self._encounter_balances = encounter_balances

    def _validate_encounter_balances(self, encounter_balances: list[dict]) -> None:
        for balance in encounter_balances:
            if "encounter_id" not in balance:
                raise ValueError("encounter_id is required")
            if "balance_cents" not in balance:
                raise ValueError("balance_cents is required")
            if not isinstance(balance["balance_cents"], int):
                raise ValueError("balance_cents must be an integer")
            if not isinstance(balance["encounter_id"], str):
                raise ValueError("encounter_id must be a string")
            if balance["encounter_id"] == "":
                raise ValueError("encounter_id must be non-empty")
    

    def allocate(self, payment_cents: int) -> dict:

        self._validate_encounter_balances(self._encounter_balances)

        if payment_cents < 0:
            raise ValueError("payment_cents must be non-negative")
        
        if payment_cents == 0:
            return {"allocations": [], "unapplied_cents": 0}
        
        allocations = []


        for encounter_balance in sorted(self._encounter_balances, key=lambda x: x['encounter_id']):
            if encounter_balance['balance_cents'] <= 0:
                continue
            if payment_cents <= 0:
                break
            applied_cents = min(encounter_balance['balance_cents'], payment_cents)
            encounter_balance['balance_cents'] -= applied_cents
            payment_cents -= applied_cents
            allocations.append({"encounter_id": encounter_balance['encounter_id'], "applied_cents": applied_cents})
        
        return {"allocations": allocations, "unapplied_cents": payment_cents}
