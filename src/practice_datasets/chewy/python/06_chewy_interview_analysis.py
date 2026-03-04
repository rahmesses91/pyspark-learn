"""
Chewy Interview Research — Analysis, Recurring Themes, and Preparation Roadmap

Summary of 35–50 additional medium Python questions for Data Engineer / Analytics Engineer.
No Stack/Queue, no Heap; focus on dicts, sets, lists, two pointers, sliding window,
string manipulation, data parsing, and real-world transformation.
"""

from typing import List, Dict, Any
import importlib.util
from pathlib import Path

def _load_question_module(name: str):
    """Load a question module by filename (e.g. 02_questions_data_parsing_cleaning) from same directory."""
    this_dir = Path(__file__).resolve().parent
    path = this_dir / f"{name}.py"
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod

# Lazy-load question banks (filenames cannot be imported as-is because they start with digits)
_PARSING = _ARRAY = _DICT_SET = _TRANSFORM = None

def get_all_questions_by_category() -> Dict[str, List[Dict[str, Any]]]:
    global _PARSING, _ARRAY, _DICT_SET, _TRANSFORM
    if _PARSING is None:
        _PARSING = _load_question_module("02_questions_data_parsing_cleaning")
        _ARRAY = _load_question_module("03_questions_list_array_manipulation")
        _DICT_SET = _load_question_module("04_questions_dictionary_set")
        _TRANSFORM = _load_question_module("05_questions_real_world_transformation")
    return {
        "data_parsing_cleaning": _PARSING.get_all_questions(),
        "list_array_manipulation": _ARRAY.get_all_questions(),
        "dictionary_set": _DICT_SET.get_all_questions(),
        "real_world_transformation": _TRANSFORM.get_all_questions(),
    }


def get_total_question_count() -> int:
    n = 0
    for qlist in get_all_questions_by_category().values():
        n += len(qlist)
    return n


# ---------------------------------------------------------------------------
# Recurring themes across the problems
# ---------------------------------------------------------------------------

RECURRING_THEMES = """
1. DATA RELIABILITY AND ROBUSTNESS
   - Validation: type checks, schema checks, None/empty handling.
   - Parsing: malformed input (missing delimiters, wrong types, extra spaces).
   - Edge cases: empty list, single element, duplicates, missing keys.
   Questions that emphasize this: CSV/row validators, env/log parsers, boolean normalizers,
   version validators, dedupe-by-key, and any "return None or raise" spec.

2. PERFORMANCE AWARENESS
   - O(n) vs O(n^2): hash-join vs nested loop, set/dict lookup vs list lookup, prefix-sum vs brute force.
   - Space: in-place where asked (move zeros, rotate array), avoiding unnecessary copies.
   - Single pass: frequency in one pass, min/max in one pass, running totals.
   Questions: Inner/left join, subarray sum equals K, majority element, first unique,
   find duplicates O(n), longest consecutive sequence, merge sorted streams.

3. NATIVE PYTHON OVER LIBRARIES
   - Prefer collections (defaultdict, Counter, OrderedDict), re, datetime, and basic types.
   - No pandas in these screens: implement group-by, join, pivot with dicts and lists.
   - String work: split, strip, regex; not necessarily full CSV readers.
   Questions: Pivot long-to-wide, rollup aggregation, group by category, merge streams,
   all parsing/cleaning problems.

4. DICTIONARY AND SET AS PRIMARY TOOLS
   - Lookup: join keys, allowed sets, stop words, seen IDs, prefix-sum counts.
   - Grouping: defaultdict(list), key = normalized form (e.g. sorted tuple for anagrams).
   - Frequency: Counter or dict for counts; distinct counts from len(Counter) or explicit.
   Questions: Group anagrams, group by category, hash-join, word frequency with stop words,
   relative sort, symmetric difference, ransom note, distinct in window.

5. SLIDING WINDOW AND TWO POINTERS
   - Fixed window: max sum of size k, anagrams in string, distinct count per window.
   - Variable window: longest substring without repeating, at most k distinct, smallest window containing pattern.
   - Two pointers: two sum, move zeros, sort 0s and 1s, merge sorted lists, pairs with difference K.
   Questions: All in list_array_manipulation (B04, B05, B07, B15, B19, B06, B12, B18) and some in dict_set (C15, C20).

6. REAL-WORLD DATA SHAPES
   - Long vs wide: pivot, rollup, running total by group.
   - Joins: inner and left; self-join for referrals.
   - Time and sessions: longest session, time between events, merge by timestamp.
   Questions: All in real_world_transformation (D01–D14).

7. STRING AND PARSING FLUENCY
   - Delimiters: pipe, comma, semicolon, key=value; quoted and escaped fields.
   - Normalization: case, whitespace, phone/email/boolean/version.
   - Extraction: numbers from text, dates from free text, key-value from logs.
   Questions: All in data_parsing_cleaning (A01–A14) and reinforced in 01_python_question_bank.md.
"""


