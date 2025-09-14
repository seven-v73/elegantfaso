import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

@immutable
class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? intent;
  final Map<String, dynamic>? metadata;
  final MessageType type;
  final String? error;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.intent,
    this.metadata,
    this.type = MessageType.text,
    this.error,
  }) : id = const Uuid().v4();


  factory ChatMessage.user(String text) {
    return ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
  }

  factory ChatMessage.bot({
    required String text,
    String? intent,
    Map<String, dynamic>? metadata,
    MessageType type = MessageType.text,
  }) {
    return ChatMessage(
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
      intent: intent,
      metadata: metadata,
      type: type,
    );
  }

  factory ChatMessage.error(String errorMessage) {
    return ChatMessage(
      text: "Une erreur est survenue",
      isUser: false,
      timestamp: DateTime.now(),
      error: errorMessage,
      type: MessageType.error,
    );
  }

  factory ChatMessage.fromResponse(Map<String, dynamic> response) {
    final recommendation = response['recommendation'] ?? {};
    return ChatMessage.bot(
      text: response['text'] ?? '',
      intent: response['intention'],
      metadata: recommendation,
      type: _determineMessageType(response['intention'], recommendation),
    );
  }

  static MessageType _determineMessageType(String? intent, Map<String, dynamic> recommendation) {
    if (intent?.toLowerCase().contains('recommend') ?? false) {
      return MessageType.outfitSuggestion;
    } else if (intent == 'style_advice') {
      return MessageType.styleTip;
    } else if (intent == 'shopping') {
      return MessageType.shoppingSuggestion;
    }
    return MessageType.text;
  }

  String get formattedTime => DateFormat.Hm().format(timestamp);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ChatMessage &&
            runtimeType == other.runtimeType &&
            id == other.id;
  }

  @override
  int get hashCode => id.hashCode;
}

enum MessageType {
  text,
  image,
  product,
  outfitSuggestion,
  styleTip,
  shoppingSuggestion,
  error,
}