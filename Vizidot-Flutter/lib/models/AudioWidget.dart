import 'dart:io';
import 'package:flutter/material.dart';
import 'package:vizidot_flutter/constants.dart';

class AudioWidget extends StatelessWidget {
  late String? videoPath;
  final bool isEdit;
  final VoidCallback onClicked;

  AudioWidget({
    Key? key,
    this.videoPath,
    this.isEdit = false,
    required this.onClicked,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
        color: kPrimaryColor,
        image: DecorationImage(image: AssetImage(videoPath!.isEmpty == true ? "assets/added-music.png" : "assets/add-music.png")),
        borderRadius: BorderRadius.circular(17)),
    child:buildImage());
  }

  Widget buildImage() {
    return Ink.image(
      image: AssetImage(videoPath!.isEmpty == true ? "assets/added-music.png" : "assets/add-music.png"),
      fit: BoxFit.fitHeight,
      height: 150,
      child: InkWell(onTap: onClicked),
    );
  }
}
