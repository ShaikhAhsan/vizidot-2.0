/// API path and query constants. Base URL comes from [AppConfig].
/// See [FLUTTER_API_GUIDE.md] for usage.
class ApiConstants {
  ApiConstants._();

  /// API version prefix used by backend (e.g. /api/v1/...).
  static const String apiVersion = 'api/v1';

  /// Music / artist paths (public and private).
  static const String musicSegment = 'music';

  /// Artist profile for app (public). Replace :id with artist id.
  static String artistProfilePath(int artistId) =>
      '$musicSegment/artists/profile/$artistId';

  /// Artist by id (private, admin). Replace :id with artist id.
  static String artistByIdPath(int artistId) =>
      '$musicSegment/artists/$artistId';

  /// List artists (private).
  static const String artistsPath = '$musicSegment/artists';

  /// Follow artist (auth required). Replace :id with artist id.
  static String artistFollowPath(int artistId) =>
      '$musicSegment/artists/$artistId/follow';

  /// Unfollow artist (auth required). Replace :id with artist id.
  static String artistUnfollowPath(int artistId) =>
      '$musicSegment/artists/$artistId/follow';

  /// Health check (no version prefix on backend).
  static const String healthPath = 'health';
}
