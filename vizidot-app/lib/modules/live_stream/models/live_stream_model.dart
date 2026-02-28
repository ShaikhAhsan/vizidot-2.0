class LiveStreamModel {
  final String name;
  final String photo;
  final String desc;
  late String identifier;
  late int dateAdded;
  late String channel; // Unique per stream (e.g. Firestore doc id)
  late int dateUpdated;
  /// Artist id (as string) when broadcaster is an artist; else Firebase UID. Used to hide own stream and filter.
  final String broadcasterUid;
  /// MySQL artist id when broadcaster is an artist; 0 otherwise.
  final int artistId;
  /// Artist display name when broadcaster is an artist; empty otherwise.
  final String artistName;

  LiveStreamModel({
    required this.name,
    required this.photo,
    required this.desc,
    required this.identifier,
    required this.dateAdded,
    required this.channel,
    required this.dateUpdated,
    this.broadcasterUid = '',
    this.artistId = 0,
    this.artistName = '',
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
      if (broadcasterUid.isNotEmpty) 'broadcasterUid': broadcasterUid,
      if (artistId > 0) 'artistId': artistId,
      if (artistName.isNotEmpty) 'artistName': artistName,
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
      broadcasterUid: map['broadcasterUid']?.toString() ?? '',
      artistId: (map['artistId'] as num?)?.toInt() ?? 0,
      artistName: map['artistName'] as String? ?? '',
    );
  }
}

