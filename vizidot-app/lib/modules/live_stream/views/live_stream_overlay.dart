import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Viewer count, live chat, and reactions overlay for BroadcastPage.
/// Uses Firestore: LiveStreams/{streamId}/viewers, /messages, /reactions.
class LiveStreamOverlay extends StatefulWidget {
  final String streamId;
  final bool isBroadcaster;
  final VoidCallback? onStreamEnded;

  const LiveStreamOverlay({
    super.key,
    required this.streamId,
    required this.isBroadcaster,
    this.onStreamEnded,
  });

  @override
  State<LiveStreamOverlay> createState() => _LiveStreamOverlayState();
}

class _LiveStreamOverlayState extends State<LiveStreamOverlay> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _addViewer() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || widget.streamId.isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection('LiveStreams')
          .doc(widget.streamId)
          .collection('viewers')
          .doc(uid)
          .set({'joinedAt': FieldValue.serverTimestamp()});
    } catch (_) {}
  }

  Future<void> _removeViewer() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || widget.streamId.isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection('LiveStreams')
          .doc(widget.streamId)
          .collection('viewers')
          .doc(uid)
          .delete();
    } catch (_) {}
  }

  Future<void> _sendMessage(String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('LiveStreams')
          .doc(widget.streamId)
          .collection('messages')
          .add({
        'userId': user.uid,
        'userDisplayName': user.displayName ?? 'User',
        'userPhotoURL': user.photoURL ?? '',
        'text': t,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _messageController.clear();
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    } catch (_) {}
  }

  Future<void> _sendReaction({String type = 'heart', String? emoji}) async {
    if (widget.streamId.isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection('LiveStreams')
          .doc(widget.streamId)
          .collection('reactions')
          .add({
        'type': type,
        if (emoji != null) 'emoji': emoji,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final streamRef = FirebaseFirestore.instance
        .collection('LiveStreams')
        .doc(widget.streamId);
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: streamRef.snapshots(),
      builder: (context, streamSnap) {
        final hasData = streamSnap.hasData;
        final exists = streamSnap.data?.exists ?? false;
        // Only "ended" when we have received a snapshot and the doc is missing
        final streamEnded = hasData && !exists;
        if (streamEnded && widget.onStreamEnded != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onStreamEnded!();
          });
        }

        return GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          behavior: HitTestBehavior.deferToChild,
          child: Stack(
          children: [
            // Broadcaster avatar + name (from stream doc) — top-left
            if (exists && streamSnap.data != null) ...[
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 12,
                child: _BroadcasterHeader(
                  name: streamSnap.data!.data()?['name'] as String? ?? 'Live',
                  photoUrl: streamSnap.data!.data()?['photo'] as String? ?? '',
                ),
              ),
            ],
            // Viewer count (top-left, below broadcaster when present)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8 + (exists ? 52 : 0),
              left: 12,
              child: _ViewerCountBadge(streamId: widget.streamId),
            ),
            // Chat panel — for viewer extends to bottom (input flush); for broadcaster above toolbar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: widget.isBroadcaster ? 100 : 0,
              child: _ChatPanel(
                streamId: widget.streamId,
                streamEnded: streamEnded,
                isBroadcaster: widget.isBroadcaster,
                messageController: _messageController,
                scrollController: _scrollController,
                onSend: _sendMessage,
              ),
            ),
            // Reaction buttons — aligned with text field (same vertical level)
            if (!widget.isBroadcaster)
              Positioned(
                right: 12,
                bottom: safeBottom,
                child: _ReactionButtons(
                  streamEnded: streamEnded,
                  onHeart: () => _sendReaction(type: 'heart'),
                  onEmoji: (emoji) => _sendReaction(type: 'emoji', emoji: emoji),
                ),
              ),
            // Floating reactions overlay
            Positioned.fill(
              child: _FloatingReactions(streamId: widget.streamId),
            ),
          ],
        ),
        );
      },
    );
  }
}

/// Broadcaster avatar + name from the live stream document.
class _BroadcasterHeader extends StatelessWidget {
  final String name;
  final String photoUrl;

  const _BroadcasterHeader({required this.name, required this.photoUrl});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.white24,
          backgroundImage: photoUrl.isNotEmpty
              ? CachedNetworkImageProvider(photoUrl)
              : null,
          child: photoUrl.isEmpty
              ? const Icon(Icons.person, color: Colors.white70, size: 22)
              : null,
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            name.isNotEmpty ? name : 'Live',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 1)),
                Shadow(color: Colors.black26, blurRadius: 4),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ViewerCountBadge extends StatelessWidget {
  final String streamId;

  const _ViewerCountBadge({required this.streamId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('LiveStreams')
          .doc(streamId)
          .collection('viewers')
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: const ColorFilter.mode(Colors.black54, BlendMode.srcOver),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(CupertinoIcons.person_2_fill, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    count.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ChatPanel extends StatefulWidget {
  final String streamId;
  final bool streamEnded;
  final bool isBroadcaster;
  final TextEditingController messageController;
  final ScrollController scrollController;
  final void Function(String) onSend;

  const _ChatPanel({
    required this.streamId,
    required this.streamEnded,
    required this.isBroadcaster,
    required this.messageController,
    required this.scrollController,
    required this.onSend,
  });

  @override
  State<_ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<_ChatPanel> {
  bool _inputExpanded = false;
  late FocusNode _inputFocusNode;

  @override
  void initState() {
    super.initState();
    _inputFocusNode = FocusNode();
    _inputFocusNode.addListener(() {
      if (!_inputFocusNode.hasFocus && mounted) setState(() => _inputExpanded = false);
    });
  }

  @override
  void dispose() {
    _inputFocusNode.dispose();
    super.dispose();
  }

  /// Transparent frosted pill/bar used for both collapsed and expanded input.
  Widget _frostedCapsule({
    required Widget child,
    EdgeInsetsGeometry? padding,
    BorderRadius? borderRadius,
  }) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: borderRadius ?? BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canSend = !widget.isBroadcaster && !widget.streamEnded;
    final keyboardBottom = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return LayoutBuilder(
      builder: (context, constraints) {
        final rightPadding = widget.isBroadcaster ? 0.0 : 56.0;
        return Padding(
          padding: EdgeInsets.only(right: rightPadding),
          child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: const SizedBox.shrink()),
            // Message list: fixed height 250px, scrollable, top edge fades transparent into screen
            SizedBox(
              height: 250,
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (bounds) => LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.white.withOpacity(0.3),
                    Colors.white,
                  ],
                  stops: const [0.0, 0.25, 0.5],
                ).createShader(bounds),
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('LiveStreams')
                      .doc(widget.streamId)
                      .collection('messages')
                      .orderBy('createdAt', descending: true)
                      .limit(80)
                      .snapshots(),
                  builder: (context, snap) {
                    final docs = snap.data?.docs ?? [];
                    if (docs.isEmpty) return const SizedBox.shrink();
                    return ListView.builder(
                      controller: widget.scrollController,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      itemCount: docs.length,
                      itemBuilder: (context, i) {
                        final d = docs[i].data();
                        final userName = d['userDisplayName'] as String? ?? 'User';
                        final photo = d['userPhotoURL'] as String? ?? '';
                        final text = d['text'] as String? ?? '';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.white24,
                                backgroundImage: photo.isNotEmpty
                                    ? CachedNetworkImageProvider(photo)
                                    : null,
                                child: photo.isEmpty
                                    ? const Icon(Icons.person, size: 16, color: Colors.white70)
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      userName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        shadows: [
                                          Shadow(color: Colors.black54, blurRadius: 4),
                                          Shadow(color: Colors.black38, blurRadius: 2),
                                        ],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      text,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        height: 1.25,
                                        shadows: [
                                          Shadow(color: Colors.black54, blurRadius: 4),
                                          Shadow(color: Colors.black38, blurRadius: 2),
                                        ],
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            if (canSend) ...[
              // Expanded input accessory (full-width bar above keyboard)
              if (_inputExpanded) ...[
                Padding(
                  padding: EdgeInsets.fromLTRB(12, 6, 12, 8 + keyboardBottom + safeBottom),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: _frostedCapsule(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: TextField(
                            controller: widget.messageController,
                            focusNode: _inputFocusNode,
                            autofocus: true,
                            textInputAction: TextInputAction.send,
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                            decoration: InputDecoration(
                              hintText: 'Type comment here...',
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
                              border: InputBorder.none,
                              filled: true,
                              fillColor: Colors.transparent,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            maxLines: 4,
                            minLines: 1,
                            onSubmitted: widget.onSend,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ]
              else
                // Collapsed: pill "Type comment here..." only (no gift button)
                Padding(
                  padding: EdgeInsets.fromLTRB(12, 4, 12, 3 + safeBottom),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _inputExpanded = true);
                          },
                          child: _frostedCapsule(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.messageController.text.trim().isEmpty
                                        ? 'Type comment here...'
                                        : widget.messageController.text.trim(),
                                    style: TextStyle(
                                      color: widget.messageController.text.trim().isEmpty
                                          ? Colors.white.withOpacity(0.7)
                                          : Colors.white,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),

                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ]
            else if (widget.streamEnded)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  'Stream ended',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                    shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
                  ),
                ),
              ),
          ],
        ),
        );
      },
    );
  }
}

const _reactionEmojis = ['❤️', '😂', '🔥', '👏', '😍'];

class _ReactionButtons extends StatelessWidget {
  final bool streamEnded;
  final VoidCallback onHeart;
  final void Function(String emoji) onEmoji;

  const _ReactionButtons({
    required this.streamEnded,
    required this.onHeart,
    required this.onEmoji,
  });

  @override
  Widget build(BuildContext context) {
    if (streamEnded) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ReactionBtn(
          icon: Icons.favorite,
          color: Colors.red,
          onTap: onHeart,
        ),
        const SizedBox(height: 8),
        ..._reactionEmojis.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _ReactionBtn(
              emoji: e,
              onTap: () => onEmoji(e),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReactionBtn extends StatelessWidget {
  final IconData? icon;
  final Color? color;
  final String? emoji;
  final VoidCallback onTap;

  const _ReactionBtn({
    this.icon,
    this.color,
    this.emoji,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.35),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white24),
          ),
          child: icon != null
              ? Icon(icon, color: color ?? Colors.white, size: 28)
              : Text(emoji ?? '', style: const TextStyle(fontSize: 24)),
        ),
      ),
    );
  }
}

class _FloatingReactions extends StatefulWidget {
  final String streamId;

  const _FloatingReactions({required this.streamId});

  @override
  State<_FloatingReactions> createState() => _FloatingReactionsState();
}

class _FloatingReactionsState extends State<_FloatingReactions> {
  final _activeReactions = <String, _ReactionItem>{};
  final _shownIds = <String>{};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _reactionsSub;

  @override
  void initState() {
    super.initState();
    _reactionsSub = FirebaseFirestore.instance
        .collection('LiveStreams')
        .doc(widget.streamId)
        .collection('reactions')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
          _processNewReactions(snapshot.docs);
        });
  }

  void _processNewReactions(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    var changed = false;
    for (final doc in docs) {
      if (_shownIds.contains(doc.id)) continue;
      _shownIds.add(doc.id);
      final d = doc.data();
      final type = d['type'] as String? ?? 'heart';
      final emoji = d['emoji'] as String?;
      if (!_activeReactions.containsKey(doc.id)) {
        _activeReactions[doc.id] = _ReactionItem(
          type: type,
          emoji: emoji,
          onDone: () {
            if (mounted) setState(() => _activeReactions.remove(doc.id));
          },
        );
        changed = true;
      }
    }
    if (changed && mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _reactionsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          for (final entry in _activeReactions.entries)
            _FloatingReactionWidget(
              key: ValueKey(entry.key),
              item: entry.value,
            ),
        ],
      ),
    );
  }
}

class _ReactionItem {
  final String type;
  final String? emoji;
  final VoidCallback onDone;

  _ReactionItem({required this.type, this.emoji, required this.onDone});
}

class _FloatingReactionWidget extends StatefulWidget {
  final _ReactionItem item;

  const _FloatingReactionWidget({super.key, required this.item});

  @override
  State<_FloatingReactionWidget> createState() => _FloatingReactionWidgetState();
}

class _FloatingReactionWidgetState extends State<_FloatingReactionWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _opacity = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _offset = Tween<Offset>(
      begin: Offset(0.15 + (DateTime.now().millisecond % 70) / 100, 0.85),
      end: Offset(0.2 + (DateTime.now().millisecond % 60) / 100, 0.2),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _controller.forward().then((_) {
      widget.item.onDone();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: _offset.value.dx * size.width - 24,
          top: _offset.value.dy * size.height - 24,
          child: Opacity(
            opacity: _opacity.value,
            child: widget.item.type == 'emoji' && widget.item.emoji != null
                ? Text(
                    widget.item.emoji!,
                    style: const TextStyle(fontSize: 48),
                  )
                : const Text(
                    '❤️',
                    style: TextStyle(fontSize: 48),
                  ),
          ),
        );
      },
    );
  }
}
