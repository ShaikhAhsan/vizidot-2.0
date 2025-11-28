import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

class ArtistDetailView extends StatelessWidget {
  final String artistName;
  final String artistImage;
  final String? description;
  final int? followers;
  final int? following;

  const ArtistDetailView({
    super.key,
    required this.artistName,
    required this.artistImage,
    this.description,
    this.followers,
    this.following,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final statusBarHeight = MediaQuery.of(context).padding.top;
    final navBarHeight = 44.0;

    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          // Custom Navigation Bar Sliver - Pinned at top
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
            child: Padding(
              padding: const EdgeInsets.only(
                top: 10,
                left: 10,
                right: 10,
              ),
              child: Column(
                children: [
                  // Statistics and Profile Picture Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Followers (Left)
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
                      // Profile Picture (Center)
                      Column(
                        children: [
                        Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(24), // smooth rounded edges
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          artistImage,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
              const SizedBox(height: 16),
                          // Artist Name
                          Text(
                            artistName,
                            style: textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          // Description
                          Text(
                            description ?? 'Artist / Musician / Writer',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colors.onSurface.withOpacity(0.6),
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      const SizedBox(width: 40),
                      // Following (Right)
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
                ],
              ),
            ),
          ),
        ],
      ),
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

