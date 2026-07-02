// lib/features/booking/data/repos/booking_repo_impl.dart

import 'package:rafiq/core/networking/api_consumer.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/entities/session_entity.dart';
import '../../domain/entities/slot_entity.dart';
import '../../domain/repos/booking_repo.dart';
import '../models/booking_model.dart';
import '../models/session_model.dart';
import '../models/slot_model.dart';

class BookingRepoImpl implements BookingRepo {
  final ApiConsumer _api;

  BookingRepoImpl({required ApiConsumer api}) : _api = api;

  // ─── Slots ──────────────────────────────────────────────────────────────────

  @override
  Future<List<SlotEntity>> getAvailableSlots({DateTime? from, DateTime? to}) async {
    final queryParams = <String, dynamic>{};
    if (from != null) queryParams['from'] = from.toUtc().toIso8601String();
    if (to != null) queryParams['to'] = to.toUtc().toIso8601String();

    final response = await _api.get('slots', queryParameters: queryParams);
    final data = response['data'] as List<dynamic>? ?? [];
    return data.map((e) => SlotModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ─── Bookings ────────────────────────────────────────────────────────────────

  @override
  Future<BookingEntity> createBooking({required String slotId, String? notes}) async {
    final response = await _api.post('bookings', data: {
      'slotId': slotId,
      if (notes != null) 'notes': notes,
    });
    return BookingModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  @override
  Future<List<BookingEntity>> getMyBookings({String? status}) async {
    final queryParams = <String, dynamic>{};
    if (status != null) queryParams['status'] = status;

    final response = await _api.get('bookings/mine', queryParameters: queryParams);
    final data = response['data'] as List<dynamic>? ?? [];
    return data.map((e) => BookingModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<BookingEntity> getBookingById(String bookingId) async {
    final response = await _api.get('bookings/$bookingId');
    return BookingModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  @override
  Future<BookingEntity> cancelBooking(String bookingId, {String? reason}) async {
    final response = await _api.patch('bookings/$bookingId/cancel', data: {
      if (reason != null) 'reason': reason,
    });
    return BookingModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  // ─── Payments ────────────────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> initiatePayment(String bookingId, {String? paymentMethod, String? walletNumber}) async {
    final response = await _api.post('payments/initiate', data: {
      'bookingId': bookingId,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (walletNumber != null) 'walletNumber': walletNumber,
    });
    return (response['data'] as Map<String, dynamic>?) ?? {};
  }

  @override
  Future<Map<String, dynamic>> getPaymentStatus(String bookingId) async {
    final response = await _api.get('payments/status/$bookingId');
    return (response['data'] as Map<String, dynamic>?) ?? {};
  }

  @override
  Future<Map<String, dynamic>> verifyDevPayment(String bookingId) async {
    // DEV-ONLY: Calls POST /api/payments/verify-dev/:bookingId
    // This triggers the full post-payment success flow on the backend
    // (booking confirmation, session creation, notifications, etc.)
    // In production: NODE_ENV=production disables this endpoint (returns 404).
    final response = await _api.post('payments/verify-dev/$bookingId', data: {});
    return (response['data'] as Map<String, dynamic>?) ?? {};
  }


  @override
  Future<List<SessionEntity>> getMySessions({String? status}) async {
    final queryParams = <String, dynamic>{};
    if (status != null) queryParams['status'] = status;

    final response = await _api.get('sessions/mine', queryParameters: queryParams);
    final data = response['data'] as List<dynamic>? ?? [];
    return data.map((e) => SessionModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<SessionEntity> getSessionById(String sessionId) async {
    final response = await _api.get('sessions/$sessionId');
    return SessionModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>> joinSession(String sessionId) async {
    final response = await _api.post('sessions/$sessionId/join', data: {});
    return (response['data'] as Map<String, dynamic>?) ?? {};
  }
}
