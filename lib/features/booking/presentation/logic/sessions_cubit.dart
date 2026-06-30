// lib/features/booking/presentation/logic/sessions_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rafiq/features/booking/domain/repos/booking_repo.dart';
import 'sessions_state.dart';

class SessionsCubit extends Cubit<SessionsState> {
  final BookingRepo _repo;

  SessionsCubit(this._repo) : super(SessionsInitial());

  Future<void> loadMySessions({String? status}) async {
    emit(SessionsLoading());
    try {
      final sessions = await _repo.getMySessions(status: status);
      emit(SessionsLoaded(sessions));
    } catch (e) {
      emit(SessionsError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> loadSessionById(String sessionId) async {
    emit(SessionsLoading());
    try {
      final session = await _repo.getSessionById(sessionId);
      emit(SessionDetailLoaded(session));
    } catch (e) {
      emit(SessionsError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> joinSession(String sessionId) async {
    emit(SessionJoining());
    try {
      final data = await _repo.joinSession(sessionId);
      emit(SessionJoined(
        sessionId: data['sessionId'] as String? ?? sessionId,
        jitsiRoomName: data['jitsiRoomName'] as String? ?? '',
        jitsiUrl: data['jitsiUrl'] as String? ?? '',
        startTime: data['startTime'] != null
            ? DateTime.parse(data['startTime'] as String).toLocal()
            : DateTime.now(),
        durationMins: (data['durationMins'] as num?)?.toInt() ?? 60,
        isAdmin: data['isAdmin'] as bool? ?? false,
      ));
    } catch (e) {
      emit(SessionsError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
