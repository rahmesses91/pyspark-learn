import inspect
import os
import sys

current_dir = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
parent_dir = os.path.dirname(current_dir)
sys.path.insert(0, parent_dir)

from timeout_decorator import timeout
import unittest
from integer_container_impl import IntegerContainerImpl


class SandboxTests(unittest.TestCase):
    """
    Playground — modify freely. Results do not affect score (simulation).

    Kept dependency-light so they pass while ``IntegerContainerImpl`` is still a stub.
    """

    failureException = Exception

    @classmethod
    def setUp(cls):
        cls.container = IntegerContainerImpl()

    @timeout(0.4)
    def test_sample(self):
        self.assertTrue(callable(self.container.add))
        self.assertTrue(callable(self.container.delete))
        self.assertTrue(callable(self.container.get_median))
