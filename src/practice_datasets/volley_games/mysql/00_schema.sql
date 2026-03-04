-- Volley Games Voice Analytics Schema
-- MySQL 8.0+
-- Run this script to create all tables before importing CSV data

CREATE DATABASE IF NOT EXISTS volley_games;
USE volley_games;

-- =============================================================================
-- USERS TABLE
-- Player accounts and profile information
-- =============================================================================
DROP TABLE IF EXISTS events;
DROP TABLE IF EXISTS purchases;
DROP TABLE IF EXISTS sessions;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS games;

CREATE TABLE users (
    user_id INT PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    device_type ENUM('alexa', 'google_home', 'mobile_ios', 'mobile_android') NOT NULL,
    country VARCHAR(50) NOT NULL,
    created_at DATETIME NOT NULL,
    is_premium TINYINT(1) DEFAULT 0,
    last_active_at DATETIME,
    
    INDEX idx_users_created (created_at),
    INDEX idx_users_country (country),
    INDEX idx_users_device (device_type)
);

-- =============================================================================
-- GAMES TABLE
-- Catalog of available voice games
-- =============================================================================
CREATE TABLE games (
    game_id INT PRIMARY KEY,
    game_name VARCHAR(100) NOT NULL,
    category ENUM('trivia', 'word_game', 'adventure', 'puzzle', 'music', 'kids', 'educational') NOT NULL,
    difficulty ENUM('easy', 'medium', 'hard') NOT NULL,
    release_date DATE NOT NULL,
    is_premium TINYINT(1) DEFAULT 0,
    
    INDEX idx_games_category (category)
);

-- =============================================================================
-- SESSIONS TABLE
-- Individual game play sessions
-- =============================================================================
CREATE TABLE sessions (
    session_id INT PRIMARY KEY,
    user_id INT NOT NULL,
    game_id INT NOT NULL,
    device_type ENUM('alexa', 'google_home', 'mobile_ios', 'mobile_android') NOT NULL,
    started_at DATETIME NOT NULL,
    ended_at DATETIME,
    completed TINYINT(1) DEFAULT 0,
    score INT,
    
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (game_id) REFERENCES games(game_id),
    
    INDEX idx_sessions_user (user_id),
    INDEX idx_sessions_game (game_id),
    INDEX idx_sessions_started (started_at),
    INDEX idx_sessions_completed (completed)
);

-- =============================================================================
-- EVENTS TABLE
-- In-game events (voice commands, achievements, errors, etc.)
-- =============================================================================
CREATE TABLE events (
    event_id INT PRIMARY KEY,
    session_id INT NOT NULL,
    user_id INT NOT NULL,
    event_type ENUM('voice_command', 'game_start', 'game_complete', 'achievement', 'error', 'hint_used', 'level_up', 'pause', 'resume') NOT NULL,
    event_data JSON,
    created_at DATETIME NOT NULL,
    
    FOREIGN KEY (session_id) REFERENCES sessions(session_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    
    INDEX idx_events_session (session_id),
    INDEX idx_events_user (user_id),
    INDEX idx_events_type (event_type),
    INDEX idx_events_created (created_at)
);

-- =============================================================================
-- PURCHASES TABLE
-- In-app purchases and subscriptions
-- =============================================================================
CREATE TABLE purchases (
    purchase_id INT PRIMARY KEY,
    user_id INT NOT NULL,
    game_id INT,
    item_type ENUM('premium_subscription', 'hint_pack', 'extra_lives', 'cosmetic', 'game_unlock', 'ad_removal') NOT NULL,
    amount_usd DECIMAL(10, 2) NOT NULL,
    purchased_at DATETIME NOT NULL,
    
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (game_id) REFERENCES games(game_id),
    
    INDEX idx_purchases_user (user_id),
    INDEX idx_purchases_date (purchased_at),
    INDEX idx_purchases_item (item_type)
);

-- =============================================================================
-- USEFUL VIEWS FOR ANALYSIS
-- =============================================================================

-- Daily metrics view
CREATE OR REPLACE VIEW v_daily_metrics AS
SELECT 
    DATE(s.started_at) AS activity_date,
    COUNT(DISTINCT s.user_id) AS dau,
    COUNT(DISTINCT s.session_id) AS total_sessions,
    SUM(CASE WHEN s.completed = 1 THEN 1 ELSE 0 END) AS completed_sessions,
    AVG(TIMESTAMPDIFF(MINUTE, s.started_at, s.ended_at)) AS avg_session_minutes
FROM sessions s
GROUP BY DATE(s.started_at);

-- User summary view
CREATE OR REPLACE VIEW v_user_summary AS
SELECT 
    u.user_id,
    u.username,
    u.device_type,
    u.country,
    u.created_at AS signup_date,
    u.is_premium,
    COUNT(DISTINCT s.session_id) AS total_sessions,
    SUM(CASE WHEN s.completed = 1 THEN 1 ELSE 0 END) AS completed_sessions,
    MIN(s.started_at) AS first_session,
    MAX(s.started_at) AS last_session,
    COALESCE(SUM(p.amount_usd), 0) AS total_spent
FROM users u
LEFT JOIN sessions s ON u.user_id = s.user_id
LEFT JOIN purchases p ON u.user_id = p.user_id
GROUP BY u.user_id, u.username, u.device_type, u.country, u.created_at, u.is_premium;
