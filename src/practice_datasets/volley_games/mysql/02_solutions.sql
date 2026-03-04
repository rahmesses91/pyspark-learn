-- =============================================================================
-- VOLLEY GAMES - SQL PRACTICE PROBLEMS - SOLUTIONS
-- MySQL 8.0+
-- =============================================================================

USE volley_games;

-- =============================================================================
-- LEVEL 0: BASIC QUERIES (Warm-up)
-- =============================================================================

-- Q1: How many users are there in total?
SELECT COUNT(*) AS total_users FROM users;


-- Q2: How many games are available on the platform?
SELECT COUNT(*) AS total_games FROM games;


-- Q3: How many sessions were completed successfully?
SELECT COUNT(*) AS completed_sessions 
FROM sessions 
WHERE completed = 1;


-- Q4: What is the total revenue from all purchases?
SELECT SUM(amount_usd) AS total_revenue FROM purchases;


-- Q5: Which country has the most users?
SELECT country, COUNT(*) AS user_count
FROM users
GROUP BY country
ORDER BY user_count DESC
LIMIT 1;


-- Q6: In which month did the most users sign up?
SELECT 
    DATE_FORMAT(created_at, '%Y-%m') AS signup_month,
    COUNT(*) AS user_count
FROM users
GROUP BY DATE_FORMAT(created_at, '%Y-%m')
ORDER BY user_count DESC
LIMIT 1;


-- Q7: What is the most popular device type among users?
SELECT device_type, COUNT(*) AS user_count
FROM users
GROUP BY device_type
ORDER BY user_count DESC
LIMIT 1;


-- Q8: How many premium vs non-premium users are there?
SELECT 
    CASE WHEN is_premium = 1 THEN 'Premium' ELSE 'Free' END AS user_type,
    COUNT(*) AS user_count
FROM users
GROUP BY is_premium;


-- Q9: What is the average purchase amount?
SELECT ROUND(AVG(amount_usd), 2) AS avg_purchase_amount FROM purchases;


-- Q10: Which game category has the most games?
SELECT category, COUNT(*) AS game_count
FROM games
GROUP BY category
ORDER BY game_count DESC
LIMIT 1;


-- Q11: What is the most common item type purchased?
SELECT item_type, COUNT(*) AS purchase_count
FROM purchases
GROUP BY item_type
ORDER BY purchase_count DESC
LIMIT 1;


-- Q12: Find the username who has spent the most money
SELECT u.username, SUM(p.amount_usd) AS total_spent
FROM users u
JOIN purchases p ON u.user_id = p.user_id
GROUP BY u.user_id, u.username
ORDER BY total_spent DESC
LIMIT 1;


-- =============================================================================
-- LEVEL 1: BASIC AGGREGATIONS
-- =============================================================================

-- Problem 1: Daily Active Users (DAU)
SELECT 
    DATE(started_at) AS activity_date,
    COUNT(DISTINCT user_id) AS dau
FROM sessions
GROUP BY DATE(started_at)
ORDER BY activity_date;


-- Problem 2: Most Popular Games
SELECT 
    g.game_name,
    g.category,
    COUNT(s.session_id) AS total_sessions
FROM games g
LEFT JOIN sessions s ON g.game_id = s.game_id
GROUP BY g.game_id, g.game_name, g.category
ORDER BY total_sessions DESC;


-- Problem 3: Revenue by Country
SELECT 
    u.country,
    COUNT(p.purchase_id) AS num_purchases,
    SUM(p.amount_usd) AS total_revenue
FROM users u
JOIN purchases p ON u.user_id = p.user_id
GROUP BY u.country
ORDER BY total_revenue DESC;


-- =============================================================================
-- LEVEL 2: INTERMEDIATE JOINS & GROUPING
-- =============================================================================

-- Problem 4: Session Duration Analysis
SELECT 
    g.game_name,
    s.device_type,
    COUNT(s.session_id) AS num_sessions,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, s.started_at, s.ended_at)), 2) AS avg_duration_minutes
FROM sessions s
JOIN games g ON s.game_id = g.game_id
WHERE s.ended_at IS NOT NULL
GROUP BY g.game_id, g.game_name, s.device_type
ORDER BY g.game_name, s.device_type;


