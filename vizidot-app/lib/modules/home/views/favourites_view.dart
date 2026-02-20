import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../../../core/widgets/asset_or_network_image.dart';
import '../controllers/favourites_controller.dart';
import '../../../routes/app_pages.dart';
import 'video_web_view.dart';
import '../../music_player/utils/play_track_helper.dart';
import '../../music_player/utils/record_play_helper.dart';

class FavouritesView extends GetView<FavouritesController> {
  const FavouritesView({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Favourites'),
        previousPageTitle: 'Back',
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  _TabChip(
                    label: 'Audio',
                    isSelected: controller.selectedType.value == 'track',
                    onTap: () => controller.setType('track'),
                  ),
                  const SizedBox(width: 8),
                  _TabChip(
                    label: 'Video',
                    isSelected: controller.selectedType.value == 'video',
                    onTap: () => controller.setType('video'),
                  ),
                  const SizedBox(width: 8),
                  _TabChip(
                    label: 'Albums',
                    isSelected: controller.selectedType.value == 'album',
                    onTap: () => controller.setType('album'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value && controller.items.isEmpty) {
                  return const Center(child: CupertinoActivityIndicator());
                }
                if (controller.items.isEmpty) {
                  return Center(
                    child: Text(
                      'No favourites yet',
                      style: textTheme.bodyLarge?.copyWith(
                        color: colors.onSurface.withOpacity(0.6),
                      ),
                    ),
                  );
                }
                final type = controller.selectedType.value;
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: controller.items.length + (controller.hasMore.value ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= controller.items.length) {
                      controller.loadMore();
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CupertinoActivityIndicator()),
                      );
                    }
                    final item = controller.items[index];
                    if (type == 'album') {
                      return _AlbumTile(
                        title: item['title'] as String? ?? '',
                        artist: item['artistName'] as String? ?? '',
                        imageUrl: item['albumArt'] as String?,
                        albumId: (item['entityId'] as num?)?.toInt(),
                      );
                    }
                    if (type == 'video') {
                      return _VideoTile(
                        title: item['title'] as String? ?? '',
                        artist: item['artistName'] as String? ?? '',
                        imageUrl: item['albumArt'] as String?,
                        videoUrl: item['videoUrl'] as String?,
                        videoId: (item['entityId'] as num?)?.toInt(),
                      );
                    }
                    return _AudioTile(
                      title: item['title'] as String? ?? '',
                      artist: item['artistName'] as String? ?? '',
                      imageUrl: item['albumArt'] as String?,
                      audioUrl: item['audioUrl'] as String?,
                      trackId: (item['entityId'] as num?)?.toInt(),
                      artistId: (item['artistId'] as num?)?.toInt(),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isSelected ? colors.onPrimary : colors.onSurface,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _AlbumTile extends StatelessWidget {
  final String title;
  final String artist;
  final String? imageUrl;
  final int? albumId;

  const _AlbumTile({
    required this.title,
    required this.artist,
    this.imageUrl,
    this.albumId,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: albumId != null
            ? () => Get.toNamed(AppRoutes.albumDetail, arguments: {'albumId': albumId})
            : null,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: assetOrNetworkImage(
                src: imageUrl ?? '',
                width: 64,
                height: 64,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    artist,
                    style: textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoTile extends StatelessWidget {
  final String title;
  final String artist;
  final String? imageUrl;
  final String? videoUrl;
  final int? videoId;

  const _VideoTile({
    required this.title,
    required this.artist,
    this.imageUrl,
    this.videoUrl,
    this.videoId,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: (videoUrl != null && videoUrl!.isNotEmpty)
            ? () {
                if (videoId != null) recordPlayIfPossible('video', videoId!);
                Get.to(() => VideoWebView(url: videoUrl!));
              }
            : null,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: assetOrNetworkImage(
                src: imageUrl ?? '',
                width: 64,
                height: 64,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    artist,
                    style: textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (videoUrl != null && videoUrl!.isNotEmpty)
              const Icon(CupertinoIcons.play_circle_fill, size: 32),
          ],
        ),
      ),
    );
  }
}

class _AudioTile extends StatelessWidget {
  final String title;
  final String artist;
  final String? imageUrl;
  final String? audioUrl;
  final int? trackId;
  final int? artistId;

  const _AudioTile({
    required this.title,
    required this.artist,
    this.imageUrl,
    this.audioUrl,
    this.trackId,
    this.artistId,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () async {
          final played = await playTrack(
            title: title,
            artist: artist,
            albumArt: imageUrl ?? '',
            audioUrl: audioUrl,
            duration: const Duration(minutes: 3, seconds: 30),
          );
          if (played && trackId != null) recordPlayIfPossible('audio', trackId!);
        },
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: assetOrNetworkImage(
                src: imageUrl ?? '',
                width: 64,
                height: 64,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    artist,
                    style: textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(CupertinoIcons.play_circle_fill, size: 32),
          ],
        ),
      ),
    );
  }
}
