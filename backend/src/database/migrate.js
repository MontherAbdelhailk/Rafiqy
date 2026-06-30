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
    logger.info('   Tables created: users, refresh_tokens');
    logger.info('   Indexes created: username, email, status, created_at, token_hash');
    logger.info('   Triggers created: users_updated_at_trigger');
    logger.info('   Views created: active_users');
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