-- Problem 5: Completion Rate by Game
SELECT 
    g.game_name,
    g.difficulty,
    COUNT(s.session_id) AS total_sessions,
    SUM(s.completed) AS completed_sessions,
    ROUND(100.0 * SUM(s.completed) / COUNT(s.session_id), 2) AS completion_rate_pct
FROM games g
JOIN sessions s ON g.game_id = s.game_id
GROUP BY g.game_id, g.game_name, g.difficulty
ORDER BY completion_rate_pct DESC;


-- Problem 6: Premium Conversion Rate
WITH active_users AS (
    SELECT DISTINCT user_id
    FROM sessions
),
users_with_purchases AS (
    SELECT DISTINCT user_id
    FROM purchases
)
SELECT 
    u.is_premium,
    COUNT(DISTINCT au.user_id) AS active_users,
    COUNT(DISTINCT up.user_id) AS users_who_purchased,
    ROUND(100.0 * COUNT(DISTINCT up.user_id) / NULLIF(COUNT(DISTINCT au.user_id), 0), 2) AS conversion_rate_pct
FROM active_users au
JOIN users u ON au.user_id = u.user_id
LEFT JOIN users_with_purchases up ON au.user_id = up.user_id
GROUP BY u.is_premium;


-- =============================================================================
-- LEVEL 3: WINDOW FUNCTIONS
-- =============================================================================

-- Problem 7: Day-over-Day DAU Growth
WITH daily_dau AS (
    SELECT 
        DATE(started_at) AS activity_date,
        COUNT(DISTINCT user_id) AS dau
    FROM sessions
    GROUP BY DATE(started_at)
)
SELECT 
    activity_date,
    dau,
    LAG(dau, 1) OVER (ORDER BY activity_date) AS prev_day_dau,
    ROUND(100.0 * (dau - LAG(dau, 1) OVER (ORDER BY activity_date)) / 
          NULLIF(LAG(dau, 1) OVER (ORDER BY activity_date), 0), 2) AS dau_change_pct
FROM daily_dau
ORDER BY activity_date;


-- Problem 8: User Retention (Day 1, Day 7, Day 30)
WITH user_first_session AS (
    SELECT 
        user_id,
        MIN(DATE(started_at)) AS first_session_date
    FROM sessions
    GROUP BY user_id
),
user_activity AS (
    SELECT 
        ufs.user_id,
        ufs.first_session_date,
        DATE(s.started_at) AS activity_date
    FROM user_first_session ufs
    JOIN sessions s ON ufs.user_id = s.user_id
)
SELECT 
    DATE(first_session_date - INTERVAL WEEKDAY(first_session_date) DAY) AS cohort_week,
    COUNT(DISTINCT user_id) AS cohort_size,
    COUNT(DISTINCT CASE 
        WHEN DATEDIFF(activity_date, first_session_date) = 1 
        THEN user_id 
    END) AS returned_day_1,
    ROUND(100.0 * COUNT(DISTINCT CASE 
        WHEN DATEDIFF(activity_date, first_session_date) = 1 
        THEN user_id 
    END) / COUNT(DISTINCT user_id), 2) AS d1_retention_pct,
    COUNT(DISTINCT CASE 
        WHEN DATEDIFF(activity_date, first_session_date) BETWEEN 1 AND 7 
        THEN user_id 
    END) AS returned_within_7_days,
    ROUND(100.0 * COUNT(DISTINCT CASE 
        WHEN DATEDIFF(activity_date, first_session_date) BETWEEN 1 AND 7 
        THEN user_id 
    END) / COUNT(DISTINCT user_id), 2) AS d7_retention_pct,
    COUNT(DISTINCT CASE 
        WHEN DATEDIFF(activity_date, first_session_date) BETWEEN 1 AND 30 
        THEN user_id 
    END) AS returned_within_30_days,
    ROUND(100.0 * COUNT(DISTINCT CASE 
        WHEN DATEDIFF(activity_date, first_session_date) BETWEEN 1 AND 30 
        THEN user_id 
    END) / COUNT(DISTINCT user_id), 2) AS d30_retention_pct
FROM user_activity
GROUP BY DATE(first_session_date - INTERVAL WEEKDAY(first_session_date) DAY)
ORDER BY cohort_week;


