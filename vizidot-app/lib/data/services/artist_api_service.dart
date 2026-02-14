import 'package:get/get.dart';

import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/artist_profile_response.dart';

/// Artist API: profile (public) and follow/unfollow (auth required).
class ArtistApiService extends GetxService {
  ArtistApiService(this._client);

  final ApiClient _client;

  /// GET artist profile for app. Public endpoint.
  /// Returns null on failure.
  Future<ArtistProfileResponse?> getArtistProfile(int artistId) async {
    try {
      final path = ApiConstants.artistProfilePath(artistId);
      final response = await _client.get(path, useAuth: false);

      if (response.statusCode != 200) {
        return null;
      }
      final parsed = ApiClient.parseResponse(response);
      if (!parsed.$1) {
        return null;
      }
      final data = parsed.$2;
      if (data == null || data is! Map<String, dynamic>) {
        return null;
      }
      return ArtistProfileResponse.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  /// POST follow artist. Requires authenticated client (useAuth: true).
  /// Returns true on success (201/200), false otherwise.
  Future<bool> followArtist(int artistId) async {
    try {
      final path = ApiConstants.artistFollowPath(artistId);
      final response = await _client.post(path, body: {}, useAuth: true);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  /// DELETE unfollow artist. Requires authenticated client (useAuth: true).
  /// Returns true on success (200), false otherwise.
  Future<bool> unfollowArtist(int artistId) async {
    try {
      final path = ApiConstants.artistUnfollowPath(artistId);
      final response = await _client.delete(path, useAuth: true);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
