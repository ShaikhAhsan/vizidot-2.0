import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../widgets/streamer_profile_card.dart';
import '../widgets/live_session_card.dart';
import '../../../routes/app_pages.dart';

class StreamingView extends StatelessWidget {
  const StreamingView({super.key});

  // Dummy data for streamers
  final List<Map<String, dynamic>> _streamers = const [
    {'image': 'assets/artists/Choc B.png', 'name': 'Jane', 'isLive': false},
    {'image': 'assets/artists/Choc B.png', 'name': 'Kaleb', 'isLive': true},
    {'image': 'assets/artists/Choc B.png', 'name': 'Simon', 'isLive': true},
    {'image': 'assets/artists/Choc B.png', 'name': 'Lusy', 'isLive': false},
    {'image': 'assets/artists/Choc B.png', 'name': 'Kory', 'isLive': false},
  ];

  // Dummy data for live sessions with dynamic heights
  final List<Map<String, dynamic>> _liveSessions = const [
    {
      'image': 'assets/artists/Choc B.png',
      'title': 'Live at New York sess...',
      'artist': '30 Seconds to Mars',
      'viewers': '1.2K',
      'height': 117.0,
    },
    {
      'image': 'assets/artists/Choc B.png',
      'title': 'LA live session',
      'artist': '30 Seconds to Mars',
      'viewers': '1.2K',
      'height': 192.0,
    },
    {
      'image': 'assets/artists/Choc B.png',
      'title': 'New York live session',
      'artist': '30 Seconds to Mars',
      'viewers': '1.2K',
      'height': 157.0,
    },
    {
      'image': 'assets/artists/Choc B.png',
      'title': 'Concert hall live',
      'artist': '30 Seconds to Mars',
      'viewers': '1.2K',
      'height': 192.0,
    },
    {
      'image': 'assets/artists/Choc B.png',
      'title': 'Live session',
      'artist': '30 Seconds to Mars',
      'viewers': '1.2K',
      'height': 117.0,
    },
    {
      'image': 'assets/artists/Choc B.png',
      'title': 'Live session',
      'artist': '30 Seconds to Mars',
      'viewers': '1.2K',
      'height': 192.0,
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
            largeTitle: const Text('Streaming now'),
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
                  Get.toNamed(AppRoutes.search);
                },
                child: const Icon(
                  CupertinoIcons.search,
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
                  const SizedBox(height: 12),
                  // Streamer Profiles - Horizontal Scroll
                  SizedBox(
                    height: 90,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _streamers.length,
                      itemBuilder: (context, index) {
                        final streamer = _streamers[index];
                        return StreamerProfileCard(
                          imageUrl: streamer['image'] as String,
                          name: streamer['name'] as String,
                          isLive: streamer['isLive'] as bool,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ),
          // Live Sessions Grid - using SliverMasonryGrid for 2 columns
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverMasonryGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 20,
              crossAxisSpacing: 16,
              itemBuilder: (context, index) {
                final session = _liveSessions[index];
                return LiveSessionCard(
                  imageUrl: session['image'] as String,
                  title: session['title'] as String,
                  artistName: session['artist'] as String,
                  viewerCount: session['viewers'] as String,
                  imageHeight: session['height'] as double,
                  onTap: () {
                    // TODO: Navigate to live session detail
                  },
                );
              },
              childCount: _liveSessions.length,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: const SizedBox(height: 24),
            ),
          ),
        ],
      ),
    );
  }
}

