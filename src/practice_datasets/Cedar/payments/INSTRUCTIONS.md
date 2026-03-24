# Payments practice — simple guide

This folder is a practice version of a coding test (ICA style). You work in steps called levels. Each level adds a new job. The story is fake healthcare billing data (no real patient data).

This repo is not affiliated with Cedar or CodeSignal. For the big-picture idea of the Cedar practice pack, read the file `README.md` one folder up (`../README.md`).

---

What this practice is about (three levels)

Level 1 — Read one CSV text line and turn it into a Python dictionary with the right types. Bad rows should raise an error.

Level 2 — Take many of those dictionaries plus a list of adjustments. For each encounter id, add up charges and adjustments and produce one row per encounter, sorted by encounter id.

Level 3 — Given a patient and the balance rows from level 2, apply incoming payments in order (waterfall) and remember what is left on each encounter between calls.

The exact rules are whatever the unit tests expect. When in doubt, make the tests pass.

---

Expected input and output (formats the grader checks)

This section matches `tests/level_1_tests.py`, `tests/level_2_tests.py`, and `tests/level_3_tests.py`. Types matter: use Python `str`, `int`, `list`, `dict`, and `None` as shown.

Level 1 — `parse_line()`

Input: one string `line`. Split on commas, trim each field.

Valid rows have exactly 4 or 5 fields after trim:

- Field 0: `patient_id` (string)
- Field 1: `encounter_id` (string)
- Field 2: `service_date` (string, calendar date `YYYY-MM-DD`)
- Field 3: `charge_cents` (string of an integer, no decimals)
- Field 4 (optional): `payer_id` (non-empty string if present)

If there are 4 fields, `payer_id` in the result is `None`.

On success, return one dictionary with exactly these keys:

    {
      "patient_id": str,
      "encounter_id": str,
      "service_date": str,
      "charge_cents": int,
      "payer_id": str or None
    }

Example (same idea as the sample test): for a line with five comma-separated fields where ids are `"1234567890"`, date `2024-01-01`, charge `100000`, payer `1234567890`, the expected output is:

    {
      "patient_id": "1234567890",
      "encounter_id": "1234567890",
      "service_date": "2024-01-01",
      "charge_cents": 100000,
      "payer_id": "1234567890"
    }

On bad length, bad date, or non-integer cents: raise `ValueError` (any message is usually fine unless a test pins it).

---

Level 2 — `compute_encounter_balances(normalized_lines, adjustments)`

`PaymentBalanceCalculatorImpl` is constructed with no arguments. The method signature is:

    compute_encounter_balances(
        normalized_lines: list[dict],
        adjustments: list[dict],
    ) -> list[dict]

Each item in `normalized_lines` looks like the Level 1 output (same keys).

Each adjustment dict uses at least:

    {
      "encounter_id": str,
      "amount_cents": int,
      "reason": str
    }

(`reason` is carried through for realism; tests sum `amount_cents` by `encounter_id`.)

Return a list (possibly empty) of dictionaries, one per distinct `encounter_id` that appears in `normalized_lines`. Sort that list by `encounter_id` in ascending string order (for example `"e10"` before `"e2"` if your sort is plain string sort — follow the tests).

Each output row must have exactly:

    {
      "encounter_id": str,
      "charges_cents": int,      # sum of charge_cents for that encounter
      "adjustments_cents": int,  # sum of amount_cents for adjustments targeting that encounter
      "balance_cents": int       # charges_cents + adjustments_cents
    }

Ignore adjustments whose `encounter_id` never appears on any normalized line.

Example shape for one encounter with charges 5000 and no adjustments:

    [
      {
        "encounter_id": "e10",
        "charges_cents": 5000,
        "adjustments_cents": 0,
        "balance_cents": 5000
      }
    ]

---

Level 3 — `PaymentAllocatorImpl(patient_id, encounter_balances)` and `allocate(payment_cents)`

Constructor arguments:

- `patient_id`: `str` (stored for context; tests still call it)
- `encounter_balances`: `list[dict]` — each dict is a Level 2 style row. Allocation uses at least `encounter_id` (str) and `balance_cents` (int). Rows may also include `charges_cents` and `adjustments_cents`; treat `balance_cents` as the amount still owed before allocation. Encounters with `balance_cents <= 0` are skipped when applying payment.

Method:

    allocate(payment_cents: int) -> dict

- If `payment_cents < 0`, raise `ValueError`.
- Otherwise return exactly this structure:

    {
      "allocations": [
        {"encounter_id": str, "applied_cents": int},
        ...
      ],
      "unapplied_cents": int
    }

Rules reflected in tests:

- Walk encounters in **lexicographic** (plain string) order of `encounter_id`: same idea as `sorted(encounter_ids)` in Python. This is **not** “natural” or numeric order (e.g. `e2` is **not** before `e10` here).
- For ids `"e10"` and `"e2"`, string order is **`e10` first, then `e2`**, because at the second character `'1' < '2'`. So a 1500 payment hits `e10` (balance 1000) first, then puts the remaining 500 on `e2` (balance 2000). Expected result:

    {
      "allocations": [
        {"encounter_id": "e10", "applied_cents": 1000},
        {"encounter_id": "e2", "applied_cents": 500}
      ],
      "unapplied_cents": 0
    }

- Apply payment to each encounter’s remaining balance until the payment is used up or balances are satisfied.
- `unapplied_cents` is whatever part of the payment could not be applied (for example overpayment).
- The same allocator instance keeps remaining balances in memory for later `allocate` calls.

Edge cases covered by tests: empty encounter list, zero payment, negative payment (error), encounters with zero balance skipped.

---

What to read first

Read `../README.md` for the full story in plain language.

Then use this file to see which files are which and how to run tests.

---

Which files do what

Files you should not change while practicing (pretend the website locks them):

- `payment_parser.py` — defines the parser interface.
- `payment_balance_calculator.py` — defines the balance calculator interface.
- `payment_allocator.py` — defines the payment allocator interface.
- `tests/level_1_tests.py`, `tests/level_2_tests.py`, `tests/level_3_tests.py` — the official tests for each level.

Files you edit (your solution goes here):

- `payment_parser_impl.py`
- `payment_balance_calculator_impl.py`
- `payment_allocator_impl.py`

Other:

- `tests/sandbox_tests.py` — for your own experiments. It does not decide your score on a real platform.
- `timeout_decorator.py` — small helper so tests run on your laptop the same way as on the test site.

For rules about how we simulate the real test (levels, no cheating, etc.), see `../ica_practice_test_simulation/ICA_SIMULATION.md`.

---

Short reminders (details are in “Expected input and output” above)

- Level 1: one CSV string in, one dict out; `ValueError` on bad data.
- Level 2: `compute_encounter_balances(lines, adjustments)` → sorted list of balance rows; ignore orphan adjustments.
- Level 3: construct with `patient_id` and Level 2 rows; `allocate` returns `allocations` + `unapplied_cents`; stateful across calls.

---

How to run the tests

Open a terminal in this folder (the same folder that contains `tests`).

Run everything:

    python3 -m unittest discover -s tests -p '*.py' -v

Or:

    bash main.sh

Run tests whose name contains a word:

    bash run_single_test.sh "parse_line"

You need Python 3.9 or newer. No extra packages are required beyond the standard library.

---

Useful links

CodeSignal ICA candidate rules: https://support.codesignal.com/hc/en-us/articles/19116922232983-What-are-the-Industry-Coding-Assessment-ICA-rules

Simulation notes in this repo: `../ica_practice_test_simulation/ICA_SIMULATION.md`
