import 'dart:convert';

import 'package:http/http.dart' as http;

import '../base_api.dart';
import '../api_client.dart';
import '../../constants/api_constants.dart';

/// API for chat message history (MySQL-backed, paginated). Real-time messages stay in Firebase.
class ChatApi extends BaseApi {
  ChatApi({
    required super.baseUrl,
    super.authToken,
    super.timeout,
    super.debugPrintRequest,
  });

  /// GET /api/v1/chats/messages?chatDocId=&before=&limit=
  /// Returns older messages from MySQL. Auth required.
  Future<ChatMessagesResponse?> getMessages({
    required String chatDocId,
    String? before,
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, String>{
        'chatDocId': chatDocId,
        'limit': limit.toString(),
      };
      if (before != null && before.isNotEmpty) {
        queryParams['before'] = before;
      }
      final response = await execute(
        'GET',
        ApiConstants.chatsMessagesPath,
        queryParams: queryParams,
        visibility: ApiVisibility.private,
      );
      if (response.statusCode != 200) return null;
      final map = jsonDecode(response.body) as Map<String, dynamic>?;
      if (map == null) return null;
      final data = map['data'] as Map<String, dynamic>?;
      if (data == null) return null;
      return ChatMessagesResponse.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  /// POST /api/v1/chats/send-message — send message via API (Firestore + push to all recipient devices).
  Future<SendMessageResult?> sendMessage({ required String chatDocId, required String text }) async {
    try {
      final response = await execute(
        'POST',
        ApiConstants.chatsSendMessagePath,
        body: { 'chatDocId': chatDocId, 'text': text },
        visibility: ApiVisibility.private,
      );
      if (response.statusCode != 200) return null;
      final map = jsonDecode(response.body) as Map<String, dynamic>?;
      if (map == null || ((map['success'] as bool?) != true)) return null;
      final data = map['data'] as Map<String, dynamic>?;
      if (data == null) return null;
      final createdAt = data['createdAt'];
      return SendMessageResult(
        messageId: data['messageId'] as String?,
        createdAt: createdAt is String ? DateTime.tryParse(createdAt) ?? DateTime.now() : DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }
}

class SendMessageResult {
  SendMessageResult({ this.messageId, required this.createdAt });
  final String? messageId;
  final DateTime createdAt;
}

class ChatMessagesResponse {
  ChatMessagesResponse({ required this.messages, this.nextBefore });
  final List<ChatHistoryMessage> messages;
  final String? nextBefore;

  factory ChatMessagesResponse.fromJson(Map<String, dynamic> json) {
    final list = json['messages'] as List<dynamic>? ?? [];
    return ChatMessagesResponse(
      messages: list.map((e) => ChatHistoryMessage.fromJson(e as Map<String, dynamic>)).toList(),
      nextBefore: json['nextBefore'] as String?,
    );
  }
}

class ChatHistoryMessage {
  ChatHistoryMessage({
    required this.id,
    required this.text,
    required this.senderType,
    required this.senderId,
    required this.createdAt,
  });
  final String id;
  final String text;
  final String senderType;
  final String senderId;
  final DateTime createdAt;

  factory ChatHistoryMessage.fromJson(Map<String, dynamic> json) {
    final createdAt = json['createdAt'];
    return ChatHistoryMessage(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      senderType: json['senderType'] as String? ?? 'user',
      senderId: json['senderId'] as String? ?? '',
      createdAt: createdAt is String ? DateTime.tryParse(createdAt) ?? DateTime.now() : DateTime.now(),
    );
  }
}
