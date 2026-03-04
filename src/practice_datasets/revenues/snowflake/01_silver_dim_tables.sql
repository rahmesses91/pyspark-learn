-- ============================================================================
-- STEP 1: SILVER LAYER - Dimension Tables
-- ============================================================================
-- PURPOSE: Create dimension tables for users, campaigns, and revenue with
--          derived attributes useful for filtering and analysis.
--
-- WHY DIMENSION TABLES:
--   - Centralize business logic (e.g., "what is an Active user?")
--   - Pre-calculate commonly used attributes
--   - Enable consistent filtering across all dashboards
--   - Reduce repeated calculations in downstream queries
--
-- SOURCE TABLES:
--   - SOURCES.NEXTDOOR_ADS_CAMPAIGN.USERS
--   - SOURCES.NEXTDOOR_ADS_CAMPAIGN.AD_CAMPAIGNS
--   - SOURCES.NEXTDOOR_ADS_CAMPAIGN.AD_REVENUE
--
-- OUTPUT TABLES:
--   - SEMANTIC_LAYER.SILVER.DIM_USERS
--   - SEMANTIC_LAYER.SILVER.DIM_CAMPAIGNS
--   - SEMANTIC_LAYER.SILVER.DIM_AD_REVENUE
--
-- DASHBOARD USE CASES:
--   - User segmentation filters (age group, device, engagement status)
--   - Campaign filtering (budget tier, status, objective)
--   - Revenue performance tiers (CTR tier, conversion tier)
-- ============================================================================


-- ============================================================================
-- DIM_USERS: User dimension with derived engagement status
-- ============================================================================
-- GRAIN: 1 row per user
-- 
-- WHY THESE DERIVED COLUMNS:
--   - ACCOUNT_AGE_DAYS: Helps segment new vs established users
--   - DAYS_SINCE_LAST_ACTIVE: Primary churn indicator
--   - USER_ENGAGEMENT_STATUS: Pre-calculated segment for easy filtering
-- ============================================================================

CREATE OR REPLACE TABLE SEMANTIC_LAYER.SILVER.DIM_USERS
AS (
    SELECT 
        USER_ID,
        NAME AS USER_NAME,
        EMAIL,
        NEIGHBORHOOD_ID,
        AGE_GROUP,
        GENDER,
        IS_VERIFIED,
        IS_ACTIVE,
        NOTIFICATION_ENABLED,
        DEVICE_TYPE AS PREFERRED_DEVICE,
        
        -- Timestamps (raw)
        CREATED_AT,
        LAST_ACTIVE_AT,
        
        -- Calculated date columns (for easier joins)
        DATE(CREATED_AT) AS CREATED_DATE,
        DATE(LAST_ACTIVE_AT) AS LAST_ACTIVE_DATE,
        
        -- ---------------------------------------------------------------------
        -- DERIVED: Account age metrics
        -- WHY: Segment users by tenure (new users behave differently)
        -- ---------------------------------------------------------------------
        DATEDIFF('day', CREATED_AT, CURRENT_TIMESTAMP()) AS ACCOUNT_AGE_DAYS,
        DATEDIFF('day', LAST_ACTIVE_AT, CURRENT_TIMESTAMP()) AS DAYS_SINCE_LAST_ACTIVE,
        
        -- ---------------------------------------------------------------------
        -- DERIVED: Engagement status bucket
        -- WHY: Pre-calculated segment for dashboard filters
        -- THRESHOLDS: Active (7d), Recent (30d), Lapsed (90d), Dormant (90d+)
        -- ---------------------------------------------------------------------
        CASE 
            WHEN DATEDIFF('day', LAST_ACTIVE_AT, CURRENT_TIMESTAMP()) <= 7 THEN 'Active'
            WHEN DATEDIFF('day', LAST_ACTIVE_AT, CURRENT_TIMESTAMP()) <= 30 THEN 'Recent'
            WHEN DATEDIFF('day', LAST_ACTIVE_AT, CURRENT_TIMESTAMP()) <= 90 THEN 'Lapsed'
            ELSE 'Dormant'
        END AS USER_ENGAGEMENT_STATUS
        
    FROM SOURCES.NEXTDOOR_ADS_CAMPAIGN.USERS
);


