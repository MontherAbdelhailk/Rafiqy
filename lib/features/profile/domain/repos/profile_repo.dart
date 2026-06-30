import 'package:rafiq/features/profile/domain/entities/profile_entity.dart';

abstract class ProfileRepo {
  Future<ProfileEntity> getProfileData();
  Future<void> updateProfile(ProfileEntity user);
  Future<String> uploadProfilePicture(String filepath);
}