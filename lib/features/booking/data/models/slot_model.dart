// lib/features/booking/data/models/slot_model.dart

import '../../domain/entities/slot_entity.dart';

class SlotModel extends SlotEntity {
  const SlotModel({
    required super.id,
    required super.startTime,
    required super.endTime,
    required super.durationMins,
    required super.price,
    required super.isAvailable,
    required super.isBooked,
    super.notes,
  });

  factory SlotModel.fromJson(Map<String, dynamic> json) {
    return SlotModel(
      id: json['id'] as String,
      startTime: DateTime.parse(json['start_time'] as String).toLocal(),
      endTime: DateTime.parse(json['end_time'] as String).toLocal(),
      durationMins: (json['duration_mins'] as num?)?.toInt() ?? 60,
      price: json['price'] != null ? (double.tryParse(json['price'].toString()) ?? 50.0) : 50.0,
      isAvailable: json['is_available'] as bool? ?? true,
      isBooked: json['is_booked'] as bool? ?? false,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'duration_mins': durationMins,
      'price': price,
      'is_available': isAvailable,
      'is_booked': isBooked,
      'notes': notes,
    };
  }
}
