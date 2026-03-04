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
--   - SEMANTIC_LAYER.SILVER.FCT_USER_ENGAGEMENT_AD (from Step 2)
--   - SEMANTIC_LAYER.SILVER.DIM_AD_REVENUE (from Step 1)
--   - SEMANTIC_LAYER.SILVER.DIM_CAMPAIGNS (from Step 1)
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
-- CTE: ENGAGEMENT_BY_DAY
-- WHAT: Aggregates impressions and clicks per day
-- WHY:  Base metrics for CTR calculation. Grouped by day for time-series.
-- -----------------------------------------------------------------------------
WITH ENGAGEMENT_BY_DAY AS (
    SELECT
        EVENT_DATE,
        COUNT_IF(EVENT_TYPE = 'IMPRESSION') AS TOTAL_IMPRESSIONS,
        COUNT_IF(EVENT_TYPE = 'CLICK') AS TOTAL_CLICKS
    FROM SEMANTIC_LAYER.SILVER.FCT_USER_ENGAGEMENT_AD
    GROUP BY EVENT_DATE
),

-- -----------------------------------------------------------------------------
-- CTE: REVENUE_BY_DAY
-- WHAT: Aggregates revenue per day across all campaigns
-- WHY:  Need to join with engagement to get full picture.
-- -----------------------------------------------------------------------------
REVENUE_BY_DAY AS (
    SELECT
        REVENUE_DATE,
        SUM(REVENUE_AMOUNT) AS TOTAL_REVENUE,
        SUM(ADVERTISER_SPEND) AS TOTAL_SPEND
    FROM SEMANTIC_LAYER.SILVER.DIM_AD_REVENUE
    GROUP BY REVENUE_DATE
)

-- -----------------------------------------------------------------------------
-- FINAL SELECT: Daily summary with CTR
-- CTR FORMULA: (clicks / impressions) * 100
-- ROAS: Return on Ad Spend = revenue / spend
-- -----------------------------------------------------------------------------
SELECT
    ENG.EVENT_DATE,
    ENG.TOTAL_IMPRESSIONS,
    ENG.TOTAL_CLICKS,
    ROUND(ENG.TOTAL_CLICKS * 100.0 / NULLIF(ENG.TOTAL_IMPRESSIONS, 0), 2) AS CTR_PERCENT,
    COALESCE(REV.TOTAL_REVENUE, 0) AS TOTAL_REVENUE,
    COALESCE(REV.TOTAL_SPEND, 0) AS TOTAL_SPEND,
    ROUND(COALESCE(REV.TOTAL_REVENUE, 0) / NULLIF(REV.TOTAL_SPEND, 0), 2) AS ROAS
FROM ENGAGEMENT_BY_DAY ENG
LEFT JOIN REVENUE_BY_DAY REV
    ON ENG.EVENT_DATE = REV.REVENUE_DATE
ORDER BY ENG.EVENT_DATE;


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
-- CTE: ENGAGEMENT_BY_DAY
-- WHAT: Daily impressions/clicks by campaign and neighborhood
-- WHY:  Most granular level for drill-down analysis.
-- -----------------------------------------------------------------------------
WITH ENGAGEMENT_BY_DAY AS (
    SELECT
        EVENT_DATE,
        CAMPAIGN_ID,
        NEIGHBORHOOD_ID,
        COUNT_IF(EVENT_TYPE = 'IMPRESSION') AS TOTAL_IMPRESSIONS,
        COUNT_IF(EVENT_TYPE = 'CLICK') AS TOTAL_CLICKS,
        COUNT_IF(IS_CONVERSION = TRUE) AS TOTAL_CONVERSIONS
    FROM SEMANTIC_LAYER.SILVER.FCT_USER_ENGAGEMENT_AD
    GROUP BY EVENT_DATE, CAMPAIGN_ID, NEIGHBORHOOD_ID
),

-- -----------------------------------------------------------------------------
-- CTE: REVENUE_BY_DAY
-- WHAT: Daily revenue by campaign
-- WHY:  Revenue is tracked at campaign level (not neighborhood).
--       We'll attribute it proportionally or just join for totals.
-- -----------------------------------------------------------------------------
REVENUE_BY_DAY AS (
    SELECT
        REVENUE_DATE,
        CAMPAIGN_ID,
        SUM(REVENUE_AMOUNT) AS TOTAL_REVENUE
    FROM SEMANTIC_LAYER.SILVER.DIM_AD_REVENUE
    GROUP BY REVENUE_DATE, CAMPAIGN_ID
)

