'use strict';

const PaymentModel = require('../models/payment.model');
const BookingModel = require('../models/booking.model');
const SessionModel = require('../models/session.model');
const { query: dbQuery } = require('../database/connection');
const { initiatePayment, verifyWebhookHmac } = require('../services/paymob.service');
const { buildJitsiUrl } = require('../services/jitsi.service');
const { executePaymentSuccessFlow } = require('../services/payment_success.service');
const { AppError } = require('../utils/AppError');
const { sendPushNotification } = require('../utils/notification');
const logger = require('../utils/logger');

/**
 * POST /api/payments/initiate
 * Initiate a Paymob payment for a booking
 * Body: { bookingId }
 */
const initiateBookingPayment = async (req, res, next) => {
  try {
    const { bookingId, paymentMethod = 'card', walletNumber } = req.body;
    const userId = req.user.id;

    if (!bookingId) {
      return next(new AppError('bookingId is required', 400, 'VALIDATION_ERROR'));
    }

    // Verify booking ownership
    const booking = await BookingModel.findById(bookingId);
    if (!booking) return next(new AppError('Booking not found', 404, 'BOOKING_NOT_FOUND'));
    if (booking.user_id !== userId) return next(new AppError('Access denied', 403, 'FORBIDDEN'));
    if (booking.status !== 'pending_payment') {
      return next(new AppError(`Cannot initiate payment for booking with status: ${booking.status}`, 400, 'INVALID_STATUS'));
    }

    // Create payment record
    const payment = await PaymentModel.create({
      bookingId,
      userId,
      amount: booking.amount,
    });

    // Paymob billing data from user
    const billingData = {
      apartment: 'NA',
      email: req.user.email || 'user@rafiq.app',
      floor: 'NA',
      first_name: req.user.first_name || req.user.full_name?.split(' ')[0] || 'User',
      street: 'NA',
      building: 'NA',
      phone_number: req.user.phone_number || '+20100000000',
      shipping_method: 'NA',
      postal_code: 'NA',
      city: 'Cairo',
      country: 'EG',
      last_name: req.user.last_name || req.user.full_name?.split(' ').slice(1).join(' ') || 'Rafiq',
      state: 'NA',
    };

    // Initiate payment with Paymob
    const { paymentKey, orderId, iframeUrl, amountCents } = await initiatePayment({
      amountEGP: booking.amount,
      merchantOrderId: `rafiq-${bookingId}-${Date.now()}`,
      billingData,
      paymentMethod,
      walletNumber,
    });

    // Update payment record with Paymob order info
    await PaymentModel.updatePaymobInfo(payment.id, {
      paymobOrderId: String(orderId),
      paymobPaymentKey: paymentKey,
    });

    logger.info(`💳 Payment initiated for booking ${bookingId}: Paymob Order ${orderId}`);

    res.json({
      success: true,
      data: {
        paymentId: payment.id,
        iframeUrl,
        paymentKey,
        amountCents,
        amount: booking.amount,
        bookingId,
      },
    });
  } catch (err) {
    logger.error(`Payment initiation failed: ${err.message}`);
    // If it's a Paymob config error, don't expose internals
    if (err.message.includes('not configured')) {
      return next(new AppError('Payment service is not configured. Please contact support.', 503, 'PAYMENT_UNAVAILABLE'));
    }
    next(err);
  }
};

/**
 * POST /api/payments/webhook
 * Paymob webhook — processes transaction callbacks
 * Must be raw body for HMAC verification
 *
 * PRODUCTION PATH:
 *   Paymob Webhook → handlePaymobWebhook → executePaymentSuccessFlow()
 */
