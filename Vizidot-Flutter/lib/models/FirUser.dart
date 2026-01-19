import 'package:cloud_firestore/cloud_firestore.dart';

class SUser {
  late String id;
  late String artistId;
  late String name;
  late String email;
  late String password;
  late String photo;
  late String? fcmToken;

  SUser(
      {required this.id,
      required this.artistId,
      required this.name,
      required this.email,
      required this.password,
      required this.photo,
      required this.fcmToken});

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'artistId': artistId,
      'name': name,
      'email': email,
      'password': password,
      'photo': photo,
      'fcmToken': fcmToken
    };
  }

  SUser.fromDocumentSnapshot(DocumentSnapshot<Map<String, dynamic>> doc)
      : id = doc.id,
        artistId = doc.data()!["artistId"] ?? "",
        name = doc.data()!["name"] ?? "",
        email = doc.data()!["email"] ?? "",
        password = doc.data()!["password"] ?? "",
        photo = doc.data()!["photo"] ?? "",
        fcmToken = doc.data()!["fcmToken"] ?? "";

  SUser.fromJson(Map<String, dynamic> json)
      : id = json['id'] ?? "",
        artistId = json['artistId'] ?? "",
        name = json['name'] ?? "",
        email = json['email'] ?? "",
        password = json['password'] ?? "",
        photo = json['photo'] ?? "",
        fcmToken = json['fcmToken'] ?? "";
}
