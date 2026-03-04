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
--   - SEMANTIC_LAYER.SILVER.FCT_USER_ENGAGEMENT (from Step 1)
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
-- CTE: USER_ENGAGEMENT
-- WHAT: Base data pull from the fact table
-- WHY:  Standard pattern - pull data into CTE for clarity and potential filtering.
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
),

-- -----------------------------------------------------------------------------
-- CTE: CHECK_USERS_PREVIOUS_ACTIVITY
-- WHAT: Uses LAG to find each user's previous activity timestamp
-- WHY:  We need to compare current activity to previous activity to classify
--       the "return" behavior. LAG(1) gets the immediately preceding row.
--
-- PARTITION BY USER_ID: Each user's activities are analyzed independently
-- ORDER BY ACTIVITY_DATETIME: Ensures chronological ordering
-- -----------------------------------------------------------------------------
CHECK_USERS_PREVIOUS_ACTIVITY AS (
    SELECT 
        USER_ID,
        ACTIVITY_DATETIME,
        LAG(ACTIVITY_DATETIME, 1) OVER (
            PARTITION BY USER_ID 
            ORDER BY ACTIVITY_DATETIME
        ) AS PREVIOUS_ACTIVITY_DATE
    FROM USER_ENGAGEMENT
    WHERE ACTIVITY_TYPE IN ('POST', 'COMMENT', 'REACTION')
)

-- -----------------------------------------------------------------------------
-- FINAL SELECT: Classifies each activity by return type
-- 
-- DATEDIFF: Returns number of day boundaries between two timestamps
-- CASE ordering matters: check smallest intervals first
-- -----------------------------------------------------------------------------
SELECT 
    USER_ID,
    ACTIVITY_DATETIME,
    PREVIOUS_ACTIVITY_DATE,
    CASE 
        WHEN PREVIOUS_ACTIVITY_DATE IS NULL THEN 'first_activity'
        WHEN DATEDIFF(day, PREVIOUS_ACTIVITY_DATE, ACTIVITY_DATETIME) < 1 THEN 'returned_within_a_day'
        WHEN DATEDIFF(day, PREVIOUS_ACTIVITY_DATE, ACTIVITY_DATETIME) < 7 THEN 'returned_within_a_week'
        WHEN DATEDIFF(day, PREVIOUS_ACTIVITY_DATE, ACTIVITY_DATETIME) < 30 THEN 'returned_within_a_month'
        ELSE 'returned_after_a_month' 
    END AS USER_RETURN_TYPE
FROM CHECK_USERS_PREVIOUS_ACTIVITY
ORDER BY USER_ID, ACTIVITY_DATETIME;


-- =============================================================================
-- QUERY 2: User Segment Distribution Summary
-- =============================================================================
-- DASHBOARD USE CASE: Pie chart or bar chart of user health distribution
-- WHY: Executives want to know "what % of our users are power users vs casual?"
-- =============================================================================

-- -----------------------------------------------------------------------------
-- CTE: USER_ENGAGEMENT
-- WHAT: Same base data pull
-- WHY:  Consistency across queries
-- -----------------------------------------------------------------------------
WITH USER_ENGAGEMENT AS (
    SELECT 
        USER_ID,
        ACTIVITY_TYPE,
        ACTIVITY_DATETIME
    FROM SEMANTIC_LAYER.SILVER.FCT_USER_ENGAGEMENT
    WHERE ACTIVITY_TYPE IN ('POST', 'COMMENT', 'REACTION')
),

-- -----------------------------------------------------------------------------
-- CTE: USER_WITH_RETURN_PATTERNS
-- WHAT: Calculates return type for every activity
-- WHY:  Need this intermediate step before aggregating to segment counts.
-- -----------------------------------------------------------------------------
USER_WITH_RETURN_PATTERNS AS (
    SELECT 
        USER_ID,
        ACTIVITY_DATETIME,
        LAG(ACTIVITY_DATETIME, 1) OVER (
            PARTITION BY USER_ID 
            ORDER BY ACTIVITY_DATETIME
        ) AS PREVIOUS_ACTIVITY_DATE,
        CASE 
            WHEN LAG(ACTIVITY_DATETIME, 1) OVER (PARTITION BY USER_ID ORDER BY ACTIVITY_DATETIME) IS NULL 
                THEN 'first_activity'
            WHEN DATEDIFF(day, LAG(ACTIVITY_DATETIME, 1) OVER (PARTITION BY USER_ID ORDER BY ACTIVITY_DATETIME), ACTIVITY_DATETIME) < 1 
                THEN 'returned_within_a_day'
            WHEN DATEDIFF(day, LAG(ACTIVITY_DATETIME, 1) OVER (PARTITION BY USER_ID ORDER BY ACTIVITY_DATETIME), ACTIVITY_DATETIME) < 7 
                THEN 'returned_within_a_week'
            WHEN DATEDIFF(day, LAG(ACTIVITY_DATETIME, 1) OVER (PARTITION BY USER_ID ORDER BY ACTIVITY_DATETIME), ACTIVITY_DATETIME) < 30 
                THEN 'returned_within_a_month'
            ELSE 'returned_after_a_month' 
        END AS USER_RETURN_TYPE
    FROM USER_ENGAGEMENT
),

