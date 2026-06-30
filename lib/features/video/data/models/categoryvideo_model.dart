import '../../domain/entities/video_category_entity.dart';

class VideoCategoryModel extends VideoCategoryEntity {
  VideoCategoryModel({
    required super.id,
    required super.title,
    required super.description,
    required super.iconName,
  });

  factory VideoCategoryModel.fromJson(Map<String, dynamic> json) {
    return VideoCategoryModel(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      iconName: json['icon_name'] ?? 'family_restroom',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'icon_name': iconName,
    };
  }
}