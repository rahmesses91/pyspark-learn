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


select 
	country,
	count(user_id) as user_count
from weekend.users u
group by u.country 
order by user_count desc limit 1;


-- -----------------------------------------------------------------------------
-- QUESTION 2
-- -----------------------------------------------------------------------------
-- Finance needs revenue by country. For each country, return: country name,
-- number of purchases, and total revenue (sum of amount_usd). Include only
-- countries that have at least one purchase. Order by total revenue descending.

-- Your SQL:

select
	u.country as country_name,
	count(p.purchase_id) as number_of_purchases,
	round(sum(p.amount_usd)::numeric, 2) as total_revenue
from weekend.purchases p
inner join weekend.users u
on p.user_id = u.user_id
group by country_name
order by total_revenue desc;





-- -----------------------------------------------------------------------------
-- QUESTION 3
-- -----------------------------------------------------------------------------
-- For each game, compute completion metrics. Return: game_name, difficulty,
-- total_sessions (count), completed_sessions (count where completed = 1),
-- and completion_rate_pct (percentage of sessions that are completed, rounded
-- to 2 decimals). Guard against division by zero. Order by completion_rate_pct
-- descending.

-- Your SQL:

select
	g.game_name,
	g.difficulty,
	count(s.session_id) as total_sessions,
	count(s.session_id) FILTER(where s.completed = 1) as total_completed_sessions,
	round((count(s.session_id) FILTER(where s.completed = 1) * 100/ nullif( count(s.session_id), 0)), 2) as completion_rate_pct

from weekend.sessions s
inner join weekend.games g
on s.game_id = g.game_id 
where s.started_at is not null
group by 1,2;

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

with users_cohort_by_sign_up_week as (

select
	count(distinct s.user_id) as cohort_size,
	date_trunc('week', s.started_at::timestamp)::date as signup_week
from weekend.sessions s
group by signup_week
),

user_earliest_session as (

select s.user_id,
		min(s.started_at::date) as first_activity_date
from weekend.sessions s
where s.started_at is not null and s.started_at < s.ended_at
group by s.user_id
),

retention as (

select 
		
		count(distinct uas.user_id) as total_users,
		round( count(distinct day1.user_id) / nullif( count(distinct uas.user_id), 0), 2)  as day1_retention_pct,
		round( count(distinct day7.user_id) / nullif( count(distinct uas.user_id), 0), 2)  as day7_retention_pct,
		round( count(distinct day30.user_id) / nullif( count(distinct uas.user_id), 0), 2)  as day30_retention_pct
	
from user_earliest_session uas
left join weekend.sessions day1
on day1.started_at::date = uas.first_activity_date + interval '1 day'
left join weekend.sessions day7
on day1.started_at::date between uas.first_activity_date + interval '1 day' and uas.first_activity_date + interval '7 days'
left join weekend.sessions day30
on day1.started_at::date between uas.first_activity_date + interval '8 day' and uas.first_activity_date + interval '30 days'
 
)
select * from retention;



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


