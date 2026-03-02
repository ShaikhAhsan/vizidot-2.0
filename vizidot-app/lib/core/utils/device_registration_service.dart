import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import 'app_config.dart';
import '../network/apis/device_api.dart';
import 'auth_service.dart';

const _storageKeyDeviceId = 'vizidot_device_id';

/// Manages device_id (stable UUID per app install) and FCM token registration with the backend.
/// Call [registerDevice] after login and when FCM token refreshes; call [logoutDevice] before signOut.
class DeviceRegistrationService extends GetxService {
  @override
  void onInit() {
    super.onInit();
    listenToTokenRefresh();
  }

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  final _uuid = const Uuid();

  /// Returns a stable device_id (UUID). Generates and stores once per app install.
  Future<String> getOrCreateDeviceId() async {
    try {
      String? id = await _storage.read(key: _storageKeyDeviceId);
      if (id == null || id.isEmpty) {
        id = _uuid.v4();
        await _storage.write(key: _storageKeyDeviceId, value: id);
      }
      return id;
    } catch (_) {
      return _uuid.v4();
    }
  }

  /// Platform string for API: ios, android, or web.
  String get platform {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.android:
        return 'android';
      default:
        return 'web';
    }
  }

  /// Returns true if notification permission is already granted (no dialog). Use before requesting on app open.
  Future<bool> hasNotificationPermission() async {
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final status = await Permission.notification.status;
        if (status.isDenied || status.isPermanentlyDenied) return false;
      }
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (_) {
      return false;
    }
  }

  /// Request push notification permission (iOS: system dialog; Android 13+: POST_NOTIFICATIONS).
  /// Call on login so the user is prompted. Returns true if granted or already granted.
  Future<bool> requestNotificationPermission() async {
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final status = await Permission.notification.request();
        if (status.isDenied || status.isPermanentlyDenied) return false;
      }
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (_) {
      return false;
    }
  }

  /// Get current FCM token. If [requestPermissionFirst] is true (default), requests permission then gets token.
  /// Returns null if permission denied or token unavailable.
  Future<String?> getFcmToken({bool requestPermissionFirst = true}) async {
    try {
      final messaging = FirebaseMessaging.instance;
      if (requestPermissionFirst) {
        final granted = await requestNotificationPermission();
        if (!granted) return null;
      } else {
        final settings = await messaging.getNotificationSettings();
        if (settings.authorizationStatus == AuthorizationStatus.denied ||
            settings.authorizationStatus == AuthorizationStatus.notDetermined) {
          return null;
        }
      }
      final token = await messaging.getToken();
      return token;
    } catch (_) {
      return null;
    }
  }

  /// Register this device with the backend (auth required). Call after login and on token refresh.
  /// When [requestPermissionIfNeeded] is true (e.g. app open when already logged in): checks permission first;
  /// only requests (shows dialog) if not already granted, then gets token and updates API.
  /// When false (e.g. token refresh): gets token without requesting permission.
  /// After fresh login the caller typically requests permission first via [getFcmToken](requestPermissionFirst: true).
  Future<bool> registerDevice({bool requestPermissionIfNeeded = true}) async {
    final auth = Get.isRegistered<AuthService>() ? Get.find<AuthService>() : null;
    if (auth == null || !auth.isLoggedIn.value) return false;
    final token = await auth.getIdToken();
    if (token == null || token.isEmpty) return false;

    final config = AppConfig.fromEnv();
    final baseUrl = config.baseUrl.replaceFirst(RegExp(r'/$'), '');
    final deviceId = await getOrCreateDeviceId();
    final requestPermissionFirst = requestPermissionIfNeeded && !(await hasNotificationPermission());
    final fcmToken = await getFcmToken(requestPermissionFirst: requestPermissionFirst);

    final api = DeviceApi(baseUrl: baseUrl, authToken: token);
    return api.register(
      deviceId: deviceId,
      platform: platform,
      fcmToken: fcmToken,
      deviceName: null,
    );
  }

  /// De-register this device (set is_active = false). Call before signOut while still authenticated.
  Future<bool> logoutDevice() async {
    final auth = Get.isRegistered<AuthService>() ? Get.find<AuthService>() : null;
    if (auth == null || !auth.isLoggedIn.value) return true;
    final token = await auth.getIdToken();
    if (token == null || token.isEmpty) return true;

    final config = AppConfig.fromEnv();
    final baseUrl = config.baseUrl.replaceFirst(RegExp(r'/$'), '');
    final deviceId = await getOrCreateDeviceId();
    final api = DeviceApi(baseUrl: baseUrl, authToken: token);
    return api.logout(deviceId: deviceId);
  }

  /// Call from app init to listen for FCM token refresh; re-registers if user is logged in.
  void listenToTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((_) async {
      await registerDevice(requestPermissionIfNeeded: false);
    });
  }
}
