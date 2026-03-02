import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Displays profile image from [imageUrl] (network) or [fallbackAssetPath] (asset).
/// [onTap] e.g. to pick and upload new image.
class ProfileImageUpload extends StatelessWidget {
  final String? imageUrl;
  final String? fallbackAssetPath;
  final VoidCallback? onTap;

  const ProfileImageUpload({
    super.key,
    this.imageUrl,
    this.fallbackAssetPath,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasNetworkImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: hasNetworkImage
                ? CachedNetworkImage(
                    imageUrl: imageUrl!,
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
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.black.withOpacity(0.3),
              ),
              child: const Center(
                child: Icon(
                  CupertinoIcons.camera,
                  color: Colors.white,
                  size: 32,
                ),
              ),
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
      child: const Icon(CupertinoIcons.person_fill, size: 36, color: Colors.grey),
    );
  }
}
