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

  Future<void> playTrack(TrackModel track, {List<TrackModel>? queueList, int? index}) async {
    try {
      currentTrack.value = track;
      
      if (queueList != null && queueList.isNotEmpty) {
        queue.value = queueList;
        currentIndex.value = index ?? 0;
        
        // Create playlist
        final playlist = ConcatenatingAudioSource(
          children: queueList.map((t) {
            if (t.audioUrl != null) {
              return AudioSource.uri(Uri.parse(t.audioUrl!));
            } else if (t.localPath != null) {
              return AudioSource.asset(t.localPath!);
            } else {
              // Use dummy/placeholder - in real app, you'd have actual audio
              return AudioSource.uri(Uri.parse('https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'));
            }
          }).toList(),
        );
        
        await _audioPlayer.setAudioSource(playlist, initialIndex: currentIndex.value);
        updateCurrentTrack();
      } else {
        // Single track - create a queue with just this track
        queue.value = [track];
        currentIndex.value = 0;
        
        if (track.audioUrl != null) {
          await _audioPlayer.setUrl(track.audioUrl!);
        } else if (track.localPath != null) {
          await _audioPlayer.setAsset(track.localPath!);
        } else {
          // Dummy audio for demo
          await _audioPlayer.setUrl('https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3');
        }
      }
      
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Error playing track: $e');
    }
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
    // TODO: Implement shuffle logic
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

