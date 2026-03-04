# Ad Revenue Analytics Pipeline

A data pipeline for analyzing ad campaign performance, revenue, and user engagement for an ad-supported neighborhood platform. This pipeline transforms raw ad event data into actionable metrics for **dashboard visualization**.

> **Interview Context**: This is designed for a 1-hour technical interview focused on creating SQL datasets to power a dynamic dashboard. The emphasis is on ad tech metrics: CTR, CPC, ROAS, and rolling revenue.

---

## Data Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              BRONZE LAYER (Raw Data)                        │
├─────────────────────────────────────────────────────────────────────────────┤
│  users.csv   neighborhoods.csv   ad_campaigns.csv   ad_impressions.csv      │
│                                  ad_clicks.csv      ad_revenue.csv          │
└───────┬────────────┬────────────────┬─────────────────────┬─────────────────┘
        │            │                │                     │
        └────────────┴────────────────┴─────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         SILVER LAYER (Dimensions + Facts)                   │
├─────────────────────────────────────────────────────────────────────────────┤
│  01_silver_dim_tables.sql  →  dim_users, dim_campaigns, dim_ad_revenue      │
│  02_silver_user_engagement_ad.sql  →  fct_user_engagement_ad                │
└─────────────────────────────────────────────────────────────────────────────┘
                                  │
                    ┌─────────────┴─────────────┐
                    │                           │
                    ▼                           ▼
        ┌───────────────────┐       ┌───────────────────┐
        │   GOLD LAYER      │       │   GOLD LAYER      │
        │   (Metrics)       │       │   (Advanced)      │
        ├───────────────────┤       ├───────────────────┤
        │ 03_gold_ad_       │       │ 04_gold_advanced_ │
        │ performance_      │       │ revenue_          │
        │ metrics.sql       │       │ analytics.sql     │
        └───────────────────┘       └───────────────────┘
```

---

## Entity Relationship Diagram

```
┌─────────────────────────┐                      ┌─────────────────────────┐
│      NEIGHBORHOODS      │                      │      AD_CAMPAIGNS       │
├─────────────────────────┤                      ├─────────────────────────┤
│ PK  neighborhood_id     │                      │ PK  campaign_id         │
│     name                │                      │     advertiser_name     │
│     city                │                      │     objective           │
│     state               │                      │     budget              │
│     population          │                      │     status              │
└───────────┬─────────────┘                      │     start_date          │
            │                                    │     end_date            │
            │ 1                                  └───────────┬─────────────┘
            │                                                │
            │                                                │ 1
            │                                    ┌───────────┴───────────────────────────┐
            │                                    │                                       │
            │                                    │ N                                     │ N
            │    ┌─────────────────────────┐     │     ┌─────────────────────────┐       │
            │    │         USERS           │     │     │       AD_REVENUE        │       │
            │    ├─────────────────────────┤     │     ├─────────────────────────┤       │
            │    │ PK  user_id             │     │     │ PK  revenue_id          │       │
            │    │ FK  neighborhood_id  ───┼──┐  │     │ FK  campaign_id      ───┼───────┘
            │    │     age_group           │  │  │     │     revenue_date        │
            │    │     gender              │  │  │     │     revenue_amount      │
            │    │     device_type         │  │  │     │     ctr                 │
            │    │     is_verified         │  │  │     │     spend_amount        │
            │    │     created_at          │  │  │     └─────────────────────────┘
            │    └───────────┬─────────────┘  │  │
            │                │                │  │
            │                │ 1              │  │
            │                │                │  │
            │ N              │ N              │  │
┌───────────┴────────────────┴────────────────┴──┴───────────────────────────────┐
│                               AD_IMPRESSIONS                                   │
├────────────────────────────────────────────────────────────────────────────────┤
│ PK  impression_id                                                              │
│ FK  campaign_id  ──────────────────────────────────────────────────────────────┼───┐
│ FK  user_id                                                                    │   │
│ FK  neighborhood_id                                                            │   │
│     ad_placement                                                               │   │
│     is_viewable                                                                │   │
│     created_at                                                                 │   │
└───────────────────────────────────┬────────────────────────────────────────────┘   │
                                    │                                                │
                                    │ 1                                              │
                                    │                                                │
                                    │ N                                              │
                    ┌───────────────┴───────────────┐                                │
                    │          AD_CLICKS            │                                │
                    ├───────────────────────────────┤                                │
                    │ PK  click_id                  │                                │
                    │ FK  impression_id             │                                │
                    │ FK  campaign_id  ─────────────┼────────────────────────────────┘
                    │ FK  user_id                   │
                    │     is_conversion             │
                    │     clicked_at                │
                    └───────────────────────────────┘


