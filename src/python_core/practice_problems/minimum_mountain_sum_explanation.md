# Minimum Mountain Sum - Solution Explanation

## Problem Summary

Given an array `nums`, find the **minimum sum** of a **mountain triplet** — three indices `i < j < k` such that:
- `nums[i] < nums[j]` (element at `j` is greater than element at `i`)
- `nums[j] > nums[k]` (element at `j` is greater than element at `k`)

In other words, index `j` is a **peak** — it is greater than both its left neighbor (at `i`) and right neighbor (at `k`).

**Goal:** Minimize `nums[i] + nums[j] + nums[k]`.

---

## Approach: Precompute Left and Right Minimums

### Key Insight

For each potential peak index `j`, we want:
- The **smallest** value to the left of `j` (to minimize the sum)
- The **smallest** value to the right of `j` (to minimize the sum)

If `nums[j]` is greater than both of these, we have a valid mountain triplet, and the sum is minimized by choosing the smallest left and right values.

### Algorithm Steps

#### 1. Precompute `left_min`

- `left_min[i]` = minimum value in `nums[0..i]` (inclusive)
- Built left-to-right: `left_min[i] = min(left_min[i-1], nums[i])`
- For peak at `j`, the minimum value **strictly to the left** is `left_min[j-1]`

#### 2. Precompute `right_min`

- `right_min[i]` = minimum value in `nums[i..n-1]` (inclusive)
- Built right-to-left: `right_min[i] = min(right_min[i+1], nums[i])`
- For peak at `j`, the minimum value **strictly to the right** is `right_min[j+1]`

#### 3. Iterate Over Potential Peaks

- A peak can only occur at indices `1` to `n-2` (must have at least one element on each side)
- For each `j` in `[1, n-2]`:
  - `min_left = left_min[j-1]`
  - `min_right = right_min[j+1]`
  - If `nums[j] > min_left` and `nums[j] > min_right` → valid mountain
  - Sum = `nums[j] + min_left + min_right`
  - Track the minimum such sum

#### 4. Return Result

- If at least one valid mountain was found → return `min_mountain_sum`
- Otherwise → return `-1`

---

## Example Walkthrough

**Input:** `nums = [8, 6, 1, 5, 3]`

| Index | 0 | 1 | 2 | 3 | 4 |
|-------|---|---|---|---|---|
| nums  | 8 | 6 | 1 | 5 | 3 |

**left_min:** `[8, 6, 1, 1, 1]`  
**right_min:** `[1, 1, 1, 3, 3]`

**Peak at j=3 (value 5):**
- `min_left = left_min[2] = 1`
- `min_right = right_min[4] = 3`
- `5 > 1` ✓ and `5 > 3` ✓ → valid mountain
- Sum = 5 + 1 + 3 = **9**

**Peak at j=1 (value 6):**
- `min_left = left_min[0] = 8`
- `min_right = right_min[2] = 1`
- `6 > 8` ✗ → not valid

**Answer:** 9

---

## Time & Space Complexity

| Complexity | Value | Reason |
|------------|-------|--------|
| **Time**   | O(n)  | Two passes for `left_min` and `right_min`, one pass over peaks |
| **Space**  | O(n)  | Two arrays `left_min` and `right_min` of length n |

---

## Edge Cases Handled

- `n < 3` → return `-1` (need at least 3 elements for a triplet)
- No valid mountain → return `-1`
- All elements equal → no peak possible → return `-1`
