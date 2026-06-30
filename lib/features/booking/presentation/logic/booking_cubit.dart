// lib/features/booking/presentation/logic/booking_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rafiq/features/booking/domain/repos/booking_repo.dart';
import 'booking_state.dart';

class BookingCubit extends Cubit<BookingState> {
  final BookingRepo _repo;

  BookingCubit(this._repo) : super(BookingInitial());

  Future<void> createBooking({required String slotId, String? notes}) async {
    emit(BookingLoading());
    try {
      final booking = await _repo.createBooking(slotId: slotId, notes: notes);
      emit(BookingCreated(booking));
    } catch (e) {
      emit(BookingError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> loadMyBookings({String? status}) async {
    emit(BookingLoading());
    try {
      final bookings = await _repo.getMyBookings(status: status);
      emit(BookingListLoaded(bookings));
    } catch (e) {
      emit(BookingError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> loadBookingById(String bookingId) async {
    emit(BookingLoading());
    try {
      final booking = await _repo.getBookingById(bookingId);
      emit(BookingDetailLoaded(booking));
    } catch (e) {
      emit(BookingError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> cancelBooking(String bookingId, {String? reason}) async {
    emit(BookingLoading());
    try {
      final booking = await _repo.cancelBooking(bookingId, reason: reason);
      emit(BookingCancelled(booking));
    } catch (e) {
      emit(BookingError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> initiatePayment(String bookingId, {String? paymentMethod, String? walletNumber}) async {
    emit(PaymentInitiating());
    try {
      final paymentData = await _repo.initiatePayment(bookingId, paymentMethod: paymentMethod, walletNumber: walletNumber);
      emit(PaymentInitiated(
        iframeUrl: paymentData['iframeUrl'] as String? ?? '',
        paymentKey: paymentData['paymentKey'] as String? ?? '',
        paymentId: paymentData['paymentId'] as String? ?? '',
        bookingId: paymentData['bookingId'] as String? ?? bookingId,
        amount: paymentData['amount'] != null ? (double.tryParse(paymentData['amount'].toString()) ?? 0.0) : 0.0,
      ));
    } catch (e) {
      emit(PaymentError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> checkPaymentStatus(String bookingId) async {
    emit(BookingLoading());
    try {
      final statusData = await _repo.getPaymentStatus(bookingId);
      emit(PaymentStatusLoaded(
        bookingStatus: statusData['bookingStatus'] as String? ?? 'pending_payment',
        payment: statusData['payment'] as Map<String, dynamic>?,
        session: statusData['session'] as Map<String, dynamic>?,
      ));
    } catch (e) {
      emit(BookingError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// DEV-ONLY: Trigger the full payment success flow via the backend dev endpoint.
  ///
  /// Development path:
  ///   "Verify Payment" button → verifyDevPayment() → POST /api/payments/verify-dev/:id
  ///   → backend executes booking confirm + session create + notifications
  ///   → emits PaymentDevVerified → UI navigates to success screen
  ///
  /// Production path:
  ///   Paymob webhook fires automatically → no cubit method needed.
  ///   To disable this entirely in production, set kDevMode = false in
  ///   payment_webview_screen.dart (see comment there).
  Future<void> verifyDevPayment(String bookingId, {required double amount}) async {
    emit(BookingLoading());
    try {
      final data = await _repo.verifyDevPayment(bookingId);
      emit(PaymentDevVerified(
        bookingId: data['bookingId'] as String? ?? bookingId,
        amount: amount,
        session: data['session'] as Map<String, dynamic>?,
      ));
    } catch (e) {
      emit(BookingError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
