import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/auth_service.dart';
import '../../../core/utils/user_profile_service.dart';
import '../../../routes/app_pages.dart';

/// Matches LaunchScreen.storyboard: full-screen background + centered logo.
class SplashView extends StatelessWidget {
  const SplashView({super.key});

  static const Color _lightBackground = Color(0xFFFFFFFF);
  static const Color _darkBackground = Color(0xFF000000);

  /// Prevents multiple navigations when build() runs more than once.
  static bool _navigateStarted = false;

  @override
  Widget build(BuildContext context) {
    if (!_navigateStarted) {
      _navigateStarted = true;
      Future.microtask(_navigateAfterInit);
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? _darkBackground : _lightBackground;
    final logoAsset = isDark ? 'assets/splash/splash_dark.png' : 'assets/splash/splash.png';
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: Image.asset(
            logoAsset,
            fit: BoxFit.contain,
            width: 188,
            height: 225,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  Future<void> _navigateAfterInit() async {
    AuthService auth;
    if (!Get.isRegistered<AuthService>()) {
      auth = await Get.putAsync<AuthService>(() async => AuthService().init(), permanent: true);
    } else {
      auth = Get.find<AuthService>();
    }
    if (!auth.isLoggedIn.value) {
      if (Get.isRegistered<UserProfileService>()) {
        Get.find<UserProfileService>().clearProfile();
      }
      Get.offAllNamed(AppRoutes.landing);
      return;
    }
    final profileService = Get.find<UserProfileService>();
    final profile = await profileService.loadFromApi();
    final isOnboarded = profile?.isOnboarded ?? false;
    final next = isOnboarded ? AppRoutes.home : AppRoutes.categories;
    Get.offAllNamed(next);
  }
}


