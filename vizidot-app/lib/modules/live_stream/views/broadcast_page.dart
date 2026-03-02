import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:agora_token_generator/agora_token_generator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;
import '../models/live_stream_model.dart';
import '../../../core/utils/agora.dart';
import '../../../core/utils/app_config.dart';
import '../../../core/network/apis/live_api.dart';
import 'live_stream_overlay.dart';
import '../widgets/invite_to_join_popup.dart';

class BroadcastPage extends StatefulWidget {
  final bool isBroadcaster;
  final bool isInvitedGuest;
  final LiveStreamModel liveStream;

  const BroadcastPage({
    super.key,
    required this.isBroadcaster,
    this.isInvitedGuest = false,
    required this.liveStream,
  });

  @override
  State<BroadcastPage> createState() => _BroadcastPageState();
}

class _BroadcastPageState extends State<BroadcastPage> {
  final _remoteUids = <int>[];
  Timer? timer;
  RtcEngine? _engine;
  bool _localUserJoined = false;
  bool _isInitializing = false;
  bool muted = false;
  /// Local Agora UID (0 for host; set from onJoinChannelSuccess for guest).
  int? _localUid;

  @override
  void dispose() {
    developer.log('🧹 [Broadcast] Disposing broadcast page...', name: 'BroadcastPage');
    _removeViewerIfAudience();
    _dispose();
    if (widget.isBroadcaster && !widget.isInvitedGuest) {
      developer.log('🗑️ [Broadcast] Removing live stream from Firestore...', name: 'BroadcastPage');
      removeLiveStream();
    }
    _remoteUids.clear();
    timer?.cancel();
    developer.log('✅ [Broadcast] Broadcast page disposed', name: 'BroadcastPage');
    super.dispose();
  }

