"""
Volley Games - Synthetic Data Generator
Generates realistic voice gaming analytics data with referential integrity.

Usage:
    python generate_data.py

Output:
    - users.csv
    - games.csv
    - sessions.csv
    - events.csv
    - purchases.csv
"""

import csv
import json
import random
from datetime import datetime, timedelta
from pathlib import Path

random.seed(42)

OUTPUT_DIR = Path(__file__).parent

# Configuration
NUM_USERS = 3000
NUM_GAMES = 25
NUM_SESSIONS = 50000
NUM_PURCHASES = 5000
DATE_START = datetime(2024, 1, 1)
DATE_END = datetime(2024, 12, 31)

# Reference data
DEVICE_TYPES = ['alexa', 'google_home', 'mobile_ios', 'mobile_android']
DEVICE_WEIGHTS = [0.35, 0.25, 0.25, 0.15]

COUNTRIES = ['US', 'UK', 'Canada', 'Australia', 'Germany', 'France', 'India', 'Japan', 'Brazil', 'Mexico']
COUNTRY_WEIGHTS = [0.45, 0.15, 0.10, 0.08, 0.05, 0.05, 0.04, 0.03, 0.03, 0.02]

GAME_CATEGORIES = ['trivia', 'word_game', 'adventure', 'puzzle', 'music', 'kids', 'educational']
DIFFICULTIES = ['easy', 'medium', 'hard']

EVENT_TYPES = ['voice_command', 'game_start', 'game_complete', 'achievement', 'error', 'hint_used', 'level_up', 'pause', 'resume']
PURCHASE_TYPES = ['premium_subscription', 'hint_pack', 'extra_lives', 'cosmetic', 'game_unlock', 'ad_removal']
PURCHASE_PRICES = {
    'premium_subscription': [4.99, 9.99, 14.99],
    'hint_pack': [0.99, 1.99, 2.99],
    'extra_lives': [0.99, 1.99],
    'cosmetic': [1.99, 2.99, 4.99],
    'game_unlock': [2.99, 4.99, 6.99],
    'ad_removal': [2.99, 4.99]
}

VOICE_COMMANDS = [
    "guess letter A", "guess letter E", "guess letter S", "guess letter T",
    "answer Paris", "answer London", "answer Tokyo", "answer New York",
    "play again", "next question", "skip", "help", "hint please",
    "option A", "option B", "option C", "option D",
    "spin the wheel", "buy a vowel", "solve puzzle",
    "yes", "no", "repeat", "stop", "pause game"
]

ACHIEVEMENTS = [
    "first_win", "streak_3", "streak_5", "streak_10", "perfect_game",
    "speed_demon", "trivia_master", "word_wizard", "early_bird", "night_owl",
    "comeback_king", "no_hints", "social_butterfly", "dedicated_player"
]

GAME_NAMES = [
    "Voice Trivia Challenge", "Word Wizard", "Mystery Manor", "Brain Teasers",
    "Song Quiz", "Kids Adventure", "Math Masters", "History Hunt",
    "Spelling Bee", "Geography Genius", "Science Quest", "Movie Mania",
    "Sports Trivia", "Music Maestro", "Animal Kingdom", "Space Explorer",
    "Riddle Me This", "Vocabulary Builder", "Quick Math", "Story Time",
    "Language Lab", "Puzzle Palace", "Memory Master", "Logic Land", "Fun Facts"
]

USERNAMES_PREFIXES = [
    "Player", "Gamer", "Voice", "Quiz", "Trivia", "Brain", "Smart", "Quick",
    "Fun", "Happy", "Lucky", "Super", "Cool", "Epic", "Pro", "Master"
]


def random_date(start: datetime, end: datetime) -> datetime:
    delta = end - start
    random_days = random.randint(0, delta.days)
    random_seconds = random.randint(0, 86400)
    return start + timedelta(days=random_days, seconds=random_seconds)


def generate_users() -> list[dict]:
    users = []
    for i in range(1, NUM_USERS + 1):
        created_at = random_date(DATE_START, DATE_END - timedelta(days=30))
        prefix = random.choice(USERNAMES_PREFIXES)
        
        user = {
            'user_id': i,
            'username': f"{prefix}{random.randint(100, 9999)}",
            'email': f"user{i}@example.com",
            'device_type': random.choices(DEVICE_TYPES, weights=DEVICE_WEIGHTS)[0],
            'country': random.choices(COUNTRIES, weights=COUNTRY_WEIGHTS)[0],
            'created_at': created_at.strftime('%Y-%m-%d %H:%M:%S'),
            'is_premium': 1 if random.random() < 0.15 else 0,
            'last_active_at': None
        }
        users.append(user)
    return users


def generate_games() -> list[dict]:
    games = []
    for i, name in enumerate(GAME_NAMES, 1):
        release_date = random_date(DATE_START - timedelta(days=365), DATE_START + timedelta(days=180))
        
        game = {
            'game_id': i,
            'game_name': name,
            'category': random.choice(GAME_CATEGORIES),
            'difficulty': random.choice(DIFFICULTIES),
            'release_date': release_date.strftime('%Y-%m-%d'),
            'is_premium': 1 if random.random() < 0.2 else 0
        }
        games.append(game)
    return games


