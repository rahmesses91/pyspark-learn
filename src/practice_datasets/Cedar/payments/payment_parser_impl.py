"""Level 1 — **your implementation** (editable). The interface in ``payment_parser.py`` is the locked contract."""

from __future__ import annotations

from payment_parser import PaymentParser
from datetime import datetime


class PaymentParserImpl(PaymentParser):
    def __init__(self, line: str) -> None:
        self._line = line
        self.line_split = list()

    def parse_line(self) -> dict:
        
        if isinstance(self._line, str):

            self.line_split = self._line.split(",")
            self.line_split = list(map(str.strip, self.line_split ))
        else:
            raise ValueError(f"The line: {self._line} isn't a valid string")
        
        if len(self.line_split) not in (4, 5):
            raise ValueError(f"The line: {self._line} should have more than 3 or upto 5 fields only")
        
        if self.line_split[2]:
            try:
                datetime.strptime(self.line_split[2], '%Y-%m-%d')
            except ValueError as e:
                raise ValueError(f"The line field {self.line_split[2]} is not a valid date. Error: {e}")
        else:
            pass

        if self.line_split[3]:
            try:
                int(self.line_split[3])
            except ValueError as e:
                raise ValueError(f"The line field {self.line_split[3]} is not valid integer cents. Error: {e}")
        else:
            pass
        
        return {
            "patient_id": self.line_split[0],
            "encounter_id": self.line_split[1],
            "service_date": self.line_split[2],
            "charge_cents": int(self.line_split[3]),
            "payer_id": self.line_split[4] if self.line_split[4] else None
        }

        #raise NotImplementedError
