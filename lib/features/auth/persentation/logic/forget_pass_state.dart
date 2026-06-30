sealed class ForgetPasswordState {}

final class ForgetPasswordInitial extends ForgetPasswordState {}
final class ForgetPasswordLoading extends ForgetPasswordState {}
final class ForgetPasswordSuccess extends ForgetPasswordState {}
final class ForgetPasswordError extends ForgetPasswordState {
  final String message;
  ForgetPasswordError(this.message);
}

final class OtpLoading extends ForgetPasswordState {}
final class OtpSuccess extends ForgetPasswordState {
  final String token;
  OtpSuccess({required this.token});
}
final class OtpError extends ForgetPasswordState {
  final String message;
  OtpError(this.message);


  
}


final class ResetPasswordLoading extends ForgetPasswordState {}
final class ResetPasswordSuccess extends ForgetPasswordState {}
final class ResetPasswordError extends ForgetPasswordState {
  final String message;
  ResetPasswordError(this.message);
}