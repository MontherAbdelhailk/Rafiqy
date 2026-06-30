'use strict';

const { query, getClient } = require('../database/connection');

class SlotModel {
  /**
   * Get all available (non-booked) slots from today onwards
   */
  static async getAvailableSlots({ from, to } = {}) {
    const fromDate = from || new Date().toISOString();
    const params = [fromDate];
    let sql = `
      SELECT
        id, start_time, end_time, duration_mins, price,
        is_available, is_booked, notes, created_at
      FROM consultation_slots
      WHERE is_available = TRUE
        AND is_booked = FALSE
        AND start_time >= $1
    `;

    if (to) {
      params.push(to);
      sql += ` AND start_time <= $${params.length}`;
    }

    sql += ' ORDER BY start_time ASC';

    const result = await query(sql, params);
    return result.rows;
  }

  /**
   * Get a specific slot by ID
   */
  static async findById(id) {
    const result = await query(
      'SELECT * FROM consultation_slots WHERE id = $1',
      [id]
    );
    return result.rows[0] || null;
  }

  /**
   * Create a new slot (Admin only)
   */
  static async create({ startTime, endTime, durationMins, price, notes, createdBy }) {
    const result = await query(
      `INSERT INTO consultation_slots (start_time, end_time, duration_mins, price, notes, created_by)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [startTime, endTime, durationMins || 60, price || 50.00, notes || null, createdBy]
    );
    return result.rows[0];
  }

  /**
   * Update a slot (Admin only)
   */
  static async update(id, { startTime, endTime, durationMins, price, isAvailable, notes }) {
    const fields = [];
    const values = [];
    let paramIdx = 1;

    if (startTime !== undefined)   { fields.push(`start_time = $${paramIdx++}`);    values.push(startTime); }
    if (endTime !== undefined)     { fields.push(`end_time = $${paramIdx++}`);      values.push(endTime); }
    if (durationMins !== undefined){ fields.push(`duration_mins = $${paramIdx++}`); values.push(durationMins); }
    if (price !== undefined)       { fields.push(`price = $${paramIdx++}`);         values.push(price); }
    if (isAvailable !== undefined) { fields.push(`is_available = $${paramIdx++}`);  values.push(isAvailable); }
    if (notes !== undefined)       { fields.push(`notes = $${paramIdx++}`);         values.push(notes); }

    if (fields.length === 0) return this.findById(id);

    values.push(id);
    const result = await query(
      `UPDATE consultation_slots SET ${fields.join(', ')} WHERE id = $${paramIdx} RETURNING *`,
      values
    );
    return result.rows[0] || null;
  }

  /**
   * Mark a slot as booked / un-booked
   */
  static async markBooked(id, booked = true) {
    const result = await query(
      'UPDATE consultation_slots SET is_booked = $1 WHERE id = $2 RETURNING *',
      [booked, id]
    );
    return result.rows[0] || null;
  }

  /**
   * Delete a slot — only if not booked
   */
  static async delete(id) {
    const result = await query(
      'DELETE FROM consultation_slots WHERE id = $1 AND is_booked = FALSE RETURNING id',
      [id]
    );
    return result.rows[0] || null;
  }

  /**
   * Get all slots (Admin view, includes booked)
   */
  static async getAllAdmin({ from, to, page = 1, limit = 50 } = {}) {
    const offset = (page - 1) * limit;
    const params = [];
    const conditions = [];

    if (from)  { params.push(from); conditions.push(`start_time >= $${params.length}`); }
    if (to)    { params.push(to);   conditions.push(`start_time <= $${params.length}`); }

    const whereClause = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';

    params.push(limit, offset);
    const result = await query(
      `SELECT *, COUNT(*) OVER() AS total_count
       FROM consultation_slots
       ${whereClause}
       ORDER BY start_time ASC
       LIMIT $${params.length - 1} OFFSET $${params.length}`,
      params
    );

    const totalCount = parseInt(result.rows[0]?.total_count || 0);
    return {
      slots: result.rows.map(({ total_count, ...slot }) => slot),
      pagination: {
        total: totalCount,
        page: parseInt(page),
        limit: parseInt(limit),
        totalPages: Math.ceil(totalCount / limit),
      },
    };
  }
}

module.exports = SlotModel;
