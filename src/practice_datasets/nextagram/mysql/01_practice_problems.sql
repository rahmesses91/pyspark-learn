-- =============================================================================
-- NEXTAGRAM - SQL PRACTICE PROBLEMS
-- Photo-sharing app analytics for interview preparation
-- MySQL 8.0+
-- =============================================================================

USE nextagram;

-- =============================================================================
-- REFERENCE: DATA MODEL
-- =============================================================================
-- 
-- users          view_event
-- +------------+ +------------+
-- | id         |<----| user_id    |    | id         |
-- | name       | |   | photo_id   |--->| user_id    |
-- | join_ts    | |   | ts         |    | url        |
-- +------------+ |   +------------+    | upload_ts  |
--                |                     +------------+
-- followers      |                           ^
-- +------------+ |                           |
-- | id         | |                           |
-- | user_id    |-+                           |
-- | following_id|----------------------------+
-- | follow_ts  |
-- +------------+
--
-- users.id <-- followers.user_id (the person who follows)
-- users.id <-- followers.following_id (the person being followed)
-- users.id <-- photos.user_id
-- users.id <-- view_event.user_id
-- photos.id <-- view_event.photo_id
-- =============================================================================


-- =============================================================================
-- PART I: BASIC DATA EXPLORATION
-- Let's get to know the data a bit
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Q1: How many users are there?
-- -----------------------------------------------------------------------------

-- YOUR SOLUTION:



-- -----------------------------------------------------------------------------
-- Q2: In which month did the most users join?
-- Return month name or month number and count
-- -----------------------------------------------------------------------------

-- YOUR SOLUTION:



-- -----------------------------------------------------------------------------
-- Q3: What is the name of the user with the most followers?
-- A follower is someone who follows another user
-- (the user in following_id column is being followed by user_id)
-- -----------------------------------------------------------------------------

-- YOUR SOLUTION:



-- =============================================================================
-- PART II: KPI DASHBOARD DESIGN
-- =============================================================================
-- 
-- Now let's plan a KPI dashboard. All of these will be reported on a daily 
-- basis. Even though the example tables are tiny, let's imagine that we are 
-- planning for a huge dataset and we want the dashboard to be fast.
--
-- Our KPI's will be:
--   * new users
--       - change over seven days ago
--   * DAU (Daily Active Users)
--       - change over seven days ago
--   * new photos
--       - new photos per DAU
--       - change over seven days ago
--   * followers
--       - % users with 0 followers
--       - % users with 1-2 followers
--       - % users with 3+ followers
--
-- -----------------------------------------------------------------------------
-- Q4: Design the table(s) that power the dashboard
--
-- Requirements:
-- - All metrics reported daily
-- - Dashboard should be fast (consider pre-aggregation)
-- - Support for 7-day comparison
-- - Think about what columns/metrics to pre-compute
--
-- Consider:
-- - Should this be one table or multiple?
-- - What granularity of data should be stored?
-- - How would you handle the follower distribution metrics?
-- - What indexes would be useful?
--
-- Write the CREATE TABLE statement(s) for your dashboard table(s).
-- -----------------------------------------------------------------------------

-- YOUR SOLUTION:



-- =============================================================================
-- PART III: DAILY DASHBOARD POPULATION QUERIES
-- =============================================================================
--
-- Write queries to populate the dashboard table(s) on a daily basis.
-- Assume these queries run at the end of each day.
-- Use a parameter @report_date or specify a sample date like '2024-03-15'
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Q5: Query to calculate daily new users and 7-day change
-- -----------------------------------------------------------------------------

-- YOUR SOLUTION:



-- -----------------------------------------------------------------------------
-- Q6: Query to calculate DAU (Daily Active Users) and 7-day change
-- DAU = users who either viewed a photo or uploaded a photo that day
-- -----------------------------------------------------------------------------

-- YOUR SOLUTION:



-- -----------------------------------------------------------------------------
-- Q7: Query to calculate new photos, photos per DAU, and 7-day changes
-- -----------------------------------------------------------------------------

-- YOUR SOLUTION:



-- -----------------------------------------------------------------------------
-- Q8: Query to calculate follower distribution metrics
-- Calculate: % with 0 followers, % with 1-2 followers, % with 3+ followers
-- -----------------------------------------------------------------------------

-- YOUR SOLUTION:



-- -----------------------------------------------------------------------------
-- Q9: Combined INSERT statement to populate the dashboard table
-- Write a single query that calculates all metrics for a given day
-- and inserts them into your dashboard table
-- -----------------------------------------------------------------------------

-- YOUR SOLUTION:



-- =============================================================================
-- BONUS PROBLEMS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Bonus 1: User Engagement Score
-- Create a query that scores users based on:
--   - Number of photos uploaded (weight: 3)
--   - Number of followers (weight: 2)
--   - Number of photos viewed (weight: 1)
-- Return top 20 most engaged users
-- -----------------------------------------------------------------------------

-- YOUR SOLUTION:



-- -----------------------------------------------------------------------------
-- Bonus 2: Viral Photos
-- Find photos that have been viewed by at least 5% of all users
-- Include: photo_id, uploader name, view count, % of users who viewed
-- -----------------------------------------------------------------------------

-- YOUR SOLUTION:



-- -----------------------------------------------------------------------------
-- Bonus 3: Follow Network Analysis
-- For each user, calculate:
--   - followers_count (how many follow them)
--   - following_count (how many they follow)
--   - ratio (followers / following, handle division by zero)
-- Identify "influencers" (ratio > 2) and "fans" (ratio < 0.5)
-- -----------------------------------------------------------------------------

-- YOUR SOLUTION:


