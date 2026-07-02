import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rafiq/features/chatbot_and_assessment/data/models/chatmodel.dart';
import 'package:rafiq/features/chatbot_and_assessment/domain/entities/chat_entity.dart';
import 'package:rafiq/features/chatbot_and_assessment/domain/use_cases/get_chat_history_usecase.dart';
import 'package:rafiq/features/chatbot_and_assessment/domain/use_cases/send_message_usecase.dart';
import 'package:rafiq/features/chatbot_and_assessment/persentation/screens/logic/chatbot_states.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatBloc extends Cubit<ChatState> {
  final SendMessageUseCase sendMessageUseCase;
  final GetChatHistoryUseCase getChatHistoryUseCase; 
  
  final List<ChatMessage> allMessages = [];

  ChatBloc(this.sendMessageUseCase, this.getChatHistoryUseCase) : super(ChatInitial()){
    print("🚀 ChatBloc Initialized!");
  }

  // void getChatHistory(String userId) async {
  //   emit(ChatHistoryLoading()); 

  //   try {
  //     final history = await getChatHistoryUseCase.call(userId);
      
  //     allMessages.clear(); 
  //     allMessages.addAll(history); 

  //     if (allMessages.isEmpty) {
  //       emit(ChatInitial());
  //     } else {
  //       emit(ChatLoaded(List.from(allMessages))); 
  //     }
  //   } catch (e) {
  //     emit(ChatError(e.toString()));
  //     emit(ChatInitial()); 
  //   }
  // }


void getChatHistory(String userId) async {
  print("🔍 [DEBUG] داخل الـ getChatHistory يا ريس!");
  
  emit(ChatHistoryLoading()); 

  // 1. نحاول نجيب الكاش في try-catch منفصل عشان لو فشل ما يوقفش التطبيق
  try {
    final localCached = await getCachedMessages();
    if (localCached.isNotEmpty) {
      allMessages.clear();
      allMessages.addAll(localCached);
      emit(ChatLoaded(List.from(allMessages)));
      print("✅ [DEBUG] لقيت داتا في الكاش: ${allMessages.length}");
    }
  } catch (e) {
    print("⚠️ [DEBUG] الكاش فيه مشكلة بس عادي مكملين: $e");
  }

  // 2. كملي شغل الـ API عادي
  try {
    final history = await getChatHistoryUseCase.call(userId);
    print("🔍 [DEBUG] الـ API رجع ${history.length} رسالة");
    
    allMessages.clear(); 
    allMessages.addAll(history); 

    await cacheMessagesLocally(history); 

    if (allMessages.isEmpty) {
      emit(ChatInitial());
    } else {
      emit(ChatLoaded(List.from(allMessages))); 
    }
  } catch (e) {
    print("❌ [DEBUG] حصلت مشكلة في الـ API: $e");
    if (allMessages.isEmpty) {
      emit(ChatError(e.toString()));
      emit(ChatInitial());
    }
  }
}

  void sendMessage(String text) async {
  if (text.trim().isEmpty) return;

  // 1. إنشاء رسالة المستخدم
  final userMsg = ChatMessage(
    text: text, 
    isBot: false, 
    timestamp: DateTime.now(),
  );
  
  allMessages.insert(0, userMsg); 
  
  emit(ChatLoaded(List.from(allMessages)));

  try {
    final response = await sendMessageUseCase.call(text);
    
    allMessages.insert(0, response);
    
    emit(ChatLoaded(List.from(allMessages)));
  } catch (e) {
    emit(ChatError(e.toString()));
    emit(ChatLoaded(List.from(allMessages)));
  }
}

  // void sendMessage(String text) async {
  //   if (text.trim().isEmpty) return;

  //   final userMsg = ChatMessage(
  //     text: text, 
  //     isBot: false, 
  //     timestamp: DateTime.now(),
  //   );
  //   allMessages.add(userMsg);
    
  //   emit(ChatLoaded(List.from(allMessages)));

  //   try {
  //     final response = await sendMessageUseCase.call(text);
      
  //     allMessages.add(response);
      
  //     emit(ChatLoaded(List.from(allMessages)));
  //   } catch (e) {
  //     emit(ChatError(e.toString()));
  //     emit(ChatLoaded(List.from(allMessages)));
  //   }
  // }


Future<void> cacheMessagesLocally(List<ChatMessage> messages) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    
    List<String> encodedMessages = messages.map((msg) {
      return jsonEncode({
        'reply': msg.text,     // msg.text جاي من الـ Entity الأساسي سليم وزي الفل
        'is_bot': msg.isBot,   // msg.isBot جاي من الـ Entity
        'timestamp': msg.timestamp.toIso8601String(),
      });
    }).toList();
    
    await prefs.setStringList('cached_chat_history', encodedMessages);
    print("💾 [SharedPrefs Cache] تم حفظ الرسائل بنجاح محلياً! عدد الرسائل: ${encodedMessages.length}");
  } catch (e) {
    print("❌ [SharedPrefs Cache Error] فشل حفظ الرسائل في الكاش: $e");
  }
}

Future<List<ChatModel>> getCachedMessages() async {
  final prefs = await SharedPreferences.getInstance();
  final List<String>? encodedMessages = prefs.getStringList('cached_chat_history');
  
  if (encodedMessages != null) {
    return encodedMessages.map((msg) {
      return ChatModel.fromJson(jsonDecode(msg) as Map<String, dynamic>);
    }).toList();
  }
  return [];
}
}