-- -----------------------------------------------------------------------------
-- CTE: SEGMENT_COUNTS
-- WHAT: Counts activities by return type
-- WHY:  Raw counts for each segment, used for % calculation.
-- -----------------------------------------------------------------------------
SEGMENT_COUNTS AS (
    SELECT
        USER_RETURN_TYPE,
        COUNT(*) AS ACTIVITY_COUNT,
        COUNT(DISTINCT USER_ID) AS UNIQUE_USERS
    FROM USER_WITH_RETURN_PATTERNS
    GROUP BY USER_RETURN_TYPE
)

-- -----------------------------------------------------------------------------
-- FINAL SELECT: Distribution with percentages
-- WINDOW FUNCTIONS: Calculate totals for percentage denominators
-- -----------------------------------------------------------------------------
SELECT
    USER_RETURN_TYPE,
    ACTIVITY_COUNT,
    UNIQUE_USERS,
    ROUND(ACTIVITY_COUNT::NUMERIC / SUM(ACTIVITY_COUNT) OVER () * 100, 2) AS PCT_OF_ACTIVITIES,
    ROUND(UNIQUE_USERS::NUMERIC / SUM(UNIQUE_USERS) OVER () * 100, 2) AS PCT_OF_USERS
FROM SEGMENT_COUNTS
ORDER BY 
    CASE USER_RETURN_TYPE
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
-- CTE: USER_COHORT
-- WHAT: Assigns each user to a cohort based on their first activity week
-- WHY:  Cohorts let us compare "apples to apples" - users who joined at
--       similar times should have similar retention if product is stable.
-- -----------------------------------------------------------------------------
WITH USER_COHORT AS (
    SELECT
        USER_ID,
        DATE_TRUNC('week', MIN(ACTIVITY_DATE)) AS COHORT_WEEK
    FROM SEMANTIC_LAYER.SILVER.FCT_USER_ENGAGEMENT
    WHERE ACTIVITY_TYPE IN ('POST', 'COMMENT', 'REACTION')
    GROUP BY USER_ID
),

-- -----------------------------------------------------------------------------
-- CTE: USER_ACTIVITY_WEEKS
-- WHAT: Gets all weeks each user was active
-- WHY:  We'll compare activity weeks to cohort week to see retention.
-- -----------------------------------------------------------------------------
USER_ACTIVITY_WEEKS AS (
    SELECT DISTINCT
        USER_ID,
        DATE_TRUNC('week', ACTIVITY_DATE) AS ACTIVITY_WEEK
    FROM SEMANTIC_LAYER.SILVER.FCT_USER_ENGAGEMENT
    WHERE ACTIVITY_TYPE IN ('POST', 'COMMENT', 'REACTION')
),

-- -----------------------------------------------------------------------------
-- CTE: COHORT_RETENTION
-- WHAT: Calculates weeks since cohort start for each activity
-- WHY:  "Week 0" = cohort week, "Week 1" = first week after, etc.
--       This normalizes all cohorts to the same timeline.
-- -----------------------------------------------------------------------------
COHORT_RETENTION AS (
    SELECT
        uc.COHORT_WEEK,
        DATEDIFF('week', uc.COHORT_WEEK, ua.ACTIVITY_WEEK) AS WEEKS_SINCE_COHORT,
        COUNT(DISTINCT ua.USER_ID) AS ACTIVE_USERS
    FROM USER_COHORT uc
    INNER JOIN USER_ACTIVITY_WEEKS ua ON uc.USER_ID = ua.USER_ID
    WHERE DATEDIFF('week', uc.COHORT_WEEK, ua.ACTIVITY_WEEK) >= 0
      AND DATEDIFF('week', uc.COHORT_WEEK, ua.ACTIVITY_WEEK) <= 12  -- First 12 weeks
    GROUP BY uc.COHORT_WEEK, DATEDIFF('week', uc.COHORT_WEEK, ua.ACTIVITY_WEEK)
),

-- -----------------------------------------------------------------------------
-- CTE: COHORT_SIZE
-- WHAT: Counts users in each cohort (Week 0 users)
-- WHY:  This is the denominator for retention percentage.
-- -----------------------------------------------------------------------------
COHORT_SIZE AS (
    SELECT
        COHORT_WEEK,
        COUNT(DISTINCT USER_ID) AS COHORT_USERS
    FROM USER_COHORT
    GROUP BY COHORT_WEEK
)

