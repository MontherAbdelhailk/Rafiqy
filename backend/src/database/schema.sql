-- ============================================================
-- Rafiq Authentication Backend — Full Database Schema
-- PostgreSQL 14+
-- Run: psql -U postgres -f schema.sql
-- ============================================================

-- Create the database (run as superuser separately if needed)
-- CREATE DATABASE rafiq_db;
-- \c rafiq_db;

-- ─── Extensions ──────────────────────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "pgcrypto";   -- gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS "citext";     -- case-insensitive text

-- ─── Clean up (dev/re-run safety) ────────────────────────────────────────────
DROP TABLE IF EXISTS user_fcm_tokens CASCADE;
DROP TABLE IF EXISTS admin_chat_messages CASCADE;
DROP TABLE IF EXISTS payments CASCADE;
DROP TABLE IF EXISTS sessions CASCADE;
DROP TABLE IF EXISTS bookings CASCADE;
DROP TABLE IF EXISTS consultation_slots CASCADE;
DROP TABLE IF EXISTS video_likes CASCADE;
DROP TABLE IF EXISTS video_views CASCADE;
DROP TABLE IF EXISTS videos CASCADE;
DROP TABLE IF EXISTS video_subcategories CASCADE;
DROP TABLE IF EXISTS video_categories CASCADE;
DROP TABLE IF EXISTS reel_comment_replies CASCADE;
DROP TABLE IF EXISTS reel_comment_likes CASCADE;
DROP TABLE IF EXISTS reel_comments CASCADE;
DROP TABLE IF EXISTS reel_loves CASCADE;
DROP TABLE IF EXISTS reels CASCADE;
DROP TABLE IF EXISTS comment_replies CASCADE;
DROP TABLE IF EXISTS comment_likes CASCADE;
DROP TABLE IF EXISTS comments CASCADE;
DROP TABLE IF EXISTS post_loves CASCADE;
DROP TABLE IF EXISTS posts CASCADE;
DROP TABLE IF EXISTS refresh_tokens CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- ─── ENUM Types ──────────────────────────────────────────────────────────────
DO $$ BEGIN
  CREATE TYPE user_status AS ENUM ('active', 'inactive', 'suspended', 'deleted');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE marital_status AS ENUM ('Single', 'Married', 'Divorced');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- ============================================================
-- TABLE: users
-- ============================================================
CREATE TABLE users (
  id              UUID          NOT NULL DEFAULT gen_random_uuid(),
  full_name       VARCHAR(100)  NOT NULL,
  username        CITEXT        NOT NULL,         -- case-insensitive unique
  email           CITEXT        NOT NULL,         -- case-insensitive unique
  password_hash   TEXT          NOT NULL,
  status          user_status   NOT NULL DEFAULT 'active',
  is_verified     BOOLEAN       NOT NULL DEFAULT FALSE,
  
  -- Profile fields
  first_name      VARCHAR(50),
  last_name       VARCHAR(50),
  profile_picture TEXT DEFAULT '/uploads/default_user.png',
  marital_status  marital_status NOT NULL DEFAULT 'Single',
  age             INTEGER,
  phone_number    VARCHAR(20),
  children_count  INTEGER DEFAULT 0,
  bio             TEXT DEFAULT 'Parenting Enthusiast',
  role            VARCHAR(20)   NOT NULL DEFAULT 'user',

  last_login_at   TIMESTAMPTZ,
  created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),

  -- ─── Constraints ──────────────────────────────────────────
  CONSTRAINT users_pkey             PRIMARY KEY (id),
  CONSTRAINT users_username_length  CHECK (char_length(username) >= 3),
  CONSTRAINT users_full_name_length CHECK (char_length(full_name) >= 2),
  CONSTRAINT users_email_format     CHECK (email ~* '^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$'),
  CONSTRAINT check_children_conditional CHECK (
    (marital_status = 'Married' AND children_count IS NOT NULL) OR
    (marital_status != 'Married')
  )
);

