-- =============================================================================
-- WEEKEND TECHNICAL EXERCISE - WARM-UP (NOT TIMED) - CORRECT ANSWERS
-- Date: 2026-03-16   Time: 21:00
-- Database: PostgreSQL   Schema: volley_games (users, games, sessions, events, purchases)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- QUESTION 1
-- -----------------------------------------------------------------------------
SELECT COUNT(*) AS user_count
FROM users;


-- -----------------------------------------------------------------------------
-- QUESTION 2
-- -----------------------------------------------------------------------------
SELECT 
    to_char(created_at::date, 'YYYY-MM') AS signup_month,
    COUNT(*) AS user_count
FROM users
GROUP BY to_char(created_at::date, 'YYYY-MM')
ORDER BY user_count DESC
LIMIT 1;


-- -----------------------------------------------------------------------------
-- QUESTION 3
-- -----------------------------------------------------------------------------
SELECT 
    started_at::date AS activity_date,
    COUNT(DISTINCT user_id) AS dau
FROM sessions
GROUP BY started_at::date
ORDER BY activity_date;


-- -----------------------------------------------------------------------------
-- QUESTION 4
-- -----------------------------------------------------------------------------
SELECT 
    g.game_name,
    s.device_type,
    COUNT(s.session_id) AS number_of_sessions,
    ROUND(AVG(EXTRACT(EPOCH FROM (s.ended_at - s.started_at)) / 60)::numeric, 2) AS average_session_length
FROM sessions s
JOIN games g ON s.game_id = g.game_id
WHERE s.started_at IS NOT NULL AND s.ended_at IS NOT NULL
GROUP BY g.game_id, g.game_name, s.device_type
ORDER BY g.game_name, s.device_type;


-- -----------------------------------------------------------------------------
-- QUESTION 5
-- -----------------------------------------------------------------------------
WITH date_spine AS (
    SELECT generate_series(
        (SELECT MIN(started_at::date) FROM sessions),
        (SELECT MAX(started_at::date) FROM sessions),
        '1 day'::interval
    )::date AS activity_date
),
daily_dau AS (
    SELECT 
        started_at::date AS activity_date,
        COUNT(DISTINCT user_id) AS dau
    FROM sessions
    GROUP BY started_at::date
),
dau_calendar AS (
    SELECT 
        ds.activity_date,
        COALESCE(dau.dau, 0) AS dau
    FROM date_spine ds
    LEFT JOIN daily_dau dau ON ds.activity_date = dau.activity_date
)
SELECT 
    activity_date,
    dau,
    LAG(dau, 1) OVER (ORDER BY activity_date) AS prev_day_dau,
    ROUND(
        100.0 * (dau - LAG(dau, 1) OVER (ORDER BY activity_date)) / 
        NULLIF(LAG(dau, 1) OVER (ORDER BY activity_date), 0),
        2
    ) AS dau_change_pct
FROM dau_calendar
ORDER BY activity_date;


-- -----------------------------------------------------------------------------
-- QUESTION 6
-- -----------------------------------------------------------------------------
WITH max_date AS (
    SELECT MAX(started_at::date) AS today
    FROM sessions
),
user_last_activity AS (
    SELECT 
        u.user_id,
        u.username,
        u.is_premium,
        MAX(s.started_at::date) AS last_active_date
    FROM users u
    JOIN sessions s ON u.user_id = s.user_id
    GROUP BY u.user_id, u.username, u.is_premium
)
SELECT 
    ula.user_id,
    ula.username,
    ula.is_premium,
    ula.last_active_date,
    (md.today - ula.last_active_date) AS days_since_active,
    CASE 
        WHEN (md.today - ula.last_active_date) <= 7 THEN 'ACTIVE'
        WHEN (md.today - ula.last_active_date) BETWEEN 8 AND 14 THEN 'AT_RISK'
        WHEN (md.today - ula.last_active_date) BETWEEN 15 AND 30 THEN 'DORMANT'
        ELSE 'CHURNED'
    END AS churn_status
FROM user_last_activity ula
CROSS JOIN max_date md
ORDER BY days_since_active DESC;


-- -----------------------------------------------------------------------------
-- QUESTION 7
-- -----------------------------------------------------------------------------
-- 1. Define a composite key (e.g. event_id, user_id, session_id, created_at) that
--    uniquely identifies an event. Use ROW_NUMBER() OVER (PARTITION BY key ORDER BY created_at)
--    and keep only rows where rn = 1. In Snowflake: QUALIFY ROW_NUMBER() OVER (PARTITION BY key ORDER BY created_at) = 1.
--
-- 2. Use a hash (MD5/SHA) of the key columns to identify duplicates. Group by the hash
--    and keep one row per group (e.g. MIN or MAX by created_at).
--
-- 3. For idempotent loads: use MERGE (or INSERT ... ON CONFLICT) with the composite key
--    as the unique constraint so duplicates are skipped or updated.
