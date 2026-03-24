"""Level 2 graded tests — TOP_ACTIVITY. See ``question.txt``."""

import inspect
import os
import sys
import unittest

current_dir = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
parent_dir = os.path.dirname(current_dir)
sys.path.insert(0, parent_dir)

from timeout_decorator import timeout  # noqa: E402
from banking_system_impl import BankingSystemImpl, run_queries  # noqa: E402


class Level2Tests(unittest.TestCase):
    """Graded Level 2 — activity totals and TOP_ACTIVITY ranking."""

    failureException = Exception

    def setUp(self) -> None:
        self.bank = BankingSystemImpl()

    @timeout(0.4)
    def test_top_activity_descending_by_total(self) -> None:
        self.bank.execute(["CREATE_ACCOUNT", "1", "bob"])
        self.bank.execute(["CREATE_ACCOUNT", "2", "alice"])
        self.bank.execute(["DEPOSIT", "3", "alice", "100"])
        self.bank.execute(["DEPOSIT", "4", "bob", "50"])
        self.assertEqual(
            self.bank.execute(["TOP_ACTIVITY", "5", "2"]),
            "alice(100), bob(50)",
        )

    @timeout(0.4)
    def test_tie_break_lexicographic_before_top_n(self) -> None:
        self.bank.execute(["CREATE_ACCOUNT", "1", "zebra"])
        self.bank.execute(["CREATE_ACCOUNT", "2", "apple"])
        self.bank.execute(["DEPOSIT", "3", "zebra", "10"])
        self.bank.execute(["DEPOSIT", "4", "apple", "10"])
        self.assertEqual(
            self.bank.execute(["TOP_ACTIVITY", "5", "2"]),
            "apple(10), zebra(10)",
        )

    @timeout(0.4)
    def test_pay_increments_activity(self) -> None:
        self.bank.execute(["CREATE_ACCOUNT", "1", "a1"])
        self.bank.execute(["DEPOSIT", "2", "a1", "100"])
        self.bank.execute(["PAY", "3", "a1", "40"])
        self.assertEqual(self.bank.execute(["TOP_ACTIVITY", "4", "1"]), "a1(140)")

    @timeout(0.4)
    def test_failed_pay_does_not_increase_activity(self) -> None:
        self.bank.execute(["CREATE_ACCOUNT", "1", "a1"])
        self.bank.execute(["DEPOSIT", "2", "a1", "5"])
        self.assertEqual(self.bank.execute(["PAY", "3", "a1", "10"]), "")
        self.assertEqual(self.bank.execute(["TOP_ACTIVITY", "4", "1"]), "a1(5)")

    @timeout(0.4)
    def test_failed_deposit_does_not_increase_activity(self) -> None:
        self.bank.execute(["CREATE_ACCOUNT", "1", "a1"])
        self.assertEqual(self.bank.execute(["DEPOSIT", "2", "ghost", "100"]), "")
        self.assertEqual(self.bank.execute(["TOP_ACTIVITY", "3", "1"]), "a1(0)")

    @timeout(0.4)
    def test_fewer_accounts_than_n_lists_all(self) -> None:
        self.bank.execute(["CREATE_ACCOUNT", "1", "only"])
        self.bank.execute(["DEPOSIT", "2", "only", "7"])
        self.assertEqual(
            self.bank.execute(["TOP_ACTIVITY", "3", "5"]),
            "only(7)",
        )

    @timeout(0.4)
    def test_top_activity_between_other_ops(self) -> None:
        self.bank.execute(["CREATE_ACCOUNT", "1", "x"])
        self.bank.execute(["DEPOSIT", "2", "x", "500"])
        self.assertEqual(self.bank.execute(["TOP_ACTIVITY", "3", "1"]), "x(500)")
        self.bank.execute(["PAY", "4", "x", "100"])
        self.assertEqual(self.bank.execute(["DEPOSIT", "5", "x", "1"]), "401")

    @timeout(0.4)
    def test_top_activity_zero_n_returns_empty(self) -> None:
        self.bank.execute(["CREATE_ACCOUNT", "1", "a"])
        self.assertEqual(self.bank.execute(["TOP_ACTIVITY", "2", "0"]), "")

    @timeout(0.4)
    def test_run_queries_with_top_activity(self) -> None:
        queries = [
            ["CREATE_ACCOUNT", "1", "u"],
            ["DEPOSIT", "2", "u", "10"],
            ["TOP_ACTIVITY", "3", "1"],
        ]
        self.assertEqual(run_queries(queries), ["true", "10", "u(10)"])


if __name__ == "__main__":
    unittest.main()
