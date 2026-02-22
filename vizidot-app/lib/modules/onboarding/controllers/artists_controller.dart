import 'package:get/get.dart';

import '../../../core/network/apis/music_api.dart';
import '../../../core/network/apis/settings_api.dart';
import '../../../core/utils/app_config.dart';
import '../../../core/utils/auth_service.dart';
import '../../../core/utils/user_profile_service.dart';

class ArtistItem {
  final int id;
  final String name;
  final String? imageUrl;

  ArtistItem({required this.id, required this.name, this.imageUrl});
}

class ArtistsController extends GetxController {
  final items = <ArtistItem>[].obs;
  final isLoading = true.obs;
  final isSaving = false.obs;
  final hasMore = true.obs;
  final _offset = 0.obs;
  static const int _pageSize = 24;

  final selected = <int>{}.obs;

  bool get canContinue => selected.length >= 3;

  @override
  void onInit() {
    super.onInit();
    loadArtists();
  }

  Future<void> loadArtists() async {
    isLoading.value = true;
    _offset.value = 0;
    hasMore.value = true;
    try {
      final config = AppConfig.fromEnv();
      final api = MusicApi(baseUrl: config.baseUrl);
      final resp = await api.getArtists(limit: _pageSize, offset: 0);
      if (resp != null) {
        items.assignAll(
          resp.artists.map((a) => ArtistItem(id: a.id, name: a.name, imageUrl: a.imageUrl)),
        );
        _offset.value = resp.artists.length;
        hasMore.value = resp.artists.length >= _pageSize && (_offset.value < resp.total);
      } else {
        items.clear();
      }
    } catch (_) {
      items.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (!hasMore.value || isLoading.value) return;
    isLoading.value = true;
    try {
      final config = AppConfig.fromEnv();
      final api = MusicApi(baseUrl: config.baseUrl);
      final resp = await api.getArtists(limit: _pageSize, offset: _offset.value);
      if (resp != null && resp.artists.isNotEmpty) {
        items.addAll(
          resp.artists.map((a) => ArtistItem(id: a.id, name: a.name, imageUrl: a.imageUrl)),
        );
        _offset.value += resp.artists.length;
        hasMore.value = resp.artists.length >= _pageSize && (_offset.value < resp.total);
      } else {
        hasMore.value = false;
      }
    } catch (_) {
      hasMore.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  void toggleByIndex(int index) {
    if (index < 0 || index >= items.length) return;
    final id = items[index].id;
    if (selected.contains(id)) {
      selected.remove(id);
    } else {
      selected.add(id);
    }
    selected.refresh();
  }

  void toggle(int index) => toggleByIndex(index);

  /// Called when user taps Next. If logged in, saves selected artists (follow), marks onboarded, then navigates to home.
  Future<void> onContinue() async {
    if (!canContinue) return;
    final auth = Get.isRegistered<AuthService>() ? Get.find<AuthService>() : null;
    final loggedIn = auth?.isLoggedIn.value ?? false;
    isSaving.value = true;
    try {
      if (loggedIn) {
        final token = await auth?.getIdToken();
        final config = AppConfig.fromEnv();
        final baseUrl = config.baseUrl.replaceFirst(RegExp(r'/$'), '');
        final musicApi = MusicApi(baseUrl: baseUrl, authToken: token);
        await musicApi.saveSelectedArtists(selected.toList());
        final settingsApi = SettingsApi(baseUrl: baseUrl, authToken: token);
        await settingsApi.updateSettings(isOnboarded: true);
        if (Get.isRegistered<UserProfileService>()) {
          final p = Get.find<UserProfileService>().profile;
          if (p != null) {
            Get.find<UserProfileService>().setProfile(p.copyWith(isOnboarded: true));
          }
        }
      }
    } finally {
      isSaving.value = false;
    }
    Get.offAllNamed('/');
  }

  /// Called when user taps Skip. If logged in, marks onboarded so onboarding is not shown again.
  Future<void> onSkip() async {
    final auth = Get.isRegistered<AuthService>() ? Get.find<AuthService>() : null;
    if (auth?.isLoggedIn.value ?? false) {
      final token = await auth?.getIdToken();
      final config = AppConfig.fromEnv();
      final baseUrl = config.baseUrl.replaceFirst(RegExp(r'/$'), '');
      final api = SettingsApi(baseUrl: baseUrl, authToken: token);
      await api.updateSettings(isOnboarded: true);
      if (Get.isRegistered<UserProfileService>()) {
        final p = Get.find<UserProfileService>().profile;
        if (p != null) {
          Get.find<UserProfileService>().setProfile(p.copyWith(isOnboarded: true));
        }
      }
    }
    Get.offAllNamed('/');
  }
}
