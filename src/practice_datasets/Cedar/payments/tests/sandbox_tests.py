"""Sandbox — edit freely; not scored on the real platform (simulation)."""

import inspect
import os
import sys
import unittest

current_dir = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
parent_dir = os.path.dirname(current_dir)
sys.path.insert(0, parent_dir)

from timeout_decorator import timeout  # noqa: E402
from payment_parser_impl import PaymentParserImpl  # noqa: E402


class SandboxTests(unittest.TestCase):
    failureException = Exception

    @timeout(0.4)
    def test_sample(self) -> None:
        p = PaymentParserImpl("a,b,2024-06-01,42")
        self.assertTrue(callable(p.parse_line))
