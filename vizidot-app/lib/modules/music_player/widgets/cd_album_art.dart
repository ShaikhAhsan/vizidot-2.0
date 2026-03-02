import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:math' as math;
import '../../../core/widgets/asset_or_network_image.dart';

class CdAlbumArt extends StatefulWidget {
  final String imageUrl;
  final bool isPlaying;
  final double size;

  const CdAlbumArt({
    super.key,
    required this.imageUrl,
    required this.isPlaying,
    this.size = 280,
  });

  @override
  State<CdAlbumArt> createState() => _CdAlbumArtState();
}

class _CdAlbumArtState extends State<CdAlbumArt>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
    
    if (widget.isPlaying) {
      _rotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(CdAlbumArt oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _rotationController.repeat();
      } else {
        _rotationController.stop();
      }
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return Transform.rotate(
          angle: widget.isPlaying
              ? _rotationController.value * 2 * math.pi
              : 0,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer CD ring
                Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.black,
                      width: 1,
                    ),
                    gradient: RadialGradient(
                      colors: [
                        Colors.grey.shade300,
                        Colors.grey.shade400,
                        Colors.grey.shade500,
                      ],
                    ),
                  ),
                ),
                // Inner image area (asset or network)
                Container(
                  width: widget.size - 1,
                  height: widget.size - 1,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: ClipOval(
                    child: assetOrNetworkImage(
                      src: widget.imageUrl,
                      width: widget.size - 1,
                      height: widget.size - 1,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Center hole
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).scaffoldBackgroundColor,
                    border: Border.all(
                      color: Colors.black,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

