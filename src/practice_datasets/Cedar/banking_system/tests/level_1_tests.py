"""Level 1 graded tests — do not modify (practice simulation). See ``question.txt``."""

import inspect
import os
import sys
import unittest

current_dir = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
parent_dir = os.path.dirname(current_dir)
sys.path.insert(0, parent_dir)

from timeout_decorator import timeout  # noqa: E402
from banking_system_impl import BankingSystemImpl, run_queries  # noqa: E402

# Match CodeSignal-style harness: exceptions surface as test failures (not framework errors).


def _run_queries(bank: BankingSystemImpl, queries: list[list[str]]) -> list[str]:
    # ``run_queries`` uses a fresh impl instance; ``bank`` kept for API compatibility.
    return run_queries(queries)


class Level1Tests(unittest.TestCase):
    """
    Graded Level 1 cases — tokenized queries ``[OP, timestamp, accountId, ...]``.
    Treat as read-only like the platform’s locked tests.
    """

    failureException = Exception

    @classmethod
    def setUp(cls) -> None:
        cls.bank = BankingSystemImpl()

    @timeout(0.4)
    def test_create_account_success(self) -> None:
        self.assertEqual(self.bank.execute(["CREATE_ACCOUNT", "1", "alice"]), "true")
        self.assertEqual(self.bank.execute(["CREATE_ACCOUNT", "2", "bob"]), "true")

    @timeout(0.4)
    def test_create_account_duplicate_returns_false(self) -> None:
        self.assertEqual(self.bank.execute(["CREATE_ACCOUNT", "1", "alice"]), "true")
        self.assertEqual(self.bank.execute(["CREATE_ACCOUNT", "10", "alice"]), "false")

    @timeout(0.4)
    def test_deposit_returns_new_balance(self) -> None:
        self.bank.execute(["CREATE_ACCOUNT", "1", "a1"])
        self.assertEqual(self.bank.execute(["DEPOSIT", "2", "a1", "100"]), "100")
        self.assertEqual(self.bank.execute(["DEPOSIT", "3", "a1", "25"]), "125")

    @timeout(0.4)
    def test_deposit_unknown_account_returns_empty_string(self) -> None:
        self.assertEqual(self.bank.execute(["DEPOSIT", "1", "ghost", "50"]), "")

    @timeout(0.4)
    def test_pay_returns_balance_after_withdrawal(self) -> None:
        self.bank.execute(["CREATE_ACCOUNT", "1", "a1"])
        self.bank.execute(["DEPOSIT", "2", "a1", "100"])
        self.assertEqual(self.bank.execute(["PAY", "3", "a1", "30"]), "70")

    @timeout(0.4)
    def test_pay_exact_balance_returns_zero_string(self) -> None:
        self.bank.execute(["CREATE_ACCOUNT", "1", "a1"])
        self.bank.execute(["DEPOSIT", "2", "a1", "50"])
        self.assertEqual(self.bank.execute(["PAY", "3", "a1", "50"]), "0")

    @timeout(0.4)
    def test_pay_insufficient_funds_returns_empty_string(self) -> None:
        self.bank.execute(["CREATE_ACCOUNT", "1", "a1"])
        self.bank.execute(["DEPOSIT", "2", "a1", "10"])
        self.assertEqual(self.bank.execute(["PAY", "3", "a1", "11"]), "")

    @timeout(0.4)
    def test_pay_unknown_account_returns_empty_string(self) -> None:
        self.assertEqual(self.bank.execute(["PAY", "1", "nobody", "1"]), "")

    @timeout(0.4)
    def test_full_sequence_matches_spec(self) -> None:
        out = [
            self.bank.execute(["CREATE_ACCOUNT", "100", "x"]),
            self.bank.execute(["CREATE_ACCOUNT", "200", "y"]),
            self.bank.execute(["DEPOSIT", "300", "x", "500"]),
            self.bank.execute(["PAY", "400", "x", "100"]),
            self.bank.execute(["DEPOSIT", "500", "y", "1"]),
        ]
        self.assertEqual(out, ["true", "true", "500", "400", "1"])

    @timeout(0.4)
    def test_run_queries_equivalent_sequence(self) -> None:
        queries = [
            ["CREATE_ACCOUNT", "1", "u"],
            ["DEPOSIT", "2", "u", "7"],
            ["PAY", "3", "u", "2"],
        ]
        self.assertEqual(_run_queries(BankingSystemImpl(), queries), ["true", "7", "5"])

    @timeout(0.4)
    def test_execute_unknown_operation_raises(self) -> None:
        with self.assertRaises(ValueError) as ctx:
            BankingSystemImpl().execute(["UNKNOWN", "1"])
        self.assertIn("operation", str(ctx.exception).lower())


class Level1SmokeTests(unittest.TestCase):
    """Lightweight checks that stay green if imports work."""

    def test_impl_class_exists(self) -> None:
        self.assertTrue(callable(BankingSystemImpl))
