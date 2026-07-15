-- Wallpaper Sync D1 Database Schema
-- Run: npx wrangler d1 execute wallpaper-sync-db --file=src/db/schema.sql

CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    pinterest_user_id TEXT UNIQUE,
    pinterest_username TEXT,
    encrypted_refresh_token TEXT NOT NULL,
    board_id TEXT,
    mobile_board_id TEXT,
    desktop_board_id TEXT,
    stripe_customer_id TEXT UNIQUE,
    subscription_status TEXT NOT NULL DEFAULT 'inactive',
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Index for fast lookups by Pinterest user ID
CREATE INDEX IF NOT EXISTS idx_users_pinterest_user_id ON users(pinterest_user_id);

-- Index for Stripe webhook lookups
CREATE INDEX IF NOT EXISTS idx_users_stripe_customer_id ON users(stripe_customer_id);
