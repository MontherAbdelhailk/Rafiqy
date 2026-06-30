'use strict';

/**
 * Database Migration Script
 * Runs schema.sql against the configured PostgreSQL database.
 * Usage: node src/database/migrate.js
 */

require('dotenv').config();
const fs = require('fs');
const path = require('path');
const { Pool } = require('pg');

const logger = require('../utils/logger');

async function migrate() {
  const pool = new Pool({
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT, 10) || 5432,
    database: process.env.DB_NAME || 'rafiq_db',
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD,
  });

  const client = await pool.connect();

  try {
    logger.info('🔄 Starting database migration...');

    const schemaPath = path.join(__dirname, 'schema.sql');
    const sql = fs.readFileSync(schemaPath, 'utf8');

    await client.query('BEGIN');
    await client.query(sql);
    await client.query('COMMIT');

    logger.info('✅ Migration completed successfully!');
    logger.info('   Tables: users, refresh_tokens, posts, post_loves, comments, comment_likes,');
    logger.info('           comment_replies, reels, reel_loves, reel_comments, reel_comment_likes,');
    logger.info('           reel_comment_replies, video_categories, video_subcategories, videos,');
    logger.info('           video_likes, video_views, admin_chat_messages, user_fcm_tokens,');
    logger.info('           consultation_slots, bookings, payments, sessions');
    logger.info('   ENUMs: user_status, marital_status, user_role, slot_state, booking_status,');
    logger.info('          payment_status, session_status');
    logger.info('   Triggers: users_updated_at_trigger, users_sync_full_name,');
    logger.info('             consultation_slots_updated_at, bookings_updated_at,');
    logger.info('             payments_updated_at, payments_user_consistency,');
    logger.info('             sessions_updated_at, sessions_user_consistency');
    logger.info('   Views: active_users');
  } catch (error) {
    await client.query('ROLLBACK');
    logger.error('❌ Migration failed:', error.message);
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

migrate().catch((err) => {
  logger.error('Migration error:', err);
  process.exit(1);
});
