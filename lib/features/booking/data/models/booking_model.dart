// lib/features/booking/data/models/booking_model.dart

import '../../domain/entities/booking_entity.dart';

class BookingModel extends BookingEntity {
  const BookingModel({
    required super.id,
    required super.userId,
    required super.slotId,
    required super.status,
    required super.amount,
    required super.createdAt,
    super.notes,
    super.cancellationReason,
    super.confirmedAt,
    super.cancelledAt,
    super.completedAt,
    super.startTime,
    super.endTime,
    super.durationMins,
    super.sessionId,
    super.jitsiRoomName,
    super.jitsiUrl,
    super.sessionStatus,
    super.paymentStatus,
    super.paymentMethod,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    // Build jitsi URL from room name if present
    final roomName = json['jitsi_room_name'] as String?;
    final jitsiUrl = roomName != null ? 'https://meet.jit.si/${Uri.encodeComponent(roomName)}' : null;

    return BookingModel(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? '',
      slotId: json['slot_id'] as String? ?? '',
      status: json['status'] as String? ?? 'pending_payment',
      amount: json['amount'] != null ? (double.tryParse(json['amount'].toString()) ?? 0.0) : 0.0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String).toLocal()
          : DateTime.now(),
      notes: json['notes'] as String?,
      cancellationReason: json['cancellation_reason'] as String?,
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.parse(json['confirmed_at'] as String).toLocal()
          : null,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'] as String).toLocal()
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String).toLocal()
          : null,
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'] as String).toLocal()
          : null,
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String).toLocal()
          : null,
      durationMins: (json['duration_mins'] as num?)?.toInt(),
      sessionId: json['session_id'] as String?,
      jitsiRoomName: roomName,
      jitsiUrl: jitsiUrl,
      sessionStatus: json['session_status'] as String?,
      paymentStatus: json['payment_status'] as String?,
      paymentMethod: json['payment_method'] as String?,
    );
  }
}
