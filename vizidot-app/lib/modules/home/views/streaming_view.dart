import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../widgets/streamer_profile_card.dart';
import '../widgets/live_session_card.dart';
import '../../../routes/app_pages.dart';
import '../../../core/utils/selected_artist_service.dart';
import '../../live_stream/models/live_stream_model.dart';
import '../../live_stream/views/broadcast_page.dart';

class StreamingView extends StatelessWidget {
  const StreamingView({super.key});

  static const String _placeholderAsset = 'assets/artists/Choc B.png';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final firebaseUid = FirebaseAuth.instance.currentUser?.uid;
    final currentBroadcasterUid = Get.isRegistered<SelectedArtistService>()
        ? Get.find<SelectedArtistService>().broadcasterUidOrNull(firebaseUid)
        : firebaseUid;

    return CupertinoPageScaffold(
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('LiveStreams')
            .orderBy('dateUpdated', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CupertinoActivityIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          var liveStreams = docs.map((doc) {
            final data = doc.data();
            final model = LiveStreamModel.fromMap(data);
            model.identifier = doc.id;
            if (model.channel.isEmpty) {
              model.channel = doc.id;
            }
            return model;
          }).toList();

          // Don't show the broadcaster their own stream in the list
          if (currentBroadcasterUid != null && currentBroadcasterUid.isNotEmpty) {
            liveStreams =
                liveStreams.where((s) => s.broadcasterUid != currentBroadcasterUid).toList();
          }

          return CustomScrollView(
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
              if (liveStreams.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'No one is live right now.\nBe the first to go live!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.onSurface.withOpacity(0.6),
                          ),
                    ),
                  ),
                )
              else ...[
                SliverSafeArea(
                  top: false,
                  sliver: SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const SizedBox(height: 12),
                        // Streamer Profiles - Horizontal Scroll (unique by name)
                        SizedBox(
                          height: 90,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: liveStreams.length,
                            itemBuilder: (context, index) {
                              final stream = liveStreams[index];
                              final name = stream.name.isNotEmpty
                                  ? stream.name
                                  : 'Live Stream';
                              final imageUrl = stream.photo.isNotEmpty
                                  ? stream.photo
                                  : _placeholderAsset;
                              return StreamerProfileCard(
                                imageUrl: imageUrl,
                                name: name,
                                isLive: true,
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
                      final stream = liveStreams[index];
                      const heights = [117.0, 192.0, 157.0, 192.0];
                      final height = heights[index % heights.length];
                      final title =
                          stream.desc.isNotEmpty ? stream.desc : stream.name;
                      final artistName =
                          stream.name.isNotEmpty ? stream.name : 'Live Stream';
                      final imageUrl = stream.photo.isNotEmpty
                          ? stream.photo
                          : _placeholderAsset;
                      return LiveSessionCard(
                        imageUrl: imageUrl,
                        title: title,
                        artistName: artistName,
                        viewerCount: 'Live',
                        imageHeight: height,
                        onTap: () {
                          Get.to(() => BroadcastPage(
                                isBroadcaster: false,
                                liveStream: stream,
                              ));
                        },
                      );
                    },
                    childCount: liveStreams.length,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: const SizedBox(height: 24),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

