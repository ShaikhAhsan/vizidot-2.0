import 'package:get/get.dart';

import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/artist_profile_response.dart';

/// Public API: get artist profile (no auth). Used by ArtistDetailView.
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
}
