import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:vizidot_flutter/constants.dart';

class PhotoWidget extends StatelessWidget {
  late String imagePath;
  late String title;
  final bool isEdit;
  final VoidCallback onClicked;

  PhotoWidget({
    Key? key,
    required this.imagePath,
    required this.title,
    this.isEdit = false,
    required this.onClicked,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        title,
        style: TextStyle(
            fontWeight: FontWeight.bold, fontSize: 16, color: kPrimaryColor),
      ),
      SizedBox(height: 20),
      Center(
        child: Stack(
          children: [
            buildImage(),
          ],
        ),
      )
    ]);
  }

  Widget buildImage() {
    print("Image Path" + imagePath);
    if (imagePath == null || imagePath.length == 0) {
      imagePath =
          "https://firebasestorage.googleapis.com/v0/b/vizidot-1d585.appspot.com/o/AppTheme%2Fplaceholder-image.jpeg?alt=media&token=f01a4d81-2043-4e16-937e-50ab1238fd7c";
    }
    print(imagePath);
    final image = CachedNetworkImageProvider(imagePath);
    return
      Stack(
        children: <Widget>[
          Image.network(imagePath),
          Positioned.fill(
            child: Material(
              color: kPrimaryColor.withAlpha(3),
              child: InkWell(
                onTap: onClicked,
              ),
            ),
          ),
        ],
      );Ink.image(
      image: image,
      fit: BoxFit.cover,
      width: 128,
      height: 300,
      child: InkWell(onTap: onClicked),
    );
  }
}
