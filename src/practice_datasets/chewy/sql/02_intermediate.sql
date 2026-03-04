-- =============================================================================
-- PRODUCTS / EVENTS / ORDERS - INTERMEDIATE SQL PROBLEMS
-- Two or three table joins, GROUP BY, conditional logic, simple subqueries
-- =============================================================================
-- Tables: users (user_id, signup_date, country, region)
--         products (product_id, category, price)
--         events (user_id, event_time, event_type, product_id, session_id)
--         orders (order_id, user_id, order_time, product_id, quantity)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Revenue by product category.
--    Return category and total_revenue, ordered by total_revenue descending.
-- -----------------------------------------------------------------------------

select
	p.category,
	ROUND(SUM(o.quantity * p.price)::numeric, 2) as total_revenue
from chewy.orders o
inner join chewy.products p 
on o.product_id = p.product_id 
group by p.category
order by total_revenue DESC;

-- Edge cases:
--   • Dupes: If orders had duplicate rows for same (order_id, product_id), revenue would be
--     double-counted — dedupe or use a grain (e.g. SUM over DISTINCT order line keys) if needed.
--   • NULL product_id in orders: inner join drops those rows; use LEFT JOIN + COALESCE category
--     if you need to include "unknown" category revenue.
-- Optimization: Single join + aggregation; already efficient. Index on orders.product_id helps.

-- -----------------------------------------------------------------------------
-- 2. Average order value (revenue per order) by user. Return user_id and avg_order_value.
--    Consider only users with at least one order. Order by avg_order_value descending.
-- -----------------------------------------------------------------------------
WITH revenue_per_order AS (
	SELECT
		o.user_id,
		o.order_id,
		SUM(o.quantity * p.price) AS total_per_order
	FROM chewy.orders o
	INNER JOIN chewy.products p
		ON o.product_id = p.product_id
	GROUP BY o.user_id, o.order_id
)
SELECT
	user_id,
	ROUND(AVG(total_per_order)::numeric, 2) AS avg_order_value
FROM revenue_per_order
GROUP BY user_id
ORDER BY avg_order_value DESC;

-- Edge cases:
--   • Dupes: Grouping by (user_id, order_id) first ensures one order = one total; if the same
--     order line appeared twice in orders, we'd overstate revenue per order — treat as data quality
--     or dedupe before summing.
--   • Users with a single order: AVG of one value is correct; no miscalculation.
-- Optimization: CTE is clear and one logical pass; alternative with window (SUM per order) then
-- outer GROUP BY has similar cost. No need to change.

-- -----------------------------------------------------------------------------
-- 3. First order date per user. Return user_id and first_order_date.

-- -----------------------------------------------------------------------------


select
	user_id,
	min(order_time::date) as first_order_date
from chewy.orders
group by user_id;

-- Edge cases:
--   • Dupes: One row per user from GROUP BY; no duplicate user_id. If order_time is NULL,
--     MIN returns NULL — use COALESCE or WHERE order_time IS NOT NULL if you need a valid date.
--   • Users with no orders: won't appear (we only select from orders); use RIGHT JOIN from users
--     if you need "first_order_date = NULL" for non-buyers.
-- Optimization: Single table, GROUP BY; index on (user_id, order_time) helps. No change needed.

-- -----------------------------------------------------------------------------
-- 4. For each product, count how many times it was viewed vs added to cart vs purchased
--    in the events table. Return product_id, view_count, add_to_cart_count, purchase_count.
-- -----------------------------------------------------------------------------

select
	product_id,
	SUM( case when event_type = 'view' then 1 else 0 end ) as view_count,
	SUM( case when event_type = 'add_to_cart' then 1 else 0 end ) as add_to_cart_count,
	SUM( case when event_type = 'purchase' then 1 else 0 end ) as purchase_count
from chewy.events
group by product_id;

-- Edge cases:
--   • Dupes: Each event row counted once; if the same event is logged twice (duplicate rows),
--     we overcount — use an event_id and COUNT(DISTINCT event_id) per type, or dedupe by
--     (user_id, event_time, product_id, session_id) if that's the natural key.
--   • Products with no events: won't appear (we group by product_id from events); LEFT JOIN
--     from products and COALESCE(count, 0) if you need all products with zero counts.
-- Optimization: Single scan; Postgres FILTER (e.g. COUNT(*) FILTER (WHERE event_type = 'view'))
-- is slightly cleaner but same performance. Fine as-is.

-- -----------------------------------------------------------------------------
-- 5. Top 3 products by revenue within each category. Return category, product_id,
-- -----------------------------------------------------------------------------

-- Optimized: compute total_revenue once in first CTE, then rank by that column (no repeated SUM).
WITH product_revenue AS (
	SELECT
		p.category,
		o.product_id,
		ROUND(SUM(o.quantity * p.price)::numeric, 2) AS total_revenue
	FROM chewy.orders o
	INNER JOIN chewy.products p ON o.product_id = p.product_id
	GROUP BY p.category, o.product_id
),
ranked AS (
	SELECT
		category,
		product_id,
		total_revenue,
		DENSE_RANK() OVER (PARTITION BY category ORDER BY total_revenue DESC) AS rank_by_revenue
	FROM product_revenue
)
SELECT category, product_id, total_revenue
FROM ranked
WHERE rank_by_revenue <= 3
ORDER BY category, total_revenue DESC;

