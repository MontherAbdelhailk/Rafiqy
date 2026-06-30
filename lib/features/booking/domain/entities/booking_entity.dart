// lib/features/booking/domain/entities/booking_entity.dart

class BookingEntity {
  final String id;
  final String userId;
  final String slotId;
  final String status; // pending_payment, confirmed, cancelled, completed, no_show
  final double amount;
  final String? notes;
  final String? cancellationReason;
  final DateTime? confirmedAt;
  final DateTime? cancelledAt;
  final DateTime? completedAt;
  final DateTime createdAt;

  // Joined from slot
  final DateTime? startTime;
  final DateTime? endTime;
  final int? durationMins;

  // Joined from session
  final String? sessionId;
  final String? jitsiRoomName;
  final String? jitsiUrl;
  final String? sessionStatus;

  // Joined from payment
  final String? paymentStatus;
  final String? paymentMethod;

  const BookingEntity({
    required this.id,
    required this.userId,
    required this.slotId,
    required this.status,
    required this.amount,
    required this.createdAt,
    this.notes,
    this.cancellationReason,
    this.confirmedAt,
    this.cancelledAt,
    this.completedAt,
    this.startTime,
    this.endTime,
    this.durationMins,
    this.sessionId,
    this.jitsiRoomName,
    this.jitsiUrl,
    this.sessionStatus,
    this.paymentStatus,
    this.paymentMethod,
  });

  bool get isPendingPayment => status == 'pending_payment';
  bool get isConfirmed => status == 'confirmed';
  bool get isCancelled => status == 'cancelled';
  bool get isCompleted => status == 'completed';
  bool get hasSession => sessionId != null && jitsiRoomName != null;

  bool get canJoin {
    if (!isConfirmed || !hasSession) return false;
    if (startTime == null) return false;
    final now = DateTime.now();
    final earliest = startTime!.subtract(const Duration(minutes: 15));
    final latest = startTime!.add(Duration(minutes: durationMins ?? 120));
    return now.isAfter(earliest) && now.isBefore(latest);
  }
}
