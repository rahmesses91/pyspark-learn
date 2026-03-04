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
--   - users
--   - ad_campaigns
--   - ad_revenue
--
-- OUTPUT TABLES:
--   - dim_users
--   - dim_campaigns
--   - dim_ad_revenue
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
--   - account_age_days: Helps segment new vs established users
--   - days_since_last_active: Primary churn indicator
--   - user_engagement_status: Pre-calculated segment for easy filtering
-- ============================================================================

DROP TABLE IF EXISTS dim_users;

CREATE TABLE dim_users AS (
    SELECT 
        user_id,
        name AS user_name,
        email,
        neighborhood_id,
        age_group,
        gender,
        is_verified,
        is_active,
        notification_enabled,
        device_type AS preferred_device,
        
        -- Timestamps (raw)
        created_at,
        last_active_at,
        
        -- Calculated date columns (for easier joins)
        created_at::DATE AS created_date,
        last_active_at::DATE AS last_active_date,
        
        -- ---------------------------------------------------------------------
        -- DERIVED: Account age metrics
        -- WHY: Segment users by tenure (new users behave differently)
        -- PostgreSQL: (date2 - date1) returns integer days
        -- ---------------------------------------------------------------------
        (CURRENT_DATE - created_at::DATE) AS account_age_days,
        (CURRENT_DATE - last_active_at::DATE) AS days_since_last_active,
        
        -- ---------------------------------------------------------------------
        -- DERIVED: Engagement status bucket
        -- WHY: Pre-calculated segment for dashboard filters
        -- THRESHOLDS: Active (7d), Recent (30d), Lapsed (90d), Dormant (90d+)
        -- ---------------------------------------------------------------------
        CASE 
            WHEN (CURRENT_DATE - last_active_at::DATE) <= 7 THEN 'Active'
            WHEN (CURRENT_DATE - last_active_at::DATE) <= 30 THEN 'Recent'
            WHEN (CURRENT_DATE - last_active_at::DATE) <= 90 THEN 'Lapsed'
            ELSE 'Dormant'
        END AS user_engagement_status
        
    FROM users
);


-- ============================================================================
-- DIM_CAMPAIGNS: Campaign dimension with lifecycle status and budget tiers
-- ============================================================================
-- GRAIN: 1 row per campaign
-- 
-- WHY THESE DERIVED COLUMNS:
--   - campaign_duration_days: Normalize performance across short/long campaigns
--   - campaign_lifecycle_status: More granular than raw status
--   - budget_tier: Segment campaigns by investment level
-- ============================================================================

DROP TABLE IF EXISTS dim_campaigns;

CREATE TABLE dim_campaigns AS (
    SELECT 
        campaign_id,
        campaign_name,
        advertiser_id,
        advertiser_name,
        business_category,
        campaign_objective,
        ad_type,
        target_neighborhood_ids,
        target_age_groups,
        daily_budget,
        total_budget,
        bid_strategy,
        bid_amount,
        status AS campaign_status,
        start_date,
        end_date,
        
        -- Timestamps
        created_at,
        created_at::DATE AS created_date,
        
        -- ---------------------------------------------------------------------
        -- DERIVED: Campaign duration metrics
        -- WHY: Normalize revenue/performance by campaign length
        -- ---------------------------------------------------------------------
        (end_date - start_date) AS campaign_duration_days,
        (CURRENT_DATE - start_date) AS days_since_start,
        (end_date - CURRENT_DATE) AS days_until_end,
        
        -- ---------------------------------------------------------------------
        -- DERIVED: Lifecycle status (more granular than raw status)
        -- WHY: Distinguishes scheduled vs running vs completed
        -- ---------------------------------------------------------------------
        CASE 
            WHEN status = 'Active' AND CURRENT_DATE BETWEEN start_date AND end_date THEN 'Running'
            WHEN status = 'Active' AND CURRENT_DATE < start_date THEN 'Scheduled'
            WHEN status = 'Paused' THEN 'Paused'
            WHEN status = 'Draft' THEN 'Draft'
            WHEN CURRENT_DATE > end_date THEN 'Completed'
            ELSE status
        END AS campaign_lifecycle_status,
        
        -- ---------------------------------------------------------------------
        -- DERIVED: Budget tier for segmentation
        -- WHY: Analyze performance by investment level
        -- THRESHOLDS: Small (<$1k), Medium ($1-5k), Large ($5-20k), Enterprise ($20k+)
        -- ---------------------------------------------------------------------
        CASE 
            WHEN total_budget < 1000 THEN 'Small'
            WHEN total_budget < 5000 THEN 'Medium'
            WHEN total_budget < 20000 THEN 'Large'
            ELSE 'Enterprise'
        END AS budget_tier
        
    FROM ad_campaigns
);


