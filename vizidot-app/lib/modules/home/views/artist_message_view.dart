import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as chat_core;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';

/// Builds the Firestore chat document ID for a conversation between an artist and a fan (user).
/// Format: {artistId}_{fanUserId} so we can query all chats for an artist.
String chatDocId(int artistId, String fanUserId) => '${artistId}_$fanUserId';

/// Message screen for one conversation between a user (fan) and an artist.
/// Uses Firestore: chats/{artistId_fanUserId} with fields artistId, userId, lastMessage, lastMessageAt, etc.;
/// subcollection messages with text, senderId, senderType ('user'|'artist'), createdAt.
class ArtistMessageView extends StatefulWidget {
  final int? artistId;
  /// The fan's Firebase UID. When opening as fan, pass null and we use currentUser.uid.
  final String? otherPartyUserId;
  final String otherPartyDisplayName;
  final String? otherPartyImageUrl;
  /// True when the logged-in user is the artist (sending as artist).
  final bool isCurrentUserArtist;
  final String artistName;
  final String? artistImageUrl;

  const ArtistMessageView({
    super.key,
    this.artistId,
    this.otherPartyUserId,
    required this.otherPartyDisplayName,
    this.otherPartyImageUrl,
    this.isCurrentUserArtist = false,
    this.artistName = '',
    this.artistImageUrl,
  });

  @override
  State<ArtistMessageView> createState() => _ArtistMessageViewState();
}

class _ArtistMessageViewState extends State<ArtistMessageView> {
  static const String _chatsCollection = 'chats';
  static const String _messagesSubcollection = 'messages';

  auth.User? _user;
  late chat_core.InMemoryChatController _chatController;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  String get _chatDocId => chatDocId(widget.artistId ?? 0, _fanUserId);

  String get _fanUserId {
    if (widget.isCurrentUserArtist) return widget.otherPartyUserId ?? '';
    return widget.otherPartyUserId ?? _user?.uid ?? '';
  }

  /// Other party's senderId in messages: when fan view it's artist_artistId, when artist view it's fan's uid.
  String get _otherPartySenderId =>
      widget.isCurrentUserArtist ? (_fanUserId) : 'artist_${widget.artistId ?? 0}';

  CollectionReference<Map<String, dynamic>> get _messagesRef =>
      FirebaseFirestore.instance
          .collection(_chatsCollection)
          .doc(_chatDocId)
          .collection(_messagesSubcollection);

  DocumentReference<Map<String, dynamic>> get _chatDocRef =>
      FirebaseFirestore.instance.collection(_chatsCollection).doc(_chatDocId);

  @override
  void initState() {
    super.initState();
    _user = auth.FirebaseAuth.instance.currentUser;
    _chatController = chat_core.InMemoryChatController(messages: const []);
    if (_user != null && widget.artistId != null && _fanUserId.isNotEmpty) {
      _subscription = _messagesRef
          .orderBy('createdAt', descending: false)
          .snapshots()
          .listen(_onMessagesSnapshot);
    }
  }

