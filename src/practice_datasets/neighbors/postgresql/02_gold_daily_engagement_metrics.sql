-- ============================================================================
-- STEP 2: GOLD LAYER - Daily Engagement Metrics & Active User Counts
-- ============================================================================
-- PURPOSE: Calculate daily, weekly, and monthly active user metrics along with
--          activity breakdowns by neighborhood for dashboard visualization.
--
-- WHY THIS MATTERS FOR DASHBOARDS:
--   - Executives want to see DAU/WAU/MAU trends at a glance
--   - Product managers need stickiness ratios to measure engagement quality
--   - Community managers need neighborhood-level breakdowns
--
-- DEPENDS ON:
--   - fct_user_engagement (from Step 1)
--   - neighborhoods
--
-- INTERVIEW TIP: These are the most common dashboard metrics. Be ready to
--                explain WHY each ratio matters and what "good" looks like.
-- ============================================================================


-- =============================================================================
-- QUERY 1: Daily Activity Breakdown by Neighborhood
-- =============================================================================
-- DASHBOARD USE CASE: Activity overview cards, neighborhood comparison charts
-- FILTERS SUPPORTED: Date range picker, neighborhood selector
-- =============================================================================

-- -----------------------------------------------------------------------------
-- CTE: user_engagement
-- WHAT: Pulls all activity records from the silver layer fact table
-- WHY:  Acts as the base dataset. Using a CTE here allows us to add filters
--       (like date range) in one place without repeating in every aggregation.
-- -----------------------------------------------------------------------------
WITH user_engagement AS (
    SELECT 
        user_id,
        post_id,
        neighborhood_id,
        user_status,
        activity_type,
        event_id,
        activity_datetime,
        activity_date
    FROM fct_user_engagement
)

SELECT 
    activity_date,
    n.name AS neighborhood_name,
    
    -- Activity counts: Raw volume metrics
    COUNT(*) FILTER (WHERE activity_type = 'POST') AS total_posts,
    COUNT(*) FILTER (WHERE activity_type = 'COMMENT') AS total_comments,
    COUNT(*) FILTER (WHERE activity_type = 'REACTION') AS total_reactions,
    
    -- User counts: Unique participants by activity type
    COUNT(DISTINCT user_id) AS total_users,
    COUNT(DISTINCT user_id) FILTER (WHERE activity_type = 'POST') AS total_posting_users,
    COUNT(DISTINCT user_id) FILTER (WHERE activity_type = 'COMMENT') AS total_commenting_users,
    COUNT(DISTINCT user_id) FILTER (WHERE activity_type = 'REACTION') AS total_reacting_users,
    COUNT(DISTINCT user_id) FILTER (WHERE activity_type = 'NO_ACTIVITY') AS total_inactive_users

FROM user_engagement ue
INNER JOIN neighborhoods n
    ON ue.neighborhood_id = n.neighborhood_id
GROUP BY activity_date, n.name
ORDER BY activity_date, n.name;


-- =============================================================================
-- QUERY 2: DAU / WAU / MAU with Stickiness Ratios
-- =============================================================================
-- DASHBOARD USE CASE: Executive KPI dashboard, engagement health scorecard
-- 
-- KEY METRICS EXPLAINED:
--   DAU/WAU Ratio: What % of weekly users come back daily? (Target: 20-40%)
--   DAU/MAU Ratio: What % of monthly users come back daily? (Target: 10-20%)
--   WAU/MAU Ratio: What % of monthly users are active weekly? (Target: 40-60%)
--
-- INTERVIEW TIP: Higher ratios = "stickier" product. Facebook targets 50%+ DAU/MAU
-- =============================================================================

-- -----------------------------------------------------------------------------
-- CTE: active_users
-- WHAT: Filters to only meaningful engagement (excludes NO_ACTIVITY users)
-- WHY:  For DAU/WAU/MAU, we only count users who actually DID something.
--       Signing up alone doesn't make you "active".
-- -----------------------------------------------------------------------------
WITH active_users AS (
    SELECT 
        user_id,
        neighborhood_id,
        activity_date
    FROM fct_user_engagement
    WHERE activity_type IN ('POST', 'COMMENT', 'REACTION')
),

-- -----------------------------------------------------------------------------
-- CTE: date_spine
-- WHAT: Creates a complete list of date + neighborhood combinations
-- WHY:  Ensures we have a row for every day, even if there was zero activity.
--       Without this, gaps in data would cause misleading charts.
-- -----------------------------------------------------------------------------
date_spine AS (
    SELECT DISTINCT 
        activity_date,
        neighborhood_id
    FROM active_users
),

