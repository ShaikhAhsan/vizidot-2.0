import 'package:cloud_firestore/cloud_firestore.dart';

class LiveStream {
  final String name;
  final String photo;
  final String desc;
  late  String identifier;
  late  int dateAdded;
  final String channel;
  late int dateUpdated;

  LiveStream(
      {required this.name,
      required this.photo,
      required this.desc,
      required this.identifier,
      required this.dateAdded,
      required this.channel,
      required this.dateUpdated});

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'photo': photo,
      'desc': desc,
      'identifier': identifier,
      'dateAdded': dateAdded,
      'channel': channel,
      'dateUpdated': dateUpdated
    };
  }

  LiveStream.fromDocumentSnapshot(DocumentSnapshot<Map<String, dynamic>> doc)
      : name = doc.data()!["name"],
        photo = doc.data()!["photo"],
        desc = doc.data()!["desc"],
        identifier = doc.data()!["identifier"],
        dateAdded = doc.data()!["dateAdded"],
        channel = doc.data()!["channel"],
        dateUpdated = doc.data()!["dateUpdated"];
}
