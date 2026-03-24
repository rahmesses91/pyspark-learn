from __future__ import annotations

from abc import ABC
from typing import Optional


class IntegerContainer(ABC):
    """
    `IntegerContainer` interface (locked on the platform).
    """

    def add(self, value: int) -> int:
        """
        Should add the specified integer `value` to the container
        and return the number of integers in the container after the
        addition.
        """
        # default implementation
        return 0

    def delete(self, value: int) -> bool:
        """
        Should attempt to remove the specified integer `value` from
        the container.
        If the `value` is present in the container, remove it and
        return `True`, otherwise, return `False`.
        """
        # default implementation
        return False

    def get_median(self) -> Optional[int]:
        """
        Should return the median integer - the integer in the middle
        of the sequence after all integers stored in the container
        are sorted in ascending order.
        If the length of the sequence is even, the leftmost integer
        from the two middle integers should be returned.
        If the container is empty, this method should return `None`.
        """
        # default implementation
        return None
