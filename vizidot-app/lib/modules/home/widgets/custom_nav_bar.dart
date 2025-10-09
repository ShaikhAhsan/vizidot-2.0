import 'package:flutter/material.dart';
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
    'home.png',
    'elocker.png',
    'shop.png',
    'streaming.png',
    'profile.png',
  ];

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color iconColor = isDark ? Colors.white : Colors.black;

    return Material(
      color: Colors.white,
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.08),
      child: SafeArea(
        top: false,
        child: Obx(() {
          final int current = widget.selectedIndex.value;
          final List<String> icons = widget.assetNames ?? _defaultIcons;
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ],
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

class _NavItem extends StatelessWidget {
  final String assetPath;
  final bool isSelected;
  final Color iconColor;
  final VoidCallback onTap;

  const _NavItem({required this.assetPath, required this.isSelected, required this.iconColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 30,
              height: 30,
              child: SvgPicture.asset(
                assetPath,
                width: 28,
                height: 28,
                fit: BoxFit.contain,
                colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
              ),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeInOut,
              height: 3,
              width: 26,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFF7110) : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


