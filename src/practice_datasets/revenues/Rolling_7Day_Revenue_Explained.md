# Rolling 7-Day Revenue by Neighborhood — Query Explanation

---

## Overview

This query calculates the **7-day rolling revenue** for each neighborhood by joining ad revenue data with impression data. It ensures that all dates are accounted for (even days with zero revenue) by using a date spine technique.

---

## Step 1: revenue_by_day_base

**Purpose:** Aggregate daily revenue by neighborhood.

```sql
revenue_by_day_base AS (
    SELECT
        impressions.neighborhood_id,
        revenue.revenue_date,
        SUM(revenue.revenue_amount) AS daily_revenue
    FROM SOURCES.NEXTDOOR_ADS_CAMPAIGN.AD_REVENUE AS revenue
    JOIN SOURCES.NEXTDOOR_ADS_CAMPAIGN.AD_IMPRESSIONS AS impressions
        ON impressions.campaign_id = revenue.campaign_id
       AND DATE(impressions.created_at) = revenue.revenue_date
    GROUP BY
        impressions.neighborhood_id,
        revenue.revenue_date
)
```

**Explanation:** This CTE joins the `AD_REVENUE` table with `AD_IMPRESSIONS` to attribute revenue to specific neighborhoods. Revenue is grouped by neighborhood and date.

| Output Columns | Description |
|----------------|-------------|
| neighborhood_id | The neighborhood where impressions occurred |
| revenue_date | The date of the revenue |
| daily_revenue | Total revenue for that neighborhood on that date |

---

## Step 2: neighborhood_date_range

**Purpose:** Find the earliest revenue date for each neighborhood.

```sql
neighborhood_date_range AS (
    SELECT
        neighborhood_id,
        MIN(revenue_date) AS min_date
    FROM revenue_by_day_base
    GROUP BY neighborhood_id
)
```

**Explanation:** This determines when each neighborhood started generating revenue, which will be used as the starting point for the date spine.

| Output Columns | Description |
|----------------|-------------|
| neighborhood_id | The neighborhood |
| min_date | First date with revenue activity |

---

## Step 3: date_spine

**Purpose:** Generate a continuous sequence of dates.

```sql
date_spine AS (
    SELECT
        DATEADD(day, SEQ4(), '2024-01-01') AS spine_date
    FROM TABLE(GENERATOR(ROWCOUNT => 2000))
)
```

**Explanation:** This creates a table of 2,000 consecutive dates starting from January 1, 2024. This ensures we have a complete date range to fill gaps where no revenue was recorded.

| Output Columns | Description |
|----------------|-------------|
| spine_date | A continuous date from 2024-01-01 onwards |

---

## Step 4: neighborhood_spine

**Purpose:** Create a complete date range for each neighborhood.

```sql
neighborhood_spine AS (
    SELECT
        date_range.neighborhood_id,
        spine.spine_date AS revenue_date
    FROM neighborhood_date_range AS date_range
    JOIN date_spine AS spine
        ON spine.spine_date BETWEEN date_range.min_date AND CURRENT_DATE
)
```

**Explanation:** This cross-joins each neighborhood with the date spine, filtered from their minimum revenue date to today. This ensures every neighborhood has a row for every possible date.

| Output Columns | Description |
|----------------|-------------|
| neighborhood_id | The neighborhood |
| revenue_date | Every date from min_date to current date |

---

## Step 5: revenue_with_spine

**Purpose:** Fill missing dates with zero revenue.

```sql
revenue_with_spine AS (
    SELECT
        neighborhood_spine.neighborhood_id,
        neighborhood_spine.revenue_date,
        COALESCE(revenue_by_day_base.daily_revenue, 0) AS daily_revenue
    FROM neighborhood_spine
    LEFT JOIN revenue_by_day_base
        ON revenue_by_day_base.neighborhood_id = neighborhood_spine.neighborhood_id
       AND revenue_by_day_base.revenue_date    = neighborhood_spine.revenue_date
)
```

**Explanation:** This left joins the actual revenue data onto the complete date spine. Days with no revenue are filled with 0 using COALESCE.

| Output Columns | Description |
|----------------|-------------|
| neighborhood_id | The neighborhood |
| revenue_date | The date (continuous, no gaps) |
| daily_revenue | Actual revenue or 0 if no activity |

---

## Step 6: max_dates

**Purpose:** Find the most recent revenue date for each neighborhood.

```sql
max_dates AS (
    SELECT
        neighborhood_id,
        MAX(revenue_date) AS max_date
    FROM revenue_by_day_base
    GROUP BY neighborhood_id
)
```

**Explanation:** This identifies the last date each neighborhood had revenue, which serves as the endpoint for the 7-day window.

| Output Columns | Description |
|----------------|-------------|
| neighborhood_id | The neighborhood |
| max_date | Most recent date with revenue |

---

## Step 7: filtered_last_7_days

**Purpose:** Keep only the last 7 days of data per neighborhood.

```sql
filtered_last_7_days AS (
    SELECT
        spine_data.neighborhood_id,
        spine_data.revenue_date,
        spine_data.daily_revenue
    FROM revenue_with_spine AS spine_data
    JOIN max_dates
      ON spine_data.neighborhood_id = max_dates.neighborhood_id
     AND spine_data.revenue_date BETWEEN DATEADD(day, -6, max_dates.max_date)
                                     AND max_dates.max_date
)
```

