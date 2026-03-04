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
--   - SEMANTIC_LAYER.SILVER.FCT_USER_ENGAGEMENT_AD (from Step 2)
--   - SEMANTIC_LAYER.SILVER.DIM_AD_REVENUE (from Step 1)
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
-- CTE: USER_ENGAGEMENT
-- WHAT: Base engagement data for aggregation
-- WHY:  Single source for all headline calculations.
-- -----------------------------------------------------------------------------
WITH USER_ENGAGEMENT AS (
    SELECT 
        USER_ID,
        NEIGHBORHOOD_ID,
        EVENT_ID,
        EVENT_TYPE,
        CAMPAIGN_ID,
        AD_PLACEMENT,
        DEVICE_TYPE,
        IS_VIEWABLE,
        IS_CONVERSION,
        EVENT_TIMESTAMP,
        EVENT_DATE
    FROM SEMANTIC_LAYER.SILVER.FCT_USER_ENGAGEMENT_AD
),

-- -----------------------------------------------------------------------------
-- CTE: HEADLINE_METRICS
-- WHAT: Calculates all headline KPIs in one pass
-- WHY:  Efficient single-scan aggregation for dashboard cards.
--
-- INTERVIEW NOTE: These are the metrics that appear in big font at the
--                 top of every ad dashboard.
-- -----------------------------------------------------------------------------
HEADLINE_METRICS AS (
    SELECT 
        -- Metric 1: Active Campaigns (last 7 days)
        -- WHY: Shows current platform health
        COUNT(DISTINCT 
            CASE 
                WHEN EVENT_TYPE = 'IMPRESSION'
                 AND EVENT_DATE >= CURRENT_DATE - 7
                THEN CAMPAIGN_ID
            END
        ) AS ACTIVE_CAMPAIGNS_LAST_7_DAYS,

        -- Metric 2: Unique Users Reached
        -- WHY: Measures ad reach/penetration
        COUNT(DISTINCT USER_ID) AS TOTAL_UNIQUE_USERS,

        -- Metric 3: Total Impressions
        -- WHY: Volume metric for platform scale
        COUNT_IF(EVENT_TYPE = 'IMPRESSION') AS TOTAL_IMPRESSIONS,

        -- Metric 4: Average Frequency
        -- WHY: How many times each user sees ads (too high = ad fatigue)
        -- FORMULA: impressions / unique users
        ROUND(
            COUNT_IF(EVENT_TYPE = 'IMPRESSION')::FLOAT / 
            NULLIF(COUNT(DISTINCT USER_ID), 0),
        1) AS AVERAGE_FREQUENCY,

        -- Metric 5: Conversion Rate
        -- WHY: Ultimate success metric (clicks that become customers)
        -- FORMULA: conversions / clicks * 100
        ROUND(
            COUNT_IF(IS_CONVERSION = TRUE) * 100.0 / 
            NULLIF(COUNT_IF(EVENT_TYPE = 'CLICK'), 0),
        2) AS CONVERSION_RATE_PERCENT
        
    FROM USER_ENGAGEMENT
)

SELECT * FROM HEADLINE_METRICS;


-- =============================================================================
-- QUERY 2: Impressions by Device Type
-- =============================================================================
-- DASHBOARD USE CASE: Device breakdown pie chart
-- 
-- WHY DEVICE BREAKDOWN:
--   - Optimize ad creative for dominant device
--   - Identify underperforming platforms
--   - Guide budget allocation by device
-- =============================================================================

-- -----------------------------------------------------------------------------
-- CTE: USER_ENGAGEMENT
-- WHAT: Base data with device type
-- WHY:  Simple aggregation pattern.
-- -----------------------------------------------------------------------------
WITH USER_ENGAGEMENT AS (
    SELECT DEVICE_TYPE, EVENT_TYPE 
    FROM SEMANTIC_LAYER.SILVER.FCT_USER_ENGAGEMENT_AD
),

-- -----------------------------------------------------------------------------
-- CTE: DEVICE_BREAKDOWN
-- WHAT: Impressions and clicks by device
-- WHY:  Need both for CTR calculation by device.
-- -----------------------------------------------------------------------------
DEVICE_BREAKDOWN AS (
    SELECT 
        DEVICE_TYPE, 
        COUNT_IF(EVENT_TYPE = 'IMPRESSION') AS IMPRESSIONS,
        COUNT_IF(EVENT_TYPE = 'CLICK') AS CLICKS
    FROM USER_ENGAGEMENT 
    GROUP BY DEVICE_TYPE
)

-- -----------------------------------------------------------------------------
-- FINAL SELECT: Device metrics with percentages
-- -----------------------------------------------------------------------------
SELECT
    DEVICE_TYPE,
    IMPRESSIONS,
    CLICKS,
    ROUND(CLICKS * 100.0 / NULLIF(IMPRESSIONS, 0), 2) AS CTR_PERCENT,
    ROUND(IMPRESSIONS * 100.0 / SUM(IMPRESSIONS) OVER (), 2) AS PCT_OF_IMPRESSIONS
