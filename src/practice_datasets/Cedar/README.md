# Cedar — mock Industry Coding Assessment (Python)

Practice pack styled after CodeSignal’s **Industry Coding Assessment (ICA)** format. Use it to rehearse timing, the multi-level progression, and refactoring as requirements compound.

**Official ICA candidate rules:** [CodeSignal — ICA rules](https://support.codesignal.com/hc/en-us/articles/19116922232983-What-are-the-Industry-Coding-Assessment-ICA-rules)  
**Framework / structure inspiration:** [PaulLockett/CodeSignal_Practice_Industry_Coding_Framework](https://github.com/PaulLockett/CodeSignal_Practice_Industry_Coding_Framework)

This folder is **not** affiliated with Cedar or CodeSignal. Problems are original and use generic healthcare–payments *themes* (scheduling, balances, remittances) without real PHI.

---

## ICA filesystem practice tasks (in this repo)

Each task uses a **flat root** next to `tests/`, a **locked** interface file, an **editable** `*_impl.py`, `unittest`, and `main.sh` / `run_single_test.sh`. Per-task **questions, layout, and commands** are in each folder’s **`INSTRUCTIONS.md`** (or **`INSTRUCTIONS.txt`** for `banking_system`):

| Folder | Topic |
|--------|--------|
| [`banking_system/`](banking_system/INSTRUCTIONS.txt) | Stateful banking queries (`question.txt`), Level 1 first. |
| [`payments/`](payments/INSTRUCTIONS.md) | CSV line parsing (Level 1); balances later. |
| [`ica_practice_test_simulation/`](ica_practice_test_simulation/INSTRUCTIONS.md) | Reference **integer container** task (Levels 1–2 tests bundled). |

Shared **simulation rules** for agents and humans: [`ica_practice_test_simulation/ICA_SIMULATION.md`](ica_practice_test_simulation/ICA_SIMULATION.md).

---

## Assessment blueprint (90-minute cap)

| Level | Time budget | Focus | What good looks like |
|-------|-------------|--------|----------------------|
| 1 | 10–15 min | Parsing & validation | Clean edge cases (`None`, empty, bad types), small pure functions |
| 2 | 20–30 min | Data structures | `dict`/`set` grouping, stable ordering, dedup keys |
| 3 | 30–45 min | Stateful simulation | Rules that depend on prior state; clear API on a small “service” class |
| 4 | 30–45 min | Integration | Reuse Level 1–3 utilities; add one cross-cutting concern (e.g. idempotency, audit trail) |

**Scoring philosophy (ICA-style):** partial credit for depth through levels matters more than polishing Level 4. Prefer a working Level 2–3 over a perfect Level 1.

---

## Suggested problem set (Cedar-flavored, Python 3.10+)

All inputs are **synthetic**. Names and IDs are fake.

### Level 1 — **Normalize a patient responsibility line**

**Story:** Ingest a raw CSV row (string) representing one line on a statement. Return a structured `dict` with typed fields.

**Requirements:**

- Parse: `patient_id`, `encounter_id`, `service_date` (ISO `YYYY-MM-DD`), `charge_cents` (int), `payer_id` (optional str).
- Reject malformed dates and non-integer cents; raise `ValueError` with a short message (or return `None` / a result type—pick one convention and document it in tests).
- Trim whitespace on string fields.

**Stretch for realism:** accept a single header row + data row and map by column name.

---

### Level 2 — **Apply adjustments and compute balance**

**Story:** Given a list of normalized lines (Level 1 output) plus a list of adjustment records `{encounter_id, amount_cents, reason}`, compute **per-encounter** `charges_cents`, `adjustments_cents`, `balance_cents`.

**Requirements:**

- Group by `encounter_id`.
- Sum charges and adjustments; `balance = charges + adjustments` (adjustments may be negative).
- Return a list of dicts sorted by `encounter_id`.
- Ignore adjustments whose unknown `encounter_id` does not match any charge line (or flag them—define behavior in the prompt; tests must pin it).

---

### Level 3 — **Payment allocation simulation**

**Story:** Implement a class or module API `allocate_payment(patient_id, payment_cents, encounter_balances)` that applies payment to encounters in **ascending encounter_id** until funds are exhausted (waterfall). Each call returns an allocation ledger: list of `{encounter_id, applied_cents}`.

**Requirements:**

- Subsequent calls remember remaining balances **in memory** for that session (simple module-level or instance dict is fine).
- If `payment_cents` exceeds total outstanding for the patient, apply only up to outstanding; return `unapplied_cents`.
- Must be deterministic given sorted encounter order.

---

### Level 4 — **Idempotent payment ingestion**

**Story:** Payments arrive with an `event_id`. The same `event_id` must not apply twice.

**Requirements:**

- Extend Level 3 with `submit_payment(event_id, patient_id, payment_cents, ...)`.
- Second submission with the same `event_id` returns the **same** allocation result as the first (no double application).
- Expose a read-only summary: total applied per encounter and global unapplied cash.

---

## Repo layout (optional next step)

To match the GitHub practice framework, you can add:

```
Cedar/
  README.md                 # this file
  python/
    simulation.py           # candidate edits
    test_simulation.py      # unittest per level
  data/
    sample_statement_rows.csv   # optional fixtures
```

Run style: `python3 -m unittest python.test_simulation` (after you add files).

---

## Fairness & constraints

- Align behavior and **pinned tests** with whatever the prompt promises (silent drops vs. errors kill many candidates).
- Keep I/O minimal: pure Python + stdlib unless you explicitly allow `pandas` (real ICA often does not).
- Use **Python 3.10.6** if you want parity with common CodeSignal runtimes (see the practice framework README).

---

## References

- [Cedar open roles](https://www.cedar.com/careers/open-roles?gh_jid=7545388) — use the JD for *tone* (patient financial experience, reliability, clarity), not for copying proprietary assessments.
