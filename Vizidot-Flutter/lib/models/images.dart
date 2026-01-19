import 'package:cloud_firestore/cloud_firestore.dart';

class Photo {
  late String name;
  late String url;
  late String? thumb;
  late int? milliseconds;

  Photo({required this.name, required this.url, required this.thumb, required this.milliseconds});

  Map<String, dynamic> toMap() {
    return {'name': name, 'url': url, 'thumb': thumb, 'milliseconds': milliseconds};
  }

  Photo.fromMap(Map<String, dynamic> imageMap)
      : name = imageMap["name"],
        url = imageMap["url"],
        thumb = imageMap["thumb"],
        milliseconds = imageMap["milliseconds"];

  Photo.fromDocumentSnapshot(DocumentSnapshot<Map<String, dynamic>> doc)
      : name = doc.data()!["name"],
        url = doc.data()!["url"],
        thumb = doc.data()!["thumb"],
        milliseconds = doc.data()!["milliseconds"];
}
