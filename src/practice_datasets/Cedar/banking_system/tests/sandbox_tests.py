"""Sandbox — edit freely; runs with graded tests but does not affect ICA scoring (simulation)."""

import inspect
import os
import sys
import unittest

current_dir = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
parent_dir = os.path.dirname(current_dir)
sys.path.insert(0, parent_dir)

from timeout_decorator import timeout  # noqa: E402
from banking_system_impl import BankingSystemImpl  # noqa: E402


class SandboxTests(unittest.TestCase):
    failureException = Exception

    @classmethod
    def setUp(cls) -> None:
        cls.bank = BankingSystemImpl()

    @timeout(0.4)
    def test_sample(self) -> None:
        """Edit this once ``BankingSystemImpl.execute`` is implemented."""
        self.assertTrue(callable(self.bank.execute))
