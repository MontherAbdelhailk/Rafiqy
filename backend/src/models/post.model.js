'use strict';

const { query } = require('../database/connection');

class PostModel {
  /**
   * Create a new post (Admin only)
   */
  static async create({ content, media_url, user_id }) {
    const sql = `
      INSERT INTO posts (content, media_url, user_id)
      VALUES ($1, $2, $3)
      RETURNING id, content, media_url, user_id, created_at, updated_at
    `;
    const result = await query(sql, [content, media_url, user_id]);
    return result.rows[0];
  }

  /**
   * Update an existing post (Admin only)
   */
  static async update(id, { content, media_url }) {
    const sql = `
      UPDATE posts
      SET content = COALESCE($1, content),
          media_url = COALESCE($2, media_url),
          updated_at = NOW()
      WHERE id = $3
      RETURNING id, content, media_url, user_id, created_at, updated_at
    `;
    const result = await query(sql, [content, media_url, id]);
    return result.rows[0] || null;
  }

  /**
   * Delete a post (Admin only)
   */
  static async delete(id) {
    const sql = `
      DELETE FROM posts
      WHERE id = $1
      RETURNING id
    `;
    const result = await query(sql, [id]);
    return result.rows[0] || null;
  }

  /**
   * Find all posts with love count, comment count, and user's love status
   */
  static async findAll(currentUserId) {
    const sql = `
      SELECT p.id, p.content, p.media_url, p.created_at, p.updated_at,
             u.id as author_id, u.full_name as author_name, u.username as author_username, u.profile_picture as author_image, u.role as author_role,
             COALESCE(l.love_count, 0) as love_count,
             COALESCE(c.comment_count, 0) as comment_count,
             CASE WHEN ul.user_id IS NOT NULL THEN TRUE ELSE FALSE END as has_loved
      FROM posts p
      JOIN users u ON p.user_id = u.id
      LEFT JOIN (
        SELECT post_id, COUNT(*) as love_count
        FROM post_loves
        GROUP BY post_id
      ) l ON p.id = l.post_id
      LEFT JOIN (
        SELECT post_id, COUNT(*) as comment_count
        FROM comments
        GROUP BY post_id
      ) c ON p.id = c.post_id
      LEFT JOIN post_loves ul ON p.id = ul.post_id AND ul.user_id = $1
      ORDER BY p.created_at DESC
    `;
    const result = await query(sql, [currentUserId || null]);
    return result.rows;
  }

  /**
   * Toggle love on a post
   */
  static async toggleLove(postId, userId) {
    // Check if already loved
    const checkSql = `SELECT 1 FROM post_loves WHERE post_id = $1 AND user_id = $2`;
    const checkRes = await query(checkSql, [postId, userId]);

    if (checkRes.rowCount > 0) {
      // Remove love
      await query(`DELETE FROM post_loves WHERE post_id = $1 AND user_id = $2`, [postId, userId]);
    } else {
      // Add love
      await query(`INSERT INTO post_loves (post_id, user_id) VALUES ($1, $2) ON CONFLICT DO NOTHING`, [postId, userId]);
    }

    // Get updated love count and check if loved now
    const countSql = `
      SELECT 
        (SELECT COUNT(*) FROM post_loves WHERE post_id = $1) as love_count,
        EXISTS(SELECT 1 FROM post_loves WHERE post_id = $1 AND user_id = $2) as has_loved
    `;
    const countRes = await query(countSql, [postId, userId]);
    return {
      love_count: parseInt(countRes.rows[0].love_count, 10),
      has_loved: countRes.rows[0].has_loved,
    };
  }

  /**
   * Add a comment to a post
   */
  static async addComment(postId, userId, content) {
    const sql = `
      INSERT INTO comments (post_id, user_id, content)
      VALUES ($1, $2, $3)
      RETURNING id, post_id, user_id, content, created_at
    `;
    const insertRes = await query(sql, [postId, userId, content]);
    const comment = insertRes.rows[0];

    // Fetch comment with user details
    const detailSql = `
      SELECT c.id, c.post_id, c.content, c.created_at,
             u.full_name as author_name, u.username as author_username, u.profile_picture as author_image, u.role as author_role
      FROM comments c
      JOIN users u ON c.user_id = u.id
      WHERE c.id = $1
    `;
    const detailRes = await query(detailSql, [comment.id]);
    return detailRes.rows[0];
  }

