-- =============================================================================
-- VOLLEY GAMES - SQL PRACTICE PROBLEMS
-- Progressive difficulty for interview preparation
-- MySQL 8.0+
-- =============================================================================

USE volley_games;

-- =============================================================================
-- LEVEL 0: BASIC QUERIES (Warm-up)
-- Single table queries, simple aggregations, no joins required
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Q1: How many users are there in total?
-- -----------------------------------------------------------------------------

SELECT COUNT(USER_ID) FROM VOLLEY_GAMES.USERS;

-- -----------------------------------------------------------------------------
-- Q2: How many games are available on the platform?
-- -----------------------------------------------------------------------------

SELECT COUNT(game_id) FROM volley_games.games g;

-- -----------------------------------------------------------------------------
-- Q3: How many sessions were completed successfully?
-- -----------------------------------------------------------------------------

SELECT COUNT(DISTINCT SESSION_ID) FROM volley_games.sessions s 
WHERE s.completed = 1;

-- -----------------------------------------------------------------------------
-- Q4: What is the total revenue from all purchases?
-- -----------------------------------------------------------------------------

SELECT SUM(p.amount_usd) FROM volley_games.purchases p;

-- -----------------------------------------------------------------------------
-- Q5: Which country has the most users?
-- -----------------------------------------------------------------------------

SELECT
    COUNTRY,
    COUNT(user_id) AS USER_COUNT
FROM volley_games.users
GROUP BY COUNTRY 
ORDER BY COUNT(user_id) DESC LIMIT 1;

-- -----------------------------------------------------------------------------
-- Q6: In which month did the most users sign up?
-- (Return month and count)
-- -----------------------------------------------------------------------------

SELECT 
    MONTH(created_at) AS month_of_signup,
    COUNT(user_id) AS user_count
FROM volley_games.users
GROUP BY month_of_signup
ORDER BY user_count DESC LIMIT 1;

-- -----------------------------------------------------------------------------
-- Q7: What is the most popular device type among users?
-- -----------------------------------------------------------------------------

WITH users_per_device AS (
    SELECT
        device_type,
        COUNT(user_id) AS user_count
    FROM volley_games.users
    GROUP BY device_type 
    ORDER BY user_count DESC LIMIT 1
)
SELECT device_type FROM users_per_device;

-- -----------------------------------------------------------------------------
-- Q8: How many premium vs non-premium users are there?
-- -----------------------------------------------------------------------------

SELECT 
    COUNT(CASE WHEN is_premium = 1 THEN user_id END) AS count_of_premium_users,
    COUNT(CASE WHEN is_premium = 0 THEN user_id END) AS count_of_non_premium_users
FROM volley_games.users;

-- -----------------------------------------------------------------------------
-- Q9: What is the average purchase amount?
-- -----------------------------------------------------------------------------

SELECT ROUND(AVG(amount_usd), 2) AS avg_purchase_amount 
FROM volley_games.purchases;

-- -----------------------------------------------------------------------------
-- Q10: Which game category has the most games?
-- -----------------------------------------------------------------------------

SELECT 
    category, 
    COUNT(game_id) AS game_count
FROM volley_games.games
GROUP BY category
ORDER BY game_count DESC LIMIT 1;

-- -----------------------------------------------------------------------------
-- Q11: What is the most common item type purchased?
-- -----------------------------------------------------------------------------

SELECT 
    item_type, 
    COUNT(purchase_id) AS purchase_count
FROM volley_games.purchases
GROUP BY item_type
ORDER BY purchase_count DESC LIMIT 1;

-- -----------------------------------------------------------------------------
-- Q12: Find the username who has spent the most money
-- (Requires a simple GROUP BY and ORDER BY)
-- -----------------------------------------------------------------------------

SELECT 
    u.username, 
    SUM(p.amount_usd) AS total_spent
FROM volley_games.users u
JOIN volley_games.purchases p ON u.user_id = p.user_id
GROUP BY u.user_id, u.username
ORDER BY total_spent DESC LIMIT 1;



-- =============================================================================
-- LEVEL 1: BASIC AGGREGATIONS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Problem 1: Daily Active Users (DAU)
-- Count distinct users who had at least one session each day
-- Expected: One row per day with date and user count
-- -----------------------------------------------------------------------------

-- YOUR SOLUTION:



-- -----------------------------------------------------------------------------
-- Problem 2: Most Popular Games
-- Rank games by total number of sessions played
-- Include game name, category, and session count
-- -----------------------------------------------------------------------------

-- YOUR SOLUTION:



-- -----------------------------------------------------------------------------
-- Problem 3: Revenue by Country
-- Total purchase revenue grouped by user country
-- Include country, total revenue, and number of purchases
-- -----------------------------------------------------------------------------

