import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:developer' as developer;
import '../models/live_stream_model.dart';
import '../views/broadcast_page.dart';
import '../../music_player/controllers/music_player_controller.dart';
import '../../../core/utils/app_config.dart';
import '../../../core/utils/selected_artist_service.dart';
import '../../../core/network/apis/notifications_api.dart';

class LiveStreamController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Make image URL absolute when relative. baseUrl has no trailing slash.
  String _absoluteImageUrl(String? url, String baseUrl) {
    if (url == null || url.trim().isEmpty) return '';
    final u = url.trim();
    if (u.startsWith('http://') || u.startsWith('https://')) return u;
    return baseUrl + (u.startsWith('/') ? u : '/$u');
  }

  Future<void> startLiveStream() async {
    developer.log('🎥 [LiveStream] Starting live stream...', name: 'LiveStreamController');
    try {
      // Request permissions
      developer.log('📷 [LiveStream] Requesting camera and microphone permissions...', name: 'LiveStreamController');
      final permissions = await [Permission.camera, Permission.microphone].request();
      
      final cameraStatus = permissions[Permission.camera] ?? PermissionStatus.denied;
      final microphoneStatus = permissions[Permission.microphone] ?? PermissionStatus.denied;
      
      developer.log('📷 [LiveStream] Camera status: ${cameraStatus.toString()}', name: 'LiveStreamController');
      developer.log('🎤 [LiveStream] Microphone status: ${microphoneStatus.toString()}', name: 'LiveStreamController');

      // If permanently denied, open settings
      if (cameraStatus.isPermanentlyDenied || microphoneStatus.isPermanentlyDenied) {
        developer.log('❌ [LiveStream] Permissions permanently denied', name: 'LiveStreamController');
        Get.snackbar(
          'Permissions Required',
          'Please enable camera and microphone permissions in Settings to start a live stream.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
        await Future.delayed(const Duration(seconds: 1));
        await openAppSettings();
        return;
      }

      // Check if permissions are granted
      if (!cameraStatus.isGranted || !microphoneStatus.isGranted) {
        developer.log('❌ [LiveStream] Permissions not granted', name: 'LiveStreamController');
        Get.snackbar(
          'Permissions Required',
          'Camera and microphone permissions are required to start a live stream.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
        return;
      }

      developer.log('✅ [LiveStream] Permissions granted', name: 'LiveStreamController');

      final user = _auth.currentUser;
      if (user == null) {
        developer.log('❌ [LiveStream] User not authenticated', name: 'LiveStreamController');
        Get.snackbar(
          'Authentication Required',
          'Please sign in to start a live stream.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      developer.log('👤 [LiveStream] User authenticated: ${user.uid}', name: 'LiveStreamController');

      // Only artists can start a live stream (use artist detail, not user detail)
      if (!Get.isRegistered<SelectedArtistService>()) {
        developer.log('❌ [LiveStream] SelectedArtistService not registered', name: 'LiveStreamController');
        Get.snackbar(
          'Artist required',
          'Only artists can start a live stream. Link an artist to your account first.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      final artist = Get.find<SelectedArtistService>().selectedArtist;
      if (artist == null) {
        developer.log('❌ [LiveStream] No assigned artist', name: 'LiveStreamController');
        Get.snackbar(
          'Artist required',
          'Only artists can start a live stream. Link an artist to your account first.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final config = AppConfig.fromEnv();
      final baseUrl = config.baseUrl.replaceFirst(RegExp(r'/$'), '');

      // Use global selected artist (from settings API); only artists can broadcast
      int streamArtistId = artist.artistId;
      String streamArtistName = artist.name;
      String displayName = artist.name;
      String imageUrl = user.photoURL ?? '';
      if (artist.imageUrl != null && artist.imageUrl!.trim().isNotEmpty) {
        imageUrl = _absoluteImageUrl(artist.imageUrl, baseUrl);
      }

      // broadcasterUid: artist id (string) when artist, else Firebase UID — so "Streaming now" can filter
      final broadcasterUidValue = streamArtistId > 0 ? streamArtistId.toString() : user.uid;

      developer.log('📺 [LiveStream] Creating live stream model...', name: 'LiveStreamController');
      developer.log('📺 [LiveStream] Name: $displayName, photo length: ${imageUrl.length}', name: 'LiveStreamController');
      developer.log('📺 [LiveStream] broadcasterUid: $broadcasterUidValue, artistId: $streamArtistId', name: 'LiveStreamController');

      final liveStream = LiveStreamModel(
        name: displayName,
        photo: imageUrl,
        desc: '',
        identifier: '', // Set after Firestore add
        dateAdded: now,
        channel: '', // Set after Firestore add (unique channel = doc id)
        dateUpdated: now + 30000,
        broadcasterUid: broadcasterUidValue,
        artistId: streamArtistId,
        artistName: streamArtistName,
      );

      // Add to Firestore (channel and identifier set after we have doc id)
      developer.log('💾 [LiveStream] Adding live stream to Firestore...', name: 'LiveStreamController');
      final docRef = await _firestore.collection('LiveStreams').add(liveStream.toMap());
      liveStream.identifier = docRef.id;
      liveStream.channel = docRef.id; // Unique Agora channel per stream (max 64 bytes; Firestore id is 20 chars)
      await docRef.update(liveStream.toMap());
      developer.log('✅ [LiveStream] Live stream created with ID: ${liveStream.identifier}, channel: ${liveStream.channel}', name: 'LiveStreamController');

      // Notify everyone except the broadcaster (push + save to notification history); fire-and-forget
      _notifyLiveStreamStarted(
        liveStreamId: liveStream.identifier,
        artistId: streamArtistId,
        artistName: streamArtistName,
        imageUrl: imageUrl,
      );

      // Pause any playing audio before starting live stream
      try {
        final musicController = Get.find<MusicPlayerController>();
        if (musicController.isPlaying.value) {
          developer.log('🎵 [LiveStream] Pausing music player before live stream...', name: 'LiveStreamController');
          await musicController.pause();
        }
      } catch (e) {
        developer.log('⚠️ [LiveStream] Music player not available: $e', name: 'LiveStreamController');
      }

      // Navigate to broadcast page
      developer.log('🚀 [LiveStream] Navigating to broadcast page...', name: 'LiveStreamController');
      Get.to(() => BroadcastPage(
        isBroadcaster: true,
        liveStream: liveStream,
      ));
    } catch (e, stackTrace) {
      developer.log('❌ [LiveStream] Error: $e', name: 'LiveStreamController', error: e, stackTrace: stackTrace);
      Get.snackbar(
        'Error',
        'Failed to start live stream: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Calls API to send live stream push to everyone except the artist and record in notification history.
  void _notifyLiveStreamStarted({
    required String liveStreamId,
    required int artistId,
    required String artistName,
    required String imageUrl,
  }) {
    final user = _auth.currentUser;
    if (user == null) return;
    user.getIdToken().then((token) async {
      if (token == null || token.isEmpty) return;
      final config = AppConfig.fromEnv();
      final baseUrl = config.baseUrl.replaceFirst(RegExp(r'/$'), '');
      if (baseUrl.isEmpty) return;
      try {
        final api = NotificationsApi(baseUrl: baseUrl, authToken: token, debugPrintRequest: false);
        await api.notifyLiveStream(
          liveStreamId: liveStreamId,
          artistId: artistId,
          artistName: artistName,
          imageUrl: imageUrl.isEmpty ? null : imageUrl,
        );
      } catch (_) {}
    });
  }
}

