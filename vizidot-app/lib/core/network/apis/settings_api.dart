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

  /// DELETE /api/v1/auth/account. Auth required. Deletes Firebase user and backend user.
  /// Returns true on success. On failure returns false; check [lastAccountDeleteError] for message.
  String? lastAccountDeleteError;

  Future<bool> deleteAccount() async {
    lastAccountDeleteError = null;
    try {
      final response = await execute(
        'DELETE',
        ApiConstants.accountDeletePath,
        visibility: ApiVisibility.private,
      );
      if (response.statusCode == 200) return true;
      final body = response.body;
      if (body.isNotEmpty) {
        try {
          final map = jsonDecode(body) as Map<String, dynamic>?;
          if (map != null && map['error'] != null) {
            lastAccountDeleteError = map['error'] as String?;
          }
        } catch (_) {}
      }
      lastAccountDeleteError ??= 'Could not delete account';
      return false;
    } catch (e) {
      lastAccountDeleteError = e.toString().replaceFirst(RegExp(r'^Exception: '), '');
      return false;
    }
  }

  /// PATCH /api/v1/settings. Auth required. Updates user settings (notifications, language, isOnboarded).
  Future<SettingsResponse?> updateSettings({
    bool? enableNotifications,
    bool? messageNotifications,
    String? language,
    bool? isOnboarded,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (enableNotifications != null) body['enableNotifications'] = enableNotifications;
      if (messageNotifications != null) body['messageNotifications'] = messageNotifications;
      if (language != null) body['language'] = language;
      if (isOnboarded != null) body['isOnboarded'] = isOnboarded;
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

/// Response from GET /api/v1/settings. [user] and [profile] null when not logged in.
class SettingsResponse {
  SettingsResponse({
    this.user,
    this.profile,
    required this.app,
  });
  final UserSettingsData? user;
  /// Current user profile (id, name, email, isOnboarded). Present when authenticated.
  final UserProfileData? profile;
  final AppSettingsData app;

  factory SettingsResponse.fromJson(Map<String, dynamic> json) {
    final userMap = json['user'] as Map<String, dynamic>?;
    final profileMap = json['profile'] as Map<String, dynamic>?;
    final appMap = json['app'] as Map<String, dynamic>? ?? {};
    return SettingsResponse(
      user: userMap != null ? UserSettingsData.fromJson(userMap) : null,
      profile: profileMap != null ? UserProfileData.fromJson(profileMap) : null,
      app: AppSettingsData.fromJson(appMap),
    );
  }
}

/// User profile from GET /api/v1/settings (data.profile). Use across the app via [UserProfileService].
class UserProfileData {
  UserProfileData({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.profileImageUrl,
    this.isOnboarded = false,
  });
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String? profileImageUrl;
  final bool isOnboarded;

  String get fullName => '$firstName $lastName'.trim();
  bool get hasImage => profileImageUrl != null && profileImageUrl!.isNotEmpty;

  UserProfileData copyWith({
    int? id,
    String? email,
    String? firstName,
    String? lastName,
    String? profileImageUrl,
    bool? isOnboarded,
  }) {
    return UserProfileData(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isOnboarded: isOnboarded ?? this.isOnboarded,
    );
  }

  factory UserProfileData.fromJson(Map<String, dynamic> json) {
    return UserProfileData(
      id: (json['id'] as num?)?.toInt() ?? 0,
      email: json['email'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      profileImageUrl: json['profileImageUrl'] as String?,
      isOnboarded: json['isOnboarded'] as bool? ?? false,
    );
  }
}

/// User part of settings (from API or after PATCH).
class UserSettingsData {
  UserSettingsData({
    this.enableNotifications = true,
    this.messageNotifications = false,
    this.language = 'en',
    this.isOnboarded = false,
  });
  final bool enableNotifications;
  final bool messageNotifications;
  final String language;
  /// True after user completed categories + artists onboarding; used to skip onboarding on next app open.
  final bool isOnboarded;

  factory UserSettingsData.fromJson(Map<String, dynamic> json) {
    return UserSettingsData(
      enableNotifications: json['enableNotifications'] as bool? ?? true,
      messageNotifications: json['messageNotifications'] as bool? ?? false,
      language: json['language'] as String? ?? 'en',
      isOnboarded: json['isOnboarded'] as bool? ?? false,
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
