// lib/features/booking/data/models/session_model.dart

import '../../domain/entities/session_entity.dart';

class SessionModel extends SessionEntity {
  const SessionModel({
    required super.id,
    required super.bookingId,
    required super.userId,
    required super.jitsiRoomName,
    required super.status,
    required super.createdAt,
    super.jitsiUrl,
    super.startedAt,
    super.endedAt,
    super.adminJoinedAt,
    super.userJoinedAt,
    super.scheduledStart,
    super.scheduledEnd,
    super.durationMins,
    super.bookingStatus,
    super.amount,
    super.userFullName,
    super.username,
    super.userEmail,
    super.userProfilePicture,
    super.userPhone,
    super.paymentStatus,
    super.paymentMethod,
    super.paymobTransactionId,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    final roomName = json['jitsi_room_name'] as String? ?? '';
    final jitsiUrlFromApi = json['jitsi_url'] as String?;
    final jitsiUrl = jitsiUrlFromApi ?? (roomName.isNotEmpty ? 'https://meet.jit.si/${Uri.encodeComponent(roomName)}' : null);

    return SessionModel(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      jitsiRoomName: roomName,
      jitsiUrl: jitsiUrl,
      status: json['status'] as String? ?? 'scheduled',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String).toLocal()
          : DateTime.now(),
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at'] as String).toLocal() : null,
      endedAt: json['ended_at'] != null ? DateTime.parse(json['ended_at'] as String).toLocal() : null,
      adminJoinedAt: json['admin_joined_at'] != null ? DateTime.parse(json['admin_joined_at'] as String).toLocal() : null,
      userJoinedAt: json['user_joined_at'] != null ? DateTime.parse(json['user_joined_at'] as String).toLocal() : null,
      scheduledStart: json['start_time'] != null ? DateTime.parse(json['start_time'] as String).toLocal() : null,
      scheduledEnd: json['end_time'] != null ? DateTime.parse(json['end_time'] as String).toLocal() : null,
      durationMins: (json['duration_mins'] as num?)?.toInt(),
      bookingStatus: json['booking_status'] as String?,
      amount: json['amount'] != null ? double.tryParse(json['amount'].toString()) : null,
      userFullName: json['user_full_name'] as String?,
      username: json['username'] as String?,
      userEmail: json['user_email'] as String?,
      userProfilePicture: json['user_profile_picture'] as String?,
      userPhone: json['user_phone'] as String?,
      paymentStatus: json['payment_status'] as String?,
      paymentMethod: json['payment_method'] as String?,
      paymobTransactionId: json['paymob_transaction_id'] as String?,
    );
  }
}
