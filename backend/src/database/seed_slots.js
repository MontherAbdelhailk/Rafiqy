'use strict';
const path = require('path');
const backendDir = 'c:/Users/engmo/OneDrive/Desktop/Rafeeqy/rafiq/backend';

// Require dotenv from backend's node_modules
require(path.join(backendDir, 'node_modules/dotenv')).config({ path: path.join(backendDir, '.env') });

const { query, pool } = require(path.join(backendDir, 'src/database/connection'));

async function seedSlots() {
  try {
    // 1. Get Admin User ID
    const userRes = await query("SELECT id, username FROM users WHERE role = 'admin' LIMIT 1");
    if (userRes.rows.length === 0) {
      console.error('No admin user found in database. Please register/seed users first.');
      return;
    }
    const adminId = userRes.rows[0].id;
    console.log(`Found admin user: ${userRes.rows[0].username} with ID: ${adminId}`);

    // 2. Generate times in UTC
    // We want Egypt time (local: UTC+3)
    // Egypt 10:00 AM is UTC 07:00 AM
    // Egypt 02:00 PM is UTC 11:00 AM
    // Egypt 06:00 PM is UTC 03:00 PM
    const today = new Date();
    
    // Day helper
    const getFutureDate = (daysAhead, localHour) => {
      const d = new Date(today);
      d.setDate(today.getDate() + daysAhead);
      // set hours in Egypt time (UTC+3) -> convert to UTC
      const utcHour = localHour - 3;
      d.setUTCHours(utcHour, 0, 0, 0);
      return d;
    };

    const slotsToCreate = [
      {
        startTime: getFutureDate(1, 9), // Tomorrow 9:00 AM Egypt (6:00 AM UTC)
        endTime: getFutureDate(1, 10),  // Tomorrow 10:00 AM Egypt
        notes: 'Child behavioral counseling session',
        price: 450.00
      },
      {
        startTime: getFutureDate(1, 11), // Tomorrow 11:00 AM Egypt
        endTime: getFutureDate(1, 12),  // Tomorrow 12:00 PM Egypt
        notes: 'Parenting style consultation',
        price: 450.00
      },
      {
        startTime: getFutureDate(1, 15), // Tomorrow 3:00 PM Egypt
        endTime: getFutureDate(1, 16),  // Tomorrow 4:00 PM Egypt
        notes: 'Speech delay assessment support',
        price: 550.00
      },
      {
        startTime: getFutureDate(2, 10), // Day after tomorrow 10:00 AM Egypt
        endTime: getFutureDate(2, 11),  // Day after tomorrow 11:00 AM Egypt
        notes: 'General advice session',
        price: 450.00
      },
      {
        startTime: getFutureDate(2, 18), // Day after tomorrow 6:00 PM Egypt
        endTime: getFutureDate(2, 19),  // Day after tomorrow 7:00 PM Egypt
        notes: 'School readiness guidance',
        price: 600.00
      }
    ];

    console.log('Inserting slots...');
    for (const slot of slotsToCreate) {
      await query(
        `INSERT INTO consultation_slots (start_time, end_time, duration_mins, price, notes, created_by, is_available, is_booked)
         VALUES ($1, $2, $3, $4, $5, $6, TRUE, FALSE)`,
        [
          slot.startTime.toISOString(),
          slot.endTime.toISOString(),
          60,
          slot.price,
          slot.notes,
          adminId
        ]
      );
      console.log(`Inserted slot starting at Egypt local: ${slot.startTime.getUTCHours() + 3}:00 (${slot.startTime.toISOString()})`);
    }

    const countRes = await query('SELECT COUNT(*) FROM consultation_slots');
    console.log(`Total slots now in database: ${countRes.rows[0].count}`);

  } catch (err) {
    console.error(err);
  } finally {
    await pool.end();
  }
}

seedSlots();
