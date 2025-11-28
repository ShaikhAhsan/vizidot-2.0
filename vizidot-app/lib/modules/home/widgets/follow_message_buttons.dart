import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class FollowMessageButtons extends StatelessWidget {
  final bool isFollowing;
  final VoidCallback? onFollowTap;
  final VoidCallback? onMessageTap;

  const FollowMessageButtons({
    super.key,
    this.isFollowing = false,
    this.onFollowTap,
    this.onMessageTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        children: [
          Expanded(
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: colors.onSurface,
              borderRadius: BorderRadius.circular(12),
              onPressed: onFollowTap,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isFollowing ? CupertinoIcons.check_mark_circled : CupertinoIcons.add_circled,
                    color: colors.surface,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isFollowing ? 'Following' : 'Follow',
                    style: textTheme.labelLarge?.copyWith(
                      color: colors.surface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
              onPressed: onMessageTap,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.chat_bubble_2,
                    color: colors.onSurface,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Message',
                    style: textTheme.labelLarge?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

