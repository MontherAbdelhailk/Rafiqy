import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rafiq/features/video/domain/repos/video_repo.dart';
import 'package:rafiq/features/video/persentation/logic/video_list_state.dart';

class VideosListCubit extends Cubit<VideosListState> {
  final VideoRepo videoRepo;
  VideosListCubit(this.videoRepo) : super(VideosListInitial());

  Future<void> getVideos(String stageId) async {
    emit(VideosListLoading());
    try {
      final result = await videoRepo.getVideosByStage(stageId);
      emit(VideosListSuccess(result)); 
    } catch (e) {
      emit(VideosListError(e.toString()));
    }
  }

  Future<void> removeVideo(String id, String stageId) async {
    try {
      await videoRepo.deleteVideo(id);
      getVideos(stageId);
    } catch (e) {
      emit(VideosListError(e.toString()));
    }
  }
}