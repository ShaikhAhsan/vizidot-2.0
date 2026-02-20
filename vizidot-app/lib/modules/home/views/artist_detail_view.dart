import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../../../core/widgets/asset_or_network_image.dart';
import '../controllers/artist_detail_controller.dart';
import '../widgets/follow_message_buttons.dart';
import '../widgets/content_tabs.dart';
import '../widgets/albums_section.dart';
import '../widgets/tracks_section.dart';
import '../widgets/videos_section.dart';
import '../../music_player/utils/record_play_helper.dart';
import 'shop_view.dart';
import 'video_web_view.dart';

class ArtistDetailView extends StatefulWidget {
  /// When set, profile is fetched from API (public artist profile endpoint).
  final int? artistId;
  final String artistName;
  final String artistImage;
  final String? description;
  final int? followers;
  final int? following;

  const ArtistDetailView({
    super.key,
    this.artistId,
    required this.artistName,
    required this.artistImage,
    this.description,
    this.followers,
    this.following,
  });

  @override
  State<ArtistDetailView> createState() => _ArtistDetailViewState();
}

class _ArtistDetailViewState extends State<ArtistDetailView> {
  bool _isFollowing = false;
  ContentTab _selectedTab = ContentTab.music;
  bool _bioExpanded = false;

  /// Dummy data when not loading from API
  final List<AlbumItem> _dummyAlbums = [
    AlbumItem(
      title: 'Beating on my heart',
      artist: 'Choc B',
      coverImage: 'assets/artists/Choc B.png',
    ),
    AlbumItem(
      title: 'Fear of the water',
      artist: 'Doja cat',
      coverImage: 'assets/artists/Halsey.png',
    ),
    AlbumItem(
      title: 'Girls just wanna have...',
      artist: 'Tigerclub',
      coverImage: 'assets/artists/Blair.png',
    ),
    AlbumItem(
      title: 'Stop beating on my heart',
      artist: 'Cindi lauper',
      coverImage: 'assets/artists/Aalyah.png',
    ),
  ];

