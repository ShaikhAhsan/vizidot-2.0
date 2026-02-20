import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../../../core/widgets/asset_or_network_image.dart';
import '../../../routes/app_pages.dart';
import '../../music_player/utils/play_track_helper.dart';
import '../../music_player/models/track_model.dart';
import 'section_header.dart';

class TracksSection extends StatelessWidget {
  final List<TrackItem> tracks;
  final VoidCallback? onTrackTap;

  const TracksSection({
    super.key,
    required this.tracks,
    this.onTrackTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: SectionHeader(title: 'TRACKS'),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: tracks.length,
          itemBuilder: (context, index) {
            final track = tracks[index];
            return GestureDetector(
              onTap: () {
                onTrackTap?.call();
                playTrack(
                  title: track.title,
                  artist: track.artist,
                  albumArt: track.albumArt,
                  duration: _parseDuration(track.duration),
                );
                Get.toNamed(AppRoutes.musicPlayer);
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    // Album Art with Play Button (asset path or network URL)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: assetOrNetworkImage(
                            src: track.albumArt,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        Positioned.fill(
                          child: Center(
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                CupertinoIcons.play_fill,
                                color: Colors.black,
                                size: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    // Track Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.title,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
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
                    // Duration
                    Text(
                      track.duration,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class TrackItem {
  final String title;
  final String artist;
  final String albumArt;
  final String duration;

  TrackItem({
    required this.title,
    required this.artist,
    required this.albumArt,
    required this.duration,
  });
}

Duration _parseDuration(String duration) {
  try {
    final parts = duration.split(':');
    if (parts.length == 2) {
      final minutes = int.parse(parts[0]);
      final seconds = int.parse(parts[1]);
      return Duration(minutes: minutes, seconds: seconds);
    }
  } catch (e) {
    // If parsing fails, return default duration
  }
  return const Duration(minutes: 3, seconds: 30);
}