═══════════════════════════════════════════════════════════════════════════════════
                                  LEGEND
═══════════════════════════════════════════════════════════════════════════════════
    PK = Primary Key       FK = Foreign Key       1 ──── N = One-to-Many
═══════════════════════════════════════════════════════════════════════════════════


                              AD TECH DATA FLOW
═══════════════════════════════════════════════════════════════════════════════════

    ┌────────────┐      ┌────────────┐      ┌────────────┐      ┌────────────┐
    │ IMPRESSION │ ───► │   CLICK    │ ───► │ CONVERSION │ ───► │  REVENUE   │
    │   (View)   │      │  (Engage)  │      │  (Action)  │      │ (Outcome)  │
    └────────────┘      └────────────┘      └────────────┘      └────────────┘
         │                   │                   │                   │
         ▼                   ▼                   ▼                   ▼
    ad_impressions      ad_clicks          ad_clicks.           ad_revenue
                                           is_conversion
```

---

## Source Datasets

| File | Records | Description | Key Columns |
|------|---------|-------------|-------------|
| `users.csv` | ~5,000 | User profiles with demographics | user_id, age_group, gender, device_type, is_verified |
| `neighborhoods.csv` | 50 | Neighborhood reference data | neighborhood_id, name, city, state, population |
| `ad_campaigns.csv` | ~200 | Campaign metadata | campaign_id, advertiser_name, objective, budget, status |
| `ad_impressions.csv` | ~50,000 | Ad view events | impression_id, campaign_id, user_id, ad_placement, is_viewable |
| `ad_clicks.csv` | ~5,000 | Ad click events | click_id, impression_id, campaign_id, is_conversion |
| `ad_revenue.csv` | ~800 | Daily revenue by campaign | revenue_id, campaign_id, revenue_date, revenue_amount, ctr |

---

## SQL Files & Dashboard Use Cases

### Step 1: `01_silver_dim_tables.sql`
Creates dimension tables with derived attributes.

| Table | Key Derived Columns |
|-------|---------------------|
| `dim_users` | account_age_days, user_engagement_status (Active/Recent/Lapsed/Dormant) |
| `dim_campaigns` | campaign_lifecycle_status, budget_tier (Small/Medium/Large/Enterprise) |
| `dim_ad_revenue` | ctr_performance_tier, conversion_tier, revenue_tier, margin_percent |

---

### Step 2: `02_silver_user_engagement_ad.sql`
Creates unified ad engagement fact table.

| Event Type | Description |
|------------|-------------|
| IMPRESSION | User saw an ad |
| CLICK | User clicked an ad (enriched with impression context) |

---

### Step 3: `03_gold_ad_performance_metrics.sql`

| Query | Dashboard Use Case | Key Metrics |
|-------|-------------------|-------------|
| **Daily Summary** | KPI trend chart | Impressions, clicks, CTR, revenue, ROAS |
| **Campaign × Neighborhood** | Drill-down table | Performance by campaign and market |
| **Top 5 Revenue Days** | Anomaly detection | Best performing days per neighborhood |
| **Top 5 Neighborhoods** | Revenue leaderboard | Highest revenue markets |
| **Campaign Summary** | Campaign scorecard | CTR, conversion, ROAS, budget utilization |

---

### Step 4: `04_gold_advanced_revenue_analytics.sql`

| Query | Dashboard Use Case | Key Metrics |
|-------|-------------------|-------------|
| **Headline KPIs** | Executive cards | Active campaigns, reach, frequency, conversion rate |
| **Device Breakdown** | Pie chart | Impressions/CTR by device |
| **Rolling 7-Day Revenue** | Smoothed trend | Daily + rolling revenue by neighborhood |
| **Revenue Percentiles** | Distribution analysis | Identify outlier days |
| **Placement Performance** | Optimization | CTR/conversion by ad placement |
| **Week-over-Week Growth** | Growth chart | Revenue growth %, ROAS trend |

---

## Interview-Ready Metrics Cheat Sheet

### Ad Tech KPIs
| Metric | Formula | What "Good" Looks Like |
|--------|---------|------------------------|
| CTR (Click-Through Rate) | clicks / impressions × 100 | 2-5% average, 10%+ excellent |
| CVR (Conversion Rate) | conversions / clicks × 100 | 10%+ is strong |
| CPC (Cost Per Click) | spend / clicks | Lower is better |
| CPM (Cost Per Mille) | (spend / impressions) × 1000 | Varies by vertical |
| CPA (Cost Per Acquisition) | spend / conversions | Lower is better |
| ROAS (Return on Ad Spend) | revenue / spend | 3x+ is healthy |

### User Metrics
| Metric | Formula | Why It Matters |
|--------|---------|----------------|
| Reach | COUNT(DISTINCT user_id) | How many unique users saw ads |
| Frequency | impressions / unique_users | Ad fatigue risk if too high |
| Viewability | viewable_impressions / total_impressions | Ad quality metric |

### Revenue Metrics
| Metric | Formula | Why It Matters |
|--------|---------|----------------|
| Daily Revenue | SUM(revenue_amount) | Raw business outcome |
| Rolling 7-Day | SUM over 7-day window | Smoothed trend |
| Margin % | (revenue - spend) / revenue × 100 | Profitability |
| WoW Growth | (this_week - last_week) / last_week × 100 | Growth rate |

---

## Key SQL Patterns for Interviews

### 1. Rolling Window Aggregation
```sql
SUM(daily_revenue) OVER (
    PARTITION BY neighborhood_id
    ORDER BY revenue_date
    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
) AS rolling_7day_revenue
```

### 2. Date Spine for Gap Filling
```sql
-- Snowflake
SELECT DATEADD(day, SEQ4(), '2024-01-01') AS spine_date
FROM TABLE(GENERATOR(ROWCOUNT => 365))

