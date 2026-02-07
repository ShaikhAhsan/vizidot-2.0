import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/utils/encryption_utils.dart';
import '../controllers/home_controller.dart';

// Platform-specific imports
import 'package:arkit_plugin/arkit_plugin.dart';

class CameraScanningView extends StatefulWidget {
  const CameraScanningView({super.key});

  @override
  State<CameraScanningView> createState() => _CameraScanningViewState();
}

class _CameraScanningViewState extends State<CameraScanningView> {
  // iOS ARKit
  ARKitController? arkitController;
  List<ARKitReferenceImage>? arkitImages = [];
  final arkitKey = GlobalKey();
  
  // Android Camera
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  Timer? _scanTimer;
  bool _isScanning = false;
  bool _isCapturing = false; // Prevent concurrent captures
  final Map<String, img.Image> _referenceImages = {};
  
  // AR Overlay state
  String? detectedLogoName;
  bool isTracking = false;
  Rect? detectedLogoRect; // Position of detected logo for AR overlay
  
  // Common
  bool anchorWasFound = false;
  bool isLoading = true;
  bool shouldRebuild = true;
  
  // Image name mapping for detection
  final Map<String, String> _imageNameMap = {};

  bool get _isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  bool get _isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    fetch();
    if (_isAndroid) {
      _initializeCamera();
    }
  }
  
  Future<void> _initializeCamera() async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
        return;
      }
      
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
        return;
      }
      
      _cameraController = CameraController(
        _cameras![0],
        ResolutionPreset.high,
        enableAudio: false,
      );
      
      await _cameraController!.initialize();
      
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        
        debugPrint("📊 Camera initialized. Reference images: ${_referenceImages.length}");
        
        if (_referenceImages.isNotEmpty) {
          debugPrint("🚀 Starting scanning after camera init...");
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (mounted) {
              _startScanning();
            }
          });
        } else {
          debugPrint("⚠️ No reference images loaded, cannot start scanning");
        }
      }
    } catch (e) {
      debugPrint("Error initializing camera: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
  
  void _startScanning() {
    if (_isScanning) {
      debugPrint("⚠️ Already scanning, skipping start");
      return;
    }
    
    if (_referenceImages.isEmpty) {
      debugPrint("❌ Cannot start scanning: No reference images loaded");
      return;
    }
    
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      debugPrint("❌ Cannot start scanning: Camera not initialized");
      return;
    }
    
    _isScanning = true;
    debugPrint("🚀 Started scanning with ${_referenceImages.length} reference images");
    
    _scanTimer = Timer.periodic(const Duration(milliseconds: 2000), (timer) {
      if (!_isScanning) {
        debugPrint("⏹️ Scanning stopped");
        timer.cancel();
        return;
      }
      
      if (_cameraController == null || !_cameraController!.value.isInitialized) {
        debugPrint("⚠️ Camera not available, skipping capture");
        return;
      }
      
      if (anchorWasFound) {
        debugPrint("⏸️ Logo already detected, pausing scanning");
        return;
      }
      
      debugPrint("📸 Capturing frame for detection...");
      _captureAndDetect();
    });
  }
  
  void _stopScanning() {
    _isScanning = false;
    _scanTimer?.cancel();
    _scanTimer = null;
  }
  
  Future<void> _captureAndDetect() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || anchorWasFound || _isCapturing) {
      if (_isCapturing) {
        debugPrint("⚠️ Skipping capture: already capturing");
      } else {
        debugPrint("⚠️ Skipping capture: camera=${_cameraController != null}, initialized=${_cameraController?.value.isInitialized}, anchorFound=$anchorWasFound");
      }
      return;
    }
    
    _isCapturing = true;
    
    try {
      debugPrint("📷 Taking picture...");
      final XFile image = await _cameraController!.takePicture();
      debugPrint("📷 Picture taken: ${image.path}");
      
      final Uint8List imageBytes = await image.readAsBytes();
      debugPrint("📦 Image bytes: ${imageBytes.length}");
      
      final img.Image? capturedImage = img.decodeImage(imageBytes);
      
      if (capturedImage == null) {
        debugPrint("❌ Failed to decode captured image");
        await File(image.path).delete();
        return;
      }
      
      debugPrint("🖼️ Captured image: ${capturedImage.width}x${capturedImage.height}");
      
      // Get camera preview size for coordinate conversion
      final previewSize = _cameraController!.value.previewSize;
      if (previewSize == null) {
        debugPrint("❌ Preview size not available");
        await File(image.path).delete();
        return;
      }
      
      debugPrint("📐 Preview size: ${previewSize.width}x${previewSize.height}");
      debugPrint("🔍 Comparing with ${_referenceImages.length} reference images...");
      
      double bestSimilarity = 0.0;
      String? bestMatch;
      Rect? bestRect;
      
      for (var entry in _referenceImages.entries) {
        debugPrint("🔍 Checking ${entry.key}...");
        final result = _findLogoInImage(capturedImage, entry.value);
        final similarity = result['similarity'] as double;
        
        debugPrint("  Similarity with ${entry.key}: ${(similarity * 100).toStringAsFixed(1)}%");
        
        if (similarity > bestSimilarity) {
          bestSimilarity = similarity;
          bestMatch = entry.key;
          bestRect = result['rect'] as Rect?;
        }
      }
      
      debugPrint("🏆 Best match: $bestMatch with ${(bestSimilarity * 100).toStringAsFixed(1)}% similarity");
      
      // Require higher threshold - if similarity is very high, accept it
      // Lower threshold for very confident matches
      final threshold = bestSimilarity > 0.85 ? 0.85 : 0.65;
      
      if (bestSimilarity > threshold && bestMatch != null && bestRect != null) {
        // Find second best match to ensure we have a clear winner
        double secondBestSimilarity = 0.0;
        for (var entry in _referenceImages.entries) {
          if (entry.key == bestMatch) continue;
          final result = _findLogoInImage(capturedImage, entry.value);
          final similarity = result['similarity'] as double;
          if (similarity > secondBestSimilarity) {
            secondBestSimilarity = similarity;
          }
        }
        
        // Require at least 5% difference to avoid false positives, but also check absolute thresholds
        final difference = bestSimilarity - secondBestSimilarity;
        
        // If best match is very high (>85%) and difference is at least 3%, accept it
        // If best match is moderate (60-85%), require at least 10% difference
        final shouldAccept = (bestSimilarity > 0.85 && difference >= 0.03) || 
                            (bestSimilarity <= 0.85 && difference >= 0.10);
        
        if (!shouldAccept) {
          debugPrint("⚠️ Too close match (best: ${(bestSimilarity * 100).toStringAsFixed(1)}%, second: ${(secondBestSimilarity * 100).toStringAsFixed(1)}%, diff: ${(difference * 100).toStringAsFixed(1)}%)");
          await File(image.path).delete();
          return;
        }
        
        // Convert from captured image coordinates to preview coordinates
        // The captured image is 720x1280 (portrait), preview is 1280x720 (landscape)
        // We need to account for the rotation/transformation
        
        // Simple scaling - preview and captured might have different aspect ratios
        final scaleX = previewSize.width / capturedImage.width;
        final scaleY = previewSize.height / capturedImage.height;
        
        // Use the smaller scale to maintain aspect ratio
        final scale = scaleX < scaleY ? scaleX : scaleY;
        
        // Calculate centered position if aspect ratios differ
        final scaledWidth = capturedImage.width * scale;
        final scaledHeight = capturedImage.height * scale;
        final offsetX = (previewSize.width - scaledWidth) / 2;
        final offsetY = (previewSize.height - scaledHeight) / 2;
        
        // Convert logo position
        final previewLeft = bestRect.left * scale + offsetX;
        final previewTop = bestRect.top * scale + offsetY;
        final previewWidth = bestRect.width * scale;
        final previewHeight = bestRect.height * scale;
        
        final previewRect = Rect.fromLTWH(
          previewLeft.clamp(0, previewSize.width - previewWidth),
          previewTop.clamp(0, previewSize.height - previewHeight),
          previewWidth.clamp(0, previewSize.width - previewLeft),
          previewHeight.clamp(0, previewSize.height - previewTop),
        );
        
        final imageName = _imageNameMap[bestMatch] ?? 'Unknown Image';
        debugPrint("✅✅✅ Android detected: $imageName (similarity: ${(bestSimilarity * 100).toStringAsFixed(1)}%, second: ${(secondBestSimilarity * 100).toStringAsFixed(1)}%, diff: ${(difference * 100).toStringAsFixed(1)}%) at $previewRect");
        _onImageDetected(imageName, imagePath: bestMatch, logoRect: previewRect);
      } else {
        debugPrint("❌ No match found (threshold: 60%, best: ${(bestSimilarity * 100).toStringAsFixed(1)}%)");
      }
      
      await File(image.path).delete();
    } catch (e, stackTrace) {
      debugPrint("❌ Error capturing/detecting image: $e");
      debugPrint("Stack trace: $stackTrace");
    } finally {
      _isCapturing = false;
    }
  }
  
  Map<String, dynamic> _findLogoInImage(img.Image capturedImg, img.Image referenceImg) {
    // Resize reference to a standard size for template matching
    final targetSize = 150;
    final refResized = img.copyResize(referenceImg, width: targetSize, height: targetSize);
    final refGray = img.grayscale(refResized);
    
    // Resize captured image for faster processing
    final scale = 0.5; // Process at 50% resolution for speed
    final capScaled = img.copyResize(
      capturedImg, 
      width: (capturedImg.width * scale).round(),
      height: (capturedImg.height * scale).round(),
    );
    final capScaledGray = img.grayscale(capScaled);
    
    final refScaled = img.copyResize(refGray, width: (targetSize * scale).round(), height: (targetSize * scale).round());
    
    double bestSimilarity = 0.0;
    Rect? bestRect;
    
    // Template matching with sliding window
    final stepX = (refScaled.width * 0.3).round(); // Smaller steps for better accuracy
    final stepY = (refScaled.height * 0.3).round();
    
    // Try different scales to handle size variations
    final scales = [0.6, 0.8, 1.0, 1.2, 1.5];
    
    for (final scaleFactor in scales) {
      final templateWidth = (refScaled.width * scaleFactor).round();
      final templateHeight = (refScaled.height * scaleFactor).round();
      
      if (templateWidth > capScaledGray.width || templateHeight > capScaledGray.height) {
        continue;
      }
      
      final scaledTemplate = img.copyResize(refScaled, width: templateWidth, height: templateHeight);
      
      // Slide window across the image
      for (int startY = 0; startY <= capScaledGray.height - templateHeight; startY += stepY) {
        for (int startX = 0; startX <= capScaledGray.width - templateWidth; startX += stepX) {
          final similarity = _simpleCompareRegion(
            capScaledGray, 
            scaledTemplate, 
            startX, 
            startY,
          );
          
          if (similarity > bestSimilarity) {
            bestSimilarity = similarity;
            // Convert back to original image coordinates
            final originalX = (startX / scale).round();
            final originalY = (startY / scale).round();
            final originalWidth = (templateWidth / scale).round();
            final originalHeight = (templateHeight / scale).round();
            
            bestRect = Rect.fromLTWH(
              originalX.clamp(0, capturedImg.width - originalWidth).toDouble(),
              originalY.clamp(0, capturedImg.height - originalHeight).toDouble(),
              originalWidth.toDouble(),
              originalHeight.toDouble(),
            );
          }
        }
      }
    }
    
    return {
      'similarity': bestSimilarity,
      'rect': bestRect ?? Rect.fromLTWH(0, 0, targetSize.toDouble(), targetSize.toDouble()),
    };
  }
  
  double _simpleCompareRegion(img.Image img1, img.Image template, int startX, int startY) {
    if (startX + template.width > img1.width || startY + template.height > img1.height) {
      return 0.0;
    }
    
    int matchingPixels = 0;
    int totalPixels = template.width * template.height;
    int totalDiff = 0;
    int totalSquaredDiff = 0;
    
    // Calculate mean of template for normalization
    int templateSum = 0;
    for (int y = 0; y < template.height; y++) {
      for (int x = 0; x < template.width; x++) {
        final pixel = template.getPixel(x, y);
        templateSum += pixel.r.toInt();
      }
    }
    final templateMean = templateSum / totalPixels;
    
    // Calculate mean of image region
    int regionSum = 0;
    for (int y = 0; y < template.height && startY + y < img1.height; y++) {
      for (int x = 0; x < template.width && startX + x < img1.width; x++) {
        final pixel = img1.getPixel(startX + x, startY + y);
        regionSum += pixel.r.toInt();
      }
    }
    final regionMean = regionSum / totalPixels;
    
    // Normalized comparison
    for (int y = 0; y < template.height; y++) {
      for (int x = 0; x < template.width; x++) {
        if (startX + x < img1.width && startY + y < img1.height) {
          final pixel1 = img1.getPixel(startX + x, startY + y);
          final pixel2 = template.getPixel(x, y);
          
          final val1 = pixel1.r.toInt() - regionMean;
          final val2 = pixel2.r.toInt() - templateMean;
          
          final diff = (val1 - val2).abs();
          totalDiff += diff.toInt();
          totalSquaredDiff += (diff * diff).toInt();
          
          if (diff <= 40) { // Tighter threshold for better accuracy
            matchingPixels++;
          }
        }
      }
    }
    
    final avgDiff = totalDiff / totalPixels;
    final avgSquaredDiff = totalSquaredDiff / totalPixels;
    final variance = avgSquaredDiff - (avgDiff * avgDiff);
    
    // Use variance for better matching (lower variance = better match)
    final varianceScore = 1.0 - (variance / (255.0 * 255.0));
    final diffScore = 1.0 - (avgDiff / 255.0);
    final matchScore = matchingPixels / totalPixels;
    
    // Weighted combination - emphasize variance and match score
    return (varianceScore * 0.4 + diffScore * 0.3 + matchScore * 0.3).clamp(0.0, 1.0);
  }
  
  Future<void> fetch() async {
    try {
      setState(() {
        isLoading = true;
      });

      // Load reference images from assets
      await _loadReferenceImages();

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching images: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadReferenceImages() async {
    if (_isIOS) {
      await _loadARKitImages();
    } else if (_isAndroid) {
      await _loadAndroidReferenceImages();
    }
  }
  
  Future<void> _loadAndroidReferenceImages() async {
    try {
      debugPrint("🔄 Starting to load Android reference images...");
      
      // Load Coca-Cola logo
      final ByteData cocaColaData = await rootBundle.load('assets/scaning-images/coca-cola.jpg');
      final Uint8List cocaColaBytes = cocaColaData.buffer.asUint8List();
      debugPrint("📦 Loaded Coca-Cola bytes: ${cocaColaBytes.length}");
      
      final img.Image? cocaColaImage = img.decodeImage(cocaColaBytes);
      
      if (cocaColaImage != null) {
        _referenceImages['coca-cola'] = cocaColaImage;
        _imageNameMap['coca-cola'] = 'Coca-Cola';
        debugPrint("✅ Loaded Android reference image: Coca-Cola (${cocaColaImage.width}x${cocaColaImage.height})");
      } else {
        debugPrint("❌ Failed to decode Coca-Cola image");
      }
      
      // Load Pepsi logo
      final ByteData pepsiData = await rootBundle.load('assets/scaning-images/pepsi.jpeg');
      final Uint8List pepsiBytes = pepsiData.buffer.asUint8List();
      debugPrint("📦 Loaded Pepsi bytes: ${pepsiBytes.length}");
      
      final img.Image? pepsiImage = img.decodeImage(pepsiBytes);
      
      if (pepsiImage != null) {
        _referenceImages['pepsi'] = pepsiImage;
        _imageNameMap['pepsi'] = 'Pepsi';
        debugPrint("✅ Loaded Android reference image: Pepsi (${pepsiImage.width}x${pepsiImage.height})");
      } else {
        debugPrint("❌ Failed to decode Pepsi image");
      }
      
      debugPrint("📊 Android: ${_referenceImages.length} reference images loaded.");
      debugPrint("📊 Camera controller state: ${_cameraController?.value.isInitialized}");
      
      if (mounted && _cameraController != null && _cameraController!.value.isInitialized) {
        debugPrint("🚀 Starting scanning in 500ms...");
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _startScanning();
          }
        });
      } else {
        debugPrint("⚠️ Camera not ready yet, will start scanning when ready");
      }
    } catch (e, stackTrace) {
      debugPrint("❌ Failed to load Android reference images: $e");
      debugPrint("Stack trace: $stackTrace");
    }
  }

  Future<void> _loadARKitImages() async {
    // Load reference images from assets (Coca-Cola and Pepsi)
    List<ARKitReferenceImage> scanImages = [];

    try {
      // Load Coca-Cola logo
      final ByteData cocaColaData = await rootBundle.load('assets/scaning-images/coca-cola.jpg');
      final Uint8List cocaColaBytes = cocaColaData.buffer.asUint8List();
      
      // Save to temp file for ARKit
      final tempDir = Directory.systemTemp;
      final cocaColaFile = File('${tempDir.path}/coca-cola.jpg');
      await cocaColaFile.writeAsBytes(cocaColaBytes);
      
      if (cocaColaFile.existsSync()) {
        _imageNameMap[cocaColaFile.path] = 'Coca-Cola';
        scanImages.add(
          ARKitReferenceImage(
            name: cocaColaFile.path,
            physicalWidth: 0.2,
          ),
        );
        debugPrint("✅ Loaded ARKit reference image: Coca-Cola");
      }
      
      // Load Pepsi logo
      final ByteData pepsiData = await rootBundle.load('assets/scaning-images/pepsi.jpeg');
      final Uint8List pepsiBytes = pepsiData.buffer.asUint8List();
      
      final pepsiFile = File('${tempDir.path}/pepsi.jpeg');
      await pepsiFile.writeAsBytes(pepsiBytes);
      
      if (pepsiFile.existsSync()) {
        _imageNameMap[pepsiFile.path] = 'Pepsi';
        scanImages.add(
          ARKitReferenceImage(
            name: pepsiFile.path,
            physicalWidth: 0.2,
          ),
        );
        debugPrint("✅ Loaded ARKit reference image: Pepsi");
      }
      
      debugPrint("iOS ARKit: ${scanImages.length} reference images loaded from assets.");
    } catch (e) {
      debugPrint("❌ Failed to load ARKit reference images from assets: $e");
    }

    if (mounted) {
      setState(() {
        arkitImages = scanImages;
      });
    }
  }

  void _onImageDetected(String imageName, {String? imagePath, Rect? logoRect}) {
    if (mounted && !anchorWasFound) {
      setState(() {
        anchorWasFound = true;
        detectedLogoName = imageName;
        detectedLogoRect = logoRect;
        isTracking = true;
      });
      
      // Show toast
      Fluttertoast.showToast(
        msg: 'Detected: $imageName',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      
      // Add AR text overlay showing the logo name
      _addARTextOverlay(imageName);
      
      // Reset after 5 seconds to allow re-scanning
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            anchorWasFound = false;
            detectedLogoName = null;
            detectedLogoRect = null;
            isTracking = false;
            shouldRebuild = true;
          });
          _removeARTextOverlay();
          // Resume scanning on Android
          if (_isAndroid) {
            _startScanning();
          }
        }
      });
      
      // Stop scanning temporarily on Android to avoid duplicate detections
      if (_isAndroid) {
        _stopScanning();
      }

      // If we have an image path, try to add to ELocker
      if (imagePath != null) {
        final prefs = SharedPreferences.getInstance();
        prefs.then((prefs) async {
          final encryptedPath = encryptMyData(imagePath);
          final path = prefs.getString(encryptedPath);
          
          if (path != null) {
            final artistId = getFileName(path);
            addToELocker(artistId);
          }
        });
      }
    }
  }

  void _addARTextOverlay(String logoName) {
    // AR text overlay is shown via UI overlay, not 3D text node
    // This avoids complex 3D positioning issues
    debugPrint("✅ Showing AR text overlay: $logoName");
  }

  void _removeARTextOverlay() {
    // AR text overlay is removed via UI state
    debugPrint("✅ Removed AR text overlay");
  }

  Future<void> addToELocker(String artistId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        Fluttertoast.showToast(msg: 'Please login to save artists');
        return;
      }

      final elockerQuery = await FirebaseFirestore.instance
          .collection("Elocker")
          .where("artistId", isEqualTo: artistId)
          .where("userId", isEqualTo: currentUser.uid)
          .get();

      if (elockerQuery.docs.isEmpty) {
        final artistDoc = await FirebaseFirestore.instance
            .collection("Artists")
            .doc(artistId)
            .get();

        if (artistDoc.exists) {
          final artistData = artistDoc.data() as Map<String, dynamic>;
          
          final elockerData = {
            "artistId": artistId,
            "name": artistData['name'] ?? '',
            "desc": artistData['desc'] ?? artistData['bio'] ?? '',
            "photo": artistData['photo'] ?? artistData['image_url'] ?? '',
            "userId": currentUser.uid,
            "email": currentUser.email ?? '',
            "createdAt": FieldValue.serverTimestamp(),
          };

          await FirebaseFirestore.instance.collection("Elocker").add(elockerData);
          Fluttertoast.showToast(msg: 'Saved Successfully!');
          
          if (mounted) {
            setState(() {
              shouldRebuild = true;
            });
          }
        }
      } else {
        final artistDoc = await FirebaseFirestore.instance
            .collection("Artists")
            .doc(artistId)
            .get();
        
        if (artistDoc.exists) {
          final artistData = artistDoc.data() as Map<String, dynamic>;
          final artistName = artistData['name'] ?? 'Artist';
          
          if (mounted) {
            showCupertinoDialog(
              context: context,
              builder: (BuildContext dialogContext) {
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
                            shouldRebuild = true;
                          });
                        }
                        Navigator.of(dialogContext).pop();
                      },
                    ),
                    CupertinoDialogAction(
                      child: const Text("Yes"),
                      onPressed: () {
                        if (mounted) {
                          setState(() {
                            shouldRebuild = true;
                          });
                        }
                        Navigator.of(dialogContext).pop();
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
      }
    } catch (e) {
      debugPrint("Error adding to ELocker: $e");
      Fluttertoast.showToast(msg: 'Error saving artist');
    }
  }

  @override
  void dispose() {
    _stopScanning();
    _cameraController?.dispose();
    arkitController?.dispose();
    arkitImages = [];
    _referenceImages.clear();
    super.dispose();
  }

  // iOS ARKit handlers
  void onARKitViewCreated(ARKitController controller) {
    arkitController = controller;
    arkitController!.onAddNodeForAnchor = onARKitAnchorFound;
    arkitController!.onUpdateNodeForAnchor = onARKitAnchorUpdated;
  }

  void onARKitAnchorFound(ARKitAnchor anchor) async {
    if (anchor is ARKitImageAnchor && anchor.referenceImageName != null) {
      try {
        final imagePath = anchor.referenceImageName!;
        final imageName = _imageNameMap[imagePath] ?? 'Unknown Image';
        
        debugPrint("✅ ARKit detected image: $imageName");
        
        _onImageDetected(imageName, imagePath: imagePath);
        
        if (mounted) {
          setState(() {
            shouldRebuild = false;
          });
        }
      } catch (e) {
        debugPrint("Error processing ARKit anchor: $e");
      }
    }
  }

  void onARKitAnchorUpdated(ARKitAnchor anchor) {
    // Update AR overlay position as the image is tracked
    if (anchor is ARKitImageAnchor && anchor.isTracked && isTracking) {
      // The text overlay will follow the tracked image
      // ARKit automatically updates the node position
      debugPrint("🔄 Tracking image: ${anchor.referenceImageName}");
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
            // iOS: ARKit Scene View
            if (_isIOS && arkitImages!.isNotEmpty && shouldRebuild && !isLoading)
              ARKitSceneView(
                key: arkitKey,
                trackingImages: arkitImages,
                onARKitViewCreated: onARKitViewCreated,
                worldAlignment: ARWorldAlignment.camera,
                configuration: ARKitConfiguration.imageTracking,
              )
            // Android: Camera with AR-like image detection
            else if (_isAndroid && !isLoading && _cameraController != null && _cameraController!.value.isInitialized)
              CameraPreview(_cameraController!)
            else if (_isAndroid && !isLoading && _cameraController == null)
              Container(
                color: Colors.black,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.camera_fill,
                          size: 80,
                          color: colors.surface.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Camera Not Available',
                          style: textTheme.headlineSmall?.copyWith(
                            color: colors.surface,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Please grant camera permission to use AR image tracking.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.surface.withValues(alpha: 0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
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
                        color: colors.surface.withValues(alpha: 0.5),
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
            
            // AR Overlay showing detected logo name at exact position (Android)
            if (detectedLogoName != null && isTracking && _isAndroid && detectedLogoRect != null)
              Builder(
                builder: (context) {
                  final screenSize = MediaQuery.of(context).size;
                  final safeArea = MediaQuery.of(context).padding;
                  
                  // Ensure coordinates are within screen bounds
                  final labelLeft = detectedLogoRect!.left.clamp(10.0, screenSize.width - 250);
                  final labelTop = (detectedLogoRect!.top - 70).clamp(safeArea.top + 10, screenSize.height - 120);
                  
                  return Positioned(
                    left: labelLeft,
                    top: labelTop,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 240),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.greenAccent, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withValues(alpha: 0.7),
                            blurRadius: 15,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.check_mark_circled_solid,
                            color: Colors.greenAccent,
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              detectedLogoName!,
                              style: textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.8),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )
            // AR Overlay showing detected logo name (iOS or fallback)
            else if (detectedLogoName != null && isTracking)
              Positioned(
                top: 100,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue, width: 2),
                    ),
                    child: Text(
                      'Detected: $detectedLogoName',
                      style: textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            // AR bounding box showing detected logo position (Android)
            if (detectedLogoName != null && isTracking && _isAndroid && detectedLogoRect != null)
              Builder(
                builder: (context) {
                  final screenSize = MediaQuery.of(context).size;
                  
                  // Ensure bounding box is within screen bounds
                  final boxLeft = detectedLogoRect!.left.clamp(0.0, screenSize.width - 50);
                  final boxTop = detectedLogoRect!.top.clamp(0.0, screenSize.height - 50);
                  final boxWidth = detectedLogoRect!.width.clamp(50.0, screenSize.width - boxLeft).toDouble();
                  final boxHeight = detectedLogoRect!.height.clamp(50.0, screenSize.height - boxTop).toDouble();
                  
                  return Positioned(
                    left: boxLeft,
                    top: boxTop,
                    child: Container(
                      width: boxWidth,
                      height: boxHeight,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.greenAccent, width: 4),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withValues(alpha: 0.8),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  );
                },
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Point the camera at logos',
                          style: textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_isIOS && arkitImages!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Scanning for: ${arkitImages!.map((img) => _imageNameMap[img.name] ?? 'Unknown').join(', ')}',
                              style: textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        if (_isAndroid && _referenceImages.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Scanning for: ${_referenceImages.keys.map((key) => _imageNameMap[key] ?? 'Unknown').join(', ')}',
                              style: textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                              textAlign: TextAlign.center,
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
    );
  }
}
