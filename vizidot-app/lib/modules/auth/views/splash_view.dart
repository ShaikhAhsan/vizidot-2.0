import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/auth_service.dart';
import '../../../core/utils/user_profile_service.dart';
import '../../../routes/app_pages.dart';

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    Future.microtask(() async {
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
      // Logged in: fetch user profile into singleton, then route by isOnboarded
      final profileService = Get.find<UserProfileService>();
      final profile = await profileService.loadFromApi();
      final isOnboarded = profile?.isOnboarded ?? false;
      final next = isOnboarded ? AppRoutes.home : AppRoutes.categories;
      Get.offAllNamed(next);
    });
    return const Scaffold(body: SizedBox());
  }
}


