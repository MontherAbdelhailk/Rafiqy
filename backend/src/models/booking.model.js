'use strict';

const { query, getClient } = require('../database/connection');

class BookingModel {
  /**
   * Create a new booking (status: pending_payment)
   */
  static async create({ userId, slotId, amount, notes }) {
    const client = await getClient();
    try {
      await client.query('BEGIN');

      // Lock the slot to prevent double booking
      const slotCheck = await client.query(
        'SELECT * FROM consultation_slots WHERE id = $1 AND is_available = TRUE AND is_booked = FALSE FOR UPDATE',
        [slotId]
      );

      if (slotCheck.rows.length === 0) {
        await client.query('ROLLBACK');
        return null; // Slot not available
      }

      const slot = slotCheck.rows[0];

      // Create the booking
      const bookingResult = await client.query(
        `INSERT INTO bookings (user_id, slot_id, amount, notes, status)
         VALUES ($1, $2, $3, $4, 'pending_payment')
         RETURNING *`,
        [userId, slotId, amount || slot.price, notes || null]
      );

      // Mark slot as booked (reserved but not yet confirmed)
      await client.query(
        'UPDATE consultation_slots SET is_booked = TRUE WHERE id = $1',
        [slotId]
      );

      await client.query('COMMIT');
      return bookingResult.rows[0];
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }

  /**
   * Find booking by ID with slot and user details
   */
  static async findById(id) {
    const result = await query(
      `SELECT
        b.*,
        cs.start_time, cs.end_time, cs.duration_mins, cs.price as slot_price,
        u.full_name as user_full_name, u.username, u.email as user_email,
        u.phone_number as user_phone, u.profile_picture as user_profile_picture,
        s.id as session_id, s.jitsi_room_name, s.status as session_status,
        p.id as payment_id, p.paymob_transaction_id, p.status as payment_status,
        p.payment_method, p.processed_at as payment_processed_at
       FROM bookings b
       JOIN consultation_slots cs ON b.slot_id = cs.id
       JOIN users u ON b.user_id = u.id
       LEFT JOIN sessions s ON s.booking_id = b.id
       LEFT JOIN payments p ON p.booking_id = b.id
       WHERE b.id = $1`,
      [id]
    );
    return result.rows[0] || null;
  }

  /**
   * Get all bookings for a user
   */
  static async findByUserId(userId, { status, page = 1, limit = 20 } = {}) {
    const offset = (page - 1) * limit;
    const params = [userId];
    let statusClause = '';
    if (status) {
      params.push(status);
      statusClause = `AND b.status = $${params.length}`;
    }

    params.push(limit, offset);
    const result = await query(
      `SELECT
        b.id, b.status, b.amount, b.notes, b.created_at, b.confirmed_at, b.cancelled_at, b.completed_at,
        cs.start_time, cs.end_time, cs.duration_mins,
        s.id as session_id, s.jitsi_room_name, s.status as session_status,
        p.status as payment_status, p.payment_method
       FROM bookings b
       JOIN consultation_slots cs ON b.slot_id = cs.id
       LEFT JOIN sessions s ON s.booking_id = b.id
       LEFT JOIN payments p ON p.booking_id = b.id
       WHERE b.user_id = $1 ${statusClause}
       ORDER BY b.created_at DESC
       LIMIT $${params.length - 1} OFFSET $${params.length}`,
      params
    );
    return result.rows;
  }

  /**
   * Get all bookings (Admin view) with search and filters
   */
  static async findAll({ status, search, page = 1, limit = 20, sortBy = 'created_at', sortDir = 'DESC' } = {}) {
    const offset = (page - 1) * limit;
    const params = [];
    const conditions = [];

    if (status) {
      params.push(status);
      conditions.push(`b.status = $${params.length}`);
    }

    if (search) {
      params.push(`%${search}%`);
      conditions.push(`(u.full_name ILIKE $${params.length} OR u.username ILIKE $${params.length} OR u.email ILIKE $${params.length})`);
    }

    const whereClause = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
    const validSortCols = { created_at: 'b.created_at', start_time: 'cs.start_time', status: 'b.status', amount: 'b.amount' };
    const sortColumn = validSortCols[sortBy] || 'b.created_at';
    const sortDirection = sortDir.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';

    params.push(limit, offset);
    const result = await query(
      `SELECT
        b.id, b.status, b.amount, b.notes, b.created_at, b.confirmed_at, b.cancelled_at, b.completed_at,
        b.cancellation_reason,
        cs.start_time, cs.end_time, cs.duration_mins,
        u.id as user_id, u.full_name as user_full_name, u.username, u.email as user_email,
        u.phone_number as user_phone, u.profile_picture as user_profile_picture,
        s.id as session_id, s.jitsi_room_name, s.status as session_status,
        p.id as payment_id, p.paymob_transaction_id, p.status as payment_status,
        p.payment_method, p.processed_at as payment_processed_at,
        COUNT(*) OVER() AS total_count
       FROM bookings b
       JOIN consultation_slots cs ON b.slot_id = cs.id
       JOIN users u ON b.user_id = u.id
       LEFT JOIN sessions s ON s.booking_id = b.id
       LEFT JOIN payments p ON p.booking_id = b.id
       ${whereClause}
       ORDER BY ${sortColumn} ${sortDirection}
       LIMIT $${params.length - 1} OFFSET $${params.length}`,
      params
    );

    const totalCount = parseInt(result.rows[0]?.total_count || 0);
    return {
      bookings: result.rows.map(({ total_count, ...b }) => b),
      pagination: {
        total: totalCount,
        page: parseInt(page),
        limit: parseInt(limit),
        totalPages: Math.ceil(totalCount / limit),
      },
    };
  }

  /**
   * Confirm a booking after payment success.
   * Also marks the slot as permanently unavailable (is_available = FALSE)
   * so no further bookings or admin interference can touch it.
   */
  static async confirm(id) {
    const client = await getClient();
    try {
      await client.query('BEGIN');

      const bookingResult = await client.query(
        `UPDATE bookings SET status = 'confirmed', confirmed_at = NOW()
         WHERE id = $1 AND status = 'pending_payment'
         RETURNING *`,
        [id]
      );

      if (bookingResult.rows.length === 0) {
        await client.query('ROLLBACK');
        return null;
      }

      const booking = bookingResult.rows[0];

      // Permanently lock the slot: is_available = FALSE prevents any future
      // booking attempt or admin re-opening of this slot while it is confirmed.
      await client.query(
        `UPDATE consultation_slots
         SET is_available = FALSE, is_booked = TRUE
         WHERE id = $1`,
        [booking.slot_id]
      );

      await client.query('COMMIT');
      return booking;
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }

  /**
   * Cancel a booking
   */
  static async cancel(id, { reason, releasesSlot = true } = {}) {
    const client = await getClient();
    try {
      await client.query('BEGIN');

      const bookingResult = await client.query(
        `UPDATE bookings SET status = 'cancelled', cancelled_at = NOW(), cancellation_reason = $2
         WHERE id = $1 AND status IN ('pending_payment', 'confirmed')
         RETURNING *`,
        [id, reason || null]
      );

      if (bookingResult.rows.length === 0) {
        await client.query('ROLLBACK');
        return null;
      }

      const booking = bookingResult.rows[0];

      // Release the slot back to available
      if (releasesSlot) {
        await client.query(
          'UPDATE consultation_slots SET is_booked = FALSE WHERE id = $1',
          [booking.slot_id]
        );
      }

      await client.query('COMMIT');
      return booking;
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }

  /**
   * Admin Hard Delete: permanently removes a booking and all dependent records.
   *
   * Deletion order (inside a single transaction):
   *  1. Verify the booking exists.
   *  2. Release the time slot → is_booked = FALSE, is_available = TRUE
   *     (makes the slot bookable again for future users).
   *  3. DELETE the booking row.
   *     - sessions     are removed automatically (ON DELETE CASCADE).
   *     - payments     are removed automatically (ON DELETE CASCADE).
   *     - Jitsi rooms are ephemeral (no server-side cleanup needed;
   *       the room expires when unused).
   *
   * Returns the deleted booking row, or null if not found.
   */
  static async adminDelete(id) {
    const client = await getClient();
    try {
      await client.query('BEGIN');

      // Fetch the booking so we can read slot_id and return data to the caller
      const fetchResult = await client.query(
        'SELECT * FROM bookings WHERE id = $1',
        [id]
      );

      if (fetchResult.rows.length === 0) {
        await client.query('ROLLBACK');
        return null; // Not found
      }

      const booking = fetchResult.rows[0];

      // Release the slot back to the available pool
      await client.query(
        `UPDATE consultation_slots
         SET is_booked = FALSE, is_available = TRUE
         WHERE id = $1`,
        [booking.slot_id]
      );

      // Hard-delete the booking; Postgres cascades to sessions + payments
      await client.query('DELETE FROM bookings WHERE id = $1', [id]);

      await client.query('COMMIT');
      return booking; // Return the deleted record for the response body
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }

  /**
   * Mark a booking as completed (Admin)
   */
  static async complete(id) {
    const result = await query(
      `UPDATE bookings SET status = 'completed', completed_at = NOW()
       WHERE id = $1 AND status = 'confirmed'
       RETURNING *`,
      [id]
    );
    return result.rows[0] || null;
  }

  /**
   * Get upcoming bookings (for reminders)
   */
  static async getUpcoming(withinMinutes = 60) {
    const result = await query(
      `SELECT
        b.id, b.user_id, b.status,
        cs.start_time, cs.end_time,
        u.full_name as user_full_name, u.email as user_email
       FROM bookings b
       JOIN consultation_slots cs ON b.slot_id = cs.id
       JOIN users u ON b.user_id = u.id
       WHERE b.status = 'confirmed'
         AND cs.start_time > NOW()
         AND cs.start_time <= NOW() + INTERVAL '${withinMinutes} minutes'
       ORDER BY cs.start_time ASC`
    );
    return result.rows;
  }
}

module.exports = BookingModel;