# ---------------------------------------------------------------------------
# What Chewy likely prioritizes technically
# ---------------------------------------------------------------------------

CHEWY_PRIORITIES = """
- DATA ENGINEERING OVER DATA SCIENCE
  - Correctness and reliability of pipelines over model complexity.
  - Transforming messy input into clean, joinable structures.
  - Joins, group-by, and aggregations in pure Python (no pandas) to show fundamentals.

- PERFORMANCE IS KING
  - They care if you write O(n) vs O(n^2): hash-join, prefix-sum, set/dict lookups.
  - Single-pass solutions and minimal extra space when the problem allows it.
  - Awareness of when to use set vs list (lookup), Counter vs manual dict.

- NATIVE LIBRARIES PREFERRED
  - collections, re, datetime, basic types. Demonstrates you can work without pandas in a timed environment.
  - If they allow pandas later, you still show you understand the underlying logic.

- RELIABILITY BAR
  - Check for None, empty input, malformed rows.
  - Return None or raise clearly; don't crash on slight format changes (e.g. SKU format).
  - Validation and schema-like checks (e.g. price > 0, required fields).

- DOMAIN RELEVANCE (IMPLICIT)
  - Catalogs, SKUs, orders, events, sessions, timestamps, categories, prices.
  - Parsing logs, env configs, CSV-like and key=value formats.
  - Deduplication, latest-record-wins, and time-based aggregations.
"""


# ---------------------------------------------------------------------------
# Common mistakes (aggregated)
# ---------------------------------------------------------------------------

COMMON_MISTAKES_AGGREGATED = """
- Using list for membership when set is O(1): e.g. stop words, allowed categories.
- Nested loops when a hash structure gives O(n): joins, two sum, pair counting.
- Forgetting to strip or normalize: keys/values in parsing, case in comparisons.
- Mutating input when problem says "return new list" or "don't modify".
- Not handling empty input, single element, or duplicate keys.
- Sorting when problem asks O(n) or in-place (e.g. find duplicate in 1..n).
- Wrong boundary in sliding window (off-by-one, shrink condition).
- Building join in wrong direction (e.g. referrer -> list of referred).
- Keeping last duplicate instead of first (or vice versa) when spec says one.
- Using division in "product except self" when problem forbids it.
"""


# ---------------------------------------------------------------------------
# Two-week preparation roadmap
# ---------------------------------------------------------------------------

