import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as chat_core;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';

import '../../../core/utils/app_config.dart';
import '../../../core/utils/user_profile_service.dart';
import '../../../core/network/apis/chat_api.dart';
import '../../../core/network/apis/notifications_api.dart';

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
  List<chat_core.Message> _historyMessages = [];
  List<chat_core.Message> _firebaseMessages = [];

  /// Older messages loaded from MySQL (paginated). Prepend to Firebase for display.
  String? _mysqlNextBefore;
  bool _isLoadingOlder = false;
  bool _mysqlLoadAttempted = false;
  DateTime? _lastAutoLoadTrigger;
  bool _initialEmptyLoadTriggered = false;
  bool _shortListLoadTriggered = false;

  static const double _loadOlderScrollThreshold = 150;
  static const int _autoLoadDebounceMs = 800;
  static const double _shortListMaxExtent = 80;

  String get _chatDocId => chatDocId(widget.artistId ?? 0, _fanUserId);

  /// True if we have a valid artist (required for fan chat and for backend chatDocId).
  bool get _hasValidArtistId => widget.artistId != null && widget.artistId! > 0;

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
    if (_user != null && _hasValidArtistId && _fanUserId.isNotEmpty) {
      _loadHistoryThenSubscribe();
      if (widget.isCurrentUserArtist) {
        _markChatAsRead();
      } else {
        _markChatAsReadForUser();
      }
      _setPresenceOnChat();
    }
  }

  /// Tell backend we're on this chat so push is not sent for new messages here.
  Future<void> _setPresenceOnChat() async {
    try {
      final token = await auth.FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null) return;
      final config = Get.isRegistered<AppConfig>() ? Get.find<AppConfig>() : AppConfig.fromEnv();
      final baseUrl = config.baseUrl.replaceFirst(RegExp(r'/$'), '');
      final api = NotificationsApi(baseUrl: baseUrl, authToken: token);
      await api.setPresence(screen: 'chat', contextId: _chatDocId);
    } catch (_) {}
  }

  /// Clear presence when leaving chat so future pushes are delivered.
  Future<void> _clearPresence() async {
    try {
      final token = await auth.FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null) return;
      final config = Get.isRegistered<AppConfig>() ? Get.find<AppConfig>() : AppConfig.fromEnv();
      final baseUrl = config.baseUrl.replaceFirst(RegExp(r'/$'), '');
      final api = NotificationsApi(baseUrl: baseUrl, authToken: token);
      await api.setPresence(screen: 'home', contextId: null);
    } catch (_) {}
  }

  Future<void> _loadHistoryThenSubscribe() async {
    _subscription = _messagesRef
        .orderBy('createdAt', descending: false)
        .snapshots()
        .listen(_onMessagesSnapshot);
  }

  Future<void> _markChatAsRead() async {
    try {
      await _chatDocRef.set({
        'unreadByArtist': 0,
        'artistLastReadAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  /// When fan opens the chat, clear unread count for the user.
  Future<void> _markChatAsReadForUser() async {
    try {
      await _chatDocRef.set({
        'unreadByUser': 0,
        'userLastReadAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  void _onMessagesSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    _firebaseMessages = snapshot.docs.map((doc) {
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
    _mergeAndSetMessages(_historyMessages, _firebaseMessages);
    if (_firebaseMessages.isEmpty &&
        _historyMessages.isEmpty &&
        !_initialEmptyLoadTriggered &&
        !_isLoadingOlder) {
      _initialEmptyLoadTriggered = true;
      _loadOlderFromMysql();
    }
  }

  void _mergeAndSetMessages(List<chat_core.Message> history, List<chat_core.Message> firebase) {
    final combined = <chat_core.Message>[...history, ...firebase];
    combined.sort((a, b) => (a.createdAt ?? DateTime.now()).compareTo(b.createdAt ?? DateTime.now()));
    _chatController.setMessages(combined, animated: false);
  }

  /// Load older messages from MySQL (pagination). Call when user scrolls to top or taps "Load older".
  Future<void> _loadOlderFromMysql() async {
    if (_isLoadingOlder) return;
    if (_mysqlLoadAttempted && _mysqlNextBefore == null) return;
    final token = await auth.FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) return;

    final combined = <chat_core.Message>[..._historyMessages, ..._firebaseMessages];
    combined.sort((a, b) => (a.createdAt ?? DateTime.now()).compareTo(b.createdAt ?? DateTime.now()));
    final String? beforeParam = _mysqlNextBefore ?? (combined.isEmpty ? null : combined.first.createdAt?.toUtc().toIso8601String());

    setState(() => _isLoadingOlder = true);
    try {
      final config = Get.isRegistered<AppConfig>() ? Get.find<AppConfig>() : AppConfig.fromEnv();
      final baseUrl = config.baseUrl.replaceFirst(RegExp(r'/$'), '');
      final api = ChatApi(baseUrl: baseUrl, authToken: token);
      final res = await api.getMessages(
        chatDocId: _chatDocId,
        before: beforeParam,
        limit: 10,
      );
      if (!mounted) return;
      _mysqlLoadAttempted = true;
      if (res != null && res.messages.isNotEmpty) {
        final older = res.messages.map((m) => chat_core.Message.text(
          id: 'hist_${m.id}',
          authorId: m.senderId,
          createdAt: m.createdAt,
          text: m.text,
        )).toList();
        _historyMessages = [...older, ..._historyMessages];
      }
      _mysqlNextBefore = res?.nextBefore;
      _mergeAndSetMessages(_historyMessages, _firebaseMessages);
    } finally {
      if (mounted) setState(() => _isLoadingOlder = false);
    }
  }

  @override
  void dispose() {
    _clearPresence();
    _subscription?.cancel();
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _onMessageSend(String text) async {
    if (text.trim().isEmpty || _user == null) return;
    if (!_hasValidArtistId) {
      if (mounted) {
        Get.snackbar('Error', 'Cannot send message. Please open this conversation from the artist profile again.', snackPosition: SnackPosition.BOTTOM);
      }
      return;
    }
    try {
      final token = await auth.FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null) {
        if (mounted) Get.snackbar('Error', 'Please sign in again.', snackPosition: SnackPosition.BOTTOM);
        return;
      }
      final config = Get.isRegistered<AppConfig>() ? Get.find<AppConfig>() : AppConfig.fromEnv();
      final baseUrl = config.baseUrl.replaceFirst(RegExp(r'/$'), '');
      final api = ChatApi(baseUrl: baseUrl, authToken: token);
      final response = await api.sendMessage(chatDocId: _chatDocId, text: text.trim());
      if (!mounted) return;
      if (response.isSuccess) {
        // Message is written to Firestore by the API; the existing snapshot listener will add it to the UI.
        return;
      }
      Get.snackbar('Error', response.error ?? 'Could not send message.', snackPosition: SnackPosition.BOTTOM);
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
            _buildLoadingOlderIndicator(colors),
            _buildLoadOlderBar(colors, textTheme),
            Expanded(
              child: Material(
                color: colors.surface,
                child: NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification notification) {
                    if (notification is ScrollUpdateNotification ||
                        notification is ScrollEndNotification) {
                      final metrics = notification.metrics;
                      if (!metrics.hasPixels) return false;
                      final maxExtent = metrics.maxScrollExtent;
                      final pixels = metrics.pixels;
                      bool atTop = false;
                      if (maxExtent.isFinite) {
                        if (maxExtent <= _shortListMaxExtent) {
                          atTop = !_shortListLoadTriggered;
                        } else {
                          atTop = pixels >= maxExtent - _loadOlderScrollThreshold ||
                              pixels <= _loadOlderScrollThreshold;
                        }
                      } else {
                        atTop = pixels <= _loadOlderScrollThreshold;
                      }
                      if (atTop) {
                        final now = DateTime.now();
                        if (_lastAutoLoadTrigger == null ||
                            now.difference(_lastAutoLoadTrigger!).inMilliseconds >
                                _autoLoadDebounceMs) {
                          _lastAutoLoadTrigger = now;
                          if (maxExtent.isFinite && maxExtent <= _shortListMaxExtent) {
                            _shortListLoadTriggered = true;
                          }
                          _loadOlderFromMysql();
                        }
                      }
                    }
                    return false;
                  },
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOlderIndicator(ColorScheme colors) {
    if (!_isLoadingOlder) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      alignment: Alignment.center,
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: colors.primary,
        ),
      ),
    );
  }

  Widget _buildLoadOlderBar(ColorScheme colors, TextTheme textTheme) {
    final canLoadMore = !_mysqlLoadAttempted || _mysqlNextBefore != null;
    if (!canLoadMore || _isLoadingOlder) return const SizedBox.shrink();
    return Material(
      color: colors.surfaceContainerHighest.withOpacity(0.4),
      child: InkWell(
        onTap: _loadOlderFromMysql,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: Text(
              'Load older messages',
              style: textTheme.labelLarge?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
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
