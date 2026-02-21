import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/utils/auth_service.dart';
import '../../../routes/app_pages.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_menu_item.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  String _version = '1.0.0';
  String _buildNumber = '1';

  @override
  void initState() {
    super.initState();
    _loadVersionInfo();
  }

  Future<void> _loadVersionInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          // Navigation Bar with Large Title - matching home screen
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Profile'),
            trailing: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(32, 32),
                onPressed: () {
                  Get.toNamed(AppRoutes.settings);
                },
                child: const Icon(
                  CupertinoIcons.gear,
                  color: Colors.black,
                  size: 20,
                ),
              ),
            ),
            backgroundColor: Colors.transparent,
            border: null,
            automaticallyImplyTitle: false,
            automaticallyImplyLeading: false,
          ),
          SliverSafeArea(
            top: false,
            sliver: SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 10),
                  // Profile Header
                  const ProfileHeader(
                    profileImage: 'assets/artists/Choc B.png',
                    name: 'Jacob Lee',
                    role: 'Artist / Musician / Writer',
                  ),
                  const SizedBox(height: 40),
                  // Menu Items
                  ProfileMenuItem(
                    icon: CupertinoIcons.person_circle,
                    title: 'My Profile',
                    onTap: () {
                      // TODO: Navigate to my profile
                    },
                  ),
                  ProfileMenuItem(
                    icon: CupertinoIcons.person_2,
                    title: 'Upload',
                    onTap: () {
                      Get.toNamed(AppRoutes.upload);
                    },
                  ),
                  ProfileMenuItem(
                    icon: CupertinoIcons.person,
                    title: 'Personal data',
                    onTap: () {
                      Get.toNamed(AppRoutes.personalData);
                    },
                  ),
                  if (Get.isRegistered<AuthService>() && Get.find<AuthService>().canChangePassword)
                    ProfileMenuItem(
                      icon: CupertinoIcons.lock,
                      title: 'Change password',
                      onTap: () {
                        Get.toNamed(AppRoutes.changePassword);
                      },
                    ),
                  ProfileMenuItem(
                    icon: CupertinoIcons.lightbulb,
                    title: 'Announcements',
                    onTap: () {
                      Get.toNamed(AppRoutes.notifications);
                    },
                  ),
                  const SizedBox(height: 40),
                  // Version Info
                  Center(
                    child: Text(
                      'Version $_version (Build $_buildNumber)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            fontSize: 12,
                          ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
