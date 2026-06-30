import 'package:rafiq/features/chatbot_and_assessment/domain/entities/chat_entity.dart';
import 'package:rafiq/features/chatbot_and_assessment/domain/repos/chat_repo.dart';


class SendMessageUseCase {
  final ChatRepository repository;
  SendMessageUseCase(this.repository);

  Future<ChatMessage> call(String message) async {
    return await repository.sendMessage(message);
  }
}