-- Problem 9: Running Revenue by Game
WITH daily_revenue AS (
    SELECT 
        p.game_id,
        g.game_name,
        DATE(p.purchased_at) AS purchase_date,
        SUM(p.amount_usd) AS daily_revenue
    FROM purchases p
    JOIN games g ON p.game_id = g.game_id
    WHERE p.game_id IS NOT NULL
    GROUP BY p.game_id, g.game_name, DATE(p.purchased_at)
)
SELECT 
    game_name,
    purchase_date,
    daily_revenue,
    SUM(daily_revenue) OVER (
        PARTITION BY game_id 
        ORDER BY purchase_date 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total_revenue
FROM daily_revenue
ORDER BY game_name, purchase_date;


-- Problem 10: Top Players Leaderboard
SELECT 
    u.user_id,
    u.username,
    u.country,
    COUNT(s.session_id) AS total_sessions,
    ROUND(SUM(TIMESTAMPDIFF(MINUTE, s.started_at, s.ended_at)), 0) AS total_minutes_played,
    RANK() OVER (ORDER BY SUM(TIMESTAMPDIFF(MINUTE, s.started_at, s.ended_at)) DESC) AS player_rank
FROM users u
JOIN sessions s ON u.user_id = s.user_id
WHERE s.ended_at IS NOT NULL
GROUP BY u.user_id, u.username, u.country
ORDER BY player_rank
LIMIT 100;


-- =============================================================================
-- LEVEL 4: ADVANCED ANALYTICS
-- =============================================================================

-- Problem 11: Cohort Retention Matrix
WITH user_cohorts AS (
    SELECT 
        user_id,
        MIN(DATE(started_at)) AS first_session_date,
        DATE(MIN(DATE(started_at)) - INTERVAL WEEKDAY(MIN(DATE(started_at))) DAY) AS cohort_week
    FROM sessions
    GROUP BY user_id
),
user_weekly_activity AS (
    SELECT 
        uc.user_id,
        uc.cohort_week,
        DATE(s.started_at - INTERVAL WEEKDAY(s.started_at) DAY) AS activity_week,
        FLOOR(DATEDIFF(DATE(s.started_at), uc.first_session_date) / 7) AS weeks_since_signup
    FROM user_cohorts uc
    JOIN sessions s ON uc.user_id = s.user_id
)
SELECT 
    cohort_week,
    COUNT(DISTINCT user_id) AS cohort_size,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN weeks_since_signup = 0 THEN user_id END) / COUNT(DISTINCT user_id), 1) AS week_0,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN weeks_since_signup = 1 THEN user_id END) / COUNT(DISTINCT user_id), 1) AS week_1,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN weeks_since_signup = 2 THEN user_id END) / COUNT(DISTINCT user_id), 1) AS week_2,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN weeks_since_signup = 3 THEN user_id END) / COUNT(DISTINCT user_id), 1) AS week_3,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN weeks_since_signup = 4 THEN user_id END) / COUNT(DISTINCT user_id), 1) AS week_4,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN weeks_since_signup = 5 THEN user_id END) / COUNT(DISTINCT user_id), 1) AS week_5,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN weeks_since_signup = 6 THEN user_id END) / COUNT(DISTINCT user_id), 1) AS week_6,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN weeks_since_signup = 7 THEN user_id END) / COUNT(DISTINCT user_id), 1) AS week_7,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN weeks_since_signup = 8 THEN user_id END) / COUNT(DISTINCT user_id), 1) AS week_8
FROM user_weekly_activity
GROUP BY cohort_week
ORDER BY cohort_week;


-- Problem 12: Conversion Funnel Analysis
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


