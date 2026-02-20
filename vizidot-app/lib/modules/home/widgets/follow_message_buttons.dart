import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class FollowMessageButtons extends StatelessWidget {
  final bool isFollowing;
  final bool isFollowLoading;
  final VoidCallback? onFollowTap;
  final VoidCallback? onMessageTap;
  final VoidCallback? onShopTap;
  /// When false, the Shop button is hidden (e.g. when artist has no shop from API).
  final bool showShop;

  const FollowMessageButtons({
    super.key,
    this.isFollowing = false,
    this.isFollowLoading = false,
    this.onFollowTap,
    this.onMessageTap,
    this.onShopTap,
    this.showShop = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final buttons = <Widget>[
      Expanded(
        child: CupertinoButton(
          padding: const EdgeInsets.symmetric(vertical: 12),
          color: isFollowing ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(12),
          onPressed: isFollowLoading ? null : onFollowTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isFollowLoading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CupertinoActivityIndicator(
                    color: isFollowing ? Colors.white : Colors.black,
                  ),
                )
              else
                Icon(
                  isFollowing ? CupertinoIcons.check_mark_circled : CupertinoIcons.add_circled,
                  color: isFollowing ? Colors.white : Colors.black,
                  size: 18,
                ),
              const SizedBox(width: 8),
              Text(
                isFollowLoading ? '...' : (isFollowing ? 'Following' : 'Follow'),
                style: textTheme.labelLarge?.copyWith(
                  color: isFollowing ? Colors.white : Colors.black,
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
    ];
    if (showShop) {
      buttons.add(const SizedBox(width: 12));
      buttons.add(
        Expanded(
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            onPressed: onShopTap,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.shopping_cart,
                  color: colors.onSurface,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Shop',
                  style: textTheme.labelLarge?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        children: buttons,
      ),
    );
  }
}