**Explanation:** This filters the data to include only the 7 most recent days (max_date minus 6 days through max_date) for each neighborhood.

| Output Columns | Description |
|----------------|-------------|
| neighborhood_id | The neighborhood |
| revenue_date | Dates within the last 7 days |
| daily_revenue | Revenue for each day |

---

## Step 8: rolling_revenue

**Purpose:** Calculate the 7-day rolling sum.

```sql
rolling_revenue AS (
    SELECT
        neighborhood_id,
        revenue_date,
        daily_revenue,
        SUM(daily_revenue) OVER (
            PARTITION BY neighborhood_id
            ORDER BY revenue_date
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) AS rolling_7day_revenue
    FROM filtered_last_7_days
)
```

**Explanation:** This uses a window function to calculate the cumulative sum of revenue over the current row and the 6 preceding rows (7 days total).

| Output Columns | Description |
|----------------|-------------|
| neighborhood_id | The neighborhood |
| revenue_date | The date |
| daily_revenue | Revenue for that single day |
| rolling_7day_revenue | Sum of revenue for the past 7 days |

---

## Final Query

```sql
SELECT *
FROM rolling_revenue
ORDER BY neighborhood_id, revenue_date;
```

**Explanation:** The query returns all columns from the rolling_revenue CTE, ordered by neighborhood and date.

---

## Sample Output

| neighborhood_id | revenue_date | daily_revenue | rolling_7day_revenue |
|-----------------|--------------|---------------|----------------------|
| 1 | 2025-12-09 | 150.00 | 150.00 |
| 1 | 2025-12-10 | 200.00 | 350.00 |
| 1 | 2025-12-11 | 0.00 | 350.00 |
| 1 | 2025-12-12 | 175.00 | 525.00 |
| 1 | 2025-12-13 | 300.00 | 825.00 |
| 1 | 2025-12-14 | 125.00 | 950.00 |
| 1 | 2025-12-15 | 250.00 | 1200.00 |

---

## Key Techniques Used

| Technique | Description |
|-----------|-------------|
| **Date Spine** | Generates continuous dates to fill gaps in sparse data |
| **COALESCE** | Replaces NULL values with 0 for days without revenue |
| **Window Function** | Calculates rolling aggregates without collapsing rows |
| **ROWS BETWEEN 6 PRECEDING AND CURRENT ROW** | Defines a 7-day sliding window |

---

## Complete Query

```sql
WITH revenue_by_day_base AS (
    SELECT
        impressions.neighborhood_id,
        revenue.revenue_date,
        SUM(revenue.revenue_amount) AS daily_revenue
    FROM SOURCES.NEXTDOOR_ADS_CAMPAIGN.AD_REVENUE AS revenue
    JOIN SOURCES.NEXTDOOR_ADS_CAMPAIGN.AD_IMPRESSIONS AS impressions
        ON impressions.campaign_id = revenue.campaign_id
       AND DATE(impressions.created_at) = revenue.revenue_date
    GROUP BY
        impressions.neighborhood_id,
        revenue.revenue_date
),

neighborhood_date_range AS (
    SELECT
        neighborhood_id,
        MIN(revenue_date) AS min_date
    FROM revenue_by_day_base
    GROUP BY neighborhood_id
),

date_spine AS (
    SELECT
        DATEADD(day, SEQ4(), '2024-01-01') AS spine_date
    FROM TABLE(GENERATOR(ROWCOUNT => 2000))
),

neighborhood_spine AS (
    SELECT
        date_range.neighborhood_id,
        spine.spine_date AS revenue_date
    FROM neighborhood_date_range AS date_range
    JOIN date_spine AS spine
        ON spine.spine_date BETWEEN date_range.min_date AND CURRENT_DATE
),

revenue_with_spine AS (
    SELECT
        neighborhood_spine.neighborhood_id,
        neighborhood_spine.revenue_date,
        COALESCE(revenue_by_day_base.daily_revenue, 0) AS daily_revenue
    FROM neighborhood_spine
    LEFT JOIN revenue_by_day_base
        ON revenue_by_day_base.neighborhood_id = neighborhood_spine.neighborhood_id
       AND revenue_by_day_base.revenue_date    = neighborhood_spine.revenue_date
),

max_dates AS (
    SELECT
        neighborhood_id,
        MAX(revenue_date) AS max_date
    FROM revenue_by_day_base
    GROUP BY neighborhood_id
),

filtered_last_7_days AS (
    SELECT
        spine_data.neighborhood_id,
        spine_data.revenue_date,
        spine_data.daily_revenue
    FROM revenue_with_spine AS spine_data
    JOIN max_dates
      ON spine_data.neighborhood_id = max_dates.neighborhood_id
     AND spine_data.revenue_date BETWEEN DATEADD(day, -6, max_dates.max_date)
                                     AND max_dates.max_date
),

rolling_revenue AS (
    SELECT
        neighborhood_id,
        revenue_date,
        daily_revenue,
        SUM(daily_revenue) OVER (
            PARTITION BY neighborhood_id
            ORDER BY revenue_date
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) AS rolling_7day_revenue
    FROM filtered_last_7_days
)

SELECT *
FROM rolling_revenue
ORDER BY neighborhood_id, revenue_date;
```