  /**
   * Delete a comment (Author or Admin only)
   */
  static async deleteComment(commentId, userId, userRole) {
    let sql = '';
    let params = [];

    if (userRole === 'admin') {
      sql = `DELETE FROM comments WHERE id = $1 RETURNING id`;
      params = [commentId];
    } else {
      sql = `DELETE FROM comments WHERE id = $1 AND user_id = $2 RETURNING id`;
      params = [commentId, userId];
    }

    const result = await query(sql, params);
    return result.rows[0] || null;
  }

  /**
   * Find comments for a post including likes and replies
   */
  static async findCommentsByPostId(postId, currentUserId) {
    const commentsSql = `
      SELECT c.id, c.content, c.created_at,
             u.id as author_id, u.full_name as author_name, u.username as author_username, u.profile_picture as author_image, u.role as author_role,
             COALESCE(cl.like_count, 0) as like_count,
             EXISTS(SELECT 1 FROM comment_likes WHERE comment_id = c.id AND user_id = $2) as has_liked
      FROM comments c
      JOIN users u ON c.user_id = u.id
      LEFT JOIN (
        SELECT comment_id, COUNT(*) as like_count
        FROM comment_likes
        GROUP BY comment_id
      ) cl ON c.id = cl.comment_id
      WHERE c.post_id = $1
      ORDER BY c.created_at ASC
    `;
    const commentsRes = await query(commentsSql, [postId, currentUserId || null]);
    const comments = commentsRes.rows;

    // Load replies for each comment
    for (const comment of comments) {
      const repliesSql = `
        SELECT cr.id, cr.content, cr.created_at,
               u.id as author_id, u.full_name as author_name, u.username as author_username, u.profile_picture as author_image, u.role as author_role
        FROM comment_replies cr
        JOIN users u ON cr.user_id = u.id
        WHERE cr.comment_id = $1
        ORDER BY cr.created_at ASC
      `;
      const repliesRes = await query(repliesSql, [comment.id]);
      comment.replies = repliesRes.rows;
    }

    return comments;
  }

  /**
   * Toggle like on a comment
   */
  static async toggleLikeComment(commentId, userId) {
    const checkSql = `SELECT 1 FROM comment_likes WHERE comment_id = $1 AND user_id = $2`;
    const checkRes = await query(checkSql, [commentId, userId]);

    if (checkRes.rowCount > 0) {
      await query(`DELETE FROM comment_likes WHERE comment_id = $1 AND user_id = $2`, [commentId, userId]);
    } else {
      await query(`INSERT INTO comment_likes (comment_id, user_id) VALUES ($1, $2) ON CONFLICT DO NOTHING`, [commentId, userId]);
    }

    const countSql = `
      SELECT 
        (SELECT COUNT(*) FROM comment_likes WHERE comment_id = $1) as like_count,
        EXISTS(SELECT 1 FROM comment_likes WHERE comment_id = $1 AND user_id = $2) as has_liked
    `;
    const countRes = await query(countSql, [commentId, userId]);
    return {
      like_count: parseInt(countRes.rows[0].like_count, 10),
      has_liked: countRes.rows[0].has_liked,
    };
  }

  /**
   * Add a reply to a comment
   */
  static async addCommentReply(commentId, userId, content) {
    const sql = `
      INSERT INTO comment_replies (comment_id, user_id, content)
      VALUES ($1, $2, $3)
      RETURNING id, comment_id, user_id, content, created_at
    `;
    const insertRes = await query(sql, [commentId, userId, content]);
    const reply = insertRes.rows[0];

    const detailSql = `
      SELECT cr.id, cr.comment_id, cr.content, cr.created_at,
             u.full_name as author_name, u.username as author_username, u.profile_picture as author_image, u.role as author_role
      FROM comment_replies cr
      JOIN users u ON cr.user_id = u.id
      WHERE cr.id = $1
    `;
    const detailRes = await query(detailSql, [reply.id]);
    return detailRes.rows[0];
  }
}

module.exports = PostModel;
