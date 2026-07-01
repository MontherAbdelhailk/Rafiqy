'use strict';
const path = require('path');

// Require dotenv
require('dotenv').config({ path: path.join(__dirname, '../../.env') });

const { query, pool } = require('./connection');

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
    const delRes = await query("DELETE FROM consultation_slots WHERE slot_state NOT IN ('reserved', 'booked')");
    console.log(`Deleted ${delRes.rowCount} unbooked slots.`);

    // 3. Fetch all booked slot start times to prevent generating overlapping available slots
    console.log('Fetching existing booked slots...');
    const bookedRes = await query("SELECT start_time FROM consultation_slots WHERE slot_state IN ('reserved', 'booked')");
    const bookedStartTimes = new Set(bookedRes.rows.map(r => new Date(r.start_time).toISOString()));
    console.log(`Found ${bookedStartTimes.size} existing booked slots.`);

    // 4. Define timezone offset for Egypt (UTC+3)
    const EGYPT_OFFSET = 3;

    // Define date range: from today (at midnight UTC) to 200 days in the future
    const startDate = new Date();
    startDate.setUTCHours(0, 0, 0, 0);
    const endDate = new Date(startDate);
    endDate.setUTCDate(startDate.getUTCDate() + 200);

    let current = new Date(startDate);
    const slots = [];

    // Current time in UTC — used for the today-filter below
    const nowUTC = new Date();

    // Loop through each day
    while (current <= endDate) {
      // Loop through hours from 9 AM to 10 PM Egypt local time.
      // The last slot STARTS at 22:00 local (10 PM) and ends at 23:00 local (11 PM).
      // Egypt is UTC+3, so local hour 9 = UTC hour 6, local hour 22 = UTC hour 19.
      for (let localHour = 9; localHour <= 22; localHour++) {
        const utcHour = localHour - EGYPT_OFFSET; // Egypt UTC+3

        // Build start time in UTC
        const startTime = new Date(current);
        startTime.setUTCHours(utcHour, 0, 0, 0);

        // Skip if this slot is already booked
        if (bookedStartTimes.has(startTime.toISOString())) {
          continue;
        }

        // Build end time = start + exactly 45 minutes
        const endTime = new Date(startTime.getTime() + 45 * 60 * 1000);

        // Skip any slot whose start time is already in the past (pure UTC comparison).
        // This correctly handles today without relying on toDateString() local/UTC mismatch.
        if (startTime <= nowUTC) {
          continue;
        }

        slots.push({
          startTime: startTime.toISOString(),
          endTime: endTime.toISOString(),
          durationMins: 45,
          price: 750.00,
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
          `($${paramIdx++}, $${paramIdx++}, $${paramIdx++}, $${paramIdx++}, $${paramIdx++}, $${paramIdx++}, 'available'::slot_state)`
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
          (start_time, end_time, duration_mins, price, notes, created_by, slot_state)
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
