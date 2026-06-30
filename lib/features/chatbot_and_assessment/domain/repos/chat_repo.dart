import '../entities/chat_entity.dart';

abstract class ChatRepository {
  Future<ChatMessage> sendMessage(String message);
  Future<List<ChatMessage>> getChatHistory(String userId); // 🌟 الدالة الجديدة المضافة
}