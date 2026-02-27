import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomNavBar extends StatefulWidget {
  final RxInt selectedIndex;
  final Function(int) onItemTapped;
  final List<String>? assetNames; // Allow overriding filenames to match user's assets
  final Map<int, IconData>? iconOverrides; // Map of index to IconData for items that should use Cupertino icons
  /// Optional badge count for the Profile tab (index 4). When > 0, shows a count on the icon.
  final int profileTabBadgeCount;

  const CustomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    this.assetNames,
    this.iconOverrides,
    this.profileTabBadgeCount = 0,
  });

  @override
  State<CustomNavBar> createState() => _CustomNavBarState();
}

class _CustomNavBarState extends State<CustomNavBar> {
  static const String _assetsBase = 'assets/tab-ic';
  static const List<String> _defaultIcons = <String>[
    'tab-home-ic.png',
    'tab-elocker-ic.png',
    'tab-shop-ic.png',
    'tab-streaming-ic.png',
    'tab-profile-ic.png',
  ];

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color iconColor = isDark ? Colors.white : Colors.black;
    final Color background = Theme.of(context).colorScheme.surface;

    return Material(
      color: background,
      elevation: 0,
      shadowColor: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Obx(() {
          final int current = widget.selectedIndex.value;
          // final List<String> icons = widget.assetNames ?? _defaultIcons;
          final List<String> icons =  _defaultIcons;

          return Container(
            padding: const EdgeInsets.only(top: 5, bottom: 0),
            decoration: BoxDecoration(
              color: background,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(icons.length, (int index) {
                final bool isSelected = current == index;
                final IconData? iconOverride = widget.iconOverrides?[index];
                
                return _NavItem(
                  assetPath: iconOverride == null ? '$_assetsBase/${icons[index]}' : null,
                  iconData: iconOverride,
                  isSelected: isSelected,
                  iconColor: iconColor,
                  badgeCount: index == 4 ? widget.profileTabBadgeCount : null,
                  onTap: () => widget.onItemTapped(index),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final String? assetPath;
  final IconData? iconData;
  final bool isSelected;
  final Color iconColor;
  final int? badgeCount;
  final VoidCallback onTap;

  const _NavItem({
    this.assetPath,
    this.iconData,
    required this.isSelected,
    required this.iconColor,
    this.badgeCount,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _pressed = false;

  void _handleHighlight(bool value) {
    setState(() {
      _pressed = value;
    });
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _handleTap,
      onHighlightChanged: _handleHighlight,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        // color: Colors.red,
        child: SizedBox(
          width: 64,
          height: 54,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedScale(
                      duration: const Duration(milliseconds: 120),
                      curve: Curves.easeOut,
                      scale: _pressed ? 0.92 : 1.0,
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: widget.iconData != null
                            ? Icon(
                                widget.iconData,
                                color: widget.isSelected
                                    ? const Color(0xFFFF7110)
                                    : widget.iconColor,
                                size: 24,
                              )
                            : ThemedAssetIcon(
                                assetPath: widget.assetPath!,
                                iconColor: widget.iconColor,
                                size: 24,
                              ),
                      ),
                    ),
                    if (widget.badgeCount != null && widget.badgeCount! > 0)
                      Positioned(
                        top: -4,
                        right: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          constraints: const BoxConstraints(minWidth: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF7110),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.badgeCount! > 99 ? '99+' : '${widget.badgeCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  height: 3,
                  width: widget.isSelected ? 24 : 0,
                  decoration: BoxDecoration(
                    color: widget.isSelected ? const Color(0xFFFF7110) : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ThemedAssetIcon extends StatelessWidget {
  final String assetPath;
  final Color iconColor;
  final double size;

  const ThemedAssetIcon({required this.assetPath, required this.iconColor, this.size = 28});

  @override
  Widget build(BuildContext context) {
    if (assetPath.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
      );
    }
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      color: iconColor,
      colorBlendMode: BlendMode.srcIn,
    );
  }
}


