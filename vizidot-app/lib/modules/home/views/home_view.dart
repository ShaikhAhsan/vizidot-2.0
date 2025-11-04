import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/theme_controller.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../controllers/home_controller.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/custom_nav_bar.dart';
import '../../../routes/app_pages.dart';
import 'profile_view.dart';
import 'elocker_view.dart';
import '../bindings/elocker_binding.dart';
import '../controllers/elocker_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    
    // Initialize E-locker controller if not already initialized
    if (!Get.isRegistered<ELockerController>()) {
      ELockerBinding().dependencies();
    }
    
    final pages = <Widget>[
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Obx(() => Text('Counter: ${controller.counter.value}', style: Theme.of(context).textTheme.headlineMedium)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton(onPressed: controller.increment, child: const Text('Increment')),
                OutlinedButton(onPressed: themeController.toggleTheme, child: const Text('Toggle Theme')),
                TextButton(onPressed: () => Get.toNamed(AppRoutes.details), child: const Text('Open Details')),
              ],
            ),
            const SizedBox(height: 24),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: AppSearchBar()),
          ],
        ),
      ),
      const ELockerView(),
      const Center(child: Text('Shop')),
      const Center(child: Text('Streaming')),
      const ProfileView(),
    ];

    return Obx(() => Scaffold(
      appBar: controller.selectedIndex.value == 1 
          ? null 
          : const HomeAppBar(title: 'Vizidot'),
      body: pages[controller.selectedIndex.value],
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
    ));
  }
}


