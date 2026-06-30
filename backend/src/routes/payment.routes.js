'use strict';

const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/authenticate');
const {
  initiateBookingPayment,
  handlePaymobWebhook,
  verifyDevPayment,
  getPaymentStatus,
} = require('../controllers/payment.controller');

// ── Payment initiation (authenticated user) ───────────────────────────────────
// POST /api/payments/initiate — Start Paymob payment for a booking
router.post('/initiate', authenticate, initiateBookingPayment);

// ── Paymob Webhook (no auth — verified via HMAC) ─────────────────────────────
// POST /api/payments/webhook — Paymob callback
// Note: Uses raw body to allow HMAC verification
router.post('/webhook', handlePaymobWebhook);

// ── Dev-Only: Simulate payment confirmation ───────────────────────────────────
// POST /api/payments/verify-dev/:bookingId
// ⚠️  DEVELOPMENT ONLY — automatically returns 404 when NODE_ENV=production
// Executes the same business logic as the production webhook success path.
// Triggered by the "Verify Payment" button in the Paymob sandbox WebView.
router.post('/verify-dev/:bookingId', authenticate, verifyDevPayment);

// ── Payment Status ────────────────────────────────────────────────────────────
// GET /api/payments/status/:bookingId
router.get('/status/:bookingId', authenticate, getPaymentStatus);

module.exports = router;
