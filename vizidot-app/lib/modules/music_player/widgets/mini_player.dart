import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../controllers/music_player_controller.dart';
import '../widgets/progress_bar.dart';
import '../../../routes/app_pages.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MusicPlayerController>();
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Obx(() {
      if (controller.currentTrack.value == null) {
        return const SizedBox.shrink();
      }

      final track = controller.currentTrack.value!;
      final progress = controller.duration.value.inMilliseconds > 0
          ? controller.position.value.inMilliseconds / controller.duration.value.inMilliseconds
          : 0.0;

      return GestureDetector(
        onTap: () {
          Get.toNamed(AppRoutes.musicPlayer);
        },
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(
                color: colors.onSurface.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                // Album Art Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    track.albumArt,
                    width: 54,
                    height: 54,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 54,
                        height: 54,
                        color: colors.onSurface.withOpacity(0.1),
                        child: Icon(
                          CupertinoIcons.music_note,
                          color: colors.onSurface.withOpacity(0.3),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Song Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        track.title,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: colors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        track.artist,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withOpacity(0.6),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      // Progress Bar
                      Row(
                        children: [
                          Text(
                            _formatDuration(controller.position.value),
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.onSurface.withOpacity(0.5),
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: const MusicProgressBar(
                              height: 2,
                              borderRadius: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDuration(controller.duration.value),
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.onSurface.withOpacity(0.5),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Play/Pause Button
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  onPressed: () => controller.togglePlayPause(),
                  child: Icon(
                    controller.isPlaying.value
                        ? CupertinoIcons.pause_fill
                        : CupertinoIcons.play_fill,
                    color: colors.onSurface,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 8),
                // Next Button
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  onPressed: () => controller.seekToNext(),
                  child: Icon(
                    CupertinoIcons.forward_fill,
                    color: colors.onSurface,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

