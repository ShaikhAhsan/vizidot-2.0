import 'dart:io';
import 'package:flutter/material.dart';
import 'package:vizidot_flutter/constants.dart';

class VideoWidget extends StatelessWidget {
  late String? videoPath;
  final bool isEdit;
  final VoidCallback onClicked;

  VideoWidget({
    Key? key,
    this.videoPath,
    this.isEdit = false,
    required this.onClicked,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        "Video",
        style: TextStyle(
            fontWeight: FontWeight.bold, fontSize: 16, color: kPrimaryColor),
      ),
      SizedBox(height: 20),
      Stack(
        children: [
          buildImage(),
          Center(
              heightFactor: 3,
              child: Icon(Icons.play_circle_outline_sharp,
                  color: kPrimaryColor, size: 100))
        ],
      )
    ]);
  }

  Widget buildImage() {
    final image = NetworkImage(videoPath!.isEmpty == true
        ? "https://firebasestorage.googleapis.com/v0/b/vizidot-1d585.appspot.com/o/AppTheme%2Fplaceholder-video.jpeg?alt=media&token=8454eac0-6ca6-48e6-8446-70fdcb188853"
        : videoPath!);
    return Ink.image(
      image: image,
      fit: BoxFit.cover,
      // width: 128,
      height: 300,
      child: InkWell(onTap: onClicked),
    );
  }
}
