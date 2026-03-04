import pandas as pd
from faker import Faker
import random
from datetime import datetime, timedelta
import os

fake = Faker()
Faker.seed(42)
random.seed(42)

# CONFIGURATION - Total ~20,000 records
NUM_NEIGHBORHOODS = 20
NUM_USERS = 2000
NUM_POSTS = 6000
NUM_COMMENTS = 8000
NUM_REACTIONS = 5000

# OUTPUT DIRECTORY
OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "practice_datasets", "neighbors")
os.makedirs(OUTPUT_DIR, exist_ok=True)


def generate_realistic_datetime_2025(start_date, end_date):
    """
    Generate realistic timestamps that reflect typical user behavior patterns:
    - Peak hours: 8-10am (morning check) and 6-10pm (evening browsing)
    - Weekends have 30% more activity
    - Activity varies by month (higher in Jan, lower in summer)
    """
    base_date = fake.date_between(start_date=start_date, end_date=end_date)
    
    day_of_week = base_date.weekday()
    is_weekend = day_of_week >= 5
    
    hour_weights = [
        1, 1, 1, 1, 1, 2,        # 12am-5am: very low activity
        3, 5, 8, 8, 6, 5,        # 6am-11am: morning peak
        4, 4, 3, 3, 4, 5,        # 12pm-5pm: afternoon lull
        7, 9, 10, 8, 5, 3        # 6pm-11pm: evening peak
    ]
    
    if is_weekend:
        hour_weights = [w * 1.3 if 9 <= i <= 22 else w for i, w in enumerate(hour_weights)]
    
    hour = random.choices(range(24), weights=hour_weights)[0]
    minute = random.randint(0, 59)
    second = random.randint(0, 59)
    
    return datetime.combine(base_date, datetime.min.time().replace(hour=hour, minute=minute, second=second))


def generate_activity_datetime_2025(base_datetime, max_hours=48, activity_type="comment"):
    """
    Generate a datetime for activity (comments/reactions) after a post.
    - Most reactions happen within first few hours
    - Comments can come later (up to 48 hours)
    """
    if activity_type == "reaction":
        delay_weights = [10, 8, 6, 5, 4, 3, 2, 2, 1, 1, 1, 1] + [1] * (max_hours - 12)
    else:
        delay_weights = [3, 5, 6, 7, 8, 7, 6, 5, 4, 4, 3, 3] + [2] * (max_hours - 12)
    
    delay_hours = random.choices(range(1, max_hours + 1), weights=delay_weights[:max_hours])[0]
    delay_minutes = random.randint(0, 59)
    
    return base_datetime + timedelta(hours=delay_hours, minutes=delay_minutes)


# 1. GENERATE NEIGHBORHOODS
print("Generating neighborhoods...")
neighborhoods = []
for i in range(1, NUM_NEIGHBORHOODS + 1):
    neighborhoods.append({
        "neighborhood_id": i,
        "name": f"{fake.city()} Heights" if i % 2 == 0 else f"{fake.street_name()} Park",
        "city": fake.city(),
        "state": fake.state_abbr(),
        "zip_code": fake.zipcode(),
        "population": random.randint(5000, 50000)
    })
df_neighborhood = pd.DataFrame(neighborhoods)

# 2. GENERATE USERS (joined between Jan 2024 and Oct 2025)
print("Generating users...")
users = []
for i in range(101, 101 + NUM_USERS):
    join_date = generate_realistic_datetime_2025(
        start_date=datetime(2024, 1, 1),
        end_date=datetime(2025, 10, 31)
    )
    users.append({
        "user_id": i,
        "name": fake.name(),
        "email": fake.email(),
        "created_at": join_date,
        "neighborhood_id": random.choice(df_neighborhood['neighborhood_id'].tolist()),
        "is_active": random.choices([True, False], weights=[85, 15])[0]
    })
df_user = pd.DataFrame(users)
user_id_list = df_user['user_id'].tolist()

# 3. GENERATE POSTS (activity throughout 2025 with realistic patterns)
print("Generating posts...")
posts = []
for i in range(501, 501 + NUM_POSTS):
    author = df_user.sample(1).iloc[0]
    
    post_date = generate_realistic_datetime_2025(
        start_date=datetime(2025, 1, 1),
        end_date=datetime(2025, 12, 15)
    )
    
    if post_date < author['created_at']:
        post_date = author['created_at'] + timedelta(days=random.randint(1, 30))
    
    post_categories = ['General', 'Safety', 'Events', 'Recommendations', 'Lost & Found', 'Classifieds', 'Pets']
    posts.append({
        "post_id": i,
        "user_id": author['user_id'],
        "neighborhood_id": author['neighborhood_id'],
        "category": random.choice(post_categories),
        "title": fake.sentence(nb_words=random.randint(3, 6)),
        "body": fake.paragraph(nb_sentences=random.randint(1, 4)),
        "created_at": post_date
    })
df_post = pd.DataFrame(posts)

# 4. GENERATE COMMENTS (with referential integrity - always after post creation)
print("Generating comments...")
comments = []
post_records = df_post.to_dict('records')
for i in range(901, 901 + NUM_COMMENTS):
    target_post = random.choice(post_records)
    
    comment_time = generate_activity_datetime_2025(
        base_datetime=target_post['created_at'],
        max_hours=72,
        activity_type="comment"
    )
    
    comments.append({
        "comment_id": i,
        "post_id": target_post['post_id'],
        "user_id": random.choice(user_id_list),
        "body": fake.sentence(nb_words=random.randint(5, 20)),
        "created_at": comment_time
    })
df_comment = pd.DataFrame(comments)

# 5. GENERATE REACTIONS (with referential integrity - always after post creation)
print("Generating reactions...")
reactions = []
reaction_types = ['Thank', 'Helpful', 'Smile', 'Sad', 'Wow', 'Agree', 'Love']
for i in range(1, NUM_REACTIONS + 1):
    target_post = random.choice(post_records)
    
    reaction_time = generate_activity_datetime_2025(
        base_datetime=target_post['created_at'],
        max_hours=24,
        activity_type="reaction"
    )
    
    reactions.append({
        "reaction_id": i,
        "post_id": target_post['post_id'],
        "user_id": random.choice(user_id_list),
        "reaction_type": random.choice(reaction_types),
        "created_at": reaction_time
    })
df_reaction = pd.DataFrame(reactions)

# EXPORT TO CSV
print(f"\nSaving files to: {OUTPUT_DIR}")
df_neighborhood.to_csv(os.path.join(OUTPUT_DIR, "neighborhoods.csv"), index=False)
df_user.to_csv(os.path.join(OUTPUT_DIR, "users.csv"), index=False)
df_post.to_csv(os.path.join(OUTPUT_DIR, "posts.csv"), index=False)
df_comment.to_csv(os.path.join(OUTPUT_DIR, "comments.csv"), index=False)
df_reaction.to_csv(os.path.join(OUTPUT_DIR, "reactions.csv"), index=False)

total_records = len(df_neighborhood) + len(df_user) + len(df_post) + len(df_comment) + len(df_reaction)
print(f"\nSuccessfully generated {total_records:,} total records:")
print(f"  - Neighborhoods: {len(df_neighborhood):,}")
print(f"  - Users: {len(df_user):,}")
print(f"  - Posts: {len(df_post):,}")
print(f"  - Comments: {len(df_comment):,}")
print(f"  - Reactions: {len(df_reaction):,}")