-- -----------------------------------------------------------------------------
-- FINAL SELECT: Retention matrix with percentages
-- HOW TO READ: Each row is a cohort, each column is weeks since joining
-- GOOD RETENTION: 40%+ Week 1, 20%+ Week 4, 10%+ Week 12
-- -----------------------------------------------------------------------------
SELECT
    cr.COHORT_WEEK,
    cs.COHORT_USERS,
    cr.WEEKS_SINCE_COHORT,
    cr.ACTIVE_USERS,
    ROUND(cr.ACTIVE_USERS::NUMERIC / cs.COHORT_USERS * 100, 1) AS RETENTION_PCT
FROM COHORT_RETENTION cr
INNER JOIN COHORT_SIZE cs ON cr.COHORT_WEEK = cs.COHORT_WEEK
ORDER BY cr.COHORT_WEEK, cr.WEEKS_SINCE_COHORT;


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
-- CTE: RECENT_ACTIVITY
-- WHAT: Filters to last 30 days of activity
-- WHY:  Power users should be CURRENTLY active, not just historically.
-- -----------------------------------------------------------------------------
WITH RECENT_ACTIVITY AS (
    SELECT
        USER_ID,
        ACTIVITY_TYPE,
        ACTIVITY_DATE,
        POST_ID
    FROM SEMANTIC_LAYER.SILVER.FCT_USER_ENGAGEMENT
    WHERE ACTIVITY_TYPE IN ('POST', 'COMMENT', 'REACTION')
      AND ACTIVITY_DATE >= CURRENT_DATE - INTERVAL '30 days'
),

-- -----------------------------------------------------------------------------
-- CTE: USER_ACTIVITY_SUMMARY
-- WHAT: Aggregates key metrics per user for power user scoring
-- WHY:  Multiple dimensions of engagement define power users.
-- -----------------------------------------------------------------------------
USER_ACTIVITY_SUMMARY AS (
    SELECT
        USER_ID,
        COUNT(DISTINCT ACTIVITY_DATE) AS ACTIVE_DAYS,
        COUNT_IF(ACTIVITY_TYPE = 'POST') AS POST_COUNT,
        COUNT_IF(ACTIVITY_TYPE = 'COMMENT') AS COMMENT_COUNT,
        COUNT_IF(ACTIVITY_TYPE = 'REACTION') AS REACTION_COUNT
    FROM RECENT_ACTIVITY
    GROUP BY USER_ID
),

-- -----------------------------------------------------------------------------
-- CTE: POST_REACH
-- WHAT: Counts unique users who reacted to each author's posts
-- WHY:  Measures influence - power users create content others engage with.
-- -----------------------------------------------------------------------------
POST_REACH AS (
    SELECT
        p.USER_ID AS AUTHOR_ID,
        COUNT(DISTINCT r.USER_ID) AS UNIQUE_REACTORS
    FROM INTERVIEW_PREP.NEXTDOOR.POST p
    INNER JOIN INTERVIEW_PREP.NEXTDOOR.REACTIONS r ON p.POST_ID = r.POST_ID
    WHERE r.CREATED_AT >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY p.USER_ID
)

-- -----------------------------------------------------------------------------
-- FINAL SELECT: Power user candidates ranked by engagement score
-- ENGAGEMENT SCORE: Weighted combination of activity metrics
-- -----------------------------------------------------------------------------
SELECT
    uas.USER_ID,
    uas.ACTIVE_DAYS,
    uas.POST_COUNT,
    uas.COMMENT_COUNT,
    uas.REACTION_COUNT,
    COALESCE(pr.UNIQUE_REACTORS, 0) AS UNIQUE_REACTORS,
    
    -- Power user score (customizable weights)
    (uas.ACTIVE_DAYS * 2 + 
     uas.POST_COUNT * 3 + 
     uas.COMMENT_COUNT * 2 + 
     uas.REACTION_COUNT * 1 +
     COALESCE(pr.UNIQUE_REACTORS, 0) * 2) AS POWER_USER_SCORE,
    
    -- Power user flag based on thresholds
    CASE 
        WHEN uas.ACTIVE_DAYS >= 10 
         AND uas.POST_COUNT >= 5 
         AND COALESCE(pr.UNIQUE_REACTORS, 0) >= 20 THEN 'POWER_USER'
        WHEN uas.ACTIVE_DAYS >= 5 
         AND (uas.POST_COUNT >= 3 OR uas.COMMENT_COUNT >= 10) THEN 'ENGAGED_USER'
        ELSE 'REGULAR_USER'
    END AS USER_SEGMENT