-- -----------------------------------------------------------------------------
-- CTE: daily_active_users
-- WHAT: Counts unique users per day per neighborhood
-- WHY:  This is the foundation - DAU is the most granular active user metric.
--       Everything else (WAU, MAU) builds on this concept.
-- -----------------------------------------------------------------------------
daily_active_users AS (
    SELECT
        activity_date,
        neighborhood_id,
        COUNT(DISTINCT user_id) AS dau
    FROM active_users
    GROUP BY activity_date, neighborhood_id
),

-- -----------------------------------------------------------------------------
-- CTE: weekly_active_users
-- WHAT: Counts unique users in a rolling 7-day window ending on each date
-- WHY:  WAU smooths out daily volatility (weekends, holidays).
--       Rolling window (vs calendar week) provides continuous trend data.
-- 
-- TECHNICAL NOTE: We join back to active_users with a date range condition.
--                 This counts each user once even if they were active multiple days.
-- -----------------------------------------------------------------------------
weekly_active_users AS (
    SELECT
        ds.activity_date,
        ds.neighborhood_id,
        COUNT(DISTINCT au.user_id) AS wau
    FROM date_spine ds
    LEFT JOIN active_users au
        ON au.neighborhood_id = ds.neighborhood_id
        AND au.activity_date BETWEEN ds.activity_date - INTERVAL '6 days' AND ds.activity_date
    GROUP BY ds.activity_date, ds.neighborhood_id
),

-- -----------------------------------------------------------------------------
-- CTE: monthly_active_users
-- WHAT: Counts unique users in a rolling 30-day window ending on each date
-- WHY:  MAU is the standard "reach" metric for monthly reporting.
--       Investors and executives often track MAU as a headline number.
-- -----------------------------------------------------------------------------
monthly_active_users AS (
    SELECT
        ds.activity_date,
        ds.neighborhood_id,
        COUNT(DISTINCT au.user_id) AS mau
    FROM date_spine ds
    LEFT JOIN active_users au
        ON au.neighborhood_id = ds.neighborhood_id
        AND au.activity_date BETWEEN ds.activity_date - INTERVAL '29 days' AND ds.activity_date
    GROUP BY ds.activity_date, ds.neighborhood_id
)

-- -----------------------------------------------------------------------------
-- FINAL SELECT: Combines DAU, WAU, MAU and calculates stickiness ratios
-- WHY RATIOS MATTER: Raw numbers grow with user base. Ratios show QUALITY.
--                    A growing DAU with falling DAU/MAU = concerning trend.
-- -----------------------------------------------------------------------------
SELECT
    d.activity_date,
    n.name AS neighborhood_name,
    d.dau AS total_daily_active_users,
    w.wau AS total_weekly_active_users,
    m.mau AS total_monthly_active_users,
    ROUND(d.dau::NUMERIC / NULLIF(w.wau, 0), 2) AS dau_wau_ratio,
    ROUND(d.dau::NUMERIC / NULLIF(m.mau, 0), 2) AS dau_mau_ratio,
    ROUND(w.wau::NUMERIC / NULLIF(m.mau, 0), 2) AS wau_mau_ratio
FROM daily_active_users d
LEFT JOIN weekly_active_users w
    ON d.activity_date = w.activity_date
    AND d.neighborhood_id = w.neighborhood_id
LEFT JOIN monthly_active_users m
    ON d.activity_date = m.activity_date
    AND d.neighborhood_id = m.neighborhood_id
INNER JOIN neighborhoods n
    ON n.neighborhood_id = d.neighborhood_id 
ORDER BY d.activity_date, d.neighborhood_id;


-- =============================================================================
-- QUERY 3: New vs Returning Users (Growth Analysis)
-- =============================================================================
-- DASHBOARD USE CASE: Growth dashboard, acquisition vs retention breakdown
-- 
-- WHY THIS MATTERS: Healthy growth needs BOTH new users AND returning users.
--   - All new users = no retention (leaky bucket)
--   - All returning = no growth (stagnant)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- CTE: user_first_activity
-- WHAT: Finds the first activity date for each user
-- WHY:  Defines when a user "started". Any activity on this date = new user.
-- -----------------------------------------------------------------------------
WITH user_first_activity AS (
    SELECT 
        user_id,
        MIN(activity_date) AS first_activity_date
    FROM fct_user_engagement
    WHERE activity_type IN ('POST', 'COMMENT', 'REACTION')
    GROUP BY user_id
),

