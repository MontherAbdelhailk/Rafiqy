'use strict';

const { query } = require('../database/connection');

class PaymentModel {
  /**
   * Create a payment record (pending) when initiating Paymob payment
   */
  static async create({ bookingId, userId, amount, currency = 'EGP' }) {
    const result = await query(
      `INSERT INTO payments (booking_id, user_id, amount, currency, status)
       VALUES ($1, $2, $3, $4, 'pending')
       RETURNING *`,
      [bookingId, userId, amount, currency]
    );
    return result.rows[0];
  }

  /**
   * Update payment with Paymob order and key info
   */
  static async updatePaymobInfo(id, { paymobOrderId, paymobTransactionId, paymobPaymentKey }) {
    const fields = [];
    const values = [];
    let paramIdx = 1;

    if (paymobOrderId !== undefined)      { fields.push(`paymob_order_id = $${paramIdx++}`);       values.push(paymobOrderId); }
    if (paymobTransactionId !== undefined){ fields.push(`paymob_transaction_id = $${paramIdx++}`); values.push(paymobTransactionId); }
    if (paymobPaymentKey !== undefined)   { fields.push(`paymob_payment_key = $${paramIdx++}`);    values.push(paymobPaymentKey); }

    if (fields.length === 0) return null;

    values.push(id);
    const result = await query(
      `UPDATE payments SET ${fields.join(', ')} WHERE id = $${paramIdx} RETURNING *`,
      values
    );
    return result.rows[0] || null;
  }

  /**
   * Mark payment as successful
   */
  static async markSuccess(id, { transactionId, paymentMethod, rawPayload } = {}) {
    const result = await query(
      `UPDATE payments
       SET status = 'success',
           paymob_transaction_id = COALESCE($2, paymob_transaction_id),
           payment_method = COALESCE($3, payment_method),
           raw_webhook_payload = COALESCE($4, raw_webhook_payload),
           processed_at = NOW()
       WHERE id = $1
       RETURNING *`,
      [id, transactionId || null, paymentMethod || null, rawPayload ? JSON.stringify(rawPayload) : null]
    );
    return result.rows[0] || null;
  }

  /**
   * Mark payment as failed
   */
  static async markFailed(id, { rawPayload } = {}) {
    const result = await query(
      `UPDATE payments
       SET status = 'failed',
           raw_webhook_payload = COALESCE($2, raw_webhook_payload),
           processed_at = NOW()
       WHERE id = $1
       RETURNING *`,
      [id, rawPayload ? JSON.stringify(rawPayload) : null]
    );
    return result.rows[0] || null;
  }

  /**
   * Find payment by booking ID
   */
  static async findByBookingId(bookingId) {
    const result = await query(
      'SELECT * FROM payments WHERE booking_id = $1 ORDER BY created_at DESC LIMIT 1',
      [bookingId]
    );
    return result.rows[0] || null;
  }

  /**
   * Find payment by Paymob transaction ID (for webhook deduplication)
   */
  static async findByTransactionId(transactionId) {
    const result = await query(
      'SELECT * FROM payments WHERE paymob_transaction_id = $1',
      [transactionId]
    );
    return result.rows[0] || null;
  }

  /**
   * Find the latest pending payment for a booking
   */
  static async findPendingByBookingId(bookingId) {
    const result = await query(
      `SELECT * FROM payments
       WHERE booking_id = $1 AND status = 'pending'
       ORDER BY created_at DESC LIMIT 1`,
      [bookingId]
    );
    return result.rows[0] || null;
  }

  /**
   * Get payment by booking for a specific user (ownership check)
   */
  static async findByBookingAndUser(bookingId, userId) {
    const result = await query(
      'SELECT * FROM payments WHERE booking_id = $1 AND user_id = $2 ORDER BY created_at DESC LIMIT 1',
      [bookingId, userId]
    );
    return result.rows[0] || null;
  }
}

module.exports = PaymentModel;
