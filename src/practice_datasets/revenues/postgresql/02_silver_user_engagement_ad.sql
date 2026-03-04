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
--   - ad_impressions
--   - ad_clicks
--
-- OUTPUT: fct_user_engagement_ad
--
-- DASHBOARD USE CASES:
--   - CTR calculation (clicks / impressions)
--   - User reach analysis (unique users who saw ads)
--   - Device/placement performance comparison
--   - Conversion funnel analysis
-- ============================================================================

DROP TABLE IF EXISTS fct_user_engagement_ad;

CREATE TABLE fct_user_engagement_ad AS (

    -- =========================================================================
    -- IMPRESSIONS: Ad view events
    -- =========================================================================
    -- WHY INCLUDE:
    --   - Foundation for CTR calculation (denominator)
    --   - Measures reach (how many users saw ads)
    --   - Viewability and duration metrics for ad quality
    -- =========================================================================
    SELECT 
        imp.user_id,
        imp.neighborhood_id,
        imp.impression_id AS event_id,
        'IMPRESSION' AS event_type,
        imp.campaign_id,
        imp.ad_type,
        imp.ad_placement,
        imp.device_type,
        imp.session_id,
        imp.is_viewable,
        imp.view_duration_seconds,
        
        -- Click-specific fields (NULL for impressions)
        NULL::INTEGER AS parent_impression_id,
        NULL::TEXT AS click_position,
        NULL::TEXT AS landing_page_url,
        FALSE AS is_conversion,
        
        -- Timestamps
        imp.created_at AS event_timestamp,
        imp.created_at::DATE AS event_date
        
    FROM ad_impressions imp
        
    UNION ALL

    -- =========================================================================
    -- CLICKS: Ad click events (enriched with impression context)
    -- =========================================================================
    -- WHY ENRICH FROM IMPRESSIONS:
    --   - Clicks need context: what ad_type/placement led to the click?
    --   - parent_impression_id enables impression→click attribution
    --   - is_conversion is the ultimate success metric
    -- =========================================================================
    SELECT 
        clk.user_id,
        clk.neighborhood_id,
        clk.click_id AS event_id,
        'CLICK' AS event_type,
        clk.campaign_id,
        
        -- Enriched from parent impression
        imp.ad_type,
        imp.ad_placement,
        clk.device_type,
        imp.session_id,
        imp.is_viewable,
        imp.view_duration_seconds,
        
        -- Click-specific fields
        clk.impression_id AS parent_impression_id,
        clk.click_position,
        clk.landing_page_url,
        clk.is_conversion,
        
        -- Timestamps
        clk.created_at AS event_timestamp,
        clk.created_at::DATE AS event_date
        
    FROM ad_clicks clk
    LEFT JOIN ad_impressions imp
        ON clk.impression_id = imp.impression_id
);

-- Create indexes for better query performance
CREATE INDEX idx_fct_engagement_ad_user ON fct_user_engagement_ad(user_id);
CREATE INDEX idx_fct_engagement_ad_date ON fct_user_engagement_ad(event_date);
CREATE INDEX idx_fct_engagement_ad_campaign ON fct_user_engagement_ad(campaign_id);
CREATE INDEX idx_fct_engagement_ad_type ON fct_user_engagement_ad(event_type);
CREATE INDEX idx_fct_engagement_ad_neighborhood ON fct_user_engagement_ad(neighborhood_id);
