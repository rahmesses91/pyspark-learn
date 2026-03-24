# Interview prep — dimensional models (star schema)

Chewy-style e-commerce patterns for whiteboard and design discussion.

| Model | File | Focus |
|-------|------|--------|
| Orders | [orders_star_schema.md](./orders_star_schema.md) | Revenue, conversion, AOV, payments |
| Autoships | [autoships_star_schema.md](./autoships_star_schema.md) | Recurring revenue, cadence, churn |
| Supply chain / fulfillment | [fulfillment_star_schema.md](./fulfillment_star_schema.md) | Inventory, FC ops, ship, returns |

Each document: **2 facts** (header + line/detail) + **5 dimensions** (adjust to 4 in conversation if time-boxed). Diagrams use **ASCII ER boxes** (`+---+`, `1 *`, PK/FK columns)—same style as a whiteboard entity-relationship sketch.
