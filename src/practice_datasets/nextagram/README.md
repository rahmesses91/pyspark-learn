# Nextagram - Photo Sharing App Analytics Practice

A SQL practice dataset simulating analytics for a fictional Instagram-like photo-sharing platform called **Nextagram**. Designed for interview preparation with focus on KPI dashboard design and daily metrics population.

> **Interview Context**: System design + SQL coding assessment evaluating ability to design efficient dashboard tables and write daily ETL queries.

---

## Schema Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              TABLES                                          │
├─────────────────────────────────────────────────────────────────────────────┤
│  users          - User accounts and profiles                                │
│  photos         - Photos uploaded by users                                  │
│  followers      - Follow relationships between users                        │
│  view_event     - Photo view events (who viewed what and when)             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Entity Relationship Diagram

```
┌─────────────────────┐              ┌─────────────────────┐
│       users         │              │       photos        │
├─────────────────────┤              ├─────────────────────┤
│ PK  id       BIGINT │◄─────┐       │ PK  id       BIGINT │◄────┐
│     name     VARCHAR│      │       │ FK  user_id  BIGINT │─────┼──┐
│     join_ts  TS     │      │       │     url      VARCHAR│     │  │
└─────────────────────┘      │       │     upload_ts TS    │     │  │
          ▲                  │       └─────────────────────┘     │  │
          │                  │                                   │  │
          │                  │       ┌─────────────────────┐     │  │
          │                  │       │     view_event      │     │  │
          │                  │       ├─────────────────────┤     │  │
          │                  ├───────│ FK  user_id  BIGINT │     │  │
          │                  │       │ FK  photo_id BIGINT │─────┘  │
          │                  │       │     ts       TS     │        │
          │                  │       └─────────────────────┘        │
          │                  │                                      │
          │                  │       ┌─────────────────────┐        │
          │                  │       │     followers       │        │
          │                  │       ├─────────────────────┤        │
          │                  ├───────│ FK  user_id    BIGINT│ (the follower)
          └──────────────────┼───────│ FK  following_id BIGINT│ (being followed)
                             │       │ PK  id        BIGINT │        
                             │       │     follow_ts TS     │        
                             │       └─────────────────────┘        
                             │                                      
Legend: PK = Primary Key, FK = Foreign Key                          
        BIGINT = Big Integer, VARCHAR = Variable Character          
        TS = Timestamp                                              
```

---

## Data Catalog

### Table: `users`

User accounts and profile information.

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| `id` | BIGINT | NO | **Primary Key**. Unique identifier for each user |
| `name` | VARCHAR(100) | NO | User's display name |
| `join_ts` | TIMESTAMP | NO | When the user joined the platform |

**Indexes**: `id` (PK), `join_ts`

**Record Count**: 500

---

### Table: `photos`

Photos uploaded by users.

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| `id` | BIGINT | NO | **Primary Key**. Unique identifier for each photo |
| `user_id` | BIGINT | NO | **Foreign Key** → `users.id`. User who uploaded the photo |
| `url` | VARCHAR(500) | NO | URL path to the photo |
| `upload_ts` | TIMESTAMP | NO | When the photo was uploaded |

**Indexes**: `id` (PK), `user_id`, `upload_ts`

**Foreign Keys**: `user_id` → `users(id)`

**Record Count**: 2,000

---

### Table: `followers`

Follow relationships between users.

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| `id` | BIGINT | NO | **Primary Key**. Unique identifier for the relationship |
| `user_id` | BIGINT | NO | **Foreign Key** → `users.id`. The user who is following |
| `following_id` | BIGINT | NO | **Foreign Key** → `users.id`. The user being followed |
| `follow_ts` | TIMESTAMP | NO | When the follow relationship was created |

**Indexes**: `id` (PK), `user_id`, `following_id`, `follow_ts`

**Foreign Keys**: 
- `user_id` → `users(id)`
- `following_id` → `users(id)`

**Unique Constraint**: `(user_id, following_id)` - A user can only follow another user once

**Record Count**: 3,000

> **Note**: In this table, `user_id` is the follower (the one doing the following) and `following_id` is the person being followed. To count how many followers a user has, count rows where `following_id` equals that user's ID.

---

### Table: `view_event`

