import 'package:rafiq/features/chatbot_and_assessment/domain/entities/chat_entity.dart';

abstract class ChatState {}

class ChatInitial extends ChatState {}

class ChatHistoryLoading extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final List<ChatMessage> messages;
  ChatLoaded(this.messages);
}

class ChatError extends ChatState {
  final String message;
  ChatError(this.message);
}