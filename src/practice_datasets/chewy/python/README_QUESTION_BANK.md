# Chewy Python Interview Question Bank (Medium)

**Role:** Data Engineer / Analytics Engineer  
**Constraints:** No Stack/Queue, no Heap; avoid heavy graph/DP. Focus: dicts, sets, lists, two pointers, sliding window, string parsing, real-world transformation.

## Files

| File | Category | Count | Contents |
|------|----------|-------|----------|
| `01_python_question_bank.md` | String / text / lists (existing) | — | Pure Python string manipulation, parsing, validation |
| `02_questions_data_parsing_cleaning.py` | Data parsing & cleaning | 14 | Env parser, log parser, normalizers, flatten, validators, dedup by key |
| `03_questions_list_array_manipulation.py` | List & array | 20 | Two pointers, sliding window, prefix sum, merge intervals, rotate, majority |
| `04_questions_dictionary_set.py` | Dictionary & set | 21 | Group by, anagrams, frequency, isomorphic, relative sort, symmetric diff |
| `05_questions_real_world_transformation.py` | Real-world transformation | 14 | Inner/left join, pivot, rollup, top N per group, running total, sessions |
| `06_chewy_interview_analysis.py` | Analysis & roadmap | — | Recurring themes, Chewy priorities, common mistakes, 2-week prep roadmap |

**Total new questions in 02–05:** 69 (use 35–50 for focused prep; see 2-week roadmap in `06_chewy_interview_analysis.py`).

## Per-question format (in Python modules)

Each question dict includes:

- `id`, `title`, `description`
- `core_concepts`, `why_chewy`, `interviewer_evaluates`, `common_mistakes`
- `dataset_required` — key into the same module’s `DATASETS` dict (description + sample)

## How to use

- **Practice:** Pick a category; call `get_all_questions()` and `get_dataset_spec(name)` from the corresponding module.
- **Analysis:** Run `python3 06_chewy_interview_analysis.py` or call `print_summary()` for themes, priorities, mistakes, and roadmap.
- **Registry:** `get_all_questions_by_category()` in `06_chewy_interview_analysis.py` returns all questions by category (loads 02–05 via importlib).

## Datasets

- In-memory samples are in each module’s `DATASETS` (e.g. lists, dicts, strings).
- For real-world practice, align with `../DATA_DICTIONARY.md` (users, products, orders, events) and use `../*.csv` when applicable.
