import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../../core/utils/auth_service.dart';
import '../../../core/widgets/asset_or_network_image.dart';
import '../controllers/home_controller.dart';
import '../widgets/section_header.dart';
import '../widgets/media_card.dart';
import '../../../routes/app_pages.dart';
import 'playlist_detail_view.dart';

class HomeContentView extends GetView<HomeController> {
  const HomeContentView({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: <Widget>[
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Best of the week'),
            trailing: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(32, 32),
                onPressed: () {
                  // TODO: Show options menu
                },
                child: const Icon(
                  CupertinoIcons.ellipsis_vertical,
                  color: Colors.black,
                  size: 20,
                ),
              ),
            ),
            backgroundColor: Colors.transparent,
            border: null,
            automaticallyImplyTitle: false,
            automaticallyImplyLeading: false,
          ),
          Obx(() {
            if (controller.isLoadingTop.value) {
              return const SliverFillRemaining(
                child: Center(child: CupertinoActivityIndicator(radius: 14)),
              );
            }
            return SliverSafeArea(
              top: false,
              sliver: SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 12),
                    // Favourites section (when logged in)
                    Obx(() {
                      final isLoggedIn = Get.isRegistered<AuthService>() &&
                          Get.find<AuthService>().isLoggedIn.value;
                      if (!isLoggedIn) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionHeader(
                            title: 'FAVOURITES',
                            onViewAllTap: () => Get.toNamed(AppRoutes.favourites),
                          ),
                          // const SizedBox(height: 16),
                          if (controller.favouriteAudioItems.isNotEmpty)
                            SizedBox(
                              height: 178,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: controller.favouriteAudioItems.length,
                                itemBuilder: (context, index) {
                                  final item = controller.favouriteAudioItems[index];
                                  return MediaCard(
                                    title: item.title,
                                    artist: item.artist,
                                    asset: item.asset,
                                    isHorizontal: true,
                                    audioUrl: item.audioUrl,
                                    artistId: item.artistId,
                                    imageUrl: item.imageUrl,
                                    trackId: item.trackId,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(30),
                                      topRight: Radius.circular(12),
                                      bottomLeft: Radius.circular(12),
                                      bottomRight: Radius.circular(30),
                                    ),
                                  );
                                },
                              ),
                            ),
                          if (controller.favouriteVideoItems.isNotEmpty)
                            SizedBox(
                              height: 178,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: controller.favouriteVideoItems.length,
                                itemBuilder: (context, index) {
                                  final item = controller.favouriteVideoItems[index];
                                  final heights = [200.0, 280.0, 240.0, 220.0, 260.0, 230.0];
                                  return MediaCard(
                                    title: item.title,
                                    artist: item.artist,
                                    asset: item.asset,
                                    isHorizontal: true,
                                    imageHeight: heights[index % heights.length],
                                    artistId: item.artistId,
                                    imageUrl: item.imageUrl,
                                    videoUrl: item.videoUrl,
                                    videoId: item.videoId,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(30),
                                      topRight: Radius.circular(12),
                                      bottomLeft: Radius.circular(12),
                                      bottomRight: Radius.circular(30),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 20),
                          if (controller.favouriteAlbumItems.isNotEmpty)
                            SizedBox(
                              height: 140,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: controller.favouriteAlbumItems.length,
                                itemBuilder: (context, index) {
                                  final album = controller.favouriteAlbumItems[index];
                                  return GestureDetector(
                                    onTap: album.albumId != null
                                        ? () => Get.toNamed(
                                              AppRoutes.albumDetail,
                                              arguments: {'albumId': album.albumId},
                                            )
                                        : null,
                                    child: Container(
                                      width: 107,
                                      margin: const EdgeInsets.only(right: 16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          ClipRRect(
                                            borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(30),
                                              topRight: Radius.circular(12),
                                              bottomLeft: Radius.circular(12),
                                              bottomRight: Radius.circular(30),
                                            ),
                                            child: assetOrNetworkImage(
                                              src: album.imageUrl ?? '',
                                              width: 90,
                                              height: 90,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            album.title,
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            album.artist,
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  fontSize: 11,
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 10),
                        ],
                      );
                    }),
                    const SizedBox(height: 12),
                    // TOP AUDIO Section (from Home API)
                    const SectionHeader(title: 'TOP AUDIO'),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 178,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: controller.topAudioItems.length,
                        itemBuilder: (context, index) {
                          final item = controller.topAudioItems[index];
                          return MediaCard(
                            title: item.title,
                            artist: item.artist,
                            asset: item.asset,
                            isHorizontal: true,
                            audioUrl: item.audioUrl,
                            artistId: item.artistId,
                            imageUrl: item.imageUrl,
                            trackId: item.trackId,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(30),
                              topRight: Radius.circular(12),
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(30),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    // TOP VIDEO Section (from Home API)
                    const SectionHeader(title: 'TOP VIDEO'),
                    const SizedBox(height: 16),
                  ]),
                ),
              ),
            );
          }),
          Obx(() {
            if (controller.isLoadingTop.value) return const SliverToBoxAdapter(child: SizedBox.shrink());
            return SliverSafeArea(
              top: false,
              sliver: SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverMasonryGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  itemBuilder: (context, index) {
                    final item = controller.topVideoItems[index];
                    return MediaCard(
                      title: item.title,
                      artist: item.artist,
                      asset: item.asset,
                      isHorizontal: false,
                      imageHeight: item.imageHeight,
                      artistId: item.artistId,
                      imageUrl: item.imageUrl,
                      videoUrl: item.videoUrl,
                      videoId: item.videoId,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(15),
                        bottomLeft: Radius.circular(15),
                        bottomRight: Radius.circular(40),
                      ),
                      onTap: item.videoUrl == null || item.videoUrl!.isEmpty
                          ? () {
                              final playlistTracks = _generatePlaylistTracks(item);
                              Get.toNamed(
                                AppRoutes.playlistDetail,
                                arguments: {
                                  'playlistName': item.title,
                                  'playlistImage': item.imageUrl ?? item.asset,
                                  'artistName': item.artist,
                                  'likes': 1235,
                                  'duration': '1h25min',
                                  'tracks': playlistTracks,
                                },
                              );
                            }
                          : null,
                    );
                  },
                  childCount: controller.topVideoItems.length,
                ),
              ),
            );
          }),
          const SliverPadding(
            padding: EdgeInsets.only(bottom: 24),
          ),
        ],
      ),
    );
  }

  // Generate dummy playlist tracks for the video item
  List<PlaylistTrackItem> _generatePlaylistTracks(MediaItem videoItem) {
    // Available placeholder images
    final placeholderImages = [
      'assets/artists/Choc B.png',
      'assets/artists/Halsey.png',
      'assets/artists/Blair.png',
      'assets/artists/Aalyah.png',
      'assets/artists/Betty Daniels.png',
      'assets/artists/Jason Derulo.png',
      'assets/artists/Julia Styles.png',
      'assets/artists/Martina.png',
      'assets/artists/Travis.png',
    ];

    // Dummy track titles and artists
    final dummyTracks = [
      {'title': 'Need you now', 'artist': 'Joji'},
      {'title': 'Desert Rose', 'artist': 'TVORHI'},
      {'title': 'Best friend', 'artist': 'Luna bay'},
      {'title': 'Kalush Orcestra', 'artist': 'Kalush'},
      {'title': 'When the rain ends', 'artist': 'The Hardkiss'},
      {'title': 'Welcome to Ukraine', 'artist': 'Plumb'},
      {'title': 'Hail to the Victor', 'artist': '30 Seconds to Mars'},
      {'title': 'Midnight City', 'artist': 'M83'},
      {'title': 'Electric Feel', 'artist': 'MGMT'},
      {'title': 'Time to Dance', 'artist': 'The Sounds'},
    ];

    // Create playlist tracks with the video item as the first track
    final tracks = <PlaylistTrackItem>[
      PlaylistTrackItem(
        title: videoItem.title,
        artist: videoItem.artist,
        albumArt: videoItem.asset,
      ),
    ];

    // Add other dummy tracks
    for (int i = 0; i < dummyTracks.length && i < placeholderImages.length - 1; i++) {
      tracks.add(
        PlaylistTrackItem(
          title: dummyTracks[i]['title']!,
          artist: dummyTracks[i]['artist']!,
          albumArt: placeholderImages[(i + 1) % placeholderImages.length],
        ),
      );
    }

    return tracks;
  }
}

