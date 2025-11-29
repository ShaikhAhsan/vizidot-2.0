import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';

class MediaCard extends StatefulWidget {
  final String title;
  final String artist;
  final String asset;
  final bool isHorizontal;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;
  final double? imageHeight; // For dynamic heights in masonry grid

  const MediaCard({
    super.key,
    required this.title,
    required this.artist,
    required this.asset,
    this.isHorizontal = false,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.onTap,
    this.imageHeight,
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

    Widget imageWidget = ClipRRect(
      borderRadius: widget.borderRadius,
      child: widget.isHorizontal
          ? Image.asset(
              widget.asset,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 100,
            )
          : SizedBox(
              width: double.infinity,
              height: widget.imageHeight ?? 200,
              child: Image.asset(
                widget.asset,
                fit: BoxFit.cover,
                width: double.infinity,
                height: widget.imageHeight ?? 200,
              ),
            ),
    );

    Widget titleWidget = Text(
      widget.title,
      style: textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );

    Widget artistNameWidget = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Get.toNamed(
          AppRoutes.artistDetail,
          arguments: {
            'artistName': widget.artist,
            'artistImage': widget.asset,
            'description': 'Artist / Musician / Writer',
            'followers': 321000,
            'following': 125,
          },
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
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
      onTap: widget.onTap,
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
              const SizedBox(height: 5),
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
        const SizedBox(height: 10),
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

