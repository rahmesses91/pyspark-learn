-- ============================================================================
-- STEP 3: GOLD LAYER - User Engagement Funnel Analysis
-- ============================================================================
-- PURPOSE: Analyze user conversion through the engagement funnel:
--          Post → Comment → Reaction
--          
-- WHY FUNNELS MATTER:
--   - Identify where users drop off in the engagement journey
--   - Measure the effectiveness of features that drive deeper engagement
--   - Compare funnel performance across segments (neighborhoods, cohorts)
--
-- DEPENDS ON:
--   - SEMANTIC_LAYER.SILVER.FCT_USER_ENGAGEMENT (from Step 1)
--
-- INTERVIEW TIP: Funnels are CLASSIC dashboard questions. Be ready to:
--   1. Define the funnel stages clearly
--   2. Calculate conversion rates between stages
--   3. Segment by different dimensions
--   4. Identify drop-off points
-- ============================================================================


-- =============================================================================
-- QUERY 1: Overall Engagement Funnel
-- =============================================================================
-- DASHBOARD USE CASE: Funnel visualization (bar chart or funnel graphic)
-- WHAT IT SHOWS: Of all users who posted, what % also commented/reacted?
-- =============================================================================

-- -----------------------------------------------------------------------------
-- CTE: BASE
-- WHAT: Filters to only relevant activity types for the funnel
-- WHY:  NO_ACTIVITY users shouldn't be in engagement funnels - they never
--       entered the funnel in the first place.
-- -----------------------------------------------------------------------------
WITH BASE AS (
    SELECT
        USER_ID,
        ACTIVITY_TYPE,
        ACTIVITY_DATE
    FROM SEMANTIC_LAYER.SILVER.FCT_USER_ENGAGEMENT
    WHERE ACTIVITY_TYPE IN ('POST', 'COMMENT', 'REACTION')
),

-- -----------------------------------------------------------------------------
-- CTE: FIRST_EVENTS
-- WHAT: Finds the FIRST time each user did each activity type
-- WHY:  For funnel analysis, we care about whether a user EVER did something,
--       not how many times. Using MIN(date) identifies their first instance.
-- 
-- TECHNICAL NOTE: CASE inside MIN gives us NULL if user never did that activity
-- -----------------------------------------------------------------------------
FIRST_EVENTS AS (
    SELECT
        USER_ID,
        MIN(CASE WHEN ACTIVITY_TYPE = 'POST' THEN ACTIVITY_DATE END) AS FIRST_POST,
        MIN(CASE WHEN ACTIVITY_TYPE = 'COMMENT' THEN ACTIVITY_DATE END) AS FIRST_COMMENT,
        MIN(CASE WHEN ACTIVITY_TYPE = 'REACTION' THEN ACTIVITY_DATE END) AS FIRST_REACTION
    FROM BASE
    GROUP BY USER_ID
),

-- -----------------------------------------------------------------------------
-- CTE: FUNNEL
-- WHAT: Counts users at each funnel stage
-- WHY:  These raw counts become the numerators/denominators for conversion rates.
--
-- COUNT_IF is Snowflake-specific: counts rows where condition is true
-- Equivalent to: COUNT(CASE WHEN condition THEN 1 END)
-- -----------------------------------------------------------------------------
FUNNEL AS (
    SELECT
        COUNT(*) AS POSTED,
        COUNT_IF(FIRST_COMMENT IS NOT NULL) AS COMMENTED,
        COUNT_IF(FIRST_REACTION IS NOT NULL) AS REACTED
    FROM FIRST_EVENTS
)

-- -----------------------------------------------------------------------------
-- FINAL SELECT: Funnel metrics with conversion rates
-- 
-- INTERPRETATION:
--   PCT_POST_TO_COMMENT: Are posts generating discussion? (Target: 30-50%)
--   PCT_COMMENT_TO_REACTION: Are commenters also reacting? (Target: 40-60%)
--   PCT_POST_TO_REACTION: Overall engagement depth (Target: 25-40%)
-- -----------------------------------------------------------------------------
SELECT
    POSTED AS USERS_WHO_POSTED,
    COMMENTED AS USERS_WHO_COMMENTED,
    REACTED AS USERS_WHO_REACTED,
    ROUND(COMMENTED / POSTED::FLOAT, 4) AS PCT_POST_TO_COMMENT,
    ROUND(REACTED / NULLIF(COMMENTED, 0)::FLOAT, 4) AS PCT_COMMENT_TO_REACTION,
    ROUND(REACTED / POSTED::FLOAT, 4) AS PCT_POST_TO_REACTION
FROM FUNNEL;


-- =============================================================================
-- QUERY 2: Funnel by Neighborhood (Segmented Analysis)
-- =============================================================================
-- DASHBOARD USE CASE: Compare funnel performance across neighborhoods
-- WHY SEGMENT: Different communities may have different engagement patterns.
--              Low-converting neighborhoods might need intervention.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- CTE: USER_NEIGHBORHOOD
-- WHAT: Maps each user to their primary neighborhood
-- WHY:  Users might post in multiple neighborhoods. We pick their most
--       frequent one to avoid counting them multiple times.
-- -----------------------------------------------------------------------------
WITH USER_NEIGHBORHOOD AS (
    SELECT 
        USER_ID,
        NEIGHBORHOOD_ID,
        ROW_NUMBER() OVER (
            PARTITION BY USER_ID 
            ORDER BY COUNT(*) DESC
        ) AS RN
    FROM SEMANTIC_LAYER.SILVER.FCT_USER_ENGAGEMENT
    WHERE ACTIVITY_TYPE IN ('POST', 'COMMENT', 'REACTION')
    GROUP BY USER_ID, NEIGHBORHOOD_ID
),

-- -----------------------------------------------------------------------------
-- CTE: PRIMARY_NEIGHBORHOOD
-- WHAT: Keeps only each user's primary (most active) neighborhood
-- WHY:  Deduplicates users for accurate funnel counts.
-- -----------------------------------------------------------------------------
PRIMARY_NEIGHBORHOOD AS (
    SELECT USER_ID, NEIGHBORHOOD_ID
    FROM USER_NEIGHBORHOOD
    WHERE RN = 1
),

-- -----------------------------------------------------------------------------
-- CTE: BASE
-- WHAT: Activity data filtered to funnel-relevant types
-- WHY:  Same as Query 1, but will be joined with neighborhood data.
-- -----------------------------------------------------------------------------
BASE AS (
    SELECT
        USER_ID,
        ACTIVITY_TYPE,
        ACTIVITY_DATE
    FROM SEMANTIC_LAYER.SILVER.FCT_USER_ENGAGEMENT
    WHERE ACTIVITY_TYPE IN ('POST', 'COMMENT', 'REACTION')
),

-- -----------------------------------------------------------------------------
-- CTE: FIRST_EVENTS
-- WHAT: First occurrence of each activity type per user
-- WHY:  Same logic as Query 1 - we care about "did they ever" not "how many"
-- -----------------------------------------------------------------------------
FIRST_EVENTS AS (
    SELECT
        USER_ID,
        MIN(CASE WHEN ACTIVITY_TYPE = 'POST' THEN ACTIVITY_DATE END) AS FIRST_POST,
        MIN(CASE WHEN ACTIVITY_TYPE = 'COMMENT' THEN ACTIVITY_DATE END) AS FIRST_COMMENT,
        MIN(CASE WHEN ACTIVITY_TYPE = 'REACTION' THEN ACTIVITY_DATE END) AS FIRST_REACTION
    FROM BASE
    GROUP BY USER_ID
),

-- -----------------------------------------------------------------------------
-- CTE: FUNNEL_BY_NEIGHBORHOOD
-- WHAT: Joins funnel data with neighborhood and aggregates
-- WHY:  Creates the segmented view we need for comparison.
-- -----------------------------------------------------------------------------
FUNNEL_BY_NEIGHBORHOOD AS (
    SELECT
        n.NEIGHBORHOOD_NAME,
        COUNT(*) AS POSTED,
        COUNT_IF(fe.FIRST_COMMENT IS NOT NULL) AS COMMENTED,
        COUNT_IF(fe.FIRST_REACTION IS NOT NULL) AS REACTED
    FROM FIRST_EVENTS fe
    INNER JOIN PRIMARY_NEIGHBORHOOD pn ON fe.USER_ID = pn.USER_ID
    INNER JOIN SEMANTIC_LAYER.SILVER.DIM_NEIGHBORHOOD n ON pn.NEIGHBORHOOD_ID = n.NEIGHBORHOOD_ID
    GROUP BY n.NEIGHBORHOOD_NAME
)

-- -----------------------------------------------------------------------------
-- FINAL SELECT: Funnel metrics by neighborhood with ranking
-- RANKING: Helps identify best and worst performing neighborhoods
-- -----------------------------------------------------------------------------
SELECT
    NEIGHBORHOOD_NAME,
    POSTED AS USERS_WHO_POSTED,
    COMMENTED AS USERS_WHO_COMMENTED,
    REACTED AS USERS_WHO_REACTED,
    ROUND(COMMENTED / POSTED::FLOAT, 4) AS PCT_POST_TO_COMMENT,
    ROUND(REACTED / NULLIF(COMMENTED, 0)::FLOAT, 4) AS PCT_COMMENT_TO_REACTION,
    ROUND(REACTED / POSTED::FLOAT, 4) AS PCT_POST_TO_REACTION,
    RANK() OVER (ORDER BY REACTED / POSTED::FLOAT DESC) AS RANK_BY_CONVERSION
FROM FUNNEL_BY_NEIGHBORHOOD
ORDER BY PCT_POST_TO_REACTION DESC;


-- =============================================================================
-- QUERY 3: Time-to-Convert Funnel (How quickly do users progress?)
-- =============================================================================
-- DASHBOARD USE CASE: Time-to-value analysis, onboarding effectiveness
-- WHY: Fast conversion = healthy engagement. Slow conversion = friction.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- CTE: FIRST_EVENTS_WITH_DATES
-- WHAT: Gets the exact dates for each user's first activity of each type
-- WHY:  We need dates to calculate the time delta between stages.
-- -----------------------------------------------------------------------------
WITH FIRST_EVENTS_WITH_DATES AS (
    SELECT
        USER_ID,
        MIN(CASE WHEN ACTIVITY_TYPE = 'POST' THEN ACTIVITY_DATE END) AS FIRST_POST_DATE,
        MIN(CASE WHEN ACTIVITY_TYPE = 'COMMENT' THEN ACTIVITY_DATE END) AS FIRST_COMMENT_DATE,
        MIN(CASE WHEN ACTIVITY_TYPE = 'REACTION' THEN ACTIVITY_DATE END) AS FIRST_REACTION_DATE
    FROM SEMANTIC_LAYER.SILVER.FCT_USER_ENGAGEMENT
    WHERE ACTIVITY_TYPE IN ('POST', 'COMMENT', 'REACTION')
    GROUP BY USER_ID
),

-- -----------------------------------------------------------------------------
-- CTE: TIME_DELTAS
-- WHAT: Calculates days between each funnel stage
-- WHY:  Shows how long it takes users to progress through the funnel.
--
-- DATEDIFF returns the number of day boundaries crossed between two dates
-- -----------------------------------------------------------------------------
TIME_DELTAS AS (
    SELECT
        USER_ID,
        FIRST_POST_DATE,
        FIRST_COMMENT_DATE,
        FIRST_REACTION_DATE,
        DATEDIFF(day, FIRST_POST_DATE, FIRST_COMMENT_DATE) AS DAYS_POST_TO_COMMENT,
        DATEDIFF(day, FIRST_COMMENT_DATE, FIRST_REACTION_DATE) AS DAYS_COMMENT_TO_REACTION,
        DATEDIFF(day, FIRST_POST_DATE, FIRST_REACTION_DATE) AS DAYS_POST_TO_REACTION
    FROM FIRST_EVENTS_WITH_DATES
    WHERE FIRST_POST_DATE IS NOT NULL  -- Must have at least posted
)

-- -----------------------------------------------------------------------------
-- FINAL SELECT: Distribution of time-to-convert
-- MEDIAN: More robust than average (outliers don't skew it)
-- PERCENTILES: Show the full distribution shape
-- -----------------------------------------------------------------------------
SELECT
    'Post to Comment' AS FUNNEL_STAGE,
    COUNT(*) AS USERS_CONVERTED,
    ROUND(AVG(DAYS_POST_TO_COMMENT), 1) AS AVG_DAYS,
    MEDIAN(DAYS_POST_TO_COMMENT) AS MEDIAN_DAYS,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY DAYS_POST_TO_COMMENT) AS P25_DAYS,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY DAYS_POST_TO_COMMENT) AS P75_DAYS
