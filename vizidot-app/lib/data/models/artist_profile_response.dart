/// Response shape for GET /api/v1/music/artists/profile/:id (public).
class ArtistProfileResponse {
  ArtistProfileResponse({
    required this.artist,
    required this.albums,
    required this.tracks,
  });

  final ArtistProfileArtist artist;
  final List<ArtistProfileAlbum> albums;
  final List<ArtistProfileTrack> tracks;

  factory ArtistProfileResponse.fromJson(Map<String, dynamic> json) {
    final artistMap = json['artist'] as Map<String, dynamic>?;
    final albumsList = json['albums'] as List<dynamic>? ?? [];
    final tracksList = json['tracks'] as List<dynamic>? ?? [];

    return ArtistProfileResponse(
      artist: artistMap != null
          ? ArtistProfileArtist.fromJson(artistMap)
          : ArtistProfileArtist.empty(),
      albums: albumsList
          .map((e) => ArtistProfileAlbum.fromJson(e as Map<String, dynamic>))
          .toList(),
      tracks: tracksList
          .map((e) => ArtistProfileTrack.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ArtistProfileArtist {
  ArtistProfileArtist({
    required this.id,
    required this.name,
    this.bio,
    this.imageUrl,
    this.followersCount = 0,
    this.followingCount = 0,
    this.shopId,
    this.shop,
  });

  final int id;
  final String name;
  final String? bio;
  final String? imageUrl;
  final int followersCount;
  final int followingCount;
  final int? shopId;
  final ArtistProfileShop? shop;

  factory ArtistProfileArtist.fromJson(Map<String, dynamic> json) {
    return ArtistProfileArtist(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      bio: json['bio'] as String?,
      imageUrl: json['imageUrl'] as String?,
      followersCount: (json['followersCount'] as num?)?.toInt() ?? 0,
      followingCount: (json['followingCount'] as num?)?.toInt() ?? 0,
      shopId: (json['shopId'] as num?)?.toInt(),
      shop: json['shop'] != null
          ? ArtistProfileShop.fromJson(
              json['shop'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  static ArtistProfileArtist empty() => ArtistProfileArtist(
        id: 0,
        name: '',
      );
}

class ArtistProfileShop {
  ArtistProfileShop({
    required this.id,
    required this.shopName,
    required this.shopUrl,
  });

  final int id;
  final String shopName;
  final String shopUrl;

  factory ArtistProfileShop.fromJson(Map<String, dynamic> json) {
    return ArtistProfileShop(
      id: (json['id'] as num?)?.toInt() ?? 0,
      shopName: json['shopName'] as String? ?? '',
      shopUrl: json['shopUrl'] as String? ?? '',
    );
  }
}

class ArtistProfileAlbum {
  ArtistProfileAlbum({
    required this.id,
    required this.title,
    this.coverImageUrl,
    this.artistName,
  });

  final int id;
  final String title;
  final String? coverImageUrl;
  final String? artistName;

  factory ArtistProfileAlbum.fromJson(Map<String, dynamic> json) {
    return ArtistProfileAlbum(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      coverImageUrl: json['coverImageUrl'] as String?,
      artistName: json['artistName'] as String?,
    );
  }
}

class ArtistProfileTrack {
  ArtistProfileTrack({
    required this.id,
    required this.title,
    this.durationFormatted,
    this.durationSeconds,
    this.albumArt,
    this.artistName,
    this.audioUrl,
    this.albumId,
  });

  final int id;
  final String title;
  final String? durationFormatted;
  final int? durationSeconds;
  final String? albumArt;
  final String? artistName;
  final String? audioUrl;
  final int? albumId;

  factory ArtistProfileTrack.fromJson(Map<String, dynamic> json) {
    return ArtistProfileTrack(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      durationFormatted: json['durationFormatted'] as String?,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
      albumArt: json['albumArt'] as String?,
      artistName: json['artistName'] as String?,
      audioUrl: json['audioUrl'] as String?,
      albumId: (json['albumId'] as num?)?.toInt(),
    );
  }
}
