// lib/features/booking/presentation/logic/booking_state.dart

import 'package:rafiq/features/booking/domain/entities/booking_entity.dart';

abstract class BookingState {}

class BookingInitial extends BookingState {}

class BookingLoading extends BookingState {}

class BookingListLoaded extends BookingState {
  final List<BookingEntity> bookings;
  BookingListLoaded(this.bookings);
}

class BookingCreated extends BookingState {
  final BookingEntity booking;
  BookingCreated(this.booking);
}

class BookingDetailLoaded extends BookingState {
  final BookingEntity booking;
  BookingDetailLoaded(this.booking);
}

class BookingCancelled extends BookingState {
  final BookingEntity booking;
  BookingCancelled(this.booking);
}

class BookingError extends BookingState {
  final String message;
  BookingError(this.message);
}

// Payment-related states
class PaymentInitiating extends BookingState {}

class PaymentInitiated extends BookingState {
  final String iframeUrl;
  final String paymentKey;
  final String paymentId;
  final String bookingId;
  final double amount;
  PaymentInitiated({
    required this.iframeUrl,
    required this.paymentKey,
    required this.paymentId,
    required this.bookingId,
    required this.amount,
  });
}

/// Emitted when Paymob's redirect URL contains success=true.
/// At this point the payment is approved by Paymob but the booking
/// confirmation flow (session creation, notifications, etc.) has NOT run yet.
/// The UI should reveal the "Verify Payment" button only in this state.
class PaymentApproved extends BookingState {}

class PaymentStatusLoaded extends BookingState {
  final String bookingStatus;
  final Map<String, dynamic>? payment;
  final Map<String, dynamic>? session;
  PaymentStatusLoaded({
    required this.bookingStatus,
    this.payment,
    this.session,
  });
}

/// Emitted when the DEV verify-dev endpoint succeeds.
/// Carries the confirmed booking info needed to navigate to the success screen.
///
/// DEV path:  Verify Payment button → verifyDevPayment() → PaymentDevVerified
/// PROD path: Webhook fires automatically → no Flutter state needed
class PaymentDevVerified extends BookingState {
  final String bookingId;
  final double amount;
  final Map<String, dynamic>? session;

  PaymentDevVerified({
    required this.bookingId,
    required this.amount,
    this.session,
  });
}

class PaymentError extends BookingState {
  final String message;
  PaymentError(this.message);
}