  final List<TrackItem> _dummyTracks = [
    TrackItem(
      title: 'Best friend',
      artist: 'Luna bay',
      albumArt: 'assets/artists/Choc B.png',
      duration: '3:24',
    ),
    TrackItem(
      title: 'Odd one out',
      artist: 'Luna bay',
      albumArt: 'assets/artists/Halsey.png',
      duration: '3:24',
    ),
    TrackItem(
      title: 'Girls just wanna have fun',
      artist: 'Tigerclub',
      albumArt: 'assets/artists/Blair.png',
      duration: '3:24',
    ),
    TrackItem(
      title: 'Stop beating on my heart',
      artist: 'Cindi lauper',
      albumArt: 'assets/artists/Aalyah.png',
      duration: '3:24',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final navBarHeight = 44.0;

    final hasArtistId = widget.artistId != null;
    final controller = hasArtistId ? Get.find<ArtistDetailController>() : null;

    return CupertinoPageScaffold(
      child: hasArtistId && controller != null
          ? Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CupertinoActivityIndicator());
              }
              if (controller.errorMessage.value.isNotEmpty) {
                return Center(
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
                          onPressed: () => controller.fetchProfile(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return _buildContent(
                context,
                statusBarHeight,
                navBarHeight,
                artistName: controller.artistName,
                artistImage: controller.artistImage,
                description: controller.description,
                followers: controller.followers,
                following: controller.following,
                albums: controller.albums,
                tracks: controller.tracks,
                videoAlbums: controller.videoAlbums,
                videos: controller.videos,
                hasShop: controller.hasShop,
                shopUrl: controller.shopUrl,
                isFollowing: controller.isFollowing.value,
                isFollowLoading: controller.isFollowLoading.value,
                onFollowTap: controller.toggleFollow,
              );
            })
          : _buildContent(
              context,
              statusBarHeight,
              navBarHeight,
              artistName: widget.artistName,
              artistImage: widget.artistImage,
              description: widget.description,
              followers: widget.followers,
              following: widget.following,
              albums: _dummyAlbums,
              tracks: _dummyTracks,
              videoAlbums: [],
              videos: [],
              hasShop: false,
              shopUrl: null,
              isFollowing: _isFollowing,
              isFollowLoading: false,
              onFollowTap: () => setState(() => _isFollowing = !_isFollowing),
            ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    double statusBarHeight,
    double navBarHeight, {
    required String artistName,
    required String artistImage,
    required String? description,
    required int? followers,
    required int? following,
    required List<AlbumItem> albums,
    required List<TrackItem> tracks,
    required List<AlbumItem> videoAlbums,
    required List<VideoItem> videos,
    required bool hasShop,
    String? shopUrl,
    required bool isFollowing,
    required bool isFollowLoading,
    required VoidCallback onFollowTap,
  }) {
    final hasValidShop = shopUrl != null && shopUrl.trim().isNotEmpty;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return CustomScrollView(
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _CustomNavBarDelegate(
            statusBarHeight: statusBarHeight,
            navBarHeight: navBarHeight,
            onBack: () => Get.back(),
            colors: colors,
          ),
        ),
        SliverToBoxAdapter(
          child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: _StatItem(
                        value: _formatNumber(followers ?? 321000),
                        label: 'followers',
                        colors: colors,
                        textTheme: textTheme,
                      ),
                    ),
                    const SizedBox(width: 40),
                    Column(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: artistImage.isEmpty
                              ? const Icon(CupertinoIcons.person_fill)
                              : assetOrNetworkImage(
                                  src: artistImage,
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          artistName,
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                          textAlign: TextAlign.center,
                        ),

                      ],
                    ),
                    const SizedBox(width: 40),
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: _StatItem(
                        value: '${following ?? 125}',
                        label: 'following',
                        colors: colors,
                        textTheme: textTheme,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final bioText = description ?? 'Artist / Musician / Writer';
                    final bioStyle = textTheme.bodyMedium?.copyWith(
                      color: colors.onSurface.withOpacity(0.6),
                      fontSize: 13,
                    );
                    final painter = TextPainter(
                      text: TextSpan(text: bioText, style: bioStyle),
                      textDirection: TextDirection.ltr,
                      maxLines: 2,
                    )..layout(maxWidth: constraints.maxWidth - 20);
                    final exceedsTwoLines = painter.didExceedMaxLines;

                    return Container(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: exceedsTwoLines
                                ? () => setState(() => _bioExpanded = !_bioExpanded)
                                : null,
                            child: Text(
                              bioText,
                              style: bioStyle,
                              textAlign: TextAlign.center,
                              softWrap: true,
                              maxLines: _bioExpanded ? 50 : 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (exceedsTwoLines) ...[
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: () => setState(() => _bioExpanded = !_bioExpanded),
                              child: Text(
                                _bioExpanded ? 'Show less' : 'Read more',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
                FollowMessageButtons(
                  isFollowing: isFollowing,
                  isFollowLoading: isFollowLoading,
                  showShop: hasValidShop,
                  onFollowTap: onFollowTap,
                  onMessageTap: () {},
                  onShopTap: hasValidShop
                      ? () {
                          Get.to(() => ShopView(initialUrl: shopUrl!.trim()));
                        }
                      : null,
                ),
                ContentTabs(
                  selectedTab: _selectedTab,
                  onTabChanged: (tab) => setState(() => _selectedTab = tab),
                ),
                const SizedBox(height: 24),
                if (_selectedTab == ContentTab.music) ...[
                  AlbumsSection(albums: albums),
                  TracksSection(
                    tracks: tracks,
                    onTrackTap: () {},
                  ),
                ] else if (_selectedTab == ContentTab.video) ...[
                  AlbumsSection(albums: videoAlbums),
                  if (videos.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'No videos yet',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.onSurface.withOpacity(0.6),
                        ),
                      ),
                    )
                  else
                    VideosSection(
                      videos: videos,
                      onVideoTap: (video) {
                        if (video.videoUrl.isNotEmpty) {
                          if (video.videoId != null) {
                            recordPlayIfPossible('video', video.videoId!);
                          }
                          Get.to(() => VideoWebView(url: video.videoUrl));
                        }
                      },
                    ),
                ] else if (_selectedTab == ContentTab.about) ...[
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'About content coming soon',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}k';
    }
    return number.toString();
  }
}

class _CustomNavBarDelegate extends SliverPersistentHeaderDelegate {
  final double statusBarHeight;
  final double navBarHeight;
  final VoidCallback onBack;
  final ColorScheme colors;

  _CustomNavBarDelegate({
    required this.statusBarHeight,
    required this.navBarHeight,
    required this.onBack,
    required this.colors,
  });

  @override
  double get minExtent => statusBarHeight + navBarHeight;

  @override
  double get maxExtent => statusBarHeight + navBarHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      height: statusBarHeight + navBarHeight,
      padding: EdgeInsets.only(top: statusBarHeight),
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              onPressed: onBack,
              child: Container(
                width: 35,
                height: 35,
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
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              onPressed: () {
                // TODO: Show options menu
              },
              child: Container(
                width: 35,
                height: 35,
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
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_CustomNavBarDelegate oldDelegate) {
    return statusBarHeight != oldDelegate.statusBarHeight ||
        navBarHeight != oldDelegate.navBarHeight;
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final ColorScheme colors;
  final TextTheme textTheme;

  const _StatItem({
    required this.value,
    required this.label,
    required this.colors,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: colors.onSurface.withOpacity(0.6),
            fontSize: 11,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
