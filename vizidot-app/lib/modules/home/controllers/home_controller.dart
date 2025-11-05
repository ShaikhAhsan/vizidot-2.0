import 'package:get/get.dart';
import '../../../core/utils/image_cache.dart';

class MediaItem {
  final String title;
  final String artist;
  final String asset;

  MediaItem({
    required this.title,
    required this.artist,
    required this.asset,
  });
}

class HomeController extends GetxController {
  final RxInt counter = 0.obs;
  final RxInt selectedIndex = 0.obs;
  final List<String> _prefetchUrls = <String>[];

  // TOP AUDIO items
  final topAudioItems = <MediaItem>[
    MediaItem(
      title: 'Beating on my heart',
      artist: 'Choc B',
      asset: 'assets/artists/Choc B.png',
    ),
    MediaItem(
      title: 'Fear of the water',
      artist: 'Doja cat',
      asset: 'assets/artists/Halsey.png',
    ),
    MediaItem(
      title: 'Girls just wanna have...',
      artist: 'Tigerclub',
      asset: 'assets/artists/Blair.png',
    ),
    MediaItem(
      title: 'Stop beating on my heart',
      artist: 'Cindi lauper',
      asset: 'assets/artists/Aalyah.png',
    ),
  ].obs;

  // TOP VIDEO items
  final topVideoItems = <MediaItem>[
    MediaItem(
      title: 'Stop beating on my heart',
      artist: 'Cindi lauper',
      asset: 'assets/artists/Aalyah.png',
    ),
    MediaItem(
      title: 'Girls just wanna have fun',
      artist: 'Cindi lauper',
      asset: 'assets/artists/Julia Styles.png',
    ),
    MediaItem(
      title: 'Beating on my heart',
      artist: 'Choc B',
      asset: 'assets/artists/Choc B.png',
    ),
    MediaItem(
      title: 'Fear of the water',
      artist: 'Doja cat',
      asset: 'assets/artists/Halsey.png',
    ),
  ].obs;

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


