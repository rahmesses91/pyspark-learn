-- ============================================================================
-- STEP 4: GOLD LAYER - User Behavioral Segmentation (Return Patterns)
-- ============================================================================
-- PURPOSE: Segment users based on their return behavior patterns.
--
-- WHY BEHAVIORAL SEGMENTATION MATTERS:
--   - Not all users are equal - some are power users, others are casual
--   - Different segments need different product strategies
--   - Predicts churn before it happens (users slowing down → at risk)
--   - Enables personalized re-engagement campaigns
--
-- DEPENDS ON:
--   - fct_user_engagement (from Step 1)
--
-- INTERVIEW TIP: Behavioral segmentation is a VERY common interview topic.
--   Be ready to explain:
--   1. How you define each segment
--   2. Why those thresholds (1 day, 7 days, 30 days)
--   3. What actions you'd take for each segment
-- ============================================================================


-- =============================================================================
-- QUERY 1: User Return Pattern Classification
-- =============================================================================
-- DASHBOARD USE CASE: User health distribution chart, retention monitoring
-- 
-- SEGMENTS EXPLAINED:
--   first_activity      - Brand new to the platform (acquisition)
--   returned_within_day - Highly engaged, daily user (power user)
--   returned_within_week - Regular user, healthy engagement
--   returned_within_month - Casual user, at-risk of churning
--   returned_after_month - Reactivated/resurrected user (was churned)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- CTE: user_engagement
-- WHAT: Base data pull from the fact table
-- WHY:  Standard pattern - pull data into CTE for clarity and potential filtering.
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
),

-- -----------------------------------------------------------------------------
-- CTE: check_users_previous_activity
-- WHAT: Uses LAG to find each user's previous activity timestamp
-- WHY:  We need to compare current activity to previous activity to classify
--       the "return" behavior. LAG(1) gets the immediately preceding row.
--
-- PARTITION BY user_id: Each user's activities are analyzed independently
-- ORDER BY activity_datetime: Ensures chronological ordering
-- -----------------------------------------------------------------------------
check_users_previous_activity AS (
    SELECT 
        user_id,
        activity_datetime,
        LAG(activity_datetime, 1) OVER (
            PARTITION BY user_id 
            ORDER BY activity_datetime
        ) AS previous_activity_date
    FROM user_engagement
    WHERE activity_type IN ('POST', 'COMMENT', 'REACTION')
)

-- -----------------------------------------------------------------------------
-- FINAL SELECT: Classifies each activity by return type
-- 
-- PostgreSQL: (date2::DATE - date1::DATE) returns integer days
-- CASE ordering matters: check smallest intervals first
-- -----------------------------------------------------------------------------
SELECT 
    user_id,
    activity_datetime,
    previous_activity_date,
    CASE 
        WHEN previous_activity_date IS NULL THEN 'first_activity'
        WHEN (activity_datetime::DATE - previous_activity_date::DATE) < 1 THEN 'returned_within_a_day'
        WHEN (activity_datetime::DATE - previous_activity_date::DATE) < 7 THEN 'returned_within_a_week'
        WHEN (activity_datetime::DATE - previous_activity_date::DATE) < 30 THEN 'returned_within_a_month'
        ELSE 'returned_after_a_month' 
    END AS user_return_type
FROM check_users_previous_activity
ORDER BY user_id, activity_datetime;


-- =============================================================================
-- QUERY 2: User Segment Distribution Summary
-- =============================================================================
-- DASHBOARD USE CASE: Pie chart or bar chart of user health distribution
-- WHY: Executives want to know "what % of our users are power users vs casual?"
-- =============================================================================

-- -----------------------------------------------------------------------------
-- CTE: user_engagement
-- WHAT: Same base data pull
-- WHY:  Consistency across queries
-- -----------------------------------------------------------------------------
WITH user_engagement AS (
    SELECT 
        user_id,
        activity_type,
        activity_datetime
    FROM fct_user_engagement
    WHERE activity_type IN ('POST', 'COMMENT', 'REACTION')
),

