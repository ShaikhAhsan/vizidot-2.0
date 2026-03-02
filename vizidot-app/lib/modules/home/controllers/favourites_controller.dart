import 'package:get/get.dart';

import '../../../core/network/apis/music_api.dart';
import '../../../core/utils/app_config.dart';
import '../../../core/utils/auth_service.dart';

class FavouritesController extends GetxController {
  static const int pageSize = 20;

  final RxString selectedType = 'track'.obs; // track | video | album | artist
  final RxList<Map<String, dynamic>> items = <Map<String, dynamic>>[].obs;
  final RxInt total = 0.obs;
  final RxInt totalTracks = 0.obs;
  final RxInt totalVideos = 0.obs;
  final RxInt totalAlbums = 0.obs;
  final RxInt totalArtists = 0.obs;
  final RxBool isLoading = false.obs;
  final RxBool hasMore = true.obs;
  final RxBool isLoadingTotals = true.obs;
  int _offset = 0;

  @override
  void onInit() {
    super.onInit();
    _loadTotalsThenPage();
  }

  /// Uses passed-in counts from Home (View All) when available; otherwise falls back to Home API. Then loads the selected tab's list.
  Future<void> _loadTotalsThenPage() async {
    if (!Get.isRegistered<AuthService>()) return;
    final auth = Get.find<AuthService>();
    final token = await auth.getIdToken();
    if (token == null || token.isEmpty) return;
    isLoadingTotals.value = true;
    try {
      final args = Get.arguments as Map<String, dynamic>?;
      if (args != null &&
          args.containsKey('totalTracks') &&
          args.containsKey('totalVideos') &&
          args.containsKey('totalAlbums')) {
        totalTracks.value = (args['totalTracks'] as num?)?.toInt() ?? 0;
        totalVideos.value = (args['totalVideos'] as num?)?.toInt() ?? 0;
        totalAlbums.value = (args['totalAlbums'] as num?)?.toInt() ?? 0;
        totalArtists.value = (args['totalArtists'] as num?)?.toInt() ?? 0;
        final initialTab = args['initialTab'] as String?;
        if (initialTab == 'artist' && totalArtists.value > 0) {
          selectedType.value = 'artist';
        }
      } else {
        final config = AppConfig.fromEnv();
        final api = MusicApi(baseUrl: config.baseUrl, authToken: token);
        final home = await api.getHomeTop(limit: 10);
        totalTracks.value = home?.favouriteAudios.length ?? 0;
        totalVideos.value = home?.favouriteVideos.length ?? 0;
        totalAlbums.value = home?.favouriteAlbums.length ?? 0;
        totalArtists.value = home?.favouriteArtists.length ?? 0;
      }
      final current = selectedType.value;
      if (current == 'track' && totalTracks.value == 0 ||
          current == 'video' && totalVideos.value == 0 ||
          current == 'album' && totalAlbums.value == 0 ||
          current == 'artist' && totalArtists.value == 0) {
        if (totalTracks.value > 0) {
          selectedType.value = 'track';
        } else if (totalVideos.value > 0) {
          selectedType.value = 'video';
        } else if (totalAlbums.value > 0) {
          selectedType.value = 'album';
        } else if (totalArtists.value > 0) {
          selectedType.value = 'artist';
        }
      }
    } catch (_) {}
    isLoadingTotals.value = false;
    loadPage();
  }

  Future<void> loadPage() async {
    if (!Get.isRegistered<AuthService>()) return;
    final auth = Get.find<AuthService>();
    final token = await auth.getIdToken();
    if (token == null || token.isEmpty) return;
    isLoading.value = true;
    try {
      final config = AppConfig.fromEnv();
      final api = MusicApi(baseUrl: config.baseUrl, authToken: token);
      if (selectedType.value == 'artist') {
        final res = await api.getFollowedArtists(limit: pageSize, offset: _offset);
        final artistMaps = res.artists.map((a) => <String, dynamic>{
          'artistId': a['artistId'],
          'name': a['name'],
          'imageUrl': a['imageUrl'],
        }).toList();
        items.addAll(artistMaps);
        total.value = res.total;
        hasMore.value = items.length < res.total;
        _offset += res.artists.length;
      } else {
        final res = await api.getFavourites(
          type: selectedType.value,
          limit: pageSize,
          offset: _offset,
          enrich: true,
        );
        items.addAll(res.favourites);
        total.value = res.total;
        hasMore.value = items.length < res.total;
        _offset += res.favourites.length;
      }
    } catch (_) {
      hasMore.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  void setType(String type) {
    if (selectedType.value == type) return;
    selectedType.value = type;
    items.clear();
    _offset = 0;
    hasMore.value = true;
    loadPage();
  }

  Future<void> loadMore() async {
    if (isLoading.value || !hasMore.value) return;
    await loadPage();
  }

  void refresh() {
    items.clear();
    _offset = 0;
    hasMore.value = true;
    _loadTotalsThenPage();
  }
}
