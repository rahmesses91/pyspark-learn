-- =============================================================================
-- DAILY USER RETENTION - PRACTICE QUESTIONS
-- Database: PostgreSQL   Schema: volley_games (users, games, sessions, events, purchases)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- QUESTION 1
-- -----------------------------------------------------------------------------
-- Cohort retention by week: Define each user's cohort as the week (Monday start)
-- of their first session. For each cohort week, return: cohort_week (as a date,
-- the Monday of that week), cohort_size (distinct users in that cohort), and
-- three retention percentages rounded to 2 decimals: d1_retention_pct (users
-- who had a session exactly 1 day after their first session), d7_retention_pct
-- (users active again within 1–7 days after first session), d30_retention_pct
-- (users active again within 1–30 days after first session). Guard against
-- division by zero. Order by cohort_week.

-- Your SQL:




-- -----------------------------------------------------------------------------
-- QUESTION 2
-- -----------------------------------------------------------------------------
-- Daily retention: For each calendar day that has at least one session, return:
-- activity_date, total_users_active (distinct users with a session that day),
-- d1_retention_pct (of users whose first session was yesterday, what % were
-- active today?), d7_retention_pct (of users whose first session was 1–7 days
-- ago, what % were active today?), d30_retention_pct (of users whose first
-- session was 1–30 days ago, what % were active today?). All percentages
-- rounded to 2 decimals. Guard against division by zero. Order by activity_date.

-- Your SQL:




-- -----------------------------------------------------------------------------
-- QUESTION 3
-- -----------------------------------------------------------------------------
-- New vs returning user split: For each calendar day that has at least one
-- session, return: activity_date, new_users (count of distinct users whose
-- first-ever session was on that day), returning_users (count of distinct
-- users who had a session that day but had at least one session before that
-- day), total_dau (new_users + returning_users), new_user_pct (percentage of
-- that day's DAU that were new, rounded to 2 decimals), returning_user_pct
-- (percentage that were returning). Guard against division by zero. Order by
-- activity_date.

-- Your SQL:



