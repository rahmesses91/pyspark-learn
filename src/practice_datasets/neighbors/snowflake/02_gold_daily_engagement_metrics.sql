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
--   - SEMANTIC_LAYER.SILVER.FCT_USER_ENGAGEMENT (from Step 1)
--   - SEMANTIC_LAYER.SILVER.DIM_NEIGHBORHOOD
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
-- CTE: USER_ENGAGEMENT
-- WHAT: Pulls all activity records from the silver layer fact table
-- WHY:  Acts as the base dataset. Using a CTE here allows us to add filters
--       (like date range) in one place without repeating in every aggregation.
-- -----------------------------------------------------------------------------
WITH USER_ENGAGEMENT AS (
    SELECT 
        USER_ID,
        POST_ID,
        NEIGHBORHOOD_ID,
        USER_STATUS,
        ACTIVITY_TYPE,
        EVENT_ID,
        ACTIVITY_DATETIME,
        ACTIVITY_DATE
    FROM SEMANTIC_LAYER.SILVER.FCT_USER_ENGAGEMENT
)

SELECT 
    ACTIVITY_DATE,
    NEIGHBORHOOD.NEIGHBORHOOD_NAME,
    
    -- Activity counts: Raw volume metrics
    SUM(CASE WHEN ACTIVITY_TYPE = 'POST' THEN 1 ELSE 0 END) AS TOTAL_POSTS,
    SUM(CASE WHEN ACTIVITY_TYPE = 'COMMENT' THEN 1 ELSE 0 END) AS TOTAL_COMMENTS,
    SUM(CASE WHEN ACTIVITY_TYPE = 'REACTION' THEN 1 ELSE 0 END) AS TOTAL_REACTIONS,
    
    -- User counts: Unique participants by activity type
    COUNT(DISTINCT USER_ID) AS TOTAL_USERS,
    COUNT(DISTINCT CASE WHEN ACTIVITY_TYPE = 'POST' THEN USER_ID END) AS TOTAL_POSTING_USERS,
    COUNT(DISTINCT CASE WHEN ACTIVITY_TYPE = 'COMMENT' THEN USER_ID END) AS TOTAL_COMMENTING_USERS,
    COUNT(DISTINCT CASE WHEN ACTIVITY_TYPE = 'REACTION' THEN USER_ID END) AS TOTAL_REACTING_USERS,
    COUNT(DISTINCT CASE WHEN ACTIVITY_TYPE = 'NO_ACTIVITY' THEN USER_ID END) AS TOTAL_INACTIVE_USERS

FROM USER_ENGAGEMENT
INNER JOIN SEMANTIC_LAYER.SILVER.DIM_NEIGHBORHOOD NEIGHBORHOOD
    ON USER_ENGAGEMENT.NEIGHBORHOOD_ID = NEIGHBORHOOD.NEIGHBORHOOD_ID
GROUP BY ACTIVITY_DATE, NEIGHBORHOOD_NAME
ORDER BY ACTIVITY_DATE, NEIGHBORHOOD_NAME;


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
-- CTE: ACTIVE_USERS
-- WHAT: Filters to only meaningful engagement (excludes NO_ACTIVITY users)
-- WHY:  For DAU/WAU/MAU, we only count users who actually DID something.
--       Signing up alone doesn't make you "active".
-- -----------------------------------------------------------------------------
WITH ACTIVE_USERS AS (
    SELECT 
        USER_ID,
        NEIGHBORHOOD_ID,
        ACTIVITY_DATE
    FROM SEMANTIC_LAYER.SILVER.FCT_USER_ENGAGEMENT
    WHERE ACTIVITY_TYPE IN ('POST', 'COMMENT', 'REACTION')
),

-- -----------------------------------------------------------------------------
-- CTE: DATE_SPINE
-- WHAT: Creates a complete list of date + neighborhood combinations
-- WHY:  Ensures we have a row for every day, even if there was zero activity.
--       Without this, gaps in data would cause misleading charts.
-- -----------------------------------------------------------------------------
DATE_SPINE AS (
    SELECT DISTINCT 
        ACTIVITY_DATE,
        NEIGHBORHOOD_ID
    FROM ACTIVE_USERS
),

