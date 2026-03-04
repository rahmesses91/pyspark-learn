-- =============================================================================
-- NEXTAGRAM - SQL SOLUTIONS
-- Photo-sharing app analytics
-- MySQL 8.0+
-- =============================================================================

USE nextagram;


-- =============================================================================
-- PART I: BASIC DATA EXPLORATION
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Q1: How many users are there?
-- -----------------------------------------------------------------------------

SELECT COUNT(*) AS total_users
FROM users;


-- -----------------------------------------------------------------------------
-- Q2: In which month did the most users join?
-- -----------------------------------------------------------------------------

-- Option 1: Return month number and count
SELECT 
    MONTH(join_ts) AS join_month,
    MONTHNAME(join_ts) AS month_name,
    COUNT(*) AS user_count
FROM users
GROUP BY MONTH(join_ts), MONTHNAME(join_ts)
ORDER BY user_count DESC
LIMIT 1;

-- Option 2: Using window function to get all months ranked
WITH monthly_signups AS (
    SELECT 
        DATE_FORMAT(join_ts, '%Y-%m') AS join_month,
        COUNT(*) AS user_count,
        RANK() OVER (ORDER BY COUNT(*) DESC) AS rnk
    FROM users
    GROUP BY DATE_FORMAT(join_ts, '%Y-%m')
)
SELECT join_month, user_count
FROM monthly_signups
WHERE rnk = 1;


-- -----------------------------------------------------------------------------
-- Q3: What is the name of the user with the most followers?
-- Note: In the followers table:
--   - user_id = the person who is following
--   - following_id = the person being followed
-- So to count followers, we count how many times a user appears in following_id
-- -----------------------------------------------------------------------------

SELECT 
    u.name,
    COUNT(f.id) AS follower_count
FROM users u
LEFT JOIN followers f ON u.id = f.following_id
GROUP BY u.id, u.name
ORDER BY follower_count DESC
LIMIT 1;

-- Alternative with subquery
SELECT u.name, follower_counts.follower_count
FROM users u
JOIN (
    SELECT 
        following_id,
        COUNT(*) AS follower_count
    FROM followers
    GROUP BY following_id
    ORDER BY follower_count DESC
    LIMIT 1
) follower_counts ON u.id = follower_counts.following_id;


-- =============================================================================
-- PART II: KPI DASHBOARD DESIGN
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Q4: Dashboard Table Design
-- 
-- Considerations:
-- 1. Single table vs multiple: A single daily metrics table is simpler and 
--    works well since all metrics share the same granularity (daily).
-- 2. Pre-compute 7-day-ago values: Store both current and lag values to avoid
--    expensive window functions at query time.
-- 3. Follower distribution: Store as separate columns for each bucket.
-- 4. Indexes: Primary key on report_date for fast single-day lookups.
-- -----------------------------------------------------------------------------

DROP TABLE IF EXISTS daily_kpi_dashboard;

CREATE TABLE daily_kpi_dashboard (
    report_date DATE PRIMARY KEY,
    
    -- New Users metrics
    new_users INT NOT NULL DEFAULT 0,
    new_users_7d_ago INT DEFAULT NULL,
    new_users_change_pct DECIMAL(10,2) DEFAULT NULL,
    
    -- DAU metrics
    dau INT NOT NULL DEFAULT 0,
    dau_7d_ago INT DEFAULT NULL,
    dau_change_pct DECIMAL(10,2) DEFAULT NULL,
    
    -- New Photos metrics
    new_photos INT NOT NULL DEFAULT 0,
    new_photos_per_dau DECIMAL(10,4) DEFAULT NULL,
    new_photos_7d_ago INT DEFAULT NULL,
    new_photos_change_pct DECIMAL(10,2) DEFAULT NULL,
    
    -- Follower distribution (as of end of day)
    total_users_eod INT NOT NULL DEFAULT 0,
    pct_0_followers DECIMAL(5,2) DEFAULT NULL,
    pct_1_2_followers DECIMAL(5,2) DEFAULT NULL,
    pct_3_plus_followers DECIMAL(5,2) DEFAULT NULL,
    
    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_report_date (report_date)
);

-- Alternative design: Separate tables for different metric types
-- This is useful when metrics have different update frequencies or sources

-- Table for user metrics
DROP TABLE IF EXISTS daily_user_metrics;