-- YOUR SOLUTION:



-- =============================================================================
-- LEVEL 2: INTERMEDIATE JOINS & GROUPING
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Problem 4: Session Duration Analysis
-- Average session length (in minutes) by game and device type
-- Only include sessions that have both start and end times
-- -----------------------------------------------------------------------------

-- YOUR SOLUTION:



-- -----------------------------------------------------------------------------
-- Problem 5: Completion Rate by Game
-- Calculate % of sessions completed vs abandoned for each game
-- Include total sessions, completed sessions, and completion rate
-- -----------------------------------------------------------------------------

-- YOUR SOLUTION:



-- -----------------------------------------------------------------------------
-- Problem 6: Premium Conversion Rate
-- What % of users who have played at least one session have made a purchase?
-- Segment by premium vs non-premium users
-- -----------------------------------------------------------------------------

-- YOUR SOLUTION:



-- =============================================================================
-- LEVEL 3: WINDOW FUNCTIONS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Problem 7: Day-over-Day DAU Growth
-- Calculate DAU for each day and the % change from the previous day
-- Use LAG() window function
-- -----------------------------------------------------------------------------

-- YOUR SOLUTION:



-- -----------------------------------------------------------------------------
-- Problem 8: User Retention (Day 1, Day 7, Day 30)
-- For each signup cohort (by week), calculate retention rates
-- Day 1: % who played again the next day
-- Day 7: % who played again within 7 days
-- Day 30: % who played again within 30 days
-- -----------------------------------------------------------------------------

-- YOUR SOLUTION:



-- -----------------------------------------------------------------------------
-- Problem 9: Running Revenue by Game
-- Calculate cumulative revenue for each game over time
-- Include daily revenue and running total
-- -----------------------------------------------------------------------------

-- YOUR SOLUTION:



-- -----------------------------------------------------------------------------
-- Problem 10: Top Players Leaderboard
-- Rank users by total play time across all sessions
-- Include username, total sessions, total minutes, and rank
-- Show top 100 players
-- -----------------------------------------------------------------------------

-- YOUR SOLUTION:



-- =============================================================================
-- LEVEL 4: ADVANCED ANALYTICS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Problem 11: Cohort Retention Matrix
-- Create a weekly retention matrix showing % of users retained each week
-- Rows: signup cohort week
-- Columns: Week 0, Week 1, Week 2, ... Week 8
-- -----------------------------------------------------------------------------

-- YOUR SOLUTION:



-- -----------------------------------------------------------------------------
-- Problem 12: Conversion Funnel Analysis
-- Track user journey: Signup → First Session → First Completed Session → First Purchase
-- Calculate conversion rates between each stage
-- -----------------------------------------------------------------------------

-- YOUR SOLUTION:



-- -----------------------------------------------------------------------------
-- Problem 13: Churn Risk Detection
-- Identify users at risk of churning based on activity patterns
-- Categories:
--   - ACTIVE: played in last 7 days
--   - AT_RISK: last played 8-14 days ago
--   - DORMANT: last played 15-30 days ago
--   - CHURNED: no activity in 30+ days
-- Use the max date in the data as "today"
-- -----------------------------------------------------------------------------

-- YOUR SOLUTION:



-- -----------------------------------------------------------------------------
-- Problem 14: Lifetime Value (LTV) by Acquisition Cohort
-- Calculate average LTV (total spending) by monthly signup cohort
-- Include: cohort month, cohort size, total revenue, avg LTV
-- -----------------------------------------------------------------------------

-- YOUR SOLUTION:



-- -----------------------------------------------------------------------------
-- Problem 15: Voice Command Success Rate by Game Difficulty
-- Analyze voice recognition success rate across different game difficulties
-- Extract 'recognized' from event_data JSON
-- Calculate success rate and identify problematic games
-- -----------------------------------------------------------------------------

-- YOUR SOLUTION:



-- =============================================================================
-- BONUS PROBLEMS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Bonus 1: Session Engagement Score
-- Create a composite engagement score for each session based on:
--   - Duration (longer = better, capped at 30 min)
--   - Voice commands (more = better, capped at 20)
--   - Completion (2x multiplier)
--   - Achievements (bonus points)
-- -----------------------------------------------------------------------------

-- YOUR SOLUTION:



-- -----------------------------------------------------------------------------
-- Bonus 2: User Segmentation by Behavior
-- Segment users into categories based on their behavior patterns:
--   - WHALE: Top 1% by spending
--   - POWER_USER: Top 10% by sessions (excluding whales)
--   - ENGAGED: Completed 50%+ sessions
--   - CASUAL: Everyone else active in last 30 days
--   - INACTIVE: No activity in 30+ days
-- -----------------------------------------------------------------------------

-- YOUR SOLUTION:

