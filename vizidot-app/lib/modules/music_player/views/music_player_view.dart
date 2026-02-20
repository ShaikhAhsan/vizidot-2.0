import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import '../controllers/music_player_controller.dart';
import '../widgets/cd_album_art.dart';
import '../widgets/progress_bar.dart';

class MusicPlayerView extends StatelessWidget {
  const MusicPlayerView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MusicPlayerController>();
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Obx(() {
      final track = controller.currentTrack.value;
      if (track == null) {
        return CupertinoPageScaffold(
          child: Center(
            child: Text(
              'No track playing',
              style: textTheme.bodyLarge,
            ),
          ),
        );
      }

      final progress = controller.duration.value.inMilliseconds > 0
          ? controller.position.value.inMilliseconds / controller.duration.value.inMilliseconds
          : 0.0;

      return CupertinoPageScaffold(
        child: CustomScrollView(
          slivers: [
            // Navigation Bar
            CupertinoSliverNavigationBar(
              largeTitle: const SizedBox.shrink(),
              leading: CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                onPressed: () => Get.back(),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.arrow_left,
                    color: colors.onSurface,
                    size: 18,
                  ),
                ),
              ),
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                onPressed: () => _showMusicPlayerMenu(context, controller),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.ellipsis_vertical,
                    color: colors.onSurface,
                    size: 18,
                  ),
                ),
              ),
              backgroundColor: Colors.transparent,
              border: null,
              automaticallyImplyTitle: false,
              automaticallyImplyLeading: false,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // CD Album Art
                    CdAlbumArt(
                      imageUrl: track.albumArt,
                      isPlaying: controller.isPlaying.value,
                      size: 280,
                    ),
                    const SizedBox(height: 40),
                    // Song Title
                    Text(
                      track.title,
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: colors.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    // Artist Name
                    Text(
                      track.artist,
                      style: textTheme.bodyLarge?.copyWith(
                        color: colors.onSurface.withOpacity(0.6),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    // Progress Bar
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(controller.position.value),
                                style: textTheme.bodySmall?.copyWith(
                                  color: colors.onSurface.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                _formatDuration(controller.duration.value),
                                style: textTheme.bodySmall?.copyWith(
                                  color: colors.onSurface.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const MusicProgressBar(
                          height: 4,
                          borderRadius: 2,
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    // Playback Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Repeat Button
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          onPressed: () {
                            final modes = [LoopMode.off, LoopMode.one, LoopMode.all];
                            final currentIndex = modes.indexOf(controller.loopMode.value);
                            final nextIndex = (currentIndex + 1) % modes.length;
                            controller.setLoopMode(modes[nextIndex]);
                          },
                          child: Icon(
                            _getLoopIcon(controller.loopMode.value),
                            color: controller.loopMode.value != LoopMode.off
                                ? colors.primary
                                : colors.onSurface.withOpacity(0.6),
                            size: 24,
                          ),
                        ),
                        // Previous Track
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          onPressed: () => controller.seekToPrevious(),
                          child: Icon(
                            CupertinoIcons.backward_end_fill,
                            color: colors.onSurface,
                            size: 28,
                          ),
                        ),
                        // Rewind
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          onPressed: () {
                            final newPosition = controller.position.value - const Duration(seconds: 10);
                            controller.seek(newPosition < Duration.zero ? Duration.zero : newPosition);
                          },
                          child: Icon(
                            CupertinoIcons.gobackward_10,
                            color: colors.onSurface,
                            size: 28,
                          ),
                        ),
                        // Play/Pause Button
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(64, 64),
                          onPressed: () => controller.togglePlayPause(),
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: colors.onSurface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              controller.isPlaying.value
                                  ? CupertinoIcons.pause_fill
                                  : CupertinoIcons.play_fill,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                        // Fast Forward
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          onPressed: () {
                            final newPosition = controller.position.value + const Duration(seconds: 10);
                            if (newPosition > controller.duration.value) {
                              controller.seek(controller.duration.value);
                            } else {
                              controller.seek(newPosition);
                            }
                          },
                          child: Icon(
                            CupertinoIcons.goforward_10,
                            color: colors.onSurface,
                            size: 28,
                          ),
                        ),
                        // Next Track
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          onPressed: () => controller.seekToNext(),
                          child: Icon(
                            CupertinoIcons.forward_end_fill,
                            color: colors.onSurface,
                            size: 28,
                          ),
                        ),
                        // Menu
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          onPressed: () {
                            // TODO: Show menu
                          },
                          child: Icon(
                            CupertinoIcons.ellipsis,
                            color: colors.onSurface.withOpacity(0.6),
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    // Volume Control
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Icon(
                            controller.volume.value == 0
                                ? CupertinoIcons.speaker_slash
                                : controller.volume.value < 0.5
                                    ? CupertinoIcons.speaker_1
                                    : CupertinoIcons.speaker_2,
                            color: colors.onSurface.withOpacity(0.6),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CupertinoSlider(
                              value: controller.volume.value,
                              onChanged: (value) => controller.setVolume(value),
                              activeColor: colors.onSurface,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            CupertinoIcons.speaker_3,
                            color: colors.onSurface.withOpacity(0.6),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  void _showMusicPlayerMenu(BuildContext context, MusicPlayerController controller) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              controller.clear();
              Get.back();
            },
            child: const Text('Clear'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          isDefaultAction: true,
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  IconData _getLoopIcon(LoopMode mode) {
    switch (mode) {
      case LoopMode.one:
        return CupertinoIcons.repeat_1;
      case LoopMode.all:
        return CupertinoIcons.repeat;
      case LoopMode.off:
      default:
        return CupertinoIcons.repeat;
    }
  }
}

