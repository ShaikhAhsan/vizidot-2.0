import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Header with profile image, name, and caption/role. Image from [profileImageUrl] (network) or [fallbackAssetPath] (asset).
class ProfileHeader extends StatelessWidget {
  final String? profileImageUrl;
  final String? fallbackAssetPath;
  final String name;
  final String role;

  const ProfileHeader({
    super.key,
    this.profileImageUrl,
    this.fallbackAssetPath,
    required this.name,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final hasNetworkImage = profileImageUrl != null && profileImageUrl!.trim().isNotEmpty;

    return Center(
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(12),
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(30),
            ),
            child: hasNetworkImage
                ? CachedNetworkImage(
                    imageUrl: profileImageUrl!,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _placeholderBox(),
                    errorWidget: (_, __, ___) => _placeholderBox(),
                  )
                : fallbackAssetPath != null && fallbackAssetPath!.isNotEmpty
                    ? Image.asset(
                        fallbackAssetPath!,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                      )
                    : _placeholderBox(),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            role,
            style: textTheme.bodyMedium?.copyWith(
              color: colors.onSurface.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderBox() {
    return Container(
      width: 70,
      height: 70,
      color: Colors.grey.shade300,
      child: const Icon(Icons.person, size: 36, color: Colors.grey),
    );
  }
}
