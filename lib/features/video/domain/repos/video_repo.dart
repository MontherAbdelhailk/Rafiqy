import 'package:image_picker/image_picker.dart';
import 'package:rafiq/features/video/domain/entities/video_category_entity.dart';
import 'package:rafiq/features/video/domain/entities/video_entity.dart';

abstract class VideoRepo {
  Future<List<VideoCategoryEntity>> getCategories();
  Future<List<VideoEntity>> getVideosByStage(String stageId);
  Future<VideoEntity> getVideoDetails(String videoId);
  Future<void> addVideo(VideoEntity video, XFile videoFile, XFile coverImageFile);
  Future<void> editVideo(VideoEntity video, XFile? newVideoFile, XFile? newCoverImageFile);
  Future<void> deleteVideo(String videoId); 
  Future<Map<String, dynamic>> toggleLikeVideo(String videoId);
  Future<Map<String, dynamic>> incrementVideoViews(String videoId);
}