'use strict';

const BookingModel = require('../models/booking.model');
const SlotModel = require('../models/slot.model');
const SessionModel = require('../models/session.model');
const { AppError } = require('../utils/AppError');
const { sendPushNotification } = require('../utils/notification');
const logger = require('../utils/logger');

/**
 * POST /api/bookings
 * Create a new booking (User authenticated)
 */
const createBooking = async (req, res, next) => {
  try {
    const { slotId, notes } = req.body;
    const userId = req.user.id;

    if (!slotId) {
      return next(new AppError('slotId is required', 400, 'VALIDATION_ERROR'));
    }

    // Check slot exists and is available
    const slot = await SlotModel.findById(slotId);
    if (!slot) return next(new AppError('Slot not found', 404, 'SLOT_NOT_FOUND'));

    // 3NF: Check slot_state ENUM instead of dropped boolean columns
    if (slot.slot_state === 'disabled') {
      return next(new AppError('This slot is not available', 400, 'SLOT_UNAVAILABLE'));
    }
    if (slot.slot_state === 'reserved' || slot.slot_state === 'booked') {
      return next(new AppError('This slot has already been booked', 400, 'SLOT_ALREADY_BOOKED'));
    }

    // Create booking (transactional — locks slot)
    const booking = await BookingModel.create({
      userId,
      slotId,
      amount: slot.price,
      notes: notes || null,
    });

    if (!booking) {
      return next(new AppError('Slot was just taken by another user. Please select a different slot.', 409, 'SLOT_CONFLICT'));
    }

    logger.info(`📅 Booking created: ${booking.id} for user ${userId}`);

    // Send notification to admin about new booking
    try {
      await sendPushNotification('admin', {
        title: '🆕 New Booking Request',
        body: `${req.user.full_name || req.user.username} requested a consultation session.`,
        data: { type: 'NEW_BOOKING', bookingId: booking.id },
      });
    } catch (notifErr) {
      logger.warn(`Notification failed for booking ${booking.id}: ${notifErr.message}`);
    }

    res.status(201).json({
      success: true,
      data: booking,
      message: 'Booking created successfully. Please complete payment to confirm.',
    });
  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/bookings/mine
 * Get current user's bookings
 */
const getMyBookings = async (req, res, next) => {
  try {
    const { status, page = 1, limit = 20 } = req.query;
    const bookings = await BookingModel.findByUserId(req.user.id, {
      status,
      page: parseInt(page),
      limit: parseInt(limit),
    });
    res.json({ success: true, data: bookings });
  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/bookings/:id
 * Get a single booking by ID (owner or admin)
 */
const getBookingById = async (req, res, next) => {
  try {
    const booking = await BookingModel.findById(req.params.id);
    if (!booking) return next(new AppError('Booking not found', 404, 'BOOKING_NOT_FOUND'));

    // Ownership check (unless admin)
    if (req.user.role !== 'admin' && booking.user_id !== req.user.id) {
      return next(new AppError('Access denied', 403, 'FORBIDDEN'));
    }

    res.json({ success: true, data: booking });
  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/bookings (Admin only)
 * Get all bookings with search/filter/sort
 */
const getAllBookings = async (req, res, next) => {
  try {
    const { status, search, page = 1, limit = 20, sortBy = 'created_at', sortDir = 'DESC' } = req.query;
    const result = await BookingModel.findAll({
      status,
      search,
      page: parseInt(page),
      limit: parseInt(limit),
      sortBy,
      sortDir,
    });
    res.json({ success: true, ...result });
  } catch (err) {
    next(err);
  }
};

/**
 * PATCH /api/bookings/:id/cancel
 * Cancel a booking (user cancels own, or admin cancels any)
 */
const cancelBooking = async (req, res, next) => {
  try {
    const { reason } = req.body;
    const booking = await BookingModel.findById(req.params.id);

    if (!booking) return next(new AppError('Booking not found', 404, 'BOOKING_NOT_FOUND'));

    if (req.user.role !== 'admin' && booking.user_id !== req.user.id) {
      return next(new AppError('Access denied', 403, 'FORBIDDEN'));
    }

    if (!['pending_payment', 'confirmed'].includes(booking.status)) {
      return next(new AppError(`Cannot cancel a booking with status: ${booking.status}`, 400, 'INVALID_STATUS'));
    }

    const cancelled = await BookingModel.cancel(req.params.id, { reason, releasesSlot: true });

    if (!cancelled) {
      return next(new AppError('Cancellation failed', 500, 'CANCELLATION_FAILED'));
    }

    // Cancel associated session if exists
    const session = await SessionModel.findByBookingId(req.params.id);
    if (session) {
      await SessionModel.updateStatus(session.id, 'cancelled');
    }

    // Notify user if admin cancels
    if (req.user.role === 'admin' && booking.user_id !== req.user.id) {
      try {
        await sendPushNotification(booking.user_id, {
          title: '📋 Booking Cancelled',
          body: `Your consultation session on ${new Date(booking.start_time).toLocaleDateString()} has been cancelled.`,
          data: { type: 'BOOKING_CANCELLED', bookingId: booking.id },
        });
      } catch (notifErr) {
        logger.warn(`Notification failed: ${notifErr.message}`);
      }
    }

    res.json({ success: true, data: cancelled, message: 'Booking cancelled successfully' });
  } catch (err) {
    next(err);
  }
};

/**
 * PATCH /api/bookings/:id/complete (Admin only)
 * Mark a booking as completed
 */
const completeBooking = async (req, res, next) => {
  try {
    const booking = await BookingModel.findById(req.params.id);
    if (!booking) return next(new AppError('Booking not found', 404, 'BOOKING_NOT_FOUND'));

    const completed = await BookingModel.complete(req.params.id);
    if (!completed) {
      return next(new AppError('Booking cannot be completed. It must be in "confirmed" status.', 400, 'INVALID_STATUS'));
    }

    // Complete associated session
    const session = await SessionModel.findByBookingId(req.params.id);
    if (session) {
      await SessionModel.complete(session.id);
    }

    // Notify user
    try {
      await sendPushNotification(booking.user_id, {
        title: '✅ Session Completed',
        body: 'Your consultation session has been marked as completed. Thank you!',
        data: { type: 'SESSION_COMPLETED', bookingId: booking.id },
      });
    } catch (notifErr) {
      logger.warn(`Notification failed: ${notifErr.message}`);
    }

    res.json({ success: true, data: completed, message: 'Booking marked as completed' });
  } catch (err) {
    next(err);
  }
};

/**
 * DELETE /api/bookings/:id (Admin only)
 * Hard-delete a booking and all associated records.
 *
 * Business logic:
 *  - Releases the time slot (is_booked=FALSE, is_available=TRUE)
 *  - Deletes the booking row; sessions + payments cascade automatically
 *  - Notifies the user that their booking was removed by the admin
 */
const deleteBooking = async (req, res, next) => {
  try {
    const { id } = req.params;

    // Load the booking first so we can notify the user and log context
    const booking = await BookingModel.findById(id);
    if (!booking) {
      return next(new AppError('Booking not found', 404, 'BOOKING_NOT_FOUND'));
    }

    // Execute the transactional hard delete
    const deleted = await BookingModel.adminDelete(id);
    if (!deleted) {
      return next(new AppError('Booking deletion failed', 500, 'DELETE_FAILED'));
    }

    logger.info(`🗑️  Admin ${req.user.id} deleted booking ${id} (slot ${deleted.slot_id})`);

    // Notify the user — best-effort, never block the response
    try {
      await sendPushNotification(booking.user_id, {
        title: '📋 Booking Removed',
        body: 'Your consultation booking has been removed by the administrator. The time slot has been released.',
        data: { type: 'BOOKING_DELETED', bookingId: id },
      });
    } catch (notifErr) {
      logger.warn(`Delete notification failed for booking ${id}: ${notifErr.message}`);
    }

    res.json({
      success: true,
      message: 'Booking deleted successfully',
      data: { id: deleted.id, slotId: deleted.slot_id, status: deleted.status },
    });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  createBooking,
  getMyBookings,
  getBookingById,
  getAllBookings,
  cancelBooking,
  completeBooking,
  deleteBooking,
};
