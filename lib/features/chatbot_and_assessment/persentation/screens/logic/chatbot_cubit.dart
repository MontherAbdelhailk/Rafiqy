import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rafiq/features/chatbot_and_assessment/domain/entities/chat_entity.dart';
import 'package:rafiq/features/chatbot_and_assessment/domain/use_cases/get_chat_history_usecase.dart';
import 'package:rafiq/features/chatbot_and_assessment/domain/use_cases/send_message_usecase.dart';
import 'package:rafiq/features/chatbot_and_assessment/persentation/screens/logic/chatbot_states.dart';

class ChatBloc extends Cubit<ChatState> {
  final SendMessageUseCase sendMessageUseCase;
  final GetChatHistoryUseCase getChatHistoryUseCase; 
  
  final List<ChatMessage> allMessages = [];

  ChatBloc(this.sendMessageUseCase, this.getChatHistoryUseCase) : super(ChatInitial());

  void getChatHistory(String userId) async {
    emit(ChatHistoryLoading()); 

    try {
      final history = await getChatHistoryUseCase.call(userId);
      
      allMessages.clear(); 
      allMessages.addAll(history); 

      if (allMessages.isEmpty) {
        emit(ChatInitial());
      } else {
        emit(ChatLoaded(List.from(allMessages))); 
      }
    } catch (e) {
      emit(ChatError(e.toString()));
      emit(ChatInitial()); 
    }
  }

  void sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessage(
      text: text, 
      isBot: false, 
      timestamp: DateTime.now(),
    );
    allMessages.add(userMsg);
    
    emit(ChatLoaded(List.from(allMessages)));

    try {
      final response = await sendMessageUseCase.call(text);
      
      allMessages.add(response);
      
      emit(ChatLoaded(List.from(allMessages)));
    } catch (e) {
      emit(ChatError(e.toString()));
      emit(ChatLoaded(List.from(allMessages)));
    }
  }
}