'use strict';

const SessionModel = require('../models/session.model');
const BookingModel = require('../models/booking.model');
const { buildJitsiUrl, checkJoinWindow } = require('../services/jitsi.service');
const { AppError } = require('../utils/AppError');
const { sendPushNotification } = require('../utils/notification');
const logger = require('../utils/logger');

/**
 * GET /api/sessions/mine
 * Get current user's sessions
 */
const getMySessions = async (req, res, next) => {
  try {
    const { status, page = 1, limit = 20 } = req.query;
    const sessions = await SessionModel.findByUserId(req.user.id, {
      status,
      page: parseInt(page),
      limit: parseInt(limit),
    });

    // Attach jitsi URLs
    const sessionWithUrls = sessions.map((s) => ({
      ...s,
      jitsi_url: buildJitsiUrl(s.jitsi_room_name),
    }));

    res.json({ success: true, data: sessionWithUrls });
  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/sessions
 * Get all sessions (Admin only)
 */
const getAllSessions = async (req, res, next) => {
  try {
    const { status, search, page = 1, limit = 20 } = req.query;
    const result = await SessionModel.findAll({
      status,
      search,
      page: parseInt(page),
      limit: parseInt(limit),
    });

    // Attach jitsi URLs
    result.sessions = result.sessions.map((s) => ({
      ...s,
      jitsi_url: buildJitsiUrl(s.jitsi_room_name),
    }));

    res.json({ success: true, ...result });
  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/sessions/:id
 * Get session details (owner or admin)
 */
const getSessionById = async (req, res, next) => {
  try {
    const session = await SessionModel.findById(req.params.id);
    if (!session) return next(new AppError('Session not found', 404, 'SESSION_NOT_FOUND'));

    if (req.user.role !== 'admin' && session.user_id !== req.user.id) {
      return next(new AppError('Access denied', 403, 'FORBIDDEN'));
    }

    res.json({
      success: true,
      data: {
        ...session,
        jitsi_url: buildJitsiUrl(session.jitsi_room_name),
      },
    });
  } catch (err) {
    next(err);
  }
};

/**
 * POST /api/sessions/:id/join
 * Validate join access and return Jitsi URL
 * Checks time window and session status
 */
const joinSession = async (req, res, next) => {
  try {
    const session = await SessionModel.findById(req.params.id);
    if (!session) return next(new AppError('Session not found', 404, 'SESSION_NOT_FOUND'));

    // Ownership check (user or admin)
    const isAdmin = req.user.role === 'admin';
    if (!isAdmin && session.user_id !== req.user.id) {
      return next(new AppError('Access denied', 403, 'FORBIDDEN'));
    }

    // Check booking is confirmed
    if (session.booking_status !== 'confirmed') {
      return next(new AppError('Booking is not confirmed. Payment may still be pending.', 400, 'BOOKING_NOT_CONFIRMED'));
    }

    // Check session is not cancelled or completed
    if (['cancelled', 'completed'].includes(session.status)) {
      return next(new AppError(`Session is ${session.status} and cannot be joined.`, 400, 'SESSION_ENDED'));
    }

    // Time window validation
    const { allowed, reason } = checkJoinWindow(session.start_time, session.duration_mins);
    if (!allowed) {
      return next(new AppError(reason, 400, 'JOIN_WINDOW_CLOSED'));
    }

    // Record join
    if (isAdmin) {
      await SessionModel.recordAdminJoin(session.id);
      logger.info(`👨‍⚕️ Admin joined session ${session.id}`);
    } else {
      await SessionModel.recordUserJoin(session.id);
      logger.info(`👤 User ${req.user.id} joined session ${session.id}`);
    }

    const jitsiUrl = buildJitsiUrl(session.jitsi_room_name);

    // Notify the other party
    try {
      if (!isAdmin) {
        // Notify admin that user has joined
        await sendPushNotification('admin', {
          title: '🟢 User Joined Session',
          body: `${req.user.full_name || req.user.username} has joined the consultation session.`,
          data: { type: 'USER_JOINED', sessionId: session.id },
        });
      } else {
        // Notify user that admin has joined
        await sendPushNotification(session.user_id, {
          title: '🟢 Dr. is Ready',
          body: 'Your consultant has joined the session. Click to join!',
          data: { type: 'ADMIN_JOINED', sessionId: session.id, jitsiUrl },
        });
      }
    } catch (notifErr) {
      logger.warn(`Join notification failed: ${notifErr.message}`);
    }

    res.json({
      success: true,
      data: {
        sessionId: session.id,
        jitsiRoomName: session.jitsi_room_name,
        jitsiUrl,
        startTime: session.start_time,
        durationMins: session.duration_mins,
        isAdmin,
      },
    });
  } catch (err) {
    next(err);
  }
};

/**
 * PATCH /api/sessions/:id/complete (Admin only)
 * Mark a session as completed
 */
const completeSession = async (req, res, next) => {
  try {
    const session = await SessionModel.findById(req.params.id);
    if (!session) return next(new AppError('Session not found', 404, 'SESSION_NOT_FOUND'));

    const completed = await SessionModel.complete(req.params.id);
    if (!completed) {
      return next(new AppError('Session cannot be completed in its current state.', 400, 'INVALID_STATUS'));
    }

    // Also complete the booking
    await BookingModel.complete(session.booking_id);

    // Notify user
    try {
      await sendPushNotification(session.user_id, {
        title: '✅ Session Completed',
        body: 'Your consultation session has ended. Thank you for using Rafiq!',
        data: { type: 'SESSION_COMPLETED', sessionId: session.id },
      });
    } catch (notifErr) {
      logger.warn(`Notification failed: ${notifErr.message}`);
    }

    res.json({ success: true, data: completed, message: 'Session marked as completed' });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getMySessions,
  getAllSessions,
  getSessionById,
  joinSession,
  completeSession,
};
