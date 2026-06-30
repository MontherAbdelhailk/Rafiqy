'use strict';

const SlotModel = require('../models/slot.model');
const { AppError } = require('../utils/AppError');

/**
 * GET /api/slots
 * Get available slots (user-facing)
 */
const getAvailableSlots = async (req, res, next) => {
  try {
    const { from, to } = req.query;
    const slots = await SlotModel.getAvailableSlots({ from, to });
    res.json({ success: true, data: slots });
  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/slots/admin
 * Get all slots including booked ones (Admin only)
 */
const getAllSlotsAdmin = async (req, res, next) => {
  try {
    const { from, to, page = 1, limit = 50 } = req.query;
    const result = await SlotModel.getAllAdmin({ from, to, page: parseInt(page), limit: parseInt(limit) });
    res.json({ success: true, ...result });
  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/slots/:id
 * Get a single slot
 */
const getSlotById = async (req, res, next) => {
  try {
    const slot = await SlotModel.findById(req.params.id);
    if (!slot) return next(new AppError('Slot not found', 404, 'SLOT_NOT_FOUND'));
    res.json({ success: true, data: slot });
  } catch (err) {
    next(err);
  }
};

/**
 * POST /api/slots
 * Create a new slot (Admin only)
 */
const createSlot = async (req, res, next) => {
  try {
    const { startTime, endTime, durationMins, price, notes } = req.body;

    if (!startTime || !endTime) {
      return next(new AppError('startTime and endTime are required', 400, 'VALIDATION_ERROR'));
    }

    const start = new Date(startTime);
    const end = new Date(endTime);

    if (isNaN(start) || isNaN(end)) {
      return next(new AppError('Invalid date format', 400, 'VALIDATION_ERROR'));
    }

    if (end <= start) {
      return next(new AppError('endTime must be after startTime', 400, 'VALIDATION_ERROR'));
    }

    if (start < new Date()) {
      return next(new AppError('Cannot create slots in the past', 400, 'VALIDATION_ERROR'));
    }

    const slot = await SlotModel.create({
      startTime: start.toISOString(),
      endTime: end.toISOString(),
      durationMins: durationMins || 45,
      price: price || 750.00,
      notes,
      createdBy: req.user.id,
    });

    res.status(201).json({ success: true, data: slot, message: 'Slot created successfully' });
  } catch (err) {
    next(err);
  }
};

/**
 * PATCH /api/slots/:id
 * Update a slot (Admin only)
 */
const updateSlot = async (req, res, next) => {
  try {
    const { startTime, endTime, durationMins, price, isAvailable, notes } = req.body;

    const existing = await SlotModel.findById(req.params.id);
    if (!existing) return next(new AppError('Slot not found', 404, 'SLOT_NOT_FOUND'));

    if (existing.is_booked) {
      return next(new AppError('Cannot modify a booked slot', 400, 'SLOT_BOOKED'));
    }

    const slot = await SlotModel.update(req.params.id, {
      startTime, endTime, durationMins, price, isAvailable, notes,
    });

    res.json({ success: true, data: slot, message: 'Slot updated successfully' });
  } catch (err) {
    next(err);
  }
};

/**
 * DELETE /api/slots/:id
 * Delete a slot — only if not booked (Admin only)
 */
const deleteSlot = async (req, res, next) => {
  try {
    const deleted = await SlotModel.delete(req.params.id);
    if (!deleted) {
      return next(new AppError('Slot not found or is already booked and cannot be deleted', 400, 'SLOT_DELETE_FAILED'));
    }
    res.json({ success: true, message: 'Slot deleted successfully' });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getAvailableSlots,
  getAllSlotsAdmin,
  getSlotById,
  createSlot,
  updateSlot,
  deleteSlot,
};
