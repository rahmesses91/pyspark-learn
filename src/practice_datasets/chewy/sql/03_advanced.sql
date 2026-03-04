-- =============================================================================
-- PRODUCTS / EVENTS / ORDERS - ADVANCED SQL PROBLEMS
-- Window functions (ROW_NUMBER, LAG/LEAD, RANK), deduping, complex aggregations
-- =============================================================================
-- Tables: users (user_id, signup_date, country, region)
--         products (product_id, category, price)
--         events (user_id, event_time, event_type, product_id, session_id)
--         orders (order_id, user_id, order_time, product_id, quantity)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Dedupe events to one row per (user_id, session_id): keep the latest event
--    per session. Return user_id, session_id, event_time, event_type, product_id.
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- 2. For each user, compute the number of days between consecutive orders.
--    Return user_id, order_id, order_time, previous_order_time, and
--    days_since_previous_order (NULL for a user's first order).
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- 3. Running total of revenue over time. Return date (or order_time), daily_revenue,
--    and running_total_revenue.
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- 4. Users whose second order was placed within 30 days of their first order.
--    Return user_id, first_order_date, second_order_date, days_between.
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- 5. Products with revenue above the average revenue of their category.
--    Return product_id, category, product_revenue, category_avg_revenue.
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- 6. Rank products by total revenue within each category.
--    Return category, product_id, total_revenue, revenue_rank (1 = highest in category).
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- 7. One row per user with their first order: product_id, category, order_time, and quantity.
--    Return user_id and the first order's product_id, category, order_time, quantity.
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- 8. Conversion funnel per session: count how many sessions have at least one 'view',
--    at least one 'add_to_cart', and at least one 'purchase'. Return three numbers
--    (or one row): sessions_with_view, sessions_with_add_to_cart, sessions_with_purchase.
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- 9. For each user, the product they ordered most frequently (mode). If tie, pick one.
--    Return user_id, most_ordered_product_id, order_count for that product.
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- 10. Monthly cohort retention: for each signup month (users.signup_date), how many
--     users placed at least one order in the same month vs the next month vs two months later?
--     Return signup_month, orders_in_month_0, orders_in_month_1, orders_in_month_2
--     (month_0 = signup month, month_1 = next month, etc.).
-- -----------------------------------------------------------------------------
