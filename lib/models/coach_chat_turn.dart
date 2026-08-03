/// A single turn of Coach chat history sent to the LLM.
class CoachChatTurn {
  final bool isUser;
  final String content;

  const CoachChatTurn({
    required this.isUser,
    required this.content,
  });

  String get role => isUser ? 'user' : 'assistant';
}
