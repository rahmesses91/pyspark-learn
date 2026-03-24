"""Level 2 — **your implementation** (editable). The interface in ``payment_balance_calculator.py`` is the locked contract."""

from __future__ import annotations

from collections import defaultdict

from payment_balance_calculator import PaymentBalanceCalculator


def _payments_stats() -> dict:
    return {
        "charges_cents": 0,
        "adjustments_cents": 0,
        "balance_cents": 0,
    }


class PaymentBalanceCalculatorImpl(PaymentBalanceCalculator):
    def __init__(self) -> None:
        pass

    def compute_encounter_balances(
        self,
        normalized_lines: list[dict],
        adjustments: list[dict],
    ) -> list[dict]:
        # Normalized lines are expected to come from ``PaymentParserImpl.parse_line`` (Level 1),
        # which already validates row shape, date, and integer cents; no duplicate checks here.

        payments_dict = defaultdict(_payments_stats)

        processed_encounters = set()

        for line in normalized_lines:
            encounter_id = line["encounter_id"]
            charge_cents = line["charge_cents"]

            payments_dict[encounter_id]["charges_cents"] += charge_cents
            payments_dict[encounter_id]["balance_cents"] += charge_cents
            processed_encounters.add(encounter_id)

        for adjustment in adjustments:
            if adjustment["encounter_id"] in processed_encounters:
                encounter_id = adjustment["encounter_id"]
                amount_cents = adjustment["amount_cents"]
                payments_dict[encounter_id]["adjustments_cents"] += amount_cents
                payments_dict[encounter_id]["balance_cents"] += amount_cents

        result: list[dict] = []

        # String sort order (lexicographic), per contract — not numeric ("2" before "10").
        for encounter_id in sorted(payments_dict.keys()):
            bucket = payments_dict[encounter_id]
            result.append(
                {
                    "encounter_id": encounter_id,
                    "charges_cents": bucket["charges_cents"],
                    "adjustments_cents": bucket["adjustments_cents"],
                    "balance_cents": bucket["balance_cents"],
                }
            )

        return result
