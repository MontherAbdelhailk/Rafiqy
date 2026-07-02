import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rafiq/features/profile/domain/entities/profile_entity.dart';
import 'package:rafiq/features/profile/domain/repos/profile_repo.dart';
import 'package:rafiq/features/profile/persentation/logic/profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepo profileRepo;
  ProfileCubit(this.profileRepo) : super(ProfileInitial());



  Future<void> getProfile() async {
    emit(ProfileLoading());
    try {
      final user = await profileRepo.getProfileData();
      emit(ProfileSuccess(user));
    } catch (e) {
      emit(ProfileError("فشل تحميل بيانات الحساب"));
    }
  }

  Future<void> updateProfile(ProfileEntity user) async {
    emit(UpdateProfileLoading());
    try {
      await profileRepo.updateProfile(user);
      emit(UpdateProfileSuccess());
      // Refresh profile data in the background so the profile view updates
      // when we navigate back to it.
      getProfile();
    } catch (e) {
      emit(UpdateProfileError("فشل تحديث البيانات"));
    }
  }

  Future<void> uploadProfilePicture(String filepath) async {
    emit(UpdateProfileLoading());
    try {
      final newUrl = await profileRepo.uploadProfilePicture(filepath);
      // Emit a dedicated success state with the new picture URL so the
      // edit screen can update the avatar preview without navigating away.
      emit(UploadPictureSuccess(newUrl));
    } catch (e) {
      emit(UploadPictureError("فشل رفع الصورة الشخصية"));
    }
  }
}