import 'package:get/get.dart';

import '../modules/home/views/home_view.dart';
import '../modules/home/views/details_view.dart';
import '../modules/auth/views/sign_in_view.dart';
import '../modules/auth/views/forgot_password_view.dart';
import '../modules/auth/views/new_password_view.dart';
import '../modules/auth/views/sign_up_view.dart';
import '../modules/auth/bindings/auth_binding.dart';
import '../modules/auth/views/splash_view.dart';
import '../modules/auth/views/auth_landing_view.dart';
import '../modules/onboarding/views/categories_view.dart';
import '../modules/onboarding/bindings/categories_binding.dart';
import '../modules/onboarding/views/artists_view.dart';
import '../modules/onboarding/bindings/artists_binding.dart';
import '../modules/home/views/artist_detail_view.dart';
import '../modules/home/views/album_detail_view.dart';
import '../modules/home/views/playlist_detail_view.dart';
import '../modules/home/views/settings_view.dart';
import '../modules/home/views/personal_data_view.dart';
import '../modules/home/views/change_password_view.dart';
import '../modules/home/views/upload_view.dart';
import '../modules/home/views/notifications_view.dart';
import '../modules/home/views/search_view.dart';
import '../modules/home/views/filters_view.dart';
import '../modules/music_player/views/music_player_view.dart';
import '../modules/music_player/bindings/music_player_binding.dart';
import '../modules/home/widgets/tracks_section.dart';

part 'app_routes.dart';

class AppPages {
  static final routes = <GetPage<dynamic>>[
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
    ),
    GetPage(
      name: AppRoutes.landing,
      page: () => const AuthLandingView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeView(),
    ),
    GetPage(
      name: AppRoutes.signIn,
      page: () => const SignInView(),
      binding: AuthBinding(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.signUp,
      page: () => const SignUpView(),
      binding: AuthBinding(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const ForgotPasswordView(),
      binding: AuthBinding(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.newPassword,
      page: () => const NewPasswordView(),
      binding: AuthBinding(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.details,
      page: () => const DetailsView(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.categories,
      page: () => const CategoriesView(),
      binding: CategoriesBinding(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.artists,
      page: () => const ArtistsView(),
      binding: ArtistsBinding(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.artistDetail,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        return ArtistDetailView(
          artistName: args['artistName'] ?? '',
          artistImage: args['artistImage'] ?? '',
          description: args['description'],
          followers: args['followers'],
          following: args['following'],
        );
      },
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.albumDetail,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final tracksList = args['tracks'] as List?;
        final tracks = tracksList?.map((t) {
          if (t is TrackItem) {
            return t;
          } else if (t is Map) {
            return TrackItem(
              title: t['title'] ?? '',
              artist: t['artist'] ?? '',
              albumArt: t['albumArt'] ?? '',
              duration: t['duration'] ?? '',
            );
          }
          throw ArgumentError('Invalid track item type');
        }).toList().cast<TrackItem>() ?? [];
        
        return AlbumDetailView(
          albumTitle: args['albumTitle'] ?? '',
          albumImage: args['albumImage'] ?? '',
          releaseYear: args['releaseYear'],
          songCount: args['songCount'],
          totalDuration: args['totalDuration'],
          tracks: tracks,
        );
      },
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.playlistDetail,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final tracksList = args['tracks'] as List?;
        final tracks = tracksList?.map((t) {
          if (t is PlaylistTrackItem) {
            return t;
          } else if (t is Map) {
            return PlaylistTrackItem(
              title: t['title'] ?? '',
              artist: t['artist'] ?? '',
              albumArt: t['albumArt'] ?? '',
            );
          }
          throw ArgumentError('Invalid track item type');
        }).toList().cast<PlaylistTrackItem>() ?? [];
        
        return PlaylistDetailView(
          playlistName: args['playlistName'] ?? '',
          playlistImage: args['playlistImage'] ?? '',
          artistName: args['artistName'] ?? '',
          likes: args['likes'],
          duration: args['duration'],
          tracks: tracks,
        );
      },
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsView(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.personalData,
      page: () => const PersonalDataView(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.changePassword,
      page: () => const ChangePasswordView(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.upload,
      page: () => const UploadView(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.notifications,
      page: () => const NotificationsView(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.search,
      page: () => const SearchView(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.filters,
      page: () => const FiltersView(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.musicPlayer,
      page: () => const MusicPlayerView(),
      binding: MusicPlayerBinding(),
      transition: Transition.cupertino,
    ),
  ];
}


