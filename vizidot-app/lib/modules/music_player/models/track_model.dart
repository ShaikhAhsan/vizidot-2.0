class TrackModel {
  final String id;
  final String title;
  final String artist;
  final String albumArt;
  final String? audioUrl;
  final String? localPath;
  final Duration duration;

  TrackModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.albumArt,
    this.audioUrl,
    this.localPath,
    required this.duration,
  });

  TrackModel copyWith({
    String? id,
    String? title,
    String? artist,
    String? albumArt,
    String? audioUrl,
    String? localPath,
    Duration? duration,
  }) {
    return TrackModel(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      albumArt: albumArt ?? this.albumArt,
      audioUrl: audioUrl ?? this.audioUrl,
      localPath: localPath ?? this.localPath,
      duration: duration ?? this.duration,
    );
  }
}