-- -----------------------------------------------------------------------------
-- FINAL SELECT: Enriched with campaign and neighborhood names
-- WHY LEFT JOINs: Not all engagement may have revenue (lag in reporting)
-- -----------------------------------------------------------------------------
SELECT
    ENG.EVENT_DATE,
    ENG.CAMPAIGN_ID,
    CAMP.CAMPAIGN_NAME,
    CAMP.BUSINESS_CATEGORY,
    CAMP.CAMPAIGN_OBJECTIVE,
    ENG.NEIGHBORHOOD_ID,
    NBH.NAME AS NEIGHBORHOOD_NAME,
    NBH.CITY,
    NBH.STATE,
    ENG.TOTAL_IMPRESSIONS,
    ENG.TOTAL_CLICKS,
    ENG.TOTAL_CONVERSIONS,
    ROUND(ENG.TOTAL_CLICKS * 100.0 / NULLIF(ENG.TOTAL_IMPRESSIONS, 0), 2) AS CTR,
    ROUND(ENG.TOTAL_CONVERSIONS * 100.0 / NULLIF(ENG.TOTAL_CLICKS, 0), 2) AS CONVERSION_RATE,
    COALESCE(REV.TOTAL_REVENUE, 0) AS TOTAL_REVENUE
FROM ENGAGEMENT_BY_DAY ENG
LEFT JOIN REVENUE_BY_DAY REV
    ON ENG.EVENT_DATE = REV.REVENUE_DATE
   AND ENG.CAMPAIGN_ID = REV.CAMPAIGN_ID
LEFT JOIN SEMANTIC_LAYER.SILVER.DIM_CAMPAIGNS CAMP
    ON ENG.CAMPAIGN_ID = CAMP.CAMPAIGN_ID
LEFT JOIN SOURCES.NEXTDOOR_ADS_CAMPAIGN.NEIGHBORHOOD NBH
    ON ENG.NEIGHBORHOOD_ID = NBH.NEIGHBORHOOD_ID
ORDER BY ENG.EVENT_DATE, ENG.CAMPAIGN_ID, ENG.NEIGHBORHOOD_ID;


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
-- CTE: ENGAGEMENT_BY_DAY
-- WHAT: Same granular data as Query 2
-- WHY:  Reuse pattern - engagement at day/campaign/neighborhood level.
-- -----------------------------------------------------------------------------
WITH ENGAGEMENT_BY_DAY AS (
    SELECT
        EVENT_DATE,
        CAMPAIGN_ID,
        NEIGHBORHOOD_ID,
        COUNT_IF(EVENT_TYPE = 'IMPRESSION') AS TOTAL_IMPRESSIONS,
        COUNT_IF(EVENT_TYPE = 'CLICK') AS TOTAL_CLICKS
    FROM SEMANTIC_LAYER.SILVER.FCT_USER_ENGAGEMENT_AD
    GROUP BY EVENT_DATE, CAMPAIGN_ID, NEIGHBORHOOD_ID
),

-- -----------------------------------------------------------------------------
-- CTE: REVENUE_BY_DAY
-- WHAT: Revenue aggregated by date and campaign
-- WHY:  Same pattern for joining.
-- -----------------------------------------------------------------------------
REVENUE_BY_DAY AS (
    SELECT
        REVENUE_DATE,
        CAMPAIGN_ID,
        SUM(REVENUE_AMOUNT) AS TOTAL_REVENUE
    FROM SEMANTIC_LAYER.SILVER.DIM_AD_REVENUE
    GROUP BY REVENUE_DATE, CAMPAIGN_ID
),

-- -----------------------------------------------------------------------------
-- CTE: GOLD_ADS_DAILY
-- WHAT: Fully enriched daily data with names
-- WHY:  Human-readable output for dashboard.
-- -----------------------------------------------------------------------------
GOLD_ADS_DAILY AS (
    SELECT
        ENG.EVENT_DATE,
        ENG.CAMPAIGN_ID,
        CAMP.CAMPAIGN_NAME,
        ENG.NEIGHBORHOOD_ID,
        NBH.NAME AS NEIGHBORHOOD_NAME,
        NBH.CITY,
        NBH.STATE,
        ENG.TOTAL_IMPRESSIONS,
        ENG.TOTAL_CLICKS,
        ROUND(ENG.TOTAL_CLICKS * 100.0 / NULLIF(ENG.TOTAL_IMPRESSIONS, 0), 1) AS CTR,
        COALESCE(REV.TOTAL_REVENUE, 0) AS TOTAL_REVENUE
    FROM ENGAGEMENT_BY_DAY ENG
    LEFT JOIN REVENUE_BY_DAY REV
        ON ENG.EVENT_DATE = REV.REVENUE_DATE
       AND ENG.CAMPAIGN_ID = REV.CAMPAIGN_ID
    LEFT JOIN SEMANTIC_LAYER.SILVER.DIM_CAMPAIGNS CAMP
        ON ENG.CAMPAIGN_ID = CAMP.CAMPAIGN_ID
    LEFT JOIN SOURCES.NEXTDOOR_ADS_CAMPAIGN.NEIGHBORHOOD NBH
        ON ENG.NEIGHBORHOOD_ID = NBH.NEIGHBORHOOD_ID
),

