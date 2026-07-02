import 'package:rafiq/features/chatbot_and_assessment/data/datasource/dataresourceremote.dart';
import 'package:rafiq/features/chatbot_and_assessment/data/models/chatmodel.dart';
import 'package:rafiq/features/chatbot_and_assessment/domain/entities/chat_entity.dart';
import 'package:rafiq/features/chatbot_and_assessment/domain/repos/chat_repo.dart'; 

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;

  ChatRepositoryImpl({required this.remoteDataSource});

  @override
  Future<ChatMessage> sendMessage(String message) async {
    try {
      final chatModel = await remoteDataSource.sendMessage(message);
      return chatModel; 
    } catch (e) {
      throw Exception("Failed to send message: $e");
    }
  }

  @override
  Future<List<ChatMessage>> getChatHistory(String userId) async { 
    try {
      final List<ChatModel> chatModels = await remoteDataSource.getChatHistory(userId);
      
      return chatModels; 
    } catch (e) {
      throw Exception("Failed to fetch chat history from repository: $e");
    }
  }
}