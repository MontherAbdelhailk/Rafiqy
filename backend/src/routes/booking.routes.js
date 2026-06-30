'use strict';

const express = require('express');
const router = express.Router();
const { authenticate, requireAdmin } = require('../middleware/authenticate');
const {
  createBooking,
  getMyBookings,
  getBookingById,
  getAllBookings,
  cancelBooking,
  completeBooking,
  deleteBooking,
} = require('../controllers/booking.controller');

// ── User routes ───────────────────────────────────────────────────────────────
// POST /api/bookings — Create booking
router.post('/', authenticate, createBooking);

// GET /api/bookings/mine — Get my bookings
router.get('/mine', authenticate, getMyBookings);

// GET /api/bookings/:id — Get specific booking (owner or admin)
router.get('/:id', authenticate, getBookingById);

// PATCH /api/bookings/:id/cancel — Cancel booking (owner or admin)
router.patch('/:id/cancel', authenticate, cancelBooking);

// ── Admin routes ──────────────────────────────────────────────────────────────
// GET /api/bookings — Get all bookings (Admin)
router.get('/', authenticate, requireAdmin, getAllBookings);

// PATCH /api/bookings/:id/complete — Complete booking (Admin)
router.patch('/:id/complete', authenticate, requireAdmin, completeBooking);

// DELETE /api/bookings/:id — Hard delete a booking with full cleanup (Admin only)
// Releases the slot, deletes the booking, cascades to sessions + payments.
router.delete('/:id', authenticate, requireAdmin, deleteBooking);

module.exports = router;
