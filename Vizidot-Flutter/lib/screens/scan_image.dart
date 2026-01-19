import 'dart:async';
import 'dart:io';
import 'package:arkit_plugin/arkit_plugin.dart';
import 'package:bmprogresshud/progresshud.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:vizidot_flutter/constants.dart';
import 'package:vizidot_flutter/models/FirUser.dart';
import 'package:vizidot_flutter/models/artists.dart';
import 'package:vizidot_flutter/models/elocker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:vizidot_flutter/utils/shared_prefrence.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ImageDetectionPage extends StatefulWidget {
  final void Function(int) changePage;

  const ImageDetectionPage({Key? key, required this.changePage})
      : super(key: key);

  @override
  _ImageDetectionPageState createState() => _ImageDetectionPageState();
}

class _ImageDetectionPageState extends State<ImageDetectionPage> {
  late ARKitController arkitController;
  Timer? timer;
  bool anchorWasFound = false;
  List<ARKitReferenceImage>? images = [];

  // Adding the GlobalKey and the flag
  final arkitKey = GlobalKey();
  bool shouldRebuildArkit = true;

  @override
  void initState() {
    fetch();
    super.initState();
  }

  Future<void> fetch() async {
    final CollectionReference _collectionReference =
        FirebaseFirestore.instance.collection("Artists");
    QuerySnapshot querySnapShot = await _collectionReference.get();
    final allData = querySnapShot.docs
        .map((docSnapshot) => Artist.fromDocumentSnapshot(
            docSnapshot as DocumentSnapshot<Map<String, dynamic>>))
        .toList();

    List<ARKitReferenceImage>? scanImages = [];

    for (var element in allData) {
      if (element.scanImage != null && element.scanImage?.isEmpty == false) {
        // Use DefaultCacheManager to get the cached file.
        final File cachedFile =
            await DefaultCacheManager().getSingleFile(element.scanImage!);

        // DEBUGGING: Print the file path to see if it's correct.
        if (cachedFile != null) {
          print(element.scanImage!);
          final uri = Uri.parse(element.scanImage!);
          SharedPref().save(encryptMyData(cachedFile.path), uri.path);
          // Create ARKitReferenceImage using the cached file path.
          scanImages.add(
              ARKitReferenceImage(name: cachedFile.path, physicalWidth: 0.8));
        } else {
          print("Failed to cache image: ${element.scanImage}");
        }
      }
    }

    if (mounted) {
      setState(() {
        images = scanImages;
      });
    }
  }

  Future<void> addToElcoker(String artistId) async {
    SUser currentUser = SUser.fromJson(await SharedPref().read(kCurrentUser));

    QuerySnapshot querySnapShot = await FirebaseFirestore.instance
        .collection("Elocker")
        .where("artistId", isEqualTo: artistId)
        .where("userId", isEqualTo: currentUser.id)
        .get();
    if (querySnapShot.docs.length == 0) {
      FirebaseFirestore.instance
          .collection("Artists")
          .doc(artistId)
          .snapshots()
          .listen((querySnapShot) {
        Artist artist = Artist.fromDocumentSnapshot(querySnapShot);
        if (mounted) {
          setState(() {
            ElockerModel elocker = ElockerModel(
                id: "",
                artistId: artistId ?? "",
                desc: artist.desc ?? "",
                name: artist.name ?? "",
                fcmToken: currentUser.fcmToken ?? "",
                email: currentUser.email,
                userId: currentUser.id,
                photo: artist?.photo ?? "");
            ProgressHud.showLoading();
            final db = FirebaseFirestore.instance;
            db
                .collection("Elocker")
                .add(elocker.toMap())
                .then((DocumentReference doc) {
              ProgressHud.dismiss();
              Fluttertoast.showToast(msg: 'Saved Successfully!');
              setState(() {
                if (mounted) setState(() {
                  shouldRebuildArkit = true;
                });
                this.widget.changePage(1);

              });
            });
          });
        }
      });
    } else {
      FirebaseFirestore.instance
          .collection("Artists")
          .doc(artistId)
          .snapshots()
          .listen((querySnapShot) {
        Artist artist = Artist.fromDocumentSnapshot(querySnapShot);
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(artist.name),
              content: Text(
                  "${artist.name} already exist in your eLocker. Do you want to move to eLocker?"),
              actions: [
                TextButton(
                  child: Text("Cancel"),
                  onPressed: () {
                    if (mounted) {
                      setState(() {
                        shouldRebuildArkit = true;
                      });
                    }
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text("Yes"),
                  onPressed: () {
                    if (mounted) {
                      setState(() {
                        shouldRebuildArkit = true;
                      });
                    }

                    this.widget.changePage(1);
                    Navigator.of(context).pop(); // Close the dialog
                  },
                ),
              ],
            );
          },
        );
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    arkitController.dispose();
    images = [];
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: getAppBar("Scan Image"),
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: Container(
          child: Stack(
            fit: StackFit.expand,
            children: [
              (images!.length > 0 && shouldRebuildArkit)
                  ? ARKitSceneView(
                      key: arkitKey,
                      trackingImages: images,
                      onARKitViewCreated: onARKitViewCreated,
                      worldAlignment: ARWorldAlignment.camera,
                      configuration: ARKitConfiguration.imageTracking,
                    )
                  : SizedBox(height: 10),
              anchorWasFound
                  ? Container(
                      child: Text(
                        '',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(color: Colors.white),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Point the camera at Images',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(color: Colors.white),
                      ),
                    ),
            ],
          ),
        ),
      ));

  void onARKitViewCreated(ARKitController arkitController) {
    this.arkitController = arkitController;
    this.arkitController.onAddNodeForAnchor = onAnchorWasFound;
  }

  void onAnchorWasFound(ARKitAnchor anchor) async {
    if (anchor is ARKitImageAnchor) {

      String path = await SharedPref()
          .read(encryptMyData(anchor.referenceImageName!) as String);
      addToElcoker(getFileName(path));
      // Temporarily remove the ARKitSceneView
      setState(() {
        shouldRebuildArkit = false;
      });
      DefaultTabController.of(context)?.animateTo(1);
      setState(() => anchorWasFound = false);
    }
  }
}
