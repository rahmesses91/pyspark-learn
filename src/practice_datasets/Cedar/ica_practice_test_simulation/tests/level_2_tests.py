import inspect, os, sys
current_dir = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
parent_dir = os.path.dirname(current_dir)
sys.path.insert(0, parent_dir)

from timeout_decorator import timeout
import unittest
from integer_container_impl import IntegerContainerImpl


class Level2Tests(unittest.TestCase):
    """
    The test class below includes 10 tests for Level 2.

    All have the same score.
    You are not allowed to modify this file, but feel free to read the source code to better understand what is happening in every specific case.
    """

    failureException = Exception


    @classmethod
    def setUp(cls):
        cls.container = IntegerContainerImpl()

    @timeout(0.4)
    def test_level_2_case_01_simple_median_odd_length(self):
        self.assertEqual(self.container.add(1), 1)
        self.assertEqual(self.container.add(2), 2)
        self.assertEqual(self.container.add(5), 3)
        self.assertEqual(self.container.add(7), 4)
        self.assertEqual(self.container.add(9), 5)
        self.assertEqual(self.container.get_median(), 5)
        self.assertEqual(self.container.add(11), 6)
        self.assertEqual(self.container.add(15), 7)
        self.assertEqual(self.container.get_median(), 7)

    @timeout(0.4)
    def test_level_2_case_02_simple_median_even_length(self):
        self.assertEqual(self.container.add(10), 1)
        self.assertEqual(self.container.add(20), 2)
        self.assertEqual(self.container.get_median(), 10)
        self.assertEqual(self.container.add(30), 3)
        self.assertEqual(self.container.add(40), 4)
        self.assertEqual(self.container.get_median(), 20)
        self.assertEqual(self.container.get_median(), 20)
        self.assertEqual(self.container.add(50), 5)
        self.assertEqual(self.container.add(60), 6)
        self.assertEqual(self.container.add(70), 7)
        self.assertEqual(self.container.add(80), 8)
        self.assertEqual(self.container.get_median(), 40)

    @timeout(0.4)
    def test_level_2_case_03_median_of_empty_container(self):
        self.assertIsNone(self.container.get_median())
        self.assertEqual(self.container.add(1), 1)
        self.assertEqual(self.container.get_median(), 1)

    @timeout(0.4)
    def test_level_2_case_04_median_of_non_sorted_container(self):
        self.assertEqual(self.container.add(3), 1)
        self.assertEqual(self.container.add(2), 2)
        self.assertEqual(self.container.add(5), 3)
        self.assertEqual(self.container.add(4), 4)
        self.assertEqual(self.container.add(1), 5)
        self.assertEqual(self.container.get_median(), 3)
        self.assertEqual(self.container.add(8), 6)
        self.assertEqual(self.container.add(6), 7)
        self.assertEqual(self.container.add(7), 8)
        self.assertEqual(self.container.get_median(), 4)

    @timeout(0.4)
    def test_level_2_case_05_median_of_container_with_duplicates(self):
        self.assertEqual(self.container.add(5), 1)
        self.assertEqual(self.container.add(3), 2)
        self.assertEqual(self.container.add(5), 3)
        self.assertEqual(self.container.add(5), 4)
        self.assertEqual(self.container.add(10), 5)
        self.assertEqual(self.container.add(3), 6)
        self.assertEqual(self.container.get_median(), 5)
        self.assertEqual(self.container.add(3), 7)
        self.assertEqual(self.container.add(3), 8)
        self.assertEqual(self.container.add(3), 9)
        self.assertEqual(self.container.get_median(), 3)

    @timeout(0.4)
    def test_level_2_case_06_median_with_deletions(self):
        self.assertEqual(self.container.add(30), 1)
        self.assertEqual(self.container.add(20), 2)
        self.assertEqual(self.container.add(10), 3)
        self.assertEqual(self.container.get_median(), 20)
        self.assertTrue(self.container.delete(30))
        self.assertEqual(self.container.get_median(), 10)
        self.assertTrue(self.container.delete(10))
        self.assertEqual(self.container.get_median(), 20)
        self.assertTrue(self.container.delete(20))
        self.assertIsNone(self.container.get_median())

    @timeout(0.4)
    def test_level_2_case_07_double_median_and_deletions(self):
        self.assertIsNone(self.container.get_median())
        self.assertIsNone(self.container.get_median())
        self.assertFalse(self.container.delete(239))
        self.assertIsNone(self.container.get_median())
        self.assertIsNone(self.container.get_median())
        self.assertEqual(self.container.add(239), 1)
        self.assertEqual(self.container.get_median(), 239)
        self.assertEqual(self.container.get_median(), 239)
        self.assertTrue(self.container.delete(239))
        self.assertFalse(self.container.delete(239))
        self.assertIsNone(self.container.get_median())
        self.assertIsNone(self.container.get_median())

    @timeout(0.4)
    def test_level_2_case_08_median_of_container_with_negative_integers(self):
        self.assertEqual(self.container.add(-20), 1)
        self.assertEqual(self.container.add(-10), 2)
        self.assertEqual(self.container.add(10), 3)
        self.assertEqual(self.container.add(20), 4)
        self.assertEqual(self.container.add(0), 5)
        self.assertEqual(self.container.get_median(), 0)
        self.assertEqual(self.container.add(-30), 6)
        self.assertEqual(self.container.get_median(), -10)
        self.assertEqual(self.container.add(30), 7)
        self.assertEqual(self.container.get_median(), 0)
        self.assertEqual(self.container.add(40), 8)
        self.assertEqual(self.container.add(50), 9)
        self.assertEqual(self.container.get_median(), 10)

    @timeout(0.4)
    def test_level_2_case_09_mixed_operations_1(self):
        self.assertIsNone(self.container.get_median())
        self.assertEqual(self.container.add(5), 1)
        self.assertEqual(self.container.add(3), 2)
        self.assertEqual(self.container.add(5), 3)
        self.assertEqual(self.container.add(7), 4)
        self.assertEqual(self.container.add(8), 5)
        self.assertEqual(self.container.add(9), 6)
        self.assertEqual(self.container.get_median(), 5)
        self.assertTrue(self.container.delete(5))
        self.assertTrue(self.container.delete(8))
        self.assertEqual(self.container.get_median(), 5)
        self.assertTrue(self.container.delete(5))
        self.assertFalse(self.container.delete(5))
        self.assertEqual(self.container.get_median(), 7)
        self.assertEqual(self.container.add(5), 4)
        self.assertEqual(self.container.get_median(), 5)
        self.assertTrue(self.container.delete(5))
        self.assertFalse(self.container.delete(5))
        self.assertTrue(self.container.delete(7))
        self.assertTrue(self.container.delete(3))
        self.assertEqual(self.container.get_median(), 9)
        self.assertTrue(self.container.delete(9))
        self.assertIsNone(self.container.get_median())
        self.assertFalse(self.container.delete(9))
        self.assertIsNone(self.container.get_median())

    @timeout(0.4)
    def test_level_2_case_10_mixed_operations_2(self):
        self.assertIsNone(self.container.get_median())
        self.assertEqual(self.container.add(1), 1)
        self.assertEqual(self.container.add(1), 2)
        self.assertEqual(self.container.add(2), 3)
        self.assertEqual(self.container.add(2), 4)
        self.assertEqual(self.container.add(3), 5)
        self.assertEqual(self.container.add(3), 6)
        self.assertEqual(self.container.add(4), 7)
        self.assertEqual(self.container.add(4), 8)
        self.assertEqual(self.container.add(5), 9)
        self.assertEqual(self.container.add(5), 10)
        self.assertEqual(self.container.get_median(), 3)
        self.assertTrue(self.container.delete(1))
        self.assertTrue(self.container.delete(1))
        self.assertFalse(self.container.delete(1))
        self.assertEqual(self.container.get_median(), 3)
        self.assertTrue(self.container.delete(2))
        self.assertTrue(self.container.delete(2))
        self.assertFalse(self.container.delete(2))
        self.assertEqual(self.container.get_median(), 4)
        self.assertTrue(self.container.delete(3))
        self.assertTrue(self.container.delete(4))
        self.assertTrue(self.container.delete(5))
        self.assertEqual(self.container.get_median(), 4)
