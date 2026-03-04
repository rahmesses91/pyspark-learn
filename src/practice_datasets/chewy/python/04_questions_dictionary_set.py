"""
Chewy Interview Research — Domain C: Dictionary & Set Power User

Lookups, cross-references, frequency counts, set operations. No Stack/Queue, no Heap.
"""

from typing import List, Dict, Any, Optional

# ---------------------------------------------------------------------------
# Dataset requirements
# ---------------------------------------------------------------------------

DATASETS = {
    "n_sentences": {
        "description": "List of strings (e.g. product descriptions or log messages); find words common to all",
        "sample": [["dog food is great", "dog food is healthy", "we sell dog food"]],
    },
    "items_and_categories": {
        "description": "List of (item_id or name, category) tuples",
        "sample": [[("A", "X"), ("B", "Y"), ("C", "X"), ("D", "Y")]],
    },
    "sparse_vectors": {
        "description": "Two dicts: {index: value} for sparse vectors (e.g. {0: 1, 2: 3}, {1: 2, 2: 4})",
        "sample": [({0: 1, 2: 3, 5: 2}, {1: 2, 2: 4, 5: 1})],
    },
    "review_text_stopwords": {
        "description": "String (review text) and set/list of stop words (e.g. the, and, is)",
        "sample": [("The dog and the cat are friends", {"the", "and", "is", "are"})],
    },
    "two_strings_isomorphic": {
        "description": "Two strings (e.g. product name patterns) to check if character mapping is consistent",
        "sample": [("egg", "add"), ("foo", "bar"), ("paper", "title")],
    },
    "clickstream_or_string": {
        "description": "String (e.g. clickstream or product ID string); find first non-repeating character",
        "sample": ["leetcode", "loveleetcode", "aabb"],
    },
    "order_list_custom_order": {
        "description": "List to sort (e.g. item IDs) and list defining relative order (subset of elements)",
        "sample": [([2, 1, 4, 3, 5], [5, 4, 2, 1, 3]), (["b", "a", "c"], ["c", "b", "a"])],
    },
    "item_ids_appear_twice": {
        "description": "List of ints (item IDs); each element appears 1 or 2 times. Return all that appear exactly twice. O(n).",
        "sample": [[4, 3, 2, 7, 8, 2, 3, 1], [1, 1, 2, 2]],
    },
    "catalog_a_b": {
        "description": "Two sets or lists of item IDs (catalog A and B); symmetric difference",
        "sample": [({1, 2, 3}, {2, 3, 4}), ([1, 2, 3], [2, 3, 4])],
    },
    "two_lists_permutation": {
        "description": "Two lists of ints (or strings); check if one is permutation of the other",
        "sample": [([1, 2, 3], [3, 2, 1]), ([1, 2], [1, 2, 2])],
    },
    "list_of_strings_anagrams": {
        "description": "List of strings (e.g. product names or tags); group into anagram groups",
        "sample": [["eat", "tea", "tan", "ate", "nat", "bat"]],
    },
    "two_arrays_intersection": {
        "description": "Two lists of ints; return unique elements that appear in both (intersection)",
        "sample": [([1, 2, 2, 1], [2, 2]), ([4, 9, 5], [9, 4, 9, 8, 4])],
    },
    "ransom_magazine": {
        "description": "Two strings: ransom note and magazine; can we form ransom from magazine (each char use once)?",
        "sample": [("a", "b"), ("aa", "ab"), ("aa", "aab")],
    },
    "first_repeating_char": {
        "description": "String; return first character that appears more than once (or first duplicate)",
        "sample": ["geeksforgeeks", "abcde", "abbac"],
    },
    "distinct_in_window_k": {
        "description": "List of ints and window size k; return list of distinct count in each window of size k",
        "sample": [([1, 2, 1, 3, 4, 2, 3], 4)],
    },
    "sort_by_frequency_then_value": {
        "description": "List of ints; sort by frequency (asc or desc), then by value for ties",
        "sample": [[1, 2, 2, 2, 3, 3, 1], [4, 4, 2, 2, 2, 2]],
    },
    "pairs_with_sum_count": {
        "description": "List of ints and target sum; count pairs (i, j) i < j such that arr[i] + arr[j] == target",
        "sample": [([1, 5, 7, -1, 5], 6), ([1, 1, 1, 1], 2)],
    },
    "longest_consecutive_sequence": {
        "description": "Unsorted list of ints; find length of longest consecutive sequence (e.g. [100,4,200,1,3,2] -> 4 for 1,2,3,4)",
        "sample": [[100, 4, 200, 1, 3, 2], [0, -1, 1, 2]],
    },
    "tag_counter_case_normalize": {
        "description": "List of strings (tags or words); count occurrences with case normalized (e.g. Dog -> dog)",
        "sample": [["Python", "python", "PYTHON", "java", "Java"]],
    },
    "smallest_window_containing_pattern": {
        "description": "String s and string t; find smallest substring of s that contains all characters of t (frequency matters). Return length or substring.",
        "sample": [("ADOBECODEBANC", "ABC"), ("a", "a")],
    },
    "partition_labels": {
        "description": "String s; partition into maximum number of parts so each letter appears in at most one part. Return list of part lengths.",
        "sample": ["ababcbacadefegdehijhklij", "eccbbbbdec"],
    },
}


