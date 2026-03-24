# Star schema — Orders

## Purpose

Order capture through payment and lifecycle: conversion, **AOV**, item mix, **net sales**, refunds, fulfillment handoff.

## Grain

| Fact | Grain | One row per |
|------|--------|-------------|
| `fct_orders` | Order header | **Order** |
| `fct_order_line_items` | Order line | **Order line** (SKU line on an order) |

Line facts carry SKU-level revenue and qty; header fact carries order-level totals, fees, and status snapshot.

## Fact tables

### `fct_orders`

| Column | Type | Role |
|--------|------|------|
| `order_fact_sk` | surrogate PK | Fact row id |
| `order_id` | natural key | Business order id (degenerate) |
| `customer_sk` | FK | → `dim_customer` |
| `order_date_sk` | FK | → `dim_date` (order placed) |
| `ship_to_location_sk` | FK | → `dim_location` (default ship-to) |
| `order_status_sk` | FK | → `dim_order_status` |
| `currency_code` | varchar | FX handling if multi-currency |
| `order_subtotal_amt` | decimal | Pre-tax line sum |
| `order_tax_amt` | decimal | |
| `order_shipping_amt` | decimal | |
| `order_discount_amt` | decimal | Order-level promos |
| `order_total_amt` | decimal | Charged total |
| `payment_method_sk` | FK | → `dim_payment_method` (primary payment) |
| `etl_loaded_at` | timestamp | Lineage |

### `fct_order_line_items`

| Column | Type | Role |
|--------|------|------|
| `order_line_fact_sk` | surrogate PK | |
| `order_line_id` | natural key | Unique line id |
| `order_id` | FK / degenerate | Ties to `fct_orders.order_id` |
| `customer_sk` | FK | Denormalized for query convenience (or resolve via order) |
| `product_sk` | FK | → `dim_product` |
| `order_date_sk` | FK | Same as header for most analytics |
| `promotion_sk` | FK | → `dim_promotion` (nullable) |
| `quantity` | int | |
| `unit_list_price` | decimal | |
| `unit_selling_price` | decimal | After line discounts |
| `extended_selling_amt` | decimal | qty × unit_selling |
| `line_discount_amt` | decimal | |
| `line_tax_amt` | decimal | Optional if allocated |
| `etl_loaded_at` | timestamp | |

**Interview note:** For strict star purity, drop redundant `customer_sk` on lines and join through `fct_orders`; denormalize only if query patterns justify it.

## Dimension tables (5)

### `dim_customer`

| Column | Notes |
|--------|--------|
| `customer_sk` | Surrogate PK |
| `customer_nk` | Natural id from source |
| `email_hash` / token | PII policy |
| `customer_type`, `lifecycle_segment` | Type 2 if tracked |
| `valid_from`, `valid_to`, `is_current` | SCD2 optional |

### `dim_product`

| Column | Notes |
|--------|--------|
| `product_sk` | Surrogate PK |
| `sku_nk` | SKU natural key |
| `product_name`, `brand_sk` (or denorm brand) | |
| `category_id`, `species` (pet retail) | |
| `is_rx_eligible`, `is_autoship_eligible` | Flags |

### `dim_date`

Standard calendar: `date_sk` (YYYYMMDD int), `date_actual`, `fiscal_YYYYMM`, `is_weekend`, holidays, etc.

### `dim_order_status`

| Column | Notes |
|--------|--------|
| `order_status_sk` | PK |
| `status_code` | placed, paid, partially_shipped, completed, cancelled, … |
| `status_category` | open / closed / cancelled |

### `dim_payment_method`

| Column | Notes |
|--------|--------|
| `payment_method_sk` | PK |
| `payment_type` | card, paypal, gift_card, … |
| `card_brand` | nullable, aggregated category only if PCI-sensitive |

**Alternative 5th dim:** `dim_location` (ship-to: state, country, geo hierarchy) if you split status into degenerate columns on the fact—here **`dim_location`** is referenced from `fct_orders.ship_to_location_sk` as the fifth dimension alongside customer, product, date, order_status, payment_method.

**Dimension set used in facts above:** `dim_customer`, `dim_product`, `dim_date`, `dim_order_status`, `dim_payment_method`, **`dim_location`** — that is six; for exactly **five** dims on the whiteboard, merge **payment** into degenerate codes on `fct_orders` and keep: **customer, product, date, order_status, location**.

## Simplified 5-dimension set (whiteboard)

1. `dim_customer`  
2. `dim_product`  
3. `dim_date`  
4. `dim_order_status`  
5. `dim_location` (ship-to / geo)

Put **payment_type** as a degenerate or mini-dimension attribute on `fct_orders` if you need to stay at five physical dims.

## Visual — ER diagram (ASCII boxes)

**Header vs lines** in the same style as autoship plans/items. FK targets (`customer_id`, `sku_id`, `location_id`, …) are the **natural keys** that join to **dimension tables** in a star (surrogate `*_sk` in the warehouse).

```
+---------------------+            1        *    +------------------------+
|       ORDERS        |--------------------------|    ORDER_LINE_ITEMS    |
+---------------------+                           +------------------------+
| PK order_id         |                           | PK order_line_id       |
| FK customer_id      |                           | FK order_id            |
| FK order_date_id    |                           | FK sku_id              |
| FK ship_to_loc_id   |                           | FK promotion_id (null) |
| FK order_status_id  |                           | quantity               |
| currency_code       |                           | unit_list_price        |
| order_subtotal_amt  |                           | unit_selling_price     |
| order_tax_amt       |                           | extended_selling_amt   |
| order_shipping_amt  |                           | line_discount_amt      |
| order_discount_amt  |                           +------------------------+
| order_total_amt     |
| FK payment_method_id|
+---------------------+

        FK targets (dimensions — conformed across Gold marts)
+------------------+   +------------------+   +------------------+
|    CUSTOMERS     |   |     PRODUCTS     |   |     LOCATIONS    |
+------------------+   +------------------+   +------------------+
| PK customer_id   |   | PK sku_id        |   | PK location_id   |
| ...              |   | brand, category  |   | region, country  |
+------------------+   +------------------+   +------------------+

+------------------+   +------------------+   +------------------------+
|      DATES       |   |  ORDER_STATUSES  |   |   PAYMENT_METHODS      |
+------------------+   +------------------+   +------------------------+
| PK date_id       |   | PK status_id     |   | PK payment_method_id   |
| calendar attrs   |   | status_code      |   | payment_type           |
+------------------+   +------------------+   +------------------------+
```

**Join path (say aloud):** `ORDERS` = **one row per order** (totals, ship-to, status). `ORDER_LINE_ITEMS` = **SKU grain** for revenue and mix; `order_id` links 1:N. Dimensions are **shared** (same `CUSTOMERS` / `PRODUCTS` as autoship and fulfillment).

## Example metrics

- **GMV / net sales** — sum `extended_selling_amt` (lines) net of returns in a returns fact or adjustment table.  
- **AOV** — `sum(order_total_amt) / count(distinct order_id)`.  
- **Orders** — `count(*)` on `fct_orders`.  
- **Units** — `sum(quantity)` on lines.
