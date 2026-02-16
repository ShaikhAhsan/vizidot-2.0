import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api_client.dart';
import '../base_api.dart';
import '../../constants/api_constants.dart';
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

  /// GET artist profile. **Public** — no token.
  /// Accepts both wrapped { success, data: { artist, albums, tracks } } and raw { artist, albums, tracks }.
  Future<ArtistProfileResponse?> getArtistProfile(int artistId) async {
    try {
      final path = ApiConstants.artistProfilePath(artistId);
      final response = await execute(
        'GET',
        path,
        visibility: ApiVisibility.public,
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
}
