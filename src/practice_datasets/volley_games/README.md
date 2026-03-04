# Volley Games - Voice Game Analytics Practice

A SQL practice dataset simulating analytics for an AI-powered voice gaming platform (similar to Volley). Designed for interview preparation with progressively difficult data transformation problems.

> **Interview Context**: Live coding assessment evaluating SQL skills through game analytics exercises. Focus on clean queries, edge case handling, and clear communication.

---

## Schema Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              TABLES                                          │
├─────────────────────────────────────────────────────────────────────────────┤
│  users          - Player profiles and account info                          │
│  games          - Voice games catalog                                        │
│  sessions       - Game play sessions (start/end times, device info)         │
│  events         - In-game events (voice commands, achievements, errors)     │
│  purchases      - In-app purchases and subscriptions                        │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Entity Relationship Diagram

```
┌─────────────────────┐           ┌─────────────────────┐
│       users         │           │       games         │
├─────────────────────┤           ├─────────────────────┤
│ PK  user_id    INT  │◄───┐      │ PK  game_id    INT  │◄───┐
│     username   VAR  │    │      │     game_name  VAR  │    │
│     email      VAR  │    │      │     category   ENUM │    │
│     device_type ENUM│    │      │     difficulty ENUM │    │
│     country    VAR  │    │      │     release_date DATE│    │
│     created_at DT   │    │      │     is_premium TINY │    │
│     is_premium TINY │    │      └─────────────────────┘    │
│     last_active DT  │    │                                 │
└─────────────────────┘    │                                 │
          ▲                │                                 │
          │                │      ┌─────────────────────┐    │
          │                │      │     sessions        │    │
          │                │      ├─────────────────────┤    │
          │                ├──────│ FK  user_id    INT  │    │
          │                │      │ FK  game_id    INT  │────┤
          │                │      │ PK  session_id INT  │    │
          │                │      │     device_type ENUM│    │
          │                │      │     started_at  DT  │    │
          │                │      │     ended_at    DT  │    │
          │                │      │     completed  TINY │    │
          │                │      │     score      INT  │    │
          │                │      └──────────┬──────────┘    │
          │                │                 │               │
          │                │                 ▼               │
          │                │      ┌─────────────────────┐    │
          │                │      │      events         │    │
          │                │      ├─────────────────────┤    │
          │                ├──────│ FK  user_id    INT  │    │
          │                       │ FK  session_id INT  │    │
          │                       │ PK  event_id   INT  │    │
          │                       │     event_type ENUM │    │
          │                       │     event_data JSON │    │
          │                       │     created_at  DT  │    │
          │                       └─────────────────────┘    │
          │                                                  │
          │                ┌─────────────────────┐           │
          │                │     purchases       │           │
          │                ├─────────────────────┤           │
          └────────────────│ FK  user_id    INT  │           │
                           │ FK  game_id    INT  │───────────┘
                           │ PK  purchase_id INT │
                           │     item_type  ENUM │
                           │     amount_usd DEC  │
                           │     purchased_at DT │
                           └─────────────────────┘

Legend: PK = Primary Key, FK = Foreign Key
        INT = Integer, VAR = VARCHAR, DT = DATETIME
        ENUM = Enumeration, TINY = TINYINT, DEC = DECIMAL
```

---

## Data Catalog

### Table: `users`

Player accounts and profile information.

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| `user_id` | INT | NO | **Primary Key**. Unique identifier for each user |
| `username` | VARCHAR(50) | NO | Display name chosen by the player |
| `email` | VARCHAR(100) | NO | User's email address (unique) |
| `device_type` | ENUM | NO | Primary device used. Values: `alexa`, `google_home`, `mobile_ios`, `mobile_android` |
| `country` | VARCHAR(50) | NO | User's country (ISO code). Values: `US`, `UK`, `Canada`, `Australia`, `Germany`, `France`, `India`, `Japan`, `Brazil`, `Mexico` |
| `created_at` | DATETIME | NO | Timestamp when the account was created |
| `is_premium` | TINYINT(1) | YES | Premium subscription status. `1` = premium, `0` = free (default: 0) |
| `last_active_at` | DATETIME | YES | Timestamp of user's most recent session (NULL if never played) |

