// lib/features/booking/presentation/logic/sessions_state.dart

import 'package:rafiq/features/booking/domain/entities/session_entity.dart';

abstract class SessionsState {}

class SessionsInitial extends SessionsState {}

class SessionsLoading extends SessionsState {}

class SessionsLoaded extends SessionsState {
  final List<SessionEntity> sessions;
  SessionsLoaded(this.sessions);
}

class SessionDetailLoaded extends SessionsState {
  final SessionEntity session;
  SessionDetailLoaded(this.session);
}

class SessionJoining extends SessionsState {}

class SessionJoined extends SessionsState {
  final String sessionId;
  final String jitsiRoomName;
  final String jitsiUrl;
  final DateTime startTime;
  final int durationMins;
  final bool isAdmin;

  SessionJoined({
    required this.sessionId,
    required this.jitsiRoomName,
    required this.jitsiUrl,
    required this.startTime,
    required this.durationMins,
    required this.isAdmin,
  });
}

class SessionsError extends SessionsState {
  final String message;
  SessionsError(this.message);
}
