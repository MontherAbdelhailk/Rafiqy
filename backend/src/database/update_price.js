'use strict';

const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5432'),
  database: process.env.DB_NAME || 'rafiq_db',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || '123',
});

async function run() {
  try {
    console.log('Connecting to database...');
    const res = await pool.query("UPDATE consultation_slots SET price = 750.00, duration_mins = 45, end_time = start_time + INTERVAL '45 minutes';");
    console.log(`Successfully updated ${res.rowCount} slots to 750.00 EGP and 45 mins.`);
  } catch (err) {
    console.error('Error running update:', err);
  } finally {
    await pool.end();
  }
}

run();
