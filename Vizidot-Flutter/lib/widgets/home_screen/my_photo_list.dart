import 'package:flutter/material.dart';
import 'package:vizidot_flutter/constants.dart';
import 'package:vizidot_flutter/models/AddImage.dart';
import 'package:vizidot_flutter/models/artists.dart';
import 'package:vizidot_flutter/models/images.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:vizidot_flutter/utils/ButtonWidget.dart';

class MyPhotosList extends StatelessWidget {
  final List<Photo> photos;
  final Artist artist;

  const MyPhotosList({Key? key, required this.photos, required this.artist})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Audio Songs",
                style:  TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: kPrimaryColor),
              ),
              ButtonWidget(
                  text: "Add Audio Song",
                  onClicked: () async {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AddImage(this.artist, Photo(name: "", url: "", thumb: "", milliseconds: 0), null),
                      ),
                    );
                  })
            ],
          ),
          SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              // childAspectRatio: 5,
            ),
            itemCount: photos.length,
            itemBuilder: (context, index) {
              var posterPath = photos[index].url.toString();
              return InkWell(
                hoverColor: Colors.black87,
                onTap: () async {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AddImage(this.artist, photos[index], index),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                  padding: const EdgeInsets.all(5),
                  width: MediaQuery.of(context).size.width,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(
                      Radius.circular(5),
                    ),
                    color: kPrimaryColor,
                  ),
                  child: CachedNetworkImage(
                      imageUrl: posterPath, fit: BoxFit.cover),
                ),
              );
            },
          )
        ]);
  }
}