  void _onMessagesSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final messages = snapshot.docs.map((doc) {
      final d = doc.data();
      final text = d['text'] as String? ?? '';
      final senderId = d['senderId'] as String? ?? _user!.uid;
      final createdAt = d['createdAt'] is Timestamp
          ? (d['createdAt'] as Timestamp).toDate()
          : DateTime.now();
      return chat_core.Message.text(
        id: doc.id,
        authorId: senderId,
        createdAt: createdAt,
        text: text,
      );
    }).toList();
    _chatController.setMessages(messages, animated: false);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _onMessageSend(String text) async {
    if (text.trim().isEmpty || _user == null || widget.artistId == null) return;
    try {
      final senderId = widget.isCurrentUserArtist ? 'artist_${widget.artistId}' : _user!.uid;
      final senderType = widget.isCurrentUserArtist ? 'artist' : 'user';
      await _messagesRef.add({
        'text': text.trim(),
        'senderId': senderId,
        'senderType': senderType,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _chatDocRef.set({
        'artistId': widget.artistId,
        'userId': _fanUserId,
        'lastMessage': text.trim(),
        'lastMessageAt': FieldValue.serverTimestamp(),
        'userDisplayName': widget.isCurrentUserArtist ? widget.otherPartyDisplayName : (_user!.displayName ?? _user!.email ?? 'User'),
        'artistName': widget.artistName.isNotEmpty ? widget.artistName : null,
      }, SetOptions(merge: true));
    } catch (e) {
      if (mounted) {
        Get.snackbar('Error', 'Could not send message.', snackPosition: SnackPosition.BOTTOM);
      }
    }
  }

  /// For Chat widget: when artist sends, we use senderId 'artist_artistId', so we must tell the UI that "me" is that id.
  String get _effectiveCurrentUserId =>
      widget.isCurrentUserArtist ? 'artist_${widget.artistId}' : (_user?.uid ?? '');

  Future<chat_core.User?> _resolveUser(chat_core.UserID id) async {
    if (id == _effectiveCurrentUserId) {
      return chat_core.User(
        id: id,
        name: _user!.displayName,
        imageSource: _user!.photoURL,
      );
    }
    if (id == _otherPartySenderId) {
      return chat_core.User(
        id: id,
        name: widget.otherPartyDisplayName,
        imageSource: widget.otherPartyImageUrl,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final padding = MediaQuery.paddingOf(context);

    if (_user == null) {
      return CupertinoPageScaffold(
        child: ColoredBox(
          color: colors.surface,
          child: Column(
            children: [
              _buildAppBar(colors, textTheme, padding.top),
              Expanded(child: _buildSignInPrompt(colors, textTheme)),
            ],
          ),
        ),
      );
    }

    final themeData = Theme.of(context);
    final chatTheme = _buildChatThemeFromAppTheme(themeData);

    return CupertinoPageScaffold(
      child: ColoredBox(
        color: colors.surface,
        child: Column(
          children: [
            _buildAppBar(colors, textTheme, padding.top),
            Expanded(
              child: Material(
                color: colors.surface,
                child: Chat(
                  chatController: _chatController,
                  currentUserId: _effectiveCurrentUserId,
                  resolveUser: _resolveUser,
                  onMessageSend: _onMessageSend,
                  theme: chatTheme,
                  backgroundColor: colors.surface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  chat_core.ChatTheme _buildChatThemeFromAppTheme(ThemeData themeData) {
    final cs = themeData.colorScheme;
    final base = chat_core.ChatTheme.fromThemeData(themeData);
    final appColors = chat_core.ChatColors(
      primary: cs.primary,
      onPrimary: cs.onPrimary,
      surface: cs.surface,
      onSurface: cs.onSurface,
      surfaceContainer: cs.surfaceContainerHighest,
      surfaceContainerLow: cs.surfaceContainerLow,
      surfaceContainerHigh: cs.surfaceContainerHigh,
    );
    return chat_core.ChatTheme(
      colors: appColors,
      typography: base.typography,
      shape: base.shape,
    );
  }

  Widget _buildAppBar(ColorScheme colors, TextTheme textTheme, [double topInset = 0]) {
    return Container(
      padding: EdgeInsets.only(left: 8, right: 8, top: 10 + topInset, bottom: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.outline.withOpacity(0.2))),
      ),
      child: Row(
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Get.back(),
            child: Icon(CupertinoIcons.arrow_left, color: colors.onSurface),
          ),
          const SizedBox(width: 8),
          if (widget.otherPartyImageUrl != null && widget.otherPartyImageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                widget.otherPartyImageUrl!,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(CupertinoIcons.person_fill, color: colors.onSurfaceVariant, size: 40),
              ),
            )
          else
            Icon(CupertinoIcons.person_fill, color: colors.onSurfaceVariant, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherPartyDisplayName,
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Message',
                  style: textTheme.bodySmall?.copyWith(color: colors.onSurface.withOpacity(0.6)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignInPrompt(ColorScheme colors, TextTheme textTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.person_crop_circle, size: 56, color: colors.onSurface.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              'Sign in to message',
              style: textTheme.titleMedium?.copyWith(color: colors.onSurface.withOpacity(0.8)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in with your account to send messages.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(color: colors.onSurface.withOpacity(0.6)),
            ),
          ],
        ),
      ),
    );
  }
}
