-- =============================================================================
-- WEEKEND TECHNICAL EXERCISE - TIMED (70 MINUTES) - CORRECT ANSWERS
-- Date: 2026-03-17   Time: 07:00
-- Database: PostgreSQL   Schema: volley_games (users, games, sessions, events, purchases)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- QUESTION 1
-- -----------------------------------------------------------------------------
SELECT 
    country,
    COUNT(*) AS user_count
FROM users
GROUP BY country
ORDER BY user_count DESC
LIMIT 1;


-- -----------------------------------------------------------------------------
-- QUESTION 2
-- -----------------------------------------------------------------------------
SELECT 
    u.country AS country_name,
    COUNT(p.purchase_id) AS number_of_purchases,
    ROUND(SUM(p.amount_usd)::numeric, 2) AS total_revenue
FROM purchases p
JOIN users u ON p.user_id = u.user_id
GROUP BY u.country
ORDER BY total_revenue DESC;


-- -----------------------------------------------------------------------------
-- QUESTION 3
-- -----------------------------------------------------------------------------
SELECT 
    g.game_name,
    g.difficulty,
    COUNT(s.session_id) AS total_sessions,
    COUNT(s.session_id) FILTER (WHERE s.completed = 1) AS completed_sessions,
    ROUND(
        100.0 * COUNT(s.session_id) FILTER (WHERE s.completed = 1) / NULLIF(COUNT(s.session_id), 0),
        2
    ) AS completion_rate_pct
FROM sessions s
JOIN games g ON s.game_id = g.game_id
GROUP BY g.game_id, g.game_name, g.difficulty
ORDER BY completion_rate_pct DESC;


-- -----------------------------------------------------------------------------
-- QUESTION 4
-- -----------------------------------------------------------------------------
WITH user_first_session AS (
    SELECT 
        user_id,
        MIN(started_at::date) AS first_session_date
    FROM sessions
    GROUP BY user_id
),
user_activity AS (
    SELECT 
        ufs.user_id,
        date_trunc('week', ufs.first_session_date::timestamp)::date AS cohort_week,
        ufs.first_session_date,
        s.started_at::date AS activity_date
    FROM user_first_session ufs
    JOIN sessions s ON ufs.user_id = s.user_id
)
SELECT 
    cohort_week,
    COUNT(DISTINCT user_id) AS cohort_size,
    ROUND(100.0 * COUNT(DISTINCT CASE 
        WHEN (activity_date - first_session_date) = 1 THEN user_id 
    END) / COUNT(DISTINCT user_id), 2) AS d1_retention_pct,
    ROUND(100.0 * COUNT(DISTINCT CASE 
        WHEN (activity_date - first_session_date) BETWEEN 1 AND 7 THEN user_id 
    END) / COUNT(DISTINCT user_id), 2) AS d7_retention_pct,
    ROUND(100.0 * COUNT(DISTINCT CASE 
        WHEN (activity_date - first_session_date) BETWEEN 1 AND 30 THEN user_id 
    END) / COUNT(DISTINCT user_id), 2) AS d30_retention_pct
FROM user_activity
GROUP BY cohort_week
ORDER BY cohort_week;


-- -----------------------------------------------------------------------------
-- BONUS: Daily retention (with date spine - 4 CTEs)
-- -----------------------------------------------------------------------------
WITH date_spine AS (
    SELECT generate_series(
        (SELECT MIN(started_at)::date FROM sessions),
        (SELECT MAX(started_at)::date FROM sessions),
        '1 day'::interval
    )::date AS activity_date
),
user_first_activity AS (
    SELECT user_id, MIN(started_at)::date AS first_activity_date
    FROM sessions
    GROUP BY user_id
),
daily_active AS (
    SELECT started_at::date AS activity_date, COUNT(DISTINCT user_id) AS total_users_active
    FROM sessions
    GROUP BY started_at::date
),
cohorts_and_returns AS (
    SELECT
        ds.activity_date,
        COUNT(DISTINCT CASE WHEN ufa.first_activity_date = ds.activity_date - 1 THEN ufa.user_id END) AS d1_cohort,
        COUNT(DISTINCT CASE WHEN ufa.first_activity_date = ds.activity_date - 1 AND s.user_id IS NOT NULL THEN ufa.user_id END) AS d1_returned,
        COUNT(DISTINCT CASE WHEN ufa.first_activity_date BETWEEN ds.activity_date - 7 AND ds.activity_date - 1 THEN ufa.user_id END) AS d7_cohort,
        COUNT(DISTINCT CASE WHEN ufa.first_activity_date BETWEEN ds.activity_date - 7 AND ds.activity_date - 1 AND s.user_id IS NOT NULL THEN ufa.user_id END) AS d7_returned,
        COUNT(DISTINCT CASE WHEN ufa.first_activity_date BETWEEN ds.activity_date - 30 AND ds.activity_date - 1 THEN ufa.user_id END) AS d30_cohort,
        COUNT(DISTINCT CASE WHEN ufa.first_activity_date BETWEEN ds.activity_date - 30 AND ds.activity_date - 1 AND s.user_id IS NOT NULL THEN ufa.user_id END) AS d30_returned
    FROM date_spine ds
    LEFT JOIN user_first_activity ufa ON ufa.first_activity_date BETWEEN ds.activity_date - 30 AND ds.activity_date - 1
    LEFT JOIN sessions s ON s.user_id = ufa.user_id AND s.started_at::date = ds.activity_date
    GROUP BY ds.activity_date
)
SELECT
    cr.activity_date,
    da.total_users_active,
    ROUND(100.0 * cr.d1_returned / NULLIF(cr.d1_cohort, 0), 2) AS d1_retention_pct,
    ROUND(100.0 * cr.d7_returned / NULLIF(cr.d7_cohort, 0), 2) AS d7_retention_pct,
    ROUND(100.0 * cr.d30_returned / NULLIF(cr.d30_cohort, 0), 2) AS d30_retention_pct
