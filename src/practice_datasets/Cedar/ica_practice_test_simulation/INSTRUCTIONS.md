# Integer container — reference ICA practice (filesystem simulation)

This folder mirrors the **CodeSignal practice task** (“integer container”): a **flat project root**, `tests/` with **Level 1** and **Level 2** graded modules, **`sandbox_tests.py`**, and shell runners. Use it to learn the **progressive filesystem** layout before a real assessment.

---

## What to read first

1. **`ICA_SIMULATION.md`** — How we simulate locked vs editable files, level gating, and agent rules for this repo.
2. This file — Quick orientation and commands.

---

## Problem (summary)

- **Level 1:** `IntegerContainer` supports **`add`** and **`delete`** for integers (multiset semantics; duplicates allowed).
- **Level 2:** Add **`get_median`** — median of sorted values; for even length, return the **left** of the two middle values; empty container → `None`.

Full behavior is specified by the **graded test files** (`tests/level_1_tests.py`, `tests/level_2_tests.py`), not duplicated here.

---

## Layout

| Role | Files |
|------|--------|
| **Locked / read-only** (simulation) | `integer_container.py` — interface with default stub implementations. `tests/level_1_tests.py`, `tests/level_2_tests.py`. |
| **You edit** | `integer_container_impl.py` — `IntegerContainerImpl`. |
| **Sandbox** | `tests/sandbox_tests.py` — safe to change; not scored. |
| **Helpers** | `timeout_decorator.py` — no-op `@timeout` for local runs. |
| **Meta** | `test_agent_notes.py` — checks that `ICA_SIMULATION.md` exists. |

**Note:** Unlike `banking_system/` and `payments/`, this **reference** task includes **both** level test files up front (like the official practice task). **Do not** assume solutions live in `*_impl.py`; stubs use `NotImplementedError` until you implement.

**Typing:** The interface uses **`Optional[int]`** for medians so **Python 3.9** works reliably (`int | None` in annotations can break on 3.9).

---

## How to run tests

From **this directory**:

```bash
python3 -m unittest discover -s tests -p '*.py' -v
```

Or:

```bash
bash main.sh
bash run_single_test.sh "test_level_1_case_01"
```

Optional:

```bash
python3 -m unittest discover -s . -p 'test_*.py' -v   # includes test_agent_notes.py
```

---

## References

- [`ICA_SIMULATION.md`](ICA_SIMULATION.md) — Agent and human reference for this simulation.  
- Parent overview: [`../README.md`](../README.md)  
- [CodeSignal ICA rules](https://support.codesignal.com/hc/en-us/articles/19116922232983-What-are-the-Industry-Coding-Assessment-ICA-rules)