-- ─── Unique Indexes ───────────────────────────────────────────────────────────
CREATE UNIQUE INDEX users_username_uidx ON users (username);
CREATE UNIQUE INDEX users_email_uidx    ON users (email);

-- ─── Search / Filter Indexes ──────────────────────────────────────────────────
CREATE INDEX users_status_idx     ON users (status);
CREATE INDEX users_created_at_idx ON users (created_at DESC);

-- ─── Auto-update updated_at trigger ──────────────────────────────────────────
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER users_updated_at_trigger
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- TABLE: refresh_tokens
-- ============================================================
CREATE TABLE refresh_tokens (
  id          UUID        NOT NULL DEFAULT gen_random_uuid(),
  user_id     UUID        NOT NULL,
  token_hash  TEXT        NOT NULL,             -- hashed for security
  expires_at  TIMESTAMPTZ NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  revoked_at  TIMESTAMPTZ,                      -- NULL = still valid
  user_agent  TEXT,
  ip_address  INET,

  CONSTRAINT refresh_tokens_pkey    PRIMARY KEY (id),
  CONSTRAINT refresh_tokens_user_fk FOREIGN KEY (user_id)
    REFERENCES users (id) ON DELETE CASCADE
);

CREATE INDEX refresh_tokens_user_id_idx   ON refresh_tokens (user_id);
CREATE INDEX refresh_tokens_token_hash_idx ON refresh_tokens (token_hash);
CREATE INDEX refresh_tokens_expires_at_idx ON refresh_tokens (expires_at);

-- ============================================================
-- Cleanup function — remove expired/revoked tokens (run via cron)
-- ============================================================
CREATE OR REPLACE FUNCTION purge_expired_refresh_tokens()
RETURNS INTEGER AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  DELETE FROM refresh_tokens
  WHERE expires_at < NOW() OR revoked_at IS NOT NULL;
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- Helpful views
-- ============================================================
CREATE OR REPLACE VIEW active_users AS
SELECT
  id,
  full_name,
  username,
  email,
  first_name,
  last_name,
  profile_picture,
  marital_status,
  age,
  phone_number,
  children_count,
  bio,
  is_verified,
  last_login_at,
  created_at
FROM users
WHERE status = 'active';

-- ============================================================
-- TABLE: posts
-- ============================================================
CREATE TABLE posts (
  id              UUID          NOT NULL DEFAULT gen_random_uuid(),
  content         TEXT          NOT NULL,
  media_url       TEXT,
  user_id         UUID          NOT NULL,
  created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),

  CONSTRAINT posts_pkey PRIMARY KEY (id),
  CONSTRAINT posts_user_fk FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

CREATE INDEX posts_created_at_idx ON posts (created_at DESC);

-- ============================================================
-- TABLE: post_loves
-- ============================================================
CREATE TABLE post_loves (
  post_id         UUID          NOT NULL,
  user_id         UUID          NOT NULL,
  created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),

  CONSTRAINT post_loves_pkey PRIMARY KEY (post_id, user_id),
  CONSTRAINT post_loves_post_fk FOREIGN KEY (post_id) REFERENCES posts (id) ON DELETE CASCADE,
  CONSTRAINT post_loves_user_fk FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

-- ============================================================
-- TABLE: comments
-- ============================================================
CREATE TABLE comments (
  id              UUID          NOT NULL DEFAULT gen_random_uuid(),
  post_id         UUID          NOT NULL,
  user_id         UUID          NOT NULL,
  content         TEXT          NOT NULL,
  created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),

  CONSTRAINT comments_pkey PRIMARY KEY (id),
  CONSTRAINT comments_post_fk FOREIGN KEY (post_id) REFERENCES posts (id) ON DELETE CASCADE,
  CONSTRAINT comments_user_fk FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

