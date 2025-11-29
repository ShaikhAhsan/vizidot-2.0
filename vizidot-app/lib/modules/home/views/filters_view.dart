import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../widgets/section_header.dart';
import '../widgets/genre_tag.dart';
import '../widgets/social_profile_button.dart';
import '../widgets/filter_toggle_item.dart';

class FiltersView extends StatefulWidget {
  const FiltersView({super.key});

  @override
  State<FiltersView> createState() => _FiltersViewState();
}

class _FiltersViewState extends State<FiltersView> {
  // Genres
  final Set<String> _selectedGenres = {'Hard rock'};
  final List<String> _genres = [
    'pop',
    'Reggae',
    'Hard rock',
    'indie',
    'metallica',
    'Hip hop',
    'Country',
    'Rhythm and blues',
  ];

  // Social Profiles
  final Set<SocialPlatform> _selectedPlatforms = {SocialPlatform.spotify};

  // Interactions
  bool _hasPreviousCollaborations = false;
  bool _activeInCommunity = true;

  void _toggleGenre(String genre) {
    setState(() {
      if (_selectedGenres.contains(genre)) {
        _selectedGenres.remove(genre);
      } else {
        _selectedGenres.add(genre);
      }
    });
  }

  void _togglePlatform(SocialPlatform platform) {
    setState(() {
      if (_selectedPlatforms.contains(platform)) {
        _selectedPlatforms.remove(platform);
      } else {
        _selectedPlatforms.add(platform);
      }
    });
  }

  void _resetFilters() {
    setState(() {
      _selectedGenres.clear();
      _selectedGenres.add('Hard rock');
      _selectedPlatforms.clear();
      _selectedPlatforms.add(SocialPlatform.spotify);
      _hasPreviousCollaborations = false;
      _activeInCommunity = true;
    });
  }

  void _applyFilters() {
    // TODO: Apply filters and return to search screen
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final statusBarHeight = MediaQuery.of(context).padding.top;
    final navBarHeight = 44.0;

    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          // Custom Navigation Bar Sliver - Pinned at top (like Artist Screen)
          SliverPersistentHeader(
            pinned: true,
            delegate: _CustomNavBarDelegate(
              statusBarHeight: statusBarHeight,
              navBarHeight: navBarHeight,
              onBack: () => Get.back(),
              onReset: _resetFilters,
              colors: colors,
              textTheme: textTheme,
            ),
          ),
          SliverSafeArea(
            top: false,
            sliver: SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 12),
                  // GENRES Section
                  const SectionHeader(title: 'GENRES'),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _genres.map((genre) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GenreTag(
                            label: genre,
                            isSelected: _selectedGenres.contains(genre),
                            onTap: () => _toggleGenre(genre),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // SOCIAL PROFILES Section
                  const SectionHeader(title: 'SOCIAL PROFILES'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      SocialProfileButton(
                        platform: SocialPlatform.spotify,
                        isSelected: _selectedPlatforms.contains(SocialPlatform.spotify),
                        onTap: () => _togglePlatform(SocialPlatform.spotify),
                      ),
                      const SizedBox(width: 12),
                      SocialProfileButton(
                        platform: SocialPlatform.soundcloud,
                        isSelected: _selectedPlatforms.contains(SocialPlatform.soundcloud),
                        onTap: () => _togglePlatform(SocialPlatform.soundcloud),
                      ),
                      const SizedBox(width: 12),
                      SocialProfileButton(
                        platform: SocialPlatform.apple,
                        isSelected: _selectedPlatforms.contains(SocialPlatform.apple),
                        onTap: () => _togglePlatform(SocialPlatform.apple),
                      ),
                      const SizedBox(width: 12),
                      SocialProfileButton(
                        platform: SocialPlatform.youtube,
                        isSelected: _selectedPlatforms.contains(SocialPlatform.youtube),
                        onTap: () => _togglePlatform(SocialPlatform.youtube),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // INTERACTIONS Section
                  const SectionHeader(title: 'INTERACTIONS'),
                  const SizedBox(height: 16),
                  FilterToggleItem(
                    icon: CupertinoIcons.square_grid_2x2,
                    title: 'Has previous collaborations',
                    value: _hasPreviousCollaborations,
                    onChanged: (value) {
                      setState(() {
                        _hasPreviousCollaborations = value;
                      });
                    },
                  ),
                  FilterToggleItem(
                    icon: CupertinoIcons.person_2,
                    title: 'Active in the community',
                    value: _activeInCommunity,
                    onChanged: (value) {
                      setState(() {
                        _activeInCommunity = value;
                      });
                    },
                  ),
                  const SizedBox(height: 40),
                  // Apply Filters Button
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      color: colors.onSurface,
                      onPressed: _applyFilters,
                      child: const Text(
                        'Apply filters',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
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

class _CustomNavBarDelegate extends SliverPersistentHeaderDelegate {
  final double statusBarHeight;
  final double navBarHeight;
  final VoidCallback onBack;
  final VoidCallback onReset;
  final ColorScheme colors;
  final TextTheme textTheme;

  _CustomNavBarDelegate({
    required this.statusBarHeight,
    required this.navBarHeight,
    required this.onBack,
    required this.onReset,
    required this.colors,
    required this.textTheme,
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
          // Title
          Text(
            'Filters',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: colors.onSurface,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              onPressed: onReset,
              child: Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CupertinoIcons.trash,
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