-- -----------------------------------------------------------------------------
-- CTE: RANKED_DATES
-- WHAT: Ranks dates by revenue within each neighborhood
-- WHY:  ROW_NUMBER enables "Top N" filtering.
-- 
-- PARTITION BY: Each neighborhood gets its own ranking
-- ORDER BY: Highest revenue first
-- -----------------------------------------------------------------------------
RANKED_DATES AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY NEIGHBORHOOD_ID 
            ORDER BY TOTAL_REVENUE DESC
        ) AS RN
    FROM GOLD_ADS_DAILY
)

-- -----------------------------------------------------------------------------
-- FINAL SELECT: Top 5 dates per neighborhood
-- INTERVIEW TIP: Classic "Top N per group" pattern using ROW_NUMBER
-- -----------------------------------------------------------------------------
SELECT
    NEIGHBORHOOD_ID,
    NEIGHBORHOOD_NAME,
    CITY,
    STATE,
    EVENT_DATE,
    CAMPAIGN_ID,
    CAMPAIGN_NAME,
    TOTAL_IMPRESSIONS,
    TOTAL_CLICKS,
    CTR,
    TOTAL_REVENUE
FROM RANKED_DATES
WHERE RN <= 5
ORDER BY NEIGHBORHOOD_ID, TOTAL_REVENUE DESC;


-- =============================================================================
-- QUERY 4: Top 5 Neighborhoods by Total Revenue
-- =============================================================================
-- DASHBOARD USE CASE: Revenue leaderboard, market prioritization
-- =============================================================================

-- -----------------------------------------------------------------------------
-- CTE: GOLD_ADS_DAILY
-- WHAT: Same enriched daily data (could be a view/table in production)
-- WHY:  Reuse pattern for neighborhood aggregation.
-- -----------------------------------------------------------------------------
WITH ENGAGEMENT_BY_DAY AS (
    SELECT
        EVENT_DATE,
        CAMPAIGN_ID,
        NEIGHBORHOOD_ID,
        COUNT_IF(EVENT_TYPE = 'IMPRESSION') AS TOTAL_IMPRESSIONS,
        COUNT_IF(EVENT_TYPE = 'CLICK') AS TOTAL_CLICKS
    FROM SEMANTIC_LAYER.SILVER.FCT_USER_ENGAGEMENT_AD
    GROUP BY EVENT_DATE, CAMPAIGN_ID, NEIGHBORHOOD_ID
),

REVENUE_BY_DAY AS (
    SELECT
        REVENUE_DATE,
        CAMPAIGN_ID,
        SUM(REVENUE_AMOUNT) AS TOTAL_REVENUE
    FROM SEMANTIC_LAYER.SILVER.DIM_AD_REVENUE
    GROUP BY REVENUE_DATE, CAMPAIGN_ID
),

GOLD_ADS_DAILY AS (
    SELECT
        ENG.NEIGHBORHOOD_ID,
        NBH.NAME AS NEIGHBORHOOD_NAME,
        COALESCE(REV.TOTAL_REVENUE, 0) AS TOTAL_REVENUE
    FROM ENGAGEMENT_BY_DAY ENG
    LEFT JOIN REVENUE_BY_DAY REV
        ON ENG.EVENT_DATE = REV.REVENUE_DATE
       AND ENG.CAMPAIGN_ID = REV.CAMPAIGN_ID
    LEFT JOIN SOURCES.NEXTDOOR_ADS_CAMPAIGN.NEIGHBORHOOD NBH
        ON ENG.NEIGHBORHOOD_ID = NBH.NEIGHBORHOOD_ID
),

-- -----------------------------------------------------------------------------
-- CTE: REVENUE_BY_NEIGHBORHOOD
-- WHAT: Total revenue per neighborhood with ranking
-- WHY:  Leaderboard requires ranking by total.
-- -----------------------------------------------------------------------------
REVENUE_BY_NEIGHBORHOOD AS (
    SELECT 
        NEIGHBORHOOD_ID, 
        NEIGHBORHOOD_NAME, 
        SUM(TOTAL_REVENUE) AS REVENUE, 
        ROW_NUMBER() OVER (ORDER BY SUM(TOTAL_REVENUE) DESC) AS RN 
    FROM GOLD_ADS_DAILY 
    GROUP BY NEIGHBORHOOD_ID, NEIGHBORHOOD_NAME
)

