import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import '../models/track_model.dart';

class MusicPlayerController extends GetxController {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Rx<TrackModel?> currentTrack = Rx<TrackModel?>(null);
  final RxList<TrackModel> queue = <TrackModel>[].obs;
  final RxInt currentIndex = 0.obs;
  final RxBool isPlaying = false.obs;
  final Rx<Duration> position = Duration.zero.obs;
  final Rx<Duration> duration = Duration.zero.obs;
  final RxDouble volume = 1.0.obs;
  final Rx<LoopMode> loopMode = LoopMode.off.obs;
  final RxBool isShuffled = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initAudioPlayer();
  }

  void _initAudioPlayer() {
    _audioPlayer.positionStream.listen((pos) {
      position.value = pos;
    });

    _audioPlayer.durationStream.listen((dur) {
      if (dur != null) {
        duration.value = dur;
      }
    });

    _audioPlayer.playerStateStream.listen((state) {
      isPlaying.value = state.playing;
      if (state.processingState == ProcessingState.completed) {
        _handleTrackEnd();
      }
    });

    _audioPlayer.currentIndexStream.listen((index) {
      if (index != null && queue.isNotEmpty) {
        currentIndex.value = index;
        updateCurrentTrack();
      }
    });

    _audioPlayer.volumeStream.listen((vol) {
      volume.value = vol;
    });

    _audioPlayer.loopModeStream.listen((mode) {
      loopMode.value = mode;
    });

    _audioPlayer.currentIndexStream.listen((index) {
      if (index != null && queue.isNotEmpty) {
        currentIndex.value = index;
        updateCurrentTrack();
      }
    });
  }

  /// Builds ConcatenatingAudioSource from current queue and sets it. [initialIndex] is the track to start from.
  Future<void> _rebuildPlaylistFromQueue(int initialIndex) async {
    if (queue.isEmpty) return;
    final playlist = ConcatenatingAudioSource(
      children: queue.map((t) => _trackToSource(t)).toList(),
    );
    await _audioPlayer.setAudioSource(playlist, initialIndex: initialIndex.clamp(0, queue.length - 1));
    currentIndex.value = initialIndex.clamp(0, queue.length - 1);
    updateCurrentTrack();
  }

  bool _trackHasSource(TrackModel t) {
    return (t.audioUrl != null && t.audioUrl!.isNotEmpty) ||
        (t.localPath != null && t.localPath!.isNotEmpty);
  }

  AudioSource _trackToSource(TrackModel t) {
    if (t.audioUrl != null && t.audioUrl!.isNotEmpty) {
      return AudioSource.uri(Uri.parse(t.audioUrl!));
    }
    if (t.localPath != null && t.localPath!.isNotEmpty) {
      return AudioSource.asset(t.localPath!);
    }
    throw ArgumentError('Track must have audioUrl or localPath');
  }

  /// Play a track: if [queueList] is provided, replace queue and play at [index]. Otherwise add [track] on top of queue and play it.
  Future<void> playTrack(TrackModel track, {List<TrackModel>? queueList, int? index}) async {
    try {
      if (queueList != null && queueList.isNotEmpty) {
        queue.assignAll(queueList);
        currentIndex.value = (index ?? 0).clamp(0, queue.length - 1);
        currentTrack.value = track;
        await _rebuildPlaylistFromQueue(currentIndex.value);
      } else {
        // Only add if track has a playable source
        if (!_trackHasSource(track)) return;
        // If track already in queue, move it to top; otherwise add on top
        final existingIndex = queue.indexWhere((t) => t.id == track.id);
        if (existingIndex >= 0) {
          queue.removeAt(existingIndex);
        }
        queue.insert(0, track);
        currentIndex.value = 0;
        currentTrack.value = track;
        await _rebuildPlaylistFromQueue(0);
      }
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Error playing track: $e');
    }
  }

  /// Play the track at [index] in the queue (same queue, switch to that track).
  Future<void> playTrackAtIndex(int index) async {
    if (index < 0 || index >= queue.length) return;
    currentIndex.value = index;
    currentTrack.value = queue[index];
    await _audioPlayer.seek(Duration.zero, index: index);
    await _audioPlayer.play();
  }

  /// Remove track at [index] from queue. Rebuilds playlist; if queue is empty, clears and stops.
  Future<void> removeFromQueue(int index) async {
    if (index < 0 || index >= queue.length) return;
    final wasCurrent = index == currentIndex.value;
    queue.removeAt(index);
    if (queue.isEmpty) {
      await clear();
      Get.back();
      return;
    }
    final newIndex = wasCurrent
        ? (index >= queue.length ? index - 1 : index).clamp(0, queue.length - 1)
        : (index < currentIndex.value ? currentIndex.value - 1 : currentIndex.value).clamp(0, queue.length - 1);
    currentIndex.value = newIndex;
    updateCurrentTrack();
    await _rebuildPlaylistFromQueue(newIndex);
    if (wasCurrent) await _audioPlayer.play();
  }

  /// Shuffle queue and continue from current track's new position.
  Future<void> shuffleQueue() async {
    if (queue.length < 2) return;
    isShuffled.value = true;
    final current = currentTrack.value;
    final list = queue.toList()..shuffle();
    queue.assignAll(list);
    var newIndex = list.indexWhere((t) => t.id == current?.id);
    if (newIndex < 0) newIndex = 0;
    currentIndex.value = newIndex;
    updateCurrentTrack();
    await _rebuildPlaylistFromQueue(newIndex);
    await _audioPlayer.play();
  }

  Future<void> play() async {
    await _audioPlayer.play();
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> togglePlayPause() async {
    if (isPlaying.value) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> seekToNext() async {
    if (currentIndex.value < queue.length - 1) {
      currentIndex.value++;
      await _audioPlayer.seekToNext();
    }
  }

  Future<void> seekToPrevious() async {
    if (position.value.inSeconds > 3) {
      // If more than 3 seconds into track, restart it
      await seek(Duration.zero);
    } else if (currentIndex.value > 0) {
      // Otherwise go to previous track
      currentIndex.value--;
      await _audioPlayer.seekToPrevious();
    }
  }

  Future<void> setVolume(double volume) async {
    await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
  }

  Future<void> setLoopMode(LoopMode mode) async {
    await _audioPlayer.setLoopMode(mode);
  }

  void toggleShuffle() {
    isShuffled.value = !isShuffled.value;
    shuffleQueue();
  }

  /// Stops playback and clears the queue. Call before dismissing the player.
  Future<void> clear() async {
    await _audioPlayer.stop();
    queue.clear();
    currentTrack.value = null;
    currentIndex.value = 0;
    position.value = Duration.zero;
    duration.value = Duration.zero;
  }

  void _handleTrackEnd() {
    if (loopMode.value == LoopMode.off && currentIndex.value < queue.length - 1) {
      seekToNext();
    }
  }

  void updateCurrentTrack() {
    if (queue.isNotEmpty && currentIndex.value < queue.length) {
      currentTrack.value = queue[currentIndex.value];
    }
  }

  @override
  void onClose() {
    _audioPlayer.dispose();
    super.onClose();
  }
}

