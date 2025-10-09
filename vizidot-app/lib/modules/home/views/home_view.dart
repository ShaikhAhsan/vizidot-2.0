import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/theme_controller.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../controllers/home_controller.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/custom_nav_bar.dart';
import '../../../routes/app_pages.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    return Scaffold(
      appBar: const HomeAppBar(title: 'Vizidot'),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Obx(() => Text(
                  'Counter: ${controller.counter.value}',
                  style: Theme.of(context).textTheme.headlineMedium,
                )),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton(
                  onPressed: controller.increment,
                  child: const Text('Increment'),
                ),
                OutlinedButton(
                  onPressed: themeController.toggleTheme,
                  child: const Text('Toggle Theme'),
                ),
                TextButton(
                  onPressed: () => Get.toNamed(AppRoutes.details),
                  child: const Text('Open Details'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const AppSearchBar(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomNavBar(
        selectedIndex: controller.selectedIndex,
        onItemTapped: controller.onNavTap,
        assetNames: const [
          // Order: Home, eLocker, Shop, Streaming, Profile
          'tab-home-ic.png',
          'tab-elocker-ic.png',
          'tab-shop-ic.png',
          'tab-streaming-ic.png',
          'tab-profile-ic.png',
        ],
      ),
    );
  }
}