FROM cohorts_and_returns cr
LEFT JOIN daily_active da ON da.activity_date = cr.activity_date
ORDER BY cr.activity_date;


-- -----------------------------------------------------------------------------
-- BONUS: Daily retention (no date spine - 4 CTEs)
-- -----------------------------------------------------------------------------
WITH activity_dates AS (
    SELECT DISTINCT started_at::date AS activity_date
    FROM sessions
),
user_first_activity AS (
    SELECT user_id, MIN(started_at)::date AS first_activity_date
    FROM sessions
    GROUP BY user_id
),
daily_active AS (
    SELECT started_at::date AS activity_date, COUNT(DISTINCT user_id) AS total_users_active
    FROM sessions
    GROUP BY started_at::date
),
cohorts_and_returns AS (
    SELECT
        ad.activity_date,
        COUNT(DISTINCT CASE WHEN ufa.first_activity_date = ad.activity_date - 1 THEN ufa.user_id END) AS d1_cohort,
        COUNT(DISTINCT CASE WHEN ufa.first_activity_date = ad.activity_date - 1 AND s.user_id IS NOT NULL THEN ufa.user_id END) AS d1_returned,
        COUNT(DISTINCT CASE WHEN ufa.first_activity_date BETWEEN ad.activity_date - 7 AND ad.activity_date - 1 THEN ufa.user_id END) AS d7_cohort,
        COUNT(DISTINCT CASE WHEN ufa.first_activity_date BETWEEN ad.activity_date - 7 AND ad.activity_date - 1 AND s.user_id IS NOT NULL THEN ufa.user_id END) AS d7_returned,
        COUNT(DISTINCT CASE WHEN ufa.first_activity_date BETWEEN ad.activity_date - 30 AND ad.activity_date - 1 THEN ufa.user_id END) AS d30_cohort,
        COUNT(DISTINCT CASE WHEN ufa.first_activity_date BETWEEN ad.activity_date - 30 AND ad.activity_date - 1 AND s.user_id IS NOT NULL THEN ufa.user_id END) AS d30_returned
    FROM activity_dates ad
    LEFT JOIN user_first_activity ufa ON ufa.first_activity_date BETWEEN ad.activity_date - 30 AND ad.activity_date - 1
    LEFT JOIN sessions s ON s.user_id = ufa.user_id AND s.started_at::date = ad.activity_date
    GROUP BY ad.activity_date
)
SELECT
    cr.activity_date,
    da.total_users_active,
    ROUND(100.0 * cr.d1_returned / NULLIF(cr.d1_cohort, 0), 2) AS d1_retention_pct,
    ROUND(100.0 * cr.d7_returned / NULLIF(cr.d7_cohort, 0), 2) AS d7_retention_pct,
    ROUND(100.0 * cr.d30_returned / NULLIF(cr.d30_cohort, 0), 2) AS d30_retention_pct
FROM cohorts_and_returns cr
LEFT JOIN daily_active da ON da.activity_date = cr.activity_date
ORDER BY cr.activity_date;


