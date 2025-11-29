import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final String profileImage;
  final String name;
  final String role;

  const ProfileHeader({
    super.key,
    required this.profileImage,
    required this.name,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        children: [
          // Profile Image - using the same border radius design as other images
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(12),
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(30),
            ),
            child: Image.asset(
              profileImage,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),
          // Name
          Text(
            name,
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 6),
          // Role
          Text(
            role,
            style: textTheme.bodyMedium?.copyWith(
              color: colors.onSurface.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

