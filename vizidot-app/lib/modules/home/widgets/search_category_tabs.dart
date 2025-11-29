import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

enum SearchCategory {
  bestResults,
  songs,
  playlists,
  albums,
  podcasts,
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
        children: [
          _CategoryTab(
            label: 'best results',
            isSelected: selectedCategory == SearchCategory.bestResults,
            onTap: () => onCategoryChanged(SearchCategory.bestResults),
          ),
          const SizedBox(width: 8),
          _CategoryTab(
            label: 'songs',
            isSelected: selectedCategory == SearchCategory.songs,
            onTap: () => onCategoryChanged(SearchCategory.songs),
          ),
          const SizedBox(width: 8),
          _CategoryTab(
            label: 'playlists',
            isSelected: selectedCategory == SearchCategory.playlists,
            onTap: () => onCategoryChanged(SearchCategory.playlists),
          ),
          const SizedBox(width: 8),
          _CategoryTab(
            label: 'albums',
            isSelected: selectedCategory == SearchCategory.albums,
            onTap: () => onCategoryChanged(SearchCategory.albums),
          ),
          const SizedBox(width: 8),
          _CategoryTab(
            label: 'podcasts',
            isSelected: selectedCategory == SearchCategory.podcasts,
            onTap: () => onCategoryChanged(SearchCategory.podcasts),
          ),
        ],
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

