import 'package:rafiq/features/video/domain/entities/video_entity.dart';

abstract class VideosListState {}

final class VideosListInitial extends VideosListState {}
final class VideosListLoading extends VideosListState {}
final class VideosListSuccess extends VideosListState {
  final List<VideoEntity> videos; 
  VideosListSuccess(this.videos);
}
final class VideosListError extends VideosListState {
  final String message;
  VideosListError(this.message);
}