-- -----------------------------------------------------------------------------
-- CTE: daily_activity_with_status
-- WHAT: Tags each daily activity as 'NEW' or 'RETURNING'
-- WHY:  Enables splitting active users into acquisition vs retention buckets.
-- -----------------------------------------------------------------------------
daily_activity_with_status AS (
    SELECT 
        e.activity_date,
        e.user_id,
        e.neighborhood_id,
        CASE 
            WHEN e.activity_date = f.first_activity_date THEN 'NEW'
            ELSE 'RETURNING'
        END AS user_type
    FROM fct_user_engagement e
    INNER JOIN user_first_activity f ON e.user_id = f.user_id
    WHERE e.activity_type IN ('POST', 'COMMENT', 'REACTION')
)

-- -----------------------------------------------------------------------------
-- FINAL SELECT: Daily breakdown of new vs returning users
-- INTERVIEW TIP: "Returning user ratio" is a proxy for Day-N retention
-- -----------------------------------------------------------------------------
SELECT
    activity_date,
    n.name AS neighborhood_name,
    COUNT(DISTINCT user_id) AS total_active_users,
    COUNT(DISTINCT user_id) FILTER (WHERE user_type = 'NEW') AS new_users,
    COUNT(DISTINCT user_id) FILTER (WHERE user_type = 'RETURNING') AS returning_users,
    ROUND(
        COUNT(DISTINCT user_id) FILTER (WHERE user_type = 'RETURNING')::NUMERIC / 
        NULLIF(COUNT(DISTINCT user_id), 0), 
        2
    ) AS returning_user_ratio
FROM daily_activity_with_status d
INNER JOIN neighborhoods n 
    ON d.neighborhood_id = n.neighborhood_id
GROUP BY activity_date, n.name
ORDER BY activity_date, n.name;


-- =============================================================================
-- QUERY 4: Engagement by Day of Week & Hour (Temporal Patterns)
-- =============================================================================
-- DASHBOARD USE CASE: Best time to post analysis, operational scheduling
-- 
-- WHY THIS MATTERS: Helps users know when to post for maximum engagement,
--                   and helps ops teams know when to staff support.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- CTE: activity_with_time_parts
-- WHAT: Extracts day of week and hour from each activity timestamp
-- WHY:  Enables aggregation by time patterns across all dates.
-- 
-- PostgreSQL: EXTRACT(DOW FROM ...) returns 0=Sunday, 6=Saturday
-- -----------------------------------------------------------------------------
WITH activity_with_time_parts AS (
    SELECT
        user_id,
        activity_type,
        activity_datetime,
        EXTRACT(DOW FROM activity_datetime)::INTEGER AS day_of_week,
        EXTRACT(HOUR FROM activity_datetime)::INTEGER AS hour_of_day
    FROM fct_user_engagement
    WHERE activity_type IN ('POST', 'COMMENT', 'REACTION')
)

-- -----------------------------------------------------------------------------
-- FINAL SELECT: Activity volume by day of week and hour
-- VISUALIZATION: Heatmap with day on Y-axis, hour on X-axis, color = activity
-- -----------------------------------------------------------------------------
SELECT
    CASE day_of_week
        WHEN 0 THEN 'Sunday'
        WHEN 1 THEN 'Monday'
        WHEN 2 THEN 'Tuesday'
        WHEN 3 THEN 'Wednesday'
        WHEN 4 THEN 'Thursday'
        WHEN 5 THEN 'Friday'
        WHEN 6 THEN 'Saturday'
    END AS day_name,
    hour_of_day,
    COUNT(*) AS total_activities,
    COUNT(DISTINCT user_id) AS unique_users,
    COUNT(*) FILTER (WHERE activity_type = 'POST') AS posts,
    COUNT(*) FILTER (WHERE activity_type = 'COMMENT') AS comments,
    COUNT(*) FILTER (WHERE activity_type = 'REACTION') AS reactions
FROM activity_with_time_parts
GROUP BY day_of_week, hour_of_day
ORDER BY day_of_week, hour_of_day;


-- =============================================================================
-- QUERY 5: Top Neighborhoods by Engagement Score
-- =============================================================================
-- DASHBOARD USE CASE: Leaderboard, community health ranking
-- 
-- ENGAGEMENT SCORE FORMULA: Weighted combination of activities
--   Posts (highest effort) = 3 points
--   Comments (medium effort) = 2 points  
--   Reactions (low effort) = 1 point
-- =============================================================================