const handlePaymobWebhook = async (req, res, next) => {
  try {
    const receivedHmac = req.query.hmac;
    const callbackData = req.body;

    logger.info(`🔔 Paymob webhook received. HMAC: ${receivedHmac ? 'present' : 'missing'}`);

    // Verify HMAC signature
    const hmacSecret = process.env.PAYMOB_HMAC_SECRET;
    if (hmacSecret && receivedHmac) {
      const isValid = verifyWebhookHmac(hmacSecret, callbackData, receivedHmac);
      if (!isValid) {
        logger.error('❌ Invalid Paymob HMAC signature');
        return res.status(400).json({ success: false, message: 'Invalid signature' });
      }
      logger.info('✅ Paymob HMAC verified');
    } else {
      logger.warn('⚠️ Paymob HMAC verification skipped (secret not configured or HMAC missing)');
    }

    const transactionId = String(callbackData.id || callbackData.transaction?.id || '');
    const paymobOrderId = String(callbackData.order?.id || callbackData.order_id || '');
    const isSuccess = callbackData.success === true || callbackData.success === 'true';
    const isPending = callbackData.pending === true || callbackData.pending === 'true';
    const paymentMethod = callbackData.source_data?.sub_type || callbackData.source_data?.type || 'unknown';

    if (!paymobOrderId && !transactionId) {
      logger.warn('Webhook missing order/transaction ID');
      return res.status(200).json({ received: true });
    }

    // Deduplication: check if already processed
    if (transactionId) {
      const existing = await PaymentModel.findByTransactionId(transactionId);
      if (existing && existing.status === 'success') {
        logger.info(`Transaction ${transactionId} already processed. Skipping.`);
        return res.status(200).json({ received: true, skipped: true });
      }
    }

    // Find the payment record by Paymob order ID
    let payment = null;

    if (paymobOrderId) {
      const result = await dbQuery(
        "SELECT * FROM payments WHERE paymob_order_id = $1 ORDER BY created_at DESC LIMIT 1",
        [paymobOrderId]
      );
      payment = result.rows[0];
    }

    if (!payment) {
      logger.warn(`No payment record found for Paymob Order: ${paymobOrderId}`);
      return res.status(200).json({ received: true, warning: 'Payment record not found' });
    }

    if (isSuccess && !isPending) {
      // ✅ Payment success — delegate to shared service
      await executePaymentSuccessFlow(payment, {
        transactionId,
        paymentMethod,
        rawPayload: callbackData,
      });
    } else {
      // ❌ Payment failed or pending
      await PaymentModel.markFailed(payment.id, { rawPayload: callbackData });

      const booking = await BookingModel.findById(payment.booking_id);
      if (booking) {
        // Keep booking status as 'pending_payment' so user can retry payment.
        // Send notification to user
        try {
          await sendPushNotification(booking.user_id, {
            title: '❌ Payment Failed',
            body: 'Your payment could not be processed. You can retry payment from your Sessions dashboard.',
            data: { type: 'PAYMENT_FAILED', bookingId: payment.booking_id },
          });
        } catch (notifErr) {
          logger.warn(`Notification failed: ${notifErr.message}`);
        }
      }
    }

    // Always respond 200 to Paymob to prevent retries
    res.status(200).json({ received: true });
  } catch (err) {
    logger.error(`Webhook processing error: ${err.message}`, err);
    // Still return 200 to prevent Paymob from retrying invalid payloads
    res.status(200).json({ received: true, error: true });
  }
};

/**
 * POST /api/payments/verify-dev/:bookingId
 *
 * DEV-ONLY: Simulates a successful Paymob payment confirmation.
 *
 * DEVELOPMENT PATH:
 *   Verify Payment Button → verifyDevPayment → executePaymentSuccessFlow()
 *
 * This endpoint executes the exact same business logic as the production
 * webhook success path, allowing end-to-end testing in the sandbox
 * environment without waiting for an actual Paymob webhook callback.
 *
 * ⚠️  SECURITY: Guarded by NODE_ENV check — returns 404 in production.
 *     When switching to production, set NODE_ENV=production in .env.
 */
