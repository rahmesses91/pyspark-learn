-- =============================================================================
-- PostgreSQL: Add product_name to existing products table (already loaded)
-- Run this after you have loaded the Chewy data without product_name.
-- =============================================================================
-- 1. Add the column (safe to run multiple times with IF NOT EXISTS in PG 9.5+)
-- 2. Load product_id + product_name from CSV into a temp table
-- 3. Backfill products.product_name from the temp table
--
-- Replace your_schema with your actual schema (e.g. public) if needed.
-- Use the absolute path to products_product_names.csv on your machine.
-- =============================================================================

-- Step 1: Add column
ALTER TABLE products
ADD COLUMN IF NOT EXISTS product_name VARCHAR(255);

-- Step 2: Load names from CSV (choose one method)
-- Option A: From psql, run this with your path (client-side \copy):
--   \copy product_names(product_id, product_name) FROM '/full/path/to/chewy/products_product_names.csv' WITH (FORMAT csv, HEADER true);

-- Option B: From server (if CSV is on the DB server), use COPY:
--   COPY product_names(product_id, product_name) FROM '/full/path/to/products_product_names.csv' WITH (FORMAT csv, HEADER true);

-- Create temp table for the CSV load (run before \copy or COPY):
CREATE TEMP TABLE product_names (
    product_id   INT,
    product_name VARCHAR(255)
);

-- After loading into product_names (via \copy or COPY), run Step 3:

-- Step 3: Backfill
UPDATE products p
SET product_name = n.product_name
FROM product_names n
WHERE p.product_id = n.product_id;

-- Optional: verify
-- SELECT product_id, product_name, category, price FROM products LIMIT 5;
