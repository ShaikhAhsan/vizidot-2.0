import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

enum VisibilityOption {
  unlisted,
  private,
  public,
}

class VisibilitySelector extends StatelessWidget {
  final VisibilityOption selectedOption;
  final ValueChanged<VisibilityOption> onChanged;

  const VisibilitySelector({
    super.key,
    required this.selectedOption,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Visibility:',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _VisibilityButton(
              label: 'Unlisted',
              isSelected: selectedOption == VisibilityOption.unlisted,
              onTap: () => onChanged(VisibilityOption.unlisted),
            ),
            const SizedBox(width: 12),
            _VisibilityButton(
              label: 'Private',
              isSelected: selectedOption == VisibilityOption.private,
              onTap: () => onChanged(VisibilityOption.private),
            ),
            const SizedBox(width: 12),
            _VisibilityButton(
              label: 'Public',
              isSelected: selectedOption == VisibilityOption.public,
              onTap: () => onChanged(VisibilityOption.public),
            ),
          ],
        ),
      ],
    );
  }
}

class _VisibilityButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _VisibilityButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colors.onSurface.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
                color: colors.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

