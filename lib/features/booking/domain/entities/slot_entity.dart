// lib/features/booking/domain/entities/slot_entity.dart

class SlotEntity {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final int durationMins;
  final double price;
  final bool isAvailable;
  final bool isBooked;
  final String? notes;

  const SlotEntity({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.durationMins,
    required this.price,
    required this.isAvailable,
    required this.isBooked,
    this.notes,
  });

  bool get canBook => isAvailable && !isBooked;
}
