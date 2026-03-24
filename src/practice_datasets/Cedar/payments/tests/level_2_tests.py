"""Level 2 graded tests — per-encounter balances (``PaymentBalanceCalculatorImpl``). Do not modify (simulation)."""

import inspect
import os
import sys
import unittest

current_dir = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
parent_dir = os.path.dirname(current_dir)
sys.path.insert(0, parent_dir)

from timeout_decorator import timeout  # noqa: E402
from payment_balance_calculator_impl import PaymentBalanceCalculatorImpl  # noqa: E402

LINE_A = {
    "patient_id": "p1",
    "encounter_id": "e10",
    "service_date": "2024-01-01",
    "charge_cents": 5000,
    "payer_id": "pay1",
}
LINE_B = {
    "patient_id": "p1",
    "encounter_id": "e10",
    "service_date": "2024-01-15",
    "charge_cents": 3000,
    "payer_id": None,
}
LINE_C = {
    "patient_id": "p2",
    "encounter_id": "e2",
    "service_date": "2024-02-01",
    "charge_cents": 10000,
    "payer_id": None,
}


class Level2Tests(unittest.TestCase):
    """Graded Level 2 cases — treat as read-only like the platform's locked tests."""

    failureException = Exception

    @timeout(0.4)
    def test_single_encounter_no_adjustments(self) -> None:
        out = PaymentBalanceCalculatorImpl().compute_encounter_balances([LINE_A], [])
        self.assertEqual(
            out,
            [
                {
                    "encounter_id": "e10",
                    "charges_cents": 5000,
                    "adjustments_cents": 0,
                    "balance_cents": 5000,
                }
            ],
        )

    @timeout(0.4)
    def test_same_encounter_multiple_lines_sums_charges(self) -> None:
        out = PaymentBalanceCalculatorImpl().compute_encounter_balances([LINE_A, LINE_B], [])
        self.assertEqual(
            out,
            [
                {
                    "encounter_id": "e10",
                    "charges_cents": 8000,
                    "adjustments_cents": 0,
                    "balance_cents": 8000,
                }
            ],
        )

    @timeout(0.4)
    def test_multiple_encounters_sorted_by_encounter_id(self) -> None:
        out = PaymentBalanceCalculatorImpl().compute_encounter_balances([LINE_A, LINE_C], [])
        self.assertEqual(
            out,
            [
                {
                    "encounter_id": "e10",
                    "charges_cents": 5000,
                    "adjustments_cents": 0,
                    "balance_cents": 5000,
                },
                {
                    "encounter_id": "e2",
                    "charges_cents": 10000,
                    "adjustments_cents": 0,
                    "balance_cents": 10000,
                },
            ],
        )

    @timeout(0.4)
    def test_adjustments_sum_and_balance(self) -> None:
        adj = [
            {"encounter_id": "e10", "amount_cents": -1000, "reason": "contract"},
            {"encounter_id": "e10", "amount_cents": 500, "reason": "goodwill"},
        ]
        out = PaymentBalanceCalculatorImpl().compute_encounter_balances([LINE_A], adj)
        self.assertEqual(
            out,
            [
                {
                    "encounter_id": "e10",
                    "charges_cents": 5000,
                    "adjustments_cents": -500,
                    "balance_cents": 4500,
                }
            ],
        )

    @timeout(0.4)
    def test_adjustment_unknown_encounter_ignored(self) -> None:
        adj = [{"encounter_id": "e99", "amount_cents": 9999, "reason": "orphan"}]
        out = PaymentBalanceCalculatorImpl().compute_encounter_balances([LINE_A], adj)
        self.assertEqual(
            out,
            [
                {
                    "encounter_id": "e10",
                    "charges_cents": 5000,
                    "adjustments_cents": 0,
                    "balance_cents": 5000,
                }
            ],
        )

    @timeout(0.4)
    def test_empty_lines(self) -> None:
        out = PaymentBalanceCalculatorImpl().compute_encounter_balances([], [])
        self.assertEqual(out, [])
