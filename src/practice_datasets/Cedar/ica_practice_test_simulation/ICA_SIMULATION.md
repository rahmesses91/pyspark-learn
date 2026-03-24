# ICA progressive-filesystem simulation (agent reference)

This document records how we **simulate** CodeSignal-style **Industry Coding Assessment (ICA)** tasks in this repo so humans and **agents** can rehearse without embedding **solutions** in locked-looking files.

---

## What the real platform does (behavior to mirror)

1. **Levels unlock in order** — You only work on **Level 1** until **Submit** passes the **full** hidden suite for that level. Level 2+ material (prompts, tests, sometimes extra API surface) appears **after** that.
2. **Locked vs editable** — The assessment usually provides:
   - **Locked:** interface / abstract API (`integer_container.py`), **graded** `tests/level_k_tests.py`, and sometimes `main.sh` / `run_single_test.sh`.
   - **Editable:** implementation file(s) (`*_impl.py` or similar), and **`tests/sandbox_tests.py`** (custom experiments; often **not** scored).
3. **Filesystem layout** — Flat **project root** next to `tests/` (not `src/app/…`), so imports look like `from banking_system_impl import …` with `sys.path` pointing at the parent of `tests/`.
4. **Runner** — `python3 -m unittest discover -s tests -p '*.py'` (see each task’s `main.sh`).
5. **Timeouts** — Tests may use `@timeout` from **`timeout_decorator`** (available on the platform; locally we ship a **no-op** `timeout_decorator.py` so tests run offline).
6. **Scoring** — Sandbox tests run with graded tests but **do not** affect the score (unless the project fails to import).

---

## Policy for **this repo** (important for agents)

| Rule | Detail |
|------|--------|
| **No solutions in impl stubs** | `*_impl.py` files should **`raise NotImplementedError`** (or empty bodies) until the candidate implements them. Do **not** paste full solutions into impl files when “simulating” the exam. |
| **Level 1 only until green** | For each practice task, maintain **only Level 1** interface + **Level 1 graded tests** + sandbox. **Do not** add Level 2 interfaces, impls, or `level_2_tests.py` until the **candidate has finished Level 1** and **all Level 1 tests pass** (or they explicitly ask to unlock the next level). |
| **Locked files** | Treat `*_contract`/ABC files (`banking_system.py`, `payment_parser.py`, …) and **`tests/level_1_tests.py`** as **read-only** for the candidate; agents should not rewrite them to “help” unless the user asks to fix a bug in the simulation harness. |
| **Thin scaffolding** | Small helpers (e.g. `run_queries` that only loops `execute`) are optional; avoid putting **domain logic** there. |

---

## Folder map (practice tasks)

| Directory | Task | Level 1 (current) | Spec / notes |
|-----------|------|-------------------|--------------|
| `Cedar/banking_system/` | Banking ICA-style | `banking_system.py` (ABC), `banking_system_impl.py` (stub), `tests/level_1_tests.py`, `question.txt` | Implement `execute` / state per `question.txt`. **No `level_2_tests.py` until Level 1 passes.** |
| `Cedar/payments/` | Cedar-flavored payments | `payment_parser.py` (ABC), `payment_parser_impl.py` (stub), `tests/level_1_tests.py` | Parsing only; see `Cedar/README.md` Level 1. **Level 2 (balances) is not generated until Level 1 passes.** |
| `Cedar/ica_practice_test/` | Legacy / alternate copy | Optional | Same layout as below. |
| `Cedar/ica_practice_test_simulation/` | **Reference** CodeSignal **integer container** practice | `integer_container.py` (interface + default stubs), `integer_container_impl.py` (your code), `tests/level_1_tests.py`, **`tests/level_2_tests.py`** (median), `sandbox_tests.py` | Unlike `banking_system` / `payments`, this folder **bundles both level test files** to mirror the **official practice task** (both levels visible). **Impl stays a stub** until you implement. Use **`Optional[...]`** in interfaces for Python 3.9+ (`int \| None` is unsafe on 3.9). |

---

## When an agent should add Level 2

**Only after:**

1. The user confirms Level 1 is complete **or**  
2. `python3 -m unittest discover -s tests -p '*.py'` passes for **Level 1 only** in that directory,

then generate **Level 2** assets as needed, e.g.:

- `payment_balance_calculator.py` (contract) + `payment_balance_calculator_impl.py` (stub)  
- `tests/level_2_tests.py`  
- For banking: `tests/level_2_tests.py` for `TOP_ACTIVITY` (and extend `banking_system.py` / impl only if the prompt requires new methods)

Still: **impl stubs without solutions** unless the user asks for a reference implementation.

---

## Commands (from each task root)

```bash
python3 -m unittest discover -s tests -p '*.py' -v
bash run_single_test.sh "substring_of_test_name"
bash main.sh
```

Ensure the working directory is the task root (same folder as `tests/`).

---

## Related docs

- `Cedar/README.md` — mock ICA blueprint and problem themes (not affiliated with Cedar or CodeSignal).  
- CodeSignal ICA rules: [support.codesignal.com ICA article](https://support.codesignal.com/hc/en-us/articles/19116922232983-What-are-the-Industry-Coding-Assessment-ICA-rules)  
- Practice framework inspiration: [PaulLockett/CodeSignal_Practice_Industry_Coding_Framework](https://github.com/PaulLockett/CodeSignal_Practice_Industry_Coding_Framework)

---

## Changelog (conversation summary)

- Progressive filesystem tasks use **flat root + `tests/`**, **interface + impl**, **unittest** + optional **sandbox**.  
- **Level gating** is simulated by **omitting** Level 2 files until Level 1 is done.  
- **No solutions** in impl files for an authentic practice experience; agents add Level 2 **only on request** after Level 1 passes.
