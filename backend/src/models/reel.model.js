'use strict';

const { query } = require('../database/connection');
const path = require('path');
const fs = require('fs');

const uploadDir = path.join(__dirname, '../../uploads');

const deleteFile = (url) => {
  if (url && url.startsWith('/uploads/')) {
    const filename = url.replace('/uploads/', '');
    const fullPath = path.join(uploadDir, filename);
    if (fs.existsSync(fullPath)) {
      try {
        fs.unlinkSync(fullPath);
      } catch (err) {
        console.error(`Error deleting file: ${fullPath}`, err);
      }
    }
  }
};

class ReelModel {
  /**
   * Create a new Reel (Admin only)
   */
  static async create({ caption, video_url, thumbnail_url, is_public, comments_enabled, user_id, duration, resolution, aspect_ratio }) {
    const sql = `
      INSERT INTO reels (caption, video_url, thumbnail_url, is_public, comments_enabled, user_id, duration, resolution, aspect_ratio)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
      RETURNING id, caption, video_url, thumbnail_url, is_public, comments_enabled, view_count, user_id, duration, resolution, aspect_ratio, created_at
    `;
    const result = await query(sql, [
      caption,
      video_url,
      thumbnail_url || null,
      is_public !== undefined ? is_public : true,
      comments_enabled !== undefined ? comments_enabled : true,
      user_id,
      duration || '00:00',
      resolution || null,
      aspect_ratio || null,
    ]);
    return result.rows[0];
  }

  /**
   * Find all Reels (with infinite scroll / pagination support)
   */
  static async findAll(currentUserId, currentUserRole, limit = 10, offset = 0) {
    // Admins can see all (public + private). Users can only see public reels.
    let visibilityFilter = 'WHERE r.is_public = TRUE';
    if (currentUserRole === 'admin') {
      visibilityFilter = '';
    }

    const sql = `
      SELECT r.id, r.caption, r.video_url, r.thumbnail_url, r.is_public, r.comments_enabled, r.view_count, r.created_at,
             r.duration, r.resolution, r.aspect_ratio,
             u.id as author_id, u.full_name as author_name, u.username as author_username, u.profile_picture as author_image, u.role as author_role,
             COALESCE(l.love_count, 0) as love_count,
             COALESCE(c.comment_count, 0) as comment_count,
             CASE WHEN ul.user_id IS NOT NULL THEN TRUE ELSE FALSE END as has_loved
      FROM reels r
      JOIN users u ON r.user_id = u.id
      LEFT JOIN (
        SELECT reel_id, COUNT(*) as love_count
        FROM reel_loves
        GROUP BY reel_id
      ) l ON r.id = l.reel_id
      LEFT JOIN (
        SELECT reel_id, COUNT(*) as comment_count
        FROM reel_comments
        GROUP BY reel_id
      ) c ON r.id = c.reel_id
      LEFT JOIN reel_loves ul ON r.id = ul.reel_id AND ul.user_id = $1
      ${visibilityFilter}
      ORDER BY r.created_at DESC
      LIMIT $2 OFFSET $3
    `;
    const result = await query(sql, [currentUserId || null, limit, offset]);
    return result.rows;
  }

  /**
   * Find a Reel by ID
   */
  static async findById(id, currentUserId) {
    const sql = `
      SELECT r.id, r.caption, r.video_url, r.thumbnail_url, r.is_public, r.comments_enabled, r.view_count, r.created_at,
             r.duration, r.resolution, r.aspect_ratio,
             u.id as author_id, u.full_name as author_name, u.username as author_username, u.profile_picture as author_image, u.role as author_role,
             COALESCE(l.love_count, 0) as love_count,
             COALESCE(c.comment_count, 0) as comment_count,
             CASE WHEN ul.user_id IS NOT NULL THEN TRUE ELSE FALSE END as has_loved
      FROM reels r
      JOIN users u ON r.user_id = u.id
      LEFT JOIN (
        SELECT reel_id, COUNT(*) as love_count
        FROM reel_loves
        GROUP BY reel_id
      ) l ON r.id = l.reel_id
      LEFT JOIN (
        SELECT reel_id, COUNT(*) as comment_count
        FROM reel_comments
        GROUP BY reel_id
      ) c ON r.id = c.reel_id
      LEFT JOIN reel_loves ul ON r.id = ul.reel_id AND ul.user_id = $2
      WHERE r.id = $1
    `;
    const result = await query(sql, [id, currentUserId || null]);
    return result.rows[0] || null;
  }

  /**
   * Update Reel settings (Caption, Public/Private, Comments Enabled)
   */
  static async update(id, { caption, is_public, comments_enabled }) {
    const sql = `
      UPDATE reels
      SET caption = COALESCE($1, caption),
          is_public = COALESCE($2, is_public),
          comments_enabled = COALESCE($3, comments_enabled),
          updated_at = NOW()
      WHERE id = $4
      RETURNING id, caption, video_url, thumbnail_url, is_public, comments_enabled, view_count, user_id, created_at, updated_at
    `;
    const result = await query(sql, [caption, is_public, comments_enabled, id]);
    return result.rows[0] || null;
  }

  /**
   * Delete Reel & Associated Files from storage (Cascade cleanup)
   */
  static async delete(id) {
    // 1. Fetch URLs first to delete files
    const selectSql = `SELECT video_url, thumbnail_url FROM reels WHERE id = $1`;
    const selectRes = await query(selectSql, [id]);
    const reel = selectRes.rows[0];

    if (!reel) return null;

    // 2. Delete database record (associated loves/comments will be deleted by CASCADE foreign keys)
    const deleteSql = `DELETE FROM reels WHERE id = $1 RETURNING id`;
    const deleteRes = await query(deleteSql, [id]);

    // 3. Delete physical files from disk
    deleteFile(reel.video_url);
    deleteFile(reel.thumbnail_url);

    return deleteRes.rows[0];
  }

