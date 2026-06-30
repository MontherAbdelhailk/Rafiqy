class ChatMessage {
  final String text;
  final bool isBot;
  final DateTime timestamp;

  ChatMessage({
    required this.text, 
    required this.isBot, 
    required this.timestamp
  });
}