-- Problem 13: Churn Risk Detection
-- Detailed view:
WITH max_date AS (
    SELECT MAX(DATE(started_at)) AS today
    FROM sessions
),
user_last_activity AS (
    SELECT 
        u.user_id,
        u.username,
        u.is_premium,
        MAX(DATE(s.started_at)) AS last_active_date
    FROM users u
    JOIN sessions s ON u.user_id = s.user_id
    GROUP BY u.user_id, u.username, u.is_premium
)
SELECT 
    ula.user_id,
    ula.username,
    ula.is_premium,
    ula.last_active_date,
    DATEDIFF(md.today, ula.last_active_date) AS days_since_active,
    CASE 
        WHEN DATEDIFF(md.today, ula.last_active_date) <= 7 THEN 'ACTIVE'
        WHEN DATEDIFF(md.today, ula.last_active_date) BETWEEN 8 AND 14 THEN 'AT_RISK'
        WHEN DATEDIFF(md.today, ula.last_active_date) BETWEEN 15 AND 30 THEN 'DORMANT'
        ELSE 'CHURNED'
    END AS churn_status
FROM user_last_activity ula
CROSS JOIN max_date md
ORDER BY days_since_active DESC;

-- Aggregated churn summary:
WITH max_date AS (
    SELECT MAX(DATE(started_at)) AS today
    FROM sessions
),
user_last_activity AS (
    SELECT 
        u.user_id,
        MAX(DATE(s.started_at)) AS last_active_date
    FROM users u
    JOIN sessions s ON u.user_id = s.user_id
    GROUP BY u.user_id
),
user_churn_status AS (
    SELECT 
        ula.user_id,
        CASE 
            WHEN DATEDIFF(md.today, ula.last_active_date) <= 7 THEN 'ACTIVE'
            WHEN DATEDIFF(md.today, ula.last_active_date) BETWEEN 8 AND 14 THEN 'AT_RISK'
            WHEN DATEDIFF(md.today, ula.last_active_date) BETWEEN 15 AND 30 THEN 'DORMANT'
            ELSE 'CHURNED'
        END AS churn_status
    FROM user_last_activity ula
    CROSS JOIN max_date md
)
SELECT 
    churn_status,
    COUNT(*) AS user_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM user_churn_status), 2) AS percentage
FROM user_churn_status
GROUP BY churn_status
ORDER BY FIELD(churn_status, 'ACTIVE', 'AT_RISK', 'DORMANT', 'CHURNED');


-- Problem 14: Lifetime Value (LTV) by Acquisition Cohort
WITH user_cohorts AS (
    SELECT 
        user_id,
        DATE_FORMAT(created_at, '%Y-%m') AS signup_month
    FROM users
),
user_ltv AS (
    SELECT 
        uc.user_id,
        uc.signup_month,
        COALESCE(SUM(p.amount_usd), 0) AS total_spent
    FROM user_cohorts uc
    LEFT JOIN purchases p ON uc.user_id = p.user_id
    GROUP BY uc.user_id, uc.signup_month
)
SELECT 
    signup_month,
    COUNT(*) AS cohort_size,
    SUM(CASE WHEN total_spent > 0 THEN 1 ELSE 0 END) AS paying_users,
    ROUND(100.0 * SUM(CASE WHEN total_spent > 0 THEN 1 ELSE 0 END) / COUNT(*), 2) AS payer_rate_pct,
    ROUND(SUM(total_spent), 2) AS total_revenue,
    ROUND(AVG(total_spent), 2) AS avg_ltv_all_users,
    ROUND(SUM(total_spent) / NULLIF(SUM(CASE WHEN total_spent > 0 THEN 1 ELSE 0 END), 0), 2) AS avg_ltv_payers_only
FROM user_ltv
GROUP BY signup_month
ORDER BY signup_month;


-- Problem 15: Voice Command Success Rate by Game Difficulty
-- By game:
WITH voice_commands AS (
    SELECT 
        e.event_id,
        e.session_id,
        s.game_id,
        g.game_name,
        g.difficulty,
        JSON_EXTRACT(e.event_data, '$.recognized') AS recognized
    FROM events e
    JOIN sessions s ON e.session_id = s.session_id
    JOIN games g ON s.game_id = g.game_id
    WHERE e.event_type = 'voice_command'
)
SELECT 
    game_name,
    difficulty,
    COUNT(*) AS total_commands,
    SUM(CASE WHEN recognized = 'true' OR recognized = TRUE THEN 1 ELSE 0 END) AS recognized_commands,
    ROUND(100.0 * SUM(CASE WHEN recognized = 'true' OR recognized = TRUE THEN 1 ELSE 0 END) / COUNT(*), 2) AS recognition_rate_pct
