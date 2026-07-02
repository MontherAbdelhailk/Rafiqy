import 'package:dio/dio.dart';
import 'package:rafiq/core/utils/secure_storage.dart';
import 'package:rafiq/features/chatbot_and_assessment/data/models/chatmodel.dart';

abstract class ChatRemoteDataSource {
  Future<ChatModel> sendMessage(String message);
  Future<List<ChatModel>> getChatHistory(String userId); 
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final Dio dio;
  bool useMock = false; 

  ChatRemoteDataSourceImpl({required this.dio});

  @override
  Future<ChatModel> sendMessage(String message) async {
    if (useMock) {
      print("--- [CHAT] Using Mock Data ---");
      await Future.delayed(const Duration(seconds: 1));
      return ChatModel(
        text: "أهلاً بك يا صديقي! أنا رفيق أنا الـ Mock حالياً", 
        isBot: true, 
        timestamp: DateTime.now()
      );
    }

    try {
      const String url = 'https://ribatbackend-production.up.railway.app/chat';
      
      print("--- [CHAT] Sending Request to: $url ---");
      print("--- [CHAT] Payload: $message ---");

      final age = await SecureStorage.getAge();

print("AGE FROM STORAGE = $age");

      final response = await dio.post(
        url,
        data: {
          "user_id": await SecureStorage.getUserId(),
          "messages": [
            {"role": "user", "content": message}
          ],
          "child_age": age ?? 0,
        },
      ).timeout(const Duration(seconds: 15)); 

      print("--- [CHAT] Response Status: ${response.statusCode} ---");
      print("--- [CHAT] Response Data: ${response.data} ---");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ChatModel.fromJson(response.data);
      } else {
        print("--- [CHAT] Server Returned Error Status ---");
        throw Exception("Server Error");
      }
    } on DioException catch (e) {
      print("--- [CHAT] Dio Error: ${e.type} ---");
      print("--- [CHAT] Dio Error Message: ${e.message} ---");
      print("--- [CHAT] Server Response Error: ${e.response?.data} ---");
      throw Exception("Network Error: ${e.message}");
    } catch (e) {
      print("--- [CHAT] Unknown Error: $e ---");
      throw Exception("Unexpected Error occurred");
    }
  }

@override
Future<List<ChatModel>> getChatHistory(String userId) async {
  if (useMock) {
    print("--- [CHAT GET] Using Mock Data for History ---");
    await Future.delayed(const Duration(seconds: 1));
    return [
      ChatModel(text: "مرحباً! هذه رسالة قديمة من الـ Mock", isBot: true, timestamp: DateTime.now().subtract(const Duration(hours: 1))),
      ChatModel(text: "سؤال قديم مبعوث", isBot: false, timestamp: DateTime.now().subtract(const Duration(minutes: 30))),
    ];
  }

  try {
    final String url = 'https://ribatbackend-production.up.railway.app/chat/$userId'; 
    
    print("--- [CHAT GET] Fetching History from: $url ---");

    final response = await dio.get(url).timeout(const Duration(seconds: 15));

    print("--- [CHAT GET] Response Status: ${response.statusCode} ---");
    print("--- [CHAT GET] Response Data: ${response.data} ---");

    if (response.statusCode == 200) {
      final List<ChatModel> extractedMessages = [];
      
      List<dynamic> listData = [];
      if (response.data is Map && response.data['messages'] != null) {
        listData = response.data['messages'];
      } else if (response.data is List) {
        listData = response.data;
      }

for (var item in listData) {
        if (item['bot_reply'] != null && item['bot_reply'].toString().trim().isNotEmpty) {
          extractedMessages.add(ChatModel(
            text: item['bot_reply'],
            isBot: true, // بوت
            timestamp: item['created_at'] != null ? DateTime.parse(item['created_at']) : DateTime.now(),
          ));
        }

        if (item['user_message'] != null && item['user_message'].toString().trim().isNotEmpty) {
          extractedMessages.add(ChatModel(
            text: item['user_message'],
            isBot: false, // مستخدم
            timestamp: item['created_at'] != null ? DateTime.parse(item['created_at']) : DateTime.now(),
          ));
        }
      }
            return extractedMessages;
      
    } else {
      print("--- [CHAT GET] Server Returned Error Status ---");
      throw Exception("Server Error");
    }
  } on DioException catch (e) {
    print("--- [CHAT GET] Dio Error: ${e.type} ---");
    print("--- [CHAT GET] Dio Error Message: ${e.message} ---");
    print("--- [CHAT GET] Server Response Error: ${e.response?.data} ---");
    throw Exception("Network Error: ${e.message}");
  } catch (e) {
    print("--- [CHAT GET] Unknown Error: $e ---");
    throw Exception("Unexpected Error occurred");
  }   
}
  }