-- -----------------------------------------------------------------------------
-- CTE: user_with_return_patterns
-- WHAT: Calculates return type for every activity
-- WHY:  Need this intermediate step before aggregating to segment counts.
-- -----------------------------------------------------------------------------
user_with_return_patterns AS (
    SELECT 
        user_id,
        activity_datetime,
        LAG(activity_datetime, 1) OVER (
            PARTITION BY user_id 
            ORDER BY activity_datetime
        ) AS previous_activity_date,
        CASE 
            WHEN LAG(activity_datetime, 1) OVER (PARTITION BY user_id ORDER BY activity_datetime) IS NULL 
                THEN 'first_activity'
            WHEN (activity_datetime::DATE - LAG(activity_datetime, 1) OVER (PARTITION BY user_id ORDER BY activity_datetime)::DATE) < 1 
                THEN 'returned_within_a_day'
            WHEN (activity_datetime::DATE - LAG(activity_datetime, 1) OVER (PARTITION BY user_id ORDER BY activity_datetime)::DATE) < 7 
                THEN 'returned_within_a_week'
            WHEN (activity_datetime::DATE - LAG(activity_datetime, 1) OVER (PARTITION BY user_id ORDER BY activity_datetime)::DATE) < 30 
                THEN 'returned_within_a_month'
            ELSE 'returned_after_a_month' 
        END AS user_return_type
    FROM user_engagement
),

-- -----------------------------------------------------------------------------
-- CTE: segment_counts
-- WHAT: Counts activities by return type
-- WHY:  Raw counts for each segment, used for % calculation.
-- -----------------------------------------------------------------------------
segment_counts AS (
    SELECT
        user_return_type,
        COUNT(*) AS activity_count,
        COUNT(DISTINCT user_id) AS unique_users
    FROM user_with_return_patterns
    GROUP BY user_return_type
)

-- -----------------------------------------------------------------------------
-- FINAL SELECT: Distribution with percentages
-- WINDOW FUNCTIONS: Calculate totals for percentage denominators
-- -----------------------------------------------------------------------------
SELECT
    user_return_type,
    activity_count,
    unique_users,
    ROUND(activity_count::NUMERIC / SUM(activity_count) OVER () * 100, 2) AS pct_of_activities,
    ROUND(unique_users::NUMERIC / SUM(unique_users) OVER () * 100, 2) AS pct_of_users
FROM segment_counts
ORDER BY 
    CASE user_return_type
        WHEN 'first_activity' THEN 1
        WHEN 'returned_within_a_day' THEN 2
        WHEN 'returned_within_a_week' THEN 3
        WHEN 'returned_within_a_month' THEN 4
        WHEN 'returned_after_a_month' THEN 5
    END;


-- =============================================================================
-- QUERY 3: Cohort Retention Analysis (Classic Retention Matrix)
-- =============================================================================
-- DASHBOARD USE CASE: Retention heatmap, cohort analysis table
-- 
-- WHY COHORT RETENTION:
--   - Groups users by when they joined (cohort)
--   - Tracks what % are still active N days/weeks later
--   - Industry-standard way to measure retention health
--   - Shows if newer cohorts retain better than older ones
-- =============================================================================

-- -----------------------------------------------------------------------------
-- CTE: user_cohort
-- WHAT: Assigns each user to a cohort based on their first activity week
-- WHY:  Cohorts let us compare "apples to apples" - users who joined at
--       similar times should have similar retention if product is stable.
-- -----------------------------------------------------------------------------
WITH user_cohort AS (
    SELECT
        user_id,
        DATE_TRUNC('week', MIN(activity_date))::DATE AS cohort_week
    FROM fct_user_engagement
    WHERE activity_type IN ('POST', 'COMMENT', 'REACTION')
    GROUP BY user_id
),

-- -----------------------------------------------------------------------------
-- CTE: user_activity_weeks
-- WHAT: Gets all weeks each user was active
-- WHY:  We'll compare activity weeks to cohort week to see retention.
-- -----------------------------------------------------------------------------
user_activity_weeks AS (
    SELECT DISTINCT
        user_id,
        DATE_TRUNC('week', activity_date)::DATE AS activity_week
    FROM fct_user_engagement
    WHERE activity_type IN ('POST', 'COMMENT', 'REACTION')
),