-- Edge cases:
--   • Dupes: Revenue is per (category, product_id) so no double-count. Ties: DENSE_RANK
--     keeps all ties in top 3; ROW_NUMBER would arbitrarily drop ties, RANK can leave gaps.
--   • Products in category with zero revenue (never ordered): don't appear; "top 3 by revenue"
--     typically means only products with orders. Include them with LEFT JOIN orders if needed.
-- Optimization: total_revenue computed once; window uses the column instead of repeating ROUND(SUM(...)).

-- -----------------------------------------------------------------------------
-- 6. How many distinct sessions does each user have? Return user_id and session_count,
--    ordered by session_count descending.
-- -----------------------------------------------------------------------------

select
	user_id,
	count(distinct session_id) as session_count
from chewy.events
group by user_id
order by session_count DESC;

-- Edge cases:
--   • Dupes: COUNT(DISTINCT session_id) avoids counting the same session multiple times per user.
--   • NULL session_id: COUNT(DISTINCT NULL) does not increment, so users with only NULL
--     sessions get session_count = 0; filter with WHERE session_id IS NOT NULL if you want to
--     exclude those users or treat NULLs differently.
-- Optimization: Single GROUP BY; index on (user_id, session_id) helps. No change needed.

-- -----------------------------------------------------------------------------
-- 7. List orders with product category and user country.
--    Return order_id, user_id, order_time, category, country, quantity, and unit price.
-- -----------------------------------------------------------------------------

select
	o.order_id,
	o.user_id,
	o.order_time,
	p.category,
	u.country,
	o.quantity,
	p.price 
from chewy.orders o
inner join chewy.users u USING(user_id)
inner join chewy.products p using(product_id);

-- Edge cases:
--   • Dupes: One row per order line (order_id + product_id). If the spec required one row per
--     order_id and an order can have multiple lines, you'd get duplicate order_id — then
--     aggregate (e.g. MAX category, SUM quantity) or pick one line per order.
--   • Missing user or product: INNER JOIN drops orders with invalid user_id/product_id; use
--     LEFT JOIN and COALESCE(category, country, etc.) if you must show all orders.
-- Optimization: Two joins, no aggregation; already efficient. USING is fine for key-based joins.

-- -----------------------------------------------------------------------------
-- 8. Users who have placed an order but have no 'purchase' event in the events table
--    (i.e. they ordered but we have no matching purchase event). Return user_id.
-- -----------------------------------------------------------------------------

select distinct
	o.user_id
from chewy.orders o
where not exists 
	(
	select 1
	from chewy.events e
	where o.user_id = e.user_id 
	and e.event_type = 'purchase'
	);

-- Edge cases:
--   • Dupes: Without DISTINCT, a user with multiple orders (all without a purchase event) would
--     appear once per order; use SELECT DISTINCT o.user_id so each user is returned once.
--   • "No purchase event": We check for any purchase by that user (any product); if the spec
--     required "no purchase event for the same product they ordered", add AND e.product_id = o.product_id
--     in the NOT EXISTS subquery.
-- Optimization: NOT EXISTS is appropriate and typically better than LEFT JOIN ... IS NULL here.
-- No need to change.

-- -----------------------------------------------------------------------------
-- 9. For each country, return total number of orders and total revenue.
--    Return country, order_count, total_revenue. Include only countries with at least 1 order.
-- -----------------------------------------------------------------------------

select
	u.country,
	count(DISTINCT o.order_id) as order_count,
	ROUND(SUM(o.quantity * p.price)::numeric, 2) as total_revenue
from chewy.orders o
inner join chewy.users u on o.user_id = u.user_id
inner join chewy.products p on o.product_id = p.product_id
group by u.country
order by total_revenue DESC;

-- Edge cases:
--   • Dupes: Each row in the join is an order line; COUNT(o.order_id) would count lines, not
--     orders — use COUNT(DISTINCT o.order_id) so "total number of orders" is correct. Revenue
--     is correct as SUM(quantity * price) over lines.
--   • Same user in multiple countries: schema has one country per user; if user could change
--     country, clarify whether to attribute order to user's current country or at order time.
-- Optimization: Two joins then GROUP BY; could pre-aggregate revenue per order and join to
-- users then group by country, but current form is clear. Minor; no change needed.

-- -----------------------------------------------------------------------------
-- 10. Products that have never been ordered. Return product_id and category.
-- -----------------------------------------------------------------------------

select
	product_id,
	category
from chewy.products p 
where not exists (
	select 1
	from chewy.orders o 
	where p.product_id = o.product_id 
);

-- Edge cases:
--   • Dupes: One row per product from products; NOT EXISTS returns at most one row per product.
--     No duplicate product_id in output.
--   • Products with NULL category: they still appear; filter with WHERE p.category IS NOT NULL
--     if you want to exclude them.
--   • Left join alternative: SELECT p.product_id, p.category FROM products p LEFT JOIN orders o
--     ON p.product_id = o.product_id WHERE o.product_id IS NULL; same result, NOT EXISTS often
--     preferred for readability and plan.
-- Optimization: NOT EXISTS is efficient (can short-circuit). No need to change.

