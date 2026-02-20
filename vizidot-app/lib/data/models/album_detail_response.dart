/// Response shape for GET /api/v1/music/albums/:id.
class AlbumDetailResponse {
  AlbumDetailResponse({
    required this.album,
    required this.tracks,
  });

  final AlbumDetailAlbum album;
  final List<AlbumDetailTrack> tracks;

  factory AlbumDetailResponse.fromJson(Map<String, dynamic> json) {
    final albumMap = json['album'] as Map<String, dynamic>?;
    final tracksList = json['tracks'] as List<dynamic>? ?? [];
    return AlbumDetailResponse(
      album: albumMap != null
          ? AlbumDetailAlbum.fromJson(albumMap)
          : AlbumDetailAlbum.empty(),
      tracks: tracksList
          .map((e) => AlbumDetailTrack.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AlbumDetailAlbum {
  AlbumDetailAlbum({
    required this.id,
    required this.title,
    this.description,
    this.coverImageUrl,
    required this.artistId,
    this.artistName,
    this.albumType = 'audio',
    this.releaseDate,
    this.releaseYear,
    this.trackCount = 0,
    this.totalDurationFormatted,
  });

  final int id;
  final String title;
  final String? description;
  final String? coverImageUrl;
  final int artistId;
  final String? artistName;
  final String albumType;
  final String? releaseDate;
  final String? releaseYear;
  final int trackCount;
  final String? totalDurationFormatted;

  bool get isVideo => albumType == 'video';

  factory AlbumDetailAlbum.fromJson(Map<String, dynamic> json) {
    return AlbumDetailAlbum(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      coverImageUrl: json['coverImageUrl'] as String?,
      artistId: (json['artistId'] as num?)?.toInt() ?? 0,
      artistName: json['artistName'] as String?,
      albumType: json['albumType'] as String? ?? 'audio',
      releaseDate: json['releaseDate'] as String?,
      releaseYear: json['releaseYear'] as String?,
      trackCount: (json['trackCount'] as num?)?.toInt() ?? 0,
      totalDurationFormatted: json['totalDurationFormatted'] as String?,
    );
  }

  static AlbumDetailAlbum empty() => AlbumDetailAlbum(
        id: 0,
        title: '',
        artistId: 0,
      );
}

class AlbumDetailTrack {
  AlbumDetailTrack({
    required this.id,
    required this.title,
    this.durationFormatted,
    this.durationSeconds,
    this.albumArt,
    this.artistName,
    this.audioUrl,
    this.videoUrl,
    this.albumId,
    this.type = 'audio',
  });

  final int id;
  final String title;
  final String? durationFormatted;
  final int? durationSeconds;
  final String? albumArt;
  final String? artistName;
  final String? audioUrl;
  final String? videoUrl;
  final int? albumId;
  final String type;

  bool get isVideo => type == 'video';

  factory AlbumDetailTrack.fromJson(Map<String, dynamic> json) {
    return AlbumDetailTrack(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      durationFormatted: json['durationFormatted'] as String?,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
      albumArt: json['albumArt'] as String?,
      artistName: json['artistName'] as String?,
      audioUrl: json['audioUrl'] as String?,
      videoUrl: json['videoUrl'] as String?,
      albumId: (json['albumId'] as num?)?.toInt(),
      type: json['type'] as String? ?? 'audio',
    );
  }
}
