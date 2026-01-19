import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:bmprogresshud/bmprogresshud.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vizidot_flutter/constants.dart';
import 'package:vizidot_flutter/models/artists.dart';
import 'dart:typed_data';

import 'package:vizidot_flutter/models/videos.dart';
import 'package:vizidot_flutter/utils/ButtonWidget.dart';
import 'package:vizidot_flutter/utils/PhotoWidget.dart';
import 'package:vizidot_flutter/utils/TextFieldWidget.dart';
import 'package:vizidot_flutter/utils/VideoWidget.dart';

class AddVideo extends StatefulWidget {
  late Video? video;
  late Artist? artist;
  late int? index = null;

  AddVideo(this.artist, this.video, this.index);

  @override
  _AddVideoState createState() => _AddVideoState();
}

class _AddVideoState extends State<AddVideo> {
  String imageName = "";
  String imageUrl = "";
  String videoUrl = "";

  @override
  void initState() {
    super.initState();
    imageName = widget?.video?.name?.toString() ?? "";
    imageUrl = widget?.video?.thumb?.toString() ?? "";
    videoUrl = widget?.video?.url?.toString() ?? "";
  }

  Future<String?> uploadFile() async {
    String url = "";
    XFile? image = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image != null) {
      ProgressHud.showLoading(text: "Uploading Image...");
      Uint8List? fileBytes = await image?.readAsBytes();
      String fileName = image.name;
      // Upload file
      UploadTask uploadTask =
          FirebaseStorage.instance.ref('uploads/$fileName').putData(fileBytes!);
      uploadTask.snapshotEvents.listen((TaskSnapshot taskSnapshot) {},
          onError: (error) {
        ProgressHud.dismiss();
        Fluttertoast.showToast(msg: error.toString());
      }, onDone: () {
        print("Image Uploaded");
      });
      await uploadTask.whenComplete(() async {
        url = await uploadTask.snapshot.ref.getDownloadURL();
        Fluttertoast.showToast(msg: 'File added to the library');
        ProgressHud.dismiss();
      });
      return url.toString();
    }
  }

  Future<String?> uploadVideo() async {
    String url = "";
    XFile? image = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (image != null) {
      ProgressHud.showLoading(text: "Uploading Video...");
      Uint8List? fileBytes = await image?.readAsBytes();
      String fileName = image.name;
      // Upload file
      UploadTask uploadTask =
          FirebaseStorage.instance.ref('uploads/$fileName').putData(fileBytes!);
      uploadTask.snapshotEvents.listen((TaskSnapshot taskSnapshot) {},
          onError: (error) {
        ProgressHud.dismiss();
        Fluttertoast.showToast(msg: error.toString());
      }, onDone: () {
        print("Image Uploaded");
      });
      await uploadTask.whenComplete(() async {
        url = await uploadTask.snapshot.ref.getDownloadURL();
        ProgressHud.dismiss();
        Fluttertoast.showToast(msg: 'File added to the library');
        print("Video Uploaded");
      });
      return url.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) => Scaffold(
        appBar: getAppBar("Video"),
        backgroundColor: kBackgroundColor,
        body: ListView(
          padding: EdgeInsets.symmetric(horizontal: 32),
          physics: BouncingScrollPhysics(),
          children: [
            const SizedBox(height: 24),
            VideoWidget(
              videoPath: videoUrl,
              isEdit: true,
              onClicked: () async {
                String? url = await uploadVideo();
                print(url);
                videoUrl = url ?? "";
                if (mounted) setState(() {});
              },
            ),
            const SizedBox(height: 24),
            PhotoWidget(
              imagePath: widget.index == null
                  ? "https://firebasestorage.googleapis.com/v0/b/vizidot-1d585.appspot.com/o/AppTheme%2Fplaceholder-image.jpeg?alt=media&token=f01a4d81-2043-4e16-937e-50ab1238fd7c"
                  : imageUrl.toString(),
              title: "Thumbnail",
              isEdit: true,
              onClicked: () async {
                String? url = await uploadFile();
                print(url);
                imageUrl = url ?? "";
                if (mounted) setState(() {});
              },
            ),
            const SizedBox(height: 24),
            TextFieldWidget(
              label: 'Name',
              text: imageName.toString(),
              onChanged: (name) {
                imageName = name;
              },
            ),
            const SizedBox(height: 35),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                (widget.index != null)
                    ? Expanded(
                        child: ButtonWidget(
                        text: "Delete",
                        onClicked: () async {
                          ProgressHud.showLoading();
                          print(widget.artist!.toMap());
                          final db = FirebaseFirestore.instance;
                          widget.artist!.videos.removeAt(widget.index!);
                          db
                              .collection("Artists")
                              .doc(widget.artist!.id)
                              .update(widget.artist!.toMap())
                              .then((value) {
                            ProgressHud.dismiss();
                            Navigator.pop(context);
                          });
                        },
                      ))
                    : SizedBox(width: 0),
                SizedBox(width: (widget.index != null) ? 30 : 0),
                Expanded(
                    child: ButtonWidget(
                  text: "Save",
                  onClicked: () async {
                    if (imageName.length == 0) {
                      Fluttertoast.showToast(
                          msg: "Please enter the Video name first!");
                      return;
                    }
                    if (videoUrl.length == 0) {
                      Fluttertoast.showToast(
                          msg: "Please upload the video first!");
                      return;
                    }
                    if (imageUrl.length == 0) {
                      Fluttertoast.showToast(
                          msg: "Please upload the thumbnail image first!");
                      return;
                    }
                    widget.video?.url = videoUrl;
                    widget.video?.thumb = imageUrl;
                    widget.video?.name = imageName;
                    ProgressHud.showLoading();
                    print(widget.artist!.toMap());
                    final db = FirebaseFirestore.instance;
                    if (widget.index == null) {
                      widget.artist!.videos.add(widget.video!);
                    } else {
                      widget.artist!.videos.removeAt(widget.index!);
                      widget.artist!.videos
                          .insert(widget.index!, widget.video!);
                    }
                    db
                        .collection("Artists")
                        .doc(widget.artist!.id)
                        .update(widget.artist!.toMap())
                        .then((value) {
                      ProgressHud.dismiss();
                      Navigator.pop(context);
                    });
                  },
                )),
              ],
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
