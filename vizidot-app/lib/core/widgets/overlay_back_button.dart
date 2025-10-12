import 'package:flutter/material.dart';

class OverlayBackButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const OverlayBackButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container
    (
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
        icon: Icon(Icons.arrow_back, color: colors.onSurface),
        splashRadius: 24,
      ),
    );
  }
}


