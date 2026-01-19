import 'package:flutter/material.dart';
import 'package:vizidot_flutter/models/videos.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../video_player.dart';
import '../../constants.dart';
import 'package:flutter/foundation.dart';
import 'package:vizidot_flutter/constants.dart' as consts;

class VideosList extends StatelessWidget {
  final List<Video> videosList;
  final String title;

  const VideosList({Key? key, required this.videosList, required this.title})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 33, vertical: 30),
            child: Text(
              title,
              style: kSectionMovieTitle,
            ),
          ),
          const SizedBox(height: 0),
          ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: videosList.length,
              itemBuilder: (context, index) {
                var data = videosList[index];
                var posterPath = data.thumb.toString();
                return InkWell(
                  onTap: () {
                    print("Ahsan Playing Video");
                    consts.audioHandler.updateQueue([]);
                    consts.audioHandler.stop();
                    if (kIsWeb) {
                      playVideo(data.url.toString());
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => VideoPlayer(
                                title: data.name,
                                videoUrl: data.url.toString()),
                            fullscreenDialog: true),
                      );
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(35, 0, 35, 16),
                    padding: const EdgeInsets.all(0),
                    width: MediaQuery.of(context).size.width - 30,
                    height: 140,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.all(
                        Radius.circular(15),
                      ),
                      color: kBoxColor.withOpacity(0.1),
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
                                  data.name.toString(),
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