-- -----------------------------------------------------------------------------
-- CTE: DAILY_ACTIVE_USERS
-- WHAT: Counts unique users per day per neighborhood
-- WHY:  This is the foundation - DAU is the most granular active user metric.
--       Everything else (WAU, MAU) builds on this concept.
-- -----------------------------------------------------------------------------
DAILY_ACTIVE_USERS AS (
    SELECT
        ACTIVITY_DATE,
        NEIGHBORHOOD_ID,
        COUNT(DISTINCT USER_ID) AS DAU
    FROM ACTIVE_USERS
    GROUP BY ACTIVITY_DATE, NEIGHBORHOOD_ID
),

-- -----------------------------------------------------------------------------
-- CTE: WEEKLY_ACTIVE_USERS
-- WHAT: Counts unique users in a rolling 7-day window ending on each date
-- WHY:  WAU smooths out daily volatility (weekends, holidays).
--       Rolling window (vs calendar week) provides continuous trend data.
-- 
-- TECHNICAL NOTE: We join back to ACTIVE_USERS with a date range condition.
--                 This counts each user once even if they were active multiple days.
-- -----------------------------------------------------------------------------
WEEKLY_ACTIVE_USERS AS (
    SELECT
        ds.ACTIVITY_DATE,
        ds.NEIGHBORHOOD_ID,
        COUNT(DISTINCT au.USER_ID) AS WAU
    FROM DATE_SPINE ds
    LEFT JOIN ACTIVE_USERS au
        ON au.NEIGHBORHOOD_ID = ds.NEIGHBORHOOD_ID
        AND au.ACTIVITY_DATE BETWEEN ds.ACTIVITY_DATE - INTERVAL '6 days' AND ds.ACTIVITY_DATE
    GROUP BY ds.ACTIVITY_DATE, ds.NEIGHBORHOOD_ID
),

-- -----------------------------------------------------------------------------
-- CTE: MONTHLY_ACTIVE_USERS
-- WHAT: Counts unique users in a rolling 30-day window ending on each date
-- WHY:  MAU is the standard "reach" metric for monthly reporting.
--       Investors and executives often track MAU as a headline number.
-- -----------------------------------------------------------------------------
MONTHLY_ACTIVE_USERS AS (
    SELECT
        ds.ACTIVITY_DATE,
        ds.NEIGHBORHOOD_ID,
        COUNT(DISTINCT au.USER_ID) AS MAU
    FROM DATE_SPINE ds
    LEFT JOIN ACTIVE_USERS au
        ON au.NEIGHBORHOOD_ID = ds.NEIGHBORHOOD_ID
        AND au.ACTIVITY_DATE BETWEEN ds.ACTIVITY_DATE - INTERVAL '29 days' AND ds.ACTIVITY_DATE
    GROUP BY ds.ACTIVITY_DATE, ds.NEIGHBORHOOD_ID
)

-- -----------------------------------------------------------------------------
-- FINAL SELECT: Combines DAU, WAU, MAU and calculates stickiness ratios
-- WHY RATIOS MATTER: Raw numbers grow with user base. Ratios show QUALITY.
--                    A growing DAU with falling DAU/MAU = concerning trend.
-- -----------------------------------------------------------------------------
SELECT
    d.ACTIVITY_DATE,
    NEIGHBORHOOD.NEIGHBORHOOD_NAME,
    d.DAU AS TOTAL_DAILY_ACTIVE_USERS,
    w.WAU AS TOTAL_WEEKLY_ACTIVE_USERS,
    m.MAU AS TOTAL_MONTHLY_ACTIVE_USERS,
    ROUND(d.DAU::NUMERIC / NULLIF(w.WAU, 0), 2) AS DAU_WAU_RATIO,
    ROUND(d.DAU::NUMERIC / NULLIF(m.MAU, 0), 2) AS DAU_MAU_RATIO,
    ROUND(w.WAU::NUMERIC / NULLIF(m.MAU, 0), 2) AS WAU_MAU_RATIO
FROM DAILY_ACTIVE_USERS d
LEFT JOIN WEEKLY_ACTIVE_USERS w
    ON d.ACTIVITY_DATE = w.ACTIVITY_DATE
    AND d.NEIGHBORHOOD_ID = w.NEIGHBORHOOD_ID
LEFT JOIN MONTHLY_ACTIVE_USERS m
    ON d.ACTIVITY_DATE = m.ACTIVITY_DATE
    AND d.NEIGHBORHOOD_ID = m.NEIGHBORHOOD_ID
