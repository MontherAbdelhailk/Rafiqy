'use strict';

const { query } = require('../database/connection');
const { encrypt, decrypt } = require('../utils/crypto');

class ChatModel {
  /**
   * Save a chat message to database (content is encrypted)
   */
  static async createMessage({ senderId, receiverId, content, mediaUrl }) {
    const encryptedContent = content ? encrypt(content) : '';
    const sql = `
      INSERT INTO admin_chat_messages (sender_id, receiver_id, content, media_url)
      VALUES ($1, $2, $3, $4)
      RETURNING id, sender_id, receiver_id, content, media_url, is_read, created_at
    `;
    const result = await query(sql, [senderId, receiverId, encryptedContent, mediaUrl]);
    const message = result.rows[0];
    if (message) {
      message.content = decrypt(message.content);
    }
    return message;
  }

  /**
   * Get chat history between two users (decrypted)
   */
  static async getHistory(userId1, userId2) {
    const sql = `
      SELECT id, sender_id, receiver_id, content, media_url, is_read, created_at
      FROM admin_chat_messages
      WHERE (sender_id = $1 AND receiver_id = $2)
         OR (sender_id = $2 AND receiver_id = $1)
      ORDER BY created_at ASC
    `;
    const result = await query(sql, [userId1, userId2]);
    return result.rows.map((row) => ({
      ...row,
      content: decrypt(row.content),
    }));
  }

  /**
   * Mark all unread messages sent by `senderId` to `receiverId` as read
   */
  static async markAsRead(senderId, receiverId) {
    const sql = `
      UPDATE admin_chat_messages
      SET is_read = TRUE
      WHERE sender_id = $1 AND receiver_id = $2 AND is_read = FALSE
      RETURNING id
    `;
    const result = await query(sql, [senderId, receiverId]);
    return result.rowCount;
  }

  /**
   * Get all conversations for the admin, with search support (decrypted last messages)
   */
  static async getConversations(adminId, searchQuery = '') {
    const searchPattern = searchQuery ? `%${searchQuery}%` : null;
    const sql = `
      SELECT 
        u.id, 
        u.full_name, 
        u.username, 
        u.profile_picture,
        m.content AS last_message,
        m.media_url AS last_message_media_url,
        m.created_at AS last_message_time,
        m.sender_id AS last_message_sender_id,
        COALESCE(unread.count, 0)::int AS unread_count
      FROM users u
      LEFT JOIN (
        SELECT DISTINCT ON (user_id) 
          user_id, 
          id, 
          content, 
          created_at,
          sender_id
        FROM (
          SELECT sender_id AS user_id, id, content, created_at, sender_id 
          FROM admin_chat_messages 
          WHERE receiver_id = $1
          UNION ALL
          SELECT receiver_id AS user_id, id, content, created_at, sender_id 
          FROM admin_chat_messages 
          WHERE sender_id = $1
        ) sub
        ORDER BY user_id, created_at DESC
      ) last_msg ON u.id = last_msg.user_id
      LEFT JOIN admin_chat_messages m ON m.id = last_msg.id
      LEFT JOIN (
        SELECT sender_id, COUNT(*)::int AS count 
        FROM admin_chat_messages 
        WHERE receiver_id = $1 AND is_read = FALSE 
        GROUP BY sender_id
      ) unread ON u.id = unread.sender_id
      WHERE u.role != 'admin'
        AND ($2::text IS NULL OR u.full_name ILIKE $2 OR u.username ILIKE $2)
      ORDER BY COALESCE(m.created_at, '1970-01-01'::timestamptz) DESC, u.full_name ASC
    `;
    const result = await query(sql, [adminId, searchPattern]);
    return result.rows.map((row) => ({
      ...row,
      last_message: decrypt(row.last_message),
    }));
  }

  /**
   * Get total unread count for a user (or admin)
   */
  static async getUnreadCount(userId, role) {
    let sql;
    let params;
    if (role === 'admin') {
      // Admins want total unread messages from all users
      sql = `
        SELECT COUNT(*)::int AS count
        FROM admin_chat_messages
        WHERE receiver_id = $1 AND is_read = FALSE
      `;
      params = [userId];
    } else {
      // Normal users want unread messages from any admin
      sql = `
        SELECT COUNT(*)::int AS count
        FROM admin_chat_messages
        WHERE receiver_id = $1 AND is_read = FALSE
      `;
      params = [userId];
    }
    const result = await query(sql, params);
    return result.rows[0]?.count || 0;
  }

  /**
   * Save an FCM token for a user
   */
  static async saveFcmToken(userId, fcmToken) {
    const sql = `
      INSERT INTO user_fcm_tokens (user_id, fcm_token)
      VALUES ($1, $2)
      ON CONFLICT (user_id, fcm_token) DO UPDATE 
      SET created_at = NOW()
      RETURNING user_id, fcm_token
    `;
    const result = await query(sql, [userId, fcmToken]);
    return result.rows[0];
  }

  /**
   * Get all FCM tokens registered for a user
   */
  static async getFcmTokens(userId) {
    const sql = `
      SELECT fcm_token
      FROM user_fcm_tokens
      WHERE user_id = $1
    `;
    const result = await query(sql, [userId]);
    return result.rows.map((row) => row.fcm_token);
  }
}

module.exports = ChatModel;
