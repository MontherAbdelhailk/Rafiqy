'use strict';

const express = require('express');
const router = express.Router();
const { authenticate, requireAdmin } = require('../middleware/authenticate');
const {
  getAvailableSlots,
  getAllSlotsAdmin,
  getSlotById,
  createSlot,
  updateSlot,
  deleteSlot,
} = require('../controllers/slot.controller');

// ── Public (authenticated users) ─────────────────────────────────────────────
// GET /api/slots — Get available slots
router.get('/', authenticate, getAvailableSlots);

// GET /api/slots/:id — Get slot detail
router.get('/:id', authenticate, getSlotById);

// ── Admin only ─────────────────────────────────────────────────────────────
// GET /api/slots/admin/all — Get all slots (including booked)
router.get('/admin/all', authenticate, requireAdmin, getAllSlotsAdmin);

// POST /api/slots — Create a slot
router.post('/', authenticate, requireAdmin, createSlot);

// PATCH /api/slots/:id — Update a slot
router.patch('/:id', authenticate, requireAdmin, updateSlot);

// DELETE /api/slots/:id — Delete a slot
router.delete('/:id', authenticate, requireAdmin, deleteSlot);

module.exports = router;