CREATE TABLE daily_user_metrics (
    report_date DATE PRIMARY KEY,
    new_users INT NOT NULL DEFAULT 0,
    total_users INT NOT NULL DEFAULT 0,
    dau INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table for content metrics
DROP TABLE IF EXISTS daily_content_metrics;

CREATE TABLE daily_content_metrics (
    report_date DATE PRIMARY KEY,
    new_photos INT NOT NULL DEFAULT 0,
    total_photos INT NOT NULL DEFAULT 0,
    total_views INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table for follower distribution (snapshot)
DROP TABLE IF EXISTS daily_follower_distribution;

CREATE TABLE daily_follower_distribution (
    report_date DATE PRIMARY KEY,
    users_0_followers INT NOT NULL DEFAULT 0,
    users_1_2_followers INT NOT NULL DEFAULT 0,
    users_3_plus_followers INT NOT NULL DEFAULT 0,
    total_users INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- =============================================================================
-- PART III: DAILY DASHBOARD POPULATION QUERIES
-- =============================================================================

-- Set the report date (for demonstration)
SET @report_date = '2024-03-15';


-- -----------------------------------------------------------------------------
-- Q5: Daily new users and 7-day change
-- -----------------------------------------------------------------------------

WITH daily_new_users AS (
    SELECT 
        DATE(join_ts) AS report_date,
        COUNT(*) AS new_users
    FROM users
    WHERE DATE(join_ts) BETWEEN DATE_SUB(@report_date, INTERVAL 7 DAY) AND @report_date
    GROUP BY DATE(join_ts)
),
with_lag AS (
    SELECT 
        report_date,
        new_users,
        LAG(new_users, 7) OVER (ORDER BY report_date) AS new_users_7d_ago
    FROM daily_new_users
)
SELECT 
    report_date,
    new_users,
    new_users_7d_ago,
    CASE 
        WHEN new_users_7d_ago IS NULL OR new_users_7d_ago = 0 THEN NULL
        ELSE ROUND((new_users - new_users_7d_ago) * 100.0 / new_users_7d_ago, 2)
    END AS change_pct
FROM with_lag
WHERE report_date = @report_date;

-- Alternative: Self-join approach (works on older MySQL versions)
SELECT 
    today.report_date,
    today.new_users,
    week_ago.new_users AS new_users_7d_ago,
    ROUND(
        (today.new_users - COALESCE(week_ago.new_users, 0)) * 100.0 
        / NULLIF(week_ago.new_users, 0), 
        2
    ) AS change_pct
FROM (
    SELECT DATE(join_ts) AS report_date, COUNT(*) AS new_users
    FROM users
    WHERE DATE(join_ts) = @report_date
    GROUP BY DATE(join_ts)
) today
LEFT JOIN (
    SELECT DATE(join_ts) AS report_date, COUNT(*) AS new_users
    FROM users
    WHERE DATE(join_ts) = DATE_SUB(@report_date, INTERVAL 7 DAY)
    GROUP BY DATE(join_ts)
) week_ago ON 1=1;


-- -----------------------------------------------------------------------------
-- Q6: DAU (Daily Active Users) and 7-day change
-- DAU = users who viewed OR uploaded a photo that day
-- -----------------------------------------------------------------------------

WITH daily_active AS (
    SELECT report_date, COUNT(DISTINCT user_id) AS dau
    FROM (
        -- Users who viewed a photo
        SELECT DATE(ts) AS report_date, user_id
        FROM view_event
        WHERE DATE(ts) BETWEEN DATE_SUB(@report_date, INTERVAL 7 DAY) AND @report_date
        
        UNION
        
        -- Users who uploaded a photo
        SELECT DATE(upload_ts) AS report_date, user_id
        FROM photos
        WHERE DATE(upload_ts) BETWEEN DATE_SUB(@report_date, INTERVAL 7 DAY) AND @report_date
    ) all_activity
    GROUP BY report_date
),
with_lag AS (
    SELECT 
        report_date,
        dau,
        LAG(dau, 7) OVER (ORDER BY report_date) AS dau_7d_ago
    FROM daily_active
)
SELECT 
    report_date,
    dau,
    dau_7d_ago,
    CASE 
        WHEN dau_7d_ago IS NULL OR dau_7d_ago = 0 THEN NULL
        ELSE ROUND((dau - dau_7d_ago) * 100.0 / dau_7d_ago, 2)
    END AS change_pct
FROM with_lag
WHERE report_date = @report_date;


-- -----------------------------------------------------------------------------
-- Q7: New photos, photos per DAU, and 7-day changes
-- -----------------------------------------------------------------------------

WITH daily_photos AS (
    SELECT 
        DATE(upload_ts) AS report_date,
        COUNT(*) AS new_photos
    FROM photos
    WHERE DATE(upload_ts) BETWEEN DATE_SUB(@report_date, INTERVAL 7 DAY) AND @report_date
    GROUP BY DATE(upload_ts)
),
daily_dau AS (
    SELECT report_date, COUNT(DISTINCT user_id) AS dau
    FROM (
        SELECT DATE(ts) AS report_date, user_id FROM view_event
        WHERE DATE(ts) BETWEEN DATE_SUB(@report_date, INTERVAL 7 DAY) AND @report_date
        UNION
        SELECT DATE(upload_ts) AS report_date, user_id FROM photos
        WHERE DATE(upload_ts) BETWEEN DATE_SUB(@report_date, INTERVAL 7 DAY) AND @report_date
    ) all_activity
    GROUP BY report_date
),
combined AS (
    SELECT 
        p.report_date,
        p.new_photos,
        d.dau,
        ROUND(p.new_photos * 1.0 / NULLIF(d.dau, 0), 4) AS photos_per_dau,
        LAG(p.new_photos, 7) OVER (ORDER BY p.report_date) AS new_photos_7d_ago
    FROM daily_photos p
    LEFT JOIN daily_dau d ON p.report_date = d.report_date
)
SELECT 
    report_date,
    new_photos,
    dau,
    photos_per_dau,
    new_photos_7d_ago,
    CASE 
        WHEN new_photos_7d_ago IS NULL OR new_photos_7d_ago = 0 THEN NULL
        ELSE ROUND((new_photos - new_photos_7d_ago) * 100.0 / new_photos_7d_ago, 2)
    END AS photos_change_pct
FROM combined
WHERE report_date = @report_date;


-- -----------------------------------------------------------------------------
-- Q8: Follower distribution metrics
-- % with 0 followers, % with 1-2 followers, % with 3+ followers
-- -----------------------------------------------------------------------------

WITH follower_counts AS (
    -- Count followers for each user (as of report_date)
    SELECT 
        u.id AS user_id,
        COUNT(f.id) AS follower_count
    FROM users u
    LEFT JOIN followers f ON u.id = f.following_id 
        AND DATE(f.follow_ts) <= @report_date
    WHERE DATE(u.join_ts) <= @report_date
    GROUP BY u.id
),
user_buckets AS (
    SELECT 
        user_id,
        CASE 
            WHEN follower_count = 0 THEN '0_followers'
            WHEN follower_count BETWEEN 1 AND 2 THEN '1_2_followers'
            ELSE '3_plus_followers'
        END AS follower_bucket
    FROM follower_counts
),
bucket_counts AS (
    SELECT 
        follower_bucket,
        COUNT(*) AS user_count
    FROM user_buckets
    GROUP BY follower_bucket
),
total AS (
    SELECT SUM(user_count) AS total_users FROM bucket_counts
)
SELECT 
    @report_date AS report_date,
    ROUND(SUM(CASE WHEN b.follower_bucket = '0_followers' THEN b.user_count ELSE 0 END) * 100.0 / t.total_users, 2) AS pct_0_followers,
    ROUND(SUM(CASE WHEN b.follower_bucket = '1_2_followers' THEN b.user_count ELSE 0 END) * 100.0 / t.total_users, 2) AS pct_1_2_followers,
    ROUND(SUM(CASE WHEN b.follower_bucket = '3_plus_followers' THEN b.user_count ELSE 0 END) * 100.0 / t.total_users, 2) AS pct_3_plus_followers,
    t.total_users
FROM bucket_counts b
CROSS JOIN total t
GROUP BY t.total_users;


-- -----------------------------------------------------------------------------
-- Q9: Combined INSERT statement to populate the dashboard table
-- Single query that calculates all metrics and inserts into dashboard
-- -----------------------------------------------------------------------------

INSERT INTO daily_kpi_dashboard (
    report_date,
    new_users, new_users_7d_ago, new_users_change_pct,
    dau, dau_7d_ago, dau_change_pct,
    new_photos, new_photos_per_dau, new_photos_7d_ago, new_photos_change_pct,
    total_users_eod, pct_0_followers, pct_1_2_followers, pct_3_plus_followers
)
WITH 
-- New users today and 7 days ago
new_user_metrics AS (
    SELECT 
        @report_date AS report_date,
        (SELECT COUNT(*) FROM users WHERE DATE(join_ts) = @report_date) AS new_users,
        (SELECT COUNT(*) FROM users WHERE DATE(join_ts) = DATE_SUB(@report_date, INTERVAL 7 DAY)) AS new_users_7d_ago
),

-- DAU today and 7 days ago
dau_metrics AS (
    SELECT 
        @report_date AS report_date,
        (
            SELECT COUNT(DISTINCT user_id) FROM (
                SELECT user_id FROM view_event WHERE DATE(ts) = @report_date
                UNION
                SELECT user_id FROM photos WHERE DATE(upload_ts) = @report_date
            ) t
        ) AS dau,
        (
            SELECT COUNT(DISTINCT user_id) FROM (
                SELECT user_id FROM view_event WHERE DATE(ts) = DATE_SUB(@report_date, INTERVAL 7 DAY)
                UNION
                SELECT user_id FROM photos WHERE DATE(upload_ts) = DATE_SUB(@report_date, INTERVAL 7 DAY)
            ) t
        ) AS dau_7d_ago
),

-- Photo metrics
photo_metrics AS (
    SELECT 
        @report_date AS report_date,
        (SELECT COUNT(*) FROM photos WHERE DATE(upload_ts) = @report_date) AS new_photos,
        (SELECT COUNT(*) FROM photos WHERE DATE(upload_ts) = DATE_SUB(@report_date, INTERVAL 7 DAY)) AS new_photos_7d_ago
),

-- Follower distribution
follower_dist AS (
    SELECT 
        @report_date AS report_date,
        COUNT(*) AS total_users,
        SUM(CASE WHEN fc = 0 THEN 1 ELSE 0 END) AS users_0,
        SUM(CASE WHEN fc BETWEEN 1 AND 2 THEN 1 ELSE 0 END) AS users_1_2,
        SUM(CASE WHEN fc >= 3 THEN 1 ELSE 0 END) AS users_3_plus
    FROM (
        SELECT 
            u.id,
            COUNT(f.id) AS fc
        FROM users u
        LEFT JOIN followers f ON u.id = f.following_id AND DATE(f.follow_ts) <= @report_date
        WHERE DATE(u.join_ts) <= @report_date
        GROUP BY u.id
    ) user_follower_counts
)

SELECT 
    @report_date AS report_date,
    
    -- New users
    nu.new_users,
    nu.new_users_7d_ago,
    CASE 
        WHEN nu.new_users_7d_ago = 0 THEN NULL 
        ELSE ROUND((nu.new_users - nu.new_users_7d_ago) * 100.0 / nu.new_users_7d_ago, 2)
    END AS new_users_change_pct,
    
    -- DAU
    dm.dau,
    dm.dau_7d_ago,
    CASE 
        WHEN dm.dau_7d_ago = 0 THEN NULL 
        ELSE ROUND((dm.dau - dm.dau_7d_ago) * 100.0 / dm.dau_7d_ago, 2)
    END AS dau_change_pct,
    
    -- Photos
    pm.new_photos,
    CASE WHEN dm.dau = 0 THEN NULL ELSE ROUND(pm.new_photos * 1.0 / dm.dau, 4) END AS new_photos_per_dau,
    pm.new_photos_7d_ago,
    CASE 
        WHEN pm.new_photos_7d_ago = 0 THEN NULL 
        ELSE ROUND((pm.new_photos - pm.new_photos_7d_ago) * 100.0 / pm.new_photos_7d_ago, 2)
    END AS new_photos_change_pct,
    
    -- Follower distribution
    fd.total_users AS total_users_eod,
    ROUND(fd.users_0 * 100.0 / fd.total_users, 2) AS pct_0_followers,
    ROUND(fd.users_1_2 * 100.0 / fd.total_users, 2) AS pct_1_2_followers,
    ROUND(fd.users_3_plus * 100.0 / fd.total_users, 2) AS pct_3_plus_followers

FROM new_user_metrics nu
CROSS JOIN dau_metrics dm
CROSS JOIN photo_metrics pm
CROSS JOIN follower_dist fd;


-- -----------------------------------------------------------------------------
-- Procedure to populate dashboard for a date range (useful for backfill)
-- -----------------------------------------------------------------------------

DROP PROCEDURE IF EXISTS populate_daily_kpi;

DELIMITER //

CREATE PROCEDURE populate_daily_kpi(IN p_start_date DATE, IN p_end_date DATE)
BEGIN
    DECLARE current_date_var DATE;
    SET current_date_var = p_start_date;
    
    WHILE current_date_var <= p_end_date DO
        SET @report_date = current_date_var;
        
        -- Delete existing record if any
        DELETE FROM daily_kpi_dashboard WHERE report_date = current_date_var;
        
        -- Insert new record (using the INSERT query from Q9)
        INSERT INTO daily_kpi_dashboard (
            report_date,
            new_users, new_users_7d_ago, new_users_change_pct,
            dau, dau_7d_ago, dau_change_pct,
            new_photos, new_photos_per_dau, new_photos_7d_ago, new_photos_change_pct,
            total_users_eod, pct_0_followers, pct_1_2_followers, pct_3_plus_followers
        )
        SELECT 
            current_date_var AS report_date,
            COALESCE((SELECT COUNT(*) FROM users WHERE DATE(join_ts) = current_date_var), 0),
            COALESCE((SELECT COUNT(*) FROM users WHERE DATE(join_ts) = DATE_SUB(current_date_var, INTERVAL 7 DAY)), 0),
            NULL,
            COALESCE((SELECT COUNT(DISTINCT user_id) FROM (
                SELECT user_id FROM view_event WHERE DATE(ts) = current_date_var
                UNION SELECT user_id FROM photos WHERE DATE(upload_ts) = current_date_var
            ) t), 0),
            COALESCE((SELECT COUNT(DISTINCT user_id) FROM (
                SELECT user_id FROM view_event WHERE DATE(ts) = DATE_SUB(current_date_var, INTERVAL 7 DAY)
                UNION SELECT user_id FROM photos WHERE DATE(upload_ts) = DATE_SUB(current_date_var, INTERVAL 7 DAY)
            ) t), 0),
            NULL,
            COALESCE((SELECT COUNT(*) FROM photos WHERE DATE(upload_ts) = current_date_var), 0),
            NULL,
            COALESCE((SELECT COUNT(*) FROM photos WHERE DATE(upload_ts) = DATE_SUB(current_date_var, INTERVAL 7 DAY)), 0),
            NULL,
            (SELECT COUNT(*) FROM users WHERE DATE(join_ts) <= current_date_var),
            NULL, NULL, NULL;
        
        -- Update calculated fields
        UPDATE daily_kpi_dashboard d
        SET 
            new_users_change_pct = CASE 
                WHEN new_users_7d_ago = 0 THEN NULL 
                ELSE ROUND((new_users - new_users_7d_ago) * 100.0 / new_users_7d_ago, 2)
            END,
            dau_change_pct = CASE 
                WHEN dau_7d_ago = 0 THEN NULL 
                ELSE ROUND((dau - dau_7d_ago) * 100.0 / dau_7d_ago, 2)
            END,
            new_photos_per_dau = CASE 
                WHEN dau = 0 THEN NULL 
                ELSE ROUND(new_photos * 1.0 / dau, 4)
            END,
            new_photos_change_pct = CASE 
                WHEN new_photos_7d_ago = 0 THEN NULL 
                ELSE ROUND((new_photos - new_photos_7d_ago) * 100.0 / new_photos_7d_ago, 2)
            END
        WHERE report_date = current_date_var;
        
        SET current_date_var = DATE_ADD(current_date_var, INTERVAL 1 DAY);
    END WHILE;
END //

DELIMITER ;

-- Usage: CALL populate_daily_kpi('2024-01-01', '2024-06-30');


-- =============================================================================
-- BONUS PROBLEMS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Bonus 1: User Engagement Score
-- Score = (photos * 3) + (followers * 2) + (views * 1)
-- -----------------------------------------------------------------------------

WITH user_photos AS (
    SELECT user_id, COUNT(*) AS photo_count
    FROM photos
    GROUP BY user_id
),
user_followers AS (
    SELECT following_id AS user_id, COUNT(*) AS follower_count
    FROM followers
    GROUP BY following_id
),
user_views AS (
    SELECT user_id, COUNT(*) AS view_count
    FROM view_event
    GROUP BY user_id
)
SELECT 
    u.id AS user_id,
    u.name,
    COALESCE(p.photo_count, 0) AS photos_uploaded,
    COALESCE(f.follower_count, 0) AS followers,
    COALESCE(v.view_count, 0) AS photos_viewed,
    (COALESCE(p.photo_count, 0) * 3) + 
    (COALESCE(f.follower_count, 0) * 2) + 
    (COALESCE(v.view_count, 0) * 1) AS engagement_score
FROM users u
LEFT JOIN user_photos p ON u.id = p.user_id
LEFT JOIN user_followers f ON u.id = f.user_id
LEFT JOIN user_views v ON u.id = v.user_id
ORDER BY engagement_score DESC
LIMIT 20;


-- -----------------------------------------------------------------------------
-- Bonus 2: Viral Photos
-- Photos viewed by at least 5% of all users
-- -----------------------------------------------------------------------------

WITH photo_views AS (
    SELECT 
        photo_id,
        COUNT(DISTINCT user_id) AS unique_viewers
    FROM view_event
    GROUP BY photo_id
),
total_users AS (
    SELECT COUNT(*) AS total FROM users
)
SELECT 
    pv.photo_id,
    u.name AS uploader_name,
    pv.unique_viewers,
    ROUND(pv.unique_viewers * 100.0 / tu.total, 2) AS pct_users_viewed
FROM photo_views pv
JOIN photos p ON pv.photo_id = p.id
JOIN users u ON p.user_id = u.id
CROSS JOIN total_users tu
WHERE pv.unique_viewers >= (tu.total * 0.05)
ORDER BY pv.unique_viewers DESC;


-- -----------------------------------------------------------------------------
-- Bonus 3: Follow Network Analysis
-- Identify influencers (ratio > 2) and fans (ratio < 0.5)
-- -----------------------------------------------------------------------------

WITH followers_count AS (
    SELECT following_id AS user_id, COUNT(*) AS cnt
    FROM followers
    GROUP BY following_id
),
following_count AS (
    SELECT user_id, COUNT(*) AS cnt
    FROM followers
    GROUP BY user_id
)
SELECT 
    u.id AS user_id,
    u.name,
    COALESCE(fr.cnt, 0) AS followers_count,
    COALESCE(fg.cnt, 0) AS following_count,
    CASE 
        WHEN COALESCE(fg.cnt, 0) = 0 THEN NULL
        ELSE ROUND(COALESCE(fr.cnt, 0) * 1.0 / fg.cnt, 2)
    END AS follower_ratio,
    CASE 
        WHEN COALESCE(fg.cnt, 0) = 0 AND COALESCE(fr.cnt, 0) > 0 THEN 'INFLUENCER'
        WHEN COALESCE(fg.cnt, 0) = 0 THEN 'NEW_USER'
        WHEN COALESCE(fr.cnt, 0) * 1.0 / fg.cnt > 2 THEN 'INFLUENCER'
        WHEN COALESCE(fr.cnt, 0) * 1.0 / fg.cnt < 0.5 THEN 'FAN'
        ELSE 'BALANCED'
    END AS user_type
FROM users u
LEFT JOIN followers_count fr ON u.id = fr.user_id
LEFT JOIN following_count fg ON u.id = fg.user_id
ORDER BY 
    CASE 
        WHEN COALESCE(fg.cnt, 0) = 0 AND COALESCE(fr.cnt, 0) > 0 THEN 'INFLUENCER'
        WHEN COALESCE(fg.cnt, 0) = 0 THEN 'NEW_USER'
        WHEN COALESCE(fr.cnt, 0) * 1.0 / fg.cnt > 2 THEN 'INFLUENCER'
        WHEN COALESCE(fr.cnt, 0) * 1.0 / fg.cnt < 0.5 THEN 'FAN'
        ELSE 'BALANCED'
    END,
    followers_count DESC;
