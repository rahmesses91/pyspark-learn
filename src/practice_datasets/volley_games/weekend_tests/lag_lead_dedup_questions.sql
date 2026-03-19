-- =============================================================================
-- LAG, LEAD & DEDUPLICATION - PRACTICE QUESTIONS
-- Database: PostgreSQL   Schema: volley_games (users, games, sessions, events, purchases)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- QUESTION 1
-- -----------------------------------------------------------------------------
-- For each calendar day that has at least one session, compute: activity_date,
-- dau (distinct users with a session that day), prev_day_dau (the previous
-- calendar day's DAU), and dau_change_pct (percentage change from previous
-- day, rounded to 2 decimals). Use a window function to obtain the previous
-- day's DAU. Handle division by zero so the first day or zero previous DAU
-- returns null for the percentage. Order by activity_date.

-- Your SQL:




-- -----------------------------------------------------------------------------
-- QUESTION 2
-- -----------------------------------------------------------------------------
-- For each user, list their sessions in chronological order. Return: user_id,
-- session_id, started_at, game_id, and days_since_prev_session (number of days
-- between this session and the user's previous session; null for each user's
-- first session). Order by user_id, started_at.

-- Your SQL:




-- -----------------------------------------------------------------------------
-- QUESTION 3
-- -----------------------------------------------------------------------------
-- For each purchase, return: user_id, purchase_id, purchased_at, amount_usd,
-- and next_purchase_date (the date of that user's next purchase, if any; null
-- if it was their last purchase). Use a window function. Order by user_id,
-- purchased_at.

-- Your SQL:




-- -----------------------------------------------------------------------------
-- QUESTION 4
-- -----------------------------------------------------------------------------
-- The events table has no primary key and may contain duplicate rows when the
-- same event is ingested more than once. Assume duplicates share the same
-- session_id, event_type, user_id, and created_at (to the second). Write a
-- query that returns only one row per unique (session_id, event_type, user_id,
-- created_at truncated to second). Use a window function to identify and remove
-- duplicates, keeping the first occurrence. Return event_id, session_id,
-- user_id, event_type, created_at. Order by session_id, created_at.

-- Your SQL:




-- -----------------------------------------------------------------------------
-- QUESTION 5
-- -----------------------------------------------------------------------------
-- Using the same deduplication logic as Question 4 (one row per unique
-- session_id, event_type, user_id, created_at truncated to second), return a
-- summary: session_id, total_unique_events (count after deduplication), and
-- duplicate_count (how many duplicate rows were removed for that session, i.e.
-- original row count minus unique count). Include only sessions that had at
-- least one duplicate. Order by duplicate_count descending.

-- Your SQL:



