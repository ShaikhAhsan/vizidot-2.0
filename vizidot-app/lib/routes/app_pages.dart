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
  ];
}


