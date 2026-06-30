
class AdminChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final String? mediaUrl;
  final bool isRead;
  final DateTime createdAt;

  AdminChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.mediaUrl,
    required this.isRead,
    required this.createdAt,
  });

  factory AdminChatMessage.fromJson(Map<String, dynamic> json) {
    return AdminChatMessage(
      id: json['id'] as String? ?? '',
      senderId: json['sender_id'] as String? ?? '',
      receiverId: json['receiver_id'] as String? ?? '',
      content: json['content'] as String? ?? '',
      mediaUrl: json['media_url'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      'media_url': mediaUrl,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class AdminChatConversation {
  final String id;
  final String fullName;
  final String username;
  final String? profilePicture;
  final String lastMessage;
  final String? lastMessageMediaUrl;
  final DateTime? lastMessageTime;
  final String lastMessageSenderId;
  final int unreadCount;

  AdminChatConversation({
    required this.id,
    required this.fullName,
    required this.username,
    this.profilePicture,
    required this.lastMessage,
    this.lastMessageMediaUrl,
    this.lastMessageTime,
    required this.lastMessageSenderId,
    required this.unreadCount,
  });

  factory AdminChatConversation.fromJson(Map<String, dynamic> json) {
    return AdminChatConversation(
      id: json['id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      profilePicture: json['profile_picture'] as String?,
      lastMessage: json['last_message'] as String? ?? '',
      lastMessageMediaUrl: json['last_message_media_url'] as String?,
      lastMessageTime: json['last_message_time'] != null
          ? DateTime.parse(json['last_message_time'] as String)
          : null,
      lastMessageSenderId: json['last_message_sender_id'] as String? ?? '',
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }
}
