-- ============================================================================
-- STEP 1: SILVER LAYER - Unified User Activity Fact Table
-- ============================================================================
-- PURPOSE: Consolidates all user activities (posts, comments, reactions) into
--          a single denormalized fact table for downstream analytics.
--
-- WHY THIS APPROACH:
--   - Single source of truth for all user engagement
--   - Eliminates repeated JOINs in downstream queries
--   - Enables flexible filtering by activity_type
--   - Supports time-series analysis across all activity types
-- 
-- SOURCE TABLES:
--   - INTERVIEW_PREP.NEXTDOOR.USERS
--   - INTERVIEW_PREP.NEXTDOOR.POST
--   - INTERVIEW_PREP.NEXTDOOR.COMMENTS
--   - INTERVIEW_PREP.NEXTDOOR.REACTIONS
--
-- OUTPUT: SEMANTIC_LAYER.SILVER.FCT_USER_ENGAGEMENT
--
-- DASHBOARD USE CASES:
--   - Activity feed timeline
--   - User engagement heatmaps
--   - Neighborhood activity comparisons
--   - User lifecycle tracking
-- ============================================================================

CREATE OR REPLACE TABLE SEMANTIC_LAYER.SILVER.FCT_USER_ENGAGEMENT AS (

    -- -------------------------------------------------------------------------
    -- POSTS: Core content creation activity
    -- WHY: Posts are the primary engagement driver - they generate comments
    --      and reactions. Tracking posts helps measure content creation health.
    -- -------------------------------------------------------------------------
    SELECT
        posts.user_id AS USER_ID,
        posts.post_id AS POST_ID,
        posts.neighborhood_id AS NEIGHBORHOOD_ID,
        users.is_active AS USER_STATUS,
        'POST' AS ACTIVITY_TYPE,
        posts.post_id AS EVENT_ID,
        posts.created_at AS ACTIVITY_DATETIME,
        DATE(posts.created_at) AS ACTIVITY_DATE
    FROM INTERVIEW_PREP.NEXTDOOR.POST posts
    INNER JOIN INTERVIEW_PREP.NEXTDOOR.USERS users 
        ON posts.user_id = users.user_id

    UNION ALL

    -- -------------------------------------------------------------------------
    -- COMMENTS: Secondary engagement - indicates deeper interaction
    -- WHY: Comments require more effort than reactions, signaling higher
    --      engagement quality. They also drive conversation threads.
    -- -------------------------------------------------------------------------
    SELECT
        comments.user_id AS USER_ID,
        comments.post_id AS POST_ID,
        posts.neighborhood_id AS NEIGHBORHOOD_ID,
        users.is_active AS USER_STATUS,
        'COMMENT' AS ACTIVITY_TYPE,
        comments.comment_id AS EVENT_ID,
        comments.created_at AS ACTIVITY_DATETIME,
        DATE(comments.created_at) AS ACTIVITY_DATE
    FROM INTERVIEW_PREP.NEXTDOOR.COMMENTS comments
    INNER JOIN INTERVIEW_PREP.NEXTDOOR.USERS users 
        ON comments.user_id = users.user_id
    INNER JOIN INTERVIEW_PREP.NEXTDOOR.POST posts
        ON comments.post_id = posts.post_id

    UNION ALL

    -- -------------------------------------------------------------------------
    -- REACTIONS: Lightweight engagement - low friction interaction
    -- WHY: Reactions are the easiest way to engage. High reaction counts
    --      indicate content resonance. Useful for viral content detection.
    -- -------------------------------------------------------------------------
    SELECT
        reactions.user_id AS USER_ID,
        reactions.post_id AS POST_ID,
        posts.neighborhood_id AS NEIGHBORHOOD_ID,
        users.is_active AS USER_STATUS,
        'REACTION' AS ACTIVITY_TYPE,
        reactions.reaction_id AS EVENT_ID,
        reactions.created_at AS ACTIVITY_DATETIME,
        DATE(reactions.created_at) AS ACTIVITY_DATE
    FROM INTERVIEW_PREP.NEXTDOOR.REACTIONS reactions
    INNER JOIN INTERVIEW_PREP.NEXTDOOR.USERS users 
        ON reactions.user_id = users.user_id
    INNER JOIN INTERVIEW_PREP.NEXTDOOR.POST posts
        ON reactions.post_id = posts.post_id

    UNION ALL

    -- -------------------------------------------------------------------------
    -- USERS WITH NO ACTIVITY: Silent/churned users
    -- WHY: Critical for churn analysis. These users signed up but never
    --      engaged. Understanding this segment helps improve activation.
    -- -------------------------------------------------------------------------
    SELECT
        users.user_id AS USER_ID,
        NULL AS POST_ID,
        users.neighborhood_id AS NEIGHBORHOOD_ID,
        users.is_active AS USER_STATUS,
        'NO_ACTIVITY' AS ACTIVITY_TYPE,
        NULL AS EVENT_ID,
        users.created_at AS ACTIVITY_DATETIME,
        DATE(users.created_at) AS ACTIVITY_DATE
    FROM INTERVIEW_PREP.NEXTDOOR.USERS users
    WHERE NOT EXISTS (
        SELECT 1 FROM INTERVIEW_PREP.NEXTDOOR.POST p 
        WHERE p.user_id = users.user_id
    )
    AND NOT EXISTS (
        SELECT 1 FROM INTERVIEW_PREP.NEXTDOOR.COMMENTS c 
        WHERE c.user_id = users.user_id
    )
    AND NOT EXISTS (
        SELECT 1 FROM INTERVIEW_PREP.NEXTDOOR.REACTIONS r 
        WHERE r.user_id = users.user_id
    )
);
