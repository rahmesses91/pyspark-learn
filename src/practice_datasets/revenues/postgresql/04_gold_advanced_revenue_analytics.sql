-- ============================================================================
-- STEP 4: GOLD LAYER - Advanced Revenue Analytics
-- ============================================================================
-- PURPOSE: Complex revenue analytics including rolling windows, headline
--          metrics, and device/placement breakdowns.
--
-- WHY THESE QUERIES:
--   - Rolling revenue: Smooths daily volatility for trend analysis
--   - Headline metrics: Executive dashboard KPI cards
--   - Device breakdown: Optimize ad placement strategy
--
-- DEPENDS ON:
--   - fct_user_engagement_ad (from Step 2)
--   - dim_ad_revenue (from Step 1)
--
-- INTERVIEW TIP: Rolling windows are VERY common in ad tech.
--                Know ROWS BETWEEN syntax cold.
-- ============================================================================


-- =============================================================================
-- QUERY 1: Headline KPI Metrics (Executive Dashboard Cards)
-- =============================================================================
-- DASHBOARD USE CASE: Top-of-dashboard KPI cards
-- 
-- METRICS:
--   - Active Campaigns (last 7 days)
--   - Unique Users Reached
--   - Total Impressions
--   - Average Frequency (impressions per user)
--   - Conversion Rate
-- =============================================================================

-- -----------------------------------------------------------------------------
-- CTE: user_engagement
-- WHAT: Base engagement data for aggregation
-- WHY:  Single source for all headline calculations.
-- -----------------------------------------------------------------------------
WITH user_engagement AS (
    SELECT 
        user_id,
        neighborhood_id,
        event_id,
        event_type,
        campaign_id,
        ad_placement,
        device_type,
        is_viewable,
        is_conversion,
        event_timestamp,
        event_date
    FROM fct_user_engagement_ad
),

-- -----------------------------------------------------------------------------
-- CTE: headline_metrics
-- WHAT: Calculates all headline KPIs in one pass
-- WHY:  Efficient single-scan aggregation for dashboard cards.
-- -----------------------------------------------------------------------------
headline_metrics AS (
    SELECT 
        -- Metric 1: Active Campaigns (last 7 days)
        COUNT(DISTINCT campaign_id) FILTER (
            WHERE event_type = 'IMPRESSION'
              AND event_date >= CURRENT_DATE - 7
        ) AS active_campaigns_last_7_days,

        -- Metric 2: Unique Users Reached
        COUNT(DISTINCT user_id) AS total_unique_users,

        -- Metric 3: Total Impressions
        COUNT(*) FILTER (WHERE event_type = 'IMPRESSION') AS total_impressions,

        -- Metric 4: Average Frequency
        ROUND(
            COUNT(*) FILTER (WHERE event_type = 'IMPRESSION')::NUMERIC / 
            NULLIF(COUNT(DISTINCT user_id), 0),
        1) AS average_frequency,

        -- Metric 5: Conversion Rate
        ROUND(
            COUNT(*) FILTER (WHERE is_conversion = TRUE) * 100.0 / 
            NULLIF(COUNT(*) FILTER (WHERE event_type = 'CLICK'), 0),
        2) AS conversion_rate_percent
        
    FROM user_engagement
)

SELECT * FROM headline_metrics;


-- =============================================================================
-- QUERY 2: Impressions by Device Type
-- =============================================================================
-- DASHBOARD USE CASE: Device breakdown pie chart
-- =============================================================================

WITH user_engagement AS (
    SELECT device_type, event_type 
    FROM fct_user_engagement_ad
),

device_breakdown AS (
    SELECT 
        device_type, 
        COUNT(*) FILTER (WHERE event_type = 'IMPRESSION') AS impressions,
        COUNT(*) FILTER (WHERE event_type = 'CLICK') AS clicks
    FROM user_engagement 
    GROUP BY device_type
)

SELECT
    device_type,
    impressions,
    clicks,
    ROUND(clicks * 100.0 / NULLIF(impressions, 0), 2) AS ctr_percent,
    ROUND(impressions * 100.0 / SUM(impressions) OVER (), 2) AS pct_of_impressions
FROM device_breakdown
ORDER BY impressions DESC;


