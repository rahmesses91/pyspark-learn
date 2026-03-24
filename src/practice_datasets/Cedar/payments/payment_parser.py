"""Level 1 — parse one CSV statement row. Implement in ``payment_parser_impl.py``."""

from __future__ import annotations

from abc import ABC, abstractmethod


class PaymentParser(ABC):
    """Split a CSV string on commas; ``parse_line`` returns a normalized dict."""

    @abstractmethod
    def __init__(self, line: str) -> None:
        ...

    @abstractmethod
    def parse_line(self) -> dict:
        """Return ``patient_id``, ``encounter_id``, ``service_date``, ``charge_cents``, ``payer_id`` (optional)."""
        ...
