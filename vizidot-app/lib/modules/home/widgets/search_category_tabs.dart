import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// Search filter: All (default), Artists, Albums, Music, Videos. iOS-style.
enum SearchCategory {
  all,
  artists,
  albums,
  music,
  videos,
}

extension SearchCategoryX on SearchCategory {
  String get label {
    switch (this) {
      case SearchCategory.all:
        return 'All';
      case SearchCategory.artists:
        return 'Artists';
      case SearchCategory.albums:
        return 'Albums';
      case SearchCategory.music:
        return 'Music';
      case SearchCategory.videos:
        return 'Videos';
    }
  }

  String get apiType {
    switch (this) {
      case SearchCategory.all:
        return 'all';
      case SearchCategory.artists:
        return 'artists';
      case SearchCategory.albums:
        return 'albums';
      case SearchCategory.music:
        return 'music';
      case SearchCategory.videos:
        return 'videos';
    }
  }
}

class SearchCategoryTabs extends StatelessWidget {
  final SearchCategory selectedCategory;
  final ValueChanged<SearchCategory> onCategoryChanged;

  const SearchCategoryTabs({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: SearchCategory.values.map((cat) {
          final isSelected = selectedCategory == cat;
          return Padding(
            padding: EdgeInsets.only(right: cat == SearchCategory.videos ? 0 : 8),
            child: _CategoryTab(
              label: cat.label,
              isSelected: isSelected,
              onTap: () => onCategoryChanged(cat),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CategoryTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colors.onSurface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colors.onSurface.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : colors.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
