

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rafiq/features/auth/domain/repos/auth_repo.dart';
import 'package:rafiq/features/auth/persentation/logic/forget_pass_state.dart';

class ForgetPasswordCubit extends Cubit<ForgetPasswordState> {
  final AuthRepo authRepo;
  ForgetPasswordCubit(this.authRepo) : super(ForgetPasswordInitial());

  Future<void> sendOtp(String phone) async {
    emit(ForgetPasswordLoading());
    try {
      await authRepo.forgetPassword(phone);
      emit(ForgetPasswordSuccess());
    } catch (e) {
      emit(ForgetPasswordError("حدث خطأ، تأكد من رقم الهاتف"));
    }
  }

Future<void> verifyOtp({required String phone, required String otp}) async {
  emit(OtpLoading());
  try {
    final String token = await authRepo.verifyOtp(phone, otp); 
    
    emit(OtpSuccess(token: token)); 
  } catch (e) {
    emit(OtpError(e.toString()));
  }
}

Future<void> resetPassword({required String token, required String password}) async {
  emit(ResetPasswordLoading());
  try {
    await authRepo.resetPassword(token: token, newPassword: password);
    emit(ResetPasswordSuccess());
  } catch (e) {
    emit(ResetPasswordError("فشل تغيير كلمة المرور، حاول مجدداً"));
  }
}
}