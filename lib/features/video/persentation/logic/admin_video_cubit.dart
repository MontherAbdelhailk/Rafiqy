import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rafiq/features/video/domain/entities/video_entity.dart';
import 'package:rafiq/features/video/domain/repos/video_repo.dart';
import 'package:rafiq/features/video/persentation/logic/admin_video_state.dart';

class AdminVideoCubit extends Cubit<AdminVideoState> {
  final VideoRepo videoRepo;
  AdminVideoCubit(this.videoRepo) : super(AdminVideoInitial());

  Future<void> addNewVideo(VideoEntity video, XFile videoFile, XFile coverImageFile) async {
    emit(AddVideoLoading());
    try {
      await videoRepo.addVideo(video, videoFile, coverImageFile);
      emit(AddVideoSuccess());
    } catch (e) {
      emit(AddVideoError(e.toString()));
    }
  }

  Future<void> editExistingVideo(VideoEntity video, XFile? newVideoFile, XFile? newCoverImageFile) async {
    emit(AddVideoLoading());
    try {
      await videoRepo.editVideo(video, newVideoFile, newCoverImageFile);
      emit(AddVideoSuccess());
    } catch (e) {
      emit(AddVideoError(e.toString()));
    }
  }

  Future<void> removeVideo(String id) async {
    try {
      await videoRepo.deleteVideo(id);
      emit(DeleteVideoSuccess());
      // Refresh the list after deleting
      fetchAdminVideos();
    } catch (e) {
      emit(DeleteVideoError(e.toString()));
    }
  }

  Future<void> fetchAdminVideos() async {
    emit(AdminFetchLoading());
    try {
      final videos = await videoRepo.getVideosByStage("admin_all"); 
      emit(AdminFetchSuccess(videos));
    } catch (e) {
      emit(AdminFetchError("فشل في جلب البيانات: ${e.toString()}"));
    }
  }
}