  Future<void> _addViewerIfAudience() async {
    if (widget.isBroadcaster || widget.isInvitedGuest) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || widget.liveStream.identifier.isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection('LiveStreams')
          .doc(widget.liveStream.identifier)
          .collection('viewers')
          .doc(uid)
          .set({'joinedAt': FieldValue.serverTimestamp()});
    } catch (_) {}
  }

  Future<void> _removeViewerIfAudience() async {
    if (widget.isBroadcaster || widget.isInvitedGuest) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || widget.liveStream.identifier.isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection('LiveStreams')
          .doc(widget.liveStream.identifier)
          .collection('viewers')
          .doc(uid)
          .delete();
    } catch (_) {}
  }

  Future<void> _dispose() async {
    if (_engine == null) return;
    
    try {
      await _engine!.leaveChannel();
      developer.log('👋 [Broadcast] Left channel', name: 'BroadcastPage');
    } catch (e) {
      developer.log('⚠️ [Broadcast] Error leaving channel: $e', name: 'BroadcastPage');
    }
    
    try {
      await _engine!.release();
      developer.log('✅ [Broadcast] RTC Engine released', name: 'BroadcastPage');
    } catch (e) {
      developer.log('⚠️ [Broadcast] Error releasing engine: $e', name: 'BroadcastPage');
    }
  }

  @override
  void initState() {
    super.initState();
    final screenRole = widget.isBroadcaster ? 'HOST' : (widget.isInvitedGuest ? 'GUEST' : 'VIEWER');
    developer.log('📺 [Broadcast] Screen=BroadcastPage [$screenRole] isBroadcaster=${widget.isBroadcaster} isInvitedGuest=${widget.isInvitedGuest}', name: 'BroadcastPage');
    developer.log('📺 [Broadcast] Channel: ${widget.liveStream.channel}, Stream ID: ${widget.liveStream.identifier}', name: 'BroadcastPage');
    
    // Delay Agora initialization to ensure widget is fully mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initializeAgora().catchError((error, stackTrace) {
        developer.log('❌ [Broadcast] Failed to initialize Agora: $error', name: 'BroadcastPage', error: error, stackTrace: stackTrace);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to initialize live stream: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    });
    
    // Only host (broadcaster) updates the live stream doc; audience/guest do not.
    if (widget.isBroadcaster) {
      timer = Timer.periodic(
        const Duration(seconds: 30),
        (Timer t) => updateLiveStream(),
      );
    }
  }

  Future<void> initializeAgora() async {
    if (_isInitializing || _engine != null) {
      developer.log('⚠️ [Broadcast] Already initializing or initialized', name: 'BroadcastPage');
      return;
    }

    _isInitializing = true;
    developer.log('🔧 [Broadcast] Initializing Agora RTC Engine...', name: 'BroadcastPage');

    final int joinUid = widget.isBroadcaster
        ? 0
        : DateTime.now().millisecondsSinceEpoch.remainder(1000000000).clamp(1, 0x7FFFFFFF);
    String token = '';
    String effectiveAppId = appId;
    bool apiWasCalled = false;

    try {
      if (appId.isEmpty) {
        throw Exception('Agora App ID is empty');
      }

      // Debug: force empty token when Agora project is in testing mode (to confirm -17 is certificate mismatch).
      if (agoraUseEmptyToken) {
        token = '';
        developer.log('⚠️ [Broadcast] AGORA_EMPTY_TOKEN=true: joining with empty token (testing mode)', name: 'BroadcastPage');
      }

      // Fetch token first when API is available, so we use the same App ID the token was built with.
      final config = AppConfig.fromEnv();
      final baseUrl = config.baseUrl.replaceFirst(RegExp(r'/$'), '');
      if (baseUrl.isNotEmpty && !agoraUseEmptyToken) {
        apiWasCalled = true;
        try {
          final liveApi = LiveApi(baseUrl: baseUrl, debugPrintRequest: false);
          final result = await liveApi.getRtcToken(
            channelName: widget.liveStream.channel,
            role: widget.isBroadcaster ? 'publisher' : 'audience',
            uid: joinUid,
          );
          if (result != null) {
            if (result.appId != null && result.appId!.trim().isNotEmpty) {
              effectiveAppId = result.appId!.trim();
              developer.log('🔧 [Broadcast] Using App ID from token API: $effectiveAppId', name: 'BroadcastPage');
            }
            if (result.token != null && result.token!.isNotEmpty) {
              token = result.token!;
              developer.log('🔑 [Broadcast] Using RTC token from API (uid: $joinUid)', name: 'BroadcastPage');
            } else {
              developer.log('⚠️ [Broadcast] API returned no token. Set AGORA_APP_CERTIFICATE on the API server, or use Agora testing mode (empty token).', name: 'BroadcastPage');
            }
          }
        } catch (e) {
          developer.log('⚠️ [Broadcast] Token fetch from API failed: $e', name: 'BroadcastPage');
        }
      } else {
        developer.log('⚠️ [Broadcast] BASE_URL is empty; cannot fetch RTC token from API', name: 'BroadcastPage');
      }

      if (token.isEmpty && !apiWasCalled && !agoraUseEmptyToken) {
        final cert = appIdAppCertificate;
        if (cert.isNotEmpty) {
          try {
            token = RtcTokenBuilder.buildTokenWithUid(
              appId: effectiveAppId,
              appCertificate: cert,
              channelName: widget.liveStream.channel,
              uid: joinUid,
              tokenExpireSeconds: 3600,
            );
            developer.log('🔑 [Broadcast] Using locally built RTC token (uid: $joinUid)', name: 'BroadcastPage');
          } catch (e) {
            developer.log('⚠️ [Broadcast] Local token build failed: $e', name: 'BroadcastPage');
          }
        }
        if (token.isEmpty) {
          developer.log('⚠️ [Broadcast] Joining with empty token (testing mode). If join fails, set AGORA_APP_CERTIFICATE on the API server to match Agora Console.', name: 'BroadcastPage');
        }
      }

      developer.log('🔧 [Broadcast] Creating RTC Engine with App ID: $effectiveAppId', name: 'BroadcastPage');
      final engine = createAgoraRtcEngine();
      _engine = engine;

      await engine.initialize(RtcEngineContext(
        appId: effectiveAppId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));
      developer.log('✅ [Broadcast] RTC Engine initialized', name: 'BroadcastPage');

      developer.log('🎧 [Broadcast] Registering event handlers...', name: 'BroadcastPage');
      engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            developer.log('✅ [Broadcast] Joined channel successfully: ${connection.channelId}, UID: ${connection.localUid}, Elapsed: ${elapsed}ms', name: 'BroadcastPage');
            if (mounted) {
              setState(() {
                _localUserJoined = true;
                _localUid = connection.localUid;
              });
              _addViewerIfAudience();
            }
          },
          onLeaveChannel: (RtcConnection connection, RtcStats stats) {
            developer.log('👋 [Broadcast] Left channel', name: 'BroadcastPage');
            if (mounted) {
              setState(() {
                _localUserJoined = false;
                _remoteUids.clear();
              });
            }
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            developer.log('👤 [Broadcast] User joined: UID $remoteUid, Elapsed: ${elapsed}ms', name: 'BroadcastPage');
            if (mounted) {
              setState(() {
                _remoteUids.add(remoteUid);
              });
            }
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            developer.log('👋 [Broadcast] User offline: UID $remoteUid, Reason: $reason', name: 'BroadcastPage');
            if (mounted) {
              setState(() {
                _remoteUids.remove(remoteUid);
              });
            }
          },
          onFirstRemoteVideoFrame: (RtcConnection connection, int remoteUid, int width, int height, int elapsed) {
            developer.log('📹 [Broadcast] First remote video frame: UID $remoteUid, Size: ${width}x$height, Elapsed: ${elapsed}ms', name: 'BroadcastPage');
          },
          onError: (ErrorCodeType err, String msg) {
            developer.log('❌ [Broadcast] Agora error: Code $err, Message: $msg', name: 'BroadcastPage');
            if (mounted) {
              final isInvalidToken = err == ErrorCodeType.errInvalidToken;
              final content = isInvalidToken
                  ? 'Invalid Agora token. Use the exact Primary Certificate from Agora Console (for this App ID) in .env as AGORA_APP_CERTIFICATE, or set it on the API server.'
                  : 'Agora error: $err - $msg';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(content),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 6),
                ),
              );
            }
          },
        ),
      );

      // Set client role: only host is Broadcaster; invited guest (fan who accepted) joins as Audience like the old app.
      final joinAsPublisher = widget.isBroadcaster;
      if (joinAsPublisher) {
        developer.log('🎥 [Broadcast] Setting client role to Broadcaster...', name: 'BroadcastPage');
        await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      } else {
        developer.log('👂 [Broadcast] Setting client role to Audience...', name: 'BroadcastPage');
        await engine.setClientRole(role: ClientRoleType.clientRoleAudience);
      }
      developer.log('✅ [Broadcast] Client role set', name: 'BroadcastPage');

      // Enable video
      developer.log('📹 [Broadcast] Enabling video...', name: 'BroadcastPage');
      await engine.enableVideo();
      developer.log('✅ [Broadcast] Video enabled', name: 'BroadcastPage');

      // Start preview only for host (broadcaster). Invited guest is Audience — no local video, just receive host like old code.
      if (widget.isBroadcaster) {
        developer.log('📹 [Broadcast] Starting preview...', name: 'BroadcastPage');
        await engine.startPreview();
        developer.log('✅ [Broadcast] Preview started', name: 'BroadcastPage');
      }

      developer.log('🚪 [Broadcast] Joining channel: ${widget.liveStream.channel} (uid: $joinUid)...', name: 'BroadcastPage');
      await engine.joinChannel(
        token: token,
        channelId: widget.liveStream.channel,
        uid: joinUid,
        options: const ChannelMediaOptions(),
      );
      developer.log('✅ [Broadcast] Join channel request sent', name: 'BroadcastPage');
      _isInitializing = false;
    } catch (e, stackTrace) {
      _isInitializing = false;
      developer.log('❌ [Broadcast] Error initializing Agora: $e', name: 'BroadcastPage', error: e, stackTrace: stackTrace);

      // Agora -17 = ERR_JOIN_CHANNEL_REJECTED: token required, or token invalid (certificate does not match App ID's project).
      final isTokenError = e.toString().contains('-17') || e.toString().contains('AgoraRtcException(-17');
      final String userMessage = isTokenError
          ? 'Join rejected (-17). The Agora certificate on your API server does not match this App ID. In Agora Console open the project for this App ID → Project Management → Primary Certificate → copy again (no spaces) into api/.env as AGORA_APP_CERTIFICATE. If you reset the certificate, use the new one.'
          : 'Failed to initialize live stream: ${e.toString()}';

      // Clean up on error
      try {
        if (_engine != null) {
          await _engine!.release();
          _engine = null;
        }
      } catch (cleanupError) {
        developer.log('⚠️ [Broadcast] Error during cleanup: $cleanupError', name: 'BroadcastPage');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
      }
      // Do not rethrow so the guest page stays open and the user can tap back or retry
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade400,
      appBar: AppBar(
        title: Text(widget.isInvitedGuest ? 'Live with ${widget.liveStream.name}' : 'Live Stream'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: <Widget>[
          _broadcastView(),
          _toolbar(),
          LiveStreamOverlay(
            streamId: widget.liveStream.identifier,
            isBroadcaster: widget.isBroadcaster,
            isInvitedGuest: widget.isInvitedGuest,
            onStreamEnded: widget.isInvitedGuest
                ? null
                : () {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Stream ended')),
                      );
                      Navigator.of(context).pop();
                    }
                  },
          ),
          if (!widget.isBroadcaster && !widget.isInvitedGuest)
            _InviteListener(
              streamId: widget.liveStream.identifier,
              artistName: widget.liveStream.name,
              liveStream: widget.liveStream,
            ),
        ],
      ),
    );
  }

  Widget _toolbar() {
    if (widget.isInvitedGuest) {
      return Container(
        alignment: Alignment.bottomCenter,
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: RawMaterialButton(
          onPressed: () => Navigator.pop(context),
          shape: const CircleBorder(),
          elevation: 2.0,
          fillColor: Colors.redAccent,
          padding: const EdgeInsets.all(15.0),
          child: const Icon(Icons.call_end, color: Colors.white, size: 35.0),
        ),
      );
    }
    return widget.isBroadcaster
        ? Container(
            alignment: Alignment.bottomCenter,
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                RawMaterialButton(
                  onPressed: _onToggleMute,
                  shape: const CircleBorder(),
                  elevation: 2.0,
                  fillColor: muted ? Colors.blueAccent : Colors.white,
                  padding: const EdgeInsets.all(12.0),
                  child: Icon(
                    muted ? Icons.mic_off : Icons.mic,
                    color: muted ? Colors.white : Colors.blueAccent,
                    size: 20.0,
                  ),
                ),
                RawMaterialButton(
                  onPressed: () => _onCallEnd(context),
                  shape: const CircleBorder(),
                  elevation: 2.0,
                  fillColor: Colors.redAccent,
                  padding: const EdgeInsets.all(15.0),
                  child: const Icon(
                    Icons.call_end,
                    color: Colors.white,
                    size: 35.0,
                  ),
                ),
                RawMaterialButton(
                  onPressed: _onSwitchCamera,
                  shape: const CircleBorder(),
                  elevation: 2.0,
                  fillColor: Colors.white,
                  padding: const EdgeInsets.all(12.0),
                  child: const Icon(
                    Icons.switch_camera,
                    color: Colors.blueAccent,
                    size: 20.0,
                  ),
                ),
              ],
            ),
          )
        : const SizedBox.shrink();
  }

  Widget _broadcastView() {
    return Stack(
      children: [
        // Main video layout (local + remotes in one grid when there are participants)
        SizedBox.expand(
          child: _videoLayout(),
        ),
      ],
    );
  }

  /// Current user's Agora UID (host = 0, guest = from join).
  int get _myUid => widget.isBroadcaster ? 0 : (_localUid ?? 0);

  // Layout local + remote videos according to number of participants
  Widget _videoLayout() {
    if (_engine == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Only host is publisher; invited guest is Audience (like old app) — no local video, only remotes.
    final isPublisher = widget.isBroadcaster;

    // Publisher (host) alone: show local video full screen
    if (isPublisher && _localUserJoined && _remoteUids.isEmpty) {
      return _localVideoTile();
    }

    // Audience or guest waiting for remote video
    if (_remoteUids.isEmpty) {
      final isGuest = widget.isInvitedGuest;
      return Center(
        child: Text(
          isGuest ? 'Connecting to host...' : 'Waiting for remote users to join...',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
      );
    }

    // All streams: for host include local + remotes; for audience/guest only remotes (like old _getRenderViews).
    final List<int> allUids = isPublisher && _localUserJoined
        ? [_myUid, ..._remoteUids]
        : List<int>.from(_remoteUids);

    return _buildGrid(allUids);
  }

  Widget _localVideoTile() {
    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: _engine!,
        canvas: VideoCanvas(uid: _myUid),
      ),
    );
  }

  Widget _videoTile(int uid) {
    if (uid == _myUid) {
      return _localVideoTile();
    }
    return _remoteTile(uid);
  }

  Widget _buildGrid(List<int> uids) {
    if (uids.isEmpty) {
      return const Center(child: Text('Waiting...', style: TextStyle(fontSize: 16)));
    }
    if (uids.length == 1) {
      return _videoTile(uids[0]);
    }
    if (uids.length == 2) {
      return Column(
        children: [
          Expanded(child: _videoTile(uids[0])),
          Expanded(child: _videoTile(uids[1])),
        ],
      );
    }
    if (uids.length == 3) {
      return Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _videoTile(uids[0])),
                Expanded(child: _videoTile(uids[1])),
              ],
            ),
          ),
          Expanded(child: _videoTile(uids[2])),
        ],
      );
    }
    // 4+ tiles: 2x2 grid (show first 4 if more)
    final visible = uids.take(4).toList();
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: _videoTile(visible[0])),
              Expanded(child: _videoTile(visible[1])),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _videoTile(visible[2])),
              Expanded(child: _videoTile(visible.length > 3 ? visible[3] : visible[2])),
            ],
          ),
        ),
      ],
    );
  }

  Widget _remoteTile(int uid) {
    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: _engine!,
        canvas: VideoCanvas(uid: uid),
        connection: RtcConnection(channelId: widget.liveStream.channel),
      ),
    );
  }

  void _onCallEnd(BuildContext context) {
    developer.log('📞 [Broadcast] Call ended by user', name: 'BroadcastPage');
    Navigator.pop(context);
  }

  void _onToggleMute() {
    if (_engine == null) return;
    muted = !muted;
    developer.log('🔇 [Broadcast] Audio muted: $muted', name: 'BroadcastPage');
    setState(() {});
    try {
      _engine!.muteLocalAudioStream(muted);
    } catch (e) {
      developer.log('❌ [Broadcast] Error toggling mute: $e', name: 'BroadcastPage');
    }
  }

  void _onSwitchCamera() {
    if (_engine == null) return;
    developer.log('📷 [Broadcast] Switching camera...', name: 'BroadcastPage');
    try {
      _engine!.switchCamera();
    } catch (e) {
      developer.log('❌ [Broadcast] Error switching camera: $e', name: 'BroadcastPage');
    }
  }

  void updateLiveStream() {
    if (!widget.isBroadcaster) return;
    widget.liveStream.dateUpdated = widget.liveStream.dateUpdated + 30000;
    developer.log('🔄 [Broadcast] Updating live stream timestamp: ${widget.liveStream.dateUpdated}', name: 'BroadcastPage');
    final db = FirebaseFirestore.instance;
    db
        .collection("LiveStreams")
        .doc(widget.liveStream.identifier)
        .update(widget.liveStream.toMap())
        .then((value) {
          developer.log('✅ [Broadcast] Live stream updated successfully', name: 'BroadcastPage');
        })
        .catchError((error) {
          developer.log('❌ [Broadcast] Error updating live stream: $error', name: 'BroadcastPage');
        });
  }

  void removeLiveStream() async {
    developer.log('🗑️ [Broadcast] Removing live stream: ${widget.liveStream.identifier}', name: 'BroadcastPage');
    final db = FirebaseFirestore.instance;
    await db
        .collection("LiveStreams")
        .doc(widget.liveStream.identifier)
        .delete()
        .then((value) {
          developer.log('✅ [Broadcast] Live stream removed successfully', name: 'BroadcastPage');
        })
        .catchError((error) {
          developer.log('❌ [Broadcast] Error removing live stream: $error', name: 'BroadcastPage');
        });
  }
}

