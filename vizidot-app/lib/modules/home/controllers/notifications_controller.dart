import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/app_config.dart';
import '../../../core/network/apis/notifications_api.dart';
import '../../../routes/app_pages.dart';
import '../../live_stream/models/live_stream_model.dart';
import '../../live_stream/views/broadcast_page.dart';
/// Controller for notification history: list, unread count, mark read, delete, navigate by type.
class NotificationsController extends GetxController {
  final list = <UserNotificationItem>[].obs;
  final total = 0.obs;
  final unreadCount = 0.obs;
  final loading = false.obs;
  final clearing = false.obs;

  static const int _pageSize = 50;

  Future<String?> _token() async {
    return FirebaseAuth.instance.currentUser?.getIdToken();
  }

  Future<void> _apiWithToken(Future<void> Function(NotificationsApi api) fn) async {
    final token = await _token();
    if (token == null) return;
    final config = Get.isRegistered<AppConfig>() ? Get.find<AppConfig>() : AppConfig.fromEnv();
    final baseUrl = config.baseUrl.replaceFirst(RegExp(r'/$'), '');
    final api = NotificationsApi(baseUrl: baseUrl, authToken: token);
    await fn(api);
  }

  @override
  void onReady() {
    super.onReady();
    load();
    refreshUnreadCount();
  }

  Future<void> load() async {
    if (loading.value) return;
    loading.value = true;
    try {
      await _apiWithToken((api) async {
        final result = await api.list(limit: _pageSize, offset: 0);
        if (result != null) {
          list.assignAll(result.items);
          total.value = result.total;
        }
      });
    } finally {
      loading.value = false;
    }
  }

  Future<void> refreshUnreadCount() async {
    await _apiWithToken((api) async {
      final count = await api.unreadCount();
      unreadCount.value = count;
    });
  }

  Future<void> markAsRead(UserNotificationItem item) async {
    if (item.isRead) return;
    await _apiWithToken((api) async {
      final ok = await api.markRead(item.id);
      if (ok) {
        final idx = list.indexWhere((e) => e.id == item.id);
        if (idx >= 0) {
          final updated = UserNotificationItem(
            id: item.id,
            notificationType: item.notificationType,
            title: item.title,
            body: item.body,
            data: item.data,
            readAt: DateTime.now(),
            createdAt: item.createdAt,
            senderArtistId: item.senderArtistId,
            senderUserId: item.senderUserId,
            chatDocId: item.chatDocId,
            liveStreamId: item.liveStreamId,
            messageCount: item.messageCount,
          );
          list[idx] = updated;
        }
        unreadCount.value = (unreadCount.value - 1).clamp(0, 999999);
      }
    });
  }

  Future<void> deleteOne(UserNotificationItem item) async {
    await _apiWithToken((api) async {
      final ok = await api.deleteOne(item.id);
      if (ok) {
        list.removeWhere((e) => e.id == item.id);
        total.value = (total.value - 1).clamp(0, 999999);
        if (!item.isRead) unreadCount.value = (unreadCount.value - 1).clamp(0, 999999);
      }
    });
  }

  Future<void> clearAll() async {
    if (clearing.value) return;
    clearing.value = true;
    try {
      await _apiWithToken((api) async {
        final ok = await api.clearAll();
        if (ok) {
          list.clear();
          total.value = 0;
          unreadCount.value = 0;
        }
      });
    } finally {
      clearing.value = false;
    }
  }

  /// Navigate to the appropriate screen based on notification type and data.
  void handleTap(UserNotificationItem item) {
    markAsRead(item);
    final type = item.notificationType;
    final data = item.data ?? {};

    if (type == 'message') {
      final chatDocId = item.chatDocId ?? data['chatDocId'] as String?;
      if (chatDocId == null || chatDocId.isEmpty) return;
      final parts = chatDocId.split('_');
      final artistId = parts.isNotEmpty ? int.tryParse(parts[0]) : null;
      final otherPartyUserId = parts.length > 1 ? parts.sublist(1).join('_') : null;
      final title = item.title;
      final userType = data['userType'] as String?;
      final isCurrentUserArtist = userType == 'user';
      Get.toNamed(AppRoutes.artistMessage, arguments: {
        'artistId': artistId,
        'otherPartyUserId': otherPartyUserId,
        'otherPartyDisplayName': title,
        'isCurrentUserArtist': isCurrentUserArtist,
        'artistName': title,
        'artistImageUrl': null,
        'otherPartyImageUrl': null,
      });
      return;
    }

    if (type == 'liveStream') {
      final liveStreamId = item.liveStreamId ?? data['liveStreamId'] as String?;
      if (liveStreamId == null || liveStreamId.isEmpty) return;
      _openLiveStreamById(liveStreamId);
      return;
    }

    if (type == 'user' || data['userId'] != null) {
      final name = data['name'] as String? ?? item.title;
      final artistIdForProfile = item.senderArtistId ?? data['artistId'];
      if (artistIdForProfile != null) {
        Get.toNamed(AppRoutes.artistDetail, arguments: {
          'artistId': artistIdForProfile,
          'artistName': name,
        });
      }
      return;
    }

    if (item.senderArtistId != null) {
      Get.toNamed(AppRoutes.artistDetail, arguments: {
        'artistId': item.senderArtistId,
        'artistName': item.title,
      });
    }
  }

  Future<void> _openLiveStreamById(String liveStreamId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('LiveStreams')
          .doc(liveStreamId)
          .get();
      if (!doc.exists || doc.data() == null) return;
      final model = LiveStreamModel.fromMap(
        Map<String, dynamic>.from(doc.data()!),
      );
      model.identifier = liveStreamId;
      Get.to(() => BroadcastPage(
            isBroadcaster: false,
            liveStream: model,
          ));
    } catch (_) {}
  }
}
