import 'package:get/get.dart';

import '../../../core/network/apis/music_api.dart';
import '../../../core/utils/app_config.dart';
import '../../../core/utils/auth_service.dart';
import '../../../core/utils/image_cache.dart';

class MediaItem {
  final String title;
  final String artist;
  final String asset;
  final double? imageHeight; // For dynamic heights in masonry grid
  final String? audioUrl; // Audio URL for playback
  final int? artistId; // Optional: when set, artist detail uses API and follow works
  /// Network image URL (when set, displayed instead of [asset]).
  final String? imageUrl;
  /// Audio track id for play history (top audio from API).
  final int? trackId;
  /// Video URL and id for video cards (top video from API).
  final String? videoUrl;
  final int? videoId;

  MediaItem({
    required this.title,
    required this.artist,
    required this.asset,
    this.imageHeight,
    this.audioUrl,
    this.artistId,
    this.imageUrl,
    this.trackId,
    this.videoUrl,
    this.videoId,
  });
}

class HomeController extends GetxController {
  final RxInt counter = 0.obs;
  final RxInt selectedIndex = 0.obs;
  final List<String> _prefetchUrls = <String>[];

  static const String _placeholderAsset = 'assets/artists/Choc B.png';

  // TOP AUDIO items — from Home API only (no hardcoded fallback)
  final topAudioItems = <MediaItem>[].obs;
  // TOP VIDEO items — from Home API only (no hardcoded fallback)
  final topVideoItems = <MediaItem>[].obs;
  /// True while loading Home API.
  final isLoadingTop = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadTopFromApi();
  }

  /// Load top audio and video from Home API (GET /api/v1/music/home). Replaces lists with API data only.
  Future<void> loadTopFromApi() async {
    isLoadingTop.value = true;
    topAudioItems.clear();
    topVideoItems.clear();
    try {
      final config = AppConfig.fromEnv();
      final api = MusicApi(baseUrl: config.baseUrl);
      final home = await api.getHomeTop(limit: 10);

      if (home != null) {
        if (home.topAudios.isNotEmpty) {
          topAudioItems.assignAll(
            home.topAudios.map((m) {
              final title = m['title'] as String? ?? '';
              final artist = m['artistName'] as String? ?? '';
              return MediaItem(
                title: title,
                artist: artist,
                asset: _placeholderAsset,
                imageUrl: m['albumArt'] as String?,
                audioUrl: m['audioUrl'] as String?,
                artistId: (m['artistId'] as num?)?.toInt(),
                trackId: (m['id'] as num?)?.toInt(),
              );
            }),
          );
        }
        if (home.topVideos.isNotEmpty) {
          final heights = [200.0, 280.0, 240.0, 220.0, 260.0, 230.0];
          topVideoItems.assignAll(
            home.topVideos.asMap().entries.map((e) {
              final m = e.value;
              final i = e.key;
              final title = m['title'] as String? ?? '';
              final artist = m['artistName'] as String? ?? '';
              return MediaItem(
                title: title,
                artist: artist,
                asset: _placeholderAsset,
                imageHeight: heights[i % heights.length],
                imageUrl: m['albumArt'] as String?,
                videoUrl: m['videoUrl'] as String?,
                artistId: (m['artistId'] as num?)?.toInt(),
                videoId: (m['id'] as num?)?.toInt(),
              );
            }),
          );
        }
      }
    } catch (_) {
      // Leave lists empty on error
    } finally {
      isLoadingTop.value = false;
    }
  }

  void increment() {
    counter.value++;
  }

  void onNavTap(int index) {
    selectedIndex.value = index;
  }

  void setPrefetchUrls(List<String> urls) {
    _prefetchUrls
      ..clear()
      ..addAll(urls);
  }

  Future<void> prefetchImages() async {
    await AppImageCache.prefetchAll(_prefetchUrls);
  }
}


