// chat_message.dart

import 'assessment.dart';

enum ChatRole { user, assistant }

/// One bubble in the BCM Assistant conversation.
class ChatMessage {
  final ChatRole role;
  String text;

  /// True while tokens are still streaming into this bubble.
  bool isStreaming;

  /// Optional parsed maturity result attached to an assistant reply.
  PillarAssessment? assessment;

  ChatMessage({
    required this.role,
    this.text = '',
    this.isStreaming = false,
    this.assessment,
  });

  factory ChatMessage.user(String text) =>
      ChatMessage(role: ChatRole.user, text: text);

  factory ChatMessage.assistant({String text = '', bool streaming = false}) =>
      ChatMessage(role: ChatRole.assistant, text: text, isStreaming: streaming);
}
