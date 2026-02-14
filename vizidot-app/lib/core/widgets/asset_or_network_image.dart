import 'package:flutter/material.dart';

import 'cached_image.dart';

/// Shows Image.asset when [src] is not a URL, otherwise CachedNetworkImage via [CachedImage].
Widget assetOrNetworkImage({
  required String src,
  required double width,
  required double height,
  BoxFit fit = BoxFit.cover,
  BorderRadius? borderRadius,
}) {
  final isNetwork = src.startsWith('http://') || src.startsWith('https://');
  if (isNetwork && src.isNotEmpty) {
    return CachedImage(
      imageUrl: src,
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius,
    );
  }
  if (src.isEmpty) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade300,
      child: const Icon(Icons.music_note),
    );
  }
  Widget image = Image.asset(
    src,
    width: width,
    height: height,
    fit: fit,
    errorBuilder: (_, __, ___) => Container(
      width: width,
      height: height,
      color: Colors.grey.shade300,
      child: const Icon(Icons.broken_image_outlined),
    ),
  );
  if (borderRadius != null) {
    return ClipRRect(borderRadius: borderRadius, child: image);
  }
  return image;
}