def generate_sessions(users: list[dict], games: list[dict]) -> list[dict]:
    sessions = []
    user_last_active = {}
    
    # Create user activity patterns (some users are more active)
    user_activity_level = {u['user_id']: random.choice([1, 2, 3, 5, 10, 20]) for u in users}
    
    # Weighted user selection based on activity level
    user_ids = [u['user_id'] for u in users]
    user_weights = [user_activity_level[uid] for uid in user_ids]
    
    user_created = {u['user_id']: datetime.strptime(u['created_at'], '%Y-%m-%d %H:%M:%S') for u in users}
    
    # Game popularity weights
    game_ids = [g['game_id'] for g in games]
    game_weights = [random.randint(1, 10) for _ in games]
    
    for i in range(1, NUM_SESSIONS + 1):
        user_id = random.choices(user_ids, weights=user_weights)[0]
        game_id = random.choices(game_ids, weights=game_weights)[0]
        
        # Session must be after user created
        user_start = user_created[user_id]
        started_at = random_date(user_start, DATE_END)
        
        # Session duration: 1-45 minutes, with some outliers
        duration_minutes = random.choices(
            [random.randint(1, 5), random.randint(5, 15), random.randint(15, 30), random.randint(30, 45)],
            weights=[0.2, 0.5, 0.2, 0.1]
        )[0]
        ended_at = started_at + timedelta(minutes=duration_minutes)
        
        # Completion rate varies by session length
        completed = 1 if random.random() < (0.4 + (duration_minutes / 100)) else 0
        score = random.randint(100, 2000) if completed else None
        
        # Get user's device type
        user_device = next(u['device_type'] for u in users if u['user_id'] == user_id)
        
        session = {
            'session_id': i,
            'user_id': user_id,
            'game_id': game_id,
            'device_type': user_device,
            'started_at': started_at.strftime('%Y-%m-%d %H:%M:%S'),
            'ended_at': ended_at.strftime('%Y-%m-%d %H:%M:%S'),
            'completed': completed,
            'score': score
        }
        sessions.append(session)
        
        # Track last active
        if user_id not in user_last_active or ended_at > user_last_active[user_id]:
            user_last_active[user_id] = ended_at
    
    # Update users with last_active_at
    for user in users:
        if user['user_id'] in user_last_active:
            user['last_active_at'] = user_last_active[user['user_id']].strftime('%Y-%m-%d %H:%M:%S')
    
    return sessions


def generate_events(sessions: list[dict]) -> list[dict]:
    events = []
    event_id = 1
    
    for session in sessions:
        session_start = datetime.strptime(session['started_at'], '%Y-%m-%d %H:%M:%S')
        session_end = datetime.strptime(session['ended_at'], '%Y-%m-%d %H:%M:%S')
        session_duration = (session_end - session_start).total_seconds()
        
        # Game start event
        events.append({
            'event_id': event_id,
            'session_id': session['session_id'],
            'user_id': session['user_id'],
            'event_type': 'game_start',
            'event_data': json.dumps({'difficulty': random.choice(DIFFICULTIES)}),
            'created_at': session_start.strftime('%Y-%m-%d %H:%M:%S')
        })
        event_id += 1
        
        # Voice commands (3-20 per session depending on duration)
        num_commands = min(int(session_duration / 30) + random.randint(2, 5), 20)
        for j in range(num_commands):
            event_time = session_start + timedelta(seconds=random.randint(10, int(session_duration) - 10))
            recognized = random.random() < 0.88  # 88% recognition rate
            
            events.append({
                'event_id': event_id,
                'session_id': session['session_id'],
                'user_id': session['user_id'],
                'event_type': 'voice_command',
                'event_data': json.dumps({
                    'command': random.choice(VOICE_COMMANDS),
                    'recognized': recognized
                }),
                'created_at': event_time.strftime('%Y-%m-%d %H:%M:%S')
            })
            event_id += 1
        
        # Random events during session
        if random.random() < 0.15:  # 15% chance of error
            event_time = session_start + timedelta(seconds=random.randint(10, int(session_duration) - 10))
            events.append({
                'event_id': event_id,
                'session_id': session['session_id'],
                'user_id': session['user_id'],
                'event_type': 'error',
                'event_data': json.dumps({
                    'error_type': random.choice(['voice_not_recognized', 'timeout', 'connection_issue'])
                }),
                'created_at': event_time.strftime('%Y-%m-%d %H:%M:%S')
            })
            event_id += 1
        
        if random.random() < 0.25 and session_duration > 40:  # 25% chance of using hint
            event_time = session_start + timedelta(seconds=random.randint(30, int(session_duration) - 10))
            events.append({
                'event_id': event_id,
                'session_id': session['session_id'],
                'user_id': session['user_id'],
                'event_type': 'hint_used',
                'event_data': json.dumps({'hints_remaining': random.randint(0, 3)}),
                'created_at': event_time.strftime('%Y-%m-%d %H:%M:%S')
            })
            event_id += 1
        
        if random.random() < 0.10 and session_duration > 70:  # 10% chance of achievement
            event_time = session_start + timedelta(seconds=random.randint(60, int(session_duration) - 10))
            events.append({
                'event_id': event_id,
                'session_id': session['session_id'],
                'user_id': session['user_id'],
                'event_type': 'achievement',
                'event_data': json.dumps({
                    'achievement': random.choice(ACHIEVEMENTS),
                    'points': random.choice([50, 100, 150, 200, 500])
                }),
                'created_at': event_time.strftime('%Y-%m-%d %H:%M:%S')
            })
            event_id += 1
        
        if random.random() < 0.20 and session_duration > 70:  # 20% chance of level up
            event_time = session_start + timedelta(seconds=random.randint(60, int(session_duration) - 10))
            events.append({
                'event_id': event_id,
                'session_id': session['session_id'],
                'user_id': session['user_id'],
                'event_type': 'level_up',
                'event_data': json.dumps({'new_level': random.randint(2, 50)}),
                'created_at': event_time.strftime('%Y-%m-%d %H:%M:%S')
            })
            event_id += 1
        
        # Game complete event
        if session['completed']:
            events.append({
                'event_id': event_id,
                'session_id': session['session_id'],
                'user_id': session['user_id'],
                'event_type': 'game_complete',
                'event_data': json.dumps({
                    'score': session['score'],
                    'time_seconds': int(session_duration)
                }),
                'created_at': session_end.strftime('%Y-%m-%d %H:%M:%S')
            })
            event_id += 1
    
    return events


