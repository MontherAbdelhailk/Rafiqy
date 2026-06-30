// lib/features/booking/presentation/logic/slots_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rafiq/features/booking/domain/entities/slot_entity.dart';
import 'package:rafiq/features/booking/domain/repos/booking_repo.dart';
import 'slots_state.dart';

class SlotsCubit extends Cubit<SlotsState> {
  final BookingRepo _repo;

  SlotsCubit(this._repo) : super(SlotsInitial());

  List<SlotEntity> _allSlots = [];

  Future<void> loadSlots({DateTime? from, DateTime? to}) async {
    emit(SlotsLoading());
    try {
      final slots = await _repo.getAvailableSlots(from: from, to: to);
      _allSlots = slots;
      emit(SlotsLoaded(slots));
    } catch (e) {
      emit(SlotsError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Filter slots for a specific date
  List<SlotEntity> getSlotsForDate(DateTime date) {
    return _allSlots.where((slot) {
      return slot.startTime.year == date.year &&
          slot.startTime.month == date.month &&
          slot.startTime.day == date.day;
    }).toList();
  }

  /// Get unique dates that have available slots
  Set<DateTime> getAvailableDates() {
    return _allSlots.map((slot) => DateTime(
      slot.startTime.year,
      slot.startTime.month,
      slot.startTime.day,
    )).toSet();
  }
}
