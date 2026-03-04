-- ============================================================================
-- STEP 3: GOLD LAYER - Ad Performance Metrics
-- ============================================================================
-- PURPOSE: Calculate daily ad performance metrics with revenue for
--          campaign monitoring dashboards.
--
-- WHY THESE METRICS:
--   - CTR: Primary indicator of ad relevance
--   - Revenue: Business outcome we're optimizing for
--   - Neighborhood breakdown: Identify high-performing markets
--
-- DEPENDS ON:
--   - fct_user_engagement_ad (from Step 2)
--   - dim_ad_revenue (from Step 1)
--   - dim_campaigns (from Step 1)
--
-- INTERVIEW TIP: Ad tech dashboards are all about CTR, CPC, CPA, and ROAS.
--                Be ready to explain what each metric means and why it matters.
-- ============================================================================


-- =============================================================================
-- QUERY 1: Daily Engagement & Revenue Summary
-- =============================================================================
-- DASHBOARD USE CASE: Daily KPI cards, trend charts
-- 
-- METRICS:
--   - Total impressions (reach)
--   - Total clicks (engagement)
--   - CTR (quality)
--   - Revenue (outcome)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- CTE: engagement_by_day
-- WHAT: Aggregates impressions and clicks per day
-- WHY:  Base metrics for CTR calculation. Grouped by day for time-series.
-- -----------------------------------------------------------------------------
WITH engagement_by_day AS (
    SELECT
        event_date,
        COUNT(*) FILTER (WHERE event_type = 'IMPRESSION') AS total_impressions,
        COUNT(*) FILTER (WHERE event_type = 'CLICK') AS total_clicks
    FROM fct_user_engagement_ad
    GROUP BY event_date
),

-- -----------------------------------------------------------------------------
-- CTE: revenue_by_day
-- WHAT: Aggregates revenue per day across all campaigns
-- WHY:  Need to join with engagement to get full picture.
-- -----------------------------------------------------------------------------
revenue_by_day AS (
    SELECT
        revenue_date,
        SUM(revenue_amount) AS total_revenue,
        SUM(advertiser_spend) AS total_spend
    FROM dim_ad_revenue
    GROUP BY revenue_date
)

-- -----------------------------------------------------------------------------
-- FINAL SELECT: Daily summary with CTR
-- CTR FORMULA: (clicks / impressions) * 100
-- ROAS: Return on Ad Spend = revenue / spend
-- -----------------------------------------------------------------------------
SELECT
    eng.event_date,
    eng.total_impressions,
    eng.total_clicks,
    ROUND(eng.total_clicks * 100.0 / NULLIF(eng.total_impressions, 0), 2) AS ctr_percent,
    COALESCE(rev.total_revenue, 0) AS total_revenue,
    COALESCE(rev.total_spend, 0) AS total_spend,
    ROUND(COALESCE(rev.total_revenue, 0) / NULLIF(rev.total_spend, 0), 2) AS roas
FROM engagement_by_day eng
LEFT JOIN revenue_by_day rev
    ON eng.event_date = rev.revenue_date
ORDER BY eng.event_date;


-- =============================================================================
-- QUERY 2: Daily Performance by Campaign & Neighborhood
-- =============================================================================
-- DASHBOARD USE CASE: Campaign performance table, neighborhood heatmap
-- 
-- WHY THIS GRANULARITY:
--   - Campaign level: Which campaigns are performing?
--   - Neighborhood level: Which markets are most valuable?
-- =============================================================================

-- -----------------------------------------------------------------------------
-- CTE: engagement_by_day
-- WHAT: Daily impressions/clicks by campaign and neighborhood
-- WHY:  Most granular level for drill-down analysis.
-- -----------------------------------------------------------------------------
WITH engagement_by_day AS (
    SELECT
        event_date,
        campaign_id,
        neighborhood_id,
        COUNT(*) FILTER (WHERE event_type = 'IMPRESSION') AS total_impressions,
        COUNT(*) FILTER (WHERE event_type = 'CLICK') AS total_clicks,
        COUNT(*) FILTER (WHERE is_conversion = TRUE) AS total_conversions
    FROM fct_user_engagement_ad
    GROUP BY event_date, campaign_id, neighborhood_id
),

-- -----------------------------------------------------------------------------
-- CTE: revenue_by_day
-- WHAT: Daily revenue by campaign
-- WHY:  Revenue is tracked at campaign level (not neighborhood).
-- -----------------------------------------------------------------------------
revenue_by_day AS (
    SELECT
        revenue_date,
        campaign_id,
        SUM(revenue_amount) AS total_revenue
    FROM dim_ad_revenue
    GROUP BY revenue_date, campaign_id
)