INNER JOIN SEMANTIC_LAYER.SILVER.DIM_NEIGHBORHOOD NEIGHBORHOOD
    ON NEIGHBORHOOD.NEIGHBORHOOD_ID = d.NEIGHBORHOOD_ID 
ORDER BY d.ACTIVITY_DATE, d.NEIGHBORHOOD_ID;


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
-- CTE: USER_FIRST_ACTIVITY
-- WHAT: Finds the first activity date for each user
-- WHY:  Defines when a user "started". Any activity on this date = new user.
-- -----------------------------------------------------------------------------
WITH USER_FIRST_ACTIVITY AS (
    SELECT 
        USER_ID,
        MIN(ACTIVITY_DATE) AS FIRST_ACTIVITY_DATE
    FROM SEMANTIC_LAYER.SILVER.FCT_USER_ENGAGEMENT
    WHERE ACTIVITY_TYPE IN ('POST', 'COMMENT', 'REACTION')
    GROUP BY USER_ID
),

-- -----------------------------------------------------------------------------
-- CTE: DAILY_ACTIVITY_WITH_STATUS
-- WHAT: Tags each daily activity as 'NEW' or 'RETURNING'
-- WHY:  Enables splitting active users into acquisition vs retention buckets.
-- -----------------------------------------------------------------------------
DAILY_ACTIVITY_WITH_STATUS AS (
    SELECT 
        e.ACTIVITY_DATE,
        e.USER_ID,
        e.NEIGHBORHOOD_ID,
        CASE 
            WHEN e.ACTIVITY_DATE = f.FIRST_ACTIVITY_DATE THEN 'NEW'
            ELSE 'RETURNING'
        END AS USER_TYPE
    FROM SEMANTIC_LAYER.SILVER.FCT_USER_ENGAGEMENT e
    INNER JOIN USER_FIRST_ACTIVITY f ON e.USER_ID = f.USER_ID
    WHERE e.ACTIVITY_TYPE IN ('POST', 'COMMENT', 'REACTION')
)

-- -----------------------------------------------------------------------------
-- FINAL SELECT: Daily breakdown of new vs returning users
-- INTERVIEW TIP: "Returning user ratio" is a proxy for Day-N retention
-- -----------------------------------------------------------------------------
SELECT
    ACTIVITY_DATE,
    n.NEIGHBORHOOD_NAME,
    COUNT(DISTINCT USER_ID) AS TOTAL_ACTIVE_USERS,
    COUNT(DISTINCT CASE WHEN USER_TYPE = 'NEW' THEN USER_ID END) AS NEW_USERS,
    COUNT(DISTINCT CASE WHEN USER_TYPE = 'RETURNING' THEN USER_ID END) AS RETURNING_USERS,
    ROUND(
        COUNT(DISTINCT CASE WHEN USER_TYPE = 'RETURNING' THEN USER_ID END)::NUMERIC / 
        NULLIF(COUNT(DISTINCT USER_ID), 0), 
        2
    ) AS RETURNING_USER_RATIO
FROM DAILY_ACTIVITY_WITH_STATUS d
INNER JOIN SEMANTIC_LAYER.SILVER.DIM_NEIGHBORHOOD n 
    ON d.NEIGHBORHOOD_ID = n.NEIGHBORHOOD_ID
GROUP BY ACTIVITY_DATE, n.NEIGHBORHOOD_NAME
ORDER BY ACTIVITY_DATE, n.NEIGHBORHOOD_NAME;


-- =============================================================================
-- QUERY 4: Engagement by Day of Week & Hour (Temporal Patterns)
-- =============================================================================
-- DASHBOARD USE CASE: Best time to post analysis, operational scheduling
-- 
-- WHY THIS MATTERS: Helps users know when to post for maximum engagement,
--                   and helps ops teams know when to staff support.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- CTE: ACTIVITY_WITH_TIME_PARTS
-- WHAT: Extracts day of week and hour from each activity timestamp
-- WHY:  Enables aggregation by time patterns across all dates.
-- -----------------------------------------------------------------------------
WITH ACTIVITY_WITH_TIME_PARTS AS (
    SELECT
        USER_ID,
        ACTIVITY_TYPE,
        ACTIVITY_DATETIME,
        DAYOFWEEK(ACTIVITY_DATETIME) AS DAY_OF_WEEK,  -- 0=Sunday, 6=Saturday
        HOUR(ACTIVITY_DATETIME) AS HOUR_OF_DAY
    FROM SEMANTIC_LAYER.SILVER.FCT_USER_ENGAGEMENT
    WHERE ACTIVITY_TYPE IN ('POST', 'COMMENT', 'REACTION')
)

