
import 'package:rafiq/features/auth/domain/entities/user_entity.dart';

sealed class LoginState {}

final class LoginInitial extends LoginState {}

final class LoginLoading extends LoginState {}

final class LoginSuccess extends LoginState {
  final UserEntity user;
  LoginSuccess(this.user);
}

final class LoginError extends LoginState {
  final String message;
  LoginError(this.message);
}