CREATE INDEX comments_post_id_idx ON comments (post_id);
CREATE INDEX comments_created_at_idx ON comments (created_at ASC);

-- ============================================================
-- TABLE: comment_likes
-- ============================================================
CREATE TABLE comment_likes (
  comment_id      UUID          NOT NULL,
  user_id         UUID          NOT NULL,
  created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),

  CONSTRAINT comment_likes_pkey PRIMARY KEY (comment_id, user_id),
  CONSTRAINT comment_likes_comment_fk FOREIGN KEY (comment_id) REFERENCES comments (id) ON DELETE CASCADE,
  CONSTRAINT comment_likes_user_fk FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

-- ============================================================
-- TABLE: comment_replies
-- ============================================================
CREATE TABLE comment_replies (
  id              UUID          NOT NULL DEFAULT gen_random_uuid(),
  comment_id      UUID          NOT NULL,
  user_id         UUID          NOT NULL,
  content         TEXT          NOT NULL,
  created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),

  CONSTRAINT comment_replies_pkey PRIMARY KEY (id),
  CONSTRAINT comment_replies_comment_fk FOREIGN KEY (comment_id) REFERENCES comments (id) ON DELETE CASCADE,
  CONSTRAINT comment_replies_user_fk FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

CREATE INDEX comment_replies_comment_id_idx ON comment_replies (comment_id);
CREATE INDEX comment_replies_created_at_idx ON comment_replies (created_at ASC);

-- ============================================================
-- TABLE: reels
-- ============================================================
CREATE TABLE reels (
  id              UUID          NOT NULL DEFAULT gen_random_uuid(),
  caption         TEXT          NOT NULL,
  video_url       TEXT          NOT NULL,
  thumbnail_url   TEXT,
  is_public       BOOLEAN       NOT NULL DEFAULT TRUE,
  comments_enabled BOOLEAN       NOT NULL DEFAULT TRUE,
  view_count      INTEGER       NOT NULL DEFAULT 0,
  user_id         UUID          NOT NULL,
  duration        VARCHAR(20)   NOT NULL DEFAULT '00:00',
  resolution      VARCHAR(50),
  aspect_ratio    VARCHAR(20),
  created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),

  CONSTRAINT reels_pkey PRIMARY KEY (id),
  CONSTRAINT reels_user_fk FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

CREATE INDEX reels_created_at_idx ON reels (created_at DESC);

-- ============================================================
-- TABLE: reel_loves
-- ============================================================
CREATE TABLE reel_loves (
  reel_id         UUID          NOT NULL,
  user_id         UUID          NOT NULL,
  created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),

  CONSTRAINT reel_loves_pkey PRIMARY KEY (reel_id, user_id),
  CONSTRAINT reel_loves_reel_fk FOREIGN KEY (reel_id) REFERENCES reels (id) ON DELETE CASCADE,
  CONSTRAINT reel_loves_user_fk FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

-- ============================================================
-- TABLE: reel_comments
-- ============================================================
CREATE TABLE reel_comments (
  id              UUID          NOT NULL DEFAULT gen_random_uuid(),
  reel_id         UUID          NOT NULL,
  user_id         UUID          NOT NULL,
  content         TEXT          NOT NULL,
  created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),

  CONSTRAINT reel_comments_pkey PRIMARY KEY (id),
  CONSTRAINT reel_comments_reel_fk FOREIGN KEY (reel_id) REFERENCES reels (id) ON DELETE CASCADE,
  CONSTRAINT reel_comments_user_fk FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

CREATE INDEX reel_comments_reel_id_idx ON reel_comments (reel_id);
CREATE INDEX reel_comments_created_at_idx ON reel_comments (created_at ASC);

