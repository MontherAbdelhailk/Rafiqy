import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:rafiq/core/networking/api_consumer.dart';
import 'package:rafiq/core/networking/notification_service.dart';
import 'package:rafiq/core/utils/secure_storage.dart';
import 'package:rafiq/features/admin_chat/models/admin_chat_models.dart';
import 'package:rafiq/features/admin_chat/persenation/logic/admin_chat_state.dart';

class AdminChatCubit extends Cubit<AdminChatState> {
  final ApiConsumer apiConsumer;
  IO.Socket? _socket;
  String? _activeRoomUserId;
  final NotificationService _notificationService = NotificationService();

  AdminChatCubit(this.apiConsumer) : super(AdminChatState()) {
    _initUser();
  }

  String? get activeRoomUserId => _activeRoomUserId;

  Future<void> _initUser() async {
    final userId = await SecureStorage.getUserId() ?? '';
    final isAdmin = await SecureStorage.isAdmin();
    emit(state.copyWith(currentUserId: userId, isAdmin: isAdmin));
  }

  void setActiveRoom(String? userId) {
    _activeRoomUserId = userId;
    if (userId != null) {
      // Clear typing indicator for a new room
      emit(state.copyWith(isTyping: false));
      markConversationAsRead(userId);
    }
  }

  // ── REST API Methods ────────────────────────────────────────────────────────

  Future<void> loadConversations({String search = ''}) async {
    emit(state.copyWith(isConversationsLoading: true, conversationsError: null));
    try {
      final response = await apiConsumer.get('chat/conversations', queryParameters: {
        if (search.isNotEmpty) 'search': search,
      });

      final List<dynamic> data = response['data'] ?? [];
      final conversations = data.map((json) => AdminChatConversation.fromJson(json)).toList();

      emit(state.copyWith(
        conversations: conversations,
        isConversationsLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isConversationsLoading: false,
        conversationsError: e.toString(),
      ));
    }
  }

  Future<void> loadHistory(String userId) async {
    emit(state.copyWith(isMessagesLoading: true, messagesError: null));
    try {
      final response = await apiConsumer.get('chat/messages/$userId');
      final List<dynamic> data = response['data'] ?? [];
      final messages = data.map((json) => AdminChatMessage.fromJson(json)).toList();

      emit(state.copyWith(
        messages: messages,
        isMessagesLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isMessagesLoading: false,
        messagesError: e.toString(),
      ));
    }
  }

  Future<void> markConversationAsRead(String userId) async {
    try {
      await apiConsumer.patch('chat/conversations/$userId/read');
      // If we are admin, refresh unread counts & thread details on list
      final isAdmin = await SecureStorage.isAdmin();
      if (isAdmin) {
        loadConversations();
      }
      loadUnreadCount();

      // Notify server via socket so sender receives read_status update in real-time
      if (_socket != null && _socket!.connected) {
        _socket!.emit('mark_read', {
          'senderId': userId,
        });
      }
    } catch (_) {
      // Silently handle read status failure
    }
  }

  Future<void> loadUnreadCount() async {
    try {
      final response = await apiConsumer.get('chat/unread');
      final int count = response['data']?['unread_count'] ?? 0;
      emit(state.copyWith(totalUnreadCount: count));
    } catch (_) {
      // Silently handle failure
    }
  }

  Future<void> registerFCMToken(String token) async {
    try {
      await apiConsumer.post('chat/register-token', data: {'token': token});
    } catch (_) {
      // Silently handle failure
    }
  }

  // ── Socket.IO Connection & Events ──────────────────────────────────────────

