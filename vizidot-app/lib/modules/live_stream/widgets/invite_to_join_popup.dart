import 'package:flutter/material.dart';

/// Shown to a viewer when the artist invites them to join the live stream.
/// Accept: [onAccept]. Decline: [onDecline].
class InviteToJoinPopup extends StatelessWidget {
  final String artistName;
  final String? artistPhotoUrl;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const InviteToJoinPopup({
    super.key,
    required this.artistName,
    this.artistPhotoUrl,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.black54,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 340),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 28),
                    Text(
                      'You\'re invited!',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '$artistName wants you to join the live stream',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ActionButton(
                          label: 'Decline',
                          onPressed: onDecline,
                          isPrimary: false,
                        ),
                        const SizedBox(width: 12),
                        _ActionButton(
                          label: 'Accept',
                          onPressed: onAccept,
                          isPrimary: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;

  const _ActionButton({
    required this.label,
    required this.onPressed,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: isPrimary ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: isPrimary ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
