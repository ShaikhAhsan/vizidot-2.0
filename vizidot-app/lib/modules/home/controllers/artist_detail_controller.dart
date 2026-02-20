import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../core/network/apis/music_api.dart';
import '../../../core/utils/app_config.dart';
import '../../../core/utils/auth_service.dart';
import '../../../data/models/artist_profile_response.dart';
import '../widgets/albums_section.dart';
import '../widgets/tracks_section.dart';
import '../widgets/videos_section.dart';

/// Controller for artist detail screen. Uses [MusicApi] for profile and
/// follow/unfollow; [AppConfig] for base URL; [AuthService] for token when needed.
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

  /// Artist shop URL from profile; null if no shop.
  String? get shopUrl =>
      profile.value?.artist.shop?.shopUrl;

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

  List<AlbumItem> get videoAlbums {
    final list = profile.value?.videoAlbums ?? [];
    final name = artistName;
    return list
        .map((a) => AlbumItem(
              title: a.title,
              artist: name,
              coverImage: a.coverImageUrl ?? '',
            ))
        .toList();
  }

  List<VideoItem> get videos {
    final list = profile.value?.videos ?? [];
    final name = artistName;
    return list
        .map((v) => VideoItem(
              title: v.title,
              artist: name,
              thumbnail: v.albumArt ?? '',
              duration: v.durationFormatted ?? '0:00',
              videoUrl: v.videoUrl ?? '',
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

  /// Fetches artist profile via [MusicApi].getArtistProfile (public API).
  Future<void> fetchProfile() async {
    if (artistId == null) {
      isLoading.value = false;
      return;
    }
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final config = AppConfig.fromEnv();
      final api = MusicApi(baseUrl: config.baseUrl);
      final result = await api.getArtistProfile(artistId!);
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

  /// Toggle follow state via [MusicApi] (auth required). Refreshes profile on success.
  /// In development, uses [AppConfig.testAccessToken] when not logged in so APIs work for testing.
  Future<void> toggleFollow() async {
    if (artistId == null) return;
    final config = AppConfig.fromEnv();
    final auth = Get.isRegistered<AuthService>() ? Get.find<AuthService>() : null;
    final token = await auth?.getIdToken();
    final effectiveToken = (token != null && token.isNotEmpty) ? token : config.testAccessToken;
    if (effectiveToken == null || effectiveToken.isEmpty) {
      Get.snackbar('Sign in to follow', 'Sign in to follow artists');
      return;
    }
    isFollowLoading.value = true;
    try {
      final api = MusicApi(baseUrl: config.baseUrl, authToken: effectiveToken);
      final currentlyFollowing = isFollowing.value;
      final success = currentlyFollowing
          ? await api.unfollowArtist(artistId!)
          : await api.followArtist(artistId!);
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
