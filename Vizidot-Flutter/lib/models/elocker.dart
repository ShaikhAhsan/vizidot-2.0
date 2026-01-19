import 'package:cloud_firestore/cloud_firestore.dart';

class ElockerModel {
  late String id;
  late String artistId;
  late String desc;
  late String name;
  late String fcmToken;
  late String email;
  late String userId;
  late String photo;

  ElockerModel(
      {required this.id,
      required this.artistId,
      required this.desc,
      required this.name,
      required this.fcmToken,
      required this.email,
      required this.userId,
      required this.photo});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'artistId': artistId,
      'desc': desc,
      'name': name,
      'fcmToken': fcmToken,
      'email': email,
      'userId': userId,
      'photo': photo
    };
  }

  ElockerModel.fromDocumentSnapshot(DocumentSnapshot<Map<String, dynamic>> doc)
      : id = doc.id,
        artistId = doc.data()!["artistId"],
        desc = doc.data()!["desc"],
        name = doc.data()!["name"],
        fcmToken = doc.data()!["fcmToken"],
        email = doc.data()!["email"],
        userId = doc.data()!["userId"],
        photo = doc.data()!["photo"];
}
