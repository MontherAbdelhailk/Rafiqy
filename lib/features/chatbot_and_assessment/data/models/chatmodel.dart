// import 'package:rafiq/features/chatbot_and_assessment/domain/entities/chat_entity.dart';

// class ChatModel extends ChatMessage {
//   ChatModel({required super.text, required super.isBot, required super.timestamp});

//   factory ChatModel.fromJson(Map<String, dynamic> json) {
//     return ChatModel(
//       text: json['reply'] ?? json['message'] ?? "لا يوجد رد",
      
//       isBot: json['is_bot'] ?? false, 
      
//       timestamp: json['timestamp'] != null 
//           ? DateTime.parse(json['timestamp']) 
//           : DateTime.now(),    
//     );
//   }
// }

// features/chatbot_and_assessment/data/models/chatmodel.dart
import 'package:rafiq/features/chatbot_and_assessment/domain/entities/chat_entity.dart';

class ChatModel extends ChatMessage {
  ChatModel({required super.text, required super.isBot, required super.timestamp});

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    final bool checkedIsBot = json['is_bot'] ?? (json.containsKey('reply') ? true : false);

    return ChatModel(
      text: json['reply'] ?? json['message'] ?? "لا يوجد رد",
      
      isBot: checkedIsBot, // 👈 بقت مضمونة 100% للرد الفوري والتاريخ
      
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),    
    );
  }
}