import 'package:get/get.dart';

import '../../../core/network/apis/music_api.dart';
import '../../../core/utils/app_config.dart';
import '../../../core/utils/auth_service.dart';

/// Records a play for analytics / top content. Auth optional.
/// Call after starting playback (audio or video) when you have the entity id.
Future<void> recordPlayIfPossible(String entityType, int entityId) async {
  if (entityType != 'audio' && entityType != 'video') return;
  try {
    final config = AppConfig.fromEnv();
    String? token;
    if (Get.isRegistered<AuthService>()) {
      token = await Get.find<AuthService>().getIdToken();
    }
    final api = MusicApi(baseUrl: config.baseUrl, authToken: token);
    await api.recordPlay(entityType, entityId);
  } catch (_) {
    // ignore
  }
}
