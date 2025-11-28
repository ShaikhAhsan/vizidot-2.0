import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/section_header.dart';
import '../widgets/tracks_section.dart';

class AlbumDetailView extends StatefulWidget {
  final String albumTitle;
  final String albumImage;
  final String? releaseYear;
  final int? songCount;
  final String? totalDuration;
  final List<TrackItem> tracks;

  const AlbumDetailView({
    super.key,
    required this.albumTitle,
    required this.albumImage,
    this.releaseYear,
    this.songCount,
    this.totalDuration,
    required this.tracks,
  });

  @override
  State<AlbumDetailView> createState() => _AlbumDetailViewState();
}

class _AlbumDetailViewState extends State<AlbumDetailView> {
  bool _isFavorite = false;

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  Future<void> _shareAlbum() async {
    try {
      final result = await Share.share(
        'Check out this album: ${widget.albumTitle}\nhttps://vizidot.app/album/${widget.albumTitle.toLowerCase().replaceAll(' ', '-')}',
        subject: widget.albumTitle,
      );
      
      if (result.status == ShareResultStatus.success) {
        debugPrint('Album shared successfully');
      } else if (result.status == ShareResultStatus.dismissed) {
        debugPrint('Share dialog dismissed');
      }
    } catch (e) {
      debugPrint('Error sharing album: $e');
      // Show error to user if needed
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share album: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          // Navigation Bar with Large Title
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Album'),
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              onPressed: () => Get.back(),
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
            backgroundColor: Colors.transparent,
            border: null,
            automaticallyImplyTitle: false,
            automaticallyImplyLeading: false,
          ),
          SliverSafeArea(
            top: false,
            sliver: SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 20),
                  // Album Info Section
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Album Art
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              widget.albumImage,
                              width: 86,
                              height: 86,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned.fill(
                            child: Center(
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  CupertinoIcons.play_fill,
                                  color: Colors.black,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                          // Album Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.albumTitle,
                                  style: textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Album / ${widget.releaseYear ?? '2021'}',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colors.onSurface.withOpacity(0.6),
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '${widget.songCount ?? 18} Songs - ${widget.totalDuration ?? '2h 20min'}',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colors.onSurface.withOpacity(0.6),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                      // Favorite and Share Icons
                      Column(
                        children: [
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            onPressed: _toggleFavorite,
                            child: Icon(
                              _isFavorite
                                  ? CupertinoIcons.heart_fill
                                  : CupertinoIcons.heart,
                              color: _isFavorite ? Colors.red : colors.onSurface,
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 40),
                          GestureDetector(
                            onTap: _shareAlbum,
                            child: Icon(
                              CupertinoIcons.share,
                              color: colors.onSurface,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Track List Section
                  const SectionHeader(title: 'TRACK LIST'),
                  // const SizedBox(height: 16),
                ]),
              ),
            ),
          ),
          // Track List with Images
          SliverSafeArea(
            top: false,
            sliver: SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final track = widget.tracks[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          // Album Art with Play Button
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  track.albumArt,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned.fill(
                                child: Center(
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      CupertinoIcons.play_fill,
                                      color: Colors.black,
                                      size: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          // Track Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  track.title,
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  track.artist,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colors.onSurface.withOpacity(0.6),
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          // Duration
                          Text(
                            track.duration,
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.onSurface.withOpacity(0.5),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: widget.tracks.length,
                ),
              ),
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.only(bottom: 24),
          ),
        ],
      ),
    );
  }
}

