import 'package:get/get.dart';

import '../../../core/network/apis/music_api.dart';
import '../../../core/utils/app_config.dart';
import '../../../data/models/album_detail_response.dart';
import '../widgets/albums_section.dart';
import '../widgets/tracks_section.dart';
import '../widgets/videos_section.dart';

/// Controller for album detail screen. Fetches album by id and exposes album + tracks (audio or video).
class AlbumDetailController extends GetxController {
  AlbumDetailController({required this.albumId});

  final int albumId;

  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;
  final Rxn<AlbumDetailResponse> detail = Rxn<AlbumDetailResponse>();

  AlbumDetailAlbum? get album => detail.value?.album;
  List<AlbumDetailTrack> get tracks => detail.value?.tracks ?? [];
  bool get isVideoAlbum => album?.isVideo ?? false;

  List<TrackItem> get trackItems {
    final name = album?.artistName ?? '';
    return tracks
        .map((t) => TrackItem(
              title: t.title,
              artist: name,
              albumArt: t.albumArt ?? '',
              duration: t.durationFormatted ?? '0:00',
            ))
        .toList();
  }

  List<VideoItem> get videoItems {
    final name = album?.artistName ?? '';
    return tracks
        .map((v) => VideoItem(
              title: v.title,
              artist: name,
              thumbnail: v.albumArt ?? '',
              duration: v.durationFormatted ?? '0:00',
              videoUrl: v.videoUrl ?? '',
            ))
        .toList();
  }

  @override
  void onReady() {
    fetchAlbum();
    super.onReady();
  }

  Future<void> fetchAlbum() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final config = AppConfig.fromEnv();
      final api = MusicApi(baseUrl: config.baseUrl);
      final result = await api.getAlbumDetail(albumId);
      if (result != null) {
        detail.value = result;
      } else {
        errorMessage.value = 'Could not load album';
      }
    } catch (e) {
      errorMessage.value = 'Something went wrong';
    } finally {
      isLoading.value = false;
    }
  }
}