-- -----------------------------------------------------------------------------
-- FINAL SELECT: Activity volume by day of week and hour
-- VISUALIZATION: Heatmap with day on Y-axis, hour on X-axis, color = activity
-- -----------------------------------------------------------------------------
SELECT
    CASE DAY_OF_WEEK
        WHEN 0 THEN 'Sunday'
        WHEN 1 THEN 'Monday'
        WHEN 2 THEN 'Tuesday'
        WHEN 3 THEN 'Wednesday'
        WHEN 4 THEN 'Thursday'
        WHEN 5 THEN 'Friday'
        WHEN 6 THEN 'Saturday'
    END AS DAY_NAME,
    HOUR_OF_DAY,
    COUNT(*) AS TOTAL_ACTIVITIES,
    COUNT(DISTINCT USER_ID) AS UNIQUE_USERS,
    SUM(CASE WHEN ACTIVITY_TYPE = 'POST' THEN 1 ELSE 0 END) AS POSTS,
    SUM(CASE WHEN ACTIVITY_TYPE = 'COMMENT' THEN 1 ELSE 0 END) AS COMMENTS,
    SUM(CASE WHEN ACTIVITY_TYPE = 'REACTION' THEN 1 ELSE 0 END) AS REACTIONS
FROM ACTIVITY_WITH_TIME_PARTS
GROUP BY DAY_OF_WEEK, HOUR_OF_DAY
ORDER BY DAY_OF_WEEK, HOUR_OF_DAY;


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
-- CTE: NEIGHBORHOOD_ACTIVITY
-- WHAT: Aggregates all activity counts per neighborhood
-- WHY:  Raw counts needed before applying weighted scoring.
-- -----------------------------------------------------------------------------
WITH NEIGHBORHOOD_ACTIVITY AS (
    SELECT
        e.NEIGHBORHOOD_ID,
        n.NEIGHBORHOOD_NAME,
        n.POPULATION AS NEIGHBORHOOD_POPULATION,
        COUNT_IF(ACTIVITY_TYPE = 'POST') AS TOTAL_POSTS,
        COUNT_IF(ACTIVITY_TYPE = 'COMMENT') AS TOTAL_COMMENTS,
        COUNT_IF(ACTIVITY_TYPE = 'REACTION') AS TOTAL_REACTIONS,
        COUNT(DISTINCT USER_ID) AS TOTAL_ACTIVE_USERS
    FROM SEMANTIC_LAYER.SILVER.FCT_USER_ENGAGEMENT e
    INNER JOIN SEMANTIC_LAYER.SILVER.DIM_NEIGHBORHOOD n 
        ON e.NEIGHBORHOOD_ID = n.NEIGHBORHOOD_ID
    WHERE ACTIVITY_TYPE IN ('POST', 'COMMENT', 'REACTION')
    GROUP BY e.NEIGHBORHOOD_ID, n.NEIGHBORHOOD_NAME, n.POPULATION
)

-- -----------------------------------------------------------------------------
-- FINAL SELECT: Rankings by weighted engagement score
-- WHY PER-CAPITA: Normalizes for neighborhood size. A small active neighborhood
--                 may outperform a large passive one.
-- -----------------------------------------------------------------------------
SELECT
    NEIGHBORHOOD_NAME,
    NEIGHBORHOOD_POPULATION,
    TOTAL_POSTS,
    TOTAL_COMMENTS,
    TOTAL_REACTIONS,
    TOTAL_ACTIVE_USERS,
    
    -- Weighted engagement score
    (TOTAL_POSTS * 3 + TOTAL_COMMENTS * 2 + TOTAL_REACTIONS * 1) AS ENGAGEMENT_SCORE,
    
    -- Per-capita metrics (per 1000 residents)
    ROUND(TOTAL_ACTIVE_USERS::NUMERIC / NEIGHBORHOOD_POPULATION * 1000, 2) AS ACTIVE_USERS_PER_1K,
    ROUND((TOTAL_POSTS * 3 + TOTAL_COMMENTS * 2 + TOTAL_REACTIONS)::NUMERIC / NEIGHBORHOOD_POPULATION * 1000, 2) AS ENGAGEMENT_SCORE_PER_1K,
    
    -- Ranks
    RANK() OVER (ORDER BY (TOTAL_POSTS * 3 + TOTAL_COMMENTS * 2 + TOTAL_REACTIONS) DESC) AS RANK_BY_ENGAGEMENT,
    RANK() OVER (ORDER BY TOTAL_ACTIVE_USERS::NUMERIC / NEIGHBORHOOD_POPULATION DESC) AS RANK_BY_PENETRATION

