
import 'package:rafiq/features/chatbot_and_assessment/domain/entities/chat_entity.dart';

class ChatModel extends ChatMessage {
  ChatModel({required super.text, required super.isBot, required super.timestamp});

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
text: json['reply'] ?? "لا يوجد رد",
      isBot: true,
      
timestamp: json['timestamp'] != null 
        ? DateTime.parse(json['timestamp']) 
        : DateTime.now(),    );
  }
}