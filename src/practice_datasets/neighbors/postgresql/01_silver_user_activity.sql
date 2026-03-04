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
--   - users
--   - posts
--   - comments
--   - reactions
--
-- OUTPUT: fct_user_engagement
--
-- DASHBOARD USE CASES:
--   - Activity feed timeline
--   - User engagement heatmaps
--   - Neighborhood activity comparisons
--   - User lifecycle tracking
-- ============================================================================

DROP TABLE IF EXISTS fct_user_engagement;

CREATE TABLE fct_user_engagement AS (

    -- -------------------------------------------------------------------------
    -- POSTS: Core content creation activity
    -- WHY: Posts are the primary engagement driver - they generate comments
    --      and reactions. Tracking posts helps measure content creation health.
    -- -------------------------------------------------------------------------
    SELECT
        posts.user_id AS user_id,
        posts.post_id AS post_id,
        posts.neighborhood_id AS neighborhood_id,
        users.is_active AS user_status,
        'POST' AS activity_type,
        posts.post_id AS event_id,
        posts.created_at AS activity_datetime,
        posts.created_at::DATE AS activity_date
    FROM posts
    INNER JOIN users 
        ON posts.user_id = users.user_id

    UNION ALL

    -- -------------------------------------------------------------------------
    -- COMMENTS: Secondary engagement - indicates deeper interaction
    -- WHY: Comments require more effort than reactions, signaling higher
    --      engagement quality. They also drive conversation threads.
    -- -------------------------------------------------------------------------
    SELECT
        comments.user_id AS user_id,
        comments.post_id AS post_id,
        posts.neighborhood_id AS neighborhood_id,
        users.is_active AS user_status,
        'COMMENT' AS activity_type,
        comments.comment_id AS event_id,
        comments.created_at AS activity_datetime,
        comments.created_at::DATE AS activity_date
    FROM comments
    INNER JOIN users 
        ON comments.user_id = users.user_id
    INNER JOIN posts
        ON comments.post_id = posts.post_id

    UNION ALL

    -- -------------------------------------------------------------------------
    -- REACTIONS: Lightweight engagement - low friction interaction
    -- WHY: Reactions are the easiest way to engage. High reaction counts
    --      indicate content resonance. Useful for viral content detection.
    -- -------------------------------------------------------------------------
    SELECT
        reactions.user_id AS user_id,
        reactions.post_id AS post_id,
        posts.neighborhood_id AS neighborhood_id,
        users.is_active AS user_status,
        'REACTION' AS activity_type,
        reactions.reaction_id AS event_id,
        reactions.created_at AS activity_datetime,
        reactions.created_at::DATE AS activity_date
    FROM reactions
    INNER JOIN users 
        ON reactions.user_id = users.user_id
    INNER JOIN posts
        ON reactions.post_id = posts.post_id

    UNION ALL

    -- -------------------------------------------------------------------------
    -- USERS WITH NO ACTIVITY: Silent/churned users
    -- WHY: Critical for churn analysis. These users signed up but never
    --      engaged. Understanding this segment helps improve activation.
    -- -------------------------------------------------------------------------
    SELECT
        users.user_id AS user_id,
        NULL::INTEGER AS post_id,
        users.neighborhood_id AS neighborhood_id,
        users.is_active AS user_status,
        'NO_ACTIVITY' AS activity_type,
        NULL::INTEGER AS event_id,
        users.created_at AS activity_datetime,
        users.created_at::DATE AS activity_date
    FROM users
    WHERE NOT EXISTS (
        SELECT 1 FROM posts p 
        WHERE p.user_id = users.user_id
    )
    AND NOT EXISTS (
        SELECT 1 FROM comments c 
        WHERE c.user_id = users.user_id
    )
    AND NOT EXISTS (
        SELECT 1 FROM reactions r 
        WHERE r.user_id = users.user_id
    )
);

-- Create indexes for better query performance
CREATE INDEX idx_fct_user_engagement_user_id ON fct_user_engagement(user_id);
CREATE INDEX idx_fct_user_engagement_activity_date ON fct_user_engagement(activity_date);
CREATE INDEX idx_fct_user_engagement_neighborhood_id ON fct_user_engagement(neighborhood_id);
CREATE INDEX idx_fct_user_engagement_activity_type ON fct_user_engagement(activity_type);
