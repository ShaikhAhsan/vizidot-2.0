import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:bmprogresshud/bmprogresshud.dart';
import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';
import 'package:vizidot_flutter/constants.dart';
import 'package:vizidot_flutter/models/AudioWidget.dart';
import 'package:vizidot_flutter/models/artists.dart';
import 'package:vizidot_flutter/models/images.dart';
import 'package:vizidot_flutter/utils/ButtonWidget.dart';
import 'package:vizidot_flutter/utils/PhotoWidget.dart';
import 'package:vizidot_flutter/utils/TextFieldWidget.dart';

class AddImage extends StatefulWidget {
  late Photo? photo;
  late Artist? artist;
  late int? index = null;

  AddImage(this.artist, this.photo, this.index);

  @override
  _AddImageState createState() => _AddImageState();
}

class _AddImageState extends State<AddImage> {




  Future<String?> uploadAudioFile() async {
    String url = "";
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'm4a'],
    );

    if (result != null) {
      Uint8List? fileBytes = result.files.first.bytes;
      String fileName = result.files.first.name;
      // Upload file
      UploadTask uploadTask = FirebaseStorage.instance
          .ref('uploads/AudioSongs/$fileName')
          .putData(fileBytes!);
      uploadTask.snapshotEvents.listen((TaskSnapshot taskSnapshot) {
        // ProgressHud.of(context)?.dismiss();
        // print("taskSnapshot.state");

        print("Uploaded");
        if (taskSnapshot.state == TaskState.success) {
          Fluttertoast.showToast(msg: 'Audio Song added to the library');
          print("Audio song Uploaded");
        } else {
          Fluttertoast.showToast(msg: taskSnapshot.state.name);
          ProgressHud.of(context)?.dismiss();
        }
      }, onError: (error) {
        print("Error Found" + error);
        ProgressHud.of(context)?.dismiss();
        Fluttertoast.showToast(msg: error.toString());
      }, onDone: () {
        print("Audio song Uploaded");
      });
      await uploadTask.whenComplete(() async {
        url = await uploadTask.snapshot.ref.getDownloadURL();
      });
      return url.toString();
    } else {
      Fluttertoast.showToast(msg: "Audio not found!");
      ProgressHud.of(context)?.dismiss();
    }
  }

  Future<String?> uploadFile() async {
    String url = "";
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
    );
    if (result != null) {
      Uint8List? fileBytes = result.files.first.bytes;
      String fileName = result.files.first.name;
      // Upload file
      UploadTask uploadTask =
          FirebaseStorage.instance.ref('uploads/$fileName').putData(fileBytes!);
      uploadTask.snapshotEvents.listen((TaskSnapshot taskSnapshot) {
        if (taskSnapshot.state == TaskState.success) {
          Fluttertoast.showToast(msg: 'File added to the library');
          print("Image Uploaded");
        }
      }, onError: (error) {
        Fluttertoast.showToast(msg: error.toString());
      }, onDone: () {
        print("Image Uploaded");
      });
      await uploadTask.whenComplete(() async {
        url = await uploadTask.snapshot.ref.getDownloadURL();
      });
      return url.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProgressHud(
      child: Builder(
        builder: (context) => Scaffold(
          appBar: getAppBar("Audio Song"),
          backgroundColor: kBackgroundColor,
          body: ListView(
            padding: EdgeInsets.symmetric(horizontal: 32),
            physics: BouncingScrollPhysics(),
            children: [
              const SizedBox(height: 15),
              Text(
                "Audio Song:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              AudioWidget(
                videoPath: widget.photo?.url,
                isEdit: true,
                onClicked: () async {
                  ProgressHud.of(context)
                      ?.showLoading(text: "Uploading Audio Song...");
                  String? url = await uploadAudioFile();
                  print(url);
                  final player = AudioPlayer();
                  var duration = await player.setUrl(url ?? "");
                  print("File Uploaded");
                  print(duration);
                  print(duration?.inMilliseconds);
                  if (url != null) {
                    setState(() {
                      widget.photo?.milliseconds = duration?.inMilliseconds;
                      widget.photo?.url = url!;
                    });
                  }
                  ProgressHud.of(context)?.dismiss();
                },
              ),
              const SizedBox(height: 24),
              Text(
                "Thumbnail:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              PhotoWidget(
                imagePath: widget.photo!.thumb?.isEmpty == true
                    ? "https://storage.googleapis.com/proudcity/mebanenc/uploads/2021/03/placeholder-image.png"
                    : widget.photo!.thumb!.toString(),
                isEdit: true,
                title: "Thumbnail",
                onClicked: () async {
                  ProgressHud.of(context)
                      ?.showLoading(text: "Uploading Thumbnail...");
                  String? url = await uploadFile();
                  print(url);
                  if (url != null) {
                    setState(() {
                      widget.photo?.thumb = url!;
                    });
                  }
                  ProgressHud.of(context)?.dismiss();
                },
              ),
              const SizedBox(height: 24),
              TextFieldWidget(
                label: 'Name',
                text: widget.photo!.name!.toString(),
                onChanged: (name) {
                  setState(() {
                    widget.photo?.name = name;
                  });
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
                            ProgressHud.of(context)?.showLoading();
                            print(widget.artist!.toMap());
                            final db = FirebaseFirestore.instance;
                            widget.artist!.images.removeAt(widget.index!);
                            db
                                .collection("Artists")
                                .doc(widget.artist!.id)
                                .update(widget.artist!.toMap())
                                .then((value) {
                              ProgressHud.of(context)?.dismiss();
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
                      if (widget.photo!.name.isEmpty == true) {
                        Fluttertoast.showToast(
                            msg: "Please enter the Name first!");
                        return;
                      }
                      if (widget.photo!.url.isEmpty == true) {
                        Fluttertoast.showToast(
                            msg: "Please upload the Audio song first!");
                        return;
                      }
                      print(widget.artist!.toMap());
                      ProgressHud.of(context)?.showLoading();
                      print(widget.artist!.toMap());
                      final db = FirebaseFirestore.instance;
                      if (widget.index == null) {
                        widget.artist!.images.add(widget.photo!);
                      } else {
                        widget.artist!.images.removeAt(widget.index!);
                        widget.artist!.images
                            .insert(widget.index!, widget.photo!);
                      }
                      db
                          .collection("Artists")
                          .doc(widget.artist!.id)
                          .update(widget.artist!.toMap())
                          .then((value) {
                        ProgressHud.of(context)?.dismiss();
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
      ),
    );
  }
}
