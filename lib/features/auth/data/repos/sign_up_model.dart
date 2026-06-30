import 'package:rafiq/features/auth/domain/entities/sign_up_entity.dart';

class SignupModel extends SignupRequestEntity {
  SignupModel({
    required super.fullName,
    required super.username,
    required super.email,
    required super.phone,
    required super.password,
  });

  Map<String, dynamic> toJson(String confirmPassword) {
    return {
      "full_name": fullName,
      "username": username,
      "email": email,
      "phone_number": phone,
      "password": password,
      "confirm_password": confirmPassword,
    };
  }

  factory SignupModel.fromEntity(SignupRequestEntity entity) {
    return SignupModel(
      fullName: entity.fullName,
      username: entity.username,
      email: entity.email,
      phone: entity.phone,
      password: entity.password,
    );
  }
}