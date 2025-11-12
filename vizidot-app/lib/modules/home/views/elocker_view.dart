import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../controllers/elocker_controller.dart';

class ELockerView extends GetView<ELockerController> {
  const ELockerView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('E-locker'),
            centerTitle: false,
            titleSpacing: 0,
            floating: true,
            pinned: true,
            toolbarHeight: 44,
            expandedHeight: 96,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: 0,
                  onPressed: () {
                    // TODO: Implement search functionality
                  },
                  child: Icon(
                    CupertinoIcons.search,
                    color: colors.onSurface,
                    size: 20,
                  ),
                ),
              ),
            ],
            elevation: 0,
            backgroundColor: colors.surface,
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: const Text(
                'E-locker',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.37,
                ),
              ),
            ),
          ),
          SliverSafeArea(
            top: false,
            sliver: SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 8),
                  // FEATURED Section
                  _SectionHeader(
                    title: 'FEATURED',
                    onSeeAllTap: () {
                      // TODO: Navigate to see all featured
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 220,
                    child: Obx(() => ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.only(right: 4),
                          itemCount: controller.featuredArtists.length,
                          itemBuilder: (context, index) {
                            final artist = controller.featuredArtists[index];
                            return _FeaturedCard(
                              artist: artist,
                              index: index,
                              onBookmarkTap: () => controller.toggleBookmark(index),
                            );
                          },
                        )),
                  ),
                  const SizedBox(height: 32),
                  // RISING STARS Section
                  _SectionHeader(
                    title: 'RISING STARS',
                    onSeeAllTap: () {
                      // TODO: Navigate to see all rising stars
                    },
                  ),
                  const SizedBox(height: 16),
                  Obx(() => ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: controller.risingStars.length,
                        itemBuilder: (context, index) {
                          final artist = controller.risingStars[index];
                          return _RisingStarItem(
                            artist: artist,
                            index: index,
                            onBookmarkTap: () => controller.toggleBookmark(index, isRisingStar: true),
                          );
                        },
                      )),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAllTap;

  const _SectionHeader({
    required this.title,
    required this.onSeeAllTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
        ),
        TextButton(
          onPressed: onSeeAllTap,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'SEE ALL',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final Artist artist;
  final int index;
  final VoidCallback onBookmarkTap;

  const _FeaturedCard({
    required this.artist,
    required this.index,
    required this.onBookmarkTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: 160,
      margin: EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    artist.asset,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: GestureDetector(
                  onTap: onBookmarkTap,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      artist.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      size: 18,
                      color: colors.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            artist.name,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            artist.genre,
            style: textTheme.bodySmall?.copyWith(
              color: colors.onSurface.withOpacity(0.6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _RisingStarItem extends StatelessWidget {
  final Artist artist;
  final int index;
  final VoidCallback onBookmarkTap;

  const _RisingStarItem({
    required this.artist,
    required this.index,
    required this.onBookmarkTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: EdgeInsets.only(bottom: index == 0 ? 0 : 16),
      child: Row(
        children: [
          // Artist Image
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                artist.asset,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Artist Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  artist.name,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  artist.genre,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurface.withOpacity(0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Bookmark Icon
          GestureDetector(
            onTap: onBookmarkTap,
            child: Icon(
              artist.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              size: 24,
              color: colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