-- -----------------------------------------------------------------------------
-- CTE: cohort_retention
-- WHAT: Calculates weeks since cohort start for each activity
-- WHY:  "Week 0" = cohort week, "Week 1" = first week after, etc.
--       This normalizes all cohorts to the same timeline.
--
-- PostgreSQL: (date2 - date1) / 7 gives weeks difference
-- -----------------------------------------------------------------------------
cohort_retention AS (
    SELECT
        uc.cohort_week,
        (ua.activity_week - uc.cohort_week) / 7 AS weeks_since_cohort,
        COUNT(DISTINCT ua.user_id) AS active_users
    FROM user_cohort uc
    INNER JOIN user_activity_weeks ua ON uc.user_id = ua.user_id
    WHERE (ua.activity_week - uc.cohort_week) / 7 >= 0
      AND (ua.activity_week - uc.cohort_week) / 7 <= 12
    GROUP BY uc.cohort_week, (ua.activity_week - uc.cohort_week) / 7
),

-- -----------------------------------------------------------------------------
-- CTE: cohort_size
-- WHAT: Counts users in each cohort (Week 0 users)
-- WHY:  This is the denominator for retention percentage.
-- -----------------------------------------------------------------------------
cohort_size AS (
    SELECT
        cohort_week,
        COUNT(DISTINCT user_id) AS cohort_users
    FROM user_cohort
    GROUP BY cohort_week
)

-- -----------------------------------------------------------------------------
-- FINAL SELECT: Retention matrix with percentages
-- HOW TO READ: Each row is a cohort, each column is weeks since joining
-- GOOD RETENTION: 40%+ Week 1, 20%+ Week 4, 10%+ Week 12
-- -----------------------------------------------------------------------------
SELECT
    cr.cohort_week,
    cs.cohort_users,
    cr.weeks_since_cohort,
    cr.active_users,
    ROUND(cr.active_users::NUMERIC / cs.cohort_users * 100, 1) AS retention_pct
FROM cohort_retention cr
INNER JOIN cohort_size cs ON cr.cohort_week = cs.cohort_week
ORDER BY cr.cohort_week, cr.weeks_since_cohort;


-- =============================================================================
-- QUERY 4: Power User Identification
-- =============================================================================
-- DASHBOARD USE CASE: Power user leaderboard, ambassador program candidates
-- 
-- POWER USER DEFINITION (customizable):
--   - Active on 10+ distinct days in last 30 days
--   - Created 5+ posts in last 30 days
--   - Has received reactions from 20+ unique users
-- =============================================================================

-- -----------------------------------------------------------------------------
-- CTE: recent_activity
-- WHAT: Filters to last 30 days of activity
-- WHY:  Power users should be CURRENTLY active, not just historically.
-- -----------------------------------------------------------------------------
WITH recent_activity AS (
    SELECT
        user_id,
        activity_type,
        activity_date,
        post_id
    FROM fct_user_engagement
    WHERE activity_type IN ('POST', 'COMMENT', 'REACTION')
      AND activity_date >= CURRENT_DATE - INTERVAL '30 days'
),

-- -----------------------------------------------------------------------------
-- CTE: user_activity_summary
-- WHAT: Aggregates key metrics per user for power user scoring
-- WHY:  Multiple dimensions of engagement define power users.
-- -----------------------------------------------------------------------------
user_activity_summary AS (
    SELECT
        user_id,
        COUNT(DISTINCT activity_date) AS active_days,
        COUNT(*) FILTER (WHERE activity_type = 'POST') AS post_count,
        COUNT(*) FILTER (WHERE activity_type = 'COMMENT') AS comment_count,
        COUNT(*) FILTER (WHERE activity_type = 'REACTION') AS reaction_count
    FROM recent_activity
    GROUP BY user_id
),

-- -----------------------------------------------------------------------------
-- CTE: post_reach
-- WHAT: Counts unique users who reacted to each author's posts
-- WHY:  Measures influence - power users create content others engage with.
-- -----------------------------------------------------------------------------
post_reach AS (
    SELECT
        p.user_id AS author_id,
        COUNT(DISTINCT r.user_id) AS unique_reactors
    FROM posts p
    INNER JOIN reactions r ON p.post_id = r.post_id
    WHERE r.created_at >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY p.user_id
)

-- -----------------------------------------------------------------------------
-- FINAL SELECT: Power user candidates ranked by engagement score
-- ENGAGEMENT SCORE: Weighted combination of activity metrics
-- -----------------------------------------------------------------------------
SELECT
    uas.user_id,
    uas.active_days,
    uas.post_count,
    uas.comment_count,
    uas.reaction_count,
    COALESCE(pr.unique_reactors, 0) AS unique_reactors,
    
    -- Power user score (customizable weights)
    (uas.active_days * 2 + 
     uas.post_count * 3 + 
     uas.comment_count * 2 + 
     uas.reaction_count * 1 +
     COALESCE(pr.unique_reactors, 0) * 2) AS power_user_score,
    
    -- Power user flag based on thresholds
    CASE 
        WHEN uas.active_days >= 10 
         AND uas.post_count >= 5 
         AND COALESCE(pr.unique_reactors, 0) >= 20 THEN 'POWER_USER'
        WHEN uas.active_days >= 5 
         AND (uas.post_count >= 3 OR uas.comment_count >= 10) THEN 'ENGAGED_USER'
        ELSE 'REGULAR_USER'
    END AS user_segment

