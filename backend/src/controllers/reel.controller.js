'use strict';

const ReelModel = require('../models/reel.model');
const { AppError } = require('../utils/AppError');
const { parseMp4Metadata } = require('../utils/mp4_metadata');
const child_process = require('child_process');
const path = require('path');

const uploadDir = path.join(__dirname, '../../uploads');

const extractThumbnail = async (videoPath, outputFilename) => {
  return new Promise((resolve) => {
    const outputPath = path.join(uploadDir, outputFilename);
    // Grab first frame after 1 second
    const cmd = `ffmpeg -y -i "${videoPath}" -ss 00:00:01 -vframes 1 -f image2 "${outputPath}"`;
    child_process.exec(cmd, (error) => {
      if (error) {
        // Fallback to null (client will use placeholder)
        resolve(null);
      } else {
        resolve(`/uploads/${outputFilename}`);
      }
    });
  });
};

// ─── Reel Actions ────────────────────────────────────────────────────────────

const listReels = async (req, res, next) => {
  try {
    const currentUserId = req.user ? req.user.id : null;
    const currentUserRole = req.user ? req.user.role : 'user';
    const limit = parseInt(req.query.limit, 10) || 10;
    const offset = parseInt(req.query.offset, 10) || 0;

    const reels = await ReelModel.findAll(currentUserId, currentUserRole, limit, offset);
    const { getFullImageUrl } = require('../utils/imageUrl');

    const formattedReels = reels.map((reel) => {
      const fullUrl = getFullImageUrl(reel.author_image, req, reel.author_role);
      return {
        ...reel,
        author_image: fullUrl,
        profileImage: fullUrl,
        avatarUrl: fullUrl,
      };
    });

    return res.status(200).json({
      success: true,
      data: formattedReels,
    });
  } catch (error) {
    next(error);
  }
};

const createReel = async (req, res, next) => {
  try {
    const { caption, is_public, comments_enabled } = req.body;

    if (!req.file) {
      throw new AppError('Video file is required', 400, 'VIDEO_REQUIRED');
    }

    const video_url = `/uploads/${req.file.filename}`;
    const videoLocalPath = path.join(uploadDir, req.file.filename);
    const thumbFilename = `thumb-${req.file.filename.split('.')[0]}.jpg`;

    // Attempt thumbnail generation
    const thumbnail_url = await extractThumbnail(videoLocalPath, thumbFilename);

    // Extract video metadata (duration, resolution, aspect_ratio)
    const metadata = await parseMp4Metadata(videoLocalPath);

    const isPublicBool = is_public === 'false' ? false : true;
    const commentsEnabledBool = comments_enabled === 'false' ? false : true;

    const reel = await ReelModel.create({
      caption: caption || '',
      video_url,
      thumbnail_url,
      is_public: isPublicBool,
      comments_enabled: commentsEnabledBool,
      user_id: req.user.id,
      duration: metadata.duration,
      resolution: metadata.resolution,
      aspect_ratio: metadata.aspect_ratio,
    });

    const { getFullImageUrl } = require('../utils/imageUrl');
    const fullUrl = getFullImageUrl(req.user.profile_picture, req, req.user.role);
    reel.author_name = req.user.full_name || req.user.username;
    reel.author_image = fullUrl;
    reel.profileImage = fullUrl;
    reel.avatarUrl = fullUrl;
    reel.author_role = req.user.role;

    return res.status(201).json({
      success: true,
      message: 'Reel created successfully',
      data: reel,
    });
  } catch (error) {
    next(error);
  }
};

const updateReel = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { caption, is_public, comments_enabled } = req.body;

    const isPublicBool = is_public !== undefined ? (is_public === 'false' ? false : true) : undefined;
    const commentsEnabledBool = comments_enabled !== undefined ? (comments_enabled === 'false' ? false : true) : undefined;

    const reel = await ReelModel.update(id, {
      caption,
      is_public: isPublicBool,
      comments_enabled: commentsEnabledBool,
    });

    if (!reel) {
      throw new AppError('Reel not found', 404, 'REEL_NOT_FOUND');
    }

    return res.status(200).json({
      success: true,
      message: 'Reel settings updated successfully',
      data: reel,
    });
  } catch (error) {
    next(error);
  }
};

