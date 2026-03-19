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

select count(distinct user_id) as  user_count 
from users u; 


-- -----------------------------------------------------------------------------
-- QUESTION 2
-- -----------------------------------------------------------------------------
-- Growth wants to know in which calendar month the most users signed up.
-- Write a query that returns exactly one row with: the signup month (as a
-- date or year-month string) and the count of users who signed up in that month.
-- If multiple months tie, return any one of them.

-- Your SQL:

with user_signup as (
  select
    to_char(created_at::date, 'YYYY-MM') as year_month,
    count(user_id) as user_count
  from users
  group by 1
)
select DISTINCT ON (user_count) -- Key: Must be first
    year_month, 
    user_count
from user_signup
order by user_count, random();



-- -----------------------------------------------------------------------------
-- QUESTION 3
-- -----------------------------------------------------------------------------
-- Product needs a report of daily active users (DAU). For each calendar day
-- that appears in the sessions data, output the activity date and the count of
-- distinct users who had at least one session on that day. Include every day
-- that has at least one session. Order the result by activity date ascending.

-- Your SQL:

-- Follow-up question: Is a session will be called a valid session if it was started and ended on the same date?

select
	date(started_at) as activity_date,
	count(distinct user_id) as DAU
from
	sessions s
group by 1
order by activity_date;


-- -----------------------------------------------------------------------------
-- QUESTION 4
-- -----------------------------------------------------------------------------
-- We want average session length by game and device type. Consider only sessions
-- where both started_at and ended_at are non-null. For each combination of
-- game name and device type, return: game_name, device_type, number of
-- sessions, and average session length in minutes (rounded to 2 decimals).
-- Order by game_name then device_type.

-- Your SQL:


with session_games as (

select
	s.session_id,
	g.game_name,
	s.device_type,
	extract(EPOCH FROM (s.ended_at::timestamp - s.started_at::timestamp)) / 60 as session_duration_minutes

from sessions s
inner join games g on g.game_id = s.game_id
where s.ended_at > s.started_at and s.started_at is not null and s.ended_at is not null
)
select
	game_name,
	device_type,
	count(session_id) as number_of_sessions,
	round(avg(session_duration_minutes), 2) as average_session_length
from session_games
group by 1,2
order by 1,2;



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

with date_spine as (
	select generate_series(min(started_at::date), max(started_at::date), '1 DAY'::interval)::date as activity_date
	from sessions s
),

--select * from date_spine limit 10;
daily_active_users as (

select
	date(started_at) as activity_date,
	count(distinct user_id) as DAU
from
	sessions s
group by 1
	
),

dau_calendar as (

select
	ds.activity_date as activity_date,
	coalesce(dau.dau, 0) as DAU
from date_spine ds
left join daily_active_users dau
on ds.activity_date = dau.activity_date
--group by ds.activity_date
),

previous_date_dau as (
select activity_date,
		dau as current_dau,
		lag(dau, 1) over() as previous_dau,
		--round((dau::numeric / nullif(lag(dau, 1) over(),0) ) * 100, 2) 
		coalesce (round(((dau::numeric / nullif(lag(dau, 1) over(order by activity_date), 0)) - 1) * 100, 2), 0) as percentage_change
from dau_calendar

)

select 
	activity_date,
	current_dau,
	percentage_change
from previous_date_dau
order by activity_date;


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

with users_max_sessions as (

select
	s.user_id
	u.username,
	u.is_premium,
	u.last_active::date as last_active_date,
	current_date() - u.last_active_date::date as days_since_active
from sessions s 
inner join users u
on s.user_id = u.user_id
where s.started_at is not null and s.ended_at is not null and s.ended_at > s.started_at
),

select 
	user_id
	username,
	is_premium,
	last_active_date,
	days_since_active,
	case when days_since_active <= 7 then 'ACTIVE'
		 when days_since_active BETWEEN 8 and 14 then 'AT_RISK'
		 when days_since_active BETWEEN 15 and 30 then 'DORMANT'
		 when days_since_active > 30 then 'CHURNED'
from users_max_sessions limit 20;

-- -----------------------------------------------------------------------------
-- QUESTION 7
-- -----------------------------------------------------------------------------
-- In a warehouse like Snowflake, event tables are often append-only and may
-- not have a primary key, so duplicate events can appear. Briefly describe one
-- or two practical ways you would remove or identify duplicates in such a
-- table (e.g. by columns that together should be unique, or by row number).
-- Write your answer in a comment below.

-- Your answer:

-- 1. Snowflake is a columnar database that uses micro partitons (usually 50-500 MB) 
--to enable partition pruning i.e only selecting data from where the data resides. Selecting date as partitioning key, we can improve partition pruning

--2. To identify a dupe, I can calculate checksum (MD5) on the fields a dupe it by qualify over partition and selecting the latest data
-- The other way to remove dupe is using surrogate key - user_id, session_id ordered by started_at to break ties

-- 


