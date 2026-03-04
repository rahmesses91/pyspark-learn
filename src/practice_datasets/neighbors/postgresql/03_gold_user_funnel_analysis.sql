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
--   - fct_user_engagement (from Step 1)
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
-- CTE: base
-- WHAT: Filters to only relevant activity types for the funnel
-- WHY:  NO_ACTIVITY users shouldn't be in engagement funnels - they never
--       entered the funnel in the first place.
-- -----------------------------------------------------------------------------
WITH base AS (
    SELECT
        user_id,
        activity_type,
        activity_date
    FROM fct_user_engagement
    WHERE activity_type IN ('POST', 'COMMENT', 'REACTION')
),

-- -----------------------------------------------------------------------------
-- CTE: first_events
-- WHAT: Finds the FIRST time each user did each activity type
-- WHY:  For funnel analysis, we care about whether a user EVER did something,
--       not how many times. Using MIN(date) identifies their first instance.
-- 
-- TECHNICAL NOTE: CASE inside MIN gives us NULL if user never did that activity
-- -----------------------------------------------------------------------------
first_events AS (
    SELECT
        user_id,
        MIN(CASE WHEN activity_type = 'POST' THEN activity_date END) AS first_post,
        MIN(CASE WHEN activity_type = 'COMMENT' THEN activity_date END) AS first_comment,
        MIN(CASE WHEN activity_type = 'REACTION' THEN activity_date END) AS first_reaction
    FROM base
    GROUP BY user_id
),

-- -----------------------------------------------------------------------------
-- CTE: funnel
-- WHAT: Counts users at each funnel stage
-- WHY:  These raw counts become the numerators/denominators for conversion rates.
--
-- PostgreSQL uses FILTER (WHERE condition) instead of Snowflake's COUNT_IF
-- -----------------------------------------------------------------------------
funnel AS (
    SELECT
        COUNT(*) AS posted,
        COUNT(*) FILTER (WHERE first_comment IS NOT NULL) AS commented,
        COUNT(*) FILTER (WHERE first_reaction IS NOT NULL) AS reacted
    FROM first_events
)

-- -----------------------------------------------------------------------------
-- FINAL SELECT: Funnel metrics with conversion rates
-- 
-- INTERPRETATION:
--   pct_post_to_comment: Are posts generating discussion? (Target: 30-50%)
--   pct_comment_to_reaction: Are commenters also reacting? (Target: 40-60%)
--   pct_post_to_reaction: Overall engagement depth (Target: 25-40%)
-- -----------------------------------------------------------------------------
SELECT
    posted AS users_who_posted,
    commented AS users_who_commented,
    reacted AS users_who_reacted,
    ROUND(commented::NUMERIC / NULLIF(posted, 0), 4) AS pct_post_to_comment,
    ROUND(reacted::NUMERIC / NULLIF(commented, 0), 4) AS pct_comment_to_reaction,
    ROUND(reacted::NUMERIC / NULLIF(posted, 0), 4) AS pct_post_to_reaction
FROM funnel;


-- =============================================================================
-- QUERY 2: Funnel by Neighborhood (Segmented Analysis)
-- =============================================================================
-- DASHBOARD USE CASE: Compare funnel performance across neighborhoods
-- WHY SEGMENT: Different communities may have different engagement patterns.
--              Low-converting neighborhoods might need intervention.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- CTE: user_neighborhood
-- WHAT: Maps each user to their primary neighborhood
-- WHY:  Users might post in multiple neighborhoods. We pick their most
--       frequent one to avoid counting them multiple times.
-- -----------------------------------------------------------------------------
WITH user_neighborhood AS (
    SELECT 
        user_id,
        neighborhood_id,
        ROW_NUMBER() OVER (
            PARTITION BY user_id 
            ORDER BY COUNT(*) DESC
        ) AS rn
    FROM fct_user_engagement
    WHERE activity_type IN ('POST', 'COMMENT', 'REACTION')
    GROUP BY user_id, neighborhood_id
),

-- -----------------------------------------------------------------------------
-- CTE: primary_neighborhood
-- WHAT: Keeps only each user's primary (most active) neighborhood
-- WHY:  Deduplicates users for accurate funnel counts.
-- -----------------------------------------------------------------------------
primary_neighborhood AS (
    SELECT user_id, neighborhood_id
    FROM user_neighborhood
    WHERE rn = 1
),

-- -----------------------------------------------------------------------------
-- CTE: base
-- WHAT: Activity data filtered to funnel-relevant types
-- WHY:  Same as Query 1, but will be joined with neighborhood data.
-- -----------------------------------------------------------------------------
base AS (
    SELECT
        user_id,
        activity_type,
        activity_date
    FROM fct_user_engagement
    WHERE activity_type IN ('POST', 'COMMENT', 'REACTION')
),

-- -----------------------------------------------------------------------------
-- CTE: first_events
-- WHAT: First occurrence of each activity type per user
-- WHY:  Same logic as Query 1 - we care about "did they ever" not "how many"
-- -----------------------------------------------------------------------------
first_events AS (
    SELECT
        user_id,
        MIN(CASE WHEN activity_type = 'POST' THEN activity_date END) AS first_post,
        MIN(CASE WHEN activity_type = 'COMMENT' THEN activity_date END) AS first_comment,
        MIN(CASE WHEN activity_type = 'REACTION' THEN activity_date END) AS first_reaction
    FROM base
    GROUP BY user_id
),

-- -----------------------------------------------------------------------------
-- CTE: funnel_by_neighborhood
-- WHAT: Joins funnel data with neighborhood and aggregates
-- WHY:  Creates the segmented view we need for comparison.
-- -----------------------------------------------------------------------------
funnel_by_neighborhood AS (
    SELECT
        n.name AS neighborhood_name,
        COUNT(*) AS posted,
        COUNT(*) FILTER (WHERE fe.first_comment IS NOT NULL) AS commented,
        COUNT(*) FILTER (WHERE fe.first_reaction IS NOT NULL) AS reacted
    FROM first_events fe
    INNER JOIN primary_neighborhood pn ON fe.user_id = pn.user_id
    INNER JOIN neighborhoods n ON pn.neighborhood_id = n.neighborhood_id
    GROUP BY n.name
)

-- -----------------------------------------------------------------------------
-- FINAL SELECT: Funnel metrics by neighborhood with ranking
-- RANKING: Helps identify best and worst performing neighborhoods
-- -----------------------------------------------------------------------------
SELECT
    neighborhood_name,
    posted AS users_who_posted,
    commented AS users_who_commented,
    reacted AS users_who_reacted,
    ROUND(commented::NUMERIC / NULLIF(posted, 0), 4) AS pct_post_to_comment,
    ROUND(reacted::NUMERIC / NULLIF(commented, 0), 4) AS pct_comment_to_reaction,
    ROUND(reacted::NUMERIC / NULLIF(posted, 0), 4) AS pct_post_to_reaction,
    RANK() OVER (ORDER BY reacted::NUMERIC / NULLIF(posted, 0) DESC) AS rank_by_conversion
FROM funnel_by_neighborhood
ORDER BY pct_post_to_reaction DESC;


-- =============================================================================
-- QUERY 3: Time-to-Convert Funnel (How quickly do users progress?)
-- =============================================================================
-- DASHBOARD USE CASE: Time-to-value analysis, onboarding effectiveness
-- WHY: Fast conversion = healthy engagement. Slow conversion = friction.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- CTE: first_events_with_dates
-- WHAT: Gets the exact dates for each user's first activity of each type
-- WHY:  We need dates to calculate the time delta between stages.
-- -----------------------------------------------------------------------------
WITH first_events_with_dates AS (
    SELECT
        user_id,
        MIN(CASE WHEN activity_type = 'POST' THEN activity_date END) AS first_post_date,
        MIN(CASE WHEN activity_type = 'COMMENT' THEN activity_date END) AS first_comment_date,
        MIN(CASE WHEN activity_type = 'REACTION' THEN activity_date END) AS first_reaction_date
    FROM fct_user_engagement
    WHERE activity_type IN ('POST', 'COMMENT', 'REACTION')
    GROUP BY user_id
),

-- -----------------------------------------------------------------------------
-- CTE: time_deltas
-- WHAT: Calculates days between each funnel stage
-- WHY:  Shows how long it takes users to progress through the funnel.
--
-- PostgreSQL: (date2 - date1) returns integer days
-- -----------------------------------------------------------------------------
time_deltas AS (
    SELECT
        user_id,
        first_post_date,
        first_comment_date,
        first_reaction_date,
        (first_comment_date - first_post_date) AS days_post_to_comment,
        (first_reaction_date - first_comment_date) AS days_comment_to_reaction,
        (first_reaction_date - first_post_date) AS days_post_to_reaction
    FROM first_events_with_dates
    WHERE first_post_date IS NOT NULL
)

-- -----------------------------------------------------------------------------
-- FINAL SELECT: Distribution of time-to-convert
-- MEDIAN: More robust than average (outliers don't skew it)
-- PERCENTILES: Show the full distribution shape
-- -----------------------------------------------------------------------------
SELECT
    'Post to Comment' AS funnel_stage,
    COUNT(*) AS users_converted,
    ROUND(AVG(days_post_to_comment), 1) AS avg_days,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY days_post_to_comment) AS median_days,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY days_post_to_comment) AS p25_days,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY days_post_to_comment) AS p75_days
FROM time_deltas
WHERE days_post_to_comment IS NOT NULL

UNION ALL

SELECT
    'Comment to Reaction' AS funnel_stage,
    COUNT(*) AS users_converted,
    ROUND(AVG(days_comment_to_reaction), 1) AS avg_days,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY days_comment_to_reaction) AS median_days,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY days_comment_to_reaction) AS p25_days,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY days_comment_to_reaction) AS p75_days
FROM time_deltas
WHERE days_comment_to_reaction IS NOT NULL

UNION ALL

SELECT
    'Post to Reaction (Overall)' AS funnel_stage,
    COUNT(*) AS users_converted,
    ROUND(AVG(days_post_to_reaction), 1) AS avg_days,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY days_post_to_reaction) AS median_days,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY days_post_to_reaction) AS p25_days,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY days_post_to_reaction) AS p75_days
FROM time_deltas
WHERE days_post_to_reaction IS NOT NULL;


-- =============================================================================
-- QUERY 4: Post Engagement Quality (Which posts drive engagement?)
-- =============================================================================
-- DASHBOARD USE CASE: Content performance analysis, viral post detection
-- WHY: Understanding what makes a successful post helps users create better content
-- =============================================================================

-- -----------------------------------------------------------------------------
-- CTE: post_engagement
-- WHAT: Aggregates engagement metrics for each post
-- WHY:  Posts with high comments + reactions are "successful" content.
--       This helps identify patterns in high-performing content.
-- -----------------------------------------------------------------------------
WITH post_engagement AS (
    SELECT
        p.post_id,
        p.user_id AS author_id,
        p.neighborhood_id,
        p.category,
        p.created_at AS post_date,
        COUNT(DISTINCT c.comment_id) AS comment_count,
        COUNT(DISTINCT r.reaction_id) AS reaction_count
    FROM posts p
    LEFT JOIN comments c ON p.post_id = c.post_id
    LEFT JOIN reactions r ON p.post_id = r.post_id
    GROUP BY p.post_id, p.user_id, p.neighborhood_id, p.category, p.created_at
)

-- -----------------------------------------------------------------------------
-- FINAL SELECT: Engagement metrics by category with post-level stats
-- INTERVIEW TIP: This could power a "which category performs best?" analysis
-- -----------------------------------------------------------------------------
SELECT
    category,
    COUNT(*) AS total_posts,
    SUM(comment_count) AS total_comments,
    SUM(reaction_count) AS total_reactions,
    ROUND(AVG(comment_count), 2) AS avg_comments_per_post,
    ROUND(AVG(reaction_count), 2) AS avg_reactions_per_post,
    
    -- Engagement rate: % of posts that got at least one response
    ROUND(COUNT(*) FILTER (WHERE comment_count > 0 OR reaction_count > 0)::NUMERIC / COUNT(*), 4) AS engagement_rate,
    
    -- Viral detection: posts with 5+ comments AND 10+ reactions
    COUNT(*) FILTER (WHERE comment_count >= 5 AND reaction_count >= 10) AS viral_posts
    
FROM post_engagement
GROUP BY category
ORDER BY engagement_rate DESC;
