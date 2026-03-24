"""Level 3 graded tests — waterfall allocation (``PaymentAllocatorImpl``). Do not modify (simulation)."""

import copy
import inspect
import os
import sys
import unittest

current_dir = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
parent_dir = os.path.dirname(current_dir)
sys.path.insert(0, parent_dir)

from timeout_decorator import timeout  # noqa: E402
from payment_allocator_impl import PaymentAllocatorImpl  # noqa: E402

# Minimal Level 2-shaped rows (``balance_cents`` is what allocation uses).
BAL_TWO = [
    {
        "encounter_id": "e10",
        "charges_cents": 1000,
        "adjustments_cents": 0,
        "balance_cents": 1000,
    },
    {
        "encounter_id": "e2",
        "charges_cents": 2000,
        "adjustments_cents": 0,
        "balance_cents": 2000,
    },
]


class Level3Tests(unittest.TestCase):
    """Graded Level 3 cases — treat as read-only like the platform's locked tests."""

    failureException = Exception

    @timeout(0.4)
    def test_waterfall_two_encounters(self) -> None:
        alloc = PaymentAllocatorImpl("p1", copy.deepcopy(BAL_TWO))
        out = alloc.allocate(1500)
        self.assertEqual(
            out,
            {
                "allocations": [
                    {"encounter_id": "e10", "applied_cents": 1000},
                    {"encounter_id": "e2", "applied_cents": 500},
                ],
                "unapplied_cents": 0,
            },
        )

    @timeout(0.4)
    def test_overpayment_returns_unapplied(self) -> None:
        one = [
            {
                "encounter_id": "e10",
                "charges_cents": 3000,
                "adjustments_cents": 0,
                "balance_cents": 3000,
            },
        ]
        alloc = PaymentAllocatorImpl("p1", one)
        out = alloc.allocate(5000)
        self.assertEqual(
            out,
            {
                "allocations": [{"encounter_id": "e10", "applied_cents": 3000}],
                "unapplied_cents": 2000,
            },
        )

    @timeout(0.4)
    def test_subsequent_calls_remember_remaining(self) -> None:
        alloc = PaymentAllocatorImpl("p1", copy.deepcopy(BAL_TWO))
        self.assertEqual(
            alloc.allocate(1000),
            {
                "allocations": [{"encounter_id": "e10", "applied_cents": 1000}],
                "unapplied_cents": 0,
            },
        )
        self.assertEqual(
            alloc.allocate(500),
            {
                "allocations": [{"encounter_id": "e2", "applied_cents": 500}],
                "unapplied_cents": 0,
            },
        )
        self.assertEqual(
            alloc.allocate(2000),
            {
                "allocations": [{"encounter_id": "e2", "applied_cents": 1500}],
                "unapplied_cents": 500,
            },
        )

    @timeout(0.4)
    def test_empty_encounters_all_unapplied(self) -> None:
        alloc = PaymentAllocatorImpl("p1", [])
        self.assertEqual(
            alloc.allocate(100),
            {"allocations": [], "unapplied_cents": 100},
        )

    @timeout(0.4)
    def test_zero_payment(self) -> None:
        alloc = PaymentAllocatorImpl("p1", copy.deepcopy(BAL_TWO))
        self.assertEqual(
            alloc.allocate(0),
            {"allocations": [], "unapplied_cents": 0},
        )

    @timeout(0.4)
    def test_negative_payment_raises(self) -> None:
        alloc = PaymentAllocatorImpl("p1", copy.deepcopy(BAL_TWO))
        with self.assertRaises(ValueError):
            alloc.allocate(-1)

    @timeout(0.4)
    def test_zero_balance_encounter_skipped(self) -> None:
        rows = [
            {
                "encounter_id": "e10",
                "charges_cents": 0,
                "adjustments_cents": 0,
                "balance_cents": 0,
            },
            {
                "encounter_id": "e2",
                "charges_cents": 100,
                "adjustments_cents": 0,
                "balance_cents": 100,
            },
        ]
        alloc = PaymentAllocatorImpl("p1", rows)
        self.assertEqual(
            alloc.allocate(500),
            {
                "allocations": [{"encounter_id": "e2", "applied_cents": 100}],
                "unapplied_cents": 400,
            },
        )


# --- Extra cases (each test uses its own row dicts so balances stay independent) ---


