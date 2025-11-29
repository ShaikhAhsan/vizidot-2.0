import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool? isToggle;
  final bool? toggleValue;
  final ValueChanged<bool>? onToggleChanged;
  final VoidCallback? onTap;
  final bool showArrow;
  final bool isDestructive;

  const SettingsItem({
    super.key,
    required this.icon,
    required this.title,
    this.isToggle,
    this.toggleValue,
    this.onToggleChanged,
    this.onTap,
    this.showArrow = true,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final itemColor = isDestructive ? Colors.red : colors.onSurface;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            // Icon
            Icon(
              icon,
              size: 24,
              color: itemColor,
            ),
            const SizedBox(width: 16),
            // Title
            Expanded(
              child: Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  color: itemColor,
                ),
              ),
            ),
            // Toggle or Arrow
            if (isToggle == true)
              CupertinoSwitch(
                value: toggleValue ?? false,
                onChanged: onToggleChanged,
                activeColor: colors.primary,
              )
            else if (showArrow)
              Icon(
                CupertinoIcons.chevron_right,
                size: 16,
                color: itemColor.withOpacity(0.3),
              ),
          ],
        ),
      ),
    );
  }
}

