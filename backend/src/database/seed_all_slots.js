'use strict';
const path = require('path');
const backendDir = 'c:/Users/engmo/OneDrive/Desktop/Rafeeqy/rafiq/backend';

// Require dotenv
require(path.join(backendDir, 'node_modules/dotenv')).config({ path: path.join(backendDir, '.env') });

const { query, pool } = require(path.join(backendDir, 'src/database/connection'));

async function seedAllSlots() {
  try {
    // 1. Get Admin User ID
    const userRes = await query("SELECT id, username FROM users WHERE role = 'admin' LIMIT 1");
    if (userRes.rows.length === 0) {
      console.error('No admin user found in database. Please register/seed users first.');
      return;
    }
    const adminId = userRes.rows[0].id;
    console.log(`Found admin user: ${userRes.rows[0].username} with ID: ${adminId}`);

    // 2. Delete existing unbooked slots to avoid duplicates
    console.log('Cleaning up existing unbooked slots...');
    const delRes = await query('DELETE FROM consultation_slots WHERE is_booked = FALSE');
    console.log(`Deleted ${delRes.rowCount} unbooked slots.`);

    // 3. Define timezone offset for Egypt (UTC+3)
    const EGYPT_OFFSET = 3;

    // Define date range: from June 24, 2026 to December 31, 2026
    const startDate = new Date('2026-06-24T00:00:00Z');
    const endDate = new Date('2026-12-31T23:59:59Z');

    let current = new Date(startDate);
    const slots = [];

    // Loop through each day
    while (current <= endDate) {
      // Loop through hours from 9 AM to 11 PM Egypt local time
      for (let localHour = 9; localHour <= 23; localHour++) {
        // Create startTime in UTC
        // Egypt time: UTC+3. So UTC hour = localHour - 3
        const utcHour = localHour - EGYPT_OFFSET;

        const startTime = new Date(current);
        startTime.setUTCHours(utcHour, 0, 0, 0);

        // End time is 45 minutes later
        const endTime = new Date(startTime);
        endTime.setUTCMinutes(45);

        // If it is today, only insert future slots
        if (current.toDateString() === new Date().toDateString()) {
          if (startTime < new Date()) {
            continue; // Skip past hours for today
          }
        }

        slots.push({
          startTime: startTime.toISOString(),
          endTime: endTime.toISOString(),
          durationMins: 45,
          price: 550.00,
          notes: '1-on-1 Consultation Session',
        });
      }

      // Move to next day
      current.setUTCDate(current.getUTCDate() + 1);
    }

    console.log(`Prepared ${slots.length} slots to insert.`);

    // Bulk insert in batches of 500 to optimize performance
    const BATCH_SIZE = 500;
    for (let i = 0; i < slots.length; i += BATCH_SIZE) {
      const batch = slots.slice(i, i + BATCH_SIZE);
      const values = [];
      const placeholders = [];
      let paramIdx = 1;

      for (const slot of batch) {
        placeholders.push(
          `($${paramIdx++}, $${paramIdx++}, $${paramIdx++}, $${paramIdx++}, $${paramIdx++}, $${paramIdx++}, TRUE, FALSE)`
        );
        values.push(
          slot.startTime,
          slot.endTime,
          slot.durationMins,
          slot.price,
          slot.notes,
          adminId
        );
      }

      const sql = `
        INSERT INTO consultation_slots 
          (start_time, end_time, duration_mins, price, notes, created_by, is_available, is_booked)
        VALUES ${placeholders.join(', ')}
      `;

      await query(sql, values);
      console.log(`Inserted batch ${Math.floor(i / BATCH_SIZE) + 1}/${Math.ceil(slots.length / BATCH_SIZE)} (${batch.length} slots)`);
    }

    const countRes = await query('SELECT COUNT(*) FROM consultation_slots');
    console.log(`Successfully completed! Total slots now in database: ${countRes.rows[0].count}`);

  } catch (err) {
    console.error('Error seeding slots:', err);
  } finally {
    await pool.end();
  }
}

seedAllSlots();