class Level3ExtraTests(unittest.TestCase):
    """Additional edge cases for waterfall allocation (sandbox-style extension)."""

    failureException = Exception

    @timeout(0.4)
    def test_single_encounter_partial_then_remainder(self) -> None:
        rows = [
            {
                "encounter_id": "only",
                "charges_cents": 400,
                "adjustments_cents": 0,
                "balance_cents": 400,
            },
        ]
        alloc = PaymentAllocatorImpl("p1", rows)
        self.assertEqual(
            alloc.allocate(100),
            {
                "allocations": [{"encounter_id": "only", "applied_cents": 100}],
                "unapplied_cents": 0,
            },
        )
        self.assertEqual(
            alloc.allocate(999),
            {
                "allocations": [{"encounter_id": "only", "applied_cents": 300}],
                "unapplied_cents": 699,
            },
        )

    @timeout(0.4)
    def test_payment_exactly_covers_all_balances(self) -> None:
        rows = [
            {
                "encounter_id": "a",
                "charges_cents": 100,
                "adjustments_cents": 0,
                "balance_cents": 100,
            },
            {
                "encounter_id": "b",
                "charges_cents": 200,
                "adjustments_cents": 0,
                "balance_cents": 200,
            },
        ]
        alloc = PaymentAllocatorImpl("p1", rows)
        self.assertEqual(
            alloc.allocate(300),
            {
                "allocations": [
                    {"encounter_id": "a", "applied_cents": 100},
                    {"encounter_id": "b", "applied_cents": 200},
                ],
                "unapplied_cents": 0,
            },
        )

    @timeout(0.4)
    def test_after_balances_exhausted_further_payment_unapplied(self) -> None:
        rows = [
            {
                "encounter_id": "x",
                "charges_cents": 50,
                "adjustments_cents": 0,
                "balance_cents": 50,
            },
        ]
        alloc = PaymentAllocatorImpl("p1", rows)
        self.assertEqual(alloc.allocate(50), {"allocations": [{"encounter_id": "x", "applied_cents": 50}], "unapplied_cents": 0})
        self.assertEqual(alloc.allocate(100), {"allocations": [], "unapplied_cents": 100})

    @timeout(0.4)
    def test_negative_balance_cents_skipped_like_zero(self) -> None:
        rows = [
            {
                "encounter_id": "bad",
                "charges_cents": 0,
                "adjustments_cents": 0,
                "balance_cents": -50,
            },
            {
                "encounter_id": "good",
                "charges_cents": 100,
                "adjustments_cents": 0,
                "balance_cents": 100,
            },
        ]
        alloc = PaymentAllocatorImpl("p1", rows)
        self.assertEqual(
            alloc.allocate(40),
            {"allocations": [{"encounter_id": "good", "applied_cents": 40}], "unapplied_cents": 0},
        )

    @timeout(0.4)
    def test_three_encounters_waterfall(self) -> None:
        """Rows listed in ascending ``encounter_id`` string order (``e1``, ``e10``, ``e2``)."""
        rows = [
            {
                "encounter_id": "e1",
                "charges_cents": 100,
                "adjustments_cents": 0,
                "balance_cents": 100,
            },
            {
                "encounter_id": "e10",
                "charges_cents": 100,
                "adjustments_cents": 0,
                "balance_cents": 100,
            },
            {
                "encounter_id": "e2",
                "charges_cents": 100,
                "adjustments_cents": 0,
                "balance_cents": 100,
            },
        ]
        alloc = PaymentAllocatorImpl("p1", rows)
        out = alloc.allocate(250)
        self.assertEqual(
            out,
            {
                "allocations": [
                    {"encounter_id": "e1", "applied_cents": 100},
                    {"encounter_id": "e10", "applied_cents": 100},
                    {"encounter_id": "e2", "applied_cents": 50},
                ],
                "unapplied_cents": 0,
            },
        )

    @timeout(0.4)
    def test_one_cent_payment(self) -> None:
        rows = [
            {
                "encounter_id": "z",
                "charges_cents": 1,
                "adjustments_cents": 0,
                "balance_cents": 1,
            },
        ]
        alloc = PaymentAllocatorImpl("p1", rows)
        self.assertEqual(
            alloc.allocate(1),
            {"allocations": [{"encounter_id": "z", "applied_cents": 1}], "unapplied_cents": 0},
        )

    @timeout(0.4)
    def test_allocate_zero_twice_then_pay(self) -> None:
        rows = [
            {
                "encounter_id": "q",
                "charges_cents": 10,
                "adjustments_cents": 0,
                "balance_cents": 10,
            },
        ]
        alloc = PaymentAllocatorImpl("p1", rows)
        self.assertEqual(alloc.allocate(0), {"allocations": [], "unapplied_cents": 0})
        self.assertEqual(alloc.allocate(0), {"allocations": [], "unapplied_cents": 0})
        self.assertEqual(
            alloc.allocate(10),
            {"allocations": [{"encounter_id": "q", "applied_cents": 10}], "unapplied_cents": 0},
        )
