import 'package:rafiq/features/admin_chat/models/admin_chat_models.dart';

class AdminChatState {
  final List<AdminChatConversation> conversations;
  final List<AdminChatMessage> messages;
  final bool isConversationsLoading;
  final bool isMessagesLoading;
  final bool isTyping;
  final String? conversationsError;
  final String? messagesError;
  final int totalUnreadCount;
  final String currentUserId;
  final bool isAdmin;

  AdminChatState({
    this.conversations = const [],
    this.messages = const [],
    this.isConversationsLoading = false,
    this.isMessagesLoading = false,
    this.isTyping = false,
    this.conversationsError,
    this.messagesError,
    this.totalUnreadCount = 0,
    this.currentUserId = '',
    this.isAdmin = false,
  });

  AdminChatState copyWith({
    List<AdminChatConversation>? conversations,
    List<AdminChatMessage>? messages,
    bool? isConversationsLoading,
    bool? isMessagesLoading,
    bool? isTyping,
    String? conversationsError,
    String? messagesError,
    int? totalUnreadCount,
    String? currentUserId,
    bool? isAdmin,
  }) {
    return AdminChatState(
      conversations: conversations ?? this.conversations,
      messages: messages ?? this.messages,
      isConversationsLoading: isConversationsLoading ?? this.isConversationsLoading,
      isMessagesLoading: isMessagesLoading ?? this.isMessagesLoading,
      isTyping: isTyping ?? this.isTyping,
      conversationsError: conversationsError, // Nullable override
      messagesError: messagesError, // Nullable override
      totalUnreadCount: totalUnreadCount ?? this.totalUnreadCount,
      currentUserId: currentUserId ?? this.currentUserId,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}
