import 'package:get/get.dart';

import '../../../core/network/apis/music_api.dart';
import '../../../core/utils/app_config.dart';

class ElockerArtist {
  final int id;
  final String name;
  final String genre;
  final String? imageUrl;

  ElockerArtist({
    required this.id,
    required this.name,
    this.genre = 'Artist',
    this.imageUrl,
  });
}

class ELockerController extends GetxController {
  final featuredArtists = <ElockerArtist>[].obs;
  final risingStars = <ElockerArtist>[].obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadElocker();
  }

  /// Fetches featured and rising star artists from GET /api/v1/music/elocker.
  Future<void> loadElocker() async {
    isLoading.value = true;
    try {
      final config = AppConfig.fromEnv();
      final api = MusicApi(baseUrl: config.baseUrl);
      final resp = await api.getElocker();
      if (resp != null) {
        featuredArtists.assignAll(
          resp.featuredArtists
              .map((a) => ElockerArtist(id: a.id, name: a.name, genre: 'Artist', imageUrl: a.imageUrl))
              .toList(),
        );
        risingStars.assignAll(
          resp.risingStarArtists
              .map((a) => ElockerArtist(id: a.id, name: a.name, genre: 'Artist', imageUrl: a.imageUrl))
              .toList(),
        );
      } else {
        featuredArtists.clear();
        risingStars.clear();
      }
    } catch (_) {
      featuredArtists.clear();
      risingStars.clear();
    } finally {
      isLoading.value = false;
    }
  }
}