-- ============================================================================
-- DIM_AD_REVENUE: Revenue fact with performance tiers and time dimensions
-- ============================================================================
-- GRAIN: 1 row per campaign per day
-- 
-- WHY THESE DERIVED COLUMNS:
--   - Time dimensions: Enable aggregation by week/month/quarter
--   - Performance tiers: Pre-classify CTR, conversion, revenue levels
--   - margin_percent: Profitability metric (revenue - advertiser spend)
-- ============================================================================

DROP TABLE IF EXISTS dim_ad_revenue;

CREATE TABLE dim_ad_revenue AS (
    SELECT 
        revenue_id,
        campaign_id,
        advertiser_id,
        advertiser_name,
        business_category,
        revenue_date,
        
        -- Core metrics
        impressions,
        clicks,
        conversions,
        revenue_amount,
        advertiser_spend,
        
        -- Pre-calculated rates (from source, but validated)
        cpm,
        cpc,
        cpa,
        ctr,
        conversion_rate,
        
        -- Timestamps
        created_at,
        created_at::DATE AS created_date,
        
        -- ---------------------------------------------------------------------
        -- DERIVED: Time dimension attributes
        -- WHY: Enable GROUP BY week, month, quarter without repeated extraction
        -- PostgreSQL: EXTRACT returns double, cast to integer
        -- ---------------------------------------------------------------------
        EXTRACT(DOW FROM revenue_date)::INTEGER AS day_of_week,
        TO_CHAR(revenue_date, 'Day') AS day_name,
        EXTRACT(WEEK FROM revenue_date)::INTEGER AS week_of_year,
        EXTRACT(MONTH FROM revenue_date)::INTEGER AS month_num,
        TO_CHAR(revenue_date, 'Month') AS month_name,
        EXTRACT(QUARTER FROM revenue_date)::INTEGER AS quarter_num,
        EXTRACT(YEAR FROM revenue_date)::INTEGER AS year_num,
        
        -- ---------------------------------------------------------------------
        -- DERIVED: CTR performance tier
        -- WHY: Classify ad performance for filtering/alerting
        -- BENCHMARKS: <2% poor, 2-5% average, 5-10% good, 10%+ excellent
        -- ---------------------------------------------------------------------
        CASE 
            WHEN ctr >= 10 THEN 'Excellent'
            WHEN ctr >= 5 THEN 'Good'
            WHEN ctr >= 2 THEN 'Average'
            ELSE 'Below Average'
        END AS ctr_performance_tier,
        
        -- ---------------------------------------------------------------------
        -- DERIVED: Conversion tier
        -- WHY: Segment campaigns by conversion effectiveness
        -- ---------------------------------------------------------------------
        CASE 
            WHEN conversion_rate >= 20 THEN 'High Converting'
            WHEN conversion_rate >= 10 THEN 'Moderate Converting'
            WHEN conversion_rate >= 5 THEN 'Low Converting'
            ELSE 'Needs Optimization'
        END AS conversion_tier,
        
        -- ---------------------------------------------------------------------
        -- DERIVED: Revenue tier
        -- WHY: Identify high-value vs low-value days
        -- ---------------------------------------------------------------------
        CASE 
            WHEN revenue_amount >= 1000 THEN 'High Revenue'
            WHEN revenue_amount >= 500 THEN 'Medium Revenue'
            WHEN revenue_amount >= 100 THEN 'Low Revenue'
            ELSE 'Minimal Revenue'
        END AS revenue_tier,
        
        -- ---------------------------------------------------------------------
        -- DERIVED: Profit margin percentage
        -- WHY: Key metric for business health (revenue minus cost)
        -- FORMULA: (revenue - spend) / revenue * 100
        -- ---------------------------------------------------------------------
        ROUND((revenue_amount - advertiser_spend) / NULLIF(revenue_amount, 0) * 100, 2) AS margin_percent
        
    FROM ad_revenue
);

-- Create indexes for better query performance
CREATE INDEX idx_dim_users_neighborhood ON dim_users(neighborhood_id);
CREATE INDEX idx_dim_users_engagement ON dim_users(user_engagement_status);
CREATE INDEX idx_dim_campaigns_status ON dim_campaigns(campaign_lifecycle_status);
CREATE INDEX idx_dim_campaigns_category ON dim_campaigns(business_category);
CREATE INDEX idx_dim_ad_revenue_date ON dim_ad_revenue(revenue_date);
CREATE INDEX idx_dim_ad_revenue_campaign ON dim_ad_revenue(campaign_id);
