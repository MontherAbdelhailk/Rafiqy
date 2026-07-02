class ReelEntity {
  final String id;
  final String caption;
  final String videoUrl;
  final String? thumbnailUrl;
  final bool isPublic;
  final bool commentsEnabled;
  final int viewCount;
  final String authorName;
  final String authorImage;
  final int loveCount;
  final int commentCount;
  final bool hasLoved;
  final String duration;
  final String? resolution;
  final String? aspectRatio;

  ReelEntity({
    required this.id,
    required this.caption,
    required this.videoUrl,
    this.thumbnailUrl,
    required this.isPublic,
    required this.commentsEnabled,
    required this.viewCount,
    required this.authorName,
    required this.authorImage,
    required this.loveCount,
    required this.commentCount,
    required this.hasLoved,
    this.duration = '00:00',
    this.resolution,
    this.aspectRatio,
  });

  factory ReelEntity.fromJson(Map<String, dynamic> json) {
    return ReelEntity(
      id: json['id']?.toString() ?? '',
      caption: json['caption']?.toString() ?? '',
      videoUrl: json['video_url']?.toString() ?? '',
      thumbnailUrl: json['thumbnail_url']?.toString(),
      isPublic: json['is_public'] == true,
      commentsEnabled: json['comments_enabled'] == true,
      viewCount: json['view_count'] != null ? int.parse(json['view_count'].toString()) : 0,
      authorName: json['author_name']?.toString() ?? 'Rafiq',
      authorImage: json['author_image']?.toString() ?? '',
      loveCount: json['love_count'] != null ? int.parse(json['love_count'].toString()) : 0,
      commentCount: json['comment_count'] != null ? int.parse(json['comment_count'].toString()) : 0,
      hasLoved: json['has_liked'] == true || json['has_loved'] == true, // Map either backend alias
      duration: json['duration']?.toString() ?? '00:00',
      resolution: json['resolution']?.toString(),
      aspectRatio: json['aspect_ratio']?.toString(),
    );
  }
}

class ReelCommentEntity {
  final String id;
  final String userName;
  final String userImage;
  final String text;
  final String timeAgo;
  final int likesCount;
  final bool hasLiked;
  final bool canDelete;
  final List<ReelReplyEntity> replies;

  ReelCommentEntity({
    required this.id,
    required this.userName,
    required this.userImage,
    required this.text,
    required this.timeAgo,
    this.likesCount = 0,
    this.hasLiked = false,
    this.canDelete = false,
    this.replies = const [],
  });

  factory ReelCommentEntity.fromJson(Map<String, dynamic> json, String currentUserId, String currentUserRole) {
    final createdAtStr = json['created_at'] as String? ?? '';
    String displayTime = '1h ago';
    if (createdAtStr.isNotEmpty) {
      try {
        final dt = DateTime.parse(createdAtStr);
        final diff = DateTime.now().difference(dt);
        if (diff.inMinutes < 60) {
          displayTime = '${diff.inMinutes}m ago';
        } else if (diff.inHours < 24) {
          displayTime = '${diff.inHours}h ago';
        } else {
          displayTime = '${diff.inDays}d ago';
        }
      } catch (_) {}
    }

    final commentAuthorId = json['author_id']?.toString() ?? '';
    final canDeleteComment = currentUserRole == 'admin' || (currentUserId.isNotEmpty && commentAuthorId == currentUserId);

    final List<ReelReplyEntity> reps = [];
    if (json['replies'] != null && json['replies'] is List) {
      for (var r in json['replies']) {
        reps.add(ReelReplyEntity.fromJson(r));
      }
    }

    return ReelCommentEntity(
      id: json['id']?.toString() ?? '',
      userName: json['author_name']?.toString() ?? 'User',
      userImage: json['author_image']?.toString() ?? '',
      text: json['content']?.toString() ?? '',
      timeAgo: displayTime,
      likesCount: json['like_count'] != null ? int.parse(json['like_count'].toString()) : 0,
      hasLiked: json['has_liked'] == true,
      canDelete: canDeleteComment,
      replies: reps,
    );
  }
}

class ReelReplyEntity {
  final String id;
  final String userName;
  final String userImage;
  final String text;
  final String timeAgo;

  ReelReplyEntity({
    required this.id,
    required this.userName,
    required this.userImage,
    required this.text,
    required this.timeAgo,
  });

  factory ReelReplyEntity.fromJson(Map<String, dynamic> json) {
    print("DEBUG: Raw Video URL: ${json['video_url']}"); 
    final createdAtStr = json['created_at'] as String? ?? '';
    String displayTime = '1h ago';
    if (createdAtStr.isNotEmpty) {
      try {
        final dt = DateTime.parse(createdAtStr);
        final diff = DateTime.now().difference(dt);
        if (diff.inMinutes < 60) {
          displayTime = '${diff.inMinutes}m ago';
        } else if (diff.inHours < 24) {
          displayTime = '${diff.inHours}h ago';
        } else {
          displayTime = '${diff.inDays}d ago';
        }
      } catch (_) {}
    }

    return ReelReplyEntity(
      id: json['id']?.toString() ?? '',
      userName: json['author_name']?.toString() ?? 'User',
      userImage: json['author_image']?.toString() ?? '',
      text: json['content']?.toString() ?? '',
      timeAgo: displayTime,
    );
  }
}