-- ============================================================================
-- DIM_CAMPAIGNS: Campaign dimension with lifecycle status and budget tiers
-- ============================================================================
-- GRAIN: 1 row per campaign
-- 
-- WHY THESE DERIVED COLUMNS:
--   - CAMPAIGN_DURATION_DAYS: Normalize performance across short/long campaigns
--   - CAMPAIGN_LIFECYCLE_STATUS: More granular than raw status
--   - BUDGET_TIER: Segment campaigns by investment level
-- ============================================================================

CREATE OR REPLACE TABLE SEMANTIC_LAYER.SILVER.DIM_CAMPAIGNS
AS (
    SELECT 
        CAMPAIGN_ID,
        CAMPAIGN_NAME,
        ADVERTISER_ID,
        ADVERTISER_NAME,
        BUSINESS_CATEGORY,
        CAMPAIGN_OBJECTIVE,
        AD_TYPE,
        TARGET_NEIGHBORHOOD_IDS,
        TARGET_AGE_GROUPS,
        DAILY_BUDGET,
        TOTAL_BUDGET,
        BID_STRATEGY,
        BID_AMOUNT,
        STATUS AS CAMPAIGN_STATUS,
        START_DATE,
        END_DATE,
        
        -- Timestamps
        CREATED_AT,
        DATE(CREATED_AT) AS CREATED_DATE,
        
        -- ---------------------------------------------------------------------
        -- DERIVED: Campaign duration metrics
        -- WHY: Normalize revenue/performance by campaign length
        -- ---------------------------------------------------------------------
        DATEDIFF('day', START_DATE, END_DATE) AS CAMPAIGN_DURATION_DAYS,
        DATEDIFF('day', START_DATE, CURRENT_DATE()) AS DAYS_SINCE_START,
        DATEDIFF('day', CURRENT_DATE(), END_DATE) AS DAYS_UNTIL_END,
        
        -- ---------------------------------------------------------------------
        -- DERIVED: Lifecycle status (more granular than raw status)
        -- WHY: Distinguishes scheduled vs running vs completed
        -- ---------------------------------------------------------------------
        CASE 
            WHEN STATUS = 'Active' AND CURRENT_DATE() BETWEEN START_DATE AND END_DATE THEN 'Running'
            WHEN STATUS = 'Active' AND CURRENT_DATE() < START_DATE THEN 'Scheduled'
            WHEN STATUS = 'Paused' THEN 'Paused'
            WHEN STATUS = 'Draft' THEN 'Draft'
            WHEN CURRENT_DATE() > END_DATE THEN 'Completed'
            ELSE STATUS
        END AS CAMPAIGN_LIFECYCLE_STATUS,
        
        -- ---------------------------------------------------------------------
        -- DERIVED: Budget tier for segmentation
        -- WHY: Analyze performance by investment level
        -- THRESHOLDS: Small (<$1k), Medium ($1-5k), Large ($5-20k), Enterprise ($20k+)
        -- ---------------------------------------------------------------------
        CASE 
            WHEN TOTAL_BUDGET < 1000 THEN 'Small'
            WHEN TOTAL_BUDGET < 5000 THEN 'Medium'
            WHEN TOTAL_BUDGET < 20000 THEN 'Large'
            ELSE 'Enterprise'
        END AS BUDGET_TIER
        
    FROM SOURCES.NEXTDOOR_ADS_CAMPAIGN.AD_CAMPAIGNS
);


-- ============================================================================
-- DIM_AD_REVENUE: Revenue fact with performance tiers and time dimensions
-- ============================================================================
-- GRAIN: 1 row per campaign per day
-- 
-- WHY THESE DERIVED COLUMNS:
--   - Time dimensions: Enable aggregation by week/month/quarter
--   - Performance tiers: Pre-classify CTR, conversion, revenue levels
--   - MARGIN_PERCENT: Profitability metric (revenue - advertiser spend)
-- ============================================================================

