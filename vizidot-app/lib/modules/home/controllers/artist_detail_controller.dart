import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/app_config.dart';
import '../../../core/utils/auth_service.dart';
import '../../../data/models/artist_profile_response.dart';
import '../../../data/services/artist_api_service.dart';
import '../widgets/albums_section.dart';
import '../widgets/tracks_section.dart';

class ArtistDetailController extends GetxController {
  ArtistDetailController({required this.artistId});

  final int? artistId;

  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;
  final Rxn<ArtistProfileResponse> profile = Rxn<ArtistProfileResponse>();
  final RxBool isFollowing = false.obs;
  final RxBool isFollowLoading = false.obs;

  String get artistName =>
      profile.value?.artist.name ?? '';
  String get artistImage =>
      profile.value?.artist.imageUrl ?? '';
  String get description =>
      profile.value?.artist.bio ?? 'Artist / Musician / Writer';
  int get followers =>
      profile.value?.artist.followersCount ?? 0;
  int get following =>
      profile.value?.artist.followingCount ?? 0;
  bool get hasShop =>
      profile.value?.artist.shop != null;

  List<AlbumItem> get albums {
    final list = profile.value?.albums ?? [];
    final name = artistName;
    return list
        .map((a) => AlbumItem(
              title: a.title,
              artist: name,
              coverImage: a.coverImageUrl ?? '',
            ))
        .toList();
  }

  List<TrackItem> get tracks {
    final list = profile.value?.tracks ?? [];
    final name = artistName;
    return list
        .map((t) => TrackItem(
              title: t.title,
              artist: name,
              albumArt: t.albumArt ?? '',
              duration: t.durationFormatted ?? '0:00',
            ))
        .toList();
  }

  @override
  void onReady() {
    if (artistId != null) {
      fetchProfile();
    } else {
      isLoading.value = false;
    }
    super.onReady();
  }

  Future<void> fetchProfile() async {
    if (artistId == null) {
      isLoading.value = false;
      return;
    }
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final config = AppConfig.fromEnv();
      final client = ApiClient(baseUrl: config.baseUrl);
      final service = ArtistApiService(client);
      final result = await service.getArtistProfile(artistId!);
      if (result != null) {
        profile.value = result;
      } else {
        errorMessage.value = 'Could not load artist';
      }
    } catch (e) {
      errorMessage.value = 'Something went wrong';
    } finally {
      isLoading.value = false;
    }
  }

  /// Toggle follow state: call API (auth required) and refresh profile on success.
  /// If not logged in, shows snackbar and returns.
  Future<void> toggleFollow() async {
    if (artistId == null) return;
    final auth = Get.isRegistered<AuthService>() ? Get.find<AuthService>() : null;
    final token = await auth?.getIdToken();
    if (token == null || token.isEmpty) {
      Get.snackbar('Sign in to follow', 'Sign in to follow artists');
      return;
    }
    isFollowLoading.value = true;
    try {
      final config = AppConfig.fromEnv();
      final client = ApiClient(baseUrl: config.baseUrl, authToken: token);
      final service = ArtistApiService(client);
      final currentlyFollowing = isFollowing.value;
      final success = currentlyFollowing
          ? await service.unfollowArtist(artistId!)
          : await service.followArtist(artistId!);
      if (success) {
        isFollowing.value = !currentlyFollowing;
        await fetchProfile();
      } else {
        Get.snackbar('Error', 'Could not update follow');
      }
    } catch (_) {
      Get.snackbar('Error', 'Something went wrong');
    } finally {
      isFollowLoading.value = false;
    }
  }
}
