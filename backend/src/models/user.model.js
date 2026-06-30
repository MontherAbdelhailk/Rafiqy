'use strict';

const { query } = require('../database/connection');

class UserModel {
  /**
   * Create a new user
   */
  static async create({ full_name, username, email, password_hash, first_name, last_name, phone_number }) {
    const sql = `
      INSERT INTO users (full_name, username, email, password_hash, first_name, last_name, phone_number)
      VALUES ($1, $2, $3, $4, $5, $6, $7)
      RETURNING id, full_name, username, email, status, is_verified, created_at, first_name, last_name, profile_picture, marital_status, age, phone_number, children_count, bio
    `;
    const result = await query(sql, [full_name, username, email, password_hash, first_name, last_name, phone_number]);
    return result.rows[0];
  }

  /**
   * Find a user by ID (loads all profile details)
   */
  static async findById(id) {
    const sql = `
      SELECT id, full_name, username, email, password_hash,
             status, is_verified, last_login_at, created_at, updated_at,
             first_name, last_name, profile_picture, marital_status,
             age, phone_number, children_count, bio, role
      FROM users
      WHERE id = $1 AND status != 'deleted'
    `;
    const result = await query(sql, [id]);
    return result.rows[0] || null;
  }

  /**
   * Find a user by username (case-insensitive via CITEXT)
   */
  static async findByUsername(username) {
    const sql = `
      SELECT id, full_name, username, email, password_hash,
             status, is_verified, last_login_at, created_at, updated_at,
             first_name, last_name, profile_picture, marital_status,
             age, phone_number, children_count, bio, role
      FROM users
      WHERE username = $1 AND status != 'deleted'
    `;
    const result = await query(sql, [username]);
    return result.rows[0] || null;
  }

  /**
   * Find a user by email (case-insensitive via CITEXT)
   */
  static async findByEmail(email) {
    const sql = `
      SELECT id, full_name, username, email, password_hash,
             status, is_verified, last_login_at, created_at, updated_at,
             first_name, last_name, profile_picture, marital_status,
             age, phone_number, children_count, bio, role
      FROM users
      WHERE email = $1 AND status != 'deleted'
    `;
    const result = await query(sql, [email]);
    return result.rows[0] || null;
  }

  /**
   * Find a user by username OR email (for flexible login)
   */
  static async findByUsernameOrEmail(identifier) {
    const sql = `
      SELECT id, full_name, username, email, password_hash,
             status, is_verified, last_login_at, created_at, updated_at,
             first_name, last_name, profile_picture, marital_status,
             age, phone_number, children_count, bio, role
      FROM users
      WHERE (username = $1 OR email = $1) AND status != 'deleted'
      LIMIT 1
    `;
    const result = await query(sql, [identifier]);
    return result.rows[0] || null;
  }

  /**
   * Check if username exists
   */
  static async usernameExists(username) {
    const result = await query(
      'SELECT id FROM users WHERE username = $1',
      [username]
    );
    return result.rowCount > 0;
  }

  /**
   * Check if email exists
   */
  static async emailExists(email) {
    const result = await query(
      'SELECT id FROM users WHERE email = $1',
      [email]
    );
    return result.rowCount > 0;
  }

  /**
   * Update last login timestamp
   */
  static async updateLastLogin(id) {
    await query(
      'UPDATE users SET last_login_at = NOW() WHERE id = $1',
      [id]
    );
  }

  /**
   * Update user profile (safe profile fields only)
   */
  static async updateProfile(id, { first_name, last_name, profile_picture, marital_status, age, phone_number, children_count, bio }) {
    // If status is not Married, set children_count to 0 to respect conditional rules
    const finalChildrenCount = marital_status === 'Married' ? children_count : 0;

    const sql = `
      UPDATE users
      SET first_name = COALESCE($1, first_name),
          last_name = COALESCE($2, last_name),
          profile_picture = COALESCE($3, profile_picture),
          marital_status = COALESCE($4, marital_status),
          age = COALESCE($5, age),
          phone_number = COALESCE($6, phone_number),
          children_count = COALESCE($7, children_count),
          bio = COALESCE($8, bio),
          full_name = COALESCE($1 || ' ' || $2, full_name)
      WHERE id = $9 AND status != 'deleted'
      RETURNING id, full_name, username, email, status, is_verified, updated_at,
                first_name, last_name, profile_picture, marital_status,
                age, phone_number, children_count, bio
    `;
    const result = await query(sql, [
      first_name,
      last_name,
      profile_picture,
      marital_status,
      age,
      phone_number,
      finalChildrenCount,
      bio,
      id
    ]);
    return result.rows[0] || null;
  }

  /**
   * Update password hash
   */
  static async updatePassword(id, password_hash) {
    const sql = `
      UPDATE users
      SET password_hash = $1
      WHERE id = $2 AND status != 'deleted'
      RETURNING id
    `;
    const result = await query(sql, [password_hash, id]);
    return result.rows[0] || null;
  }

  /**
   * Soft-delete a user
   */
  static async softDelete(id) {
    const sql = `
      UPDATE users
      SET status = 'deleted'
      WHERE id = $1
      RETURNING id
    `;
    const result = await query(sql, [id]);
    return result.rows[0] || null;
  }

  static sanitize(user, req) {
    if (!user) return null;
    const { password_hash, ...safe } = user;
    const { getFullImageUrl } = require('../utils/imageUrl');
    const fullUrl = getFullImageUrl(safe.profile_picture, req, safe.role);
    safe.profileImage = fullUrl;
    safe.avatarUrl = fullUrl;
    return safe;
  }
}

module.exports = UserModel;
