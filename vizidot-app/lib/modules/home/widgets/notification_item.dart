import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class NotificationItem extends StatelessWidget {
  final String profileImage;
  final String notificationText;
  final String timestamp;
  final List<String> boldUsernames;

  const NotificationItem({
    super.key,
    required this.profileImage,
    required this.notificationText,
    required this.timestamp,
    this.boldUsernames = const [],
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile/Album Image
          ClipOval(
            child: Image.asset(
              profileImage,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colors.onSurface.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.person,
                    color: colors.onSurface.withOpacity(0.3),
                    size: 24,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          // Notification Text
          Expanded(
            child: _buildNotificationText(textTheme, colors),
          ),
          const SizedBox(width: 8),
          // Timestamp
          Text(
            timestamp,
            style: textTheme.bodySmall?.copyWith(
              color: colors.onSurface.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationText(TextTheme? textTheme, ColorScheme colors) {
    // Parse the notification text and make usernames bold
    // Usernames to make bold: any word that looks like a username (alphanumeric with underscores)
    // or words that start with @
    final parts = <TextSpan>[];
    
    // Pattern to match usernames: @username or standalone username (alphanumeric + underscore)
    // We'll match words that could be usernames
    final usernamePattern = RegExp(r'(@?[a-zA-Z0-9_]+)');
    final allMatches = usernamePattern.allMatches(notificationText);
    
    // Identify which matches are usernames (they have @ or are in boldUsernames list)
    final Set<int> boldIndices = {};
    
    // Check for @mentions
    for (final match in allMatches) {
      final text = match.group(0) ?? '';
      if (text.startsWith('@')) {
        boldIndices.add(match.start);
      }
    }
    
    // Check for specific usernames in the text (like "julz_free", "yana_sic")
    // These are typically usernames that appear without @
    final commonUsernames = ['julz_free', 'yana_sic'];
    for (final username in commonUsernames) {
      final pattern = RegExp(RegExp.escape(username), caseSensitive: false);
      final matches = pattern.allMatches(notificationText);
      for (final match in matches) {
        boldIndices.add(match.start);
      }
    }
    
    // Also check boldUsernames parameter
    for (final username in boldUsernames) {
      final pattern = RegExp(RegExp.escape(username), caseSensitive: false);
      final matches = pattern.allMatches(notificationText);
      for (final match in matches) {
        boldIndices.add(match.start);
      }
    }
    
    // Build text spans
    int lastIndex = 0;
    for (final match in allMatches) {
      final matchStart = match.start;
      final matchEnd = match.end;
      final shouldBold = boldIndices.contains(matchStart);
      
      // Add text before the match
      if (matchStart > lastIndex) {
        parts.add(TextSpan(
          text: notificationText.substring(lastIndex, matchStart),
          style: textTheme?.bodyMedium?.copyWith(
            color: colors.onSurface,
            fontSize: 14,
          ),
        ));
      }
      
      // Add the match (bold if it's a username)
      parts.add(TextSpan(
        text: notificationText.substring(matchStart, matchEnd),
        style: textTheme?.bodyMedium?.copyWith(
          color: colors.onSurface,
          fontSize: 14,
          fontWeight: shouldBold ? FontWeight.bold : FontWeight.normal,
        ),
      ));
      
      lastIndex = matchEnd;
    }
    
    // Add remaining text
    if (lastIndex < notificationText.length) {
      parts.add(TextSpan(
        text: notificationText.substring(lastIndex),
        style: textTheme?.bodyMedium?.copyWith(
          color: colors.onSurface,
          fontSize: 14,
        ),
      ));
    }
    
    // If no parts were created, return plain text
    if (parts.isEmpty) {
      return Text(
        notificationText,
        style: textTheme?.bodyMedium?.copyWith(
          color: colors.onSurface,
          fontSize: 14,
        ),
      );
    }
    
    return RichText(
      text: TextSpan(children: parts),
    );
  }
}