TWO_WEEK_ROADMAP = """
WEEK 1 — FOUNDATIONS AND PATTERNS

  Day 1–2: Data parsing and cleaning
  - Env parser, log line parser (Apache-style and key=value), phone/email normalizer.
  - Delimited parsing with quotes (semicolon, pipe); CSV field parser.
  - Dataset: use DATASETS in 02_questions_data_parsing_cleaning.py; add your own messy strings.
  - Goal: One-pass or clear stateful parsing; always strip and validate.

  Day 3: Dictionaries and sets
  - Group by key (defaultdict/setdefault), set intersection, Counter for frequency.
  - Word frequency with stop words (set for stop words), anagram grouping, relative sort.
  - Dataset: n_sentences, items_and_categories, review_text_stopwords, order_list_custom_order.
  - Goal: Never use list for membership when set is possible; know set operators (^, &, |, -).

  Day 4: Two pointers and sliding window (part 1)
  - Two sum, move zeros, merge overlapping intervals, best time to buy/sell.
  - Subarray sum equals K (prefix sum + map), pivot index, fixed-window max sum.
  - Dataset: prices_array, prices_and_k, zeros_and_ones, item_ids_and_budget, fixed_window_k.
  - Goal: Identify "complement" and "prefix sum" patterns; avoid brute force.

  Day 5: Sliding window (part 2) and array tricks
  - Longest substring without repeating, at most K distinct, find all anagrams.
  - Longest consecutive sequence (set), find duplicates O(n), product except self.
  - Dataset: product_name_string, at_most_k_distinct, character_sequence, numbers_disappeared.
  - Goal: Expand/shrink window logic; index marking for "disappeared" style.

  Day 6: Real-world transformation (joins and group-by)
  - Inner join and left join (hash-join); self-join for referrals.
  - Rollup aggregation, pivot long to wide, filter by column in set.
  - Dataset: orders_and_products, left_table_right_table, sales_day_store, long_format_sales.
  - Goal: Build dict from one table; iterate the other; handle one-to-many.

  Day 7: Review and mixed practice
  - One parsing, one dict/set, one sliding window, one transformation from the bank.
  - Time yourself (e.g. 20 min per problem); practice stating complexity.
  - Re-read RECURRING_THEMES and COMMON_MISTAKES_AGGREGATED.

WEEK 2 — DEPTH AND TIMED PRACTICE

  Day 8: Parsing edge cases and validation
  - Version parser, boolean normalizer, extract date from free text, duplicate rows by key column.
  - Implement a small "schema validator" (dict of column -> rule) for a list of dicts.
  - Goal: Return None or raise clearly; handle malformed and empty.

  Day 9: Dict/set harder problems
  - Smallest window containing pattern, partition labels, count pairs with sum, longest consecutive.
  - First repeating vs first unique; distinct in every window of size k.
  - Goal: Correct frequency checks in window; greedy with last-index map.

  Day 10: Array/list harder problems
  - Partition equal sum, product except self (no division), find duplicate in 1..n (cycle optional).
  - Rotate array in-place; find all numbers disappeared (index marking).
  - Goal: O(1) space where asked; no sort when O(n) possible.

  Day 11: Transformation depth
  - Running total by group, dense rank within category, top N per group.
  - Time between first and second event; merge two sorted streams.
  - Goal: Sort by (group, order_key); reset state when group changes.

  Day 12: Full mixed mock
  - Draw 2 parsing, 2 dict/set, 2 array, 2 transformation from the bank at random.
  - Do in HackerRank-style (no run until submit) or live-coding with interviewer voice-over.
  - Goal: Communicate approach first; handle follow-ups (e.g. "what if input is huge?").

  Day 13: Chewy-specific polish
  - Skim Chewy DATA_DICTIONARY (products, orders, events, users).
  - Redo: inner join orders-products, event count per (user, event_type), longest session from events-like data.
  - Goal: Use their column names and realistic shapes.

  Day 14: Light review and rest
  - Re-read CHEWY_PRIORITIES and COMMON_MISTAKES_AGGREGATED.
  - Do 2–3 "comfort" problems; avoid new heavy topics.
  - Goal: Enter interview with patterns and themes top of mind.
"""


# ---------------------------------------------------------------------------
# Export for documentation or CLI
# ---------------------------------------------------------------------------

def print_summary() -> None:
    cat = get_all_questions_by_category()
    total = get_total_question_count()
    print(f"Total questions: {total}")
    for name, qlist in cat.items():
        print(f"  {name}: {len(qlist)}")
    print("\n--- RECURRING THEMES ---")
    print(RECURRING_THEMES)
    print("\n--- CHEWY PRIORITIES ---")
    print(CHEWY_PRIORITIES)
    print("\n--- COMMON MISTAKES ---")
    print(COMMON_MISTAKES_AGGREGATED)
    print("\n--- TWO-WEEK ROADMAP ---")
    print(TWO_WEEK_ROADMAP)


if __name__ == "__main__":
    print_summary()
