// lib/features/booking/domain/entities/session_entity.dart

class SessionEntity {
  final String id;
  final String bookingId;
  final String userId;
  final String jitsiRoomName;
  final String? jitsiUrl;
  final String status; // scheduled, active, completed, cancelled
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime? adminJoinedAt;
  final DateTime? userJoinedAt;
  final DateTime createdAt;

  // Joined from booking/slot
  final DateTime? scheduledStart;
  final DateTime? scheduledEnd;
  final int? durationMins;
  final String? bookingStatus;
  final double? amount;

  // Joined from user
  final String? userFullName;
  final String? username;
  final String? userEmail;
  final String? userProfilePicture;
  final String? userPhone;

  // Joined from payment
  final String? paymentStatus;
  final String? paymentMethod;
  final String? paymobTransactionId;

  const SessionEntity({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.jitsiRoomName,
    required this.status,
    required this.createdAt,
    this.jitsiUrl,
    this.startedAt,
    this.endedAt,
    this.adminJoinedAt,
    this.userJoinedAt,
    this.scheduledStart,
    this.scheduledEnd,
    this.durationMins,
    this.bookingStatus,
    this.amount,
    this.userFullName,
    this.username,
    this.userEmail,
    this.userProfilePicture,
    this.userPhone,
    this.paymentStatus,
    this.paymentMethod,
    this.paymobTransactionId,
  });

  bool get isScheduled => status == 'scheduled';
  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  bool get canJoinNow {
    if (isCancelled || isCompleted) return false;
    if (scheduledStart == null) return false;
    final now = DateTime.now();
    final earliest = scheduledStart!.subtract(const Duration(minutes: 15));
    final latest = scheduledStart!.add(Duration(minutes: durationMins ?? 120));
    return now.isAfter(earliest) && now.isBefore(latest);
  }
}
