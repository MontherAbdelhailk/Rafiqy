'use strict';

const { query } = require('../database/connection');

class SessionModel {
  /**
   * Create a session record after booking is confirmed
   */
  static async create({ bookingId, userId, jitsiRoomName }) {
    const result = await query(
      `INSERT INTO sessions (booking_id, user_id, jitsi_room_name, status)
       VALUES ($1, $2, $3, 'scheduled')
       RETURNING *`,
      [bookingId, userId, jitsiRoomName]
    );
    return result.rows[0];
  }

  /**
   * Find session by ID with booking and user details
   */
  static async findById(id) {
    const result = await query(
      `SELECT
        s.*,
        b.status as booking_status, b.amount, b.notes as booking_notes,
        b.confirmed_at, b.cancelled_at,
        cs.start_time, cs.end_time, cs.duration_mins,
        u.full_name as user_full_name, u.username, u.email as user_email,
        u.profile_picture as user_profile_picture, u.phone_number as user_phone,
        p.paymob_transaction_id, p.status as payment_status,
        p.payment_method, p.amount as payment_amount, p.processed_at
       FROM sessions s
       JOIN bookings b ON s.booking_id = b.id
       JOIN consultation_slots cs ON b.slot_id = cs.id
       JOIN users u ON s.user_id = u.id
       LEFT JOIN payments p ON p.booking_id = b.id
       WHERE s.id = $1`,
      [id]
    );
    return result.rows[0] || null;
  }

  /**
   * Find session by booking ID
   */
  static async findByBookingId(bookingId) {
    const result = await query(
      `SELECT
        s.*,
        cs.start_time, cs.end_time, cs.duration_mins,
        b.status as booking_status
       FROM sessions s
       JOIN bookings b ON s.booking_id = b.id
       JOIN consultation_slots cs ON b.slot_id = cs.id
       WHERE s.booking_id = $1`,
      [bookingId]
    );
    return result.rows[0] || null;
  }

  /**
   * Find session by Jitsi room name
   */
  static async findByRoomName(roomName) {
    const result = await query(
      'SELECT * FROM sessions WHERE jitsi_room_name = $1',
      [roomName]
    );
    return result.rows[0] || null;
  }

  /**
   * Get all sessions for a user
   */
  static async findByUserId(userId, { status, page = 1, limit = 20 } = {}) {
    const offset = (page - 1) * limit;
    const params = [userId];
    let statusClause = '';
    if (status) {
      params.push(status);
      statusClause = `AND s.status = $${params.length}`;
    }

    params.push(limit, offset);
    const result = await query(
      `SELECT
        s.id, s.jitsi_room_name, s.status, s.started_at, s.ended_at, s.created_at,
        b.id as booking_id, b.status as booking_status, b.amount,
        cs.start_time, cs.end_time, cs.duration_mins
       FROM sessions s
       JOIN bookings b ON s.booking_id = b.id
       JOIN consultation_slots cs ON b.slot_id = cs.id
       WHERE s.user_id = $1 ${statusClause}
       ORDER BY cs.start_time DESC
       LIMIT $${params.length - 1} OFFSET $${params.length}`,
      params
    );
    return result.rows;
  }

  /**
   * Get all sessions (Admin view)
   */
  static async findAll({ status, search, page = 1, limit = 20 } = {}) {
    const offset = (page - 1) * limit;
    const params = [];
    const conditions = [];

    if (status) {
      params.push(status);
      conditions.push(`s.status = $${params.length}`);
    }

    if (search) {
      params.push(`%${search}%`);
      conditions.push(`(u.full_name ILIKE $${params.length} OR u.username ILIKE $${params.length})`);
    }

    const whereClause = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';

    params.push(limit, offset);
    const result = await query(
      `SELECT
        s.id, s.jitsi_room_name, s.status, s.started_at, s.ended_at, s.created_at,
        s.admin_joined_at, s.user_joined_at,
        b.id as booking_id, b.status as booking_status, b.amount, b.confirmed_at, b.created_at as booking_created_at,
        cs.start_time, cs.end_time, cs.duration_mins,
        u.id as user_id, u.full_name as user_full_name, u.username, u.email as user_email,
        u.profile_picture as user_profile_picture,
        p.paymob_transaction_id, p.status as payment_status, p.payment_method,
        COUNT(*) OVER() AS total_count
       FROM sessions s
       JOIN bookings b ON s.booking_id = b.id
       JOIN consultation_slots cs ON b.slot_id = cs.id
       JOIN users u ON s.user_id = u.id
       LEFT JOIN payments p ON p.booking_id = b.id
       ${whereClause}
       ORDER BY cs.start_time DESC
       LIMIT $${params.length - 1} OFFSET $${params.length}`,
      params
    );

    const totalCount = parseInt(result.rows[0]?.total_count || 0);
    return {
      sessions: result.rows.map(({ total_count, ...s }) => s),
      pagination: {
        total: totalCount,
        page: parseInt(page),
        limit: parseInt(limit),
        totalPages: Math.ceil(totalCount / limit),
      },
    };
  }

  /**
   * Update session status
   */
  static async updateStatus(id, status, extra = {}) {
    const fields = [`status = $2`];
    const values = [id, status];
    let paramIdx = 3;

    if (extra.startedAt !== undefined)    { fields.push(`started_at = $${paramIdx++}`);     values.push(extra.startedAt); }
    if (extra.endedAt !== undefined)      { fields.push(`ended_at = $${paramIdx++}`);       values.push(extra.endedAt); }
    if (extra.adminJoinedAt !== undefined){ fields.push(`admin_joined_at = $${paramIdx++}`); values.push(extra.adminJoinedAt); }
    if (extra.userJoinedAt !== undefined) { fields.push(`user_joined_at = $${paramIdx++}`); values.push(extra.userJoinedAt); }

    const result = await query(
      `UPDATE sessions SET ${fields.join(', ')} WHERE id = $1 RETURNING *`,
      values
    );
    return result.rows[0] || null;
  }

  /**
   * Record user joining the session
   */
  static async recordUserJoin(id) {
    const result = await query(
      `UPDATE sessions SET user_joined_at = NOW(), status = CASE WHEN status = 'scheduled' THEN 'active' ELSE status END
       WHERE id = $1 RETURNING *`,
      [id]
    );
    return result.rows[0] || null;
  }

  /**
   * Record admin joining the session
   */
  static async recordAdminJoin(id) {
    const result = await query(
      `UPDATE sessions SET admin_joined_at = NOW(), status = CASE WHEN status = 'scheduled' THEN 'active' ELSE status END
       WHERE id = $1 RETURNING *`,
      [id]
    );
    return result.rows[0] || null;
  }

  /**
   * Complete a session
   */
  static async complete(id) {
    const result = await query(
      `UPDATE sessions SET status = 'completed', ended_at = NOW()
       WHERE id = $1 RETURNING *`,
      [id]
    );
    return result.rows[0] || null;
  }
}

module.exports = SessionModel;