**Indexes**: `user_id` (PK), `created_at`, `country`, `device_type`

**Record Count**: ~3,000

---

### Table: `games`

Catalog of available voice games on the platform.

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| `game_id` | INT | NO | **Primary Key**. Unique identifier for each game |
| `game_name` | VARCHAR(100) | NO | Display name of the game |
| `category` | ENUM | NO | Game genre. Values: `trivia`, `word_game`, `adventure`, `puzzle`, `music`, `kids`, `educational` |
| `difficulty` | ENUM | NO | Difficulty level. Values: `easy`, `medium`, `hard` |
| `release_date` | DATE | NO | Date when the game was released on the platform |
| `is_premium` | TINYINT(1) | YES | Whether the game requires premium access. `1` = premium only, `0` = free (default: 0) |

**Indexes**: `game_id` (PK), `category`

**Record Count**: 25

---

### Table: `sessions`

Individual game play sessions tracking user engagement.

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| `session_id` | INT | NO | **Primary Key**. Unique identifier for each session |
| `user_id` | INT | NO | **Foreign Key** → `users.user_id`. Player who started the session |
| `game_id` | INT | NO | **Foreign Key** → `games.game_id`. Game being played |
| `device_type` | ENUM | NO | Device used for this session. Values: `alexa`, `google_home`, `mobile_ios`, `mobile_android` |
| `started_at` | DATETIME | NO | Timestamp when the session began |
| `ended_at` | DATETIME | YES | Timestamp when the session ended (NULL if abandoned/crashed) |
| `completed` | TINYINT(1) | YES | Whether the game was completed successfully. `1` = completed, `0` = abandoned (default: 0) |
| `score` | INT | YES | Final score achieved (NULL if not completed or game has no scoring) |

**Indexes**: `session_id` (PK), `user_id`, `game_id`, `started_at`, `completed`

**Foreign Keys**: 
- `user_id` → `users(user_id)`
- `game_id` → `games(game_id)`

**Record Count**: ~50,000

---

### Table: `events`

Granular in-game events capturing user interactions and system events.

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| `event_id` | INT | NO | **Primary Key**. Unique identifier for each event |
| `session_id` | INT | NO | **Foreign Key** → `sessions.session_id`. Session during which event occurred |
| `user_id` | INT | NO | **Foreign Key** → `users.user_id`. User who triggered the event |
| `event_type` | ENUM | NO | Type of event. Values: `voice_command`, `game_start`, `game_complete`, `achievement`, `error`, `hint_used`, `level_up`, `pause`, `resume` |
| `event_data` | JSON | YES | Additional event metadata (structure varies by event_type, see below) |
| `created_at` | DATETIME | NO | Timestamp when the event occurred |

**Indexes**: `event_id` (PK), `session_id`, `user_id`, `event_type`, `created_at`

**Foreign Keys**:
- `session_id` → `sessions(session_id)`
- `user_id` → `users(user_id)`

**Record Count**: ~975,000

#### Event Data JSON Structures

| event_type | event_data schema | Example |
|------------|-------------------|---------|
| `voice_command` | `{"command": string, "recognized": boolean}` | `{"command": "guess letter A", "recognized": true}` |
| `game_start` | `{"difficulty": string}` | `{"difficulty": "medium"}` |
| `game_complete` | `{"score": int, "time_seconds": int}` | `{"score": 850, "time_seconds": 120}` |
| `achievement` | `{"achievement": string, "points": int}` | `{"achievement": "first_win", "points": 100}` |
| `error` | `{"error_type": string}` | `{"error_type": "voice_not_recognized"}` |
| `hint_used` | `{"hints_remaining": int}` | `{"hints_remaining": 2}` |
| `level_up` | `{"new_level": int}` | `{"new_level": 5}` |
| `pause` | `{}` | `{}` |
| `resume` | `{}` | `{}` |

