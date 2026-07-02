class PostEntity {
  final String id;
  final String content;
  final String? mediaUrl;
  final String authorName;
  final String authorImage;
  final String timeAgo;
  final int loveCount;
  final int commentCount;
  final bool hasLoved;

  PostEntity({
    required this.id,
    required this.content,
    this.mediaUrl,
    required this.authorName,
    required this.authorImage,
    required this.timeAgo,
    this.loveCount = 0,
    this.commentCount = 0,
    this.hasLoved = false,
  });

  factory PostEntity.fromJson(Map<String, dynamic> json) {
    // Format created_at to time ago or date


      print("AUTHOR IMAGE = ${json['author_image']}");
  print("AUTHOR NAME = ${json['author_name']}");

    final createdAtStr = json['created_at'] as String? ?? '';
    String displayTime = '2 hours ago';
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

    return PostEntity(
      id: json['id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      mediaUrl: json['media_url']?.toString(),
      authorName: json['author_name']?.toString() ?? 'Rafiq',
      authorImage: json['author_image']?.toString() ?? '',
      timeAgo: displayTime,
      loveCount: json['love_count'] != null ? int.parse(json['love_count'].toString()) : 0,
      commentCount: json['comment_count'] != null ? int.parse(json['comment_count'].toString()) : 0,
      hasLoved: json['has_loved'] == true,
    );
  }
}

class CommentEntity {
  final String id;
  final String userName;
  final String userImage;
  final String text;
  final String timeAgo;
  final int likesCount;
  final bool hasLiked;
  final bool canDelete;
  final List<ReplyEntity> replies;

  CommentEntity({
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

  factory CommentEntity.fromJson(Map<String, dynamic> json, String currentUserId, String currentUserRole) {
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

    final List<ReplyEntity> reps = [];
    if (json['replies'] != null && json['replies'] is List) {
      for (var r in json['replies']) {
        reps.add(ReplyEntity.fromJson(r));
      }
    }

    return CommentEntity(
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

class ReplyEntity {
  final String id;
  final String userName;
  final String userImage;
  final String text;
  final String timeAgo;

  ReplyEntity({
    required this.id,
    required this.userName,
    required this.userImage,
    required this.text,
    required this.timeAgo,
  });

  factory ReplyEntity.fromJson(Map<String, dynamic> json) {
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

    return ReplyEntity(
      id: json['id']?.toString() ?? '',
      userName: json['author_name']?.toString() ?? 'User',
      userImage: json['author_image']?.toString() ?? '',
      text: json['content']?.toString() ?? '',
      timeAgo: displayTime,
    );
  }
}