FROM TIME_DELTAS
WHERE DAYS_POST_TO_COMMENT IS NOT NULL

UNION ALL

SELECT
    'Comment to Reaction' AS FUNNEL_STAGE,
    COUNT(*) AS USERS_CONVERTED,
    ROUND(AVG(DAYS_COMMENT_TO_REACTION), 1) AS AVG_DAYS,
    MEDIAN(DAYS_COMMENT_TO_REACTION) AS MEDIAN_DAYS,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY DAYS_COMMENT_TO_REACTION) AS P25_DAYS,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY DAYS_COMMENT_TO_REACTION) AS P75_DAYS
FROM TIME_DELTAS
WHERE DAYS_COMMENT_TO_REACTION IS NOT NULL

UNION ALL

SELECT
    'Post to Reaction (Overall)' AS FUNNEL_STAGE,
    COUNT(*) AS USERS_CONVERTED,
    ROUND(AVG(DAYS_POST_TO_REACTION), 1) AS AVG_DAYS,
    MEDIAN(DAYS_POST_TO_REACTION) AS MEDIAN_DAYS,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY DAYS_POST_TO_REACTION) AS P25_DAYS,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY DAYS_POST_TO_REACTION) AS P75_DAYS
FROM TIME_DELTAS
WHERE DAYS_POST_TO_REACTION IS NOT NULL;


-- =============================================================================
-- QUERY 4: Post Engagement Quality (Which posts drive engagement?)
-- =============================================================================
-- DASHBOARD USE CASE: Content performance analysis, viral post detection
-- WHY: Understanding what makes a successful post helps users create better content
-- =============================================================================

-- -----------------------------------------------------------------------------
-- CTE: POST_ENGAGEMENT
-- WHAT: Aggregates engagement metrics for each post
-- WHY:  Posts with high comments + reactions are "successful" content.
--       This helps identify patterns in high-performing content.
-- -----------------------------------------------------------------------------
WITH POST_ENGAGEMENT AS (
    SELECT
        p.POST_ID,
        p.USER_ID AS AUTHOR_ID,
        p.NEIGHBORHOOD_ID,
        p.CATEGORY,
        p.CREATED_AT AS POST_DATE,
        COUNT(DISTINCT c.COMMENT_ID) AS COMMENT_COUNT,
        COUNT(DISTINCT r.REACTION_ID) AS REACTION_COUNT
    FROM INTERVIEW_PREP.NEXTDOOR.POST p
    LEFT JOIN INTERVIEW_PREP.NEXTDOOR.COMMENTS c ON p.POST_ID = c.POST_ID
    LEFT JOIN INTERVIEW_PREP.NEXTDOOR.REACTIONS r ON p.POST_ID = r.POST_ID
    GROUP BY p.POST_ID, p.USER_ID, p.NEIGHBORHOOD_ID, p.CATEGORY, p.CREATED_AT
)

-- -----------------------------------------------------------------------------
-- FINAL SELECT: Engagement metrics by category with post-level stats
-- INTERVIEW TIP: This could power a "which category performs best?" analysis
-- -----------------------------------------------------------------------------
SELECT
    CATEGORY,
    COUNT(*) AS TOTAL_POSTS,
    SUM(COMMENT_COUNT) AS TOTAL_COMMENTS,
    SUM(REACTION_COUNT) AS TOTAL_REACTIONS,
    ROUND(AVG(COMMENT_COUNT), 2) AS AVG_COMMENTS_PER_POST,
    ROUND(AVG(REACTION_COUNT), 2) AS AVG_REACTIONS_PER_POST,
    
    -- Engagement rate: % of posts that got at least one response
    ROUND(COUNT_IF(COMMENT_COUNT > 0 OR REACTION_COUNT > 0)::FLOAT / COUNT(*), 4) AS ENGAGEMENT_RATE,
    
    -- Viral detection: posts with 5+ comments AND 10+ reactions
    COUNT_IF(COMMENT_COUNT >= 5 AND REACTION_COUNT >= 10) AS VIRAL_POSTS
    
FROM POST_ENGAGEMENT
GROUP BY CATEGORY
ORDER BY ENGAGEMENT_RATE DESC;
