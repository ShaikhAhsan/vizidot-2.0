import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  /// When set, shows "View All" on the right that navigates to [onViewAllTap].
  final VoidCallback? onViewAllTap;

  const SectionHeader({
    super.key,
    required this.title,
    this.onViewAllTap,
  });

  @override
  Widget build(BuildContext context) {
    if (onViewAllTap == null) {
      return Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 0,
            ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 0,
              ),
        ),
        CupertinoButton(
          padding: EdgeInsets.zero,
          minSize: 0,
          onPressed: onViewAllTap,
          child: Text(
            'View All',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Theme.of(context).textTheme.labelSmall?.color ??
                      Theme.of(context).colorScheme.onSurface,
                ),
          ),
        ),
      ],
    );
  }
}

