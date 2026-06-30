'use strict';

const VideoModel = require('../models/video.model');
const { AppError } = require('../utils/AppError');
const { Pool } = require('pg');
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT, 10) || 5432,
  database: process.env.DB_NAME || 'rafiq_db',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD,
});

exports.getCategories = async (req, res, next) => {
  try {
    const categories = await VideoModel.getCategories();
    res.status(200).json(categories);
  } catch (error) {
    next(error);
  }
};

exports.getVideosList = async (req, res, next) => {
  try {
    const { stageTitle } = req.params;
    const currentUserId = req.user ? req.user.id : null;
    const isAdmin = req.user && req.user.role === 'admin';

    const videos = await VideoModel.listByStage(stageTitle, currentUserId, isAdmin);

    // Append related videos to each video in the list
    const result = await Promise.all(
      videos.map(async (v) => {
        const related = await VideoModel.findRelatedVideos(
          v.id,
          v.category_id,
          v.subcategory_id,
          v.tags,
          3
        );
        return {
          id: v.id,
          title: v.title,
          description: v.description,
          video_url: v.video_url,
          thumbnail_url: v.thumbnail_url,
          duration: v.duration,
          resolution: v.resolution,
          aspect_ratio: v.aspect_ratio,
          is_public: v.is_public,
          views_count: v.view_count,
          likes_count: v.likes_count,
          has_liked: v.has_liked,
          category_id: v.category_title, // Map category name as category_id for tag property on client
          subcategory_id: v.subcategory_title,
          tags: v.tags,
          related_videos: related.map((r) => ({
            id: r.id,
            title: r.title,
            description: r.description,
            video_url: r.video_url,
            thumbnail_url: r.thumbnail_url,
            duration: r.duration,
            resolution: r.resolution,
            aspect_ratio: r.aspect_ratio,
            is_public: r.is_public,
            views_count: r.view_count,
            likes_count: r.likes_count,
            category_id: r.category_title,
          })),
        };
      })
    );

    res.status(200).json(result);
  } catch (error) {
    next(error);
  }
};

exports.createVideo = async (req, res, next) => {
  try {
    const { title, description, category_title, subcategory_title, is_public } = req.body;

    if (!req.files || !req.files['video'] || !req.files['cover_image']) {
      return next(new AppError('Both video and cover image files are required', 400, 'FILES_MISSING'));
    }

    const videoFile = req.files['video'][0];
    const coverImageFile = req.files['cover_image'][0];

    const video_url = `/uploads/${videoFile.filename}`;
    const thumbnail_url = `/uploads/${coverImageFile.filename}`;

    // Resolve Category UUID
    let categoryId = req.body.category_id;
    if (category_title) {
      const catRes = await pool.query('SELECT id FROM video_categories WHERE title = $1', [category_title]);
      if (catRes.rows[0]) {
        categoryId = catRes.rows[0].id;
      }
    }

    if (!categoryId) {
      return next(new AppError('Valid category is required', 400, 'CATEGORY_INVALID'));
    }

    // Resolve Subcategory UUID
    let subcategoryId = req.body.subcategory_id;
    if (subcategory_title) {
      const subRes = await pool.query('SELECT id FROM video_subcategories WHERE title = $1 AND category_id = $2', [subcategory_title, categoryId]);
      if (subRes.rows[0]) {
        subcategoryId = subRes.rows[0].id;
      }
    }

    // Parse Tags
    let tagArray = [];
    if (req.body.tags) {
      if (Array.isArray(req.body.tags)) {
        tagArray = req.body.tags;
      } else if (typeof req.body.tags === 'string') {
        tagArray = req.body.tags.split(',').map((t) => t.trim()).filter((t) => t.length > 0);
      }
    }

    const video = await VideoModel.create({
      title,
      description,
      video_url,
      thumbnail_url,
      category_id: categoryId,
      subcategory_id: subcategoryId || null,
      tags: tagArray,
      is_public: is_public === 'true' || is_public === true,
    });

    res.status(201).json({
      success: true,
      message: 'Video uploaded successfully',
      data: video,
    });
  } catch (error) {
    next(error);
  }
};

exports.updateVideo = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { title, description, category_title, subcategory_title, is_public } = req.body;

    const existingVideo = await VideoModel.findById(id);
    if (!existingVideo) {
      return next(new AppError('Video not found', 404, 'VIDEO_NOT_FOUND'));
    }

    const updates = {};
    if (title !== undefined) updates.title = title;
    if (description !== undefined) updates.description = description;
    if (is_public !== undefined) updates.is_public = is_public === 'true' || is_public === true;

    // Resolve category and subcategory
    let categoryId = req.body.category_id;
    if (category_title) {
      const catRes = await pool.query('SELECT id FROM video_categories WHERE title = $1', [category_title]);
      if (catRes.rows[0]) categoryId = catRes.rows[0].id;
    }
    if (categoryId) updates.category_id = categoryId;

    let subcategoryId = req.body.subcategory_id;
    if (subcategory_title) {
      const targetCatId = categoryId || existingVideo.category_id;
      const subRes = await pool.query('SELECT id FROM video_subcategories WHERE title = $1 AND category_id = $2', [subcategory_title, targetCatId]);
      if (subRes.rows[0]) subcategoryId = subRes.rows[0].id;
    }
    if (subcategoryId !== undefined) updates.subcategory_id = subcategoryId;

    // Parse Tags
    if (req.body.tags !== undefined) {
      let tagArray = [];
      if (Array.isArray(req.body.tags)) {
        tagArray = req.body.tags;
      } else if (typeof req.body.tags === 'string') {
        tagArray = req.body.tags.split(',').map((t) => t.trim()).filter((t) => t.length > 0);
      }
      updates.tags = tagArray;
    }

    // Handles files update if sent
    if (req.files) {
      if (req.files['video']) {
        const videoFile = req.files['video'][0];
        updates.video_url = `/uploads/${videoFile.filename}`;
        // Unlink old video
        const fs = require('fs');
        const path = require('path');
        const oldPath = path.join(__dirname, '../..', existingVideo.video_url);
        fs.unlink(oldPath, () => {});
      }
      if (req.files['cover_image']) {
        const coverImageFile = req.files['cover_image'][0];
        updates.thumbnail_url = `/uploads/${coverImageFile.filename}`;
        // Unlink old cover image
        const fs = require('fs');
        const path = require('path');
        const oldPath = path.join(__dirname, '../..', existingVideo.thumbnail_url);
        fs.unlink(oldPath, () => {});
      }
    }

    const updatedVideo = await VideoModel.update(id, updates);

    res.status(200).json({
      success: true,
      message: 'Video updated successfully',
      data: updatedVideo,
    });
  } catch (error) {
    next(error);
  }
};

exports.deleteVideo = async (req, res, next) => {
  try {
    const { id } = req.params;
    const deleted = await VideoModel.delete(id);
    if (!deleted) {
      return next(new AppError('Video not found', 404, 'VIDEO_NOT_FOUND'));
    }
    res.status(200).json({
      success: true,
      message: 'Video and associated media files deleted successfully',
    });
  } catch (error) {
    next(error);
  }
};

exports.toggleLikeVideo = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    const result = await VideoModel.toggleLike(id, userId);
    res.status(200).json({
      success: true,
      data: result,
    });
  } catch (error) {
    next(error);
  }
};

exports.watchVideo = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    const result = await VideoModel.watch(id, userId);
    res.status(200).json({
      success: true,
      data: result,
    });
  } catch (error) {
    next(error);
  }
};
