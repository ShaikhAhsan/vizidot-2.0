import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vizidot_flutter/models/images.dart';
import 'package:vizidot_flutter/models/videos.dart';

class Artist {
  late String id;
  late String name;
  late String photo;
  late String desc;
  late String? scanImage;
  late String? sponserIcon;
  late String? shopUrl;
  List<Photo> images = <Photo>[];
  List<Video> videos = <Video>[];

  Artist(
      {required this.id,
      required this.name,
      required this.photo,
      required this.desc,
      required this.scanImage,
      required this.sponserIcon,
      required this.shopUrl,
      required this.images,
      required this.videos});

  Map<String, dynamic> toMap() {
    var photosList = [];
    images.forEach((photo) {
      photosList.add(photo.toMap());
    });
    var videosList = [];
    videos.forEach((video) {
      videosList.add(video.toMap());
    });
    return {
      'id': id,
      'name': name,
      'photo': photo,
      'desc': desc,
      'scanImage': scanImage,
      'sponserIcon': sponserIcon,
      'shopUrl': shopUrl,
      'images': photosList,
      'videos': videosList
    };
  }

  Artist.fromMap(Map<String, dynamic> videoMap)
      : id = videoMap["id"],
        name = videoMap["name"],
        photo = videoMap["photo"],
        desc = videoMap["desc"],
        scanImage = videoMap["scanImage"],
        sponserIcon = videoMap["sponserIcon"],
        shopUrl = videoMap["shopUrl"],
        images = videoMap["images"],
        videos = videoMap["videos"];

  Artist.fromDocumentSnapshot(DocumentSnapshot<Map<String, dynamic>> doc)
      : id = doc.id,
        name = doc.data()!["name"],
        photo = doc.data()!["photo"],
        desc = doc.data()!["desc"],
        scanImage = doc.data()!["scanImage"],
        sponserIcon = doc.data()!["sponserIcon"],
        shopUrl = doc.data()!["shopUrl"],
        images = _convertImages(doc.data()!["images"]),
        videos = _convertVideos(doc.data()!["videos"]);
}

List<Photo> _convertImages(List<dynamic>? vaccinationMap) {
  if (vaccinationMap == null) {
    return <Photo>[];
  }
  List<Photo> vaccinations = <Photo>[];
  for (var value in vaccinationMap) {
    vaccinations.add(Photo.fromMap(value));
  }
  return vaccinations;
}

List<Video> _convertVideos(List<dynamic>? vaccinationMap) {
  if (vaccinationMap == null) {
    return <Video>[];
  }
  List<Video> vaccinations = <Video>[];
  for (var value in vaccinationMap) {
    vaccinations.add(Video.fromMap(value));
  }
  return vaccinations;
}
