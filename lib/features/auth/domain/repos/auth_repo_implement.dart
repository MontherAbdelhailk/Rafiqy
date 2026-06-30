import 'package:dio/dio.dart';
import 'package:rafiq/core/errors/error_handling.dart';
import 'package:rafiq/core/networking/api_consumer.dart';
import 'package:rafiq/core/utils/secure_storage.dart';
import 'package:rafiq/features/auth/data/repos/sign_up_model.dart';
import 'package:rafiq/features/auth/data/repos/user_model.dart';
import 'package:rafiq/features/auth/domain/entities/sign_up_entity.dart';
import 'package:rafiq/features/auth/domain/entities/user_entity.dart';
import 'package:rafiq/features/auth/domain/repos/auth_repo.dart';

class AuthRepoImpl implements AuthRepo {
  final ApiConsumer apiConsumer; 

  AuthRepoImpl({required this.apiConsumer});

@override
Future<UserEntity> login(String emailOrUsername, String password) async {
  try {
    // Node.js backend expects "identifier" and "password" as JSON
    final response = await apiConsumer.post(
      "auth/login",
      data: {
        "identifier": emailOrUsername,
        "password": password,
      },
    );

    // Get nested token, user details from response structure: { success: true, data: { accessToken, refreshToken, user: { ... } } }
    final data = response['data'] ?? {};
    final token = data['accessToken'] as String? ?? '';
    final refreshToken = data['refreshToken'] as String? ?? '';
    final user = data['user'] ?? {};
    final userId = user['id']?.toString() ?? '';
    final name = user['full_name'] ?? user['username'] ?? emailOrUsername;
    final emailAddress = user['email'] ?? '';
    final role = user['role']?.toString() ?? 'user';
    final profileImage = user['profileImage']?.toString() ?? user['profile_picture']?.toString() ?? '';

    // Persist credentials for subsequent requests
    await SecureStorage.saveToken(token);
    await SecureStorage.saveUserId(userId);
    await SecureStorage.saveUsername(name);
    await SecureStorage.saveRole(role);
    await SecureStorage.saveProfileImage(profileImage);

    return UserEntity(
      name: name,
      email: emailAddress,
      token: token,
    );
  } on ServerException catch (e) {
    throw Exception(e.errMessage);
  } catch (e) {
    throw Exception("بيانات الدخول غير صحيحة، تأكد من البيانات");
  }
}
@override
Future<UserEntity> signup(SignupRequestEntity request) async {
  try {
    final signupModel = SignupModel.fromEntity(request);
    
    // Node.js backend expects JSON payload matching the SignupModel structure
    final response = await apiConsumer.post(
      "auth/register",
      data: signupModel.toJson(request.password),
    );

    final data = response['data'] ?? {};
    final user = data['user'] ?? {};
    final token = data['accessToken'] as String? ?? ''; // Might need to log in to get access token, or use what is returned
    final userId = user['id']?.toString() ?? '';
    final name = user['full_name'] ?? request.fullName;
    final emailAddress = user['email'] ?? request.email;
    final role = user['role']?.toString() ?? 'user';
    final profileImage = user['profileImage']?.toString() ?? user['profile_picture']?.toString() ?? '';

    // Persist credentials for subsequent requests if token is returned
    if (token.isNotEmpty) {
      await SecureStorage.saveToken(token);
    }
    await SecureStorage.saveUserId(userId);
    await SecureStorage.saveUsername(request.username);
    await SecureStorage.saveRole(role);
    await SecureStorage.saveProfileImage(profileImage);

    return UserEntity(
      name: name,
      email: emailAddress,
      token: token,
    );
  } on ServerException catch (e) {
    throw Exception(e.errMessage);
  } catch (e) {
    throw Exception("حدث خطأ أثناء قراءة بيانات الحساب الجديد");
  }
}
@override
  Future<void> forgetPassword(String phone) async {
    try {
      await apiConsumer.post(
        "auth/forget-password",
        data: {
          "phone_number": phone, 
        },
      );
    } on ServerException catch (e) {
      throw Exception(e.errMessage);
    } catch (e) {
      throw Exception("فشل إرسال رمز التحقق، تأكد من الرقم");
    }
  }

@override
Future<String> verifyOtp(String phone, String otp) async { // 👈 غيرناها لـ Future<String>
  try {
    final response = await apiConsumer.post(
      "auth/verify-otp",
      data: {
        "phone_number": phone,
        "otp": otp,
      },
    );
    
    return response['access_token']; 
  } on ServerException catch (e) {
    throw Exception(e.errMessage);
  } catch (e) {
    throw Exception("رمز التحقق غير صحيح");
  }
}
  @override
  Future<void> resetPassword({required String token, required String newPassword}) async {
    try {
      await apiConsumer.post(
        "auth/reset-password",
        data: {
          "token": token, 
          "new_password": newPassword, 
        },
      );
    } on ServerException catch (e) {
      throw Exception(e.errMessage);
    } catch (e) {
      throw Exception("فشل إعادة تعيين كلمة المرور");
    }
  }


}