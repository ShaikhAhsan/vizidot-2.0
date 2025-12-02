import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;
import '../models/live_stream_model.dart';
import '../../../core/utils/agora.dart';

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

      // Join channel (as per latest Agora example)
      developer.log('🚪 [Broadcast] Joining channel: ${widget.liveStream.channel}...', name: 'BroadcastPage');
      await engine.joinChannel(
        token: '', // Empty token for development (use proper token in production)
        channelId: widget.liveStream.channel,
        uid: 0,
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
        // Remote users video (full screen)
        Center(
          child: _remoteVideo(),
        ),
        // Local user video (top left corner for broadcaster)
        if (widget.isBroadcaster && _localUserJoined && _engine != null)
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

  // Display remote user's video
  Widget _remoteVideo() {
    if (_engine == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (_remoteUids.isEmpty) {
      return const Center(
        child: Text(
          'Waiting for remote users to join...',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    // Display first remote user (can be extended to show multiple)
    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: _engine!,
        canvas: VideoCanvas(uid: _remoteUids[0]),
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
