"""
Nextagram Data Generator
Generates realistic sample data for the Nextagram photo-sharing app practice dataset.
"""

import random
import csv
from datetime import datetime, timedelta
from pathlib import Path

random.seed(42)

# Configuration
NUM_USERS = 500
NUM_PHOTOS = 2000
NUM_FOLLOWERS = 3000
NUM_VIEW_EVENTS = 15000

# Date range: 6 months of data
START_DATE = datetime(2024, 1, 1)
END_DATE = datetime(2024, 6, 30)

# First names for generating usernames
FIRST_NAMES = [
    "Emma", "Liam", "Olivia", "Noah", "Ava", "William", "Sophia", "James",
    "Isabella", "Oliver", "Mia", "Benjamin", "Charlotte", "Elijah", "Amelia",
    "Lucas", "Harper", "Mason", "Evelyn", "Logan", "Abigail", "Alexander",
    "Emily", "Ethan", "Elizabeth", "Jacob", "Sofia", "Michael", "Avery",
    "Daniel", "Ella", "Henry", "Scarlett", "Jackson", "Grace", "Sebastian",
    "Chloe", "Aiden", "Victoria", "Matthew", "Riley", "Samuel", "Aria",
    "David", "Lily", "Joseph", "Aurora", "Carter", "Zoey", "Owen", "Penelope",
    "Wyatt", "Layla", "John", "Nora", "Jack", "Camila", "Luke", "Hannah",
    "Jayden", "Zoe", "Dylan", "Stella", "Grayson", "Leah", "Levi", "Hazel",
    "Isaac", "Violet", "Gabriel", "Aurora", "Julian", "Savannah", "Mateo",
    "Audrey", "Anthony", "Brooklyn", "Jaxon", "Bella", "Lincoln", "Claire",
    "Joshua", "Skylar", "Christopher", "Lucy", "Andrew", "Paisley", "Theodore",
    "Everly", "Caleb", "Anna", "Ryan", "Caroline", "Asher", "Nova", "Nathan",
    "Genesis", "Thomas", "Emilia", "Leo", "Kennedy"
]

LAST_NAMES = [
    "Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller",
    "Davis", "Rodriguez", "Martinez", "Hernandez", "Lopez", "Gonzalez",
    "Wilson", "Anderson", "Thomas", "Taylor", "Moore", "Jackson", "Martin",
    "Lee", "Perez", "Thompson", "White", "Harris", "Sanchez", "Clark",
    "Ramirez", "Lewis", "Robinson", "Walker", "Young", "Allen", "King",
    "Wright", "Scott", "Torres", "Nguyen", "Hill", "Flores", "Green",
    "Adams", "Nelson", "Baker", "Hall", "Rivera", "Campbell", "Mitchell",
    "Carter", "Roberts"
]


def random_timestamp(start: datetime, end: datetime) -> datetime:
    """Generate random timestamp between start and end."""
    delta = end - start
    random_seconds = random.randint(0, int(delta.total_seconds()))
    return start + timedelta(seconds=random_seconds)


def generate_users(num_users: int) -> list[dict]:
    """Generate user records."""
    users = []
    used_names = set()
    
    for i in range(1, num_users + 1):
        while True:
            first = random.choice(FIRST_NAMES)
            last = random.choice(LAST_NAMES)
            name = f"{first} {last}"
            if name not in used_names:
                used_names.add(name)
                break
        
        join_ts = random_timestamp(START_DATE, END_DATE - timedelta(days=30))
        
        users.append({
            "id": i,
            "name": name,
            "join_ts": join_ts.strftime("%Y-%m-%d %H:%M:%S")
        })
    
    return users


def generate_photos(users: list[dict], num_photos: int) -> list[dict]:
    """Generate photo records."""
    photos = []
    
    user_weights = [random.paretovariate(1.5) for _ in users]
    total_weight = sum(user_weights)
    user_probs = [w / total_weight for w in user_weights]
    
    for i in range(1, num_photos + 1):
        user = random.choices(users, weights=user_probs, k=1)[0]
        user_join = datetime.strptime(user["join_ts"], "%Y-%m-%d %H:%M:%S")
        upload_ts = random_timestamp(user_join + timedelta(hours=1), END_DATE)
        
        photo_hash = f"{random.randint(10000000, 99999999)}"
        url = f"https://nextagram.com/photos/{user['id']}/{photo_hash}.jpg"
        
        photos.append({
            "id": i,
            "user_id": user["id"],
            "url": url,
            "upload_ts": upload_ts.strftime("%Y-%m-%d %H:%M:%S")
        })
    
    return photos


