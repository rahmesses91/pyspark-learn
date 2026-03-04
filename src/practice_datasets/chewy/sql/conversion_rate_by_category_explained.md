# Conversion Rate by Category — Query Explanation

This query computes **view-to-purchase conversion rate by product category**: for users who viewed products in a category, what share purchased something in that same category within 7 days of the view.

---

## High-level flow

1. **views** — All view events with product category and view time.
2. **purchases** — All orders with product category and order time.
3. **matched** — For each (category, user) who viewed, the earliest purchase in that category within 7 days of the view (or `NULL` if no such purchase).
4. **final** — Per category: count of distinct viewers and count of distinct converters.
5. **Final SELECT** — Conversion rate (converters / viewers) by category, ordered by rate descending.

---

## CTE-by-CTE breakdown

### 1. `views`

```sql
views AS (
    SELECT
        e.user_id,
        e.product_id,
        p.category,
        e.event_time AS view_time
    FROM events e
    JOIN products p ON e.product_id = p.product_id
    WHERE e.event_type = 'view'
)
```

- **Purpose:** One row per **view** event.
- **Source:** `events` joined to `products` to get `category`.
- **Filter:** Only `event_type = 'view'`.
- **Output:** `user_id`, `product_id`, `category`, `view_time`.

---

### 2. `purchases`

```sql
purchases AS (
    SELECT
        o.user_id,
        o.product_id,
        p.category,
        o.order_time
    FROM orders o
    JOIN products p ON o.product_id = p.product_id
)
```

- **Purpose:** One row per **order**, with the category of the ordered product.
- **Source:** `orders` joined to `products`.
- **Output:** `user_id`, `product_id`, `category`, `order_time`.

---

### 3. `matched`

```sql
matched AS (
    SELECT
        v.category,
        v.user_id,
        MIN(p.order_time) AS first_purchase_time
    FROM views v
    LEFT JOIN purchases p
        ON v.user_id = p.user_id
        AND v.category = p.category
        AND p.order_time BETWEEN v.view_time
                             AND v.view_time + INTERVAL '7' DAY
    GROUP BY v.category, v.user_id
)
```

- **Purpose:** For each (category, user) that appears in **views**, find the **earliest** order in that same category within **7 days after** the view (if any).
- **Join:** `views` **LEFT JOIN** `purchases` so every view (per user and category) is kept; non-converters get `first_purchase_time = NULL`.
- **Conditions:**
  - Same `user_id`.
  - Same `category` (view and purchase in same category).
  - `order_time` between `view_time` and `view_time + 7 days`.
- **Aggregation:** `GROUP BY v.category, v.user_id` with `MIN(p.order_time)` → one row per (category, user) with their first qualifying purchase time or `NULL`.

**Note:** If a user has multiple views in a category, they still appear once per (category, user) in `matched`; the 7-day window is applied per view before grouping, so the logic is “earliest purchase in that category within 7 days of any of their views.”

---

### 4. `final`

```sql
final AS (
    SELECT
        category,
        COUNT(DISTINCT user_id) AS total_viewers,
        COUNT(DISTINCT CASE WHEN first_purchase_time IS NOT NULL THEN user_id END) AS total_converters
    FROM matched
    GROUP BY category
)
```

- **Purpose:** Per **category**, count:
  - **total_viewers** — distinct users who viewed in that category.
  - **total_converters** — distinct users who have a non-null `first_purchase_time` (i.e. bought in that category within 7 days of a view).
- **Source:** `matched` (one row per category per user).

---

### 5. Final `SELECT`

```sql
SELECT
    category,
    total_viewers,
    total_converters,
    ROUND(total_converters::decimal / total_viewers, 4) AS conversion_rate
FROM final
ORDER BY conversion_rate DESC;
```

- **Purpose:** Add **conversion_rate** = `total_converters / total_viewers` per category, rounded to 4 decimals.
- **Order:** Categories with highest conversion rate first.

---

## Summary

| Concept | Meaning |
|--------|--------|
| **Viewer** | User who had at least one view in the category (from `events`). |
| **Converter** | Same user who had at least one order in that category within 7 days of one of their views. |
| **Conversion rate** | `total_converters / total_viewers` per category. |

The query answers: **“By category, what fraction of users who viewed products went on to buy in that category within 7 days?”**