-- ============================================================
-- TABLE: reel_comment_likes
-- ============================================================
CREATE TABLE reel_comment_likes (
  comment_id      UUID          NOT NULL,
  user_id         UUID          NOT NULL,
  created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),

  CONSTRAINT reel_comment_likes_pkey PRIMARY KEY (comment_id, user_id),
  CONSTRAINT reel_comment_likes_comment_fk FOREIGN KEY (comment_id) REFERENCES reel_comments (id) ON DELETE CASCADE,
  CONSTRAINT reel_comment_likes_user_fk FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

-- ============================================================
-- TABLE: reel_comment_replies
-- ============================================================
CREATE TABLE reel_comment_replies (
  id              UUID          NOT NULL DEFAULT gen_random_uuid(),
  comment_id      UUID          NOT NULL,
  user_id         UUID          NOT NULL,
  content         TEXT          NOT NULL,
  created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),

  CONSTRAINT reel_comment_replies_pkey PRIMARY KEY (id),
  CONSTRAINT reel_comment_replies_comment_fk FOREIGN KEY (comment_id) REFERENCES reel_comments (id) ON DELETE CASCADE,
  CONSTRAINT reel_comment_replies_user_fk FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

CREATE INDEX reel_comment_replies_comment_id_idx ON reel_comment_replies (comment_id);
CREATE INDEX reel_comment_replies_created_at_idx ON reel_comment_replies (created_at ASC);

-- ============================================================
-- TABLE: video_categories
-- ============================================================
CREATE TABLE video_categories (
  id              UUID          NOT NULL DEFAULT gen_random_uuid(),
  title           VARCHAR(100)  NOT NULL,
  description     TEXT          NOT NULL,
  icon_name       VARCHAR(50)   NOT NULL,
  created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  CONSTRAINT video_categories_pkey PRIMARY KEY (id)
);

CREATE UNIQUE INDEX video_categories_title_uidx ON video_categories (title);

-- ============================================================
-- TABLE: video_subcategories (stages)
-- ============================================================
CREATE TABLE video_subcategories (
  id              UUID          NOT NULL DEFAULT gen_random_uuid(),
  category_id     UUID          NOT NULL,
  title           VARCHAR(100)  NOT NULL,
  subtitle        VARCHAR(100),
  description     TEXT          NOT NULL,
  age_range       VARCHAR(50),
  image_path      VARCHAR(255),
  created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  CONSTRAINT video_subcategories_pkey PRIMARY KEY (id),
  CONSTRAINT video_subcategories_category_fk FOREIGN KEY (category_id) REFERENCES video_categories (id) ON DELETE CASCADE
);

CREATE UNIQUE INDEX video_subcategories_cat_title_uidx ON video_subcategories (category_id, title);

-- ============================================================
-- TABLE: videos
-- ============================================================
CREATE TABLE videos (
  id              UUID          NOT NULL DEFAULT gen_random_uuid(),
  title           VARCHAR(255)  NOT NULL,
  description     TEXT          NOT NULL,
  video_url       TEXT          NOT NULL,
  thumbnail_url   TEXT          NOT NULL,
  duration        VARCHAR(20)   NOT NULL DEFAULT '02:00',
  resolution      VARCHAR(50),
  aspect_ratio    VARCHAR(20),
  is_public       BOOLEAN       NOT NULL DEFAULT TRUE,
  category_id     UUID          NOT NULL,
  subcategory_id  UUID,
  tags            TEXT[],
  view_count      INTEGER       NOT NULL DEFAULT 0,
  created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),

  CONSTRAINT videos_pkey PRIMARY KEY (id),
  CONSTRAINT videos_category_fk FOREIGN KEY (category_id) REFERENCES video_categories (id) ON DELETE CASCADE,
  CONSTRAINT videos_subcategory_fk FOREIGN KEY (subcategory_id) REFERENCES video_subcategories (id) ON DELETE SET NULL
);

CREATE INDEX videos_created_at_idx ON videos (created_at DESC);

