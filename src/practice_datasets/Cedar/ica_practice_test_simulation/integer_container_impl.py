"""Editable implementation — fill in ``IntegerContainer`` methods (see ``tests/level_1_tests.py``)."""

from __future__ import annotations

from typing import Optional

from integer_container import IntegerContainer


class IntegerContainerImpl(IntegerContainer):
    def __init__(self) -> None:
        pass

    def add(self, value: int) -> int:
        raise NotImplementedError

    def delete(self, value: int) -> bool:
        raise NotImplementedError

    def get_median(self) -> Optional[int]:
        raise NotImplementedError
