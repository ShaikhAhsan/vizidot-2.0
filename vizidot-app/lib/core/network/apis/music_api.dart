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
  Future<ArtistProfileResponse?> getArtistProfile(int artistId) async {
    try {
      final path = ApiConstants.artistProfilePath(artistId);
      final response = await execute(
        'GET',
        path,
        visibility: ApiVisibility.public,
      );
      if (response.statusCode != 200) return null;
      final parsed = ApiClient.parseResponse(response);
      if (!parsed.$1) return null;
      final data = parsed.$2;
      if (data == null || data is! Map<String, dynamic>) return null;
      return ArtistProfileResponse.fromJson(data);
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
