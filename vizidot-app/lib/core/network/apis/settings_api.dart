import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api_client.dart';
import '../base_api.dart';
import '../../constants/api_constants.dart';

/// Settings API: load user + app settings, update user settings.
class SettingsApi extends BaseApi {
  SettingsApi({
    required super.baseUrl,
    super.authToken,
    super.timeout,
    super.debugPrintRequest,
  });

  /// GET /api/v1/settings. Auth optional (if provided, returns user settings too).
  /// Returns [SettingsResponse] with user toggles and app config (help URL, privacy URL, about text).
  Future<SettingsResponse?> getSettings({bool useAuth = true}) async {
    try {
      final response = await execute(
        'GET',
        ApiConstants.settingsPath,
        visibility: useAuth ? ApiVisibility.optional : ApiVisibility.public,
      );
      if (response.statusCode != 200) return null;
      final Map<String, dynamic>? data = _dataFromResponse(response);
      if (data == null) return null;
      return SettingsResponse.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  /// PATCH /api/v1/settings. Auth required. Updates user settings (notifications, language).
  Future<SettingsResponse?> updateSettings({
    bool? enableNotifications,
    bool? messageNotifications,
    String? language,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (enableNotifications != null) body['enableNotifications'] = enableNotifications;
      if (messageNotifications != null) body['messageNotifications'] = messageNotifications;
      if (language != null) body['language'] = language;
      final response = await execute(
        'PATCH',
        ApiConstants.settingsPath,
        body: body.isNotEmpty ? body : null,
        visibility: ApiVisibility.private,
      );
      if (response.statusCode != 200) return null;
      final Map<String, dynamic>? data = _dataFromResponse(response);
      if (data == null) return null;
      return SettingsResponse(
        user: UserSettingsData.fromJson(data),
        app: AppSettingsData(),
      );
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic>? _dataFromResponse(http.Response response) {
    final body = response.body;
    if (body.isEmpty) return null;
    try {
      final map = jsonDecode(body) as Map<String, dynamic>?;
      if (map == null) return null;
      final wrapped = ApiClient.parseResponse(response);
      if (wrapped.$2 != null && wrapped.$2 is Map<String, dynamic>) return wrapped.$2!;
      return map;
    } catch (_) {
      return null;
    }
  }
}

/// Response from GET /api/v1/settings. [user] null when not logged in.
class SettingsResponse {
  SettingsResponse({
    this.user,
    required this.app,
  });
  final UserSettingsData? user;
  final AppSettingsData app;

  factory SettingsResponse.fromJson(Map<String, dynamic> json) {
    final userMap = json['user'] as Map<String, dynamic>?;
    final appMap = json['app'] as Map<String, dynamic>? ?? {};
    return SettingsResponse(
      user: userMap != null ? UserSettingsData.fromJson(userMap) : null,
      app: AppSettingsData.fromJson(appMap),
    );
  }
}

/// User part of settings (from API or after PATCH).
class UserSettingsData {
  UserSettingsData({
    this.enableNotifications = true,
    this.messageNotifications = false,
    this.language = 'en',
  });
  final bool enableNotifications;
  final bool messageNotifications;
  final String language;

  factory UserSettingsData.fromJson(Map<String, dynamic> json) {
    return UserSettingsData(
      enableNotifications: json['enableNotifications'] as bool? ?? true,
      messageNotifications: json['messageNotifications'] as bool? ?? false,
      language: json['language'] as String? ?? 'en',
    );
  }
}

/// App-level config (help URL, privacy URL, about content, etc.).
class AppSettingsData {
  AppSettingsData({
    this.helpCenterUrl,
    this.privacyPolicyUrl,
    this.termsUrl,
    this.aboutText,
    this.appName,
    this.aboutTagline,
    this.aboutDescription,
    this.aboutVersion,
    this.aboutBuild,
    this.contactEmail,
    this.websiteUrl,
  });
  final String? helpCenterUrl;
  final String? privacyPolicyUrl;
  final String? termsUrl;
  final String? aboutText;
  final String? appName;
  final String? aboutTagline;
  final String? aboutDescription;
  final String? aboutVersion;
  final String? aboutBuild;
  final String? contactEmail;
  final String? websiteUrl;

  factory AppSettingsData.fromJson(Map<String, dynamic> json) {
    return AppSettingsData(
      helpCenterUrl: json['helpCenterUrl'] as String?,
      privacyPolicyUrl: json['privacyPolicyUrl'] as String?,
      termsUrl: json['termsUrl'] as String?,
      aboutText: json['aboutText'] as String?,
      appName: json['appName'] as String?,
      aboutTagline: json['aboutTagline'] as String?,
      aboutDescription: json['aboutDescription'] as String?,
      aboutVersion: json['aboutVersion'] as String?,
      aboutBuild: json['aboutBuild'] as String?,
      contactEmail: json['contactEmail'] as String?,
      websiteUrl: json['websiteUrl'] as String?,
    );
  }
}
