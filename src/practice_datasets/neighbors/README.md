# Neighborhood User Engagement Analytics Pipeline

A data pipeline for analyzing user engagement in a neighborhood-based social platform (similar to Nextdoor). This pipeline transforms raw activity data into actionable metrics for **dashboard visualization**.

> **Interview Context**: This is designed for a 1-hour technical interview focused on creating SQL datasets to power a dynamic dashboard. The emphasis is on translating dashboard requirements into SQL.

---

## Data Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              BRONZE LAYER (Raw Data)                        │
├─────────────────────────────────────────────────────────────────────────────┤
│  users.csv    posts.csv    comments.csv    reactions.csv    neighborhoods.csv│
└───────┬────────────┬────────────┬───────────────┬───────────────┬───────────┘
        │            │            │               │               │
        └────────────┴────────────┴───────────────┴───────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         SILVER LAYER (Fact Table)                           │
├─────────────────────────────────────────────────────────────────────────────┤
│  01_silver_user_activity.sql  →  fct_user_engagement                        │
│  (Unified activity stream: posts, comments, reactions, inactive users)      │
└─────────────────────────────────────────────────────────────────────────────┘
                                  │
        ┌─────────────────────────┼─────────────────────────┐
        │                         │                         │
        ▼                         ▼                         ▼
┌───────────────────┐  ┌───────────────────┐  ┌───────────────────┐
│   GOLD LAYER      │  │   GOLD LAYER      │  │   GOLD LAYER      │
│   (Metrics)       │  │   (Funnel)        │  │   (Segmentation)  │
├───────────────────┤  ├───────────────────┤  ├───────────────────┤
│ 02_gold_daily_    │  │ 03_gold_user_     │  │ 04_gold_user_     │
│ engagement_       │  │ funnel_analysis   │  │ behavioral_       │
│ metrics.sql       │  │ .sql              │  │ segmentation.sql  │
└───────────────────┘  └───────────────────┘  └───────────────────┘
```

---

## Source Datasets

| File | Records | Description | Key Columns |
|------|---------|-------------|-------------|
| `users.csv` | ~2,000 | User profiles | user_id, name, email, created_at, neighborhood_id, is_active |
| `posts.csv` | ~6,000 | User posts | post_id, user_id, neighborhood_id, category, title, body, created_at |
| `comments.csv` | ~8,000 | Comments on posts | comment_id, post_id, user_id, body, created_at |
| `reactions.csv` | ~5,000 | Reactions to posts | reaction_id, post_id, user_id, reaction_type, created_at |
| `neighborhoods.csv` | 20 | Neighborhood data | neighborhood_id, name, city, state, zip_code, population |

---

## SQL Files & Dashboard Use Cases

### Step 1: `01_silver_user_activity.sql`
Creates the foundation `fct_user_engagement` table.

| Query | Dashboard Use Case |
|-------|-------------------|
| CREATE TABLE | Unified activity stream for all downstream analytics |

---

### Step 2: `02_gold_daily_engagement_metrics.sql`

| Query | Dashboard Use Case | Key Metrics |
|-------|-------------------|-------------|
| **Daily Activity Breakdown** | Activity overview cards, neighborhood comparison | Posts, comments, reactions per day |
| **DAU/WAU/MAU** | Executive KPI dashboard | Active users, stickiness ratios |
| **New vs Returning Users** | Growth dashboard | Acquisition vs retention split |
| **Day of Week & Hour** | Best time to post heatmap | Temporal engagement patterns |
| **Top Neighborhoods** | Community leaderboard | Engagement score, per-capita metrics |
| **Week-over-Week Growth** | Growth trend chart | WoW % change in users/posts |

---

### Step 3: `03_gold_user_funnel_analysis.sql`

| Query | Dashboard Use Case | Key Metrics |
|-------|-------------------|-------------|
| **Overall Funnel** | Funnel visualization | Post→Comment→Reaction conversion |
| **Funnel by Neighborhood** | Segmented funnel comparison | Conversion by community |
| **Time-to-Convert** | Onboarding effectiveness | Days between funnel stages |
| **Post Engagement Quality** | Content performance | Avg comments/reactions per post category |

---

### Step 4: `04_gold_user_behavioral_segmentation.sql`

| Query | Dashboard Use Case | Key Metrics |
|-------|-------------------|-------------|
| **Return Pattern Classification** | User health monitoring | first_activity, returned_within_day/week/month |
| **Segment Distribution** | Pie chart of user types | % power users vs casual |
| **Cohort Retention Matrix** | Retention heatmap | Week N retention % |
| **Power User Identification** | Ambassador program | Top 100 by engagement score |
| **Churn Risk Detection** | At-risk user alerts | CHURNED, HIGH_RISK, MEDIUM_RISK flags |

---

## Interview-Ready Metrics Cheat Sheet

### Engagement Metrics
| Metric | Formula | Good Target |
|--------|---------|-------------|
| DAU/WAU Ratio | Daily / Weekly Active | 20-40% |
| DAU/MAU Ratio | Daily / Monthly Active | 10-20% (Facebook: 50%+) |
| WAU/MAU Ratio | Weekly / Monthly Active | 40-60% |

### Funnel Metrics
| Metric | What It Measures | Why It Matters |
|--------|------------------|----------------|
| Post→Comment Rate | Content generating discussion | Community health |
| Comment→Reaction Rate | Engagement depth | Feature stickiness |
| Time-to-Convert | Friction in user journey | Onboarding quality |

### Retention Metrics
| Metric | Definition | What "Good" Looks Like |
|--------|------------|------------------------|
| Day 1 Retention | % users active next day | 40%+ |
| Week 1 Retention | % users active next week | 25%+ |
| Day 30 Retention | % users active after 30 days | 10%+ |

### Growth Metrics
| Metric | What It Shows |
|--------|---------------|
| New User Ratio | % of DAU that are first-time users |
| Returning User Ratio | % of DAU that are repeat users |
| WoW Growth Rate | Week-over-week % change |

---

## Key SQL Patterns for Interviews

### 1. Rolling Window Aggregations (DAU/WAU/MAU)
```sql
SELECT
    ds.activity_date,
    COUNT(DISTINCT au.user_id) AS wau
