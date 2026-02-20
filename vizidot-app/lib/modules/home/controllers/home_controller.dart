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

  // TOP AUDIO items — loaded from play-history/top?type=audio, fallback to static if empty
  final topAudioItems = <MediaItem>[].obs;
  // TOP VIDEO items — loaded from play-history/top?type=video, fallback to static if empty
  final topVideoItems = <MediaItem>[].obs;

  static List<MediaItem> _defaultTopAudio() => [
        MediaItem(
          title: 'Beating on my heart',
          artist: 'Choc B',
          asset: _placeholderAsset,
          audioUrl: 'https://firebasestorage.googleapis.com/v0/b/vizidot-4b492.appspot.com/o/audio-tracks%2Faa29a735-082e-4518-aa20-d80290559c93-1763845362989.mp3?alt=media',
          artistId: 1,
        ),
        MediaItem(
          title: 'Fear of the water',
          artist: 'Doja cat',
          asset: 'assets/artists/Halsey.png',
          audioUrl: 'https://firebasestorage.googleapis.com/v0/b/vizidot-4b492.appspot.com/o/audio-tracks%2Faa29a735-082e-4518-aa20-d80290559c93-1763845362989.mp3?alt=media',
          artistId: 2,
        ),
        MediaItem(
          title: 'Girls just wanna have...',
          artist: 'Tigerclub',
          asset: 'assets/artists/Blair.png',
          audioUrl: 'https://firebasestorage.googleapis.com/v0/b/vizidot-4b492.appspot.com/o/audio-tracks%2Faa29a735-082e-4518-aa20-d80290559c93-1763845362989.mp3?alt=media',
          artistId: 3,
        ),
        MediaItem(
          title: 'Stop beating on my heart',
          artist: 'Cindi lauper',
          asset: 'assets/artists/Aalyah.png',
          audioUrl: 'https://firebasestorage.googleapis.com/v0/b/vizidot-4b492.appspot.com/o/audio-tracks%2Faa29a735-082e-4518-aa20-d80290559c93-1763845362989.mp3?alt=media',
          artistId: 4,
        ),
      ];

  static List<MediaItem> _defaultTopVideo() => [
        MediaItem(
          title: 'Stop beating on my heart',
          artist: 'Cindi lauper',
          asset: 'assets/artists/Aalyah.png',
          imageHeight: 200.0,
          artistId: 4,
        ),
        MediaItem(
          title: 'Girls just wanna have fun',
          artist: 'Cindi lauper',
          asset: 'assets/artists/Julia Styles.png',
          imageHeight: 280.0,
          artistId: 4,
        ),
        MediaItem(
          title: 'Beating on my heart',
          artist: 'Choc B',
          asset: 'assets/artists/Choc B.png',
          imageHeight: 240.0,
          artistId: 1,
        ),
        MediaItem(
          title: 'Fear of the water',
          artist: 'Doja cat',
          asset: 'assets/artists/Halsey.png',
          imageHeight: 220.0,
          artistId: 2,
        ),
        MediaItem(
          title: 'Best friend',
          artist: 'Luna bay',
          asset: 'assets/artists/Blair.png',
          imageHeight: 260.0,
          artistId: 3,
        ),
        MediaItem(
          title: 'Desert Rose',
          artist: 'TVORHI',
          asset: 'assets/artists/Betty Daniels.png',
          imageHeight: 230.0,
          artistId: 5,
        ),
      ];

  @override
  void onInit() {
    super.onInit();
    topAudioItems.assignAll(_defaultTopAudio());
    topVideoItems.assignAll(_defaultTopVideo());
    loadTopFromApi();
  }

  /// Load top audio and video from Home API (GET /api/v1/music/home); replace lists when we get data.
  Future<void> loadTopFromApi() async {
    try {
      final config = AppConfig.fromEnv();
      final api = MusicApi(baseUrl: config.baseUrl);
      final home = await api.getHomeTop(limit: 10);
      if (home == null) return;

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
    } catch (_) {
      // keep default lists
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


