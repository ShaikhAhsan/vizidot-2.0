import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class SearchResultItem extends StatelessWidget {
  final String? imageUrl; // network URL or null for placeholder
  final String title;
  final String subtitle;
  final String? details;
  final VoidCallback? onTap;
  /// When true, show play button overlay (for tracks/videos). When false, no overlay (artist/album).
  final bool showPlayIcon;

  const SearchResultItem({
    super.key,
    this.imageUrl,
    required this.title,
    required this.subtitle,
    this.details,
    this.onTap,
    this.showPlayIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildImage(context, colors),
                ),
                if (showPlayIcon)
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        CupertinoIcons.play_fill,
                        color: Colors.black,
                        size: 14,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: colors.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurface.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                  if (details != null && details!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      details!,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context, ColorScheme colors) {
    if (imageUrl != null && imageUrl!.isNotEmpty && (imageUrl!.startsWith('http://') || imageUrl!.startsWith('https://'))) {
      return Image.network(
        imageUrl!,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(colors),
      );
    }
    return _placeholder(colors);
  }

  Widget _placeholder(ColorScheme colors) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: colors.onSurface.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        CupertinoIcons.music_note,
        color: colors.onSurface.withOpacity(0.3),
        size: 32,
      ),
    );
  }
}
