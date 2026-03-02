import 'package:flutter/material.dart';

enum ContentTab { music, video, about }

class ContentTabs extends StatelessWidget {
  final ContentTab selectedTab;
  final ValueChanged<ContentTab> onTabChanged;
  /// When false, the Video tab is hidden (e.g. when artist has no video albums or videos).
  final bool showVideoTab;

  const ContentTabs({
    super.key,
    required this.selectedTab,
    required this.onTabChanged,
    this.showVideoTab = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final tabs = <Widget>[
      Expanded(
        child: _TabButton(
          label: 'Music',
          icon: Icons.music_note,
          isSelected: selectedTab == ContentTab.music,
          onTap: () => onTabChanged(ContentTab.music),
          colors: colors,
          textTheme: textTheme,
        ),
      ),
      if (showVideoTab)
        Expanded(
          child: _TabButton(
            label: 'Video',
            icon: Icons.videocam,
            isSelected: selectedTab == ContentTab.video,
            onTap: () => onTabChanged(ContentTab.video),
            colors: colors,
            textTheme: textTheme,
          ),
        ),
      Expanded(
        child: _TabButton(
          label: 'About',
          icon: Icons.person,
          isSelected: selectedTab == ContentTab.about,
          onTap: () => onTabChanged(ContentTab.about),
          colors: colors,
          textTheme: textTheme,
        ),
      ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: tabs,
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colors;
  final TextTheme textTheme;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.colors,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? colors.onSurface : colors.onSurface.withOpacity(0.5),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: textTheme.labelMedium?.copyWith(
                  color: isSelected ? colors.onSurface : colors.onSurface.withOpacity(0.5),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 2,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isSelected ? colors.onSurface : Colors.transparent,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }
}

