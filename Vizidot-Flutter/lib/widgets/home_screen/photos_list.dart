import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:vizidot_flutter/constants.dart';
import 'package:vizidot_flutter/models/artists.dart';
import 'package:vizidot_flutter/models/images.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:vizidot_flutter/screens/audio_player.dart';
import 'package:vizidot_flutter/screens/image_viewer.dart';

class PhotosList extends StatelessWidget {
  final List<Photo> photos;
  final String title;
  final Artist? artist;

  const PhotosList({Key? key, required this.photos, required this.title, required this.artist})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              // childAspectRatio: 5,
            ),
            itemCount: photos.length,
            itemBuilder: (context, index) {
              var posterPath = photos[index].thumb.toString();
              return InkWell(
                hoverColor: Colors.blue,
                onTap: () async {
                  Photo photo = photos[index];
                  List<Photo> imagesArray = [];
                  for (Photo photo in photos) {
                    imagesArray.add(photo);
                  }
                  print(imagesArray);
                  imagesArray.removeAt(index);
                  imagesArray.insert(0, photo);
                  List<MediaItem> mediaItems = [];
                  for(Photo photo in imagesArray) {
                    MediaItem item = MediaItem(id: photo?.url ?? "", title: photo.name, duration: Duration(milliseconds: photo?.milliseconds ?? 0), artist: artist?.name,
                      artUri: Uri.parse(
                        photo?.thumb ?? ""), album: artist?.desc);
                    mediaItems.add(item);
                  }


                  // Navigator.push(
                  //     context,
                  //     MaterialPageRoute(
                  //         builder: (context) =>
                  //             ImageViewerGallery(galleryItems: imagesArray),
                  //         fullscreenDialog: true));


                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              MainScreen(mediaItems: mediaItems),
                          fullscreenDialog: true));
                },
                child: Container(
                  margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                  padding: const EdgeInsets.all(2),
                  width: MediaQuery.of(context).size.width,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(
                      Radius.circular(2),
                    ),
                    color: kPrimaryColor.withOpacity(0.9),
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
