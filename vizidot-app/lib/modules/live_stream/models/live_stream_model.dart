class LiveStreamModel {
  final String name;
  final String photo;
  final String desc;
  late String identifier;
  late int dateAdded;
  final String channel;
  late int dateUpdated;

  LiveStreamModel({
    required this.name,
    required this.photo,
    required this.desc,
    required this.identifier,
    required this.dateAdded,
    required this.channel,
    required this.dateUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'photo': photo,
      'desc': desc,
      'identifier': identifier,
      'dateAdded': dateAdded,
      'channel': channel,
      'dateUpdated': dateUpdated,
    };
  }

  factory LiveStreamModel.fromMap(Map<String, dynamic> map) {
    return LiveStreamModel(
      name: map['name'] ?? '',
      photo: map['photo'] ?? '',
      desc: map['desc'] ?? '',
      identifier: map['identifier'] ?? '',
      dateAdded: map['dateAdded'] ?? 0,
      channel: map['channel'] ?? '',
      dateUpdated: map['dateUpdated'] ?? 0,
    );
  }
}

