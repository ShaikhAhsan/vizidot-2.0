import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'dart:ui';

class PlaylistDetailView extends StatefulWidget {
  final String playlistName;
  final String playlistImage;
  final String artistName;
  final int? likes;
  final String? duration;
  final List<PlaylistTrackItem> tracks;

  const PlaylistDetailView({
    super.key,
    required this.playlistName,
    required this.playlistImage,
    required this.artistName,
    this.likes,
    this.duration,
    required this.tracks,
  });

  @override
  State<PlaylistDetailView> createState() => _PlaylistDetailViewState();
}

class _PlaylistDetailViewState extends State<PlaylistDetailView> {
  bool _isLiked = false;
  bool _isDownloaded = false;
  int? _currentlyPlayingIndex;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          // Navigation Bar with Large Title - matching home screen
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Playlist page'),
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              onPressed: () => Get.back(),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  CupertinoIcons.arrow_left,
                  color: colors.onSurface,
                  size: 18,
                ),
              ),
            ),
            trailing: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(32, 32),
                onPressed: () {
                  // TODO: Show options menu
                },
                child: const Icon(
                  CupertinoIcons.ellipsis_vertical,
                  color: Colors.black,
                  size: 20,
                ),
              ),
            ),
            backgroundColor: Colors.transparent,
            border: null,
            automaticallyImplyTitle: false,
            automaticallyImplyLeading: false,
          ),
          // Now Playing Section with Blurred Background
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Blurred Background Image Container
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            widget.playlistImage,
                            fit: BoxFit.cover,
                          ),
                          // Blur effect
                          ClipRect(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                color: Colors.black.withOpacity(0.3),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Profile Picture - Cut in half circle, overlapping bottom
                  Positioned(
                    bottom: -50,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            widget.playlistImage,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Artist Info Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 60, bottom: 16),
              child: Column(
                children: [
                  // Artist Name
                  Text(
                    widget.artistName,
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Stats
                  Text(
                    '${_formatNumber(widget.likes ?? 1235)} likes / ${widget.duration ?? '1h25min'}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.onSurface.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Controls Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Like Button
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    onPressed: () {
                      setState(() {
                        _isLiked = !_isLiked;
                      });
                    },
                    child: Icon(
                      _isLiked ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                      color: _isLiked ? Colors.red : colors.onSurface,
                      size: 24,
                    ),
                  ),
                  // Download Button
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    onPressed: () {
                      setState(() {
                        _isDownloaded = !_isDownloaded;
                      });
                    },
                    child: Icon(
                      _isDownloaded ? CupertinoIcons.arrow_down_circle_fill : CupertinoIcons.arrow_down_circle,
                      color: colors.onSurface,
                      size: 24,
                    ),
                  ),
                  // Shuffle Button
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    onPressed: () {
                      // TODO: Shuffle playlist
                    },
                    child: Icon(
                      CupertinoIcons.shuffle,
                      color: colors.onSurface,
                      size: 24,
                    ),
                  ),
                  // Play Button
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    onPressed: () {
                      // TODO: Play playlist
                    },
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: colors.onSurface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.play_fill,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Playlist Items
          SliverSafeArea(
            top: false,
            sliver: SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final track = widget.tracks[index];
                    final isPlaying = _currentlyPlayingIndex == index;
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index < widget.tracks.length - 1 ? 16 : 0,
                      ),
                      child: Row(
                        children: [
                          // Album Art Thumbnail - Rounded Square
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              track.albumArt,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                            ),
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
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  track.artist,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colors.onSurface.withOpacity(0.6),
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          // Play/Skip buttons for currently playing track
                          if (isPlaying) ...[
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              onPressed: () {
                                setState(() {
                                  _currentlyPlayingIndex = null;
                                });
                              },
                              child: Icon(
                                CupertinoIcons.play_fill,
                                color: colors.onSurface,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              onPressed: () {
                                // TODO: Skip to next
                                if (index < widget.tracks.length - 1) {
                                  setState(() {
                                    _currentlyPlayingIndex = index + 1;
                                  });
                                }
                              },
                              child: Icon(
                                CupertinoIcons.forward_fill,
                                color: colors.onSurface,
                                size: 20,
                              ),
                            ),
                          ] else
                            // Menu dots
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              onPressed: () {
                                // TODO: Show track menu
                              },
                              child: Icon(
                                CupertinoIcons.ellipsis,
                                color: colors.onSurface.withOpacity(0.5),
                                size: 20,
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

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}k';
    }
    return number.toString();
  }
}

class PlaylistTrackItem {
  final String title;
  final String artist;
  final String albumArt;

  PlaylistTrackItem({
    required this.title,
    required this.artist,
    required this.albumArt,
  });
}