  /**
   * Increment view count
   */
  static async incrementViews(id) {
    const sql = `
      UPDATE reels
      SET view_count = view_count + 1
      WHERE id = $1
      RETURNING id, view_count
    `;
    const result = await query(sql, [id]);
    return result.rows[0] || null;
  }

  /**
   * Toggle love on a Reel
   */
  static async toggleLove(reelId, userId) {
    const checkSql = `SELECT 1 FROM reel_loves WHERE reel_id = $1 AND user_id = $2`;
    const checkRes = await query(checkSql, [reelId, userId]);

    if (checkRes.rowCount > 0) {
      await query(`DELETE FROM reel_loves WHERE reel_id = $1 AND user_id = $2`, [reelId, userId]);
    } else {
      await query(`INSERT INTO reel_loves (reel_id, user_id) VALUES ($1, $2) ON CONFLICT DO NOTHING`, [reelId, userId]);
    }

    const countSql = `
      SELECT 
        (SELECT COUNT(*) FROM reel_loves WHERE reel_id = $1) as love_count,
        EXISTS(SELECT 1 FROM reel_loves WHERE reel_id = $1 AND user_id = $2) as has_loved
    `;
    const countRes = await query(countSql, [reelId, userId]);
    return {
      love_count: parseInt(countRes.rows[0].love_count, 10),
      has_loved: countRes.rows[0].has_loved,
    };
  }

  /**
   * Add a comment to a Reel
   */
  static async addComment(reelId, userId, content) {
    const sql = `
      INSERT INTO reel_comments (reel_id, user_id, content)
      VALUES ($1, $2, $3)
      RETURNING id, reel_id, user_id, content, created_at
    `;
    const insertRes = await query(sql, [reelId, userId, content]);
    const comment = insertRes.rows[0];

    const detailSql = `
      SELECT c.id, c.reel_id, c.content, c.created_at,
             u.full_name as author_name, u.username as author_username, u.profile_picture as author_image, u.role as author_role
      FROM reel_comments c
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
      sql = `DELETE FROM reel_comments WHERE id = $1 RETURNING id`;
      params = [commentId];
    } else {
      sql = `DELETE FROM reel_comments WHERE id = $1 AND user_id = $2 RETURNING id`;
      params = [commentId, userId];
    }

    const result = await query(sql, params);
    return result.rows[0] || null;
  }

  /**
   * Find comments for a Reel including replies and comment likes
   */
  static async findCommentsByReelId(reelId, currentUserId) {
    const commentsSql = `
      SELECT c.id, c.content, c.created_at,
             u.id as author_id, u.full_name as author_name, u.username as author_username, u.profile_picture as author_image, u.role as author_role,
             COALESCE(cl.like_count, 0) as like_count,
             EXISTS(SELECT 1 FROM reel_comment_likes WHERE comment_id = c.id AND user_id = $2) as has_liked
      FROM reel_comments c
      JOIN users u ON c.user_id = u.id
      LEFT JOIN (
        SELECT comment_id, COUNT(*) as like_count
        FROM reel_comment_likes
        GROUP BY comment_id
      ) cl ON c.id = cl.comment_id
      WHERE c.reel_id = $1
      ORDER BY c.created_at ASC
    `;
    const commentsRes = await query(commentsSql, [reelId, currentUserId || null]);
    const comments = commentsRes.rows;

    for (const comment of comments) {
      const repliesSql = `
        SELECT cr.id, cr.content, cr.created_at,
               u.id as author_id, u.full_name as author_name, u.username as author_username, u.profile_picture as author_image, u.role as author_role
        FROM reel_comment_replies cr
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
   * Toggle like on a Reel Comment
   */
  static async toggleLikeComment(commentId, userId) {
    const checkSql = `SELECT 1 FROM reel_comment_likes WHERE comment_id = $1 AND user_id = $2`;
    const checkRes = await query(checkSql, [commentId, userId]);

    if (checkRes.rowCount > 0) {
      await query(`DELETE FROM reel_comment_likes WHERE comment_id = $1 AND user_id = $2`, [commentId, userId]);
    } else {
      await query(`INSERT INTO reel_comment_likes (comment_id, user_id) VALUES ($1, $2) ON CONFLICT DO NOTHING`, [commentId, userId]);
    }

    const countSql = `
      SELECT 
        (SELECT COUNT(*) FROM reel_comment_likes WHERE comment_id = $1) as like_count,
        EXISTS(SELECT 1 FROM reel_comment_likes WHERE comment_id = $1 AND user_id = $2) as has_liked
    `;
    const countRes = await query(countSql, [commentId, userId]);
    return {
      like_count: parseInt(countRes.rows[0].like_count, 10),
      has_liked: countRes.rows[0].has_liked,
    };
  }

  /**
   * Add a reply to a Reel Comment
   */
  static async addCommentReply(commentId, userId, content) {
    const sql = `
      INSERT INTO reel_comment_replies (comment_id, user_id, content)
      VALUES ($1, $2, $3)
      RETURNING id, comment_id, user_id, content, created_at
    `;
    const insertRes = await query(sql, [commentId, userId, content]);
    const reply = insertRes.rows[0];

    const detailSql = `
      SELECT cr.id, cr.comment_id, cr.content, cr.created_at,
             u.full_name as author_name, u.username as author_username, u.profile_picture as author_image, u.role as author_role
      FROM reel_comment_replies cr
      JOIN users u ON cr.user_id = u.id
      WHERE cr.id = $1
    `;
    const detailRes = await query(detailSql, [reply.id]);
    return detailRes.rows[0];
  }
}

module.exports = ReelModel;