---

### Table: `purchases`

In-app purchases and subscription transactions.

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| `purchase_id` | INT | NO | **Primary Key**. Unique identifier for each purchase |
| `user_id` | INT | NO | **Foreign Key** → `users.user_id`. User who made the purchase |
| `game_id` | INT | YES | **Foreign Key** → `games.game_id`. Associated game (NULL for account-wide purchases like premium subscription) |
| `item_type` | ENUM | NO | Type of item purchased. Values: `premium_subscription`, `hint_pack`, `extra_lives`, `cosmetic`, `game_unlock`, `ad_removal` |
| `amount_usd` | DECIMAL(10,2) | NO | Purchase amount in US dollars |
| `purchased_at` | DATETIME | NO | Timestamp when the purchase was completed |

**Indexes**: `purchase_id` (PK), `user_id`, `purchased_at`, `item_type`

**Foreign Keys**:
- `user_id` → `users(user_id)`
- `game_id` → `games(game_id)`

**Record Count**: ~5,000

#### Item Type Descriptions

| item_type | Description | Typical Price Range |
|-----------|-------------|---------------------|
| `premium_subscription` | Monthly/annual subscription for premium features | $4.99 - $14.99 |
| `hint_pack` | Bundle of hints for use in games | $0.99 - $2.99 |
| `extra_lives` | Additional lives/attempts in games | $0.99 - $1.99 |
| `cosmetic` | Visual customizations (avatars, themes) | $1.99 - $4.99 |
| `game_unlock` | Unlock premium game content | $2.99 - $6.99 |
| `ad_removal` | Remove advertisements permanently | $2.99 - $4.99 |

---

## Data Summary

| Table | Records | Primary Key | Foreign Keys | Indexes |
|-------|---------|-------------|--------------|---------|
| `users` | ~3,000 | `user_id` | - | 4 |
| `games` | 25 | `game_id` | - | 2 |
| `sessions` | ~50,000 | `session_id` | `user_id`, `game_id` | 5 |
| `events` | ~975,000 | `event_id` | `session_id`, `user_id` | 5 |
| `purchases` | ~5,000 | `purchase_id` | `user_id`, `game_id` | 4 |

**Data Range**: January 1, 2024 - December 31, 2024

---

## Practice Problems (Progressive Difficulty)

### Level 0: Basic Queries (Warm-up)
- Q1-Q12: Simple COUNT, SUM, AVG, GROUP BY on single tables

### Level 1: Basic Aggregations
1. **Daily Active Users (DAU)**: Count distinct users who played each day
2. **Most Popular Games**: Rank games by total sessions played
3. **Revenue by Country**: Total purchases grouped by user country

### Level 2: Intermediate Joins & Grouping
4. **Session Duration Analysis**: Average session length by game and device type
5. **Completion Rate by Game**: % of sessions that completed vs abandoned
6. **Premium Conversion**: % of free users who made a purchase

### Level 3: Window Functions
7. **Day-over-Day Growth**: Calculate DAU change % using LAG()
8. **User Retention (Day 1, Day 7)**: % of users returning after N days
9. **Running Revenue**: Cumulative revenue per game over time
10. **Top Players Leaderboard**: Rank users by total play time with RANK()

### Level 4: Advanced Analytics
11. **Cohort Retention Matrix**: Weekly retention by signup cohort
12. **Funnel Analysis**: Install → First Session → First Purchase conversion
13. **Churn Prediction**: Identify users at risk (no activity in 7+ days after being active)
14. **LTV Calculation**: Average lifetime value by acquisition cohort
15. **Voice Command Success Rate**: % of commands recognized by game difficulty

---

## Key Metrics for Voice Games

