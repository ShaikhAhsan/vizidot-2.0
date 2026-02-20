import 'package:get/get.dart';
import '../controllers/music_player_controller.dart';
import '../models/track_model.dart';

bool _trackHasSource(String? audioUrl, String? localPath) {
  return (audioUrl != null && audioUrl.isNotEmpty) ||
      (localPath != null && localPath.isNotEmpty);
}

/// Helper function to play a track from anywhere in the app.
/// Only adds to queue if the track has an [audioUrl] or [localPath]; otherwise shows an alert.
/// Returns true if the track was added/played, false if skipped (no source).
Future<bool> playTrack({
  required String title,
  required String artist,
  required String albumArt,
  String? audioUrl,
  String? localPath,
  Duration duration = const Duration(minutes: 3, seconds: 30),
  List<TrackModel>? queue,
}) async {
  if (!_trackHasSource(audioUrl, localPath)) {
    Get.snackbar(
      'Cannot play',
      'No audio source for this track.',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
    return false;
  }

  final controller = Get.find<MusicPlayerController>();

  final track = TrackModel(
    id: '${title}_$artist',
    title: title,
    artist: artist,
    albumArt: albumArt,
    audioUrl: audioUrl,
    localPath: localPath,
    duration: duration,
  );

  if (queue != null && queue.isNotEmpty) {
    final queueList = queue
        .where((t) => _trackHasSource(t.audioUrl, t.localPath))
        .map((t) => TrackModel(
              id: '${t.title}_${t.artist}',
              title: t.title,
              artist: t.artist,
              albumArt: t.albumArt,
              audioUrl: t.audioUrl,
              localPath: t.localPath,
              duration: t.duration,
            ))
        .toList();
    if (queueList.isEmpty) {
      Get.snackbar(
        'Cannot play',
        'No tracks with audio source in this list.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      return false;
    }
    final index = queueList.indexWhere((t) => t.id == track.id);
    controller.playTrack(track, queueList: queueList, index: index >= 0 ? index : 0);
  } else {
    controller.playTrack(track);
  }
  return true;
}

