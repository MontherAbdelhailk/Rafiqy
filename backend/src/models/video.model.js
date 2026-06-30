'use strict';

/**
 * VideoModel
 * NOTE: Uses the shared connection pool from connection.js.
 * The previous private `new Pool(...)` was a resource leak — fixed in 3NF migration.
 */
const { pool } = require('../database/connection');

const fs = require('fs');
const path = require('path');
const { parseMp4Metadata } = require('../utils/mp4_metadata');

const deleteFile = (relativeUrl) => {
  if (!relativeUrl) return;
  if (relativeUrl.startsWith('http://') || relativeUrl.startsWith('https://')) return;
  const cleanPath = relativeUrl.startsWith('/') ? relativeUrl : `/${relativeUrl}`;
  const filePath = path.join(__dirname, '../..', cleanPath);
  fs.unlink(filePath, (err) => {
    if (err) {
      console.warn(`Unlink warning: Could not delete ${filePath}: ${err.message}`);
    }
  });
};

class VideoModel {
  static async getCategories() {
    const sql = `SELECT * FROM video_categories ORDER BY title ASC`;
    const res = await pool.query(sql);
    return res.rows;
  }

  static async findById(id, currentUserId = null) {
    const sql = `
      SELECT v.*, 
             c.title AS category_title, 
             s.title AS subcategory_title,
             COALESCE((SELECT COUNT(*)::int FROM video_likes WHERE video_id = v.id), 0) AS likes_count,
             EXISTS(SELECT 1 FROM video_likes WHERE video_id = v.id AND user_id = $2) AS has_liked
      FROM videos v
      JOIN video_categories c ON v.category_id = c.id
      LEFT JOIN video_subcategories s ON v.subcategory_id = s.id
      WHERE v.id = $1
    `;
    const res = await pool.query(sql, [id, currentUserId]);
    return res.rows[0];
  }

  static async listByStage(stageTitle, currentUserId = null, isAdmin = false) {
    let sql;
    let params;

    if (stageTitle === 'admin_all') {
      sql = `
        SELECT v.*, 
               c.title AS category_title, 
               s.title AS subcategory_title,
               COALESCE((SELECT COUNT(*)::int FROM video_likes WHERE video_id = v.id), 0) AS likes_count,
               EXISTS(SELECT 1 FROM video_likes WHERE video_id = v.id AND user_id = $1) AS has_liked
        FROM videos v
        JOIN video_categories c ON v.category_id = c.id
        LEFT JOIN video_subcategories s ON v.subcategory_id = s.id
        ORDER BY v.created_at DESC
      `;
      params = [currentUserId];
    } else {
      sql = `
        SELECT v.*, 
               c.title AS category_title, 
               s.title AS subcategory_title,
               COALESCE((SELECT COUNT(*)::int FROM video_likes WHERE video_id = v.id), 0) AS likes_count,
               EXISTS(SELECT 1 FROM video_likes WHERE video_id = v.id AND user_id = $2) AS has_liked
        FROM videos v
        JOIN video_categories c ON v.category_id = c.id
        LEFT JOIN video_subcategories s ON v.subcategory_id = s.id
        WHERE (s.title = $1 OR c.title = $1)
          ${!isAdmin ? 'AND v.is_public = TRUE' : ''}
        ORDER BY v.created_at DESC
      `;
      params = [stageTitle, currentUserId];
    }

    const res = await pool.query(sql, params);
    return res.rows;
  }

  static async create({ title, description, video_url, thumbnail_url, category_id, subcategory_id, tags, is_public }) {
    let duration = '02:00';
    let resolution = null;
    let aspect_ratio = null;

    if (video_url && !video_url.startsWith('http')) {
      const cleanPath = video_url.startsWith('/') ? video_url : `/${video_url}`;
      const filePath = path.join(__dirname, '../..', cleanPath);
      const metadata = await parseMp4Metadata(filePath);
      duration = metadata.duration;
      resolution = metadata.resolution;
      aspect_ratio = metadata.aspect_ratio;
    }

    const sql = `
      INSERT INTO videos (title, description, video_url, thumbnail_url, duration, resolution, aspect_ratio, is_public, category_id, subcategory_id, tags)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
      RETURNING *
    `;
    const params = [title, description, video_url, thumbnail_url, duration, resolution, aspect_ratio, is_public, category_id, subcategory_id, tags];
    const res = await pool.query(sql, params);
    return res.rows[0];
  }

