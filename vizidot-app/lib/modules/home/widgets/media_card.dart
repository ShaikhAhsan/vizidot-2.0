import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import '../../../core/widgets/asset_or_network_image.dart';
import '../../music_player/utils/play_track_helper.dart';
import '../../music_player/utils/record_play_helper.dart';
import '../views/video_web_view.dart';

class MediaCard extends StatefulWidget {
  final String title;
  final String artist;
  final String asset;
  final bool isHorizontal;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;
  final double? imageHeight; // For dynamic heights in masonry grid
  final String? audioUrl; // Audio URL for playback
  final int? artistId; // When set, artist detail loads from API and follow works
  final String? imageUrl; // Network image URL (overrides asset when set)
  final int? trackId; // For play history (top audio)
  final String? videoUrl; // For video cards (top video)
  final int? videoId; // For play history (top video)

  const MediaCard({
    super.key,
    required this.title,
    required this.artist,
    required this.asset,
    this.isHorizontal = false,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.onTap,
    this.imageHeight,
    this.audioUrl,
    this.artistId,
    this.imageUrl,
    this.trackId,
    this.videoUrl,
    this.videoId,
  });

  @override
  State<MediaCard> createState() => _MediaCardState();
}

class _MediaCardState extends State<MediaCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _handleTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    final useNetworkImage = widget.imageUrl != null && widget.imageUrl!.isNotEmpty;
    final imageSrc = useNetworkImage ? widget.imageUrl! : widget.asset;
    final imageHeight = widget.imageHeight ?? 200.0;

    // Horizontal card must fit in ~174px: use smaller image so title + artist fit
    final horizontalImageHeight = 88.0;
    Widget imageWidget = ClipRRect(
      borderRadius: widget.borderRadius,
      child: widget.isHorizontal
          ? SizedBox(
              width: double.infinity,
              height: horizontalImageHeight,
              child: useNetworkImage
                  ? assetOrNetworkImage(
                      src: imageSrc,
                      width: double.infinity,
                      height: horizontalImageHeight,
                      fit: BoxFit.cover,
                      borderRadius: widget.borderRadius,
                    )
                  : Image.asset(
                      widget.asset,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: horizontalImageHeight,
                    ),
            )
          : SizedBox(
              width: double.infinity,
              height: imageHeight,
              child: useNetworkImage
                  ? assetOrNetworkImage(
                      src: imageSrc,
                      width: double.infinity,
                      height: imageHeight,
                      fit: BoxFit.cover,
                      borderRadius: widget.borderRadius,
                    )
                  : Image.asset(
                      widget.asset,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: imageHeight,
                    ),
            ),
    );

    Widget titleWidget = Text(
      widget.title,
      style: textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        fontSize: widget.isHorizontal ? 13 : 14,
      ),
      maxLines: widget.isHorizontal ? 1 : 2,
      overflow: TextOverflow.ellipsis,
    );

    Widget artistNameWidget = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Get.toNamed(
          AppRoutes.artistDetail,
          arguments: {
            if (widget.artistId != null) 'artistId': widget.artistId,
            'artistName': widget.artist,
            'artistImage': widget.imageUrl ?? widget.asset,
            'description': 'Artist / Musician / Writer',
            'followers': 321000,
            'following': 125,
          },
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 0.0),
        child: Text(
          widget.artist,
          style: textTheme.bodySmall?.copyWith(
            color: colors.onSurface.withOpacity(0.6),
            fontWeight: FontWeight.w800,
            fontSize: 10,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );

    Widget animatedImage = GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap:
          () async {

          print("widget.trackId  ${widget.videoUrl}");
          print("widget.trackId  ${widget.videoUrl}");

          if ( widget.trackId != null) {
            final played = await playTrack(
              title: widget.title,
              artist: widget.artist,
              albumArt: widget.imageUrl ?? widget.asset,
              audioUrl: widget.audioUrl,
              duration: const Duration(minutes: 3, seconds: 30),
            );
            recordPlayIfPossible('audio', widget.trackId!);
          }
        else if (widget.videoUrl != null && widget.videoUrl!.isNotEmpty) {
          if (widget.videoId != null) {
            recordPlayIfPossible('video', widget.videoId!);
          }
          Get.to(() => VideoWebView(url: widget.videoUrl!));
          return;
        } else {
            widget.onTap?.call();
          }
      },
      behavior: HitTestBehavior.deferToChild,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: imageWidget,
          );
        },
      ),
    );

    Widget animatedTitle = GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      behavior: HitTestBehavior.deferToChild,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: titleWidget,
          );
        },
      ),
    );

    Widget imageAndTitle = widget.isHorizontal
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              animatedImage,
              const SizedBox(height: 4),
              animatedTitle,
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              animatedImage,
              const SizedBox(height: 5),
              animatedTitle,
            ],
          );

    Widget cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: widget.isHorizontal ? MainAxisSize.min : MainAxisSize.max,
      children: [
        imageAndTitle,
        SizedBox(height: widget.isHorizontal ? 6 : 10),
        artistNameWidget,
      ],
    );

    Widget wrappedContent = widget.isHorizontal
        ? Container(
            width: 107,
            margin: const EdgeInsets.only(right: 16),
            child: cardContent,
          )
        : cardContent;

    return wrappedContent;
  }
}

