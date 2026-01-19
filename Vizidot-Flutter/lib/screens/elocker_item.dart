import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:vizidot_flutter/models/artists.dart';

import '../../video_player.dart';
import '../../constants.dart';
import 'elocker_detail.dart';

class ElockerItem extends StatelessWidget {
  final Artist artist;

  const ElockerItem({Key? key, required this.artist}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ElockerDetail(artist: this.artist),
              fullscreenDialog: true),
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(15, 0, 15, 16),
        padding: const EdgeInsets.all(0),
        width: 90,
        height: 160,
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
                    imageUrl: artist.photo,
                    imageBuilder: (context, imageProvider) => Container(
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
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.3,
                    child: Text(
                      artist.name,
                      maxLines: 2,
                      style: kSectionMovieTitle,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 1.8,
                    child: Text(
                      artist.desc,
                      maxLines: 5,
                      style: kSectionMovieSubtitle.copyWith(
                        overflow: TextOverflow.clip,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
