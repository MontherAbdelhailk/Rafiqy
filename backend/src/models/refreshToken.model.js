'use strict';

const crypto = require('crypto');
const { query } = require('../database/connection');

class RefreshTokenModel {
  /**
   * Hash a plain token for secure storage
   */
  static hashToken(token) {
    return crypto.createHash('sha256').update(token).digest('hex');
  }

  /**
   * Store a new refresh token
   */
  static async create({ user_id, token, expiresAt, userAgent, ipAddress }) {
    const token_hash = this.hashToken(token);
    const sql = `
      INSERT INTO refresh_tokens (user_id, token_hash, expires_at, user_agent, ip_address)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING id, user_id, expires_at, created_at
    `;
    const result = await query(sql, [
      user_id,
      token_hash,
      expiresAt,
      userAgent || null,
      ipAddress || null,
    ]);
    return result.rows[0];
  }

  /**
   * Find a valid (non-expired, non-revoked) refresh token record
   */
  static async findValid(token) {
    const token_hash = this.hashToken(token);
    const sql = `
      SELECT rt.id, rt.user_id, rt.expires_at, rt.revoked_at,
             u.status AS user_status
      FROM refresh_tokens rt
      JOIN users u ON u.id = rt.user_id
      WHERE rt.token_hash = $1
        AND rt.expires_at > NOW()
        AND rt.revoked_at IS NULL
        AND u.status = 'active'
    `;
    const result = await query(sql, [token_hash]);
    return result.rows[0] || null;
  }

  /**
   * Revoke a specific token
   */
  static async revoke(token) {
    const token_hash = this.hashToken(token);
    const sql = `
      UPDATE refresh_tokens
      SET revoked_at = NOW()
      WHERE token_hash = $1 AND revoked_at IS NULL
      RETURNING id
    `;
    const result = await query(sql, [token_hash]);
    return result.rows[0] || null;
  }

  /**
   * Revoke all tokens for a user (logout everywhere)
   */
  static async revokeAllForUser(user_id) {
    const sql = `
      UPDATE refresh_tokens
      SET revoked_at = NOW()
      WHERE user_id = $1 AND revoked_at IS NULL
    `;
    await query(sql, [user_id]);
  }
}

module.exports = RefreshTokenModel;
