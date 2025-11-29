import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class ProfileImageUpload extends StatelessWidget {
  final String imagePath;
  final VoidCallback? onTap;

  const ProfileImageUpload({
    super.key,
    required this.imagePath,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          // Profile Image
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              imagePath,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
            ),
          ),
          // Camera Icon Overlay
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
}

