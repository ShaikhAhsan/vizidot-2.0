import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;
import '../models/live_stream_model.dart';
import '../../../core/utils/agora.dart';
import '../../../core/utils/app_config.dart';
import '../../../core/network/apis/live_api.dart';
import 'live_stream_overlay.dart';

class BroadcastPage extends StatefulWidget {
  final bool isBroadcaster;
  final LiveStreamModel liveStream;

  const BroadcastPage({
    super.key,
    required this.isBroadcaster,
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

  @override
  void dispose() {
    developer.log('🧹 [Broadcast] Disposing broadcast page...', name: 'BroadcastPage');
    _removeViewerIfAudience();
    _dispose();
    if (widget.isBroadcaster) {
      developer.log('🗑️ [Broadcast] Removing live stream from Firestore...', name: 'BroadcastPage');
      removeLiveStream();
    }
    _remoteUids.clear();
    timer?.cancel();
    developer.log('✅ [Broadcast] Broadcast page disposed', name: 'BroadcastPage');
    super.dispose();
  }

  Future<void> _addViewerIfAudience() async {
    if (widget.isBroadcaster) return;
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
    if (widget.isBroadcaster) return;
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
    developer.log('📺 [Broadcast] Initializing broadcast page...', name: 'BroadcastPage');
    developer.log('📺 [Broadcast] Is Broadcaster: ${widget.isBroadcaster}', name: 'BroadcastPage');
    developer.log('📺 [Broadcast] Channel: ${widget.liveStream.channel}', name: 'BroadcastPage');
    developer.log('📺 [Broadcast] Stream ID: ${widget.liveStream.identifier}', name: 'BroadcastPage');
    
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
    
    timer = Timer.periodic(
      const Duration(seconds: 30),
      (Timer t) => updateLiveStream(),
    );
  }

  Future<void> initializeAgora() async {
    if (_isInitializing || _engine != null) {
      developer.log('⚠️ [Broadcast] Already initializing or initialized', name: 'BroadcastPage');
      return;
    }
    
    _isInitializing = true;
    developer.log('🔧 [Broadcast] Initializing Agora RTC Engine...', name: 'BroadcastPage');
    
    try {
      // Validate appId
      if (appId.isEmpty) {
        throw Exception('Agora App ID is empty');
      }
      
      // Create the engine (as per latest Agora example)
      developer.log('🔧 [Broadcast] Creating RTC Engine with App ID: $appId', name: 'BroadcastPage');
      final engine = createAgoraRtcEngine();
      _engine = engine;
      
      // Initialize with channel profile (as per latest Agora example)
      await engine.initialize(RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));
      developer.log('✅ [Broadcast] RTC Engine initialized', name: 'BroadcastPage');

      // Register event handlers (as per latest Agora example)
      developer.log('🎧 [Broadcast] Registering event handlers...', name: 'BroadcastPage');
      engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            developer.log('✅ [Broadcast] Joined channel successfully: ${connection.channelId}, UID: ${connection.localUid}, Elapsed: ${elapsed}ms', name: 'BroadcastPage');
            if (mounted) {
              setState(() {
                _localUserJoined = true;
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Agora error: $err - $msg'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      );

      // Set client role (as per latest Agora example)
      if (widget.isBroadcaster) {
        developer.log('🎥 [Broadcast] Setting client role to Broadcaster...', name: 'BroadcastPage');
        await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      } else {
        developer.log('👂 [Broadcast] Setting client role to Audience...', name: 'BroadcastPage');
        await engine.setClientRole(role: ClientRoleType.clientRoleAudience);
      }
      developer.log('✅ [Broadcast] Client role set', name: 'BroadcastPage');

      // Enable video (as per latest Agora example)
      developer.log('📹 [Broadcast] Enabling video...', name: 'BroadcastPage');
      await engine.enableVideo();
      developer.log('✅ [Broadcast] Video enabled', name: 'BroadcastPage');

      // Start preview for broadcaster (as per latest Agora example)
      if (widget.isBroadcaster) {
        developer.log('📹 [Broadcast] Starting preview...', name: 'BroadcastPage');
        await engine.startPreview();
        developer.log('✅ [Broadcast] Preview started', name: 'BroadcastPage');
      }

      // Join channel (optionally with token from API when AGORA_APP_CERTIFICATE is set)
      developer.log('🚪 [Broadcast] Joining channel: ${widget.liveStream.channel}...', name: 'BroadcastPage');
      String token = '';
      try {
        final config = AppConfig.fromEnv();
        final baseUrl = config.baseUrl.replaceFirst(RegExp(r'/$'), '');
        if (baseUrl.isNotEmpty) {
          final liveApi = LiveApi(baseUrl: baseUrl, debugPrintRequest: false);
          final result = await liveApi.getRtcToken(
            channelName: widget.liveStream.channel,
            role: widget.isBroadcaster ? 'publisher' : 'audience',
            uid: 0,
          );
          if (result?.token != null && result!.token!.isNotEmpty) {
            token = result.token!;
            developer.log('🔑 [Broadcast] Using RTC token from API', name: 'BroadcastPage');
          }
        }
      } catch (e) {
        developer.log('⚠️ [Broadcast] Token fetch failed, using empty token: $e', name: 'BroadcastPage');
      }

      // Broadcaster uses UID 0; each audience member uses a unique random UID to avoid collisions.
      final localUid = widget.isBroadcaster
          ? 0
          : DateTime.now().millisecondsSinceEpoch.remainder(1000000000);

      await engine.joinChannel(
        token: token,
        channelId: widget.liveStream.channel,
        uid: localUid,
        options: const ChannelMediaOptions(),
      );
      developer.log('✅ [Broadcast] Join channel request sent', name: 'BroadcastPage');
      _isInitializing = false;
    } catch (e, stackTrace) {
      _isInitializing = false;
      developer.log('❌ [Broadcast] Error initializing Agora: $e', name: 'BroadcastPage', error: e, stackTrace: stackTrace);
      
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
            content: Text('Failed to initialize live stream: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Live Stream'),
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
            onStreamEnded: () {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Stream ended')),
                );
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _toolbar() {
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
        // Main video layout (local + remotes)
        SizedBox.expand(
          child: _videoLayout(),
        ),
        // Local user picture-in-picture when broadcaster has remote viewers
        if (widget.isBroadcaster &&
            _localUserJoined &&
            _engine != null &&
            _remoteUids.isNotEmpty)
          Positioned(
            top: 20,
            left: 20,
            child: SizedBox(
              width: 100,
              height: 150,
              child: AgoraVideoView(
                controller: VideoViewController(
                  rtcEngine: _engine!,
                  canvas: const VideoCanvas(uid: 0),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Layout local + remote videos according to number of participants
  Widget _videoLayout() {
    if (_engine == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Broadcaster alone: show local video full screen
    if (widget.isBroadcaster && _localUserJoined && _remoteUids.isEmpty) {
      return AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: _engine!,
          canvas: const VideoCanvas(uid: 0),
        ),
      );
    }

    // Audience waiting for broadcaster (or no remotes yet)
    if (_remoteUids.isEmpty) {
      return const Center(
        child: Text(
          'Waiting for remote users to join...',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    final remotes = List<int>.from(_remoteUids);

    // 1 user → full screen
    if (remotes.length == 1) {
      return _remoteTile(remotes[0]);
    }

    // 2 users → half + half (vertical split)
    if (remotes.length == 2) {
      return Column(
        children: [
          Expanded(child: _remoteTile(remotes[0])),
          Expanded(child: _remoteTile(remotes[1])),
        ],
      );
    }

    // 3 users → top row (2 x 1/4) + bottom (1 x 1/2)
    if (remotes.length == 3) {
      return Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _remoteTile(remotes[0])),
                Expanded(child: _remoteTile(remotes[1])),
              ],
            ),
          ),
          Expanded(
            child: _remoteTile(remotes[2]),
          ),
        ],
      );
    }

    // 4+ users – simple 2x2 grid of first 4 (fallback layout)
    final visible = remotes.take(4).toList();
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: _remoteTile(visible[0])),
              if (visible.length > 1) Expanded(child: _remoteTile(visible[1])),
            ],
          ),
        ),
        if (visible.length > 2)
          Expanded(
            child: Row(
              children: [
                Expanded(child: _remoteTile(visible[2])),
                if (visible.length > 3)
                  Expanded(child: _remoteTile(visible[3])),
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