  Future<void> connectSocket() async {
    // Ensure user identity is resolved BEFORE socket connects and events fire
    await _initUser();

    if (_socket != null && _socket!.connected) return;

    final token = await SecureStorage.getToken();
    if (token == null || token.isEmpty) return;

    // Use standard 10.0.2.2 emulator IP. Fallback to localhost if needed.
    const socketUrl = 'http://10.0.2.2:5000';

    _socket = IO.io(
      socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(2000)
          .setReconnectionAttempts(5)
          .build(),
    );

    _socket!.onConnect((_) {
      print('🔌 Connected to Chat Socket Server');
    });

    _socket!.onDisconnect((_) {
      print('🔌 Disconnected from Chat Socket Server');
    });

    _socket!.onConnectError((err) {
      print('🔌 Socket Connect Error: $err');
    });

    _socket!.onError((err) {
      print('🔌 Socket Error: $err');
    });

    _socket!.on('new_message', (data) async {
      final message = AdminChatMessage.fromJson(data);
      final currentUserId = state.currentUserId.isNotEmpty
          ? state.currentUserId
          : await SecureStorage.getUserId();
      final isAdmin = state.isAdmin;

      // Check if message belongs to active chat room.
      // For normal users: relevant if activeRoom == 'admin' OR if the message
      // involves the current user (handles socket echo with actual UUID).
      final isRelevant = isAdmin
          ? (message.senderId == _activeRoomUserId || message.receiverId == _activeRoomUserId)
          : (_activeRoomUserId != null &&
              (message.senderId == currentUserId || message.receiverId == currentUserId));

      if (isRelevant) {
        // Append to local message list in state (only if not already there)
        final alreadyAppended = state.messages.any((m) => m.id == message.id);
        if (!alreadyAppended) {
          final updatedMessages = List<AdminChatMessage>.from(state.messages)..add(message);
          emit(state.copyWith(messages: updatedMessages));
        }

        // Mark as read immediately since user is actively looking at it
        if (message.senderId != currentUserId) {
          markConversationAsRead(_activeRoomUserId!);
        }
      } else {
        // Send local notification alert if the message was sent by someone else
        if (message.senderId != currentUserId) {
          final title = isAdmin ? 'New User Message' : 'Message from Rafiq Admin';
          _notificationService.showTextNotification(
            title: title,
            body: message.content.isNotEmpty ? message.content : 'Sent an image',
          );
        }
        
        // Refresh conversations lists & counts in background
        if (isAdmin) {
          loadConversations();
        }
        loadUnreadCount();
      }
    });

    _socket!.on('typing_status', (data) {
      final String senderId = data['senderId'] ?? '';
      // typerId is the sender's actual UUID (added server-side) for self-exclusion
      final String typerId = data['typerId'] ?? '';
      final bool isTyping = data['isTyping'] == true;

      // Guard 1: never show a typing indicator for our own actions
      final currentId = state.currentUserId;
      if (currentId.isNotEmpty && typerId == currentId) return;

      // Guard 2: only update the indicator when the typer is the person we are
      // actively chatting with in the open room
      if (senderId == _activeRoomUserId) {
        emit(state.copyWith(isTyping: isTyping));
      }
    });

    _socket!.on('read_status_updated', (data) {
      final String senderId = data['senderId'] ?? '';
      final String receiverId = data['receiverId'] ?? '';

      // If active conversation messages were marked read, sync local isRead status
      final isCurrentUserParticipant = (senderId == state.currentUserId || receiverId == state.currentUserId);
      final isCounterpartParticipant = state.isAdmin
          ? (senderId == _activeRoomUserId || receiverId == _activeRoomUserId)
          : (senderId != state.currentUserId || receiverId != state.currentUserId);

      if (isCurrentUserParticipant && isCounterpartParticipant) {
        final updatedMessages = state.messages.map((msg) {
          if (msg.senderId == senderId && msg.receiverId == receiverId) {
            return AdminChatMessage(
              id: msg.id,
              senderId: msg.senderId,
              receiverId: msg.receiverId,
              content: msg.content,
              mediaUrl: msg.mediaUrl,
              isRead: true,
              createdAt: msg.createdAt,
            );
          }
          return msg;
        }).toList();

        emit(state.copyWith(messages: updatedMessages));
      }
    });

    // Event emitted when conversations update for admin
    _socket!.on('admin_conversations_updated', (_) {
      loadConversations();
      loadUnreadCount();
    });

    _socket!.on('admin_new_message', (_) {
      loadConversations();
      loadUnreadCount();
    });

    _socket!.connect();
  }

  void disconnectSocket() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  // ── Emit socket events ──────────────────────────────────────────────────────

  /// Send a text message. Tries socket first; falls back to REST if disconnected.
  void sendMessage(String content, {String? receiverId}) {
    if (_socket != null && _socket!.connected) {
      // Fast path: send via socket
      _socket!.emitWithAck('send_message', {
        'content': content,
        'receiverId': receiverId,
      }, ack: (data) {
        if (data != null && data['success'] == true) {
          final message = AdminChatMessage.fromJson(data['data']);
          // The socket server broadcasts 'new_message' to sender too, so the
          // listener handles appending. We only add here as a safety net.
          final alreadyAppended = state.messages.any((m) => m.id == message.id);
          if (!alreadyAppended) {
            final updatedMessages = List<AdminChatMessage>.from(state.messages)..add(message);
            emit(state.copyWith(messages: updatedMessages));
          }
          loadConversations(); // Update previews
        }
      });
    } else {
      // Fallback: send via REST API (also broadcasts via socket server-side)
      _sendMessageViaRest(content, receiverId: receiverId);
    }
  }

  /// REST fallback for sendMessage — used when socket is not yet connected.
  Future<void> _sendMessageViaRest(String content, {String? receiverId}) async {
    try {
      final Map<String, dynamic> body = {'content': content};
      if (receiverId != null) body['receiverId'] = receiverId;

      final response = await apiConsumer.post('chat/messages', data: body);

      if (response != null && response['success'] == true) {
        final message = AdminChatMessage.fromJson(response['data']);
        final alreadyAppended = state.messages.any((m) => m.id == message.id);
        if (!alreadyAppended) {
          final updatedMessages = List<AdminChatMessage>.from(state.messages)..add(message);
          emit(state.copyWith(messages: updatedMessages));
        }
        loadConversations(); // Update previews
      }
    } catch (e) {
      print('sendMessage REST fallback error: $e');
    }
  }

  Future<void> sendImageMessage(String imagePath, {String? receiverId}) async {
    try {
      final formData = FormData.fromMap({
        if (receiverId != null) 'receiverId': receiverId,
        'image': await MultipartFile.fromFile(imagePath),
      });

      final response = await apiConsumer.post(
        'chat/messages',
        data: formData,
        isFormData: true,
      );

      if (response != null && response['success'] == true) {
        final message = AdminChatMessage.fromJson(response['data']);
        
        final alreadyAppended = state.messages.any((m) => m.id == message.id);
        if (!alreadyAppended) {
          final updatedMessages = List<AdminChatMessage>.from(state.messages)..add(message);
          emit(state.copyWith(messages: updatedMessages));
        }

        loadConversations(); // Update previews
      }
    } catch (e) {
      print('🔌 sendImageMessage failed to upload image: $e');
    }
  }

  void sendTypingStatus(String receiverId, bool isTyping) {
    if (_socket == null || !_socket!.connected) return;

    _socket!.emit('typing_status', {
      'receiverId': receiverId,
      'isTyping': isTyping,
    });
  }

  @override
  Future<void> close() {
    disconnectSocket();
    return super.close();
  }
}
