'use strict';

const { Router } = require('express');
const chatController = require('../controllers/chat.controller');
const { authenticate, requireAdmin } = require('../middleware/authenticate');

const router = Router();

// All chat routes require JWT authentication
router.use(authenticate);

const upload = require('../middleware/upload');

/**
 * POST /api/chat/messages
 * Send a message (User to Admin, or Admin to User)
 */
router.post('/messages', upload.single('image'), chatController.sendMessage);

/**
 * GET /api/chat/messages/:userId
 * Load conversation history with target userId
 */
router.get('/messages/:userId', chatController.getHistory);

/**
 * PATCH /api/chat/conversations/:userId/read
 * Mark messages in conversation with userId as read
 */
router.patch('/conversations/:userId/read', chatController.markAsRead);

/**
 * GET /api/chat/conversations
 * Admin Dashboard: List all user conversations (Admin only)
 */
router.get('/conversations', requireAdmin, chatController.getConversations);

/**
 * GET /api/chat/unread
 * Get total unread count for current user
 */
router.get('/unread', chatController.getUnreadCount);

/**
 * POST /api/chat/register-token
 * Register FCM push token for current user
 */
router.post('/register-token', chatController.registerFcmToken);

module.exports = router;