-- -----------------------------------------------------------------------------
-- FINAL SELECT: Enriched with campaign and neighborhood names
-- WHY LEFT JOINs: Not all engagement may have revenue (lag in reporting)
-- -----------------------------------------------------------------------------
SELECT
    eng.event_date,
    eng.campaign_id,
    camp.campaign_name,
    camp.business_category,
    camp.campaign_objective,
    eng.neighborhood_id,
    nbh.name AS neighborhood_name,
    nbh.city,
    nbh.state,
    eng.total_impressions,
    eng.total_clicks,
    eng.total_conversions,
    ROUND(eng.total_clicks * 100.0 / NULLIF(eng.total_impressions, 0), 2) AS ctr,
    ROUND(eng.total_conversions * 100.0 / NULLIF(eng.total_clicks, 0), 2) AS conversion_rate,
    COALESCE(rev.total_revenue, 0) AS total_revenue
FROM engagement_by_day eng
LEFT JOIN revenue_by_day rev
    ON eng.event_date = rev.revenue_date
   AND eng.campaign_id = rev.campaign_id
LEFT JOIN dim_campaigns camp
    ON eng.campaign_id = camp.campaign_id
LEFT JOIN neighborhoods nbh
    ON eng.neighborhood_id = nbh.neighborhood_id
ORDER BY eng.event_date, eng.campaign_id, eng.neighborhood_id;


-- =============================================================================
-- QUERY 3: Top 5 Revenue Days per Neighborhood
-- =============================================================================
-- DASHBOARD USE CASE: Best performing days analysis, anomaly detection
-- 
-- WHY TOP N:
--   - Identify what made those days successful
--   - Find patterns (day of week, campaigns running, etc.)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- CTE: engagement_by_day
-- WHAT: Same granular data as Query 2
-- WHY:  Reuse pattern - engagement at day/campaign/neighborhood level.
-- -----------------------------------------------------------------------------
WITH engagement_by_day AS (
    SELECT
        event_date,
        campaign_id,
        neighborhood_id,
        COUNT(*) FILTER (WHERE event_type = 'IMPRESSION') AS total_impressions,
        COUNT(*) FILTER (WHERE event_type = 'CLICK') AS total_clicks
    FROM fct_user_engagement_ad
    GROUP BY event_date, campaign_id, neighborhood_id
),

revenue_by_day AS (
    SELECT
        revenue_date,
        campaign_id,
        SUM(revenue_amount) AS total_revenue
    FROM dim_ad_revenue
    GROUP BY revenue_date, campaign_id
),

gold_ads_daily AS (
    SELECT
        eng.event_date,
        eng.campaign_id,
        camp.campaign_name,
        eng.neighborhood_id,
        nbh.name AS neighborhood_name,
        nbh.city,
        nbh.state,
        eng.total_impressions,
        eng.total_clicks,
        ROUND(eng.total_clicks * 100.0 / NULLIF(eng.total_impressions, 0), 1) AS ctr,
        COALESCE(rev.total_revenue, 0) AS total_revenue
    FROM engagement_by_day eng
    LEFT JOIN revenue_by_day rev
        ON eng.event_date = rev.revenue_date
       AND eng.campaign_id = rev.campaign_id
    LEFT JOIN dim_campaigns camp
        ON eng.campaign_id = camp.campaign_id
    LEFT JOIN neighborhoods nbh
        ON eng.neighborhood_id = nbh.neighborhood_id
),

-- -----------------------------------------------------------------------------
-- CTE: ranked_dates
-- WHAT: Ranks dates by revenue within each neighborhood
-- WHY:  ROW_NUMBER enables "Top N" filtering.
-- 
-- PARTITION BY: Each neighborhood gets its own ranking
-- ORDER BY: Highest revenue first
-- -----------------------------------------------------------------------------
ranked_dates AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY neighborhood_id 
            ORDER BY total_revenue DESC
        ) AS rn
    FROM gold_ads_daily
)

-- -----------------------------------------------------------------------------
-- FINAL SELECT: Top 5 dates per neighborhood
-- INTERVIEW TIP: Classic "Top N per group" pattern using ROW_NUMBER
-- -----------------------------------------------------------------------------
SELECT
    neighborhood_id,
    neighborhood_name,
    city,
    state,
    event_date,
    campaign_id,
    campaign_name,
    total_impressions,
    total_clicks,
    ctr,
    total_revenue
FROM ranked_dates
WHERE rn <= 5
ORDER BY neighborhood_id, total_revenue DESC;