FROM voice_commands
GROUP BY game_name, difficulty
ORDER BY recognition_rate_pct ASC;

-- Aggregate by difficulty level:
WITH voice_commands AS (
    SELECT 
        e.event_id,
        s.game_id,
        g.difficulty,
        JSON_EXTRACT(e.event_data, '$.recognized') AS recognized
    FROM events e
    JOIN sessions s ON e.session_id = s.session_id
    JOIN games g ON s.game_id = g.game_id
    WHERE e.event_type = 'voice_command'
)
SELECT 
    difficulty,
    COUNT(*) AS total_commands,
    SUM(CASE WHEN recognized = 'true' OR recognized = TRUE THEN 1 ELSE 0 END) AS recognized_commands,
    ROUND(100.0 * SUM(CASE WHEN recognized = 'true' OR recognized = TRUE THEN 1 ELSE 0 END) / COUNT(*), 2) AS recognition_rate_pct
FROM voice_commands
GROUP BY difficulty
ORDER BY FIELD(difficulty, 'easy', 'medium', 'hard');


-- =============================================================================
-- BONUS PROBLEMS
-- =============================================================================

-- Bonus 1: Session Engagement Score
WITH session_metrics AS (
    SELECT 
        s.session_id,
        s.user_id,
        g.game_name,
        LEAST(TIMESTAMPDIFF(MINUTE, s.started_at, s.ended_at), 30) AS duration_score,
        LEAST(COUNT(CASE WHEN e.event_type = 'voice_command' THEN 1 END), 20) AS command_score,
        s.completed * 2 AS completion_multiplier,
        COUNT(CASE WHEN e.event_type = 'achievement' THEN 1 END) * 5 AS achievement_bonus
    FROM sessions s
    JOIN games g ON s.game_id = g.game_id
    LEFT JOIN events e ON s.session_id = e.session_id
    WHERE s.ended_at IS NOT NULL
    GROUP BY s.session_id, s.user_id, g.game_name, s.started_at, s.ended_at, s.completed
)
SELECT 
    session_id,
    user_id,
    game_name,
    duration_score,
    command_score,
    completion_multiplier,
    achievement_bonus,
    (duration_score + command_score) * (1 + completion_multiplier) + achievement_bonus AS engagement_score
FROM session_metrics
ORDER BY engagement_score DESC
LIMIT 100;


-- Bonus 2: User Segmentation by Behavior
WITH max_date AS (
    SELECT MAX(DATE(started_at)) AS today FROM sessions
),
user_stats AS (
    SELECT 
        u.user_id,
        u.username,
        COUNT(DISTINCT s.session_id) AS total_sessions,
        SUM(s.completed) AS completed_sessions,
        MAX(DATE(s.started_at)) AS last_active,
        COALESCE(SUM(p.amount_usd), 0) AS total_spent
    FROM users u
    LEFT JOIN sessions s ON u.user_id = s.user_id
    LEFT JOIN purchases p ON u.user_id = p.user_id
    GROUP BY u.user_id, u.username
),
percentiles AS (
    SELECT 
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY total_spent) AS spend_p99,
        PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY total_sessions) AS sessions_p90
    FROM user_stats
    WHERE total_sessions > 0
)
SELECT 
    us.user_id,
    us.username,
    us.total_sessions,
    us.completed_sessions,
    us.total_spent,
    DATEDIFF(md.today, us.last_active) AS days_inactive,
    CASE 
        WHEN us.total_spent >= (SELECT spend_p99 FROM percentiles) THEN 'WHALE'
        WHEN us.total_sessions >= (SELECT sessions_p90 FROM percentiles) THEN 'POWER_USER'
        WHEN us.total_sessions > 0 AND us.completed_sessions / us.total_sessions >= 0.5 THEN 'ENGAGED'
        WHEN DATEDIFF(md.today, us.last_active) <= 30 THEN 'CASUAL'
        ELSE 'INACTIVE'
    END AS user_segment
FROM user_stats us
CROSS JOIN max_date md
ORDER BY 
    FIELD(user_segment, 'WHALE', 'POWER_USER', 'ENGAGED', 'CASUAL', 'INACTIVE'),
    total_spent DESC;