  static async update(id, { title, description, category_id, subcategory_id, tags, is_public, video_url, thumbnail_url }) {
    const fields = [];
    const params = [];
    let paramIndex = 1;

    const updates = { title, description, category_id, subcategory_id, tags, is_public, video_url, thumbnail_url };
    
    if (video_url && !video_url.startsWith('http')) {
      const cleanPath = video_url.startsWith('/') ? video_url : `/${video_url}`;
      const filePath = path.join(__dirname, '../..', cleanPath);
      const metadata = await parseMp4Metadata(filePath);
      updates.duration = metadata.duration;
      updates.resolution = metadata.resolution;
      updates.aspect_ratio = metadata.aspect_ratio;
    }

    for (const [key, val] of Object.entries(updates)) {
      if (val !== undefined) {
        fields.push(`${key} = $${paramIndex}`);
        params.push(val);
        paramIndex++;
      }
    }

    if (fields.length === 0) return null;

    params.push(id);
    const sql = `
      UPDATE videos
      SET ${fields.join(', ')}, updated_at = NOW()
      WHERE id = $${paramIndex}
      RETURNING *
    `;

    const res = await pool.query(sql, params);
    return res.rows[0];
  }

  static async delete(id) {
    const selectSql = `SELECT video_url, thumbnail_url FROM videos WHERE id = $1`;
    const selectRes = await pool.query(selectSql, [id]);
    const video = selectRes.rows[0];

    if (!video) return false;

    // Delete record (cascades database views and likes)
    const deleteSql = `DELETE FROM videos WHERE id = $1`;
    await pool.query(deleteSql, [id]);

    // Delete physical files
    deleteFile(video.video_url);
    deleteFile(video.thumbnail_url);

    return true;
  }

  static async toggleLike(id, userId) {
    const checkSql = `SELECT 1 FROM video_likes WHERE video_id = $1 AND user_id = $2`;
    const checkRes = await pool.query(checkSql, [id, userId]);

    if (checkRes.rows.length > 0) {
      // Unlike
      await pool.query(`DELETE FROM video_likes WHERE video_id = $1 AND user_id = $2`, [id, userId]);
    } else {
      // Like
      await pool.query(`INSERT INTO video_likes (video_id, user_id) VALUES ($1, $2)`, [id, userId]);
    }

    // Return updated totals
    const totalSql = `SELECT COUNT(*)::int AS count FROM video_likes WHERE video_id = $1`;
    const totalRes = await pool.query(totalSql, [id]);
    const likesCount = totalRes.rows[0].count;

    const hasLiked = checkRes.rows.length === 0;

    return { likes_count: likesCount, has_liked: hasLiked };
  }

  static async watch(id, userId) {
    // Unique view record insertion
    await pool.query(
      `INSERT INTO video_views (video_id, user_id) 
       VALUES ($1, $2) 
       ON CONFLICT (video_id, user_id) DO NOTHING`,
      [id, userId]
    );

    // Update total unique views
    const totalSql = `SELECT COUNT(*)::int AS count FROM video_views WHERE video_id = $1`;
    const totalRes = await pool.query(totalSql, [id]);
    const viewsCount = totalRes.rows[0].count;

    await pool.query(`UPDATE videos SET view_count = $1 WHERE id = $2`, [viewsCount, id]);

    return { views_count: viewsCount };
  }

  static async findRelatedVideos(id, categoryId, subcategoryId, tags, limit = 3) {
    const sql = `
      SELECT v.*, 
             c.title AS category_title, 
             s.title AS subcategory_title,
             COALESCE((SELECT COUNT(*)::int FROM video_likes WHERE video_id = v.id), 0) AS likes_count,
             (CASE WHEN v.subcategory_id = $3 THEN 3 ELSE 0 END +
              CASE WHEN v.category_id = $2 THEN 1 ELSE 0 END +
              COALESCE((SELECT COUNT(*)::int FROM UNNEST(v.tags) t WHERE t = ANY($4::text[])), 0) * 2) AS relevance_score
      FROM videos v
      JOIN video_categories c ON v.category_id = c.id
      LEFT JOIN video_subcategories s ON v.subcategory_id = s.id
      WHERE v.id != $1 AND v.is_public = TRUE
      ORDER BY relevance_score DESC, v.created_at DESC
      LIMIT $5
    `;
    const res = await pool.query(sql, [id, categoryId, subcategoryId, tags || [], limit]);
    return res.rows;
  }
}

module.exports = VideoModel;