-- =============================================================================
-- QUERY 3: Rolling 7-Day Revenue by Neighborhood
-- =============================================================================
-- DASHBOARD USE CASE: Revenue trend chart with smoothing
-- 
-- WHY ROLLING WINDOWS:
--   - Smooths daily volatility (weekends, holidays)
--   - Shows true trend direction
--   - Industry standard for revenue dashboards
-- =============================================================================

-- -----------------------------------------------------------------------------
-- CTE: revenue_by_day_base
-- WHAT: Actual revenue data joined to get neighborhood context
-- WHY:  Revenue table doesn't have neighborhood_id directly.
-- -----------------------------------------------------------------------------
WITH revenue_by_day_base AS (
    SELECT
        imp.neighborhood_id,
        rev.revenue_date,
        SUM(rev.revenue_amount) AS daily_revenue
    FROM ad_revenue AS rev
    INNER JOIN ad_impressions AS imp
        ON imp.campaign_id = rev.campaign_id
       AND imp.created_at::DATE = rev.revenue_date
    GROUP BY imp.neighborhood_id, rev.revenue_date
),

-- -----------------------------------------------------------------------------
-- CTE: neighborhood_date_range
-- WHAT: Min/max revenue dates per neighborhood
-- WHY:  We only want to create a date spine within actual data range.
-- -----------------------------------------------------------------------------
neighborhood_date_range AS (
    SELECT
        neighborhood_id,
        MIN(revenue_date) AS min_date,
        MAX(revenue_date) AS max_date
    FROM revenue_by_day_base
    GROUP BY neighborhood_id
),

-- -----------------------------------------------------------------------------
-- CTE: date_spine
-- WHAT: Generates a sequence of dates
-- WHY:  Need continuous dates for rolling window to work correctly.
-- 
-- PostgreSQL: generate_series creates date sequences
-- -----------------------------------------------------------------------------
date_spine AS (
    SELECT generate_series(
        '2024-01-01'::DATE, 
        '2026-12-31'::DATE, 
        '1 day'::INTERVAL
    )::DATE AS spine_date
),

-- -----------------------------------------------------------------------------
-- CTE: neighborhood_dates
-- WHAT: Cross join neighborhoods with dates (only within their range)
-- WHY:  Creates complete grid of neighborhood × date combinations.
-- -----------------------------------------------------------------------------
neighborhood_dates AS (
    SELECT
        dr.neighborhood_id,
        ds.spine_date AS revenue_date
    FROM neighborhood_date_range dr
    INNER JOIN date_spine ds
        ON ds.spine_date BETWEEN dr.min_date AND dr.max_date
),

-- -----------------------------------------------------------------------------
-- CTE: revenue_by_day
-- WHAT: Left join actual revenue onto spine (gaps become $0)
-- WHY:  Ensures every day has a value for rolling calculation.
-- -----------------------------------------------------------------------------
revenue_by_day AS (
    SELECT
        nd.neighborhood_id,
        nd.revenue_date,
        COALESCE(rbd.daily_revenue, 0) AS daily_revenue
    FROM neighborhood_dates nd
    LEFT JOIN revenue_by_day_base rbd
        ON rbd.neighborhood_id = nd.neighborhood_id
       AND rbd.revenue_date = nd.revenue_date
),

-- -----------------------------------------------------------------------------
-- CTE: rolling_revenue
-- WHAT: Calculates rolling 7-day sum using window function
-- WHY:  ROWS BETWEEN 6 PRECEDING AND CURRENT ROW = current + 6 prior = 7 days
-- -----------------------------------------------------------------------------
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
    FROM revenue_by_day
),

-- -----------------------------------------------------------------------------
-- CTE: max_dates
-- WHAT: Find last date with actual data per neighborhood
-- WHY:  Filter output to only show last 7 days.
-- -----------------------------------------------------------------------------
max_dates AS (
    SELECT
        neighborhood_id,
        MAX(revenue_date) AS max_date
    FROM revenue_by_day_base
    GROUP BY neighborhood_id
)

-- -----------------------------------------------------------------------------
-- FINAL SELECT: Last 7 days of rolling revenue per neighborhood
-- -----------------------------------------------------------------------------
SELECT
    rr.neighborhood_id,
    rr.revenue_date,
    rr.daily_revenue,
    rr.rolling_7day_revenue
