import 'package:get/get.dart';
import '../../../core/utils/image_cache.dart';

class MediaItem {
  final String title;
  final String artist;
  final String asset;
  final double? imageHeight; // For dynamic heights in masonry grid
  final String? audioUrl; // Audio URL for playback

  MediaItem({
    required this.title,
    required this.artist,
    required this.asset,
    this.imageHeight,
    this.audioUrl,
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
      audioUrl: 'https://firebasestorage.googleapis.com/v0/b/vizidot-4b492.appspot.com/o/audio-tracks%2Faa29a735-082e-4518-aa20-d80290559c93-1763845362989.mp3?alt=media',
    ),
    MediaItem(
      title: 'Fear of the water',
      artist: 'Doja cat',
      asset: 'assets/artists/Halsey.png',
      audioUrl: 'https://firebasestorage.googleapis.com/v0/b/vizidot-4b492.appspot.com/o/audio-tracks%2Faa29a735-082e-4518-aa20-d80290559c93-1763845362989.mp3?alt=media',
    ),
    MediaItem(
      title: 'Girls just wanna have...',
      artist: 'Tigerclub',
      asset: 'assets/artists/Blair.png',
      audioUrl: 'https://firebasestorage.googleapis.com/v0/b/vizidot-4b492.appspot.com/o/audio-tracks%2Faa29a735-082e-4518-aa20-d80290559c93-1763845362989.mp3?alt=media',
    ),
    MediaItem(
      title: 'Stop beating on my heart',
      artist: 'Cindi lauper',
      asset: 'assets/artists/Aalyah.png',
      audioUrl: 'https://firebasestorage.googleapis.com/v0/b/vizidot-4b492.appspot.com/o/audio-tracks%2Faa29a735-082e-4518-aa20-d80290559c93-1763845362989.mp3?alt=media',
    ),
  ].obs;

  // TOP VIDEO items with dynamic heights
  final topVideoItems = <MediaItem>[
    MediaItem(
      title: 'Stop beating on my heart',
      artist: 'Cindi lauper',
      asset: 'assets/artists/Aalyah.png',
      imageHeight: 200.0,
    ),
    MediaItem(
      title: 'Girls just wanna have fun',
      artist: 'Cindi lauper',
      asset: 'assets/artists/Julia Styles.png',
      imageHeight: 280.0,
    ),
    MediaItem(
      title: 'Beating on my heart',
      artist: 'Choc B',
      asset: 'assets/artists/Choc B.png',
      imageHeight: 240.0,
    ),
    MediaItem(
      title: 'Fear of the water',
      artist: 'Doja cat',
      asset: 'assets/artists/Halsey.png',
      imageHeight: 220.0,
    ),
    MediaItem(
      title: 'Best friend',
      artist: 'Luna bay',
      asset: 'assets/artists/Blair.png',
      imageHeight: 260.0,
    ),
    MediaItem(
      title: 'Desert Rose',
      artist: 'TVORHI',
      asset: 'assets/artists/Betty Daniels.png',
      imageHeight: 230.0,
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