FROM DEVICE_BREAKDOWN
ORDER BY IMPRESSIONS DESC;


-- =============================================================================
-- QUERY 3: Rolling 7-Day Revenue by Neighborhood
-- =============================================================================
-- DASHBOARD USE CASE: Revenue trend chart with smoothing
-- 
-- WHY ROLLING WINDOWS:
--   - Smooths daily volatility (weekends, holidays)
--   - Shows true trend direction
--   - Industry standard for revenue dashboards
--
-- TECHNICAL CHALLENGE:
--   - Revenue is at campaign level, not neighborhood
--   - Must join through impressions to get neighborhood
--   - Must fill gaps (days with no revenue = $0, not NULL)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- CTE: REVENUE_BY_DAY_BASE
-- WHAT: Actual revenue data joined to get neighborhood context
-- WHY:  Revenue table doesn't have neighborhood_id directly.
--       We join through impressions to attribute revenue to neighborhoods.
-- 
-- ATTRIBUTION LOGIC: Revenue is attributed to neighborhoods where the
--                    campaign's ads were shown on that day.
-- -----------------------------------------------------------------------------
WITH REVENUE_BY_DAY_BASE AS (
    SELECT
        impressions.NEIGHBORHOOD_ID,
        revenue.REVENUE_DATE,
        SUM(revenue.REVENUE_AMOUNT) AS DAILY_REVENUE
    FROM SOURCES.NEXTDOOR_ADS_CAMPAIGN.AD_REVENUE AS revenue
    INNER JOIN SOURCES.NEXTDOOR_ADS_CAMPAIGN.AD_IMPRESSIONS AS impressions
        ON impressions.CAMPAIGN_ID = revenue.CAMPAIGN_ID
       AND DATE(impressions.CREATED_AT) = revenue.REVENUE_DATE
    GROUP BY
        impressions.NEIGHBORHOOD_ID,
        revenue.REVENUE_DATE
),

-- -----------------------------------------------------------------------------
-- CTE: NEIGHBORHOOD_DATE_RANGE
-- WHAT: Min/max revenue dates per neighborhood
-- WHY:  We only want to create a date spine within actual data range.
--       Avoids inflating with zeros before campaign started.
-- -----------------------------------------------------------------------------
NEIGHBORHOOD_DATE_RANGE AS (
    SELECT
        NEIGHBORHOOD_ID,
        MIN(REVENUE_DATE) AS MIN_DATE,
        MAX(REVENUE_DATE) AS MAX_DATE
    FROM REVENUE_BY_DAY_BASE
    GROUP BY NEIGHBORHOOD_ID
),

-- -----------------------------------------------------------------------------
-- CTE: DATE_SPINE
-- WHAT: Generates a sequence of dates
-- WHY:  Need continuous dates for rolling window to work correctly.
--
-- SNOWFLAKE: TABLE(GENERATOR(ROWCOUNT => N)) creates N rows
--            SEQ4() gives sequence 0, 1, 2, ...
--            DATEADD adds those days to start date
-- -----------------------------------------------------------------------------
DATE_SPINE AS (
    SELECT
        DATEADD(day, SEQ4(), '2024-01-01') AS SPINE_DATE
    FROM TABLE(GENERATOR(ROWCOUNT => 2000))
),

-- -----------------------------------------------------------------------------
-- CTE: NEIGHBORHOOD_DATES
-- WHAT: Cross join neighborhoods with dates (only within their range)
-- WHY:  Creates complete grid of neighborhood × date combinations.
-- -----------------------------------------------------------------------------
NEIGHBORHOOD_DATES AS (
    SELECT
        date_range.NEIGHBORHOOD_ID,
        spine.SPINE_DATE AS REVENUE_DATE
    FROM NEIGHBORHOOD_DATE_RANGE AS date_range
    INNER JOIN DATE_SPINE AS spine
        ON spine.SPINE_DATE BETWEEN date_range.MIN_DATE AND date_range.MAX_DATE
),

-- -----------------------------------------------------------------------------
-- CTE: REVENUE_BY_DAY
-- WHAT: Left join actual revenue onto spine (gaps become $0)
-- WHY:  Ensures every day has a value for rolling calculation.
--
-- COALESCE: Converts NULL (no data) to 0 (zero revenue)
-- -----------------------------------------------------------------------------
REVENUE_BY_DAY AS (
    SELECT
        nd.NEIGHBORHOOD_ID,
        nd.REVENUE_DATE,
        COALESCE(rbd.DAILY_REVENUE, 0) AS DAILY_REVENUE
    FROM NEIGHBORHOOD_DATES nd
    LEFT JOIN REVENUE_BY_DAY_BASE rbd
        ON rbd.NEIGHBORHOOD_ID = nd.NEIGHBORHOOD_ID
       AND rbd.REVENUE_DATE = nd.REVENUE_DATE
),

