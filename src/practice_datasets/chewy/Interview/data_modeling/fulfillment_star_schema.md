# Star schema — Supply chain & order fulfillment

## Purpose

Post–order capture: **inventory**, **FC operations**, **shipping**, **delivery**, **returns** — cycle time, **OTD**, **in-stock**, FC productivity, return rate.

## Grain

| Fact | Grain | One row per |
|------|--------|-------------|
| `fct_fulfillment_orders` | Fulfillment header | **Order (or shipment group)** as processed by supply chain |
| `fct_fulfillment_line_items` | Fulfillment line | **Order line** fulfillment attempt: pick, pack, ship, short-ship |

Alternative naming: `fct_shipments` + `fct_shipment_lines` if the business keys shipments first—below uses **order-centric** fulfillment to align with the orders star schema.

## Fact tables

### `fct_fulfillment_orders`

| Column | Type | Role |
|--------|------|------|
| `fulfillment_order_fact_sk` | surrogate PK | |
| `order_id` | natural key | Links to sales `fct_orders` (customer via conformed order fact) |
| `shipment_id` | natural key | Nullable if multi-shipment; else same as order |
| `origin_fc_sk` | FK | → `dim_fulfillment_center` (ship-from) |
| `ship_date_sk` | FK | → `dim_date` |
| `promised_delivery_date_sk` | FK | → `dim_date` |
| `carrier_sk` | FK | → `dim_carrier` |
| `fulfillment_status_sk` | FK | → `dim_fulfillment_status` |
| `package_count` | int | |
| `shipped_weight_kg` | decimal | Optional |
| `fulfillment_cycle_time_hours` | decimal | order confirmed → ship |
| `delivery_cycle_time_hours` | decimal | ship → delivered (when known) |
| `etl_loaded_at` | timestamp | |

### `fct_fulfillment_line_items`

| Column | Type | Role |
|--------|------|------|
| `fulfillment_line_fact_sk` | surrogate PK | |
| `fulfillment_line_id` | natural key | Pick/pack line id |
| `order_id` | degenerate | |
| `order_line_id` | degenerate | Aligns with `fct_order_line_items` |
| `product_sk` | FK | → `dim_product` |
| `origin_fc_sk` | FK | → `dim_fulfillment_center` |
| `ship_date_sk` | FK | → `dim_date` |
| `quantity_picked` | int | |
| `quantity_shipped` | int | |
| `quantity_backordered` | int | |
| `line_fulfillment_status_sk` | FK | → `dim_fulfillment_status` |
| `etl_loaded_at` | timestamp | |

**Returns:** Either **add measures** (`return_qty`, `return_amt`) via bridge to a `fct_returns` or keep a separate **returns fact** for interview depth; at star-schema level, a third fact `fct_return_line_items` often shares `dim_product`, `dim_date`, `dim_fulfillment_center`.

## Dimension tables (5)

1. **`dim_fulfillment_center`** — FC id, region, timezone, capacity band.  
2. **`dim_carrier`** — UPS, FedEx, USPS, LTL; service level.  
3. **`dim_product`** — SKU (same conformed dim as orders).  
4. **`dim_date`** — ship date, promised delivery, etc.  
5. **`dim_fulfillment_status`** — picked, packed, shipped, delivered, cancelled, returned, partial.

**Customer segmentation:** use `order_id` → `fct_orders.customer_sk` / `dim_customer` so this star stays at **five physical dimensions** on the fulfillment facts.

### `dim_fulfillment_center`

| Column | Notes |
|--------|--------|
| `fc_sk` | Surrogate PK |
| `fc_nk` | Warehouse code |
| `region`, `country` | |

### `dim_carrier`

| Column | Notes |
|--------|--------|
| `carrier_sk` | PK |
| `carrier_code`, `service_level` | |

### `dim_fulfillment_status`

| Column | Notes |
|--------|--------|
| `fulfillment_status_sk` | PK |
| `status_code` | granular |
| `status_bucket` | in_transit / completed / exception |

## Visual — ER diagram (ASCII boxes)

**Customer** is not duplicated here: join **`ORDERS.customer_id`** (or `order_id` → `ORDERS`) for segmentation. Below matches **shipment header + line** patterns used in WMS/TMS integrations.

```
+-----------------------------+         1        *    +----------------------------------+
|   FULFILLMENT_SHIPMENTS     |-------------------------|   FULFILLMENT_LINE_ITEMS         |
+-----------------------------+                         +----------------------------------+
| PK shipment_id              |                         | PK fulfillment_line_id           |
| FK order_id                 |                         | FK shipment_id                   |
| FK origin_fc_id             |                         | FK order_line_id                 |
| FK carrier_id               |                         | FK sku_id                        |
| ship_date                   |                         | qty_picked                       |
| promised_delivery_date      |                         | qty_shipped                      |
| FK fulfillment_status_id    |                         | qty_backordered                  |
| package_count               |                         | FK line_fulfillment_status_id    |
| fulfillment_cycle_time_hrs  |                         +----------------------------------+
| delivery_cycle_time_hrs     |
+-----------------------------+

        FK targets (dimensions)
+----------------------+   +------------------+   +------------------+
| FULFILLMENT_CENTERS  |   |    CARRIERS      |   |     PRODUCTS     |
+----------------------+   +------------------+   +------------------+
| PK fc_id             |   | PK carrier_id    |   | PK sku_id        |
| region, timezone     |   | service_level    |   | (conformed)      |
+----------------------+   +------------------+   +------------------+

+----------------------+   +---------------------------+
|       DATES          |   |  FULFILLMENT_STATUSES     |
+----------------------+   +---------------------------+
| PK date_id           |   | PK fulfillment_status_id  |
+----------------------+   +---------------------------+
```

**Join path:** `FULFILLMENT_SHIPMENTS` = **when/where/how** (date, FC, carrier) + **shipment-level** status and cycle times. `FULFILLMENT_LINE_ITEMS` = **SKU** and **quantities** at pick/ship grain; **customer** and **order totals** come from **`order_id` → ORDERS**.

## Example metrics

- **On-time delivery (OTD)** — compare actual delivery date to `promised_delivery_date` (needs delivery event or carrier scan fact).  
- **Fulfillment cycle time** — avg `fulfillment_cycle_time_hours` by FC.  
- **Fill rate** — `sum(quantity_shipped) / sum(quantity_ordered)` (join to order lines for ordered qty).  
- **Return rate** — via returns fact or order flags, by SKU/FC/period.

## Conformed dimensions (cross-model)

Reuse **`dim_customer`**, **`dim_product`**, **`dim_date`** with the **orders** and **autoships** models so Gold marts can join **order → fulfillment → subscription** without conflicting grain definitions.