def generate_followers(users: list[dict], num_followers: int) -> list[dict]:
    """Generate follower relationships."""
    followers = []
    existing_follows = set()
    
    user_popularity = {u["id"]: random.paretovariate(1.2) for u in users}
    
    follow_id = 1
    attempts = 0
    max_attempts = num_followers * 10
    
    while len(followers) < num_followers and attempts < max_attempts:
        attempts += 1
        
        follower = random.choice(users)
        followed_weights = [
            user_popularity[u["id"]] if u["id"] != follower["id"] else 0 
            for u in users
        ]
        total = sum(followed_weights)
        if total == 0:
            continue
        followed_probs = [w / total for w in followed_weights]
        followed = random.choices(users, weights=followed_probs, k=1)[0]
        
        relationship = (follower["id"], followed["id"])
        if relationship in existing_follows or follower["id"] == followed["id"]:
            continue
        
        existing_follows.add(relationship)
        
        follower_join = datetime.strptime(follower["join_ts"], "%Y-%m-%d %H:%M:%S")
        followed_join = datetime.strptime(followed["join_ts"], "%Y-%m-%d %H:%M:%S")
        earliest_follow = max(follower_join, followed_join) + timedelta(hours=1)
        
        if earliest_follow >= END_DATE:
            continue
            
        follow_ts = random_timestamp(earliest_follow, END_DATE)
        
        followers.append({
            "id": follow_id,
            "user_id": follower["id"],
            "following_id": followed["id"],
            "follow_ts": follow_ts.strftime("%Y-%m-%d %H:%M:%S")
        })
        follow_id += 1
    
    return followers


def generate_view_events(
    users: list[dict], 
    photos: list[dict], 
    num_events: int
) -> list[dict]:
    """Generate photo view events."""
    events = []
    
    photo_weights = [random.paretovariate(1.3) for _ in photos]
    total_weight = sum(photo_weights)
    photo_probs = [w / total_weight for w in photo_weights]
    
    user_join_map = {
        u["id"]: datetime.strptime(u["join_ts"], "%Y-%m-%d %H:%M:%S") 
        for u in users
    }
    photo_upload_map = {
        p["id"]: datetime.strptime(p["upload_ts"], "%Y-%m-%d %H:%M:%S") 
        for p in photos
    }
    
    for _ in range(num_events):
        user = random.choice(users)
        photo = random.choices(photos, weights=photo_probs, k=1)[0]
        
        user_join = user_join_map[user["id"]]
        photo_upload = photo_upload_map[photo["id"]]
        earliest_view = max(user_join, photo_upload) + timedelta(minutes=1)
        
        if earliest_view >= END_DATE:
            continue
        
        view_ts = random_timestamp(earliest_view, END_DATE)
        
        events.append({
            "user_id": user["id"],
            "photo_id": photo["id"],
            "ts": view_ts.strftime("%Y-%m-%d %H:%M:%S")
        })
    
    return events


def write_csv(data: list[dict], filepath: Path) -> None:
    """Write data to CSV file."""
    if not data:
        return
    
    with open(filepath, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=data[0].keys())
        writer.writeheader()
        writer.writerows(data)
    
    print(f"Wrote {len(data)} records to {filepath}")


def main():
    """Generate all data files."""
    output_dir = Path(__file__).parent
    
    print("Generating Nextagram sample data...")
    print(f"Date range: {START_DATE.date()} to {END_DATE.date()}")
    print("-" * 50)
    
    print("Generating users...")
    users = generate_users(NUM_USERS)
    write_csv(users, output_dir / "users.csv")
    
    print("Generating photos...")
    photos = generate_photos(users, NUM_PHOTOS)
    write_csv(photos, output_dir / "photos.csv")
    
    print("Generating followers...")
    followers = generate_followers(users, NUM_FOLLOWERS)
    write_csv(followers, output_dir / "followers.csv")
    
    print("Generating view events...")
    view_events = generate_view_events(users, photos, NUM_VIEW_EVENTS)
    write_csv(view_events, output_dir / "view_events.csv")
    
    print("-" * 50)
    print("Data generation complete!")
    print(f"\nSummary:")
    print(f"  Users: {len(users)}")
    print(f"  Photos: {len(photos)}")
    print(f"  Followers: {len(followers)}")
    print(f"  View Events: {len(view_events)}")


if __name__ == "__main__":
    main()
