import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:bmprogresshud/bmprogresshud.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:vizidot_flutter/constants.dart';
import 'package:vizidot_flutter/models/artists.dart';
import 'package:vizidot_flutter/utils/ButtonWidget.dart';
import 'package:vizidot_flutter/utils/ProfileWidget.dart';
import 'package:vizidot_flutter/utils/TextFieldWidget.dart';
import 'package:vizidot_flutter/widgets/home_screen/my_photo_list.dart';
import 'package:vizidot_flutter/widgets/home_screen/my_video_list.dart';

class AddArtistController extends StatefulWidget {
  late int current = 0;
  final String? artistId;

  AddArtistController(this.artistId);

  @override
  _AddArtistControllerState createState() => _AddArtistControllerState();
}

class _AddArtistControllerState extends State<AddArtistController> {
  late Artist? artist;// = Artist(id: "", name: "", photo: "", desc: "", scanImage: "", sponserIcon: "", images: [], videos: []);

  @override
  void initState() {
    fetch();
    super.initState();
  }

  Future<void> fetch() async {
    print(widget.artistId);
    FirebaseFirestore.instance
        .collection("Artists")
        .doc(widget.artistId)
        .snapshots()
        .listen((querySnapShot) {
      print("Response");

      print(querySnapShot.data());
      Artist artist = Artist.fromDocumentSnapshot(querySnapShot);
      if (mounted) {
        setState(() {
          this.artist = artist;
          print(artist.name);
        });
      }
    });
  }

  Future<String?> uploadFile() async {
    String url = "";
    XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 25);
    if (image != null) {
      ProgressHud.showLoading(text: "Uploading Image...");
      Uint8List? fileBytes = await image?.readAsBytes();
      String fileName = image.name;
      // Upload file
      UploadTask uploadTask =
          FirebaseStorage.instance.ref('uploads/$fileName').putData(fileBytes!);
      uploadTask.snapshotEvents.listen((TaskSnapshot taskSnapshot) {
      }, onError: (error) {
        ProgressHud.dismiss();
        Fluttertoast.showToast(msg: error.toString());
      }, onDone: () {
        print("Image Uploaded");
      });
      await uploadTask.whenComplete(() async {
        url = await uploadTask.snapshot.ref.getDownloadURL();
        ProgressHud.dismiss();
          Fluttertoast.showToast(msg: 'File added to the library');
          print("Image Uploaded");
      });
      return url.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getAppBar("My Artist"),
      backgroundColor: kBackgroundColor,
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 32),
        physics: BouncingScrollPhysics(),
        children: [
          const SizedBox(height: 24),
          ProfileWidget(
            imagePath: this.artist!.photo.toString(),
            isEdit: true,
            onClicked: () async {
              String? url = await uploadFile();
              print(url);
              setState(() {
                this.artist!.photo = url.toString();
              });
            },
          ),
          const SizedBox(height: 24),
          TextFieldWidget(
            label: 'Name',
            text: this.artist!.name.toString(),
            onChanged: (name) {
              this.artist!.name = name;
            },

          ),
          const SizedBox(height: 24),
          TextFieldWidget(
            label: 'Description',
            text: this.artist!.desc.toString(),
            maxLines: 5,
            onChanged: (desc) {
              this.artist!.desc = desc;
            },
          ),
          const SizedBox(height: 24),
          this.artist!.id.toString().isEmpty == false
              ? DefaultTabController(
                  length: 2,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        TabBar(
                          indicatorWeight: 2,
                          indicatorColor: kPrimaryColor,
                          labelColor: kPrimaryColor,
                          //labelStyle: kButtonTextStyle,
                          unselectedLabelColor: Colors.white,
                          tabs: const [
                            Tab(text: 'Audio Songs'),
                            Tab(text: 'Videos')
                          ],
                          onTap: (index) {
                            setState(() {
                              widget.current = index;
                            });
                          },
                        ),
                        const SizedBox(height: 24),
                        Builder(builder: (_) {
                          if (widget.current == 0) {
                            return MyPhotosList(
                                photos: this.artist!.images.length > 0
                                    ? this.artist!.images
                                    : [],
                                artist: this.artist!);
                          } else {
                            return MyVideosList(
                              videosList: this.artist!.videos.length > 0
                                  ? this.artist!.videos
                                  : [],
                              artist: this.artist!,
                            );
                          }
                        }),
                      ]))
              : Text(""),
          const SizedBox(height: 20),
          ButtonWidget(
            text: "Save",
            onClicked: () async {
              if (this.artist!.name.isEmpty == true) {
                Fluttertoast.showToast(msg: "Please enter the Name first!");
                return;
              }
              if (this.artist!.photo.isEmpty == true) {
                Fluttertoast.showToast(msg: "Please upload the image first!");
                return;
              }
              ProgressHud.showLoading();
              print(this.artist!.toMap());
              final db = FirebaseFirestore.instance;
              db
                  .collection("Artists")
                  .doc(this.artist!.id)
                  .update(this.artist!.toMap())
                  .then((value) {
                Fluttertoast.showToast(msg: 'Updated Successfully!');
                ProgressHud.dismiss();
                Navigator.pop(context);
              });
            },
          ),
          SizedBox(height: 50),
        ],
      ),
    );
  }
}
