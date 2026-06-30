import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rafiq/core/networking/api_consumer.dart';
import 'package:rafiq/features/video/data/models/categoryvideo_model.dart';
import 'package:rafiq/features/video/data/models/video_model.dart';
import '../../domain/entities/video_category_entity.dart';
import '../../domain/entities/video_entity.dart';
import '../../domain/repos/video_repo.dart';

class VideoRepoImpl implements VideoRepo {
  final ApiConsumer api;

  VideoRepoImpl({required this.api});

  @override
  Future<List<VideoCategoryEntity>> getCategories() async {
    final response = await api.get("videos/categories");
    List categoriesJson = response as List;
    return categoriesJson.map((json) => VideoCategoryModel.fromJson(json)).toList();
  }

  @override
  Future<List<VideoEntity>> getVideosByStage(String stageId) async {
    final response = await api.get(
      "videos/list/$stageId",
      queryParameters: {
        "limit": 20,
        "offset": 0,
      },
    );
    List videosJson = response as List;
    return videosJson.map((json) => VideoModel.fromJson(json)).toList();
  }

  @override
  Future<VideoEntity> getVideoDetails(String videoId) async {
    throw UnimplementedError();
  }

  @override
  Future<void> addVideo(VideoEntity video, XFile videoFile, XFile coverImageFile) async {
    final Map<String, dynamic> data = {
      'title': video.title,
      'description': video.description,
      'category_title': video.tag,
      'subcategory_title': video.subCategory,
      'is_public': video.isPublic.toString(),
      'tags': video.tags.join(','),
      'video': await MultipartFile.fromFile(
        videoFile.path,
        filename: videoFile.name,
      ),
      'cover_image': await MultipartFile.fromFile(
        coverImageFile.path,
        filename: coverImageFile.name,
      ),
    };

    await api.post(
      "videos",
      data: data,
      isFormData: true,
    );
  }

  @override
  Future<void> editVideo(VideoEntity video, XFile? newVideoFile, XFile? newCoverImageFile) async {
    final Map<String, dynamic> data = {
      'title': video.title,
      'description': video.description,
      'category_title': video.tag,
      'subcategory_title': video.subCategory,
      'is_public': video.isPublic.toString(),
      'tags': video.tags.join(','),
    };

    if (newVideoFile != null) {
      data['video'] = await MultipartFile.fromFile(
        newVideoFile.path,
        filename: newVideoFile.name,
      );
    }

    if (newCoverImageFile != null) {
      data['cover_image'] = await MultipartFile.fromFile(
        newCoverImageFile.path,
        filename: newCoverImageFile.name,
      );
    }

    await api.patch(
      "videos/${video.id}",
      data: data,
      isFormData: true,
    );
  }

  @override
  Future<void> deleteVideo(String videoId) async {
    await api.delete("videos/$videoId");
  }

  @override
  Future<Map<String, dynamic>> toggleLikeVideo(String videoId) async {
    final response = await api.post("videos/$videoId/like");
    return Map<String, dynamic>.from(response['data'] ?? {});
  }

  @override
  Future<Map<String, dynamic>> incrementVideoViews(String videoId) async {
    final response = await api.post("videos/$videoId/watch");
    return Map<String, dynamic>.from(response['data'] ?? {});
  }
}