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

class FavouriteAlbumItem {
  final String title;
  final String artist;
  final String? imageUrl;
  final int? albumId;
  final int? artistId;

  FavouriteAlbumItem({
    required this.title,
    required this.artist,
    this.imageUrl,
    this.albumId,
    this.artistId,
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

  // Favourites (when logged in): top 10 per type
  final favouriteAudioItems = <MediaItem>[].obs;
  final favouriteVideoItems = <MediaItem>[].obs;
  final favouriteAlbumItems = <FavouriteAlbumItem>[].obs;
  final isLoadingFavourites = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadTopFromApi();
  }

  /// Load top audio and video from Home API (GET /api/v1/music/home). When logged in, favourites come from same response.
  Future<void> loadTopFromApi() async {
    isLoadingTop.value = true;
    topAudioItems.clear();
    topVideoItems.clear();
    favouriteAudioItems.clear();
    favouriteVideoItems.clear();
    favouriteAlbumItems.clear();
    try {
      final config = AppConfig.fromEnv();
      final token = Get.isRegistered<AuthService>()
          ? await Get.find<AuthService>().getIdToken()
          : null;
      final api = MusicApi(baseUrl: config.baseUrl, authToken: token);
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
        // Favourites from Home API (only when logged in)
        for (final m in home.favouriteAudios) {
          favouriteAudioItems.add(MediaItem(
            title: m['title'] as String? ?? '',
            artist: m['artistName'] as String? ?? '',
            asset: _placeholderAsset,
            imageUrl: m['albumArt'] as String?,
            audioUrl: m['audioUrl'] as String?,
            artistId: (m['artistId'] as num?)?.toInt(),
            trackId: (m['entityId'] as num?)?.toInt(),
          ));
        }
        final heights = [200.0, 280.0, 240.0, 220.0, 260.0, 230.0];
        for (var i = 0; i < home.favouriteVideos.length; i++) {
          final m = home.favouriteVideos[i];
          favouriteVideoItems.add(MediaItem(
            title: m['title'] as String? ?? '',
            artist: m['artistName'] as String? ?? '',
            asset: _placeholderAsset,
            imageHeight: heights[i % heights.length],
            imageUrl: m['albumArt'] as String?,
            videoUrl: m['videoUrl'] as String?,
            artistId: (m['artistId'] as num?)?.toInt(),
            videoId: (m['entityId'] as num?)?.toInt(),
          ));
        }
        for (final m in home.favouriteAlbums) {
          favouriteAlbumItems.add(FavouriteAlbumItem(
            title: m['title'] as String? ?? '',
            artist: m['artistName'] as String? ?? '',
            imageUrl: m['albumArt'] as String?,
            albumId: (m['entityId'] as num?)?.toInt(),
            artistId: (m['artistId'] as num?)?.toInt(),
          ));
        }
      }
    } catch (_) {
      // Leave lists empty on error
    } finally {
      isLoadingTop.value = false;
    }
  }

  /// Load top 10 favourites per type (audio, video, album) when user is logged in.
  Future<void> loadFavourites() async {
    if (!Get.isRegistered<AuthService>()) return;
    final auth = Get.find<AuthService>();
    final token = await auth.getIdToken();
    if (token == null || token.isEmpty) return;
    isLoadingFavourites.value = true;
    favouriteAudioItems.clear();
    favouriteVideoItems.clear();
    favouriteAlbumItems.clear();
    try {
      final config = AppConfig.fromEnv();
      final api = MusicApi(baseUrl: config.baseUrl, authToken: token);
      final heights = [200.0, 280.0, 240.0, 220.0, 260.0, 230.0];
      final audioRes = await api.getFavourites(type: 'track', limit: 10, enrich: true);
      final videoRes = await api.getFavourites(type: 'video', limit: 10, enrich: true);
      final albumRes = await api.getFavourites(type: 'album', limit: 10, enrich: true);
      for (final m in audioRes.favourites) {
        favouriteAudioItems.add(MediaItem(
          title: m['title'] as String? ?? '',
          artist: m['artistName'] as String? ?? '',
          asset: _placeholderAsset,
          imageUrl: m['albumArt'] as String?,
          audioUrl: m['audioUrl'] as String?,
          artistId: (m['artistId'] as num?)?.toInt(),
          trackId: (m['entityId'] as num?)?.toInt(),
        ));
      }
      for (var i = 0; i < videoRes.favourites.length; i++) {
        final m = videoRes.favourites[i];
        favouriteVideoItems.add(MediaItem(
          title: m['title'] as String? ?? '',
          artist: m['artistName'] as String? ?? '',
          asset: _placeholderAsset,
          imageHeight: heights[i % heights.length],
          imageUrl: m['albumArt'] as String?,
          videoUrl: m['videoUrl'] as String?,
          artistId: (m['artistId'] as num?)?.toInt(),
          videoId: (m['entityId'] as num?)?.toInt(),
        ));
      }
      for (final m in albumRes.favourites) {
        favouriteAlbumItems.add(FavouriteAlbumItem(
          title: m['title'] as String? ?? '',
          artist: m['artistName'] as String? ?? '',
          imageUrl: m['albumArt'] as String?,
          albumId: (m['entityId'] as num?)?.toInt(),
          artistId: (m['artistId'] as num?)?.toInt(),
        ));
      }
    } catch (_) {}
    isLoadingFavourites.value = false;
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


