import 'dart:convert';

import '../base_api.dart';
import '../../constants/api_constants.dart';

/// API for user notifications: notify (record + push), presence, history, read, delete.
class NotificationsApi extends BaseApi {
  NotificationsApi({
    required super.baseUrl,
    super.authToken,
    super.timeout,
    super.debugPrintRequest,
  });

  /// POST /api/v1/notifications/notify — record and send push (skips if recipient on same screen).
  /// Pass either recipient_user_id OR (chat_doc_id + is_sender_artist).
  Future<NotifyResult?> notify({
    int? recipientUserId,
    String? chatDocId,
    bool? isSenderArtist,
    String notificationType = 'message',
    required String title,
    required String body,
    Map<String, dynamic>? data,
    int? senderArtistId,
    int? senderUserId,
    String? liveStreamId,
    int messageCount = 1,
  }) async {
    try {
      final bodyMap = <String, dynamic>{
        'notification_type': notificationType,
        'title': title,
        'body': body,
        'message_count': messageCount,
      };
      if (recipientUserId != null) bodyMap['recipient_user_id'] = recipientUserId;
      if (chatDocId != null) bodyMap['chat_doc_id'] = chatDocId;
      if (isSenderArtist != null) bodyMap['is_sender_artist'] = isSenderArtist;
      if (data != null && data.isNotEmpty) bodyMap['data'] = data;
      if (senderArtistId != null) bodyMap['sender_artist_id'] = senderArtistId;
      if (senderUserId != null) bodyMap['sender_user_id'] = senderUserId;
      if (liveStreamId != null) bodyMap['live_stream_id'] = liveStreamId;

      final response = await execute(
        'POST',
        ApiConstants.notificationsNotifyPath,
        body: bodyMap,
        visibility: ApiVisibility.private,
      );
      if (response.statusCode != 200) return null;
      final map = jsonDecode(response.body) as Map<String, dynamic>?;
      final dataObj = map?['data'] as Map<String, dynamic>?;
      if (dataObj == null) return null;
      return NotifyResult(
        notificationId: dataObj['notificationId'] as int?,
        recorded: dataObj['recorded'] as bool? ?? false,
        sent: dataObj['sent'] as bool? ?? false,
        reason: dataObj['reason'] as String?,
        successCount: dataObj['successCount'] as int? ?? 0,
      );
    } catch (_) {
      return null;
    }
  }

  /// PUT /api/v1/notifications/presence — set current screen for skip-push logic.
  Future<bool> setPresence({required String screen, String? contextId}) async {
    try {
      final response = await execute(
        'PUT',
        ApiConstants.notificationsPresencePath,
        body: {
          'screen': screen,
          if (contextId != null && contextId.isNotEmpty) 'context_id': contextId,
        },
        visibility: ApiVisibility.private,
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// GET /api/v1/notifications — list current user's notification history.
  Future<NotificationsListResult?> list({int limit = 50, int offset = 0}) async {
    try {
      final response = await execute(
        'GET',
        ApiConstants.notificationsPath,
        queryParams: {'limit': limit.toString(), 'offset': offset.toString()},
        visibility: ApiVisibility.private,
      );
      if (response.statusCode != 200) return null;
      final map = jsonDecode(response.body) as Map<String, dynamic>?;
      final dataObj = map?['data'] as Map<String, dynamic>?;
      if (dataObj == null) return null;
      final items = (dataObj['items'] as List<dynamic>?)
          ?.map((e) => UserNotificationItem.fromJson(e as Map<String, dynamic>))
          .toList() ?? [];
      return NotificationsListResult(
        items: items,
        total: dataObj['total'] as int? ?? 0,
        limit: dataObj['limit'] as int? ?? limit,
        offset: dataObj['offset'] as int? ?? offset,
      );
    } catch (_) {
      return null;
    }
  }

  /// GET /api/v1/notifications/unread-count
  Future<int> unreadCount() async {
    try {
      final response = await execute(
        'GET',
        ApiConstants.notificationsUnreadCountPath,
        visibility: ApiVisibility.private,
      );
      if (response.statusCode != 200) return 0;
      final map = jsonDecode(response.body) as Map<String, dynamic>?;
      final dataObj = map?['data'] as Map<String, dynamic>?;
      return dataObj?['count'] as int? ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// PATCH /api/v1/notifications/:id/read
  Future<bool> markRead(int id) async {
    try {
      final response = await execute(
        'PATCH',
        ApiConstants.notificationsMarkReadPath(id),
        visibility: ApiVisibility.private,
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// DELETE /api/v1/notifications/:id
  Future<bool> deleteOne(int id) async {
    try {
      final response = await execute(
        'DELETE',
        ApiConstants.notificationsDeletePath(id),
        visibility: ApiVisibility.private,
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// DELETE /api/v1/notifications — clear all for current user.
  Future<bool> clearAll() async {
    try {
      final response = await execute(
        'DELETE',
        ApiConstants.notificationsPath,
        visibility: ApiVisibility.private,
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

class NotifyResult {
  final int? notificationId;
  final bool recorded;
  final bool sent;
  final String? reason;
  final int successCount;
  NotifyResult({
    this.notificationId,
    required this.recorded,
    required this.sent,
    this.reason,
    required this.successCount,
  });
}

class NotificationsListResult {
  final List<UserNotificationItem> items;
  final int total;
  final int limit;
  final int offset;
  NotificationsListResult({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
  });
}

class UserNotificationItem {
  final int id;
  final String notificationType;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final DateTime? readAt;
  final DateTime createdAt;
  final int? senderArtistId;
  final int? senderUserId;
  final String? chatDocId;
  final String? liveStreamId;
  final int messageCount;

  UserNotificationItem({
    required this.id,
    required this.notificationType,
    required this.title,
    required this.body,
    this.data,
    this.readAt,
    required this.createdAt,
    this.senderArtistId,
    this.senderUserId,
    this.chatDocId,
    this.liveStreamId,
    this.messageCount = 1,
  });

  factory UserNotificationItem.fromJson(Map<String, dynamic> json) {
    final readAt = json['read_at'];
    final createdAt = json['created_at'];
    return UserNotificationItem(
      id: json['id'] as int? ?? 0,
      notificationType: json['notification_type'] as String? ?? 'message',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      data: json['data'] is Map ? Map<String, dynamic>.from(json['data'] as Map) : null,
      readAt: readAt is String ? DateTime.tryParse(readAt) : null,
      createdAt: createdAt is String ? DateTime.tryParse(createdAt) ?? DateTime.now() : DateTime.now(),
      senderArtistId: json['sender_artist_id'] as int?,
      senderUserId: json['sender_user_id'] as int?,
      chatDocId: json['chat_doc_id'] as String?,
      liveStreamId: json['live_stream_id'] as String?,
      messageCount: json['message_count'] as int? ?? 1,
    );
  }

  bool get isRead => readAt != null;

  /// Display line: e.g. "Katty Parry sent a message" or "Muhammad Ahsan sent a notification"
  String get displayTitle => title;

  String get displayBody => body;
}