FROM user_activity_summary uas
LEFT JOIN post_reach pr ON uas.user_id = pr.author_id
ORDER BY power_user_score DESC
LIMIT 100;


-- =============================================================================
-- QUERY 5: Churn Risk Detection
-- =============================================================================
-- DASHBOARD USE CASE: At-risk user alerts, re-engagement campaign targeting
-- 
-- CHURN SIGNALS:
--   - Days since last activity increasing
--   - Activity frequency decreasing
--   - Used to be active but now silent
-- =============================================================================

-- -----------------------------------------------------------------------------
-- CTE: user_last_activity
-- WHAT: Finds each user's most recent activity
-- WHY:  Days since last activity is primary churn indicator.
-- -----------------------------------------------------------------------------
WITH user_last_activity AS (
    SELECT
        user_id,
        MAX(activity_date) AS last_activity_date,
        MIN(activity_date) AS first_activity_date,
        COUNT(DISTINCT activity_date) AS total_active_days,
        COUNT(*) AS total_activities
    FROM fct_user_engagement
    WHERE activity_type IN ('POST', 'COMMENT', 'REACTION')
    GROUP BY user_id
),

-- -----------------------------------------------------------------------------
-- CTE: recent_vs_historical
-- WHAT: Compares recent activity (last 30 days) vs historical average
-- WHY:  Declining activity is a stronger churn signal than just inactivity.
-- -----------------------------------------------------------------------------
recent_vs_historical AS (
    SELECT
        user_id,
        COUNT(*) FILTER (WHERE activity_date >= CURRENT_DATE - INTERVAL '30 days') AS last_30_days_activities,
        COUNT(*) FILTER (WHERE activity_date >= CURRENT_DATE - INTERVAL '60 days' 
                              AND activity_date < CURRENT_DATE - INTERVAL '30 days') AS prior_30_days_activities
    FROM fct_user_engagement
    WHERE activity_type IN ('POST', 'COMMENT', 'REACTION')
    GROUP BY user_id
)

-- -----------------------------------------------------------------------------
-- FINAL SELECT: Churn risk scoring
-- RISK LEVELS: Based on days since last activity + activity trend
-- -----------------------------------------------------------------------------
SELECT
    ula.user_id,
    ula.last_activity_date,
    ula.first_activity_date,
    (CURRENT_DATE - ula.last_activity_date) AS days_since_last_activity,
    ula.total_active_days,
    ula.total_activities,
    rvh.last_30_days_activities,
    rvh.prior_30_days_activities,
    
    -- Activity trend (positive = growing, negative = declining)
    rvh.last_30_days_activities - rvh.prior_30_days_activities AS activity_trend,
    
    -- Churn risk classification
    CASE
        WHEN (CURRENT_DATE - ula.last_activity_date) > 60 THEN 'CHURNED'
        WHEN (CURRENT_DATE - ula.last_activity_date) > 30 THEN 'HIGH_RISK'
        WHEN (CURRENT_DATE - ula.last_activity_date) > 14 
             AND rvh.last_30_days_activities < rvh.prior_30_days_activities THEN 'MEDIUM_RISK'
        WHEN rvh.last_30_days_activities < rvh.prior_30_days_activities * 0.5 THEN 'DECLINING'
        ELSE 'HEALTHY'
    END AS churn_risk_level

FROM user_last_activity ula
LEFT JOIN recent_vs_historical rvh ON ula.user_id = rvh.user_id
WHERE ula.total_active_days > 1
ORDER BY 
    CASE 
        WHEN (CURRENT_DATE - ula.last_activity_date) > 60 THEN 1
        WHEN (CURRENT_DATE - ula.last_activity_date) > 30 THEN 2
        WHEN (CURRENT_DATE - ula.last_activity_date) > 14 THEN 3
        ELSE 4
    END,
    ula.total_activities DESC;
