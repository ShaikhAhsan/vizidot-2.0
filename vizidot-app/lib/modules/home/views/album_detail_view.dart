import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/widgets/asset_or_network_image.dart';
import '../controllers/album_detail_controller.dart';
import '../widgets/section_header.dart';
import '../widgets/tracks_section.dart';
import '../widgets/videos_section.dart';
import 'video_web_view.dart';

class AlbumDetailView extends StatefulWidget {
  const AlbumDetailView({super.key});

  @override
  State<AlbumDetailView> createState() => _AlbumDetailViewState();
}

class _AlbumDetailViewState extends State<AlbumDetailView> {
  Future<void> _shareAlbum(String title) async {
    try {
      await Share.share(
        'Check out this album: $title\nhttps://vizidot.app/album/${title.toLowerCase().replaceAll(' ', '-')}',
        subject: title,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share: $e'), duration: const Duration(seconds: 2)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildFromController(context);
  }

  Widget _buildFromController(BuildContext context) {
    final controller = Get.find<AlbumDetailController>();
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Obx(() {
      if (controller.isLoading.value) {
        return CupertinoPageScaffold(
          child: CustomScrollView(
            slivers: [
              _navBar(context, title: 'Album'),
              const SliverFillRemaining(
                child: Center(child: CupertinoActivityIndicator()),
              ),
            ],
          ),
        );
      }
      if (controller.errorMessage.value.isNotEmpty) {
        return CupertinoPageScaffold(
          child: CustomScrollView(
            slivers: [
              _navBar(context, title: 'Album'),
              SliverFillRemaining(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        controller.errorMessage.value,
                        textAlign: TextAlign.center,
                        style: textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      CupertinoButton.filled(
                        onPressed: controller.fetchAlbum,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }

      final album = controller.album!;
      final coverUrl = album.coverImageUrl ?? '';
      final title = album.title;
      final releaseYear = album.releaseYear;
      final trackCount = album.trackCount;
      final totalDuration = album.totalDurationFormatted ?? '';

      return CupertinoPageScaffold(
        child: CustomScrollView(
          slivers: [
            _navBar(context, title: 'Album'),
            SliverSafeArea(
              top: false,
              sliver: SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: assetOrNetworkImage(
                                src: coverUrl,
                                width: 86,
                                height: 86,
                                fit: BoxFit.cover,
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            // Positioned.fill(
                            //   child: Center(
                            //     child: Container(
                            //       width: 48,
                            //       height: 48,
                            //       decoration: BoxDecoration(
                            //         color: Colors.white.withOpacity(0.9),
                            //         shape: BoxShape.circle,
                            //       ),
                            //       child: Icon(
                            //         controller.isVideoAlbum
                            //             ? CupertinoIcons.play_fill
                            //             : CupertinoIcons.play_fill,
                            //         color: Colors.black,
                            //         size: 24,
                            //       ),
                            //     ),
                            //   ),
                            // ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '${controller.isVideoAlbum ? "Video" : "Album"} / ${releaseYear ?? "—"}',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colors.onSurface.withOpacity(0.6),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '$trackCount ${trackCount == 1 ? "Track" : "Tracks"}${totalDuration.isNotEmpty ? " · $totalDuration" : ""}',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colors.onSurface.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          children: [
                            Obx(() {
                              final loading = controller.isFavouriteLoading.value;
                              final fav = controller.isFavourite.value;
                              return CupertinoButton(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                onPressed: loading ? null : () => controller.toggleFavourite(),
                                child: loading
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: const CupertinoActivityIndicator(),
                                      )
                                    : Icon(
                                        fav ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                                        color: fav ? Colors.red : colors.onSurface,
                                        size: 20,
                                      ),
                              );
                            }),
                            // const SizedBox(height: 40),
                            // GestureDetector(
                            //   onTap: () => _shareAlbum(title),
                            //   child: Icon(
                            //     CupertinoIcons.share,
                            //     color: colors.onSurface,
                            //     size: 20,
                            //   ),
                            // ),
                          ],
                        ),
                      ],
                    ),
                    // const SizedBox(height: 20),
                    // const SectionHeader(title: 'TRACK LIST'),
                    // const SizedBox(height: 16),
                  ]),
                ),
              ),
            ),
            if (controller.isVideoAlbum)
              SliverSafeArea(
                top: false,
                sliver: SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  sliver: SliverToBoxAdapter(
                    child: VideosSection(
                      videos: controller.videoItems,
                      onVideoTap: (video) {
                        if (video.videoUrl.isNotEmpty) {
                          Get.to(() => VideoWebView(url: video.videoUrl));
                        }
                      },
                    ),
                  ),
                ),
              )
            else
              SliverSafeArea(
                top: false,
                sliver: SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  sliver: SliverToBoxAdapter(
                    child: TracksSection(
                      tracks: controller.trackItems,
                      onTrackTap: () {},
                    ),
                  ),
                ),
              ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
          ],
        ),
      );
    });
  }

  Widget _navBar(BuildContext context, {String title = 'Album'}) {
    final colors = Theme.of(context).colorScheme;
    return CupertinoSliverNavigationBar(
      largeTitle: Text(title),
      leading: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        onPressed: () => Get.back(),
        child: Container(
          width: 35,
          height: 35,
          decoration: const BoxDecoration(
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
      backgroundColor: Colors.transparent,
      border: null,
      automaticallyImplyTitle: false,
      automaticallyImplyLeading: false,
    );
  }

}
