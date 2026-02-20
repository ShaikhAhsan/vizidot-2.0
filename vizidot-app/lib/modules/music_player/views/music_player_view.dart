import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import '../../../core/widgets/asset_or_network_image.dart';
import '../controllers/music_player_controller.dart';
import '../models/track_model.dart';
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
                        // Shuffle
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          onPressed: controller.queue.length > 1 ? () => controller.shuffleQueue() : null,
                          child: Icon(
                            CupertinoIcons.shuffle,
                            color: controller.isShuffled.value ? colors.primary : colors.onSurface.withOpacity(0.6),
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
                    const SizedBox(height: 32),
                    // Queue / Playlist
                    if (controller.queue.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Row(
                          children: [
                            Text(
                              'Queue (${controller.queue.length})',
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colors.onSurface.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 320),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: controller.queue.length,
                          itemBuilder: (context, index) {
                            final t = controller.queue[index];
                            final isCurrent = index == controller.currentIndex.value;
                            return _QueueTile(
                              track: t,
                              isCurrent: isCurrent,
                              onTap: () => controller.playTrackAtIndex(index),
                              onRemove: () => controller.removeFromQueue(index),
                            );
                          },
                        ),
                      ),
                    ],
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
      builder: (ctx) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              controller.shuffleQueue();
            },
            child: const Text('Shuffle queue'),
          ),
          if (controller.queue.isNotEmpty)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                controller.removeFromQueue(controller.currentIndex.value);
              },
              child: const Text('Remove current from queue'),
            ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              controller.clear();
              Get.back();
            },
            child: const Text('Clear queue & close', style: TextStyle(color: CupertinoColors.destructiveRed)),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
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

class _QueueTile extends StatelessWidget {
  final TrackModel track;
  final bool isCurrent;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _QueueTile({
    required this.track,
    required this.isCurrent,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: assetOrNetworkImage(
                src: track.albumArt,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    track.title,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                      color: isCurrent ? colors.primary : colors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    track.artist,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurface.withOpacity(0.6),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isCurrent)
              Icon(CupertinoIcons.play_fill, size: 16, color: colors.primary),
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              onPressed: onRemove,
              child: Icon(
                CupertinoIcons.xmark_circle_fill,
                size: 22,
                color: colors.onSurface.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

