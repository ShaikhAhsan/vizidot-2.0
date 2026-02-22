import 'package:get/get.dart';

import '../network/apis/settings_api.dart';
import 'app_config.dart';
import 'auth_service.dart';

/// Singleton holding the current user profile. Fetched on splash when user is logged in.
/// Use across the app: Get.find<UserProfileService>().profile
class UserProfileService extends GetxService {
  final Rx<UserProfileData?> _profile = Rx<UserProfileData?>(null);

  /// Current profile, or null if not loaded or not logged in.
  UserProfileData? get profile => _profile.value;

  /// True if profile is loaded and user has completed onboarding.
  bool get isOnboarded => _profile.value?.isOnboarded ?? false;

  /// Fetches settings (including profile) and saves profile to this service.
  /// Returns the loaded profile, or null on failure.
  Future<UserProfileData?> loadFromApi() async {
    if (!Get.isRegistered<AuthService>()) return null;
    final auth = Get.find<AuthService>();
    if (!auth.isLoggedIn.value) {
      clearProfile();
      return null;
    }
    try {
      final token = await auth.getIdToken();
      final config = Get.isRegistered<AppConfig>() ? Get.find<AppConfig>() : AppConfig.fromEnv();
      final baseUrl = config.baseUrl.replaceFirst(RegExp(r'/$'), '');
      final api = SettingsApi(baseUrl: baseUrl, authToken: token);
      final response = await api.getSettings(useAuth: true);
      final p = response?.profile;
      _profile.value = p;
      return p;
    } catch (_) {
      _profile.value = null;
      return null;
    }
  }

  /// Clears the stored profile (e.g. on logout).
  void clearProfile() {
    _profile.value = null;
  }

  /// Updates the stored profile (e.g. after completing onboarding or editing profile).
  void setProfile(UserProfileData? p) {
    _profile.value = p;
  }
}
