// lib/features/booking/domain/repos/booking_repo.dart

import '../entities/slot_entity.dart';
import '../entities/booking_entity.dart';
import '../entities/session_entity.dart';

abstract class BookingRepo {
  // ── Slots ───────────────────────────────────────────────────────────────────

  /// Get all available slots (optionally filtered by date range)
  Future<List<SlotEntity>> getAvailableSlots({DateTime? from, DateTime? to});

  // ── Bookings ─────────────────────────────────────────────────────────────────

  /// Create a new booking for a slot
  Future<BookingEntity> createBooking({required String slotId, String? notes});

  /// Get all bookings for the current user
  Future<List<BookingEntity>> getMyBookings({String? status});

  /// Get a specific booking by ID
  Future<BookingEntity> getBookingById(String bookingId);

  /// Cancel a booking
  Future<BookingEntity> cancelBooking(String bookingId, {String? reason});

  // ── Payments ─────────────────────────────────────────────────────────────────

  /// Initiate Paymob payment for a booking
  /// Returns: { iframeUrl, paymentKey, paymentId, amount, bookingId }
  Future<Map<String, dynamic>> initiatePayment(String bookingId, {String? paymentMethod, String? walletNumber});

  /// Get payment status for a booking (read-only status check)
  Future<Map<String, dynamic>> getPaymentStatus(String bookingId);

  // ── Dev-Only ──────────────────────────────────────────────────────────────

  /// DEV-ONLY: Simulate a successful payment confirmation.
  /// Calls POST /api/payments/verify-dev/:bookingId and executes the full
  /// post-payment business logic (confirm booking, create session, notify).
  ///
  /// In production, the Paymob webhook triggers this logic automatically.
  /// When moving to production: set NODE_ENV=production (backend disables
  /// the endpoint) and use kDevMode=false in Flutter to stop calling this.
  ///
  /// Returns: { bookingId, bookingStatus, payment, session }
  Future<Map<String, dynamic>> verifyDevPayment(String bookingId);

  // ── Sessions ─────────────────────────────────────────────────────────────────

  /// Get all sessions for the current user
  Future<List<SessionEntity>> getMySessions({String? status});

  /// Get session details by ID
  Future<SessionEntity> getSessionById(String sessionId);

  /// Join a session — validates time window, returns Jitsi info
  Future<Map<String, dynamic>> joinSession(String sessionId);
}
