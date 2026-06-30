import 'package:rafiq/features/auth/domain/entities/sign_up_entity.dart';
import 'package:rafiq/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepo {
  Future<UserEntity> login(String username, String password);
   Future<UserEntity> signup(SignupRequestEntity request);
   Future<void> forgetPassword(String phone);
   Future<String> verifyOtp(String phone, String otp);
   Future<void> resetPassword({
    required String token, 
    required String newPassword,
  });

  
}