FROM rolling_revenue rr
INNER JOIN max_dates md
    ON rr.neighborhood_id = md.neighborhood_id
   AND rr.revenue_date BETWEEN md.max_date - 6 AND md.max_date
ORDER BY rr.neighborhood_id, rr.revenue_date;


-- =============================================================================
-- QUERY 4: Revenue Distribution Analysis (Percentiles)
-- =============================================================================
-- DASHBOARD USE CASE: Revenue distribution histogram, anomaly detection
-- =============================================================================

WITH revenue_by_day_base AS (
    SELECT
        imp.neighborhood_id,
        rev.revenue_date,
        SUM(rev.revenue_amount) AS daily_revenue
    FROM ad_revenue AS rev
    INNER JOIN ad_impressions AS imp
        ON imp.campaign_id = rev.campaign_id
       AND imp.created_at::DATE = rev.revenue_date
    GROUP BY imp.neighborhood_id, rev.revenue_date
)

SELECT 
    neighborhood_id, 
    revenue_date, 
    daily_revenue, 
    ROUND(CUME_DIST() OVER (
        PARTITION BY neighborhood_id 
        ORDER BY daily_revenue
    )::NUMERIC, 3) AS revenue_percentile
FROM revenue_by_day_base 
ORDER BY neighborhood_id, revenue_date;


-- =============================================================================
-- QUERY 5: Ad Placement Performance
-- =============================================================================
-- DASHBOARD USE CASE: Placement optimization, creative strategy
-- =============================================================================

WITH placement_performance AS (
    SELECT
        ad_placement,
        COUNT(*) FILTER (WHERE event_type = 'IMPRESSION') AS impressions,
        COUNT(*) FILTER (WHERE event_type = 'CLICK') AS clicks,
        COUNT(*) FILTER (WHERE is_conversion = TRUE) AS conversions,
        COUNT(DISTINCT user_id) AS unique_users,
        COUNT(DISTINCT campaign_id) AS campaigns_using
    FROM fct_user_engagement_ad
    GROUP BY ad_placement
)

SELECT
    ad_placement,
    impressions,
    clicks,
    conversions,
    unique_users,
    campaigns_using,
    ROUND(clicks * 100.0 / NULLIF(impressions, 0), 2) AS ctr_percent,
    ROUND(conversions * 100.0 / NULLIF(clicks, 0), 2) AS conversion_rate_percent,
    ROUND(impressions * 1.0 / NULLIF(unique_users, 0), 1) AS avg_impressions_per_user
FROM placement_performance
ORDER BY ctr_percent DESC;


-- =============================================================================
-- QUERY 6: Week-over-Week Revenue Growth
-- =============================================================================
-- DASHBOARD USE CASE: Growth trend chart, executive reporting
-- =============================================================================

WITH weekly_revenue AS (
    SELECT
        DATE_TRUNC('week', revenue_date)::DATE AS week_start,
        SUM(revenue_amount) AS total_revenue,
        SUM(advertiser_spend) AS total_spend,
        SUM(impressions) AS total_impressions,
        SUM(clicks) AS total_clicks
    FROM dim_ad_revenue
    GROUP BY DATE_TRUNC('week', revenue_date)
),

weekly_with_prior AS (
    SELECT
        week_start,
        total_revenue,
        total_spend,
        total_impressions,
        total_clicks,
        LAG(total_revenue) OVER (ORDER BY week_start) AS prior_week_revenue,
        LAG(total_spend) OVER (ORDER BY week_start) AS prior_week_spend
    FROM weekly_revenue
)

SELECT
    week_start,
    total_revenue,
    prior_week_revenue,
    ROUND((total_revenue - prior_week_revenue) / NULLIF(prior_week_revenue, 0) * 100, 1) AS revenue_growth_pct,
    total_spend,
    ROUND(total_revenue / NULLIF(total_spend, 0), 2) AS roas,
    total_impressions,
    total_clicks,
    ROUND(total_clicks * 100.0 / NULLIF(total_impressions, 0), 2) AS ctr_percent
FROM weekly_with_prior
WHERE prior_week_revenue IS NOT NULL
ORDER BY week_start;