FROM date_spine ds
LEFT JOIN active_users au
    ON au.activity_date BETWEEN ds.activity_date - INTERVAL '6 days' AND ds.activity_date
GROUP BY ds.activity_date
```

### 2. Funnel Analysis with CASE + MIN
```sql
SELECT
    user_id,
    MIN(CASE WHEN activity_type = 'POST' THEN activity_date END) AS first_post,
    MIN(CASE WHEN activity_type = 'COMMENT' THEN activity_date END) AS first_comment
FROM activities
GROUP BY user_id
```

### 3. Cohort Retention with Week Difference
```sql
-- Snowflake
DATEDIFF('week', cohort_week, activity_week)

-- PostgreSQL
(activity_week - cohort_week) / 7
```

### 4. Behavioral Segmentation with LAG
```sql
SELECT
    user_id,
    activity_datetime,
    LAG(activity_datetime) OVER (PARTITION BY user_id ORDER BY activity_datetime) AS prev_activity,
    CASE 
        WHEN prev_activity IS NULL THEN 'first_activity'
        WHEN DATEDIFF(day, prev_activity, activity_datetime) < 7 THEN 'returned_within_week'
        ...
    END AS segment
```

### 5. New vs Returning User Classification
```sql
WITH user_first_activity AS (
    SELECT user_id, MIN(activity_date) AS first_date
    FROM activities GROUP BY user_id
)
SELECT
    CASE WHEN a.activity_date = f.first_date THEN 'NEW' ELSE 'RETURNING' END
FROM activities a
JOIN user_first_activity f ON a.user_id = f.user_id
```

---

## Snowflake vs PostgreSQL Syntax

| Feature | Snowflake | PostgreSQL |
|---------|-----------|------------|
| Table creation | `CREATE OR REPLACE TABLE` | `DROP TABLE IF EXISTS` + `CREATE TABLE` |
| Conditional count | `COUNT_IF(condition)` | `COUNT(*) FILTER (WHERE condition)` |
| Date difference | `DATEDIFF(day, a, b)` | `(b::DATE - a::DATE)` |
| Week difference | `DATEDIFF('week', a, b)` | `(b - a) / 7` |
| Day of week | `DAYOFWEEK(ts)` | `EXTRACT(DOW FROM ts)` |
| Hour | `HOUR(ts)` | `EXTRACT(HOUR FROM ts)` |
| Median | `MEDIAN(col)` | `PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY col)` |

---

## Folder Structure

```
neighbors/
├── README.md                      # This file
├── users.csv                      # Raw user data
├── posts.csv                      # Raw posts data
├── comments.csv                   # Raw comments data
├── reactions.csv                  # Raw reactions data
├── neighborhoods.csv              # Raw neighborhood data
│
├── snowflake/                     # Snowflake SQL files
│   ├── 01_silver_user_activity.sql
│   ├── 02_gold_daily_engagement_metrics.sql
│   ├── 03_gold_user_funnel_analysis.sql
│   └── 04_gold_user_behavioral_segmentation.sql
│
└── postgresql/                    # PostgreSQL SQL files
    ├── 01_silver_user_activity.sql
    ├── 02_gold_daily_engagement_metrics.sql
    ├── 03_gold_user_funnel_analysis.sql
    └── 04_gold_user_behavioral_segmentation.sql
```

---

## Interview Preparation Tips

1. **Understand the "Why"**: Every CTE has a comment explaining what it does AND why. Be ready to explain your thought process.

2. **Know Your Metrics**: Be able to explain what DAU/MAU ratio means, what "good" looks like, and why it matters.

3. **Think in Dashboards**: Frame your answers as "This powers the X widget which helps stakeholders see Y."

4. **Handle Edge Cases**: 
   - Users with no activity
   - Division by zero (use `NULLIF`)
   - First week has no prior week for WoW calculations

5. **Window Functions Are Your Friend**:
   - `LAG()` for return behavior
   - `RANK()` for leaderboards
   - `SUM() OVER()` for running totals
   - Rolling windows for WAU/MAU

6. **Common Follow-up Questions**:
   - "How would you add a date filter for the dashboard?"
   - "What if we wanted to see this by mobile vs web?"
   - "How would you handle timezone differences?"
