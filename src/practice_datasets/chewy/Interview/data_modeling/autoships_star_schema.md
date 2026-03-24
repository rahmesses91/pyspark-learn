# Star schema — Autoships (subscriptions)

## Purpose

Recurring schedules: **subscription counts**, **cadence**, skips/pauses, **autoship churn**, next ship date, tie-out to **orders** for shipped revenue.

## Grain

| Fact | Grain | One row per |
|------|--------|-------------|
| `fct_subscriptions` | Subscription header | **Active or historical subscription** (customer + pet + program) |
| `fct_autoship_line_items` | Subscription line | **SKU (or item) on a subscription** with its schedule |

## Fact tables

### `fct_subscriptions`

| Column | Type | Role |
|--------|------|------|
| `subscription_fact_sk` | surrogate PK | |
| `subscription_id` | natural key | Business subscription id |
| `customer_sk` | FK | → `dim_customer` |
| `pet_sk` | FK | → `dim_pet` (nullable if not pet-specific) |
| `subscription_status_sk` | FK | → `dim_subscription_status` |
| `start_date_sk` | FK | → `dim_date` |
| `cancel_date_sk` | FK | → `dim_date` (nullable) |
| `next_ship_date_sk` | FK | → `dim_date` (nullable; snapshot or SCD-aware) |
| `cadence_days` | int | e.g. 30, 45, 60 |
| `etl_loaded_at` | timestamp | |

### `fct_autoship_line_items`

| Column | Type | Role |
|--------|------|------|
| `autoship_line_fact_sk` | surrogate PK | |
| `subscription_line_id` | natural key | Unique subscription-SKU line |
| `subscription_id` | FK / degenerate | → ties to `fct_subscriptions` |
| `customer_sk` | FK | Optional denorm |
| `product_sk` | FK | → `dim_product` |
| `effective_date_sk` | FK | → `dim_date` (line effective / as-of) |
| `quantity_per_ship` | decimal | |
| `line_status_sk` | FK | → `dim_subscription_status` or mini `dim_line_state` |
| `last_modification_type` | varchar | skip, pause, resume, qty_change (or FK to dim) |
| `etl_loaded_at` | timestamp | |

**Interview note:** Shipped autoship **orders** link via `order_id` on shipment/order facts; here we model **subscription intent**, not every shipment.

## Dimension tables (5)

1. **`dim_customer`** — same role as orders model; `customer_sk`.  
2. **`dim_product`** — SKU on subscription line.  
3. **`dim_pet`** — pet id, species, breed rollup (pet retail differentiator).  
4. **`dim_date`** — role-playing: start, cancel, next_ship, effective.  
5. **`dim_subscription_status`** — active, paused, cancelled, expired, pending_activation.

### `dim_pet` (example)

| Column | Notes |
|--------|--------|
| `pet_sk` | Surrogate PK |
| `pet_nk` | Natural id |
| `species`, `breed`, `age_band` | Non-PHI attributes |
| `customer_sk` | Owner link (or only via fact) |

### `dim_subscription_status`

| Column | Notes |
|--------|--------|
| `subscription_status_sk` | PK |
| `status_code` | active, paused, cancelled, … |
| `is_recurring_revenue` | boolean for reporting |

## Visual — ER diagram (ASCII boxes)

This is the **operational / 3NF** view interviewers often sketch first. It maps cleanly to the **star** names above: `AUTOSHIP_PLANS` ≈ `fct_subscriptions` / subscription header; `AUTOSHIP_ITEMS` ≈ line grain; **executions** and **snapshots** add **run history** and **point-in-time pricing** for audit and finance.

```
+---------------------+            1        *    +------------------------+
|   AUTOSHIP_PLANS    |--------------------------|    AUTOSHIP_ITEMS      |
+---------------------+                           +------------------------+
| PK autoship_id      |                           | PK autoship_item_id    |
| FK customer_id      |                           | FK autoship_id         |
| FK pet_id (nullable)|                           | FK sku_id              |
| status              |                           | quantity               |
| frequency_type      |                           | is_active              |
| frequency_value     |                           | created_at             |
| next_run_date       |                           | ended_at               |
| created_at          |                           +------------------------+
| canceled_at         |
+---------------------+

             1        *
+---------------------+            +------------------------------+
|   AUTOSHIP_PLANS    |------------|    AUTOSHIP_EXECUTIONS       |
+---------------------+            +------------------------------+
| PK autoship_id      |            | PK autoship_execution_id     |
| ...                 |            | FK autoship_id               |
+---------------------+            | scheduled_run_date           |
                                   | actual_run_date              |
                                   | status                       |
                                   | order_id (nullable)          |
                                   | reason_code                  |
                                   +------------------------------+

             1        *
+------------------------------+       +-------------------------------------+
|    AUTOSHIP_EXECUTIONS       |-------|    AUTOSHIP_ITEM_SNAPSHOTS          |
+------------------------------+       +-------------------------------------+
| PK autoship_execution_id     |       | PK autoship_item_snapshot_id        |
| ...                          |       | FK autoship_execution_id            |
+------------------------------+       | sku_id                              |
                                       | quantity                            |
                                       | price_at_execution                  |
                                       | discount_at_execution               |
                                       +-------------------------------------+
```

**Star-schema mapping (same story, different shape):** `AUTOSHIP_PLANS` + `AUTOSHIP_ITEMS` → conformed **dim_customer**, **dim_pet**, **dim_product** (via `sku_id`), **dim_date**, **dim_subscription_status** on snapshots of the plan; **AUTOSHIP_EXECUTIONS** bridges to **orders** (`order_id`) and **fulfillment** for “did the run ship on time?”

**Join path (say aloud):** Plans hold **intent** and cadence; **items** hold **which SKUs**; **executions** are **each scheduled run**; **item snapshots** freeze **qty/price** for that run (revenue recognition, promo disputes).

## Example metrics

- **Active subscriptions** — count on `fct_subscriptions` where status = active (as-of snapshot or type 2).  
- **Autoship churn** — cancels in period / subs at period start.  
- **SKU mix on autoship** — from `fct_autoship_line_items` joined to `dim_product`.  
- **On-time next ship** — compare `next_ship_date` to actual order ship (bridge to orders/fulfillment facts).
