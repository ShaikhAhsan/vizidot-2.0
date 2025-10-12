import 'package:flutter/material.dart';
import 'overlay_back_button.dart';

class BannerNavBar extends StatelessWidget {
  final String imageAsset;
  final bool showBack;
  final EdgeInsetsGeometry? margin;

  const BannerNavBar({
    super.key,
    required this.imageAsset,
    this.showBack = true,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final double top = MediaQuery.of(context).padding.top;
    return Container(
      height: 112,
      width: double.infinity,
      margin: margin,
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(top: top),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          if (showBack)
            Positioned(
              top: top + ((112 - top - 44) / 2),
              left: 16,
              child: const OverlayBackButton(),
            ),
        ],
      ),
    );
  }
}