const verifyDevPayment = async (req, res, next) => {
  // ── Production guard ───────────────────────────────────────────────────────
  if (process.env.NODE_ENV === 'production') {
    return next(new AppError('Not found', 404, 'NOT_FOUND'));
  }

  try {
    const { bookingId } = req.params;
    const userId = req.user.id;

    logger.info(`🧪 [DEV] verify-dev requested for booking ${bookingId} by user ${userId}`);

    // ── 1. Load and validate the booking ──────────────────────────────────────
    const booking = await BookingModel.findById(bookingId);
    if (!booking) {
      return next(new AppError('Booking not found', 404, 'BOOKING_NOT_FOUND'));
    }
    if (booking.user_id !== userId) {
      return next(new AppError('Access denied', 403, 'FORBIDDEN'));
    }

    // ── 2. Find the pending payment for this booking ───────────────────────────
    const payment = await PaymentModel.findPendingByBookingId(bookingId);

    // ── 3. Idempotency — if already confirmed, return current state ────────────
    if (booking.status === 'confirmed') {
      logger.info(`[DEV] Booking ${bookingId} already confirmed — returning current state`);
      const existingSession = await SessionModel.findByBookingId(bookingId);
      const jitsiUrl = existingSession
        ? buildJitsiUrl(existingSession.jitsi_room_name)
        : null;

      return res.json({
        success: true,
        alreadyConfirmed: true,
        data: {
          bookingId,
          bookingStatus: 'confirmed',
          session: existingSession
            ? {
                id: existingSession.id,
                jitsiRoomName: existingSession.jitsi_room_name,
                jitsiUrl,
                status: existingSession.status,
              }
            : null,
        },
      });
    }

    // ── 4. Must have a pending payment to proceed ──────────────────────────────
    if (!payment) {
      return next(
        new AppError(
          'No pending payment found for this booking. Please initiate payment first.',
          400,
          'PAYMENT_NOT_FOUND'
        )
      );
    }

    // ── 5. Execute the shared payment success flow ─────────────────────────────
    const { booking: confirmedBooking, session, jitsiUrl } = await executePaymentSuccessFlow(
      payment,
      {
        transactionId: `dev-verify-${Date.now()}`,
        paymentMethod: 'card',
        rawPayload: { source: 'dev_verify_button', bookingId, userId, timestamp: new Date().toISOString() },
      }
    );

    logger.info(`✅ [DEV] Payment verification complete — booking ${bookingId} confirmed`);

    res.json({
      success: true,
      data: {
        bookingId,
        bookingStatus: confirmedBooking.status,
        payment: {
          status: 'success',
        },
        session: session
          ? {
              id: session.id,
              jitsiRoomName: session.jitsi_room_name,
              jitsiUrl,
              status: session.status,
            }
          : null,
      },
    });
  } catch (err) {
    logger.error(`[DEV] verifyDevPayment error: ${err.message}`, err);
    next(err);
  }
};

/**
 * GET /api/payments/status/:bookingId
 * Check payment status for a booking (user or admin)
 */
const getPaymentStatus = async (req, res, next) => {
  try {
    const { bookingId } = req.params;

    const booking = await BookingModel.findById(bookingId);
    if (!booking) return next(new AppError('Booking not found', 404, 'BOOKING_NOT_FOUND'));

    if (req.user.role !== 'admin' && booking.user_id !== req.user.id) {
      return next(new AppError('Access denied', 403, 'FORBIDDEN'));
    }

    const payment = await PaymentModel.findByBookingId(bookingId);
    const session = await SessionModel.findByBookingId(bookingId);

    res.json({
      success: true,
      data: {
        bookingId,
        bookingStatus: booking.status,
        payment: payment ? {
          id: payment.id,
          status: payment.status,
          amount: payment.amount,
          currency: payment.currency,
          paymentMethod: payment.payment_method,
          processedAt: payment.processed_at,
        } : null,
        session: session ? {
          id: session.id,
          jitsiRoomName: session.jitsi_room_name,
          jitsiUrl: buildJitsiUrl(session.jitsi_room_name),
          status: session.status,
        } : null,
      },
    });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  initiateBookingPayment,
  handlePaymobWebhook,
  verifyDevPayment,
  getPaymentStatus,
};
