import 'package:rafiq/features/video/domain/entities/video_category_entity.dart';

abstract class CategoryState {}

final class CategoryInitial extends CategoryState {}
final class CategoryLoading extends CategoryState {}
final class CategorySuccess extends CategoryState {
  final List<VideoCategoryEntity> categories;
  CategorySuccess(this.categories);
}
final class CategoryError extends CategoryState {
  final String message;
  CategoryError(this.message);
}