| Metric | Formula | Benchmark |
|--------|---------|-----------|
| **DAU/MAU** | Daily Active / Monthly Active | 20-30% |
| **Session Length** | AVG(ended_at - started_at) | 5-15 min |
| **Completion Rate** | Sessions completed / Total sessions | 60-80% |
| **D1 Retention** | Users active Day 1 / New users | 35-45% |
| **D7 Retention** | Users active Day 7 / New users | 15-25% |
| **ARPU** | Revenue / Active Users | Varies |
| **Voice Recognition Rate** | Recognized commands / Total commands | 85-95% |

---

## MySQL-Specific Syntax Reference

### Date & Time Functions

#### Extracting Date/Time Parts
```sql
-- Extract date from datetime
DATE(started_at)                        -- '2024-03-15'
TIME(started_at)                        -- '14:30:45'

-- Extract individual components
YEAR(created_at)                        -- 2024
MONTH(created_at)                       -- 3
DAY(created_at)                         -- 15
HOUR(started_at)                        -- 14
MINUTE(started_at)                      -- 30
SECOND(started_at)                      -- 45

-- Day of week/year
DAYOFWEEK(created_at)                   -- 1 (Sunday) to 7 (Saturday)
WEEKDAY(created_at)                     -- 0 (Monday) to 6 (Sunday)
DAYOFYEAR(created_at)                   -- 1 to 366
WEEK(created_at)                        -- Week number (0-53)
QUARTER(created_at)                     -- 1 to 4
```

#### Date Formatting
```sql
-- Format date as string
DATE_FORMAT(created_at, '%Y-%m-%d')     -- '2024-03-15'
DATE_FORMAT(created_at, '%Y-%m')        -- '2024-03' (year-month)
DATE_FORMAT(created_at, '%M %d, %Y')    -- 'March 15, 2024'
DATE_FORMAT(created_at, '%W')           -- 'Friday' (day name)
DATE_FORMAT(created_at, '%H:%i:%s')     -- '14:30:45'

-- Common format codes:
-- %Y = 4-digit year    %y = 2-digit year
-- %m = month (01-12)   %M = month name
-- %d = day (01-31)     %e = day (1-31)
-- %H = hour (00-23)    %h = hour (01-12)
-- %i = minutes         %s = seconds
-- %W = weekday name    %w = weekday (0=Sunday)
```

#### Date Arithmetic
```sql
-- Add intervals
DATE_ADD(created_at, INTERVAL 7 DAY)
DATE_ADD(created_at, INTERVAL 1 MONTH)
DATE_ADD(created_at, INTERVAL 1 YEAR)
DATE_ADD(started_at, INTERVAL 30 MINUTE)

-- Subtract intervals
DATE_SUB(created_at, INTERVAL 7 DAY)
created_at - INTERVAL 7 DAY             -- Alternative syntax

-- Difference between dates
DATEDIFF(ended_at, started_at)          -- Days between (integer)
TIMESTAMPDIFF(DAY, started_at, ended_at)    -- Days
TIMESTAMPDIFF(HOUR, started_at, ended_at)   -- Hours
TIMESTAMPDIFF(MINUTE, started_at, ended_at) -- Minutes
TIMESTAMPDIFF(SECOND, started_at, ended_at) -- Seconds
TIMESTAMPDIFF(MONTH, created_at, NOW())     -- Months since signup
```

#### Date Truncation
```sql
-- Truncate to start of period
DATE(started_at)                        -- Start of day
DATE_FORMAT(created_at, '%Y-%m-01')     -- Start of month
DATE_SUB(created_at, INTERVAL WEEKDAY(created_at) DAY)  -- Start of week (Monday)

-- Get first/last day of month
LAST_DAY(created_at)                    -- Last day of month
DATE_FORMAT(created_at, '%Y-%m-01')     -- First day of month
```