-- =============================================================================
-- QUERY 4: Top 5 Neighborhoods by Total Revenue
-- =============================================================================
-- DASHBOARD USE CASE: Revenue leaderboard, market prioritization
-- =============================================================================

WITH engagement_by_day AS (
    SELECT
        event_date,
        campaign_id,
        neighborhood_id,
        COUNT(*) FILTER (WHERE event_type = 'IMPRESSION') AS total_impressions,
        COUNT(*) FILTER (WHERE event_type = 'CLICK') AS total_clicks
    FROM fct_user_engagement_ad
    GROUP BY event_date, campaign_id, neighborhood_id
),

revenue_by_day AS (
    SELECT
        revenue_date,
        campaign_id,
        SUM(revenue_amount) AS total_revenue
    FROM dim_ad_revenue
    GROUP BY revenue_date, campaign_id
),

gold_ads_daily AS (
    SELECT
        eng.neighborhood_id,
        nbh.name AS neighborhood_name,
        COALESCE(rev.total_revenue, 0) AS total_revenue
    FROM engagement_by_day eng
    LEFT JOIN revenue_by_day rev
        ON eng.event_date = rev.revenue_date
       AND eng.campaign_id = rev.campaign_id
    LEFT JOIN neighborhoods nbh
        ON eng.neighborhood_id = nbh.neighborhood_id
),

revenue_by_neighborhood AS (
    SELECT 
        neighborhood_id, 
        neighborhood_name, 
        SUM(total_revenue) AS revenue, 
        ROW_NUMBER() OVER (ORDER BY SUM(total_revenue) DESC) AS rn 
    FROM gold_ads_daily 
    GROUP BY neighborhood_id, neighborhood_name
)

SELECT 
    neighborhood_name, 
    revenue 
FROM revenue_by_neighborhood 
WHERE rn <= 5
ORDER BY revenue DESC;


-- =============================================================================
-- QUERY 5: Campaign Performance Summary
-- =============================================================================
-- DASHBOARD USE CASE: Campaign health scorecard
-- =============================================================================

WITH campaign_engagement AS (
    SELECT
        campaign_id,
        COUNT(*) FILTER (WHERE event_type = 'IMPRESSION') AS total_impressions,
        COUNT(*) FILTER (WHERE event_type = 'CLICK') AS total_clicks,
        COUNT(*) FILTER (WHERE is_conversion = TRUE) AS total_conversions,
        COUNT(DISTINCT user_id) AS unique_users_reached,
        COUNT(DISTINCT neighborhood_id) AS neighborhoods_reached
    FROM fct_user_engagement_ad
    GROUP BY campaign_id
),

campaign_revenue AS (
    SELECT
        campaign_id,
        SUM(revenue_amount) AS total_revenue,
        SUM(advertiser_spend) AS total_spend,
        AVG(ctr) AS avg_daily_ctr,
        AVG(conversion_rate) AS avg_daily_conversion_rate
    FROM dim_ad_revenue
    GROUP BY campaign_id
)

SELECT
    c.campaign_id,
    c.campaign_name,
    c.advertiser_name,
    c.business_category,
    c.campaign_objective,
    c.budget_tier,
    c.campaign_lifecycle_status,
    c.total_budget,
    
    -- Engagement metrics
    COALESCE(e.total_impressions, 0) AS total_impressions,
    COALESCE(e.total_clicks, 0) AS total_clicks,
    COALESCE(e.total_conversions, 0) AS total_conversions,
    COALESCE(e.unique_users_reached, 0) AS unique_users_reached,
    COALESCE(e.neighborhoods_reached, 0) AS neighborhoods_reached,
    
    -- Calculated rates
    ROUND(e.total_clicks * 100.0 / NULLIF(e.total_impressions, 0), 2) AS ctr_percent,
    ROUND(e.total_conversions * 100.0 / NULLIF(e.total_clicks, 0), 2) AS conversion_rate_percent,
    
    -- Revenue metrics
    COALESCE(r.total_revenue, 0) AS total_revenue,
    COALESCE(r.total_spend, 0) AS total_spend,
    ROUND(COALESCE(r.total_revenue, 0) / NULLIF(r.total_spend, 0), 2) AS roas,
    
    -- Budget utilization
    ROUND(COALESCE(r.total_spend, 0) / NULLIF(c.total_budget, 0) * 100, 1) AS budget_utilization_pct

FROM dim_campaigns c
LEFT JOIN campaign_engagement e ON c.campaign_id = e.campaign_id
LEFT JOIN campaign_revenue r ON c.campaign_id = r.campaign_id
ORDER BY total_revenue DESC;
