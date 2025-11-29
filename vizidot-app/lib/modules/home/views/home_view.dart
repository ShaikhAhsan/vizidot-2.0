import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/home_controller.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/custom_nav_bar.dart';
import 'profile_view.dart';
import 'elocker_view.dart';
import 'shop_view.dart';
import 'home_content_view.dart';
import 'streaming_view.dart';
import '../bindings/elocker_binding.dart';
import '../controllers/elocker_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize E-locker controller if not already initialized
    if (!Get.isRegistered<ELockerController>()) {
      ELockerBinding().dependencies();
    }
    
    final pages = <Widget>[
      const HomeContentView(),
      const ELockerView(),
      const ShopView(),
      const StreamingView(),
      const ProfileView(),
    ];

    return Obx(() => Scaffold(
      appBar: null,

      // (controller.selectedIndex.value == 1 || controller.selectedIndex.value == 0)
      //     ? null
      //     : const HomeAppBar(title: 'Vizidot'),
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


