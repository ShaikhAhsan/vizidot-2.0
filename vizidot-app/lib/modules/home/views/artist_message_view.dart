import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as chat_core;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';

/// Message screen for chatting with an artist. Uses [flutter_chat_ui] and
/// Firebase Firestore. Collection: chats/{chatId}/messages.
class ArtistMessageView extends StatefulWidget {
  final int? artistId;
  final String artistName;
  final String? artistImageUrl;

  const ArtistMessageView({
    super.key,
    this.artistId,
    required this.artistName,
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

  String get _chatId {
    final uid = _user?.uid ?? '';
    final aid = widget.artistId ?? 0;
    return 'user_${uid}_artist_$aid';
  }

  String get _artistUserId => 'artist_${widget.artistId ?? 0}';

  CollectionReference<Map<String, dynamic>> get _messagesRef =>
      FirebaseFirestore.instance
          .collection(_chatsCollection)
          .doc(_chatId)
          .collection(_messagesSubcollection);

  @override
  void initState() {
    super.initState();
    _user = auth.FirebaseAuth.instance.currentUser;
    _chatController = chat_core.InMemoryChatController(messages: const []);
    if (_user != null && widget.artistId != null) {
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
    if (text.trim().isEmpty || _user == null) return;
    try {
      await _messagesRef.add({
        'text': text.trim(),
        'senderId': _user!.uid,
        'senderType': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) {
        Get.snackbar('Error', 'Could not send message.', snackPosition: SnackPosition.BOTTOM);
      }
    }
  }

  Future<chat_core.User?> _resolveUser(chat_core.UserID id) async {
    if (id == _user?.uid) {
      return chat_core.User(
        id: id,
        name: _user!.displayName,
        imageSource: _user!.photoURL,
      );
    }
    if (id == _artistUserId) {
      return chat_core.User(
        id: id,
        name: widget.artistName,
        imageSource: widget.artistImageUrl,
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
                  currentUserId: _user!.uid,
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

  /// Builds a [chat_core.ChatTheme] from the app's [ThemeData] so chat UI
  /// (bubbles, input, background) uses the same colors as the rest of the app.
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
          if (widget.artistImageUrl != null && widget.artistImageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                widget.artistImageUrl!,
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
                  widget.artistName,
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
              'Sign in with your account to send messages to ${widget.artistName}.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(color: colors.onSurface.withOpacity(0.6)),
            ),
          ],
        ),
      ),
    );
  }
}
