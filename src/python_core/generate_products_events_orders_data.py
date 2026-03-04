"""
Generate practice datasets for products / events / orders schema (with User dimension).
Schema: users, products, events, orders. At least 5k orders.
Output: practice_datasets/chewy/*.csv
"""
import pandas as pd
from faker import Faker
import random
from datetime import datetime, timedelta
import os

fake = Faker()
Faker.seed(42)
random.seed(42)

# CONFIGURATION
NUM_USERS = 2500
NUM_PRODUCTS = 400
NUM_ORDERS = 5200   # at least 5k
NUM_EVENTS = 22000  # ~4x orders for view/add_to_cart/purchase funnel

# OUTPUT DIRECTORY (same pattern as neighbors, revenues)
OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "practice_datasets", "chewy")
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Schema-aligned constants
PRODUCT_CATEGORIES = [
    "Pet Food", "Treats", "Toys", "Supplies", "Health", "Grooming",
    "Beds", "Collars", "Litter", "Aquarium", "Small Pet", "Wild Bird"
]
EVENT_TYPES = ["view", "add_to_cart", "remove_from_cart", "purchase", "wishlist"]


def generate_realistic_datetime(start_date, end_date):
    """Peak hours 8-10am and 6-10pm; weekends slightly higher activity."""
    base_date = fake.date_between(start_date=start_date, end_date=end_date)
    day_of_week = base_date.weekday()
    is_weekend = day_of_week >= 5
    hour_weights = [
        1, 1, 1, 1, 1, 2, 3, 5, 8, 8, 6, 5,
        4, 4, 3, 3, 4, 5, 7, 9, 10, 8, 5, 3
    ]
    if is_weekend:
        hour_weights = [w * 1.2 if 9 <= i <= 22 else w for i, w in enumerate(hour_weights)]
    hour = random.choices(range(24), weights=hour_weights)[0]
    minute = random.randint(0, 59)
    second = random.randint(0, 59)
    return datetime.combine(
        base_date,
        datetime.min.time().replace(hour=hour, minute=minute, second=second)
    )


# 1. USERS (dimension)
print("Generating users...")
users = []
for i in range(1, NUM_USERS + 1):
    signup = generate_realistic_datetime(
        start_date=datetime(2023, 1, 1),
        end_date=datetime(2025, 10, 31)
    )
    users.append({
        "user_id": i,
        "signup_date": signup.date(),
        "country": random.choices(
            ["US", "CA", "UK", "DE", "AU"],
            weights=[75, 8, 6, 5, 6]
        )[0],
        "region": fake.state_abbr() if random.random() < 0.8 else fake.country_code(),
    })
df_users = pd.DataFrame(users)
user_ids = df_users["user_id"].tolist()

# Product name building blocks (pet / Chewy-style); seed makes names reproducible
PRODUCT_NAME_STEMS = [
    "Premium", "Natural", "Grain-Free", "Organic", "Blue", "Salmon", "Chicken",
    "Beef", "Senior", "Puppy", "Kitten", "Adult", "Wild", "Hairball", "Weight",
    "Dental", "Joint", "Skin & Coat", "Sensitive", "Indoor", "Outdoor"
]
PRODUCT_NAME_SUFFIXES = [
    "Food 5lb", "Food 12lb", "Food 24lb", "Treats 6oz", "Treats 12oz",
    "Biscuits", "Chews", "Pellets", "Pads", "Litter 14lb", "Bed Medium",
    "Collar", "Leash", "Bowl", "Brush", "Shampoo", "Supplement 60ct"
]

# 2. PRODUCTS
print("Generating products...")
products = []
for i in range(1, NUM_PRODUCTS + 1):
    stem = random.choice(PRODUCT_NAME_STEMS)
    suffix = random.choice(PRODUCT_NAME_SUFFIXES)
    products.append({
        "product_id": i,
        "product_name": f"{stem} {suffix}",
        "category": random.choice(PRODUCT_CATEGORIES),
        "price": round(random.uniform(4.99, 149.99), 2),
    })
df_products = pd.DataFrame(products)
product_ids = df_products["product_id"].tolist()

# 3. ORDERS (at least 5k; user_id and product_id FK)
print("Generating orders...")
orders = []
for i in range(1, NUM_ORDERS + 1):
    uid = random.choice(user_ids)
    pid = random.choice(product_ids)
    order_time = generate_realistic_datetime(
        start_date=datetime(2024, 1, 1),
        end_date=datetime(2025, 12, 15)
    )
    orders.append({
        "order_id": i,
        "user_id": uid,
        "order_time": order_time,
        "product_id": pid,
        "quantity": random.choices([1, 2, 3, 4, 5], weights=[60, 25, 10, 3, 2])[0],
    })
df_orders = pd.DataFrame(orders)

# 4. EVENTS (user_id, event_time, event_type, product_id, session_id)
print("Generating events...")
events = []
session_counter = 0
for i in range(1, NUM_EVENTS + 1):
    uid = random.choice(user_ids)
    pid = random.choice(product_ids)
    # Sessions: some events share session_id (e.g. same session, multiple events)
    if random.random() < 0.3 and events and events[-1]["user_id"] == uid:
        session_id = events[-1]["session_id"]
    else:
        session_counter += 1
        session_id = f"s{session_counter:06d}"
    event_time = generate_realistic_datetime(
        start_date=datetime(2024, 1, 1),
        end_date=datetime(2025, 12, 15)
    )
    events.append({
        "user_id": uid,
        "event_time": event_time,
        "event_type": random.choices(
            EVENT_TYPES,
            weights=[50, 18, 5, 12, 15]
        )[0],
        "product_id": pid,
        "session_id": session_id,
    })
df_events = pd.DataFrame(events)

# EXPORT TO CSV (same format as practice_datasets: CSV, index=False)
print(f"\nSaving files to: {OUTPUT_DIR}")
df_users.to_csv(os.path.join(OUTPUT_DIR, "users.csv"), index=False)
df_products.to_csv(os.path.join(OUTPUT_DIR, "products.csv"), index=False)
df_orders.to_csv(os.path.join(OUTPUT_DIR, "orders.csv"), index=False)
df_events.to_csv(os.path.join(OUTPUT_DIR, "events.csv"), index=False)

total_records = len(df_users) + len(df_products) + len(df_orders) + len(df_events)
print(f"\nSuccessfully generated {total_records:,} total records:")
print(f"  - Users: {len(df_users):,}")
print(f"  - Products: {len(df_products):,}")
print(f"  - Orders: {len(df_orders):,}")
print(f"  - Events: {len(df_events):,}")
