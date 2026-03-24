"""Level 1 graded tests — CSV row parsing (``PaymentParserImpl``). Do not modify (simulation)."""

import inspect
import os
import sys
import unittest

current_dir = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
parent_dir = os.path.dirname(current_dir)
sys.path.insert(0, parent_dir)

from timeout_decorator import timeout  # noqa: E402
from payment_parser_impl import PaymentParserImpl  # noqa: E402

# Match CodeSignal-style harness.

SAMPLE_LINE = "1234567890,1234567890,2024-01-01,100000,1234567890"
BAD_LINE = "1234567890,1234567890,2024-01-01,100000,1234567890,extra"
BAD_DATE = "1234567890,1234567890,not-a-date,100000,1234567890"
BAD_CHARGE_CENTS = "1234567890,1234567890,2024-01-01,10.5,1234567890"


class Level1Tests(unittest.TestCase):
    """Graded Level 1 cases — treat as read-only like the platform’s locked tests."""

    failureException = Exception

    @timeout(0.4)
    def test_parse_line(self) -> None:
        self.assertEqual(
            PaymentParserImpl(SAMPLE_LINE).parse_line(),
            {
                "patient_id": "1234567890",
                "encounter_id": "1234567890",
                "service_date": "2024-01-01",
                "charge_cents": 100000,
                "payer_id": "1234567890",
            },
        )

    @timeout(0.4)
    def test_bad_line(self) -> None:
        with self.assertRaises(ValueError):
            PaymentParserImpl(BAD_LINE).parse_line()

    @timeout(0.4)
    def test_bad_date(self) -> None:
        with self.assertRaises(ValueError):
            PaymentParserImpl(BAD_DATE).parse_line()

    @timeout(0.4)
    def test_bad_charge_cents(self) -> None:
        with self.assertRaises(ValueError):
            PaymentParserImpl(BAD_CHARGE_CENTS).parse_line()
