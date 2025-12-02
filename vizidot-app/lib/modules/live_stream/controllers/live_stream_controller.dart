import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:developer' as developer;
import '../models/live_stream_model.dart';
import '../views/broadcast_page.dart';
import '../../music_player/controllers/music_player_controller.dart';

class LiveStreamController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

      // Use user data directly from login (no Firestore fetch needed)
      final artistId = user.uid; // Use user UID as artistId/channel
      final now = DateTime.now().millisecondsSinceEpoch;

      developer.log('📺 [LiveStream] Creating live stream model...', name: 'LiveStreamController');
      developer.log('📺 [LiveStream] Channel: $artistId', name: 'LiveStreamController');
      developer.log('📺 [LiveStream] Name: ${user.displayName ?? 'Live Stream'}', name: 'LiveStreamController');

      // Create live stream using user data from login
      final liveStream = LiveStreamModel(
        name: user.displayName ?? 'Live Stream',
        photo: user.photoURL ?? '',
        desc: '',
        identifier: '',
        dateAdded: now,
        channel: artistId,
        dateUpdated: now + 30000,
      );

      // Add to Firestore
      developer.log('💾 [LiveStream] Adding live stream to Firestore...', name: 'LiveStreamController');
      final docRef = await _firestore.collection('LiveStreams').add(liveStream.toMap());
      liveStream.identifier = docRef.id;
      developer.log('✅ [LiveStream] Live stream created with ID: ${liveStream.identifier}', name: 'LiveStreamController');

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

}

