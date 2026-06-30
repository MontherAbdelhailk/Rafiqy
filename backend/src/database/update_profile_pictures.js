'use strict';

/**
 * Migration Script: Update Profile Pictures
 * Sets DEFAULT value for users.profile_picture and updates existing records.
 * Usage: node src/database/update_profile_pictures.js
 */

require('dotenv').config();
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
    logger.info('🔄 Starting profile picture database migration...');

    await client.query('BEGIN');

    // 1. Alter default value for profile_picture column
    await client.query(`
      ALTER TABLE users 
      ALTER COLUMN profile_picture SET DEFAULT '/uploads/default_user.png'
    `);
    logger.info('  ✓ Altered users.profile_picture column default to "/uploads/default_user.png"');

    // 2. Update existing users: Admin gets the logo
    const adminUpdate = await client.query(`
      UPDATE users
      SET profile_picture = '/uploads/admin_logo.svg'
      WHERE role = 'admin' OR username = 'Rafiqy'
    `);
    logger.info(`  ✓ Updated ${adminUpdate.rowCount} admin user(s) to logo avatar.`);

    // 3. Update existing users: Others get the default user image if null
    const userUpdate = await client.query(`
      UPDATE users
      SET profile_picture = '/uploads/default_user.png'
      WHERE (role != 'admin' AND username != 'Rafiqy') 
        AND (profile_picture IS NULL OR profile_picture = '')
    `);
    logger.info(`  ✓ Updated ${userUpdate.rowCount} user(s) to default user avatar.`);

    await client.query('COMMIT');
    logger.info('✅ Profile picture migration completed successfully!');
  } catch (error) {
    await client.query('ROLLBACK');
    logger.error('❌ Profile picture migration failed:', error.message);
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