FROM USER_ACTIVITY_SUMMARY uas
LEFT JOIN POST_REACH pr ON uas.USER_ID = pr.AUTHOR_ID
ORDER BY POWER_USER_SCORE DESC
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
-- CTE: USER_LAST_ACTIVITY
-- WHAT: Finds each user's most recent activity
-- WHY:  Days since last activity is primary churn indicator.
-- -----------------------------------------------------------------------------
WITH USER_LAST_ACTIVITY AS (
    SELECT
        USER_ID,
        MAX(ACTIVITY_DATE) AS LAST_ACTIVITY_DATE,
        MIN(ACTIVITY_DATE) AS FIRST_ACTIVITY_DATE,
        COUNT(DISTINCT ACTIVITY_DATE) AS TOTAL_ACTIVE_DAYS,
        COUNT(*) AS TOTAL_ACTIVITIES
    FROM SEMANTIC_LAYER.SILVER.FCT_USER_ENGAGEMENT
    WHERE ACTIVITY_TYPE IN ('POST', 'COMMENT', 'REACTION')
    GROUP BY USER_ID
),

-- -----------------------------------------------------------------------------
-- CTE: RECENT_VS_HISTORICAL
-- WHAT: Compares recent activity (last 30 days) vs historical average
-- WHY:  Declining activity is a stronger churn signal than just inactivity.
-- -----------------------------------------------------------------------------
RECENT_VS_HISTORICAL AS (
    SELECT
        USER_ID,
        COUNT_IF(ACTIVITY_DATE >= CURRENT_DATE - INTERVAL '30 days') AS LAST_30_DAYS_ACTIVITIES,
        COUNT_IF(ACTIVITY_DATE >= CURRENT_DATE - INTERVAL '60 days' 
                 AND ACTIVITY_DATE < CURRENT_DATE - INTERVAL '30 days') AS PRIOR_30_DAYS_ACTIVITIES
    FROM SEMANTIC_LAYER.SILVER.FCT_USER_ENGAGEMENT
    WHERE ACTIVITY_TYPE IN ('POST', 'COMMENT', 'REACTION')
    GROUP BY USER_ID
)

-- -----------------------------------------------------------------------------
-- FINAL SELECT: Churn risk scoring
-- RISK LEVELS: Based on days since last activity + activity trend
-- -----------------------------------------------------------------------------
SELECT
    ula.USER_ID,
    ula.LAST_ACTIVITY_DATE,
    ula.FIRST_ACTIVITY_DATE,
    DATEDIFF(day, ula.LAST_ACTIVITY_DATE, CURRENT_DATE) AS DAYS_SINCE_LAST_ACTIVITY,
    ula.TOTAL_ACTIVE_DAYS,
    ula.TOTAL_ACTIVITIES,
    rvh.LAST_30_DAYS_ACTIVITIES,
    rvh.PRIOR_30_DAYS_ACTIVITIES,
    
    -- Activity trend (positive = growing, negative = declining)
    rvh.LAST_30_DAYS_ACTIVITIES - rvh.PRIOR_30_DAYS_ACTIVITIES AS ACTIVITY_TREND,
    
    -- Churn risk classification
    CASE
        WHEN DATEDIFF(day, ula.LAST_ACTIVITY_DATE, CURRENT_DATE) > 60 THEN 'CHURNED'
        WHEN DATEDIFF(day, ula.LAST_ACTIVITY_DATE, CURRENT_DATE) > 30 THEN 'HIGH_RISK'
        WHEN DATEDIFF(day, ula.LAST_ACTIVITY_DATE, CURRENT_DATE) > 14 
             AND rvh.LAST_30_DAYS_ACTIVITIES < rvh.PRIOR_30_DAYS_ACTIVITIES THEN 'MEDIUM_RISK'
        WHEN rvh.LAST_30_DAYS_ACTIVITIES < rvh.PRIOR_30_DAYS_ACTIVITIES * 0.5 THEN 'DECLINING'
        ELSE 'HEALTHY'
    END AS CHURN_RISK_LEVEL

FROM USER_LAST_ACTIVITY ula
LEFT JOIN RECENT_VS_HISTORICAL rvh ON ula.USER_ID = rvh.USER_ID
WHERE ula.TOTAL_ACTIVE_DAYS > 1  -- Exclude one-time users
ORDER BY 
    CASE 
        WHEN DATEDIFF(day, ula.LAST_ACTIVITY_DATE, CURRENT_DATE) > 60 THEN 1
        WHEN DATEDIFF(day, ula.LAST_ACTIVITY_DATE, CURRENT_DATE) > 30 THEN 2
        WHEN DATEDIFF(day, ula.LAST_ACTIVITY_DATE, CURRENT_DATE) > 14 THEN 3
        ELSE 4
    END,
    ula.TOTAL_ACTIVITIES DESC;
