import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class GenreTag extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const GenreTag({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colors.onSurface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colors.onSurface.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : colors.onSurface,
          ),
        ),
      ),
    );
  }
}

