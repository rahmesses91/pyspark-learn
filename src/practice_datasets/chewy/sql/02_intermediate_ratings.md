# 02_intermediate.sql — Interview Ratings

Rated only the questions you answered. Criteria: **correctness**, **query optimization**, **output (column names/ordering)**.  
Scale: 0–5. Questions with no answer (e.g. Q9) are omitted.

| question_number | rating |
|-----------------|--------|
| 1               | 4      |
| 2               | 5      |
| 3               | 4      |
| 4               | 5      |
| 5               | 5      |
| 6               | 4      |
| 7               | 5      |
| 8               | 5      |
| 10              | 5      |

---

## Brief feedback (by question)

| Q | Score | Notes |
|---|--------|--------|
| **1** | 4 | Logic and output are correct. Spec asked “ordered by total_revenue **descending**”; your `ORDER BY total_revenue` is ascending. Add `DESC`. |
| **2** | 5 | Correct use of CTE to get revenue per order then AVG per user. Output and rounding are good. |
| **3** | 4 | `MIN(order_time::date)` is correct. Spec asked for a column named **first_order_date**; add `AS first_order_date` so the output matches. |
| **4** | 5 | Correct conditional aggregation. Single pass over `events`, clear column names. |
| **5** | 5 | Correct `DENSE_RANK()` and filter for top 3 per category. Output and ordering are good. |
| **6** | 4 | `COUNT(DISTINCT session_id)` is correct. Spec asked for **session_count**; add `AS session_count`. |
| **7** | 5 | Joins and columns (including unit price as `p.price`) match the spec. |
| **8** | 5 | `NOT EXISTS` correctly finds users with orders but no `purchase` event. Good choice of pattern. |
| **10** | 5 | `NOT EXISTS` correctly finds products with no orders. Output columns correct. |

**Overall:** Strong intermediate SQL: joins, CTEs, window functions, and NOT EXISTS used correctly. The main improvements are following spec exactly on **ORDER direction** (Q1) and **column aliases** (Q3, Q6).