-- -----------------------------------------------------------------------------
-- CTE: ROLLING_REVENUE
-- WHAT: Calculates rolling 7-day sum using window function
-- WHY:  ROWS BETWEEN 6 PRECEDING AND CURRENT ROW = current + 6 prior = 7 days
--
-- WINDOW FUNCTION BREAKDOWN:
--   SUM(DAILY_REVENUE) OVER (
--       PARTITION BY NEIGHBORHOOD_ID     -- Reset for each neighborhood
--       ORDER BY REVENUE_DATE            -- Sort chronologically
--       ROWS BETWEEN 6 PRECEDING AND CURRENT ROW  -- 7-day window
--   )
-- -----------------------------------------------------------------------------
ROLLING_REVENUE AS (
    SELECT
        NEIGHBORHOOD_ID,
        REVENUE_DATE,
        DAILY_REVENUE,
        SUM(DAILY_REVENUE) OVER (
            PARTITION BY NEIGHBORHOOD_ID
            ORDER BY REVENUE_DATE
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) AS ROLLING_7DAY_REVENUE
    FROM REVENUE_BY_DAY
),

-- -----------------------------------------------------------------------------
-- CTE: MAX_DATES
-- WHAT: Find last date with actual data per neighborhood
-- WHY:  Filter output to only show last 7 days (most recent trend).
-- -----------------------------------------------------------------------------
MAX_DATES AS (
    SELECT
        NEIGHBORHOOD_ID,
        MAX(REVENUE_DATE) AS MAX_DATE
    FROM REVENUE_BY_DAY_BASE
    GROUP BY NEIGHBORHOOD_ID
)

-- -----------------------------------------------------------------------------
-- FINAL SELECT: Last 7 days of rolling revenue per neighborhood
-- JOIN LOGIC: Only show dates within 6 days of the max date
-- -----------------------------------------------------------------------------
SELECT
    rr.NEIGHBORHOOD_ID,
    rr.REVENUE_DATE,
    rr.DAILY_REVENUE,
    rr.ROLLING_7DAY_REVENUE
FROM ROLLING_REVENUE rr
INNER JOIN MAX_DATES md
    ON rr.NEIGHBORHOOD_ID = md.NEIGHBORHOOD_ID
   AND rr.REVENUE_DATE BETWEEN DATEADD(day, -6, md.MAX_DATE) AND md.MAX_DATE
ORDER BY rr.NEIGHBORHOOD_ID, rr.REVENUE_DATE;


-- =============================================================================
-- QUERY 4: Revenue Distribution Analysis (Percentiles)
-- =============================================================================
-- DASHBOARD USE CASE: Revenue distribution histogram, anomaly detection
-- 
-- WHY PERCENTILES:
--   - Understand typical daily revenue (median vs mean)
--   - Identify outlier days (above 95th percentile = investigate)
--   - Set realistic revenue targets
-- =============================================================================

-- -----------------------------------------------------------------------------
-- CTE: REVENUE_BY_DAY_BASE
-- WHAT: Same attribution logic as Query 3
-- WHY:  Get daily revenue by neighborhood.
-- -----------------------------------------------------------------------------
WITH REVENUE_BY_DAY_BASE AS (
    SELECT
        impressions.NEIGHBORHOOD_ID,
        revenue.REVENUE_DATE,
        SUM(revenue.REVENUE_AMOUNT) AS DAILY_REVENUE
    FROM SOURCES.NEXTDOOR_ADS_CAMPAIGN.AD_REVENUE AS revenue
    INNER JOIN SOURCES.NEXTDOOR_ADS_CAMPAIGN.AD_IMPRESSIONS AS impressions
        ON impressions.CAMPAIGN_ID = revenue.CAMPAIGN_ID
       AND DATE(impressions.CREATED_AT) = revenue.REVENUE_DATE
    GROUP BY impressions.NEIGHBORHOOD_ID, revenue.REVENUE_DATE
)

-- -----------------------------------------------------------------------------
-- FINAL SELECT: Percentile distribution with CUME_DIST
-- 
-- CUME_DIST: Cumulative distribution (what % of values are <= this one)
-- Use case: "This day was in the top 10% of revenue days"
-- -----------------------------------------------------------------------------
SELECT 
    NEIGHBORHOOD_ID, 
    REVENUE_DATE, 
    DAILY_REVENUE, 
    ROUND(CUME_DIST() OVER (
        PARTITION BY NEIGHBORHOOD_ID 
        ORDER BY DAILY_REVENUE
    ), 3) AS REVENUE_PERCENTILE
