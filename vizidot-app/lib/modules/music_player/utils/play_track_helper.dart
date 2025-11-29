import 'package:get/get.dart';
import '../controllers/music_player_controller.dart';
import '../models/track_model.dart';

/// Helper function to play a track from anywhere in the app
Future<void> playTrack({
  required String title,
  required String artist,
  required String albumArt,
  String? audioUrl,
  String? localPath,
  Duration duration = const Duration(minutes: 3, seconds: 30),
  List<TrackModel>? queue,
}) async {
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
    final queueList = queue.map((t) => TrackModel(
      id: '${t.title}_${t.artist}',
      title: t.title,
      artist: t.artist,
      albumArt: t.albumArt,
      audioUrl: t.audioUrl,
      localPath: t.localPath,
      duration: t.duration,
    )).toList();
    
    final index = queueList.indexWhere((t) => t.id == track.id);
    await controller.playTrack(track, queueList: queueList, index: index >= 0 ? index : 0);
  } else {
    await controller.playTrack(track);
  }
}

