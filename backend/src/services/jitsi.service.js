'use strict';

const crypto = require('crypto');

/**
 * Generate a unique, deterministic Jitsi Meet room name for a booking.
 * Format: rafiq-{short-hash}
 * The room name must be URL-safe and consistent for the same booking.
 *
 * @param {string} bookingId - UUID of the booking
 * @returns {string} Jitsi room name
 */
function generateRoomName(bookingId) {
  // Use first 12 chars of SHA-256 hash for a clean, readable room name
  const hash = crypto
    .createHash('sha256')
    .update(bookingId)
    .digest('hex')
    .slice(0, 12);

  return `rafiq-${hash}`;
}

/**
 * Generate the full Jitsi Meet URL for a room.
 * Defaults to meet.jit.si if no custom server configured.
 *
 * @param {string} roomName
 * @returns {string} Full Jitsi URL
 */
function buildJitsiUrl(roomName) {
  const jitsiServer = process.env.JITSI_SERVER || 'meet.jit.si';
  return `https://${jitsiServer}/${encodeURIComponent(roomName)}`;
}

/**
 * Check if a user is allowed to join a session.
 * Allows joining 15 minutes before start and up to 2 hours after start.
 *
 * @param {Date|string} startTime - Session start time
 * @param {number} durationMins - Session duration in minutes
 * @returns {{ allowed: boolean, reason?: string }}
 */
function checkJoinWindow(startTime, durationMins = 60) {
  const now = new Date();
  const start = new Date(startTime);
  const earlyJoinMs = 15 * 60 * 1000; // 15 minutes before
  const lateJoinMs = Math.max(durationMins, 120) * 60 * 1000; // at least 2h window

  const earliest = new Date(start.getTime() - earlyJoinMs);
  const latest = new Date(start.getTime() + lateJoinMs);

  if (now < earliest) {
    const minutesUntil = Math.ceil((earliest - now) / 60000);
    return {
      allowed: false,
      reason: `Session starts in ${minutesUntil} minute(s). You can join 15 minutes before the scheduled time.`,
    };
  }

  if (now > latest) {
    return {
      allowed: false,
      reason: 'Session time window has expired.',
    };
  }

  return { allowed: true };
}

module.exports = {
  generateRoomName,
  buildJitsiUrl,
  checkJoinWindow,
};
