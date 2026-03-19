"""
LeetCode-style: Minimum Mountain Sum (Mountain Triplet)
Find the minimum sum of nums[i] + nums[j] + nums[k] where i < j < k
and nums[i] < nums[j] > nums[k] (j is a peak).
"""

from typing import List


class Solution:
    def minimumSum(self, nums: List[int]) -> int:
        n = len(nums)
        if n < 3:
            return -1

        # Precompute the minimum value seen from the left up to each index
        left_min = [0] * n
        left_min[0] = nums[0]
        for i in range(1, n):
            left_min[i] = min(left_min[i - 1], nums[i])

        # Precompute the minimum value seen from the right up to each index
        right_min = [0] * n
        right_min[n - 1] = nums[n - 1]
        for i in range(n - 2, -1, -1):
            right_min[i] = min(right_min[i + 1], nums[i])

        min_mountain_sum = float("inf")

        # Find the peak element 'j' that satisfies the mountain condition
        for j in range(1, n - 1):
            num_j = nums[j]
            min_left = left_min[j - 1]  # Min strictly to the left
            min_right = right_min[j + 1]  # Min strictly to the right

            # A mountain requires the peak to be greater than both neighbors
            if num_j > min_left and num_j > min_right:
                current_sum = num_j + min_left + min_right
                if current_sum < min_mountain_sum:
                    min_mountain_sum = current_sum

        return min_mountain_sum if min_mountain_sum != float("inf") else -1