#### Current Date/Time
```sql
NOW()                                   -- Current datetime: '2024-03-15 14:30:45'
CURDATE()                               -- Current date: '2024-03-15'
CURTIME()                               -- Current time: '14:30:45'
CURRENT_TIMESTAMP                       -- Same as NOW()
UTC_TIMESTAMP()                         -- Current UTC datetime
```

#### Date Conversion
```sql
-- String to date
STR_TO_DATE('15-03-2024', '%d-%m-%Y')   -- '2024-03-15'
STR_TO_DATE('March 15, 2024', '%M %d, %Y')

-- Unix timestamp
UNIX_TIMESTAMP(created_at)              -- Seconds since 1970-01-01
FROM_UNIXTIME(1710512345)               -- Convert back to datetime
```

#### Useful Date Patterns for Analytics
```sql
-- Users who signed up in last 7 days
WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)

-- Users who signed up this month
WHERE YEAR(created_at) = YEAR(CURDATE()) 
  AND MONTH(created_at) = MONTH(CURDATE())

-- Group by week (starting Monday)
GROUP BY DATE(created_at - INTERVAL WEEKDAY(created_at) DAY)

-- Group by month
GROUP BY DATE_FORMAT(created_at, '%Y-%m')

-- Sessions longer than 30 minutes
WHERE TIMESTAMPDIFF(MINUTE, started_at, ended_at) > 30

-- Calculate session duration in minutes
ROUND(TIMESTAMPDIFF(SECOND, started_at, ended_at) / 60.0, 2) AS duration_minutes
```

### Window Functions (MySQL 8.0+)
```sql
-- Running total
SUM(amount_usd) OVER (ORDER BY purchased_at) AS running_revenue

-- Previous row value
LAG(dau, 1) OVER (ORDER BY activity_date) AS prev_day_dau

-- Ranking
RANK() OVER (PARTITION BY game_id ORDER BY score DESC) AS player_rank

-- Row number
ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at) AS session_num
```

### JSON Functions
```sql
-- Extract value from JSON
JSON_EXTRACT(event_data, '$.recognized') AS recognized
JSON_EXTRACT(event_data, '$.score') AS score

-- Shorthand syntax
event_data->>'$.command' AS command
```

### Common Patterns
```sql
-- Avoid division by zero
total_completed / NULLIF(total_sessions, 0) AS completion_rate

-- Conditional aggregation
SUM(CASE WHEN completed = 1 THEN 1 ELSE 0 END) AS completed_count
COUNT(CASE WHEN event_type = 'voice_command' THEN 1 END) AS voice_commands

-- NULL handling
IFNULL(revenue, 0) AS revenue
COALESCE(first_purchase, 'never') AS first_purchase
```

---

## Folder Structure

```
volley_games/
├── README.md                     # This file (data catalog & documentation)
├── mysql/
│   ├── 00_schema.sql             # CREATE TABLE statements
│   ├── 01_practice_problems.sql  # Problems only (no solutions)
│   └── 02_solutions.sql          # All solutions
├── users.csv                     # Raw user data
├── games.csv                     # Games catalog
├── sessions.csv                  # Play sessions
├── events.csv                    # In-game events
├── purchases.csv                 # Transactions
└── generate_data.py              # Python script to regenerate data
```

---

## Getting Started with DBeaver

1. Create a new MySQL database: `CREATE DATABASE volley_games;`
2. Run `mysql/00_schema.sql` to create tables
3. Import CSV files using DBeaver's import wizard:
   - Right-click table → Import Data → CSV
4. Start with Level 0 problems and progress upward
5. Time yourself: aim for 5-10 min per problem in interviews

---

## Interview Tips

1. **Clarify before coding**: Ask about date ranges, null handling, edge cases
2. **Think aloud**: Explain your approach as you write
3. **Start simple**: Get a working query first, then optimize
4. **Use CTEs**: Break complex logic into readable steps
5. **Handle edge cases**: Division by zero, nulls, first day of data
6. **Know your metrics**: Be ready to explain what each metric means and why it matters
