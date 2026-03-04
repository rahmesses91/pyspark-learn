-- ============================================================================
-- STEP 2: SILVER LAYER - Unified Ad Engagement Fact Table
-- ============================================================================
-- PURPOSE: Consolidate ad impressions and clicks into a single event stream
--          for unified engagement analysis.
--
-- WHY UNIFY IMPRESSIONS AND CLICKS:
--   - Single table for all ad engagement queries
--   - Enables funnel analysis: Impression → Click → Conversion
--   - Consistent schema for filtering/aggregation
--   - Enriches clicks with impression context (ad_type, placement, session)
--
-- SOURCE TABLES:
--   - SOURCES.NEXTDOOR_ADS_CAMPAIGN.AD_IMPRESSIONS
--   - SOURCES.NEXTDOOR_ADS_CAMPAIGN.AD_CLICKS
--
-- OUTPUT: SEMANTIC_LAYER.SILVER.FCT_USER_ENGAGEMENT_AD
--
-- DASHBOARD USE CASES:
--   - CTR calculation (clicks / impressions)
--   - User reach analysis (unique users who saw ads)
--   - Device/placement performance comparison
--   - Conversion funnel analysis
-- ============================================================================

CREATE OR REPLACE TABLE SEMANTIC_LAYER.SILVER.FCT_USER_ENGAGEMENT_AD
AS (

    -- =========================================================================
    -- IMPRESSIONS: Ad view events
    -- =========================================================================
    -- WHY INCLUDE:
    --   - Foundation for CTR calculation (denominator)
    --   - Measures reach (how many users saw ads)
    --   - Viewability and duration metrics for ad quality
    -- =========================================================================
    SELECT 
        IMP.USER_ID,
        IMP.NEIGHBORHOOD_ID,
        IMP.IMPRESSION_ID AS EVENT_ID,
        'IMPRESSION' AS EVENT_TYPE,
        IMP.CAMPAIGN_ID,
        IMP.AD_TYPE,
        IMP.AD_PLACEMENT,
        IMP.DEVICE_TYPE,
        IMP.SESSION_ID,
        IMP.IS_VIEWABLE,
        IMP.VIEW_DURATION_SECONDS,
        
        -- Click-specific fields (NULL for impressions)
        NULL AS PARENT_IMPRESSION_ID,
        NULL AS CLICK_POSITION,
        NULL AS LANDING_PAGE_URL,
        FALSE AS IS_CONVERSION,
        
        -- Timestamps
        IMP.CREATED_AT AS EVENT_TIMESTAMP,
        DATE(IMP.CREATED_AT) AS EVENT_DATE
        
    FROM SOURCES.NEXTDOOR_ADS_CAMPAIGN.AD_IMPRESSIONS IMP
        
    UNION ALL

    -- =========================================================================
    -- CLICKS: Ad click events (enriched with impression context)
    -- =========================================================================
    -- WHY ENRICH FROM IMPRESSIONS:
    --   - Clicks need context: what ad_type/placement led to the click?
    --   - PARENT_IMPRESSION_ID enables impression→click attribution
    --   - IS_CONVERSION is the ultimate success metric
    -- =========================================================================
    SELECT 
        CLK.USER_ID,
        CLK.NEIGHBORHOOD_ID,
        CLK.CLICK_ID AS EVENT_ID,
        'CLICK' AS EVENT_TYPE,
        CLK.CAMPAIGN_ID,
        
        -- Enriched from parent impression
        IMP.AD_TYPE,
        IMP.AD_PLACEMENT,
        CLK.DEVICE_TYPE,
        IMP.SESSION_ID,
        IMP.IS_VIEWABLE,
        IMP.VIEW_DURATION_SECONDS,
        
        -- Click-specific fields
        CLK.IMPRESSION_ID AS PARENT_IMPRESSION_ID,
        CLK.CLICK_POSITION,
        CLK.LANDING_PAGE_URL,
        CLK.IS_CONVERSION,
        
        -- Timestamps
        CLK.CREATED_AT AS EVENT_TIMESTAMP,
        DATE(CLK.CREATED_AT) AS EVENT_DATE
        
    FROM SOURCES.NEXTDOOR_ADS_CAMPAIGN.AD_CLICKS CLK
    LEFT JOIN SOURCES.NEXTDOOR_ADS_CAMPAIGN.AD_IMPRESSIONS IMP
        ON CLK.IMPRESSION_ID = IMP.IMPRESSION_ID
);
