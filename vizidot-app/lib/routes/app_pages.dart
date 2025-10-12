import 'package:get/get.dart';

import '../modules/home/views/home_view.dart';
import '../modules/home/views/details_view.dart';
import '../modules/auth/views/sign_in_view.dart';
import '../modules/auth/views/forgot_password_view.dart';
import '../modules/auth/views/new_password_view.dart';
import '../modules/auth/views/sign_up_view.dart';
import '../modules/auth/bindings/auth_binding.dart';

part 'app_routes.dart';

class AppPages {
  static final routes = <GetPage<dynamic>>[
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
  ];
}


