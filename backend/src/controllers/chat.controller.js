'use strict';

const ChatModel = require('../models/chat.model');
const { query } = require('../database/connection');
const { AppError } = require('../utils/AppError');
const { sendPushNotification } = require('../utils/notification');

/**
 * Helper to fetch the admin user ID
 */
async function getAdminId() {
  const result = await query("SELECT id FROM users WHERE role = 'admin' LIMIT 1");
  return result.rows[0]?.id || null;
}

/**
 * POST /api/chat/messages
 * Send a message
 */
exports.sendMessage = async (req, res, next) => {
  try {
    const { content } = req.body;
    let { receiverId } = req.body;
    const senderId = req.user.id;
    const isSenderAdmin = req.user.role === 'admin';

    let mediaUrl = null;
    if (req.file) {
      mediaUrl = `/uploads/${req.file.filename}`;
    }

    if ((!content || content.trim() === '') && !mediaUrl) {
      return next(new AppError('Message content or image attachment is required', 400));
    }

    if (!isSenderAdmin) {
      // Normal user sending to Admin. Resolve Admin ID.
      const adminId = await getAdminId();
      if (!adminId) {
        return next(new AppError('Admin account not found', 404));
      }
      receiverId = adminId;
    } else {
      // Admin sending to user. receiverId is required.
      if (!receiverId) {
        return next(new AppError('receiverId is required for admin replies', 400));
      }
    }

    const message = await ChatModel.createMessage({
      senderId,
      receiverId,
      content: content || '',
      mediaUrl,
    });

    // Broadcast message via Socket.IO
    const io = require('../socket').getIo();
    if (io) {
      // Emit message to receiver's private room
      io.to(`user_${receiverId}`).emit('new_message', message);
      
      // Emit message back to sender's other sessions
      io.to(`user_${senderId}`).emit('new_message', message);

      // Notify admins if user sent message to admin
      if (!isSenderAdmin) {
        io.to('admin_inbox').emit('admin_new_message', {
          message,
          sender: {
            id: senderId,
            full_name: req.user.full_name,
            username: req.user.username,
            profileImage: req.user.profileImage,
            avatarUrl: req.user.avatarUrl,
          },
        });
      }
    }

    // Send Push Notification in the background
    const title = isSenderAdmin ? 'Message from Rafiq Admin' : `New message from ${req.user.full_name || req.user.username}`;
    sendPushNotification(receiverId, {
      title,
      body: content || 'Sent an image',
      data: {
        type: 'chat_message',
        sender_id: senderId,
        message_id: message.id,
      },
    });

    res.status(201).json({
      success: true,
      data: message,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/chat/messages/:userId
 * Load conversation history between the authenticated user and target userId
 */
exports.getHistory = async (req, res, next) => {
  try {
    const requesterId = req.user.id;
    const isRequesterAdmin = req.user.role === 'admin';
    const targetUserId = req.params.userId;

    let adminId;
    let userId;

    if (isRequesterAdmin) {
      adminId = requesterId;
      userId = targetUserId;
    } else {
      // Normal users can only view their own history with Admin.
      userId = requesterId;
      adminId = await getAdminId();
      if (!adminId) {
        return next(new AppError('Admin account not found', 404));
      }
    }

    const messages = await ChatModel.getHistory(adminId, userId);

    res.status(200).json({
      success: true,
      data: messages,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * PATCH /api/chat/conversations/:userId/read
 * Mark messages in a conversation as read
 */
exports.markAsRead = async (req, res, next) => {
  try {
    const requesterId = req.user.id;
    const isRequesterAdmin = req.user.role === 'admin';
    const targetUserId = req.params.userId;

    let senderId;
    let receiverId;

    if (isRequesterAdmin) {
      // Admin marks messages sent by the user (targetUserId) as read
      senderId = targetUserId;
      receiverId = requesterId;
    } else {
      // User marks messages sent by Admin as read
      const adminId = await getAdminId();
      if (!adminId) {
        return next(new AppError('Admin account not found', 404));
      }
      senderId = adminId;
      receiverId = requesterId;
    }

    const updatedCount = await ChatModel.markAsRead(senderId, receiverId);

    res.status(200).json({
      success: true,
      data: {
        updated_count: updatedCount,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/chat/conversations
 * Admin Dashboard: List all user conversations (Admin only)
 */
exports.getConversations = async (req, res, next) => {
  try {
    if (req.user.role !== 'admin') {
      return next(new AppError('Forbidden: Access denied', 403));
    }

    const adminId = req.user.id;
    const { search } = req.query;

    const conversations = await ChatModel.getConversations(adminId, search || '');
    const { getFullImageUrl } = require('../utils/imageUrl');

    const formattedConversations = conversations.map((conv) => {
      const fullUrl = getFullImageUrl(conv.profile_picture, req, 'user');
      return {
        ...conv,
        profile_picture: fullUrl,
        profileImage: fullUrl,
        avatarUrl: fullUrl,
      };
    });

    res.status(200).json({
      success: true,
      data: formattedConversations,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/chat/unread
 * Get total unread count for current user
 */
exports.getUnreadCount = async (req, res, next) => {
  try {
    const count = await ChatModel.getUnreadCount(req.user.id, req.user.role);

    res.status(200).json({
      success: true,
      data: {
        unread_count: count,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * POST /api/chat/register-token
 * Register FCM push token for current user
 */
exports.registerFcmToken = async (req, res, next) => {
  try {
    const { token } = req.body;
    if (!token) {
      return next(new AppError('FCM token is required', 400));
    }

    const record = await ChatModel.saveFcmToken(req.user.id, token);

    res.status(200).json({
      success: true,
      data: record,
    });
  } catch (error) {
    next(error);
  }
};