def generate_purchases(users: list[dict], games: list[dict], sessions: list[dict]) -> list[dict]:
    purchases = []
    
    # Users who have sessions are more likely to purchase
    active_users = list(set(s['user_id'] for s in sessions))
    session_counts = {}
    for s in sessions:
        session_counts[s['user_id']] = session_counts.get(s['user_id'], 0) + 1
    
    user_created = {u['user_id']: datetime.strptime(u['created_at'], '%Y-%m-%d %H:%M:%S') for u in users}
    game_ids = [g['game_id'] for g in games]
    
    for i in range(1, NUM_PURCHASES + 1):
        # Weighted selection: more active users more likely to purchase
        weights = [session_counts.get(uid, 0) + 1 for uid in active_users]
        user_id = random.choices(active_users, weights=weights)[0]
        
        item_type = random.choices(
            PURCHASE_TYPES,
            weights=[0.15, 0.25, 0.20, 0.15, 0.15, 0.10]
        )[0]
        
        amount = random.choice(PURCHASE_PRICES[item_type])
        
        # Purchase happens after user creation
        purchase_date = random_date(user_created[user_id], DATE_END)
        
        # game_id is optional (some purchases are account-wide)
        game_id = random.choice(game_ids) if item_type in ['game_unlock', 'hint_pack', 'extra_lives'] else None
        
        purchase = {
            'purchase_id': i,
            'user_id': user_id,
            'game_id': game_id,
            'item_type': item_type,
            'amount_usd': amount,
            'purchased_at': purchase_date.strftime('%Y-%m-%d %H:%M:%S')
        }
        purchases.append(purchase)
    
    return purchases


def write_csv(filename: str, data: list[dict], fieldnames: list[str]):
    filepath = OUTPUT_DIR / filename
    with open(filepath, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(data)
    print(f"  ✓ {filename}: {len(data):,} records")


def main():
    print("Generating Volley Games synthetic data...")
    print("=" * 50)
    
    print("\n1. Generating users...")
    users = generate_users()
    
    print("2. Generating games...")
    games = generate_games()
    
    print("3. Generating sessions...")
    sessions = generate_sessions(users, games)
    
    print("4. Generating events...")
    events = generate_events(sessions)
    
    print("5. Generating purchases...")
    purchases = generate_purchases(users, games, sessions)
    
    print("\n6. Writing CSV files...")
    write_csv('users.csv', users, 
              ['user_id', 'username', 'email', 'device_type', 'country', 'created_at', 'is_premium', 'last_active_at'])
    write_csv('games.csv', games,
              ['game_id', 'game_name', 'category', 'difficulty', 'release_date', 'is_premium'])
    write_csv('sessions.csv', sessions,
              ['session_id', 'user_id', 'game_id', 'device_type', 'started_at', 'ended_at', 'completed', 'score'])
    write_csv('events.csv', events,
              ['event_id', 'session_id', 'user_id', 'event_type', 'event_data', 'created_at'])
    write_csv('purchases.csv', purchases,
              ['purchase_id', 'user_id', 'game_id', 'item_type', 'amount_usd', 'purchased_at'])
    
    print("\n" + "=" * 50)
    print("Data generation complete!")
    print(f"\nTotal records:")
    print(f"  - Users: {len(users):,}")
    print(f"  - Games: {len(games):,}")
    print(f"  - Sessions: {len(sessions):,}")
    print(f"  - Events: {len(events):,}")
    print(f"  - Purchases: {len(purchases):,}")


if __name__ == "__main__":
    main()
