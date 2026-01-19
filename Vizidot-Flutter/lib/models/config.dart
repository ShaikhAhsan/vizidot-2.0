import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:encrypt/encrypt.dart';

class Config {
  late String? elockerSlang;
  late String? defaultUrl;
  late String? sponserIcon;
  late String? sponserLarge;

  Config({Key? key});

  Map<String, dynamic> toJson() {
    return {
      'elockerSlang': elockerSlang,
      'defaultUrl': defaultUrl,
      'sponserIcon': sponserIcon,
      'sponserLarge': sponserLarge
    };
  }

  Config.fromMap(Map<String, dynamic> videoMap)
      : elockerSlang = videoMap["elockerSlang"] ?? "",
        defaultUrl = videoMap["defaultUrl"] ?? "",
        sponserIcon = videoMap["sponserIcon"] ?? "",
        sponserLarge = videoMap["sponserLarge"] ?? "";

  Config.fromDocumentSnapshot(DocumentSnapshot<Map<String, dynamic>> doc)
      : elockerSlang = doc.data()?["elockerSlang"] ?? "",
        defaultUrl = doc.data()!["defaultUrl"] ?? "",
        sponserIcon = doc.data()!["sponserIcon"] ?? "",
        sponserLarge = doc.data()!["sponserLarge"] ?? "";

  Config.fromJson(Map<String, dynamic> json)
      : elockerSlang = json['elockerSlang'] ?? "",
        defaultUrl = json['defaultUrl'] ?? "",
        sponserIcon = json['sponserIcon'] ?? "",
        sponserLarge = json['sponserLarge'] ?? "";
}