-- PostgreSQL
SELECT generate_series('2024-01-01'::DATE, '2024-12-31'::DATE, '1 day')::DATE
```

### 3. Top N per Group
```sql
WITH ranked AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY neighborhood_id 
        ORDER BY revenue DESC
    ) AS rn
    FROM revenue_data
)
SELECT * FROM ranked WHERE rn <= 5
```

### 4. Revenue Attribution to Neighborhoods
```sql
-- Revenue is at campaign level, attribute via impressions
SELECT impressions.neighborhood_id, SUM(revenue.revenue_amount)
FROM ad_revenue revenue
JOIN ad_impressions impressions
    ON impressions.campaign_id = revenue.campaign_id
   AND impressions.created_at::DATE = revenue.revenue_date
GROUP BY impressions.neighborhood_id
```

---

## Snowflake vs PostgreSQL Syntax

| Feature | Snowflake | PostgreSQL |
|---------|-----------|------------|
| Table creation | `CREATE OR REPLACE TABLE` | `DROP IF EXISTS` + `CREATE TABLE` |
| Conditional count | `COUNT_IF(condition)` | `COUNT(*) FILTER (WHERE condition)` |
| Date difference | `DATEDIFF('day', a, b)` | `(b::DATE - a::DATE)` |
| Date spine | `TABLE(GENERATOR(ROWCOUNT => N))` | `generate_series(start, end, interval)` |
| Day of week | `DAYOFWEEK(date)` | `EXTRACT(DOW FROM date)` |
| Day name | `DAYNAME(date)` | `TO_CHAR(date, 'Day')` |

---

## Folder Structure

```
revenues/
├── README.md                      # This file
├── Rolling_7Day_Revenue_Explained.md  # Deep dive on rolling windows
├── users.csv                      # User data
├── neighborhoods.csv              # Neighborhood reference
├── ad_campaigns.csv               # Campaign metadata
├── ad_impressions.csv             # Impression events
├── ad_clicks.csv                  # Click events
├── ad_revenue.csv                 # Daily revenue
│
├── snowflake/                     # Snowflake SQL files
│   ├── 01_silver_dim_tables.sql
│   ├── 02_silver_user_engagement_ad.sql
│   ├── 03_gold_ad_performance_metrics.sql
│   └── 04_gold_advanced_revenue_analytics.sql
│
└── postgresql/                    # PostgreSQL SQL files
    ├── 01_silver_dim_tables.sql
    ├── 02_silver_user_engagement_ad.sql
    ├── 03_gold_ad_performance_metrics.sql
    └── 04_gold_advanced_revenue_analytics.sql
```

---

## Interview Preparation Tips

1. **Know the Ad Tech Funnel**: Impression → Click → Conversion → Revenue

2. **Understand Attribution**: Revenue is at campaign level, but you need to join through impressions to get neighborhood context.

3. **Rolling Windows**: Most important pattern for ad dashboards. Practice ROWS BETWEEN syntax.

4. **ROAS is King**: Return on Ad Spend is the metric advertisers care about most.

5. **Gap Filling**: Revenue data has gaps (weekends, no spend days). Use date spine + COALESCE to fill with zeros.

6. **Common Follow-up Questions**:
   - "How would you handle multiple neighborhoods per campaign?"
   - "What if impressions and revenue have different time zones?"
   - "How would you add a date filter for the dashboard?"
