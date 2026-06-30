class VideoEntity {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String videoUrl;
  final String duration;
  final String views; 
  final String likes; 
  final String tag;   
  final String subCategory;
  final List<VideoEntity>? relatedVideos;
  final bool isPublic;
  final List<String> tags;
  final bool hasLiked;
  final String? resolution;
  final String? aspectRatio;

  VideoEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.videoUrl,
    required this.duration,
    required this.views,
    required this.likes,
    this.tag = "",
    this.subCategory = "",
    this.relatedVideos,
    this.isPublic = true,
    this.tags = const [],
    this.hasLiked = false,
    this.resolution,
    this.aspectRatio,
  });
}