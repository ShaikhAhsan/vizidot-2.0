import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomNavBar extends StatefulWidget {
  final RxInt selectedIndex;
  final Function(int) onItemTapped;
  final List<String>? assetNames; // Allow overriding filenames to match user's assets

  const CustomNavBar({super.key, required this.selectedIndex, required this.onItemTapped, this.assetNames});

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
                return _NavItem(
                  assetPath: '$_assetsBase/${icons[index]}',
                  isSelected: isSelected,
                  iconColor: iconColor,
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
  final String assetPath;
  final bool isSelected;
  final Color iconColor;
  final VoidCallback onTap;

  const _NavItem({required this.assetPath, required this.isSelected, required this.iconColor, required this.onTap});

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
                AnimatedScale(
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeOut,
                  scale: _pressed ? 0.92 : 1.0,
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: ThemedAssetIcon(
                      assetPath: widget.assetPath,
                      iconColor: widget.iconColor,
                      size: 24,
                    ),
                  ),
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


