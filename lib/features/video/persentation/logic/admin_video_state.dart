import 'package:rafiq/features/video/domain/entities/video_entity.dart';

abstract class AdminVideoState {}

final class AdminVideoInitial extends AdminVideoState {}

final class AddVideoLoading extends AdminVideoState {}

final class AddVideoSuccess extends AdminVideoState {}

final class AddVideoError extends AdminVideoState {
  final String message;
  AddVideoError(this.message);
}

final class DeleteVideoLoading extends AdminVideoState {
  final String videoId; 
  DeleteVideoLoading(this.videoId);
}

final class DeleteVideoSuccess extends AdminVideoState {}

final class DeleteVideoError extends AdminVideoState {
  final String message;
  DeleteVideoError(this.message);
}

final class AdminFetchLoading extends AdminVideoState {}

final class AdminFetchSuccess extends AdminVideoState {
  final List<VideoEntity> videos;
  AdminFetchSuccess(this.videos);
}

final class AdminFetchError extends AdminVideoState {
  final String message;
  AdminFetchError(this.message);
}