FROM REVENUE_BY_DAY_BASE 
ORDER BY NEIGHBORHOOD_ID, REVENUE_DATE;


-- =============================================================================
-- QUERY 5: Ad Placement Performance
-- =============================================================================
-- DASHBOARD USE CASE: Placement optimization, creative strategy
-- 
-- WHY PLACEMENT ANALYSIS:
--   - Notification ads vs Feed ads vs Search ads perform differently
--   - Optimize where to show ads for better CTR
-- =============================================================================

WITH PLACEMENT_PERFORMANCE AS (
    SELECT
        AD_PLACEMENT,
        COUNT_IF(EVENT_TYPE = 'IMPRESSION') AS IMPRESSIONS,
        COUNT_IF(EVENT_TYPE = 'CLICK') AS CLICKS,
        COUNT_IF(IS_CONVERSION = TRUE) AS CONVERSIONS,
        COUNT(DISTINCT USER_ID) AS UNIQUE_USERS,
        COUNT(DISTINCT CAMPAIGN_ID) AS CAMPAIGNS_USING
    FROM SEMANTIC_LAYER.SILVER.FCT_USER_ENGAGEMENT_AD
    GROUP BY AD_PLACEMENT
)

SELECT
    AD_PLACEMENT,
    IMPRESSIONS,
    CLICKS,
    CONVERSIONS,
    UNIQUE_USERS,
    CAMPAIGNS_USING,
    ROUND(CLICKS * 100.0 / NULLIF(IMPRESSIONS, 0), 2) AS CTR_PERCENT,
    ROUND(CONVERSIONS * 100.0 / NULLIF(CLICKS, 0), 2) AS CONVERSION_RATE_PERCENT,
    ROUND(IMPRESSIONS * 1.0 / NULLIF(UNIQUE_USERS, 0), 1) AS AVG_IMPRESSIONS_PER_USER
FROM PLACEMENT_PERFORMANCE
ORDER BY CTR_PERCENT DESC;


-- =============================================================================
-- QUERY 6: Week-over-Week Revenue Growth
-- =============================================================================
-- DASHBOARD USE CASE: Growth trend chart, executive reporting
-- =============================================================================

-- -----------------------------------------------------------------------------
-- CTE: WEEKLY_REVENUE
-- WHAT: Aggregate revenue by week
-- WHY:  Weekly granularity smooths daily noise.
-- -----------------------------------------------------------------------------
WITH WEEKLY_REVENUE AS (
    SELECT
        DATE_TRUNC('week', REVENUE_DATE) AS WEEK_START,
        SUM(REVENUE_AMOUNT) AS TOTAL_REVENUE,
        SUM(ADVERTISER_SPEND) AS TOTAL_SPEND,
        SUM(IMPRESSIONS) AS TOTAL_IMPRESSIONS,
        SUM(CLICKS) AS TOTAL_CLICKS
    FROM SEMANTIC_LAYER.SILVER.DIM_AD_REVENUE
    GROUP BY DATE_TRUNC('week', REVENUE_DATE)
),

-- -----------------------------------------------------------------------------
-- CTE: WEEKLY_WITH_PRIOR
-- WHAT: Add prior week values using LAG
-- WHY:  Need both weeks to calculate growth rate.
-- -----------------------------------------------------------------------------
WEEKLY_WITH_PRIOR AS (
    SELECT
        WEEK_START,
        TOTAL_REVENUE,
        TOTAL_SPEND,
        TOTAL_IMPRESSIONS,
        TOTAL_CLICKS,
        LAG(TOTAL_REVENUE) OVER (ORDER BY WEEK_START) AS PRIOR_WEEK_REVENUE,
        LAG(TOTAL_SPEND) OVER (ORDER BY WEEK_START) AS PRIOR_WEEK_SPEND
    FROM WEEKLY_REVENUE
)

-- -----------------------------------------------------------------------------
-- FINAL SELECT: Growth rates and ROAS
-- -----------------------------------------------------------------------------
SELECT
    WEEK_START,
    TOTAL_REVENUE,
    PRIOR_WEEK_REVENUE,
    ROUND((TOTAL_REVENUE - PRIOR_WEEK_REVENUE) / NULLIF(PRIOR_WEEK_REVENUE, 0) * 100, 1) AS REVENUE_GROWTH_PCT,
    TOTAL_SPEND,
    ROUND(TOTAL_REVENUE / NULLIF(TOTAL_SPEND, 0), 2) AS ROAS,
    TOTAL_IMPRESSIONS,
    TOTAL_CLICKS,
    ROUND(TOTAL_CLICKS * 100.0 / NULLIF(TOTAL_IMPRESSIONS, 0), 2) AS CTR_PERCENT
FROM WEEKLY_WITH_PRIOR
WHERE PRIOR_WEEK_REVENUE IS NOT NULL
ORDER BY WEEK_START;
