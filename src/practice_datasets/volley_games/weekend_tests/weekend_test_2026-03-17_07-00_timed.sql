-- =============================================================================
-- WEEKEND TECHNICAL EXERCISE - TIMED (70 MINUTES)
-- Date: 2026-03-17   Time: 07:00
-- Database: PostgreSQL   Schema: volley_games (users, games, sessions, events, purchases)
-- Target: Complete in 60 min; 70 min hard stop.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- QUESTION 1
-- -----------------------------------------------------------------------------
-- Which country has the most users? Return one row with: country and the count
-- of users in that country. If there is a tie, return any one of the top countries.

-- Your SQL:




-- -----------------------------------------------------------------------------
-- QUESTION 2
-- -----------------------------------------------------------------------------
-- Finance needs revenue by country. For each country, return: country name,
-- number of purchases, and total revenue (sum of amount_usd). Include only
-- countries that have at least one purchase. Order by total revenue descending.

-- Your SQL:




-- -----------------------------------------------------------------------------
-- QUESTION 3
-- -----------------------------------------------------------------------------
-- For each game, compute completion metrics. Return: game_name, difficulty,
-- total_sessions (count), completed_sessions (count where completed = 1),
-- and completion_rate_pct (percentage of sessions that are completed, rounded
-- to 2 decimals). Guard against division by zero. Order by completion_rate_pct
-- descending.

-- Your SQL:




-- -----------------------------------------------------------------------------
-- QUESTION 4
-- -----------------------------------------------------------------------------
-- For user retention by signup week, define each user's cohort as the week
-- (Monday start) of their first session. For each cohort week, return:
-- cohort_week, cohort_size (distinct users), and three retention percentages
-- rounded to 2 decimals: d1_retention_pct (users who had a session exactly 1
-- day after first session), d7_retention_pct (users active again within 1–7
-- days after first session), d30_retention_pct (users active again within
-- 1–30 days after first session). Order by cohort_week.

-- Your SQL:




-- -----------------------------------------------------------------------------
-- QUESTION 5
-- -----------------------------------------------------------------------------
-- Conversion funnel: signup → first session → first completed session →
-- first purchase. For the entire user base, return a single row with:
-- total_signups, played_first_session (count), signup_to_session_pct,
-- completed_first_session (count), session_to_completion_pct, made_purchase
-- (count), completion_to_purchase_pct. All percentages rounded to 2 decimals;
-- use the denominator of the previous stage and guard against division by zero.
-- Users with no session have null first session; same for completion and purchase.

-- Your SQL:




-- -----------------------------------------------------------------------------
-- QUESTION 6
-- -----------------------------------------------------------------------------
-- In a pipeline that loads events into a warehouse table that has no primary
-- key, how would you handle duplicate events (same event ingested more than
-- once)? Mention at least one approach (e.g. deduplication key, merge strategy,
-- or idempotent writes). Write your answer in a comment below.

-- Your answer:


