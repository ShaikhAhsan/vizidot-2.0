import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../routes/app_pages.dart';

/// Lists all chats (conversations with users) for an artist. Artist taps Messages in Profile > Artist tab.
class ArtistChatListView extends StatefulWidget {
  final int artistId;
  final String artistName;
  final String? artistImageUrl;

  const ArtistChatListView({
    super.key,
    required this.artistId,
    required this.artistName,
    this.artistImageUrl,
  });

  @override
  State<ArtistChatListView> createState() => _ArtistChatListViewState();
}

class _ArtistChatListViewState extends State<ArtistChatListView> {
  static const String _chatsCollection = 'chats';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final topPadding = MediaQuery.paddingOf(context).top;

    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Messages'),
            backgroundColor: colors.surface,
            border: null,
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => Get.back(),
              child: const Icon(CupertinoIcons.arrow_left),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 8 + topPadding)),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection(_chatsCollection)
                .where('artistId', isEqualTo: widget.artistId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Something went wrong',
                            style: textTheme.bodyLarge?.copyWith(color: colors.error),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            snapshot.error.toString(),
                            style: textTheme.bodySmall?.copyWith(color: colors.onSurface.withOpacity(0.7)),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const SliverFillRemaining(
                  child: Center(child: CupertinoActivityIndicator()),
                );
              }
              final rawDocs = snapshot.data!.docs;
              final docs = rawDocs.toList();
              // Sort by lastMessageAt descending (newest first) in memory to avoid composite index
              docs.sort((a, b) {
                final tA = a.data()['lastMessageAt'] is Timestamp
                    ? (a.data()['lastMessageAt'] as Timestamp).millisecondsSinceEpoch
                    : 0;
                final tB = b.data()['lastMessageAt'] is Timestamp
                    ? (b.data()['lastMessageAt'] as Timestamp).millisecondsSinceEpoch
                    : 0;
                return tB.compareTo(tA);
              });
              if (docs.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.chat_bubble_2,
                            size: 64,
                            color: colors.onSurface.withOpacity(0.3),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'No conversations yet',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colors.onSurface.withOpacity(0.8),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'When users message you, conversations will appear here.',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colors.onSurface.withOpacity(0.6),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final doc = docs[index];
                    final d = doc.data();
                    final userId = d['userId'] as String? ?? '';
                    final userDisplayName = d['userDisplayName'] as String?;
                    final userEmail = d['userEmail'] as String?;
                    final displayLabel = (userDisplayName != null && userDisplayName.trim().isNotEmpty)
                        ? userDisplayName.trim()
                        : (userEmail != null && userEmail.trim().isNotEmpty ? userEmail.trim() : 'User');
                    final userPhotoURL = d['userPhotoURL'] as String?;
                    final lastMessage = d['lastMessage'] as String? ?? '';
                    final lastMessageAt = d['lastMessageAt'] is Timestamp
                        ? (d['lastMessageAt'] as Timestamp).toDate()
                        : null;
                    final unreadByArtist = (d['unreadByArtist'] as num?)?.toInt() ?? 0;
                    return _ChatTile(
                      displayLabel: displayLabel,
                      userPhotoURL: userPhotoURL,
                      lastMessage: lastMessage,
                      lastMessageAt: lastMessageAt,
                      unreadCount: unreadByArtist,
                      onTap: () {
                        Get.toNamed(
                          AppRoutes.artistMessage,
                          arguments: {
                            'artistId': widget.artistId,
                            'otherPartyUserId': userId,
                            'otherPartyDisplayName': displayLabel,
                            'otherPartyImageUrl': userPhotoURL,
                            'isCurrentUserArtist': true,
                            'artistName': widget.artistName,
                            'artistImageUrl': widget.artistImageUrl,
                          },
                        );
                      },
                    );
                  },
                  childCount: docs.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final String displayLabel;
  final String? userPhotoURL;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final VoidCallback onTap;

  const _ChatTile({
    required this.displayLabel,
    this.userPhotoURL,
    required this.lastMessage,
    required this.lastMessageAt,
    this.unreadCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(bottom: BorderSide(color: colors.outline.withOpacity(0.15))),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: userPhotoURL != null && userPhotoURL!.isNotEmpty
                  ? Image.network(
                      userPhotoURL!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _avatarPlaceholder(colors),
                    )
                  : _avatarPlaceholder(colors),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayLabel,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: unreadCount > 0 ? FontWeight.w700 : FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (lastMessage.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      lastMessage,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.onSurface.withOpacity(0.7),
                        fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : '$unreadCount',
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              )
            else if (lastMessageAt != null)
              Text(
                _formatTime(lastMessageAt!),
                style: textTheme.bodySmall?.copyWith(
                  color: colors.onSurface.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _avatarPlaceholder(ColorScheme colors) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      child: Icon(CupertinoIcons.person_fill, color: colors.onSurfaceVariant, size: 28),
    );
  }

  String _formatTime(DateTime t) {
    final now = DateTime.now();
    if (t.day == now.day && t.month == now.month && t.year == now.year) {
      return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    }
    if (t.year == now.year) {
      return '${t.month}/${t.day}';
    }
    return '${t.year}/${t.month}/${t.day}';
  }
}
