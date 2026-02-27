import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../modules/live_stream/models/live_stream_model.dart';
import '../../modules/live_stream/views/broadcast_page.dart';
import '../../routes/app_pages.dart';

/// Handles FCM notification tap: getInitialMessage (app opened from quit) and onMessageOpenedApp (app in background).
/// Navigates to the appropriate screen based on notificationType and data payload.
void setupPushNotificationTapHandler() {
  FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
    if (message != null) _navigateFromPayload(message.data);
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    _navigateFromPayload(message.data);
  });
}

void _navigateFromPayload(Map<String, dynamic> data) {
  if (data.isEmpty) return;
  final type = _string(data['notificationType']) ?? 'message';
  if (type == 'message') {
    final chatDocId = _string(data['chatDocId']);
    if (chatDocId == null || chatDocId.isEmpty) return;
    final parts = chatDocId.split('_');
    final artistId = parts.isNotEmpty ? int.tryParse(parts[0]) : null;
    final otherPartyUserId = parts.length > 1 ? parts.sublist(1).join('_') : null;
    final name = _string(data['name']) ?? 'Chat';
    final userType = _string(data['userType']);
    final isCurrentUserArtist = userType == 'user';
    Future.delayed(const Duration(milliseconds: 500), () {
      Get.toNamed(AppRoutes.artistMessage, arguments: {
        'artistId': artistId,
        'otherPartyUserId': otherPartyUserId,
        'otherPartyDisplayName': name,
        'isCurrentUserArtist': isCurrentUserArtist,
        'artistName': name,
        'artistImageUrl': null,
        'otherPartyImageUrl': null,
      });
    });
    return;
  }
  if (type == 'liveStream') {
    final liveStreamId = _string(data['liveStreamId']);
    if (liveStreamId == null || liveStreamId.isEmpty) return;
    _openLiveStreamById(liveStreamId);
    return;
  }
  final artistIdRaw = data['artistId'];
  final artistId = artistIdRaw is int
      ? artistIdRaw
      : (artistIdRaw is num ? artistIdRaw.toInt() : int.tryParse(artistIdRaw?.toString() ?? ''));
  if (artistId != null && artistId > 0) {
    final name = _string(data['name']) ?? 'Artist';
    Future.delayed(const Duration(milliseconds: 500), () {
      Get.toNamed(AppRoutes.artistDetail, arguments: {
        'artistId': artistId,
        'artistName': name,
      });
    });
  }
}

String? _string(dynamic v) {
  if (v == null) return null;
  if (v is String) return v.isEmpty ? null : v;
  return v.toString();
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
    Future.delayed(const Duration(milliseconds: 500), () {
      Get.to(() => BroadcastPage(
            isBroadcaster: false,
            liveStream: model,
          ));
    });
  } catch (_) {}
}