Photo view events tracking user engagement.

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| `user_id` | BIGINT | NO | **Foreign Key** → `users.id`. User who viewed the photo |
| `photo_id` | BIGINT | NO | **Foreign Key** → `photos.id`. Photo that was viewed |
| `ts` | TIMESTAMP | NO | When the view occurred |

**Indexes**: `user_id`, `photo_id`, `ts`

**Foreign Keys**:
- `user_id` → `users(id)`
- `photo_id` → `photos(id)`

**Record Count**: 15,000

> **Note**: This table does not have a primary key - the same user can view the same photo multiple times.

---

## Data Summary

| Table | Records | Primary Key | Foreign Keys |
|-------|---------|-------------|--------------|
| `users` | 500 | `id` | - |
| `photos` | 2,000 | `id` | `user_id` |
| `followers` | 3,000 | `id` | `user_id`, `following_id` |
| `view_event` | 15,000 | - | `user_id`, `photo_id` |

**Data Range**: January 1, 2024 - June 30, 2024

---

## Practice Problems

### Part I: Basic Data Exploration (Warm-up)

1. **Q1**: How many users are there?
2. **Q2**: In which month did the most users join?
3. **Q3**: What is the name of the user with the most followers?

### Part II: KPI Dashboard Design

Design the table(s) that power a daily KPI dashboard with:

- **New Users** - count and 7-day change
- **DAU** (Daily Active Users) - count and 7-day change
- **New Photos** - count, photos per DAU, and 7-day change
- **Follower Distribution** - % with 0, 1-2, and 3+ followers

**Considerations**:
- Dashboard performance (pre-aggregation vs. real-time calculation)
- Single table vs. multiple tables
- Index design
- Handling the 7-day comparison efficiently

### Part III: Daily Dashboard Population

Write queries to populate the dashboard table(s):

- **Q5**: Daily new users and 7-day change
- **Q6**: DAU and 7-day change (users who viewed OR uploaded)
- **Q7**: New photos, photos per DAU, 7-day changes
- **Q8**: Follower distribution percentages
- **Q9**: Combined INSERT statement for all metrics

### Bonus Problems

1. **User Engagement Score**: Weighted score based on photos, followers, views
2. **Viral Photos**: Photos viewed by 5%+ of all users
3. **Follow Network Analysis**: Identify influencers vs fans based on follower ratio

---

## Key Metrics for Photo-Sharing Apps

| Metric | Formula | Typical Benchmark |
|--------|---------|-------------------|
| **DAU/MAU** | Daily Active / Monthly Active | 50-70% for social apps |
| **New User Growth** | Day-over-day new signups | 2-5% daily |
| **Photos per DAU** | Total uploads / Active users | 0.1-0.3 |
| **D1 Retention** | Users active Day 1 / New users | 40-50% |
| **Follower Ratio** | Followers / Following | 1.0 balanced |

---

## Folder Structure

```
nextagram/
├── README.md                     # This file (data catalog & documentation)
├── mysql/
│   ├── 00_schema.sql             # CREATE TABLE statements
│   ├── 01_practice_problems.sql  # Problems only (no solutions)
│   └── 02_solutions.sql          # All solutions
├── users.csv                     # Raw user data
├── photos.csv                    # Photo records
├── followers.csv                 # Follow relationships
├── view_events.csv               # View event log
└── generate_data.py              # Python script to regenerate data
```

---

## Getting Started

1. Create a new MySQL database: `CREATE DATABASE nextagram;`
2. Run `mysql/00_schema.sql` to create tables
3. Import CSV files using your preferred method:
   - DBeaver: Right-click table → Import Data → CSV
   - MySQL CLI: `LOAD DATA INFILE 'path/to/file.csv' INTO TABLE ...`
4. Start with Part I problems and progress to Part II & III

---

## Interview Tips

1. **Part I**: Warm-up questions - be fast and accurate
2. **Part II**: This is a design question - think aloud about trade-offs:
   - Pre-aggregation vs. real-time flexibility
   - Storage cost vs. query performance
   - Single table simplicity vs. multi-table modularity
3. **Part III**: Show you understand ETL patterns:
   - Use CTEs for clarity
   - Handle edge cases (division by zero, NULL values)
   - Consider idempotency (re-running should be safe)
4. **Explain the "why"**: Interviewers care about your reasoning, not just the code