/// Listens to the current user's invite doc and shows the invite dialog when status is pending.
/// Uses [showDialog] so the dialog is on a separate route and receives touches (Agora platform view was stealing taps).
class _InviteListener extends StatefulWidget {
  final String streamId;
  final String artistName;
  final LiveStreamModel liveStream;

  const _InviteListener({
    required this.streamId,
    required this.artistName,
    required this.liveStream,
  });

  @override
  State<_InviteListener> createState() => _InviteListenerState();
}

class _InviteListenerState extends State<_InviteListener> {
  bool _dialogShown = false;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || widget.streamId.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('LiveStreams')
          .doc(widget.streamId)
          .collection('invites')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          developer.log('📩 [Invite] No snapshot data', name: 'InviteListener');
          return const SizedBox.shrink();
        }
        final doc = snapshot.data;
        if (doc == null || !doc.exists) {
          developer.log('📩 [Invite] Doc missing or not exists', name: 'InviteListener');
          return const SizedBox.shrink();
        }
        final data = doc.data();
        final status = data?['status'] as String?;
        developer.log('📩 [Invite] Doc exists, status=$status', name: 'InviteListener');
        if (data == null || status != 'pending') {
          if (_dialogShown) WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) setState(() => _dialogShown = false); });
          return const SizedBox.shrink();
        }

        if (!_dialogShown) {
          developer.log('📩 [Invite] Showing dialog (pending invite)', name: 'InviteListener');
          _dialogShown = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            developer.log('📩 [Invite] Calling showDialog', name: 'InviteListener');
            showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (dialogContext) => InviteToJoinPopup(
                artistName: widget.artistName,
                artistPhotoUrl: widget.liveStream.photo.isNotEmpty ? widget.liveStream.photo : null,
                onAccept: () => _onAccept(dialogContext),
                onDecline: () => _onDecline(dialogContext),
              ),
            );
          });
        }

        return const SizedBox.shrink();
      },
    );
  }

  Future<void> _onAccept(BuildContext dialogContext) async {
    developer.log('📩 [Invite] Accept tapped', name: 'InviteListener');
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final liveStream = widget.liveStream;
    try {
      await FirebaseFirestore.instance
          .collection('LiveStreams')
          .doc(widget.streamId)
          .collection('invites')
          .doc(uid)
          .update({'status': 'accepted'});
    } catch (_) {}
    if (!dialogContext.mounted) return;
    Navigator.of(dialogContext).pop();
    developer.log('📩 [Invite] Dialog closed. Current route before replace: ${Get.currentRoute}', name: 'InviteListener');
    final nav = Get.key?.currentContext != null
        ? Navigator.of(Get.key!.currentContext!, rootNavigator: true)
        : null;
    if (nav == null) {
      developer.log('📩 [Invite] No navigator (Get.key.currentContext null), falling back to Get.off()', name: 'InviteListener');
      Get.off(() => BroadcastPage(
            liveStream: liveStream,
            isBroadcaster: false,
            isInvitedGuest: true,
          ));
    } else {
      developer.log('📩 [Invite] Replacing VIEWER with GUEST via Navigator.pushReplacement', name: 'InviteListener');
      nav.pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => BroadcastPage(
            liveStream: liveStream,
            isBroadcaster: false,
            isInvitedGuest: true,
          ),
        ),
      );
      developer.log('📩 [Invite] pushReplacement called; GUEST BroadcastPage should build now', name: 'InviteListener');
    }
  }

  Future<void> _onDecline(BuildContext dialogContext) async {
    developer.log('📩 [Invite] Decline tapped', name: 'InviteListener');
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('LiveStreams')
          .doc(widget.streamId)
          .collection('invites')
          .doc(uid)
          .update({'status': 'rejected'});
    } catch (_) {}
    if (dialogContext.mounted) Navigator.of(dialogContext).pop();
    if (mounted) setState(() => _dialogShown = false);
  }
}