const deleteReel = async (req, res, next) => {
  try {
    const { id } = req.params;
    const result = await ReelModel.delete(id);

    if (!result) {
      throw new AppError('Reel not found', 404, 'REEL_NOT_FOUND');
    }

    return res.status(200).json({
      success: true,
      message: 'Reel deleted successfully',
    });
  } catch (error) {
    next(error);
  }
};

const watchReel = async (req, res, next) => {
  try {
    const { id } = req.params;
    const result = await ReelModel.incrementViews(id);

    if (!result) {
      throw new AppError('Reel not found', 404, 'REEL_NOT_FOUND');
    }

    return res.status(200).json({
      success: true,
      data: result,
    });
  } catch (error) {
    next(error);
  }
};

const toggleLoveReel = async (req, res, next) => {
  try {
    const { id } = req.params;
    const result = await ReelModel.toggleLove(id, req.user.id);

    return res.status(200).json({
      success: true,
      data: result,
    });
  } catch (error) {
    next(error);
  }
};

// ─── Comment Actions ─────────────────────────────────────────────────────────

const listReelComments = async (req, res, next) => {
  try {
    const { reelId } = req.params;
    const currentUserId = req.user ? req.user.id : null;
    const comments = await ReelModel.findCommentsByReelId(reelId, currentUserId);
    const { getFullImageUrl } = require('../utils/imageUrl');

    const formattedComments = comments.map((comment) => {
      const comUrl = getFullImageUrl(comment.author_image, req, comment.author_role);
      const formattedReplies = (comment.replies || []).map((reply) => {
        const repUrl = getFullImageUrl(reply.author_image, req, reply.author_role);
        return {
          ...reply,
          author_image: repUrl,
          profileImage: repUrl,
          avatarUrl: repUrl,
        };
      });

      return {
        ...comment,
        author_image: comUrl,
        profileImage: comUrl,
        avatarUrl: comUrl,
        replies: formattedReplies,
      };
    });

    return res.status(200).json({
      success: true,
      data: formattedComments,
    });
  } catch (error) {
    next(error);
  }
};

const addReelComment = async (req, res, next) => {
  try {
    const { reelId } = req.params;
    const { content } = req.body;

    if (!content || content.trim().length === 0) {
      throw new AppError('Comment content is required', 400, 'CONTENT_REQUIRED');
    }

    const comment = await ReelModel.addComment(reelId, req.user.id, content);
    const { getFullImageUrl } = require('../utils/imageUrl');
    const fullUrl = getFullImageUrl(comment.author_image, req, comment.author_role);
    comment.author_image = fullUrl;
    comment.profileImage = fullUrl;
    comment.avatarUrl = fullUrl;

    return res.status(201).json({
      success: true,
      message: 'Comment added successfully',
      data: comment,
    });
  } catch (error) {
    next(error);
  }
};

const deleteReelComment = async (req, res, next) => {
  try {
    const { id } = req.params;
    const comment = await ReelModel.deleteComment(id, req.user.id, req.user.role);

    if (!comment) {
      throw new AppError('Comment not found or unauthorized', 403, 'UNAUTHORIZED');
    }

    return res.status(200).json({
      success: true,
      message: 'Comment deleted successfully',
    });
  } catch (error) {
    next(error);
  }
};

const toggleLikeReelComment = async (req, res, next) => {
  try {
    const { id } = req.params;
    const result = await ReelModel.toggleLikeComment(id, req.user.id);

    return res.status(200).json({
      success: true,
      data: result,
    });
  } catch (error) {
    next(error);
  }
};

const addReelCommentReply = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { content } = req.body;

    if (!content || content.trim().length === 0) {
      throw new AppError('Reply content is required', 400, 'CONTENT_REQUIRED');
    }

    const reply = await ReelModel.addCommentReply(id, req.user.id, content);
    const { getFullImageUrl } = require('../utils/imageUrl');
    const fullUrl = getFullImageUrl(reply.author_image, req, reply.author_role);
    reply.author_image = fullUrl;
    reply.profileImage = fullUrl;
    reply.avatarUrl = fullUrl;

    return res.status(201).json({
      success: true,
      message: 'Reply added successfully',
      data: reply,
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  listReels,
  createReel,
  updateReel,
  deleteReel,
  watchReel,
  toggleLoveReel,
  listReelComments,
  addReelComment,
  deleteReelComment,
  toggleLikeReelComment,
  addReelCommentReply,
};
