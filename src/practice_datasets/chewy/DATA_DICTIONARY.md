# Chewy Practice Dataset — Data Dictionary

Practice schema for products, events, orders, and users (e.g. e‑commerce / Chewy-style interviews).

---

## Entity-Relationship Diagram

Pictorial view (ASCII). One user has many orders and many events; one product appears in many orders and many events.

```
                    ┌──────────────────────┐
                    │      products        │
                    ├──────────────────────┤
                    │ product_id (PK)      │
                    │ product_name         │
                    │ category             │
                    │ price                │
                    └──────────┬───────────┘
                               │ 1
              ┌────────────────┼────────────────┐
              │                │                │
              │ M              │ M              │
              ▼                ▼                │
    ┌──────────────────────┐   ┌──────────────────────┐
    │       orders         │   │       events         │
    ├──────────────────────┤   ├──────────────────────┤
    │ order_id (PK)        │   │ user_id        (FK)  │
    │ user_id        (FK)──┼───│ event_time           │
    │ order_time           │   │ event_type           │
    │ product_id     (FK)  │   │ product_id     (FK)  │
    │ quantity             │   │ session_id           │
    └──────────────────────┘   └──────────────────────┘
              ▲                ▲
              │                │
              │ 1              │ 1
              │                │
    ┌─────────┴────────────────┴─────────┐
    │              users                  │
    ├────────────────────────────────────┤
    │ user_id (PK)                        │
    │ signup_date                         │
    │ country                             │
    │ region                              │
    └────────────────────────────────────┘
```

**Relationships:**

| From       | To        | Cardinality | Description                          |
|-----------|-----------|-------------|--------------------------------------|
| users     | orders    | 1 : M       | A user can place many orders.        |
| users     | events    | 1 : M       | A user can generate many events.     |
| products  | orders    | 1 : M       | A product can appear in many orders. |
| products  | events    | 1 : M       | A product can appear in many events. |

---

## Column-Level Definitions

### Table: `users`

| Column       | Data type | Description |
|-------------|-----------|-------------|
| **user_id** | integer   | Unique identifier for the user (primary key). |
| **signup_date** | date   | Date the user signed up. |
| **country** | string    | Country code (e.g. US, CA, UK, DE, AU). |
| **region**  | string    | Region or state (e.g. state abbreviation for US). |

**Source file:** `users.csv`

---

### Table: `products`

| Column         | Data type | Description |
|----------------|-----------|-------------|
| **product_id** | integer   | Unique identifier for the product (primary key). |
| **product_name** | string  | Display name of the product (e.g. "Premium Dog Food 5lb"). |
| **category**   | string    | Product category (e.g. Pet Food, Treats, Toys, Supplies, Health, Grooming, Beds, Collars, Litter, Aquarium, Small Pet, Wild Bird). |
| **price**      | decimal   | Unit price of the product. |

**Source file:** `products.csv`

---

### Table: `orders`

| Column       | Data type | Description |
|-------------|-----------|-------------|
| **order_id** | integer  | Unique identifier for the order (primary key). |
| **user_id**  | integer  | References `users.user_id`. User who placed the order. |
| **order_time** | datetime | Timestamp when the order was placed. |
| **product_id** | integer  | References `products.product_id`. Product ordered. |
| **quantity** | integer   | Number of units ordered. |

**Source file:** `orders.csv`

---

### Table: `events`

| Column       | Data type | Description |
|-------------|-----------|-------------|
| **user_id** | integer   | References `users.user_id`. User who generated the event. |
| **event_time** | datetime | Timestamp when the event occurred. |
| **event_type** | string   | Type of event: `view`, `add_to_cart`, `remove_from_cart`, `purchase`, `wishlist`. |
| **product_id** | integer  | References `products.product_id`. Product associated with the event. |
| **session_id** | string   | Identifier for the browsing session (multiple events can share one session). |

**Source file:** `events.csv`

**Note:** `events` has no single primary key; a row is uniquely identified by the combination of (user_id, event_time, product_id, session_id) or by application logic (e.g. event stream order).

---

## File Summary

| File         | Table    | Approx. rows |
|-------------|----------|----------------|
| users.csv   | users    | 2,500         |
| products.csv| products | 400           |
| orders.csv  | orders   | 5,200+        |
| events.csv  | events   | 22,000+       |

Data is generated by `src/python_core/generate_products_events_orders_data.py` and is intended for SQL, Python, and PySpark practice.