-- -----------------------------------------------------------------------------
-- CTE: neighborhood_activity
-- WHAT: Aggregates all activity counts per neighborhood
-- WHY:  Raw counts needed before applying weighted scoring.
-- -----------------------------------------------------------------------------
WITH neighborhood_activity AS (
    SELECT
        e.neighborhood_id,
        n.name AS neighborhood_name,
        n.population AS neighborhood_population,
        COUNT(*) FILTER (WHERE activity_type = 'POST') AS total_posts,
        COUNT(*) FILTER (WHERE activity_type = 'COMMENT') AS total_comments,
        COUNT(*) FILTER (WHERE activity_type = 'REACTION') AS total_reactions,
        COUNT(DISTINCT user_id) AS total_active_users
    FROM fct_user_engagement e
    INNER JOIN neighborhoods n 
        ON e.neighborhood_id = n.neighborhood_id
    WHERE activity_type IN ('POST', 'COMMENT', 'REACTION')
    GROUP BY e.neighborhood_id, n.name, n.population
)

-- -----------------------------------------------------------------------------
-- FINAL SELECT: Rankings by weighted engagement score
-- WHY PER-CAPITA: Normalizes for neighborhood size. A small active neighborhood
--                 may outperform a large passive one.
-- -----------------------------------------------------------------------------
SELECT
    neighborhood_name,
    neighborhood_population,
    total_posts,
    total_comments,
    total_reactions,
    total_active_users,
    
    -- Weighted engagement score
    (total_posts * 3 + total_comments * 2 + total_reactions * 1) AS engagement_score,
    
    -- Per-capita metrics (per 1000 residents)
    ROUND(total_active_users::NUMERIC / neighborhood_population * 1000, 2) AS active_users_per_1k,
    ROUND((total_posts * 3 + total_comments * 2 + total_reactions)::NUMERIC / neighborhood_population * 1000, 2) AS engagement_score_per_1k,
    
    -- Ranks
    RANK() OVER (ORDER BY (total_posts * 3 + total_comments * 2 + total_reactions) DESC) AS rank_by_engagement,
    RANK() OVER (ORDER BY total_active_users::NUMERIC / neighborhood_population DESC) AS rank_by_penetration

FROM neighborhood_activity
ORDER BY engagement_score DESC;


-- =============================================================================
-- QUERY 6: Week-over-Week Growth Rate
-- =============================================================================
-- DASHBOARD USE CASE: Growth trend chart, alert when growth slows
-- 
-- WHY WOW GROWTH: More stable than day-over-day, more responsive than MoM.
--                 Ideal for weekly standups and operational dashboards.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- CTE: weekly_metrics
-- WHAT: Aggregates key metrics by week
-- WHY:  Weekly granularity smooths daily noise while staying responsive.
-- -----------------------------------------------------------------------------
WITH weekly_metrics AS (
    SELECT
        DATE_TRUNC('week', activity_date)::DATE AS week_start,
        COUNT(DISTINCT user_id) AS weekly_active_users,
        COUNT(*) FILTER (WHERE activity_type = 'POST') AS weekly_posts,
        COUNT(*) AS total_activities
    FROM fct_user_engagement
    WHERE activity_type IN ('POST', 'COMMENT', 'REACTION')
    GROUP BY DATE_TRUNC('week', activity_date)
),

-- -----------------------------------------------------------------------------
-- CTE: weekly_with_prior
-- WHAT: Adds prior week's values using LAG window function
-- WHY:  Need both current and prior values to calculate growth rate.
-- -----------------------------------------------------------------------------
weekly_with_prior AS (
    SELECT
        week_start,
        weekly_active_users,
        weekly_posts,
        total_activities,
        LAG(weekly_active_users) OVER (ORDER BY week_start) AS prior_week_users,
        LAG(weekly_posts) OVER (ORDER BY week_start) AS prior_week_posts,
        LAG(total_activities) OVER (ORDER BY week_start) AS prior_week_activities
    FROM weekly_metrics
)

-- -----------------------------------------------------------------------------
-- FINAL SELECT: Week-over-week growth percentages
-- INTERPRETATION: +10% WoW = healthy growth, -5% WoW = needs investigation
-- -----------------------------------------------------------------------------
SELECT
    week_start,
    weekly_active_users,
    prior_week_users,
    ROUND((weekly_active_users - prior_week_users)::NUMERIC / NULLIF(prior_week_users, 0) * 100, 1) AS user_growth_pct,
    weekly_posts,
    prior_week_posts,
    ROUND((weekly_posts - prior_week_posts)::NUMERIC / NULLIF(prior_week_posts, 0) * 100, 1) AS post_growth_pct,
    total_activities,
    ROUND((total_activities - prior_week_activities)::NUMERIC / NULLIF(prior_week_activities, 0) * 100, 1) AS activity_growth_pct
FROM weekly_with_prior
WHERE prior_week_users IS NOT NULL  -- Exclude first week (no prior data)
ORDER BY week_start;
