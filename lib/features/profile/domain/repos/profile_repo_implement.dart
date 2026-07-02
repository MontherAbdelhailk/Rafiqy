import 'package:dio/dio.dart';
import 'package:rafiq/core/networking/api_consumer.dart';
import 'package:rafiq/core/errors/error_handling.dart';
import 'package:rafiq/features/profile/data/model/profile_model.dart';
import 'package:rafiq/features/profile/domain/entities/profile_entity.dart';
import 'package:rafiq/features/profile/domain/repos/profile_repo.dart';
import 'package:rafiq/core/utils/secure_storage.dart';

class ProfileRepoImpl implements ProfileRepo {
  final ApiConsumer apiConsumer;

  ProfileRepoImpl({required this.apiConsumer});

  @override
  Future<ProfileEntity> getProfileData() async {
    try {
      final response = await apiConsumer.get("users/profile");
      // Backend returns structure: { success: true, data: { user: { ... } } }
      final data = response['data'] ?? {};
      final userData = data['user'] ?? {};
      final profile = ProfileModel.fromJson(userData);
      if (profile.profilePicture != null) {
        await SecureStorage.saveProfileImage(profile.profilePicture!);
      }
      await SecureStorage.saveAge(profile.age);

      return profile;
    } on ServerException catch (e) {
      throw Exception(e.errMessage);
    } catch (e) {
      throw Exception("فشل تحميل بيانات الحساب");
    }
  }

  @override
  Future<void> updateProfile(ProfileEntity user) async {
    try {
      await apiConsumer.patch(
        "users/profile",
        data: {
          "first_name": user.firstName,
          "last_name": user.lastName,
          "phone": user.phone,
          "age": user.age,
          "status": user.status,
          "children_count": user.childrenCount,
          "bio": user.bio,
        },
      );
      await SecureStorage.saveAge(user.age);
    } on ServerException catch (e) {
      throw Exception(e.errMessage);
    } catch (e) {
      throw Exception("فشل تحديث البيانات");
    }
  }

  @override
  Future<String> uploadProfilePicture(String filepath) async {
    try {
      final file = await _getMultipartFile(filepath);

      final response = await apiConsumer.patch(
        "users/profile/picture",
        data: {
          "picture": file,
        },
        isFormData: true,
      );

      final data = response['data'] ?? {};
      final profilePicture = data['profile_picture'] as String? ?? '';
      if (profilePicture.isNotEmpty) {
        await SecureStorage.saveProfileImage(profilePicture);
      }
      return profilePicture;
    } on ServerException catch (e) {
      throw Exception(e.errMessage);
    } catch (e) {
      throw Exception("فشل رفع الصورة الشخصية");
    }
  }

  Future<dynamic> _getMultipartFile(String path) async {
    final name = path.split('/').last;
    return await MultipartFile.fromFile(
      path,
      filename: name,
    );
  }
}