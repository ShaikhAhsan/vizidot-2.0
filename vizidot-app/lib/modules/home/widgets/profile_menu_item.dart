import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const ProfileMenuItem({
    super.key,
    required this.icon,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            // Icon with outline style
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.onSurface,
                  width: 1.5,
                ),
              ),
              child: Icon(
                icon,
                size: 14,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(width: 16),
            // Title
            Expanded(
              child: Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ),
            // Chevron arrow
            Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: colors.onSurface.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }
}

