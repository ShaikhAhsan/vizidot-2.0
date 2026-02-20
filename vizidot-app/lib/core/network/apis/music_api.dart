import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api_client.dart';
import '../base_api.dart';
import '../../constants/api_constants.dart';
import '../../../data/models/album_detail_response.dart';
import '../../../data/models/artist_profile_response.dart';

/// Music / artist APIs. Use [ApiVisibility.public] for no-auth endpoints,
/// [ApiVisibility.private] for endpoints that require token.
class MusicApi extends BaseApi {
  MusicApi({
    required super.baseUrl,
    super.authToken,
    super.timeout,
    super.debugPrintRequest,
  });

  /// GET artist profile. Pass [useAuth: true] when the user is logged in so the API returns [artist.isFollowing].
  /// Accepts both wrapped { success, data: { artist, albums, tracks } } and raw { artist, albums, tracks }.
  Future<ArtistProfileResponse?> getArtistProfile(int artistId, {bool useAuth = false}) async {
    try {
      final path = ApiConstants.artistProfilePath(artistId);
      final response = await execute(
        'GET',
        path,
        visibility: useAuth ? ApiVisibility.private : ApiVisibility.public,
      );
      if (response.statusCode != 200) return null;
      final Map<String, dynamic>? data = _profileDataFromResponse(response);
      if (data == null) return null;
      return ArtistProfileResponse.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  /// Extracts profile map from response: either response.data or raw body if it has artist/albums/tracks.
  static Map<String, dynamic>? _profileDataFromResponse(http.Response response) {
    final body = response.body;
    if (body.isEmpty) return null;
    try {
      final map = jsonDecode(body) as Map<String, dynamic>?;
      if (map == null) return null;
      final wrapped = ApiClient.parseResponse(response);
      if (wrapped.$2 != null && wrapped.$2 is Map<String, dynamic>) return wrapped.$2!;
      // Backend may return raw { artist, albums, tracks } without success/data wrapper
      if (map.containsKey('artist')) return map;
      return null;
    } catch (_) {
      return null;
    }
  }

  /// GET music categories (genres). Public.
  Future<List<MusicCategoryItem>> getCategories() async {
    try {
      final response = await execute(
        'GET',
        ApiConstants.categoriesPath,
        visibility: ApiVisibility.public,
      );
      if (response.statusCode != 200) return [];
      final Map<String, dynamic>? data = _dataFromResponse(response);
      if (data == null) return [];
      final list = data['categories'] as List<dynamic>?;
      if (list == null) return [];
      return list
          .map((e) => MusicCategoryItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// GET album detail (public). Returns album info + tracks (audio or video by album_type).
  Future<AlbumDetailResponse?> getAlbumDetail(int albumId) async {
    try {
      final path = ApiConstants.albumDetailPath(albumId);
      final response = await execute(
        'GET',
        path,
        visibility: ApiVisibility.public,
      );
      if (response.statusCode != 200) return null;
      final Map<String, dynamic>? data = _dataFromResponse(response);
      if (data == null) return null;
      return AlbumDetailResponse.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic>? _dataFromResponse(http.Response response) {
    final body = response.body;
    if (body.isEmpty) return null;
    try {
      final map = jsonDecode(body) as Map<String, dynamic>?;
      if (map == null) return null;
      final wrapped = ApiClient.parseResponse(response);
      if (wrapped.$2 != null && wrapped.$2 is Map<String, dynamic>) return wrapped.$2!;
      return map;
    } catch (_) {
      return null;
    }
  }

  /// POST follow artist. **Private** — requires token.
  Future<bool> followArtist(int artistId) async {
    try {
      final path = ApiConstants.artistFollowPath(artistId);
      final response = await execute(
        'POST',
        path,
        body: {},
        visibility: ApiVisibility.private,
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  /// DELETE unfollow artist. **Private** — requires token.
  Future<bool> unfollowArtist(int artistId) async {
    try {
      final path = ApiConstants.artistUnfollowPath(artistId);
      final response = await execute(
        'DELETE',
        path,
        visibility: ApiVisibility.private,
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ---------- Favourites (album, track, video) — private ----------

  /// Check if album/track/video is in user's favourites. **Private.**
  Future<bool> checkFavourite(String entityType, int entityId) async {
    try {
      final path = '${ApiConstants.favouriteCheckPath()}?type=$entityType&id=$entityId';
      final response = await execute(
        'GET',
        path,
        visibility: ApiVisibility.private,
      );
      if (response.statusCode != 200) return false;
      final map = _dataFromResponse(response);
      final data = map ?? jsonDecode(response.body) as Map<String, dynamic>?;
      return data?['favourited'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Add album, track, or video to favourites. **Private.** [entityType] = album | track | video.
  Future<bool> addFavourite(String entityType, int entityId) async {
    try {
      final response = await execute(
        'POST',
        ApiConstants.favouritesPath,
        body: {'entityType': entityType, 'entityId': entityId},
        visibility: ApiVisibility.private,
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  /// Remove from favourites. **Private.**
  Future<bool> removeFavourite(String entityType, int entityId) async {
    try {
      final path = ApiConstants.favouriteRemovePath(entityType, entityId);
      final response = await execute(
        'DELETE',
        path,
        visibility: ApiVisibility.private,
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// List user's favourites. Optional [type] = album | track | video. **Private.**
  /// [limit] and [offset] for pagination; [enrich] returns title, albumArt, artistName, etc.
  Future<FavouritesListResponse> getFavourites({
    String? type,
    int? limit,
    int offset = 0,
    bool enrich = false,
  }) async {
    try {
      final q = <String>[];
      if (type != null) q.add('type=$type');
      if (limit != null) q.add('limit=$limit');
      if (offset > 0) q.add('offset=$offset');
      if (enrich) q.add('enrich=1');
      final path = q.isEmpty ? ApiConstants.favouritesPath : '${ApiConstants.favouritesPath}?${q.join('&')}';
      final response = await execute(
        'GET',
        path,
        visibility: ApiVisibility.private,
      );
      if (response.statusCode != 200) {
        return FavouritesListResponse(favourites: [], total: 0, limit: limit ?? 0, offset: offset);
      }
      final map = _dataFromResponse(response);
      final list = map?['favourites'] as List<dynamic>?;
      final total = (map?['total'] as num?)?.toInt() ?? 0;
      final limitVal = (map?['limit'] as num?)?.toInt() ?? limit ?? 0;
      final offsetVal = (map?['offset'] as num?)?.toInt() ?? offset;
      final favourites = list?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
      return FavouritesListResponse(favourites: favourites, total: total, limit: limitVal, offset: offsetVal);
    } catch (_) {
      return FavouritesListResponse(favourites: [], total: 0, limit: limit ?? 0, offset: offset);
    }
  }

  /// List artists the user follows. **Private.** Paginated.
  Future<FollowedArtistsResponse> getFollowedArtists({int limit = 20, int offset = 0}) async {
    try {
      final path = '${ApiConstants.followedArtistsPath}?limit=$limit&offset=$offset';
      final response = await execute(
        'GET',
        path,
        visibility: ApiVisibility.private,
      );
      if (response.statusCode != 200) {
        return FollowedArtistsResponse(artists: [], total: 0, limit: limit, offset: offset);
      }
      final map = _dataFromResponse(response);
      final data = map;
      if (data == null) {
        return FollowedArtistsResponse(artists: [], total: 0, limit: limit, offset: offset);
      }
      final list = data['artists'] as List<dynamic>?;
      final total = (data['total'] as num?)?.toInt() ?? 0;
      final limitVal = (data['limit'] as num?)?.toInt() ?? limit;
      final offsetVal = (data['offset'] as num?)?.toInt() ?? offset;
      final artists = list?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
      return FollowedArtistsResponse(artists: artists, total: total, limit: limitVal, offset: offsetVal);
    } catch (_) {
      return FollowedArtistsResponse(artists: [], total: 0, limit: limit, offset: offset);
    }
  }

  // ---------- Play history (record + top) ----------

  /// Record a play (audio or video). Auth optional; if token provided, user is associated.
  Future<bool> recordPlay(String entityType, int entityId) async {
    try {
      final response = await execute(
        'POST',
        ApiConstants.playHistoryPath,
        body: {'entityType': entityType, 'entityId': entityId},
        visibility: ApiVisibility.optional,
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  /// Home API: top audios and top videos; when token is sent, includes favouriteAudios, favouriteVideos, favouriteAlbums.
  Future<HomeTopResponse?> getHomeTop({int limit = 10}) async {
    try {
      final path = ApiConstants.homePath(limit);
      final response = await execute(
        'GET',
        path,
        visibility: ApiVisibility.optional,
      );
      if (response.statusCode != 200) return null;
      final map = _dataFromResponse(response);
      final data = map ?? jsonDecode(response.body) as Map<String, dynamic>?;
      if (data == null) return null;
      final topAudios = (data['topAudios'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [];
      final topVideos = (data['topVideos'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [];
      final favouriteAudios = (data['favouriteAudios'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [];
      final favouriteVideos = (data['favouriteVideos'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [];
      final favouriteAlbums = (data['favouriteAlbums'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [];
      final favouriteArtists = (data['favouriteArtists'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [];
      return HomeTopResponse(
        topAudios: topAudios,
        topVideos: topVideos,
        favouriteAudios: favouriteAudios,
        favouriteVideos: favouriteVideos,
        favouriteAlbums: favouriteAlbums,
        favouriteArtists: favouriteArtists,
      );
    } catch (_) {
      return null;
    }
  }

  /// Get top played tracks or videos (single type). Prefer [getHomeTop] for home screen.
  Future<List<Map<String, dynamic>>> getTopPlayed(String type, {int limit = 10}) async {
    try {
      final path = ApiConstants.playHistoryTopPath(type, limit);
      final response = await execute(
        'GET',
        path,
        visibility: ApiVisibility.public,
      );
      if (response.statusCode != 200) return [];
      final map = _dataFromResponse(response);
      final list = map?['items'] as List<dynamic>?;
      return list?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
    } catch (_) {
      return [];
    }
  }
}

/// Response from GET /api/v1/music/home. Favourite lists are present when user is logged in.
class HomeTopResponse {
  HomeTopResponse({
    required this.topAudios,
    required this.topVideos,
    this.favouriteAudios = const [],
    this.favouriteVideos = const [],
    this.favouriteAlbums = const [],
    this.favouriteArtists = const [],
  });
  final List<Map<String, dynamic>> topAudios;
  final List<Map<String, dynamic>> topVideos;
  final List<Map<String, dynamic>> favouriteAudios;
  final List<Map<String, dynamic>> favouriteVideos;
  final List<Map<String, dynamic>> favouriteAlbums;
  final List<Map<String, dynamic>> favouriteArtists;
}

/// Response from GET /api/v1/music/favourites with limit/offset/enrich.
class FavouritesListResponse {
  FavouritesListResponse({
    required this.favourites,
    required this.total,
    required this.limit,
    required this.offset,
  });
  final List<Map<String, dynamic>> favourites;
  final int total;
  final int limit;
  final int offset;
}

/// Response from GET /api/v1/music/followed-artists.
class FollowedArtistsResponse {
  FollowedArtistsResponse({
    required this.artists,
    required this.total,
    required this.limit,
    required this.offset,
  });
  final List<Map<String, dynamic>> artists;
  final int total;
  final int limit;
  final int offset;
}

/// Item from GET /api/v1/music/categories.
class MusicCategoryItem {
  MusicCategoryItem({
    required this.id,
    required this.name,
    required this.slug,
    this.imageUrl,
    required this.sortOrder,
  });
  final int id;
  final String name;
  final String slug;
  final String? imageUrl;
  final int sortOrder;

  factory MusicCategoryItem.fromJson(Map<String, dynamic> json) {
    return MusicCategoryItem(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }
}
