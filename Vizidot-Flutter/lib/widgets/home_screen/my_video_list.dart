import 'package:flutter/material.dart';
import 'package:vizidot_flutter/constants.dart';
import 'package:vizidot_flutter/models/AddVideo.dart';
import 'package:vizidot_flutter/models/artists.dart';
import 'package:vizidot_flutter/models/videos.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:vizidot_flutter/utils/ButtonWidget.dart';

class MyVideosList extends StatelessWidget {
  final List<Video> videosList;
  final Artist artist;

  const MyVideosList({Key? key, required this.videosList, required this.artist})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Videos",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: kPrimaryColor),
              ),
              ButtonWidget(
                  text: "Add New Video",
                  onClicked: () async {
                    Video video = Video(name: "", url: "", thumb: "");
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            AddVideo(this.artist, video, null),
                      ),
                    );
                  })
            ],
          ),
          const SizedBox(height: 20),
          ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: videosList.length,
              itemBuilder: (context, index) {
                var video = videosList[index];
                var posterPath = video.thumb.toString();
                return InkWell(
                  onTap: () {
                    print("Ahsan");
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            AddVideo(this.artist, video, index),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                    padding: const EdgeInsets.all(0),
                    width: MediaQuery.of(context).size.width - 30,
                    height: 160,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.all(
                        Radius.circular(15),
                      ),
                      color: kPrimaryColor.withOpacity(0.1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          // color: kPrimaryColor, //kBoxColor.withOpacity(0.1),
                          margin: const EdgeInsets.fromLTRB(12, 12, 0, 12),
                          height: MediaQuery.of(context).size.height * 0.3,
                          width: MediaQuery.of(context).size.width / 4,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.all(
                              Radius.circular(8),
                            ),
                            child: Stack(children: [
                              CachedNetworkImage(
                                imageUrl: posterPath,
                                imageBuilder: (context, imageProvider) =>
                                    Container(
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: imageProvider,
                                      fit: BoxFit.cover,
                                      //colorFilter: ColorFilter.mode(Colors.red, BlendMode.colorBurn)
                                    ),
                                  ),
                                ),
                                fit: BoxFit.fill,
                              ),
                              Align(
                                widthFactor: 20,
                                alignment: Alignment.center,
                                child: Icon(Icons.play_circle_outline_sharp,
                                    color: kPrimaryColor, size: 48),
                              ),
                            ]),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Padding(
                          padding: const EdgeInsets.only(top: 16, bottom: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.5,
                                child: Text(
                                  video.name.toString(),
                                  maxLines: 5,

                                  style: kSectionMovieTitle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              })
        ]);
  }
}
