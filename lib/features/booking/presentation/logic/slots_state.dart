// lib/features/booking/presentation/logic/slots_state.dart

import 'package:rafiq/features/booking/domain/entities/slot_entity.dart';

abstract class SlotsState {}

class SlotsInitial extends SlotsState {}

class SlotsLoading extends SlotsState {}

class SlotsLoaded extends SlotsState {
  final List<SlotEntity> slots;
  SlotsLoaded(this.slots);
}

class SlotsError extends SlotsState {
  final String message;
  SlotsError(this.message);
}
