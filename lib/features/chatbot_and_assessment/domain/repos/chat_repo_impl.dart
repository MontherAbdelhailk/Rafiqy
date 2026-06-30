import 'package:rafiq/features/chatbot_and_assessment/data/datasource/dataresourceremote.dart';
import 'package:rafiq/features/chatbot_and_assessment/data/models/chatmodel.dart';
import 'package:rafiq/features/chatbot_and_assessment/domain/entities/chat_entity.dart';
import 'package:rafiq/features/chatbot_and_assessment/domain/repos/chat_repo.dart'; // أو حسب مسار الـ Abstract class عندك

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;

  ChatRepositoryImpl({required this.remoteDataSource});

  @override
  Future<ChatMessage> sendMessage(String message) async {
    try {
      final chatModel = await remoteDataSource.sendMessage(message);
      return chatModel; // بما إن الـ ChatModel بيـ inherit من ChatMessage هيرجع عادي جداً
    } catch (e) {
      throw Exception("Failed to send message: $e");
    }
  }

  @override
  Future<List<ChatMessage>> getChatHistory(String userId) async { // 🌟 الـ Override الجديد لجلب التاريخ
    try {
      final List<ChatModel> chatModels = await remoteDataSource.getChatHistory(userId);
      
      return chatModels; 
    } catch (e) {
      throw Exception("Failed to fetch chat history from repository: $e");
    }
  }
}