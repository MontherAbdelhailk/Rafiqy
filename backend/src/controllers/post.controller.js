'use strict';

const PostModel = require('../models/post.model');
const { AppError } = require('../utils/AppError');

// ─── Post Controllers ────────────────────────────────────────────────────────

const listPosts = async (req, res, next) => {
  try {
    const currentUserId = req.user ? req.user.id : null;
    const posts = await PostModel.findAll(currentUserId);
    const { getFullImageUrl } = require('../utils/imageUrl');

    const formattedPosts = posts.map((post) => {
      const fullUrl = getFullImageUrl(post.author_image, req, post.author_role);
      return {
        ...post,
        author_image: fullUrl,
        profileImage: fullUrl,
        avatarUrl: fullUrl,
      };
    });

    return res.status(200).json({
      success: true,
      data: formattedPosts,
    });
  } catch (error) {
    next(error);
  }
};

const createPost = async (req, res, next) => {
  try {
    const { content } = req.body;
    let media_url = null;

    if (req.file) {
      media_url = `/uploads/${req.file.filename}`;
    }

    if (!content || content.trim().length === 0) {
      throw new AppError('Post content is required', 400, 'CONTENT_REQUIRED');
    }

    const post = await PostModel.create({
      content,
      media_url,
      user_id: req.user.id,
    });

    const { getFullImageUrl } = require('../utils/imageUrl');
    const fullUrl = getFullImageUrl(req.user.profile_picture, req, req.user.role);
    post.author_name = req.user.full_name || req.user.username;
    post.author_image = fullUrl;
    post.profileImage = fullUrl;
    post.avatarUrl = fullUrl;
    post.author_role = req.user.role;

    return res.status(201).json({
      success: true,
      message: 'Post created successfully',
      data: post,
    });
  } catch (error) {
    next(error);
  }
};

const updatePost = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { content } = req.body;
    let media_url = undefined;

    if (req.file) {
      media_url = `/uploads/${req.file.filename}`;
    }

    const post = await PostModel.update(id, { content, media_url });

    if (!post) {
      throw new AppError('Post not found', 404, 'POST_NOT_FOUND');
    }

    const { getFullImageUrl } = require('../utils/imageUrl');
    const fullUrl = getFullImageUrl(req.user.profile_picture, req, req.user.role);
    post.author_name = req.user.full_name || req.user.username;
    post.author_image = fullUrl;
    post.profileImage = fullUrl;
    post.avatarUrl = fullUrl;
    post.author_role = req.user.role;

    return res.status(200).json({
      success: true,
      message: 'Post updated successfully',
      data: post,
    });
  } catch (error) {
    next(error);
  }
};

const deletePost = async (req, res, next) => {
  try {
    const { id } = req.params;
    const post = await PostModel.delete(id);

    if (!post) {
      throw new AppError('Post not found', 404, 'POST_NOT_FOUND');
    }

    return res.status(200).json({
      success: true,
      message: 'Post deleted successfully',
    });
  } catch (error) {
    next(error);
  }
};

const toggleLovePost = async (req, res, next) => {
  try {
    const { id } = req.params;
    const result = await PostModel.toggleLove(id, req.user.id);

    return res.status(200).json({
      success: true,
      data: result,
    });
  } catch (error) {
    next(error);
  }
};

// ─── Comment Controllers ─────────────────────────────────────────────────────

const listComments = async (req, res, next) => {
  try {
    const { postId } = req.params;
    const currentUserId = req.user ? req.user.id : null;
    const comments = await PostModel.findCommentsByPostId(postId, currentUserId);
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

const addComment = async (req, res, next) => {
  try {
    const { postId } = req.params;
    const { content } = req.body;

    if (!content || content.trim().length === 0) {
      throw new AppError('Comment content is required', 400, 'CONTENT_REQUIRED');
    }

    const comment = await PostModel.addComment(postId, req.user.id, content);
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

const deleteComment = async (req, res, next) => {
  try {
    const { id } = req.params;
    const comment = await PostModel.deleteComment(id, req.user.id, req.user.role);

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

const toggleLikeComment = async (req, res, next) => {
  try {
    const { id } = req.params;
    const result = await PostModel.toggleLikeComment(id, req.user.id);

    return res.status(200).json({
      success: true,
      data: result,
    });
  } catch (error) {
    next(error);
  }
};

const addCommentReply = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { content } = req.body;

    if (!content || content.trim().length === 0) {
      throw new AppError('Reply content is required', 400, 'CONTENT_REQUIRED');
    }

    const reply = await PostModel.addCommentReply(id, req.user.id, content);
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
  listPosts,
  createPost,
  updatePost,
  deletePost,
  toggleLovePost,
  listComments,
  addComment,
  deleteComment,
  toggleLikeComment,
  addCommentReply,
};
