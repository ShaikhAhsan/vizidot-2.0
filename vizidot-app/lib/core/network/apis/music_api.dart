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
  Future<List<Map<String, dynamic>>> getFavourites({String? type}) async {
    try {
      final path = type != null ? '${ApiConstants.favouritesPath}?type=$type' : ApiConstants.favouritesPath;
      final response = await execute(
        'GET',
        path,
        visibility: ApiVisibility.private,
      );
      if (response.statusCode != 200) return [];
      final map = _dataFromResponse(response);
      final list = map?['favourites'] as List<dynamic>?;
      return list?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
    } catch (_) {
      return [];
    }
  }
}
