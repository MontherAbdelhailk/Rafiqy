'use strict';

const express = require('express');
const router = express.Router();
const { authenticate, requireAdmin } = require('../middleware/authenticate');
const {
  getMySessions,
  getAllSessions,
  getSessionById,
  joinSession,
  completeSession,
} = require('../controllers/session.controller');

// ── User routes ───────────────────────────────────────────────────────────────
// GET /api/sessions/mine — Get current user's sessions
router.get('/mine', authenticate, getMySessions);

// GET /api/sessions/:id — Get session details
router.get('/:id', authenticate, getSessionById);

// POST /api/sessions/:id/join — Join session (validates time window)
router.post('/:id/join', authenticate, joinSession);

// ── Admin routes ──────────────────────────────────────────────────────────────
// GET /api/sessions — Get all sessions (Admin)
router.get('/', authenticate, requireAdmin, getAllSessions);

// PATCH /api/sessions/:id/complete — Complete session (Admin)
router.patch('/:id/complete', authenticate, requireAdmin, completeSession);

module.exports = router;
