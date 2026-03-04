-- Nextagram Photo Sharing App - Schema
-- MySQL 8.0+
-- A fictional Instagram-like social photo sharing platform

CREATE DATABASE IF NOT EXISTS nextagram;
USE nextagram;

-- =============================================================================
-- DROP EXISTING TABLES (in correct order for foreign keys)
-- =============================================================================
DROP TABLE IF EXISTS view_event;
DROP TABLE IF EXISTS followers;
DROP TABLE IF EXISTS photos;
DROP TABLE IF EXISTS users;

-- =============================================================================
-- USERS TABLE
-- User accounts and profile information
-- =============================================================================
CREATE TABLE users (
    id BIGINT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    join_ts TIMESTAMP NOT NULL,
    
    INDEX idx_users_join_ts (join_ts)
);

-- =============================================================================
-- PHOTOS TABLE
-- Photos uploaded by users
-- =============================================================================
CREATE TABLE photos (
    id BIGINT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    url VARCHAR(500) NOT NULL,
    upload_ts TIMESTAMP NOT NULL,
    
    FOREIGN KEY (user_id) REFERENCES users(id),
    
    INDEX idx_photos_user (user_id),
    INDEX idx_photos_upload_ts (upload_ts)
);

-- =============================================================================
-- FOLLOWERS TABLE
-- User follow relationships
-- =============================================================================
CREATE TABLE followers (
    id BIGINT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    following_id BIGINT NOT NULL,
    follow_ts TIMESTAMP NOT NULL,
    
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (following_id) REFERENCES users(id),
    
    INDEX idx_followers_user (user_id),
    INDEX idx_followers_following (following_id),
    INDEX idx_followers_ts (follow_ts),
    
    UNIQUE KEY uk_follow_relationship (user_id, following_id)
);

-- =============================================================================
-- VIEW_EVENT TABLE
-- Photo view events (who viewed which photo and when)
-- =============================================================================
CREATE TABLE view_event (
    user_id BIGINT NOT NULL,
    photo_id BIGINT NOT NULL,
    ts TIMESTAMP NOT NULL,
    
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (photo_id) REFERENCES photos(id),
    
    INDEX idx_view_user (user_id),
    INDEX idx_view_photo (photo_id),
    INDEX idx_view_ts (ts)
);
