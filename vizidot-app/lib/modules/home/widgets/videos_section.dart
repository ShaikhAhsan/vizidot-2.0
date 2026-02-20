import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../core/widgets/asset_or_network_image.dart';
import 'section_header.dart';

class VideoItem {
  final String title;
  final String artist;
  final String thumbnail;
  final String duration;
  final String videoUrl;

  VideoItem({
    required this.title,
    required this.artist,
    required this.thumbnail,
    required this.duration,
    required this.videoUrl,
  });
}

class VideosSection extends StatelessWidget {
  final List<VideoItem> videos;
  final void Function(VideoItem video)? onVideoTap;

  const VideosSection({
    super.key,
    required this.videos,
    this.onVideoTap,
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
          child: SectionHeader(title: 'VIDEOS'),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: videos.length,
          itemBuilder: (context, index) {
            final video = videos[index];
            return GestureDetector(
              onTap: () => onVideoTap?.call(video),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: assetOrNetworkImage(
                            src: video.thumbnail,
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            video.title,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            video.artist,
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
                    Text(
                      video.duration,
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