-- -----------------------------------------------------------------------------
-- BONUS: D1 retention only (line-by-line explanation of cohorts_and_returns)
-- -----------------------------------------------------------------------------
WITH activity_dates AS (
    SELECT DISTINCT started_at::date AS activity_date  -- each date we have session activity
    FROM sessions
),
user_first_activity AS (
    SELECT user_id, MIN(started_at)::date AS first_activity_date  -- when each user first played
    FROM sessions
    GROUP BY user_id
),
daily_active AS (
    SELECT started_at::date AS activity_date, COUNT(DISTINCT user_id) AS total_users_active
    FROM sessions
    GROUP BY started_at::date
),
cohorts_and_returns AS (
    SELECT
        ad.activity_date,  -- the date we're measuring retention for
        -- d1_cohort: count users whose first session was yesterday (activity_date - 1)
        COUNT(DISTINCT CASE WHEN ufa.first_activity_date = ad.activity_date - 1 THEN ufa.user_id END) AS d1_cohort,
        -- d1_returned: of those users, count who had a session on activity_date (s.user_id IS NOT NULL)
        COUNT(DISTINCT CASE WHEN ufa.first_activity_date = ad.activity_date - 1 AND s.user_id IS NOT NULL THEN ufa.user_id END) AS d1_returned
    FROM activity_dates ad
    -- bring in users whose first session was yesterday; each row = (activity_date, user)
    LEFT JOIN user_first_activity ufa ON ufa.first_activity_date = ad.activity_date - 1
    -- for each (activity_date, user): did they have a session on activity_date? non-null = returned
    LEFT JOIN sessions s ON s.user_id = ufa.user_id AND s.started_at::date = ad.activity_date
    GROUP BY ad.activity_date
)
SELECT
    cr.activity_date,
    da.total_users_active,
    ROUND(100.0 * cr.d1_returned / NULLIF(cr.d1_cohort, 0), 2) AS d1_retention_pct  -- returned / cohort * 100
FROM cohorts_and_returns cr
LEFT JOIN daily_active da ON da.activity_date = cr.activity_date
ORDER BY cr.activity_date;


-- -----------------------------------------------------------------------------
-- QUESTION 5
-- -----------------------------------------------------------------------------
WITH funnel_stages AS (
    SELECT 
        u.user_id,
        u.created_at AS signup_date,
        MIN(s.started_at) AS first_session_date,
        MIN(CASE WHEN s.completed = 1 THEN s.started_at END) AS first_completed_session_date,
        MIN(p.purchased_at) AS first_purchase_date
    FROM users u
    LEFT JOIN sessions s ON u.user_id = s.user_id
    LEFT JOIN purchases p ON u.user_id = p.user_id
    GROUP BY u.user_id, u.created_at
)
SELECT 
    COUNT(*) AS total_signups,
    SUM(CASE WHEN first_session_date IS NOT NULL THEN 1 ELSE 0 END) AS played_first_session,
    ROUND(100.0 * SUM(CASE WHEN first_session_date IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*), 2) AS signup_to_session_pct,
    SUM(CASE WHEN first_completed_session_date IS NOT NULL THEN 1 ELSE 0 END) AS completed_first_session,
    ROUND(100.0 * SUM(CASE WHEN first_completed_session_date IS NOT NULL THEN 1 ELSE 0 END) / 
          NULLIF(SUM(CASE WHEN first_session_date IS NOT NULL THEN 1 ELSE 0 END), 0), 2) AS session_to_completion_pct,
    SUM(CASE WHEN first_purchase_date IS NOT NULL THEN 1 ELSE 0 END) AS made_purchase,
    ROUND(100.0 * SUM(CASE WHEN first_purchase_date IS NOT NULL THEN 1 ELSE 0 END) / 
          NULLIF(SUM(CASE WHEN first_completed_session_date IS NOT NULL THEN 1 ELSE 0 END), 0), 2) AS completion_to_purchase_pct
FROM funnel_stages;


-- -----------------------------------------------------------------------------
-- QUESTION 6
-- -----------------------------------------------------------------------------
-- 1. Define a composite deduplication key (e.g. event_id, user_id, session_id, created_at).
--    Use ROW_NUMBER() OVER (PARTITION BY key ORDER BY created_at) and keep rn = 1.
--    In Snowflake: QUALIFY ROW_NUMBER() OVER (PARTITION BY key ORDER BY created_at) = 1.
--
-- 2. Use MERGE (upsert) with the composite key as the unique constraint so duplicates
--    are updated or skipped. For append-only: INSERT ... ON CONFLICT DO NOTHING.
--
-- 3. Idempotent writes: include a load_id or batch_id; dedupe by (business_key, load_id)
--    before insert so re-runs don't create duplicates.