QUESTIONS: List[Dict[str, Any]] = [
    {
        "id": "C01",
        "title": "Common Words Across N Sentences",
        "description": (
            "Given a list of strings (e.g. product descriptions), find the set of words that appear in every string. "
            "Words are space-separated; normalize case if needed."
        ),
        "core_concepts": ["Set intersection", "str.split", "set(word for word in ...)"],
        "why_chewy": "Finding common attributes across product or log text.",
        "interviewer_evaluates": "Using set.intersection(*list_of_sets); handling empty list.",
        "common_mistakes": "Using list and manual loop instead of intersection; not handling empty input.",
        "dataset_required": "n_sentences",
    },
    {
        "id": "C02",
        "title": "Group Items by Category",
        "description": (
            "Given a list of (item, category) tuples, return a dictionary: category -> list of items. "
            "Use defaultdict or setdefault; preserve order within each group if needed."
        ),
        "core_concepts": ["defaultdict(list) or setdefault", "Grouping"],
        "why_chewy": "Grouping products by category; common ETL pattern.",
        "interviewer_evaluates": "Not manually checking 'if key not in dict'; efficient append.",
        "common_mistakes": "Manually checking key in dict (verbose); overwriting instead of appending.",
        "dataset_required": "items_and_categories",
    },
    {
        "id": "C03",
        "title": "Sparse Vector Dot Product",
        "description": (
            "Given two vectors represented as dicts {index: value}, compute the dot product. "
            "Only indices present in both contribute; missing index implies 0."
        ),
        "core_concepts": ["Dictionary iteration", "Key matching", "Sum over common keys"],
        "why_chewy": "Recommendation or similarity data often in sparse form.",
        "interviewer_evaluates": "Iterating over smaller dict; handling empty dicts.",
        "common_mistakes": "Assuming same keys; iterating over both and double-counting.",
        "dataset_required": "sparse_vectors",
    },
    {
        "id": "C04",
        "title": "Word Frequency with Stop Words Excluded",
        "description": (
            "Given a string (e.g. review) and a set of stop words, return a dict of word -> count for words not in stop words. "
            "Normalize case and strip punctuation as needed."
        ),
        "core_concepts": ["Set for O(1) lookup", "Counter or dict", "String cleaning"],
        "why_chewy": "Review analytics; keyword extraction.",
        "interviewer_evaluates": "Using set for stop words (not list); consistent tokenization.",
        "common_mistakes": "Using list for stop words (O(n) per word); not lowercasing.",
        "dataset_required": "review_text_stopwords",
    },
    {
        "id": "C05",
        "title": "Isomorphic Strings (Product Name Pattern)",
        "description": (
            "Determine if two strings follow the same character mapping (e.g. 'egg' -> 'add': e->a, g->d). "
            "Must be bijection: two different chars cannot map to same char."
        ),
        "core_concepts": ["Two dicts or dual mapping", "Length check", "Consistency check"],
        "why_chewy": "Detecting similar naming patterns; data quality.",
        "interviewer_evaluates": "Checking both directions; handling unequal length.",
        "common_mistakes": "Only one-way mapping; allowing many-to-one.",
        "dataset_required": "two_strings_isomorphic",
    },
    {
        "id": "C06",
        "title": "First Unique (Non-Repeating) Character",
        "description": (
            "Find the first character in a string that does not repeat. Return its index or the character. Return -1 or None if none."
        ),
        "core_concepts": ["Frequency count (dict or Counter)", "Second pass for first with count 1", "Or OrderedDict"],
        "why_chewy": "Stream or clickstream analysis; first unique event.",
        "interviewer_evaluates": "Handling 'none found'; single pass with ordered dict if known.",
        "common_mistakes": "Not handling all repeated; returning last instead of first.",
        "dataset_required": "clickstream_or_string",
    },
    {
        "id": "C07",
        "title": "Relative Sort (Custom Order)",
        "description": (
            "Sort the first list according to the order defined by the second list. "
            "Elements in first but not in second go at end (original or sorted). Use dict for order index."
        ),
        "core_concepts": ["Dict for element -> rank", "Sort key lambda", "Handling missing in order list"],
        "why_chewy": "Display order by category priority or business rules.",
        "interviewer_evaluates": "Custom key: order.get(x, max_order+1) or similar; stable for unknowns.",
        "common_mistakes": "Assuming all elements in order list; wrong tie-break.",
        "dataset_required": "order_list_custom_order",
    },
    {
        "id": "C08",
        "title": "Find All Duplicates (Appear Exactly Twice) in O(n)",
        "description": (
            "Array of ints; each element appears 1 or 2 times. Return all elements that appear exactly twice. "
            "O(n) time; use set or dict to track seen/first occurrence."
        ),
        "core_concepts": ["Set or dict", "Single pass", "No sort"],
        "why_chewy": "Finding duplicate order or event IDs in a stream.",
        "interviewer_evaluates": "Not sorting; correct 'exactly twice' logic.",
        "common_mistakes": "Sorting (O(n log n)); returning elements that appear once.",
        "dataset_required": "item_ids_appear_twice",
    },
    {
        "id": "C09",
        "title": "Symmetric Difference of Two Catalogs",
        "description": (
            "Given two sets (or lists) of item IDs, return items that are in A or B but not in both. "
            "Use set operator ^ or (A - B) | (B - A)."
        ),
        "core_concepts": ["Set symmetric_difference", "Or manual (A-B) union (B-A)"],
        "why_chewy": "Catalog comparison; items unique to one source.",
        "interviewer_evaluates": "Knowing set operators; handling list input (convert to set).",
        "common_mistakes": "Returning intersection; not deduplicating list input.",
        "dataset_required": "catalog_a_b",
    },
    {
        "id": "C10",
        "title": "Check If Two Lists Are Permutations",
        "description": (
            "Given two lists of integers (or strings), return True if one is a permutation of the other (same multiset). "
            "Use Counter or sorted; Counter is O(n)."
        ),
        "core_concepts": ["Counter equality", "Or sort both and compare"],
        "why_chewy": "Validating two data feeds contain same counts of IDs.",
        "interviewer_evaluates": "Counter(a) == Counter(b); handling different lengths.",
        "common_mistakes": "Only checking set equality (loses count); not handling length.",
        "dataset_required": "two_lists_permutation",
    },
    {
        "id": "C11",
        "title": "Group Anagrams Together",
        "description": (
            "Given a list of strings, group them into lists of anagrams. Return list of groups. "
            "Use dict: key = normalized form (e.g. sorted tuple of chars), value = list of original strings."
        ),
        "core_concepts": ["Dict with tuple/sorted key", "Grouping"],
        "why_chewy": "Clustering similar product names or tags.",
        "interviewer_evaluates": "Immutable key (tuple of sorted chars); O(n * k log k) with k = max len.",
        "common_mistakes": "Using list as key (unhashable); not grouping correctly.",
        "dataset_required": "list_of_strings_anagrams",
    },
    {
        "id": "C12",
        "title": "Intersection of Two Arrays (Unique)",
        "description": (
            "Given two arrays, return the list of unique elements that appear in both. "
            "Result order can be arbitrary or match first array."
        ),
        "core_concepts": ["Set intersection", "Convert to set"],
        "why_chewy": "Common items in two segments (e.g. two user cohorts).",
        "interviewer_evaluates": "set(a) & set(b); handling duplicates in result.",
        "common_mistakes": "Returning duplicates; O(n^2) with nested loops.",
        "dataset_required": "two_arrays_intersection",
    },
    {
        "id": "C13",
        "title": "Ransom Note from Magazine",
        "description": (
            "Given ransom note string and magazine string, return True if we can form ransom from magazine (each char used once). "
            "Count chars in magazine; decrement for each char in ransom."
        ),
        "core_concepts": ["Counter or dict", "Single pass or two passes"],
        "why_chewy": "String composition checks; token availability.",
        "interviewer_evaluates": "Correct count logic; handling duplicate letters in ransom.",
        "common_mistakes": "Not allowing reuse of same char count; wrong comparison.",
        "dataset_required": "ransom_magazine",
    },
    {
        "id": "C14",
        "title": "First Repeating Character",
        "description": (
            "Given a string, return the first character that appears more than once (first duplicate). "
            "Return None or '' if no duplicate. Use dict to store first index or count."
        ),
        "core_concepts": ["Dict for index or count", "First occurrence tracking"],
        "why_chewy": "Finding first duplicate in event stream or ID sequence.",
        "interviewer_evaluates": "First vs any duplicate; handling no duplicate.",
        "common_mistakes": "Returning last duplicate; returning first occurrence of repeated char wrongly.",
        "dataset_required": "first_repeating_char",
    },
    {
        "id": "C15",
        "title": "Distinct Elements in Every Window of Size K",
        "description": (
            "Given an array and k, return a list where each element is the count of distinct elements in that window of size k. "
            "Sliding window + Counter (add right, remove left)."
        ),
        "core_concepts": ["Sliding window", "Counter for frequencies", "Distinct count from Counter len or explicit count"],
        "why_chewy": "Rolling diversity metric (e.g. distinct categories in last k events).",
        "interviewer_evaluates": "Efficient update when sliding; handling k > len.",
        "common_mistakes": "Recomputing distinct each time; wrong window bounds.",
        "dataset_required": "distinct_in_window_k",
    },
    {
        "id": "C16",
        "title": "Sort by Frequency Then by Value",
        "description": (
            "Sort array so that elements are ordered by frequency (e.g. ascending), then by value for ties. "
            "Return sorted list. Use Counter and custom key."
        ),
        "core_concepts": ["Counter", "Sort key (freq, value)"],
        "why_chewy": "Displaying items by popularity then by ID.",
        "interviewer_evaluates": "Stable sort; correct tie-break.",
        "common_mistakes": "Wrong order (desc vs asc); inconsistent tie-break.",
        "dataset_required": "sort_by_frequency_then_value",
    },
    {
        "id": "C17",
        "title": "Count Pairs with Given Sum",
        "description": (
            "Given array and target sum, count pairs (i, j) with i < j such that arr[i] + arr[j] == target. "
            "Use dict to store complement counts; handle duplicates (e.g. [1,1,1,1] and 2 -> 6 pairs)."
        ),
        "core_concepts": ["Complement map", "Count before adding to map for same-index avoidance"],
        "why_chewy": "Pair counting for recommendations or bundles.",
        "interviewer_evaluates": "Correct handling of duplicate values; i < j.",
        "common_mistakes": "Counting (i,j) and (j,i); not handling duplicates.",
        "dataset_required": "pairs_with_sum_count",
    },
    {
        "id": "C18",
        "title": "Longest Consecutive Sequence",
        "description": (
            "Unsorted array of ints; find the length of the longest consecutive number sequence (e.g. 1,2,3,4). "
            "Use set; for each num, if num-1 not in set, extend streak forward."
        ),
        "core_concepts": ["Set for O(1) lookup", "Only start streak when num-1 not in set", "O(n) total"],
        "why_chewy": "Finding contiguous ID or date ranges in unsorted data.",
        "interviewer_evaluates": "Not sorting; starting streaks only at sequence start.",
        "common_mistakes": "Sorting (O(n log n)); starting from every element (O(n*k)).",
        "dataset_required": "longest_consecutive_sequence",
    },
    {
        "id": "C19",
        "title": "Tag Counter with Case Normalization",
        "description": (
            "Given a list of tags (strings), return a dict of tag -> count with case normalized (e.g. all lower). "
            "So 'Python' and 'python' count together."
        ),
        "core_concepts": ["Counter or dict", "str.lower() as key"],
        "why_chewy": "Aggregating tags or categories from user input.",
        "interviewer_evaluates": "Single normalization; preserving one casing in output if needed.",
        "common_mistakes": "Case-sensitive count; wrong key (original vs normalized).",
        "dataset_required": "tag_counter_case_normalize",
    },
    {
        "id": "C20",
        "title": "Smallest Window Containing All Characters of Pattern",
        "description": (
            "String s and string t. Find smallest substring of s that contains all characters of t (frequency matters). "
            "Return the substring or its length. Sliding window + two counters."
        ),
        "core_concepts": ["Sliding window", "Counter for t and window", "Shrink when valid"],
        "why_chewy": "Finding minimal segment that covers a set of attributes.",
        "interviewer_evaluates": "Handling frequency (t can have repeated chars); O(n).",
        "common_mistakes": "Only checking presence not frequency; inefficient valid check.",
        "dataset_required": "smallest_window_containing_pattern",
    },
    {
        "id": "C21",
        "title": "Partition Labels",
        "description": (
            "Partition string into maximum number of parts so each letter appears in at most one part. "
            "Return list of lengths of each part. Build last-index map; greedy extend until current end equals last seen."
        ),
        "core_concepts": ["Last index map (dict)", "Greedy extend end boundary"],
        "why_chewy": "Segmenting sessions or events by unique attribute scope.",
        "interviewer_evaluates": "Correct greedy logic; updating end when extending.",
        "common_mistakes": "Wrong boundary update; not using last index.",
        "dataset_required": "partition_labels",
    },
]


def get_all_questions() -> List[Dict[str, Any]]:
    return list(QUESTIONS)


def get_dataset_spec(name: str) -> Optional[Dict[str, Any]]:
    return DATASETS.get(name)
