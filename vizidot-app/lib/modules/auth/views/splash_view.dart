import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import '../../../core/utils/auth_service.dart';

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
      final next = auth.isLoggedIn.value ? AppRoutes.categories : AppRoutes.signIn;
      Get.offAllNamed(next);
    });
    return const Scaffold(body: SizedBox());
  }
}


