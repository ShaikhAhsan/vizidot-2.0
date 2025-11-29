import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../widgets/section_header.dart';
import '../widgets/notification_item.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  // Dummy data for recent notifications
  final List<Map<String, String>> _recentNotifications = const [
    {
      'image': 'assets/artists/Choc B.png',
      'text': 'julz_free mentioned you in a comment: @yana_sic this looks..',
      'timestamp': '3:24',
    },
    {
      'image': 'assets/artists/Choc B.png',
      'text': 'julz_free mentioned you in a comment: @yana_sic this looks..',
      'timestamp': '3:24',
    },
    {
      'image': 'assets/artists/Choc B.png',
      'text': 'julz_free mentioned you in a comment: @yana_sic this looks..',
      'timestamp': '3:24',
    },
  ];

  // Dummy data for albums notifications
  final List<Map<String, String>> _albumsNotifications = const [
    {
      'image': 'assets/artists/Choc B.png',
      'text': 'julz_free mentioned you in a comment: @yana_sic this looks..',
      'timestamp': '3:24',
    },
    {
      'image': 'assets/artists/Choc B.png',
      'text': 'julz_free mentioned you in a comment: @yana_sic this looks..',
      'timestamp': '3:24',
    },
    {
      'image': 'assets/artists/Choc B.png',
      'text': 'julz_free mentioned you in a comment: @yana_sic this looks..',
      'timestamp': '3:24',
    },
    {
      'image': 'assets/artists/Choc B.png',
      'text': 'julz_free mentioned you in a comment: @yana_sic this looks..',
      'timestamp': '3:24',
    },
    {
      'image': 'assets/artists/Choc B.png',
      'text': 'julz_free mentioned you in a comment: @yana_sic this looks..',
      'timestamp': '3:24',
    },
    {
      'image': 'assets/artists/Choc B.png',
      'text': 'julz_free mentioned you in a comment: @yana_sic this looks..',
      'timestamp': '3:24',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          // Navigation Bar with Large Title - matching home screen
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Notifications'),
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              onPressed: () => Get.back(),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  CupertinoIcons.arrow_left,
                  color: colors.onSurface,
                  size: 18,
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
                  const SizedBox(height: 12),
                  // RECENT Section
                  const SectionHeader(title: 'RECENT'),
                  const SizedBox(height: 16),
                  ..._recentNotifications.map((notification) {
                    return NotificationItem(
                      profileImage: notification['image']!,
                      notificationText: notification['text']!,
                      timestamp: notification['timestamp']!,
                    );
                  }),
                  const SizedBox(height: 32),
                  // ALBUMS Section
                  const SectionHeader(title: 'ALBUMS'),
                  const SizedBox(height: 16),
                  ..._albumsNotifications.map((notification) {
                    return NotificationItem(
                      profileImage: notification['image']!,
                      notificationText: notification['text']!,
                      timestamp: notification['timestamp']!,
                    );
                  }),
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