-- -----------------------------------------------------------------------------
-- FINAL SELECT: Top 5 neighborhoods
-- -----------------------------------------------------------------------------
SELECT 
    NEIGHBORHOOD_NAME, 
    REVENUE 
FROM REVENUE_BY_NEIGHBORHOOD 
WHERE RN <= 5
ORDER BY REVENUE DESC;


-- =============================================================================
-- QUERY 5: Campaign Performance Summary
-- =============================================================================
-- DASHBOARD USE CASE: Campaign health scorecard
-- 
-- WHY CAMPAIGN-LEVEL:
--   - Advertisers want to see their campaign's performance
--   - Ops teams need to identify underperforming campaigns
-- =============================================================================

WITH CAMPAIGN_ENGAGEMENT AS (
    SELECT
        CAMPAIGN_ID,
        COUNT_IF(EVENT_TYPE = 'IMPRESSION') AS TOTAL_IMPRESSIONS,
        COUNT_IF(EVENT_TYPE = 'CLICK') AS TOTAL_CLICKS,
        COUNT_IF(IS_CONVERSION = TRUE) AS TOTAL_CONVERSIONS,
        COUNT(DISTINCT USER_ID) AS UNIQUE_USERS_REACHED,
        COUNT(DISTINCT NEIGHBORHOOD_ID) AS NEIGHBORHOODS_REACHED
    FROM SEMANTIC_LAYER.SILVER.FCT_USER_ENGAGEMENT_AD
    GROUP BY CAMPAIGN_ID
),

CAMPAIGN_REVENUE AS (
    SELECT
        CAMPAIGN_ID,
        SUM(REVENUE_AMOUNT) AS TOTAL_REVENUE,
        SUM(ADVERTISER_SPEND) AS TOTAL_SPEND,
        AVG(CTR) AS AVG_DAILY_CTR,
        AVG(CONVERSION_RATE) AS AVG_DAILY_CONVERSION_RATE
    FROM SEMANTIC_LAYER.SILVER.DIM_AD_REVENUE
    GROUP BY CAMPAIGN_ID
)

SELECT
    c.CAMPAIGN_ID,
    c.CAMPAIGN_NAME,
    c.ADVERTISER_NAME,
    c.BUSINESS_CATEGORY,
    c.CAMPAIGN_OBJECTIVE,
    c.BUDGET_TIER,
    c.CAMPAIGN_LIFECYCLE_STATUS,
    c.TOTAL_BUDGET,
    
    -- Engagement metrics
    COALESCE(e.TOTAL_IMPRESSIONS, 0) AS TOTAL_IMPRESSIONS,
    COALESCE(e.TOTAL_CLICKS, 0) AS TOTAL_CLICKS,
    COALESCE(e.TOTAL_CONVERSIONS, 0) AS TOTAL_CONVERSIONS,
    COALESCE(e.UNIQUE_USERS_REACHED, 0) AS UNIQUE_USERS_REACHED,
    COALESCE(e.NEIGHBORHOODS_REACHED, 0) AS NEIGHBORHOODS_REACHED,
    
    -- Calculated rates
    ROUND(e.TOTAL_CLICKS * 100.0 / NULLIF(e.TOTAL_IMPRESSIONS, 0), 2) AS CTR_PERCENT,
    ROUND(e.TOTAL_CONVERSIONS * 100.0 / NULLIF(e.TOTAL_CLICKS, 0), 2) AS CONVERSION_RATE_PERCENT,
    
    -- Revenue metrics
    COALESCE(r.TOTAL_REVENUE, 0) AS TOTAL_REVENUE,
    COALESCE(r.TOTAL_SPEND, 0) AS TOTAL_SPEND,
    ROUND(COALESCE(r.TOTAL_REVENUE, 0) / NULLIF(r.TOTAL_SPEND, 0), 2) AS ROAS,
    
    -- Budget utilization
    ROUND(COALESCE(r.TOTAL_SPEND, 0) / NULLIF(c.TOTAL_BUDGET, 0) * 100, 1) AS BUDGET_UTILIZATION_PCT

FROM SEMANTIC_LAYER.SILVER.DIM_CAMPAIGNS c
LEFT JOIN CAMPAIGN_ENGAGEMENT e ON c.CAMPAIGN_ID = e.CAMPAIGN_ID
LEFT JOIN CAMPAIGN_REVENUE r ON c.CAMPAIGN_ID = r.CAMPAIGN_ID
ORDER BY TOTAL_REVENUE DESC;
