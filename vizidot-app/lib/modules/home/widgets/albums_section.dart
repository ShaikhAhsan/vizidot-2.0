import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../../../core/widgets/asset_or_network_image.dart';
import '../../../routes/app_pages.dart';
import 'section_header.dart';
import 'tracks_section.dart';

class AlbumsSection extends StatelessWidget {
  final List<AlbumItem> albums;
  final Function(AlbumItem)? onAlbumTap;

  const AlbumsSection({
    super.key,
    required this.albums,
    this.onAlbumTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: SectionHeader(title: 'ALBUMS'),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 174, // Same height as TOP AUDIO section
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: albums.length,
            itemBuilder: (context, index) {
              final album = albums[index];
              final textTheme = Theme.of(context).textTheme;
              final colors = Theme.of(context).colorScheme;
              
              return GestureDetector(
                onTap: () {
                  if (onAlbumTap != null) {
                    onAlbumTap!(album);
                  } else if (album.id != null) {
                    Get.toNamed(
                      AppRoutes.albumDetail,
                      arguments: {'albumId': album.id},
                    );
                  }
                },
                child: Container(
                  width: 107, // Same width as TOP AUDIO MediaCard
                  margin: const EdgeInsets.only(right: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image - 90x90 (asset path or network URL)
                      assetOrNetworkImage(
                        src: album.coverImage,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                      const SizedBox(height: 5),
                      // Title
                      Text(
                        album.title,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      // Artist (Subtitle)
                      Text(
                        album.artist,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withOpacity(0.6),
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class AlbumItem {
  final int? id;
  final String title;
  final String artist;
  final String coverImage;

  AlbumItem({
    this.id,
    required this.title,
    required this.artist,
    required this.coverImage,
  });
}

