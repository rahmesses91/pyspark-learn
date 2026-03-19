-- =============================================================================
-- WEEKEND TECHNICAL EXERCISE - WARM-UP (NOT TIMED)
-- Date: 2026-03-16   Time: 21:00
-- Database: PostgreSQL   Schema: volley_games (users, games, sessions, events, purchases)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- QUESTION 1
-- -----------------------------------------------------------------------------
-- The analytics team needs the total number of registered users on the platform.
-- Write a query that returns a single number: the count of all users in the
-- users table. No grouping or filters required.

-- Your SQL:




-- -----------------------------------------------------------------------------
-- QUESTION 2
-- -----------------------------------------------------------------------------
-- Growth wants to know in which calendar month the most users signed up.
-- Write a query that returns exactly one row with: the signup month (as a
-- date or year-month string) and the count of users who signed up in that month.
-- If multiple months tie, return any one of them.

-- Your SQL:




-- -----------------------------------------------------------------------------
-- QUESTION 3
-- -----------------------------------------------------------------------------
-- Product needs a report of daily active users (DAU). For each calendar day
-- that appears in the sessions data, output the activity date and the count of
-- distinct users who had at least one session on that day. Include every day
-- that has at least one session. Order the result by activity date ascending.

-- Your SQL:




-- -----------------------------------------------------------------------------
-- QUESTION 4
-- -----------------------------------------------------------------------------
-- We want average session length by game and device type. Consider only sessions
-- where both started_at and ended_at are non-null. For each combination of
-- game name and device type, return: game_name, device_type, number of
-- sessions, and average session length in minutes (rounded to 2 decimals).
-- Order by game_name then device_type.

-- Your SQL:




-- -----------------------------------------------------------------------------
-- QUESTION 5
-- -----------------------------------------------------------------------------
-- For a day-over-day growth report, compute for each day: the date, that day's
-- DAU (distinct users with a session), the previous day's DAU, and the
-- percentage change in DAU from the previous day (rounded to 2 decimals).
-- Handle division by zero (e.g.
-- first day or zero previous DAU) so the percentage change is null or safe.
-- Order by date ascending.

-- Your SQL:




-- -----------------------------------------------------------------------------
-- QUESTION 6
-- -----------------------------------------------------------------------------
-- We need to flag users by churn risk based on their last session. Use the
-- maximum session date in the data as "today". For each user who has at least
-- one session, compute: user_id, username, is_premium, last_active_date,
-- days_since_active, and churn_status. churn_status must be exactly one of:
-- ACTIVE (last 7 days), AT_RISK (8–14 days), DORMANT (15–30 days),
-- CHURNED (more than 30 days). Order by days_since_active descending.

-- Your SQL:




-- -----------------------------------------------------------------------------
-- QUESTION 7
-- -----------------------------------------------------------------------------
-- In a warehouse like Snowflake, event tables are often append-only and may
-- not have a primary key, so duplicate events can appear. Briefly describe one
-- or two practical ways you would remove or identify duplicates in such a
-- table (e.g. by columns that together should be unique, or by row number).
-- Write your answer in a comment below.

-- Your answer:


