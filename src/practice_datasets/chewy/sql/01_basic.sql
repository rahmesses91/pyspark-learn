select * from chewy.users u limit 10;

-- =============================================================================
-- PRODUCTS / EVENTS / ORDERS - BASIC SQL PROBLEMS
-- Single-table or simple two-table joins, filters, and aggregations
-- =============================================================================
-- Tables: users (user_id, signup_date, country, region)
--         products (product_id, category, price)
--         events (user_id, event_time, event_type, product_id, session_id)
--         orders (order_id, user_id, order_time, product_id, quantity)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. List all products in a given category (e.g. 'Pet Food') with price above 20.
--    Return: product_id, category, price
-- -----------------------------------------------------------------------------

select 
	category,
	product_name,
	price
from chewy.products
where price > 20
order by category, price desc;



-- -----------------------------------------------------------------------------
-- 2. How many orders does each user have? Return user_id and order_count,
--    ordered by order_count descending.
-- -----------------------------------------------------------------------------

select 
user_id,
count(order_id) as order_count
from chewy.orders o
group by o.user_id 
order by order_count desc;

-- -----------------------------------------------------------------------------
-- 3. What is the total revenue (sum of quantity * price per order)?
--    Join orders to products. Return a single number.
-- -----------------------------------------------------------------------------

with orders_with_price as (
select 
	o.order_id,
	o.product_id,
	o.quantity * p.price as total_price
from chewy.orders o
left join chewy.products p
on o.product_id = p.product_id
)
select round(sum(total_price)::numeric, 2) from orders_with_price;
-- -----------------------------------------------------------------------------
-- 4. List all users who signed up in 2024. Return user_id, signup_date, country.
-- -----------------------------------------------------------------------------
--SELECT date_part('year', '2024-05-01'::date);
with users_signups_with_year as (
select 
	user_id,
	signup_date,
	country,
	extract(year from signup_date::date) as signup_year
from chewy.users
)
select 	user_id,
	signup_date,
	country
from users_signups_with_year where signup_year = '2024';

SELECT 
    user_id,
    signup_date,
    country
FROM chewy.users
WHERE signup_date >= '2024-01-01' 
  AND signup_date <  '2025-01-01';



-- -----------------------------------------------------------------------------
-- 5. Count events by event_type. Return event_type and event_count,
--    ordered by event_count descending.
-- -----------------------------------------------------------------------------

select
	event_type,
	count(*) as event_count
from chewy.events
group by event_type
order by event_count desc;

-- -----------------------------------------------------------------------------
-- 6. Top 5 products by number of orders (order count). Return product_id and order_count.
-- -----------------------------------------------------------------------------

select 
	product_id,
	count(order_id) as order_count
from chewy.orders
group by chewy.orders.product_id
order by order_count desc 
limit 5;

-- -----------------------------------------------------------------------------
-- 7. How many orders were placed in each month of 2025?
--    Return year-month (e.g. 2025-01) and order_count.
-- -----------------------------------------------------------------------------

with orders_in_2025 as (
select
	order_id,
	to_char(order_time::date, 'YYYY-MM') as order_year_month
from chewy.orders 
where order_time between '2025-01-01' and '2025-12-31'
)
select
	order_year_month,
	count(order_id) as order_count
from orders_in_2025
group by order_year_month
order by order_year_month;
-- -----------------------------------------------------------------------------
-- 8. List products with price between 10 and 50 (inclusive). Return product_id, category, price.
-- -----------------------------------------------------------------------------

select
	product_id,
	category,
	price
from chewy.products
where price between 10 and 50
order by category, price;

-- -----------------------------------------------------------------------------
-- 9. How many distinct users have placed at least one order? Return a single count.
-- -----------------------------------------------------------------------------
--with users_order_count as (
--select 
--	user_id,
--	count(order_id) as order
--from chewy.orders
--group by user_id 
--)
--select 

select count(distinct user_id) from chewy.orders;

-- -----------------------------------------------------------------------------
-- 10. For each category, what is the average product price?
--     Return category and avg_price, ordered by avg_price descending.
-- -----------------------------------------------------------------------------

select 
	category,
	round(avg(price)::numeric, 2) as avg_price
from chewy.products
group by category 
order by avg_price desc;