"""
Chewy Interview Research — Domain B: List & Array Manipulation

Two pointers, sliding window, prefix sums. No Stack/Queue, no Heap.
Framed for sequence analysis, time-series, and inventory-style problems.
"""

from typing import List, Dict, Any, Optional

# ---------------------------------------------------------------------------
# Dataset requirements
# ---------------------------------------------------------------------------

DATASETS = {
    "prices_array": {
        "description": "List of ints or floats: daily/product prices (e.g. [7, 1, 5, 3, 6, 4])",
        "sample": [[7, 1, 5, 3, 6, 4]],
    },
    "prices_and_k": {
        "description": "List of ints (prices or quantities), and int K for target sum",
        "sample": [([1, 2, 3, 4, 5], 9)],
    },
    "shipping_windows": {
        "description": "List of [start, end] intervals (e.g. [[1, 3], [2, 6], [8, 10]])",
        "sample": [[[1, 3], [2, 6], [8, 10], [7, 9]]],
    },
    "character_sequence": {
        "description": "String (e.g. product IDs or session string) and optional pattern string",
        "sample": [("cbaebabacd", "abc"), ("abab", "ab")],
    },
    "zeros_and_ones": {
        "description": "List of ints with 0s and 1s (e.g. in-stock 1, out-of-stock 0)",
        "sample": [[0, 1, 0, 3, 12], [1, 0, 1, 0, 1]],
    },
    "item_ids_and_budget": {
        "description": "List of ints (item IDs or prices), and int target sum",
        "sample": [([2, 7, 11, 15], 9), ([3, 2, 4], 6)],
    },
    "product_name_string": {
        "description": "String (e.g. product name or SKU) for longest unique-char substring",
        "sample": ["abcabcbb", "bbbbb", "pwwkew"],
    },
    "sequential_ids": {
        "description": "List of ints: consecutive IDs with one or more missing (e.g. [1, 2, 4, 5, 6])",
        "sample": [[1, 2, 4, 5, 6], [1, 3, 4]],
    },
    "products_rotate": {
        "description": "List of elements and int K; rotate right by K steps",
        "sample": [([1, 2, 3, 4, 5], 2), ([-1, -100, 3, 99], 2)],
    },
    "sales_counts": {
        "description": "List of ints: per-item or per-day counts (e.g. [2, 2, 1, 1, 1, 2, 2])",
        "sample": [[2, 2, 1, 1, 1, 2, 2], [3, 2, 3]],
    },
    "binary_array": {
        "description": "List of 0s and 1s (e.g. [1, 1, 0, 1, 1, 1] for consecutive ones)",
        "sample": [[1, 1, 0, 1, 1, 1], [1, 0, 1, 1, 0, 1]],
    },
    "subarray_sum_at_most_k": {
        "description": "List of ints (can have negatives) and int K; longest subarray with sum <= K",
        "sample": [([1, 2, -1, 3, 4], 5)],
    },
    "pairs_difference_k": {
        "description": "List of unique ints and int K; find count of pairs with difference exactly K",
        "sample": [([1, 5, 3, 4, 2], 2), ([1, 2, 3, 4, 5], 1)],
    },
    "partition_equal_sum": {
        "description": "List of ints; return True if can partition into two subsets with equal sum",
        "sample": [[1, 5, 11, 5], [1, 2, 3, 5]],
    },
    "pivot_index": {
        "description": "List of ints; find leftmost index where sum(left) == sum(right) (exclude pivot)",
        "sample": [[1, 7, 3, 6, 5, 6], [1, 2, 3], [2, 1, -1]],
    },
    "fixed_window_k": {
        "description": "List of ints and int k; max sum of any contiguous subarray of length k",
        "sample": [([2, 1, 5, 1, 3, 2], 3), ([1, 2, 3, 4, 5], 2)],
    },
    "product_except_self": {
        "description": "List of ints; return list where output[i] = product of all elements except nums[i]. O(n), no division.",
        "sample": [[1, 2, 3, 4], [2, 3, 4, 5]],
    },
    "duplicate_in_1_to_n": {
        "description": "List of ints from 1 to n with one duplicate (length n+1); find the duplicate in O(n) time, O(1) extra space optional.",
        "sample": [[1, 3, 4, 2, 2], [3, 1, 3, 4, 2]],
    },
    "sort_0s_and_1s": {
        "description": "List of only 0s and 1s; sort in one pass in-place (e.g. two pointers).",
        "sample": [[1, 0, 1, 0, 1], [0, 0, 1, 1]],
    },
    "at_most_k_distinct": {
        "description": "String and int k; length of longest substring with at most k distinct characters.",
        "sample": [("eceba", 2), ("aa", 1)],
    },
    "numbers_disappeared": {
        "description": "List of ints from 1 to n (length n); some appear once or twice. Find all integers in [1..n] that do not appear.",
        "sample": [[4, 3, 2, 7, 8, 2, 3, 1], [1, 1]],
    },
}


