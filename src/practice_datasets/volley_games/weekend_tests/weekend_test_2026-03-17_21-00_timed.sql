-- =============================================================================
-- WEEKEND TECHNICAL EXERCISE - TIMED (70 MINUTES)
-- Date: 2026-03-17   Time: 21:00
-- Database: PostgreSQL   Schema: volley_games (users, games, sessions, events, purchases)
-- Target: Complete in 60 min; 70 min hard stop.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- QUESTION 1
-- -----------------------------------------------------------------------------
-- What is the most frequently purchased item type? Return one row with:
-- item_type and the count of purchases for that type. If there is a tie,
-- return any one of the top types.

-- Your SQL:




-- -----------------------------------------------------------------------------
-- QUESTION 2
-- -----------------------------------------------------------------------------
-- Rank games by how often they are played. For each game, return: game_name,
-- category, and total_sessions (count of sessions for that game). Include all
-- games; if a game has zero sessions, show 0. Order by total_sessions
-- descending.

-- Your SQL:




-- -----------------------------------------------------------------------------
-- QUESTION 3
-- -----------------------------------------------------------------------------
-- Premium conversion: among users who have played at least one session, what
-- percentage have made at least one purchase? Break this down by user type:
-- is_premium (0 or 1). Return: is_premium, active_users (distinct users with
-- at least one session), users_who_purchased (distinct users with at least one
-- purchase), and conversion_rate_pct (percentage, rounded to 2 decimals).
-- Guard against division by zero. One row per is_premium value.

-- Your SQL:




-- -----------------------------------------------------------------------------
-- QUESTION 4
-- -----------------------------------------------------------------------------
-- Running revenue by game: for each game that has purchases (game_id non-null),
-- show daily revenue and a running total of revenue over time. Return:
-- game_name, purchase_date (date only), daily_revenue (sum of amount_usd for
-- that game on that date), and running_total_revenue (cumulative sum of
-- daily_revenue for that game ordered by date). Order by game_name then
-- purchase_date.

-- Your SQL:




-- -----------------------------------------------------------------------------
-- QUESTION 5
-- -----------------------------------------------------------------------------
-- Lifetime value by signup month. For each calendar month in which at least
-- one user signed up, return: signup_month (e.g. 2024-01), cohort_size
-- (number of users), paying_users (users with at least one purchase),
-- payer_rate_pct (percentage of cohort that paid), total_revenue (sum of
-- all purchases by that cohort), avg_ltv_all_users (average spend per user
-- including non-payers, rounded to 2 decimals), and avg_ltv_payers_only
-- (average spend among users who paid at least once, rounded to 2 decimals).
-- Guard against division by zero for payer_rate and avg_ltv_payers_only.
-- Order by signup_month.

-- Your SQL:




-- -----------------------------------------------------------------------------
-- QUESTION 6
-- -----------------------------------------------------------------------------
-- When building daily metrics (e.g. DAU per day), why might you use a "date
-- spine" (a continuous list of dates)? In what situation would you not need
-- one? Write your answer in a comment below.

-- Your answer:


