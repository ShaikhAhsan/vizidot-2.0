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
    loadFromSearch();
  }

  Future<void> loadFromSearch() async {
    isLoading.value = true;
    try {
      final config = AppConfig.fromEnv();
      final api = MusicApi(baseUrl: config.baseUrl);
      final resp = await api.search(q: '', type: 'artists', limit: 30);
      if (resp != null && resp.results.isNotEmpty) {
        final artists = resp.results
            .where((r) => r.type == 'artist')
            .map((r) => ElockerArtist(
                  id: r.id,
                  name: r.title,
                  genre: r.subtitle,
                  imageUrl: r.imageUrl,
                ))
            .toList();
        const featuredCount = 5;
        featuredArtists.assignAll(artists.take(featuredCount));
        risingStars.assignAll(artists.skip(featuredCount));
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
