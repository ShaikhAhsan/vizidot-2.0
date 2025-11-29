import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

enum SocialPlatform {
  spotify,
  soundcloud,
  apple,
  youtube,
}

class SocialProfileButton extends StatelessWidget {
  final SocialPlatform platform;
  final bool isSelected;
  final VoidCallback onTap;

  const SocialProfileButton({
    super.key,
    required this.platform,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    Color getBackgroundColor() {
      if (!isSelected) return Colors.white;
      switch (platform) {
        case SocialPlatform.spotify:
          return const Color(0xFF1DB954); // Spotify green
        case SocialPlatform.soundcloud:
          return const Color(0xFFFF7700); // SoundCloud orange
        case SocialPlatform.apple:
          return Colors.black;
        case SocialPlatform.youtube:
          return const Color(0xFFFF0000); // YouTube red
      }
    }

    IconData getIcon() {
      switch (platform) {
        case SocialPlatform.spotify:
          // Three horizontal curved lines
          return CupertinoIcons.music_note_list;
        case SocialPlatform.soundcloud:
          // Three vertical bars of increasing height
          return CupertinoIcons.bars;
        case SocialPlatform.apple:
          // Apple logo - using circle as representation
          return CupertinoIcons.circle_fill;
        case SocialPlatform.youtube:
          return CupertinoIcons.play_circle;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: getBackgroundColor(),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : colors.onSurface.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Icon(
          getIcon(),
          color: isSelected ? Colors.white : colors.onSurface.withOpacity(0.6),
          size: 24,
        ),
      ),
    );
  }
}