-- ============================================================
-- TABLE: video_likes
-- ============================================================
CREATE TABLE video_likes (
  video_id        UUID          NOT NULL,
  user_id         UUID          NOT NULL,
  created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  CONSTRAINT video_likes_pkey PRIMARY KEY (video_id, user_id),
  CONSTRAINT video_likes_video_fk FOREIGN KEY (video_id) REFERENCES videos (id) ON DELETE CASCADE,
  CONSTRAINT video_likes_user_fk FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

-- ============================================================
-- TABLE: video_views
-- ============================================================
CREATE TABLE video_views (
  video_id        UUID          NOT NULL,
  user_id         UUID          NOT NULL,
  created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  CONSTRAINT video_views_pkey PRIMARY KEY (video_id, user_id),
  CONSTRAINT video_views_video_fk FOREIGN KEY (video_id) REFERENCES videos (id) ON DELETE CASCADE,
  CONSTRAINT video_views_user_fk FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

-- ============================================================
-- TABLE: admin_chat_messages
-- ============================================================
CREATE TABLE admin_chat_messages (
  id            UUID          NOT NULL DEFAULT gen_random_uuid(),
  sender_id     UUID          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  receiver_id   UUID          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  content       TEXT          NOT NULL DEFAULT '',
  media_url     TEXT,
  is_read       BOOLEAN       NOT NULL DEFAULT FALSE,
  created_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  CONSTRAINT admin_chat_messages_pkey PRIMARY KEY (id)
);

CREATE INDEX admin_chat_messages_sender_idx ON admin_chat_messages (sender_id);
CREATE INDEX admin_chat_messages_receiver_idx ON admin_chat_messages (receiver_id);
CREATE INDEX admin_chat_messages_created_at_idx ON admin_chat_messages (created_at DESC);

-- ============================================================
-- TABLE: user_fcm_tokens
-- ============================================================
CREATE TABLE user_fcm_tokens (
  user_id      UUID          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  fcm_token    TEXT          NOT NULL,
  created_at   TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  CONSTRAINT user_fcm_tokens_pkey PRIMARY KEY (user_id, fcm_token)
);

CREATE INDEX user_fcm_tokens_user_id_idx ON user_fcm_tokens (user_id);

-- ============================================================
-- ENUM Types for Booking System
-- ============================================================
DO $$ BEGIN
  CREATE TYPE booking_status AS ENUM ('pending_payment', 'confirmed', 'cancelled', 'completed', 'no_show');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE payment_status AS ENUM ('pending', 'success', 'failed', 'refunded');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE session_status AS ENUM ('scheduled', 'active', 'completed', 'cancelled');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- ============================================================
-- TABLE: consultation_slots
-- Admin-defined available time slots for booking
-- ============================================================
CREATE TABLE consultation_slots (
  id              UUID          NOT NULL DEFAULT gen_random_uuid(),
  start_time      TIMESTAMPTZ   NOT NULL,
  end_time        TIMESTAMPTZ   NOT NULL,
  duration_mins   INTEGER       NOT NULL DEFAULT 45,
  price           DECIMAL(10,2) NOT NULL DEFAULT 750.00,
  is_available    BOOLEAN       NOT NULL DEFAULT TRUE,
  is_booked       BOOLEAN       NOT NULL DEFAULT FALSE,
  notes           TEXT,
  created_by      UUID          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),

  CONSTRAINT consultation_slots_pkey PRIMARY KEY (id),
  CONSTRAINT slot_times_valid CHECK (end_time > start_time)
);

CREATE INDEX consultation_slots_start_time_idx ON consultation_slots (start_time);
CREATE INDEX consultation_slots_available_idx  ON consultation_slots (is_available, is_booked);

CREATE TRIGGER consultation_slots_updated_at
  BEFORE UPDATE ON consultation_slots
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- TABLE: bookings
-- User consultation session bookings
-- ============================================================
CREATE TABLE bookings (
  id                  UUID          NOT NULL DEFAULT gen_random_uuid(),
  user_id             UUID          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  slot_id             UUID          NOT NULL REFERENCES consultation_slots(id) ON DELETE RESTRICT,
  status              booking_status NOT NULL DEFAULT 'pending_payment',
  amount              DECIMAL(10,2) NOT NULL,
  notes               TEXT,
  cancellation_reason TEXT,
  cancelled_at        TIMESTAMPTZ,
  confirmed_at        TIMESTAMPTZ,
  completed_at        TIMESTAMPTZ,
  created_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW(),

  CONSTRAINT bookings_pkey PRIMARY KEY (id),
  CONSTRAINT bookings_user_fk FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT bookings_slot_fk FOREIGN KEY (slot_id) REFERENCES consultation_slots(id) ON DELETE RESTRICT
);

CREATE INDEX bookings_user_id_idx    ON bookings (user_id);
CREATE INDEX bookings_slot_id_idx    ON bookings (slot_id);
CREATE INDEX bookings_status_idx     ON bookings (status);
CREATE INDEX bookings_created_at_idx ON bookings (created_at DESC);

CREATE TRIGGER bookings_updated_at
  BEFORE UPDATE ON bookings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- TABLE: payments
-- Paymob transaction records
-- ============================================================
CREATE TABLE payments (
  id                    UUID          NOT NULL DEFAULT gen_random_uuid(),
  booking_id            UUID          NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
  user_id               UUID          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  paymob_order_id       TEXT,
  paymob_transaction_id TEXT,
  paymob_payment_key    TEXT,
  amount                DECIMAL(10,2) NOT NULL,
  currency              VARCHAR(5)    NOT NULL DEFAULT 'EGP',
  status                payment_status NOT NULL DEFAULT 'pending',
  payment_method        VARCHAR(50),
  raw_webhook_payload   JSONB,
  processed_at          TIMESTAMPTZ,
  created_at            TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMPTZ   NOT NULL DEFAULT NOW(),

  CONSTRAINT payments_pkey PRIMARY KEY (id),
  CONSTRAINT payments_booking_fk FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE,
  CONSTRAINT payments_user_fk    FOREIGN KEY (user_id)    REFERENCES users(id)    ON DELETE CASCADE
);

CREATE UNIQUE INDEX payments_transaction_id_uidx ON payments (paymob_transaction_id) WHERE paymob_transaction_id IS NOT NULL;
CREATE INDEX payments_booking_id_idx  ON payments (booking_id);
CREATE INDEX payments_user_id_idx     ON payments (user_id);
CREATE INDEX payments_status_idx      ON payments (status);

CREATE TRIGGER payments_updated_at
  BEFORE UPDATE ON payments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- TABLE: sessions
-- Video session info generated after confirmed payment
-- ============================================================
CREATE TABLE sessions (
  id              UUID          NOT NULL DEFAULT gen_random_uuid(),
  booking_id      UUID          NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
  user_id         UUID          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  jitsi_room_name TEXT          NOT NULL,
  status          session_status NOT NULL DEFAULT 'scheduled',
  started_at      TIMESTAMPTZ,
  ended_at        TIMESTAMPTZ,
  admin_joined_at TIMESTAMPTZ,
  user_joined_at  TIMESTAMPTZ,
  notes           TEXT,
  created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),

  CONSTRAINT sessions_pkey PRIMARY KEY (id),
  CONSTRAINT sessions_booking_fk FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE,
  CONSTRAINT sessions_user_fk    FOREIGN KEY (user_id)    REFERENCES users(id)    ON DELETE CASCADE
);

CREATE UNIQUE INDEX sessions_booking_id_uidx  ON sessions (booking_id);
CREATE UNIQUE INDEX sessions_jitsi_room_uidx  ON sessions (jitsi_room_name);
CREATE INDEX        sessions_user_id_idx      ON sessions (user_id);
CREATE INDEX        sessions_status_idx       ON sessions (status);

CREATE TRIGGER sessions_updated_at
  BEFORE UPDATE ON sessions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
