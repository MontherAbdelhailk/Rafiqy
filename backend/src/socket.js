'use strict';

const socketIo = require('socket.io');
const jwt = require('jsonwebtoken');
const UserModel = require('./models/user.model');
const ChatModel = require('./models/chat.model');
const logger = require('./utils/logger');
const { query } = require('./database/connection');
const { sendPushNotification } = require('./utils/notification');

/**
 * Helper to fetch the admin user ID
 */
async function getAdminId() {
  const result = await query("SELECT id FROM users WHERE role = 'admin' LIMIT 1");
  return result.rows[0]?.id || null;
}

let io = null;

function initSocket(server) {
  io = socketIo(server, {
    cors: {
      origin: '*', // Allow all origins for mobile compatibility
      methods: ['GET', 'POST'],
    },
  });

  // Socket.IO Authentication Middleware
  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth?.token || socket.handshake.query?.token;
      if (!token) {
        return next(new Error('Authentication error: Token required'));
      }

      // Strip "Bearer " prefix if present
      const cleanToken = token.startsWith('Bearer ') ? token.slice(7) : token;

      let decoded;
      try {
        decoded = jwt.verify(cleanToken, process.env.JWT_SECRET, {
          issuer: 'rafiq-api',
          audience: 'rafiq-client',
        });
      } catch (err) {
        return next(new Error('Authentication error: Invalid or expired token'));
      }

      const user = await UserModel.findById(decoded.sub);
      if (!user) {
        return next(new Error('Authentication error: User no longer exists'));
      }
      if (user.status !== 'active') {
        return next(new Error('Authentication error: Account is inactive'));
      }

      // Attach sanitized user information to socket
      socket.user = {
        id: user.id,
        username: user.username,
        full_name: user.full_name,
        role: user.role,
      };

      next();
    } catch (error) {
      logger.error('Socket authentication error:', error.message);
      next(new Error('Authentication error: Internal server error'));
    }
  });

  io.on('connection', (socket) => {
    const userId = socket.user.id;
    const userRole = socket.user.role;

    logger.info(`🔌 User connected to socket: ${socket.user.username} (${userId}) as ${userRole}`);

    // Join user's individual room
    socket.join(`user_${userId}`);

    // Admins join general admin inbox room for real-time dashboard updates
    if (userRole === 'admin') {
      socket.join('admin_inbox');
    }

    // Event: Sending a message
    socket.on('send_message', async (data, callback) => {
      try {
        const { content } = data;
        let { receiverId } = data;

        if (!content || content.trim() === '') {
          if (callback) callback({ success: false, error: 'Message content is required' });
          return;
        }

        if (userRole !== 'admin') {
          // Normal user messages always go to Admin. Resolve Admin ID dynamically.
          const adminId = await getAdminId();
          if (!adminId) {
            if (callback) callback({ success: false, error: 'Admin account not found' });
            return;
          }
          receiverId = adminId;
        } else {
          // Admin replies require a receiverId
          if (!receiverId) {
            if (callback) callback({ success: false, error: 'receiverId is required for admin replies' });
            return;
          }
        }

        const message = await ChatModel.createMessage({
          senderId: userId,
          receiverId,
          content,
        });

        // Emit message to receiver's private room
        io.to(`user_${receiverId}`).emit('new_message', message);
        
        // Emit message back to sender's other sessions
        io.to(`user_${userId}`).emit('new_message', message);

        // Notify admins if user sent message to admin
        if (userRole !== 'admin') {
          io.to('admin_inbox').emit('admin_new_message', {
            message,
            sender: {
              id: userId,
              full_name: socket.user.full_name,
              username: socket.user.username,
            },
          });
        }

        // Trigger push notification in background
        const pushTitle = userRole === 'admin' ? 'Message from Rafiq Admin' : `New message from ${socket.user.full_name || socket.user.username}`;
        sendPushNotification(receiverId, {
          title: pushTitle,
          body: content,
          data: {
            type: 'chat_message',
            sender_id: userId,
            message_id: message.id,
          },
        });

        if (callback) {
          callback({ success: true, data: message });
        }
      } catch (err) {
        logger.error(`Socket send_message error: ${err.message}`);
        if (callback) callback({ success: false, error: 'Failed to send message' });
      }
    });

    // Event: Live Typing Status
    socket.on('typing_status', async (data) => {
      const { receiverId, isTyping } = data;
      if (!receiverId) return;

      let actualReceiverId = receiverId;
      if (receiverId === 'admin') {
        actualReceiverId = await getAdminId();
      }
      if (!actualReceiverId) return;

      // Use role-based alias so client can match against _activeRoomUserId ('admin' or UUID)
      const senderIdentifier = userRole === 'admin' ? 'admin' : userId;

      // Use socket.to() (not io.to()) so the typing event is NEVER echoed back to the sender
      socket.to(`user_${actualReceiverId}`).emit('typing_status', {
        senderId: senderIdentifier,  // role-based alias for client-side room matching
        typerId: userId,             // actual UUID — used by client to block self-indicator
        isTyping,
      });
    });

    // Event: Mark Messages as Read
    socket.on('mark_read', async (data, callback) => {
      try {
        const { senderId } = data; // Sender of the messages being read
        if (!senderId) {
          if (callback) callback({ success: false, error: 'senderId is required' });
          return;
        }

        let actualSenderId = senderId;
        if (senderId === 'admin') {
          actualSenderId = await getAdminId();
        }
        if (!actualSenderId) {
          if (callback) callback({ success: false, error: 'Admin account not found' });
          return;
        }

        // requester (receiverId) is the current user marking messages as read
        const updatedCount = await ChatModel.markAsRead(actualSenderId, userId);

        // Notify both users that read status updated
        io.to(`user_${actualSenderId}`).emit('read_status_updated', {
          senderId: actualSenderId,
          receiverId: userId,
          updatedCount,
        });

        io.to(`user_${userId}`).emit('read_status_updated', {
          senderId: actualSenderId,
          receiverId: userId,
          updatedCount,
        });

        if (userRole === 'admin') {
          // Notify other admins to sync inbox list
          io.to('admin_inbox').emit('admin_conversations_updated');
        }

        if (callback) {
          callback({ success: true, updatedCount });
        }
      } catch (err) {
        logger.error(`Socket mark_read error: ${err.message}`);
        if (callback) callback({ success: false, error: 'Failed to update read status' });
      }
    });

    socket.on('disconnect', () => {
      logger.info(`🔌 User disconnected from socket: ${socket.user.username}`);
    });
  });

  return io;
}

function getIo() {
  return io;
}

module.exports = {
  initSocket,
  getIo,
};