FROM NEIGHBORHOOD_ACTIVITY
ORDER BY ENGAGEMENT_SCORE DESC;


-- =============================================================================
-- QUERY 6: Week-over-Week Growth Rate
-- =============================================================================
-- DASHBOARD USE CASE: Growth trend chart, alert when growth slows
-- 
-- WHY WOW GROWTH: More stable than day-over-day, more responsive than MoM.
--                 Ideal for weekly standups and operational dashboards.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- CTE: WEEKLY_METRICS
-- WHAT: Aggregates key metrics by week
-- WHY:  Weekly granularity smooths daily noise while staying responsive.
-- -----------------------------------------------------------------------------
WITH WEEKLY_METRICS AS (
    SELECT
        DATE_TRUNC('week', ACTIVITY_DATE) AS WEEK_START,
        COUNT(DISTINCT USER_ID) AS WEEKLY_ACTIVE_USERS,
        COUNT_IF(ACTIVITY_TYPE = 'POST') AS WEEKLY_POSTS,
        COUNT(*) AS TOTAL_ACTIVITIES
    FROM SEMANTIC_LAYER.SILVER.FCT_USER_ENGAGEMENT
    WHERE ACTIVITY_TYPE IN ('POST', 'COMMENT', 'REACTION')
    GROUP BY DATE_TRUNC('week', ACTIVITY_DATE)
),

-- -----------------------------------------------------------------------------
-- CTE: WEEKLY_WITH_PRIOR
-- WHAT: Adds prior week's values using LAG window function
-- WHY:  Need both current and prior values to calculate growth rate.
-- -----------------------------------------------------------------------------
WEEKLY_WITH_PRIOR AS (
    SELECT
        WEEK_START,
        WEEKLY_ACTIVE_USERS,
        WEEKLY_POSTS,
        TOTAL_ACTIVITIES,
        LAG(WEEKLY_ACTIVE_USERS) OVER (ORDER BY WEEK_START) AS PRIOR_WEEK_USERS,
        LAG(WEEKLY_POSTS) OVER (ORDER BY WEEK_START) AS PRIOR_WEEK_POSTS,
        LAG(TOTAL_ACTIVITIES) OVER (ORDER BY WEEK_START) AS PRIOR_WEEK_ACTIVITIES
    FROM WEEKLY_METRICS
)

-- -----------------------------------------------------------------------------
-- FINAL SELECT: Week-over-week growth percentages
-- INTERPRETATION: +10% WoW = healthy growth, -5% WoW = needs investigation
-- -----------------------------------------------------------------------------
SELECT
    WEEK_START,
    WEEKLY_ACTIVE_USERS,
    PRIOR_WEEK_USERS,
    ROUND((WEEKLY_ACTIVE_USERS - PRIOR_WEEK_USERS)::NUMERIC / NULLIF(PRIOR_WEEK_USERS, 0) * 100, 1) AS USER_GROWTH_PCT,
    WEEKLY_POSTS,
    PRIOR_WEEK_POSTS,
    ROUND((WEEKLY_POSTS - PRIOR_WEEK_POSTS)::NUMERIC / NULLIF(PRIOR_WEEK_POSTS, 0) * 100, 1) AS POST_GROWTH_PCT,
    TOTAL_ACTIVITIES,
    ROUND((TOTAL_ACTIVITIES - PRIOR_WEEK_ACTIVITIES)::NUMERIC / NULLIF(PRIOR_WEEK_ACTIVITIES, 0) * 100, 1) AS ACTIVITY_GROWTH_PCT
FROM WEEKLY_WITH_PRIOR
WHERE PRIOR_WEEK_USERS IS NOT NULL  -- Exclude first week (no prior data)
ORDER BY WEEK_START;
