'use strict';

/**
 * payment_success.service.js
 *
 * Shared post-payment success flow.
 *
 * ┌─────────────────────────────────────────────────────────────────────────┐
 * │  DEVELOPMENT:  POST /api/payments/verify-dev/:bookingId  ──────────────┐│
 * │  PRODUCTION:   Paymob Webhook POST /api/payments/webhook  ─────────────┤│
 * │                                                              ↓          ││
 * │                              executePaymentSuccessFlow()               ││
 * └─────────────────────────────────────────────────────────────────────────┘
 *
 * When moving to production, only the CALLER changes — this service stays
 * identical. Switch is controlled by NODE_ENV (backend) + kDevMode (Flutter).
 */

const PaymentModel = require('../models/payment.model');
const BookingModel = require('../models/booking.model');
const SessionModel = require('../models/session.model');
const { generateRoomName, buildJitsiUrl } = require('./jitsi.service');
const { sendPushNotification } = require('../utils/notification');
const logger = require('../utils/logger');

/**
 * Execute the complete post-payment success flow.
 *
 * Performs, in order:
 *  1. Mark the payment record as `success` (paid)
 *  2. Confirm the booking (`confirmed` status)
 *  3. The slot remains `is_booked = TRUE` — it was reserved at booking creation.
 *     Booking status = 'confirmed' is the definitive lock; no other user can
 *     book it (slot is_booked=true prevents re-booking).
 *  4. Generate a unique Jitsi room name and URL for the session
 *  5. Create (or retrieve) the session record
 *  6. Send a push notification to the user: Booking Confirmed
 *  7. Send a push notification to the admin: New Payment Received
 *
 * @param {object} payment          - Payment DB row (must include id, booking_id)
 * @param {object} transactionData
 * @param {string} [transactionData.transactionId]  - Paymob transaction ID (or 'dev-verify')
 * @param {string} [transactionData.paymentMethod]  - Payment method string
 * @param {object} [transactionData.rawPayload]     - Raw webhook / dev payload for audit
 *
 * @returns {{ booking: object, session: object, jitsiUrl: string }}
 *
 * @throws Will throw if the DB operations fail. Notification failures are
 *         caught and logged as warnings — they do NOT abort the flow.
 */
async function executePaymentSuccessFlow(payment, {
  transactionId = null,
  paymentMethod = 'card',
  rawPayload = null,
} = {}) {
  // ── 1. Mark payment as paid ────────────────────────────────────────────────
  await PaymentModel.markSuccess(payment.id, {
    transactionId,
    paymentMethod,
    rawPayload,
  });
  logger.info(`✅ Payment ${payment.id} marked as success (txn: ${transactionId})`);

  // ── 2. Confirm the booking ─────────────────────────────────────────────────
  const booking = await BookingModel.confirm(payment.booking_id);
  if (!booking) {
    // Booking may already be confirmed (idempotency) — fetch the current state
    const existingBooking = await BookingModel.findById(payment.booking_id);
    if (!existingBooking) {
      throw new Error(`Booking ${payment.booking_id} not found during payment success flow`);
    }
    logger.warn(`⚠️ Booking ${payment.booking_id} was already confirmed. Proceeding idempotently.`);

    // Still need to ensure a session exists
    let existingSession = await SessionModel.findByBookingId(existingBooking.id);
    if (!existingSession) {
      const roomName = generateRoomName(existingBooking.id);
      existingSession = await SessionModel.create({
        bookingId: existingBooking.id,
        userId: existingBooking.user_id,
        jitsiRoomName: roomName,
      });
    }
    const jitsiUrl = buildJitsiUrl(existingSession.jitsi_room_name);
    return { booking: existingBooking, session: existingSession, jitsiUrl };
  }

  logger.info(`📅 Booking ${booking.id} confirmed`);

  // ── 3. Generate Jitsi room & create session ────────────────────────────────
  const roomName = generateRoomName(booking.id);
  const jitsiUrl = buildJitsiUrl(roomName);

  let session = await SessionModel.findByBookingId(booking.id);
  if (!session) {
    session = await SessionModel.create({
      bookingId: booking.id,
      userId: booking.user_id,
      jitsiRoomName: roomName,
    });
    logger.info(`🎥 Session ${session.id} created — room: ${roomName}`);
  } else {
    logger.info(`🎥 Session ${session.id} already existed — skipping creation`);
  }

  // ── 4. Notify user ─────────────────────────────────────────────────────────
  try {
    await sendPushNotification(booking.user_id, {
      title: '🎉 Booking Confirmed!',
      body: 'Your payment was successful. Your consultation session is now confirmed.',
      data: {
        type: 'BOOKING_CONFIRMED',
        bookingId: booking.id,
        sessionId: session.id,
        jitsiUrl,
      },
    });
  } catch (notifErr) {
    logger.warn(`⚠️ User notification failed (non-fatal): ${notifErr.message}`);
  }

  // ── 5. Notify admin ────────────────────────────────────────────────────────
  try {
    await sendPushNotification('admin', {
      title: '💳 Payment Received',
      body: 'A new consultation session has been confirmed and is ready.',
      data: {
        type: 'PAYMENT_RECEIVED',
        bookingId: booking.id,
        sessionId: session.id,
      },
    });
  } catch (notifErr) {
    logger.warn(`⚠️ Admin notification failed (non-fatal): ${notifErr.message}`);
  }

  logger.info(`🏁 Payment success flow complete — booking ${booking.id}, session ${session.id}`);

  return { booking, session, jitsiUrl };
}

module.exports = { executePaymentSuccessFlow };