CREATE OR REPLACE TABLE SEMANTIC_LAYER.SILVER.DIM_AD_REVENUE
AS (
    SELECT 
        REVENUE_ID,
        CAMPAIGN_ID,
        ADVERTISER_ID,
        ADVERTISER_NAME,
        BUSINESS_CATEGORY,
        REVENUE_DATE,
        
        -- Core metrics
        IMPRESSIONS,
        CLICKS,
        CONVERSIONS,
        REVENUE_AMOUNT,
        ADVERTISER_SPEND,
        
        -- Pre-calculated rates (from source, but validated)
        CPM,
        CPC,
        CPA,
        CTR,
        CONVERSION_RATE,
        
        -- Timestamps
        CREATED_AT,
        DATE(CREATED_AT) AS CREATED_DATE,
        
        -- ---------------------------------------------------------------------
        -- DERIVED: Time dimension attributes
        -- WHY: Enable GROUP BY week, month, quarter without repeated extraction
        -- ---------------------------------------------------------------------
        DAYOFWEEK(REVENUE_DATE) AS DAY_OF_WEEK,
        DAYNAME(REVENUE_DATE) AS DAY_NAME,
        WEEKOFYEAR(REVENUE_DATE) AS WEEK_OF_YEAR,
        MONTH(REVENUE_DATE) AS MONTH_NUM,
        MONTHNAME(REVENUE_DATE) AS MONTH_NAME,
        QUARTER(REVENUE_DATE) AS QUARTER_NUM,
        YEAR(REVENUE_DATE) AS YEAR_NUM,
        
        -- ---------------------------------------------------------------------
        -- DERIVED: CTR performance tier
        -- WHY: Classify ad performance for filtering/alerting
        -- BENCHMARKS: <2% poor, 2-5% average, 5-10% good, 10%+ excellent
        -- ---------------------------------------------------------------------
        CASE 
            WHEN CTR >= 10 THEN 'Excellent'
            WHEN CTR >= 5 THEN 'Good'
            WHEN CTR >= 2 THEN 'Average'
            ELSE 'Below Average'
        END AS CTR_PERFORMANCE_TIER,
        
        -- ---------------------------------------------------------------------
        -- DERIVED: Conversion tier
        -- WHY: Segment campaigns by conversion effectiveness
        -- ---------------------------------------------------------------------
        CASE 
            WHEN CONVERSION_RATE >= 20 THEN 'High Converting'
            WHEN CONVERSION_RATE >= 10 THEN 'Moderate Converting'
            WHEN CONVERSION_RATE >= 5 THEN 'Low Converting'
            ELSE 'Needs Optimization'
        END AS CONVERSION_TIER,
        
        -- ---------------------------------------------------------------------
        -- DERIVED: Revenue tier
        -- WHY: Identify high-value vs low-value days
        -- ---------------------------------------------------------------------
        CASE 
            WHEN REVENUE_AMOUNT >= 1000 THEN 'High Revenue'
            WHEN REVENUE_AMOUNT >= 500 THEN 'Medium Revenue'
            WHEN REVENUE_AMOUNT >= 100 THEN 'Low Revenue'
            ELSE 'Minimal Revenue'
        END AS REVENUE_TIER,
        
        -- ---------------------------------------------------------------------
        -- DERIVED: Profit margin percentage
        -- WHY: Key metric for business health (revenue minus cost)
        -- FORMULA: (revenue - spend) / revenue * 100
        -- ---------------------------------------------------------------------
        ROUND((REVENUE_AMOUNT - ADVERTISER_SPEND) / NULLIF(REVENUE_AMOUNT, 0) * 100, 2) AS MARGIN_PERCENT
        
    FROM SOURCES.NEXTDOOR_ADS_CAMPAIGN.AD_REVENUE
);
