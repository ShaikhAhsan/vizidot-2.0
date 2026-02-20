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

  /// List artists with pagination. Public. Query: limit, offset.
  static const String artistsPath = '$musicSegment/artists';
  static String artistsListPath(int limit, int offset) =>
      '$musicSegment/artists?limit=$limit&offset=$offset';

  /// Save logged-in user's selected artist ids (follow). Auth required. POST body: artistIds.
  static const String artistsSelectedPath = '$musicSegment/artists/selected';

  /// Follow artist (auth required). Replace :id with artist id.
  static String artistFollowPath(int artistId) =>
      '$musicSegment/artists/$artistId/follow';

  /// Unfollow artist (auth required). Replace :id with artist id.
  static String artistUnfollowPath(int artistId) =>
      '$musicSegment/artists/$artistId/follow';

  /// Album detail (public). Replace :id with album id.
  static String albumDetailPath(int albumId) => '$musicSegment/albums/$albumId';

  /// Favourites (auth required).
  static const String favouritesPath = '$musicSegment/favourites';
  static String favouriteCheckPath() => '$musicSegment/favourites/check';
  static String favouriteRemovePath(String type, int id) => '$musicSegment/favourites/$type/$id';

  /// Followed artists (auth required). Query: limit, offset.
  static const String followedArtistsPath = '$musicSegment/followed-artists';

  /// Music categories (genres). Public.
  static const String categoriesPath = '$musicSegment/categories';

  /// Save logged-in user's selected category ids. Auth required. POST body: categoryIds.
  static const String categoriesSelectedPath = '$musicSegment/categories/selected';

  /// Home API: top audios + top videos (from play history). Public.
  static String homePath([int limit = 10]) => '$musicSegment/home?limit=$limit';

  /// Play history (record play = POST). Auth optional for record.
  static const String playHistoryPath = '$musicSegment/play-history';
  static String playHistoryTopPath(String type, [int limit = 10]) =>
      '$musicSegment/play-history/top?type=$type&limit=$limit';

  /// Health check (no version prefix on backend).
  static const String healthPath = 'health';
}
