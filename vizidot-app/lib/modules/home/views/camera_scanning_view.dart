import 'dart:async';
import 'dart:io';
import 'package:arkit_plugin/arkit_plugin.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../../core/utils/encryption_utils.dart';
import '../controllers/home_controller.dart';

class CameraScanningView extends StatefulWidget {
  const CameraScanningView({super.key});

  @override
  State<CameraScanningView> createState() => _CameraScanningViewState();
}

class _CameraScanningViewState extends State<CameraScanningView> {
  ARKitController? arkitController;
  bool anchorWasFound = false;
  List<ARKitReferenceImage>? images = [];
  bool isLoading = true;
  bool shouldRebuildArkit = true;
  final arkitKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    fetch();
  }

  Future<void> fetch() async {
    try {
      setState(() {
        isLoading = true;
      });

      final CollectionReference collectionReference =
          FirebaseFirestore.instance.collection("Artists");
      QuerySnapshot querySnapShot = await collectionReference.get();
      
      final allData = querySnapShot.docs
          .map((docSnapshot) => docSnapshot.data() as Map<String, dynamic>)
          .toList();

      List<ARKitReferenceImage> scanImages = [];

      for (var element in allData) {
        final scanImage = element['scanImage'] as String?;
        if (scanImage != null && scanImage.isNotEmpty) {
          try {
            // Use DefaultCacheManager to get the cached file
            final File cachedFile =
                await DefaultCacheManager().getSingleFile(scanImage);

            if (cachedFile.existsSync()) {
              final uri = Uri.parse(scanImage);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString(
                encryptMyData(cachedFile.path),
                uri.path,
              );
              
              // Create ARKitReferenceImage using the cached file path
              scanImages.add(
                ARKitReferenceImage(
                  name: cachedFile.path,
                  physicalWidth: 0.8,
                ),
              );
            }
          } catch (e) {
            debugPrint("Failed to cache image: $scanImage - Error: $e");
          }
        }
      }

      if (mounted) {
        setState(() {
          images = scanImages;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching artists: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> addToELocker(String artistId) async {
    try {
      // Get current user ID from Firebase Auth
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        Fluttertoast.showToast(msg: 'Please login to save artists');
        return;
      }

      // Check if artist already exists in user's ELocker
      final elockerQuery = await FirebaseFirestore.instance
          .collection("Elocker")
          .where("artistId", isEqualTo: artistId)
          .where("userId", isEqualTo: currentUser.uid)
          .get();

      if (elockerQuery.docs.isEmpty) {
        // Fetch artist data
        final artistDoc = await FirebaseFirestore.instance
            .collection("Artists")
            .doc(artistId)
            .get();

        if (artistDoc.exists) {
          final artistData = artistDoc.data() as Map<String, dynamic>;
          
          // Create ELocker entry
          final elockerData = {
            "artistId": artistId,
            "name": artistData['name'] ?? '',
            "desc": artistData['desc'] ?? artistData['bio'] ?? '',
            "photo": artistData['photo'] ?? artistData['image_url'] ?? '',
            "userId": currentUser.uid,
            "email": currentUser.email ?? '',
            "createdAt": FieldValue.serverTimestamp(),
          };

          await FirebaseFirestore.instance
              .collection("Elocker")
              .add(elockerData);

          Fluttertoast.showToast(msg: 'Saved Successfully!');
          
          if (mounted) {
            setState(() {
              shouldRebuildArkit = true;
            });
          }
        }
      } else {
        // Artist already exists
        final artistDoc = await FirebaseFirestore.instance
            .collection("Artists")
            .doc(artistId)
            .get();
        
        if (artistDoc.exists) {
          final artistData = artistDoc.data() as Map<String, dynamic>;
          final artistName = artistData['name'] ?? 'Artist';
          
          // Show dialog
          showCupertinoDialog(
            context: context,
            builder: (BuildContext context) {
              return CupertinoAlertDialog(
                title: Text(artistName),
                content: Text(
                  "$artistName already exists in your eLocker. Do you want to view your eLocker?",
                ),
                actions: [
                  CupertinoDialogAction(
                    child: const Text("Cancel"),
                    onPressed: () {
                      if (mounted) {
                        setState(() {
                          shouldRebuildArkit = true;
                        });
                      }
                      Navigator.of(context).pop();
                    },
                  ),
                  CupertinoDialogAction(
                    child: const Text("Yes"),
                    onPressed: () {
                      if (mounted) {
                        setState(() {
                          shouldRebuildArkit = true;
                        });
                      }
                      Navigator.of(context).pop();
                      // Navigate to ELocker (index 1 in home view)
                      final homeController = Get.find<HomeController>();
                      homeController.onNavTap(1);
                    },
                  ),
                ],
              );
            },
          );
        }
      }
    } catch (e) {
      debugPrint("Error adding to ELocker: $e");
      Fluttertoast.showToast(msg: 'Error saving artist');
    }
  }

  @override
  void dispose() {
    arkitController?.dispose();
    images = [];
    super.dispose();
  }

  void onARKitViewCreated(ARKitController controller) {
    arkitController = controller;
    arkitController!.onAddNodeForAnchor = onAnchorWasFound;
  }

  void onAnchorWasFound(ARKitAnchor anchor) async {
    if (anchor is ARKitImageAnchor && anchor.referenceImageName != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final encryptedPath = encryptMyData(anchor.referenceImageName!);
        final path = prefs.getString(encryptedPath);
        
        if (path != null) {
          final artistId = getFileName(path);
          addToELocker(artistId);
          
          // Temporarily remove the ARKitSceneView
          if (mounted) {
            setState(() {
              shouldRebuildArkit = false;
            });
          }
        }
      } catch (e) {
        debugPrint("Error processing anchor: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return CupertinoPageScaffold(
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ARKit Scene View
            if (images!.isNotEmpty && shouldRebuildArkit && !isLoading)
              ARKitSceneView(
                key: arkitKey,
                trackingImages: images,
                onARKitViewCreated: onARKitViewCreated,
                worldAlignment: ARWorldAlignment.camera,
                configuration: ARKitConfiguration.imageTracking,
              )
            else if (isLoading)
              const Center(
                child: CupertinoActivityIndicator(),
              )
            else
              Container(
                color: Colors.black,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.camera_fill,
                        size: 80,
                        color: colors.surface.withOpacity(0.5),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No scan images available',
                        style: textTheme.headlineSmall?.copyWith(
                          color: colors.surface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Instruction text overlay
            if (!anchorWasFound && !isLoading)
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Point the camera at images',
                      style: textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