QUESTIONS: List[Dict[str, Any]] = [
    {
        "id": "B01",
        "title": "Max Profit Single Buy and Sell (Best Time to Buy/Sell)",
        "description": (
            "Given an array of prices, find the maximum profit from a single buy and sell. "
            "You must buy before you sell. Return 0 if no profit possible."
        ),
        "core_concepts": ["Two pointers or single pass", "Min-tracking", "O(n) time"],
        "why_chewy": "Pricing and inventory decisions; simple sequence analysis.",
        "interviewer_evaluates": "Avoiding O(n^2); clean tracking of min-so-far and max profit.",
        "common_mistakes": "Brute force two loops; off-by-one on indices.",
        "dataset_required": "prices_array",
    },
    {
        "id": "B02",
        "title": "Subarray Sum Equals K (Count)",
        "description": (
            "Given an array of integers and integer K, find the number of contiguous subarrays whose sum equals K. "
            "Negative numbers allowed."
        ),
        "core_concepts": ["Prefix sum", "HashMap (count of prefix sums)", "O(n) solution"],
        "why_chewy": "Segment analysis (e.g. periods where revenue equals target).",
        "interviewer_evaluates": "Moving from O(n^2) to prefix-sum + map; handling negative sums.",
        "common_mistakes": "Missing prefix_sum 0; not updating count before using it.",
        "dataset_required": "prices_and_k",
    },
    {
        "id": "B03",
        "title": "Merge Overlapping Intervals",
        "description": (
            "Given a list of intervals [start, end], merge all overlapping intervals and return sorted, non-overlapping list."
        ),
        "core_concepts": ["Sorting", "List merge", "Comparing endpoints"],
        "why_chewy": "Shipping windows, availability windows, time ranges.",
        "interviewer_evaluates": "Sort by start; merge in one pass; edge case (single interval).",
        "common_mistakes": "Not sorting; wrong merge condition (strict < vs <=).",
        "dataset_required": "shipping_windows",
    },
    {
        "id": "B04",
        "title": "Find All Anagrams in a String",
        "description": (
            "Given string s and string p, find all start indices of substrings in s that are anagrams of p. "
            "Use sliding window; avoid re-sorting every window."
        ),
        "core_concepts": ["Sliding window", "HashMap or Counter for frequency", "Fixed window size"],
        "why_chewy": "Pattern matching in IDs or session data.",
        "interviewer_evaluates": "O(n) with frequency comparison; not sorting window each time.",
        "common_mistakes": "Re-sorting the window; wrong window boundaries.",
        "dataset_required": "character_sequence",
    },
    {
        "id": "B05",
        "title": "Move Zeros to End",
        "description": (
            "Move all 0s in the list to the end while maintaining the relative order of non-zero elements. In-place, O(n)."
        ),
        "core_concepts": ["Two pointers", "In-place swap/write", "No extra list"],
        "why_chewy": "Filtering out-of-stock (0) items to end of list without losing order.",
        "interviewer_evaluates": "Single pass; no unnecessary space.",
        "common_mistakes": "Using extra list; two passes when one suffices.",
        "dataset_required": "zeros_and_ones",
    },
    {
        "id": "B06",
        "title": "Two Sum (Indices or Values)",
        "description": (
            "Given an array of integers and target, find two numbers that add up to target. "
            "Return their indices (or values). Exactly one solution exists; same element not used twice."
        ),
        "core_concepts": ["HashMap (value -> index)", "Single pass", "Complement check"],
        "why_chewy": "Finding product pairs for bundles or budget matching.",
        "interviewer_evaluates": "HashMap in one pass; handling duplicate values correctly.",
        "common_mistakes": "Using same index twice; brute force.",
        "dataset_required": "item_ids_and_budget",
    },
    {
        "id": "B07",
        "title": "Longest Substring Without Repeating Characters",
        "description": (
            "Find the length of the longest substring without repeating characters. Use sliding window + set or dict."
        ),
        "core_concepts": ["Sliding window", "Set or dict for seen chars", "Shrinking window on duplicate"],
        "why_chewy": "Uniqueness constraints; characterizing string/session data.",
        "interviewer_evaluates": "O(n) with expand/shrink; correct handling of window.",
        "common_mistakes": "Resetting start too aggressively; O(n^2) with nested loops.",
        "dataset_required": "product_name_string",
    },
    {
        "id": "B08",
        "title": "Find Missing Transaction ID(s)",
        "description": (
            "Given a list of sequential IDs with one or more missing (e.g. [1, 2, 4, 5, 6]), "
            "return all missing IDs. Use set or arithmetic (min, max, expected sum)."
        ),
        "core_concepts": ["Set difference", "Or sum formula", "O(n) time"],
        "why_chewy": "Auditing event or order ID sequences; data quality checks.",
        "interviewer_evaluates": "Correct handling of multiple gaps; O(1) space awareness.",
        "common_mistakes": "Assuming exactly one missing; sorting when not needed.",
        "dataset_required": "sequential_ids",
    },
    {
        "id": "B09",
        "title": "Rotate Array Right by K",
        "description": (
            "Rotate the list to the right by K steps. In-place preferred (reverse trick: reverse whole, reverse first k, reverse rest)."
        ),
        "core_concepts": ["List slicing", "Reverse in-place", "K % len to handle K > len"],
        "why_chewy": "Inventory cycle or queue-like rotation without actual queue DS.",
        "interviewer_evaluates": "Handling K > n; in-place if required.",
        "common_mistakes": "Extra O(n) space when in-place asked; not doing K % n.",
        "dataset_required": "products_rotate",
    },
    {
        "id": "B10",
        "title": "Majority Element (Top Seller)",
        "description": (
            "Find the element that appears more than n/2 times. Assume majority always exists. "
            "Boyer-Moore voting or single dict pass."
        ),
        "core_concepts": ["Boyer-Moore voting or Counter", "O(n) time, O(1) space with voting"],
        "why_chewy": "Finding dominant category or top seller in a stream.",
        "interviewer_evaluates": "Knowing O(1) space approach; correctness of voting logic.",
        "common_mistakes": "Returning wrong element when count ties; not handling length 1.",
        "dataset_required": "sales_counts",
    },
    {
        "id": "B11",
        "title": "Longest Subarray with Sum <= K",
        "description": (
            "Given an array of integers (can include negatives) and K, find the length of the longest contiguous subarray "
            "with sum <= K. Sliding window works when all positive; prefix + structure when negative allowed."
        ),
        "core_concepts": ["Sliding window (if all positive)", "Prefix sum + monotonic or map (if negative)"],
        "why_chewy": "Budget or capacity constraints over contiguous segments.",
        "interviewer_evaluates": "Correct approach for sign of numbers; edge case K negative.",
        "common_mistakes": "Using sliding window with negatives (fails); not handling empty.",
        "dataset_required": "subarray_sum_at_most_k",
    },
    {
        "id": "B12",
        "title": "Pairs with Given Difference K",
        "description": (
            "Given an array of distinct integers and K, find the number of pairs (i, j) such that abs(arr[i] - arr[j]) == K. "
            "Use set for O(n); or sort + two pointers."
        ),
        "core_concepts": ["Set lookup", "Or sort + two pointers", "Avoid double counting"],
        "why_chewy": "Finding price bands or ID ranges with fixed gap.",
        "interviewer_evaluates": "O(n) with set; handling K=0 if duplicates were allowed.",
        "common_mistakes": "Double counting (a, b) and (b, a); O(n^2) brute force.",
        "dataset_required": "pairs_difference_k",
    },
    {
        "id": "B13",
        "title": "Partition Array into Two Equal Sum Subsets",
        "description": (
            "Given an array of integers, return True if it can be partitioned into two subsets with equal sum. "
            "Each element in exactly one subset. (Subset sum variant; can use set of reachable sums.)"
        ),
        "core_concepts": ["Set of reachable sums", "Odd total => False", "DP-style set update"],
        "why_chewy": "Balancing loads or splits in data pipelines.",
        "interviewer_evaluates": "Quick check for sum % 2; correct set propagation.",
        "common_mistakes": "Not handling odd sum; wrong recurrence.",
        "dataset_required": "partition_equal_sum",
    },
    {
        "id": "B14",
        "title": "Find Pivot Index",
        "description": (
            "Return the leftmost pivot index: sum of elements to the left equals sum of elements to the right (exclude pivot). "
            "Return -1 if no such index."
        ),
        "core_concepts": ["Prefix sum", "Single pass with right sum derived from total - left - pivot"],
        "why_chewy": "Balance point in time series or weighted splits.",
        "interviewer_evaluates": "O(n) with O(1) extra space; edge (first/last element).",
        "common_mistakes": "Recomputing right sum in loop (O(n^2)); off-by-one.",
        "dataset_required": "pivot_index",
    },
    {
        "id": "B15",
        "title": "Max Sum of Subarray of Size K (Fixed Window)",
        "description": (
            "Given an array and integer k, find the maximum sum of any contiguous subarray of length k. Classic sliding window."
        ),
        "core_concepts": ["Fixed-size sliding window", "Add right, drop left", "O(n)"],
        "why_chewy": "Rolling metrics (e.g. max revenue in last k days).",
        "interviewer_evaluates": "Clean window slide; handling k > len.",
        "common_mistakes": "Recalculating window sum each time; not handling k == 0.",
        "dataset_required": "fixed_window_k",
    },
    {
        "id": "B16",
        "title": "Product of Array Except Self",
        "description": (
            "Return an array where output[i] = product of all elements except nums[i]. O(n) time, no division. "
            "Use prefix and suffix products (or two passes)."
        ),
        "core_concepts": ["Prefix/suffix arrays or single pass", "No division constraint"],
        "why_chewy": "Aggregation that excludes self (e.g. recommendation features).",
        "interviewer_evaluates": "Avoiding division; O(1) extra space (output不计) with two passes.",
        "common_mistakes": "Using division; O(n) extra for prefix and suffix when one pass possible.",
        "dataset_required": "product_except_self",
    },
    {
        "id": "B17",
        "title": "Find Duplicate in 1 to n Array",
        "description": (
            "Array of length n+1 contains integers 1..n; exactly one duplicate. Find it. "
            "Floyd cycle (if interpret as linked list) or set; optionally O(1) space with cycle detection."
        ),
        "core_concepts": ["Set", "Or index-based cycle detection (Floyd)"],
        "why_chewy": "Data quality: finding duplicate event or order IDs.",
        "interviewer_evaluates": "O(n) time; awareness of O(1) space cycle method.",
        "common_mistakes": "Modifying array when not allowed; wrong cycle start.",
        "dataset_required": "duplicate_in_1_to_n",
    },
    {
        "id": "B18",
        "title": "Sort 0s and 1s In-Place (One Pass)",
        "description": (
            "Array contains only 0s and 1s. Sort in ascending order in one pass, in-place (e.g. two pointers: swap 1s to end)."
        ),
        "core_concepts": ["Two pointers", "Swap logic", "In-place"],
        "why_chewy": "Binary flags (e.g. in-stock/out-of-stock) reordering.",
        "interviewer_evaluates": "Single pass; no extra array.",
        "common_mistakes": "Two passes; using sort().",
        "dataset_required": "sort_0s_and_1s",
    },
    {
        "id": "B19",
        "title": "Longest Substring with At Most K Distinct Characters",
        "description": (
            "Given a string and k, find the length of the longest substring containing at most k distinct characters. Sliding window + counter."
        ),
        "core_concepts": ["Sliding window", "Counter or dict for char counts", "Shrink when distinct > k"],
        "why_chewy": "Segmenting sequences by diversity (e.g. category mix in session).",
        "interviewer_evaluates": "Correct shrink logic; handling k=0.",
        "common_mistakes": "Shrinking too much; off-by-one on distinct count.",
        "dataset_required": "at_most_k_distinct",
    },
    {
        "id": "B20",
        "title": "Find All Numbers Disappeared in Array",
        "description": (
            "Array of length n, each element in [1, n]. Some appear once or twice. Return list of all integers in [1, n] that do not appear. "
            "Optional: O(n) time, O(1) extra space using index marking (negate or +n)."
        ),
        "core_concepts": ["Set difference", "Or index marking (in-place)", "1-based index handling"],
        "why_chewy": "Auditing missing IDs or skipped events.",
        "interviewer_evaluates": "Index marking trick; handling 1-based indices.",
        "common_mistakes": "Using set only (extra space); wrong index (0 vs 1-based).",
        "dataset_required": "numbers_disappeared",
    },
]


def get_all_questions() -> List[Dict[str, Any]]:
    return list(QUESTIONS)


def get_dataset_spec(name: str) -> Optional[Dict[str, Any]]:
    return DATASETS.get(name)
