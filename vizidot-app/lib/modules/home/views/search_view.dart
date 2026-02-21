import 'package:flutter/material.dart' hide SearchController;
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:vizidot_flutter/modules/home/views/video_web_view.dart';

import '../controllers/search_controller.dart';
import '../widgets/search_category_tabs.dart';
import '../widgets/search_result_item.dart' as search_widget;
import '../../../routes/app_pages.dart';
import '../../../core/utils/app_config.dart';
import '../../../core/network/apis/music_api.dart';
import '../../music_player/utils/play_track_helper.dart';
import '../../music_player/utils/record_play_helper.dart';

class SearchView extends GetView<SearchController> {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final baseUrl = AppConfig.fromEnv().baseUrl.replaceFirst(RegExp(r'/$'), '');

    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Search'),
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
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colors.onSurface.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: CupertinoTextField(
                      onChanged: controller.setQuery,
                      placeholder: 'Search',
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: const BoxDecoration(),
                      prefix: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Icon(
                          CupertinoIcons.search,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ),
                      placeholderStyle: textTheme.bodyMedium?.copyWith(
                        fontSize: 16,
                        color: colors.onSurface.withOpacity(0.5),
                      ),
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 16,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Obx(() {
                    final category = controller.selectedCategory.value;
                    return SearchCategoryTabs(
                      selectedCategory: category,
                      onCategoryChanged: controller.setCategory,
                    );
                  }),
                  const SizedBox(height: 20),
                  Obx(() {
                    final loading = controller.isLoading.value;
                    final resultsList = controller.results.toList();
                    if (loading && resultsList.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(child: CupertinoActivityIndicator()),
                      );
                    }
                    if (resultsList.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text(
                            'No results',
                            style: textTheme.bodyLarge?.copyWith(
                              color: colors.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: resultsList.map((item) {
                        String? imageUrl = item.imageUrl;
                        if (imageUrl != null && imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
                          imageUrl = '$baseUrl${imageUrl.startsWith('/') ? '' : '/'}$imageUrl';
                        }
                        String? details;
                        bool showPlayIcon = false;
                        switch (item.type) {
                          case 'album':
                            details = item.trackLabel; // e.g. "12 songs" or "3 videos"
                            showPlayIcon = false;
                            break;
                          case 'music':
                          case 'video':
                            if (item.duration != null && item.duration! > 0) {
                              final m = item.duration! ~/ 60;
                              final s = item.duration! % 60;
                              details = '${m}:${s.toString().padLeft(2, '0')}';
                            }
                            showPlayIcon = true;
                            break;
                          default:
                            showPlayIcon = false; // artist
                        }
                        return search_widget.SearchResultItem(
                          imageUrl: imageUrl,
                          title: item.title,
                          subtitle: item.subtitle,
                          details: details,
                          showPlayIcon: showPlayIcon,
                          onTap: () => _onResultTap(item),
                        );
                      }).toList(),
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

  void _onResultTap(SearchResultItem item) {
    switch (item.type) {
      case 'artist':
        Get.toNamed(AppRoutes.artistDetail, parameters: {'id': item.id.toString()});
        break;
      case 'album':
        Get.toNamed(AppRoutes.albumDetail, arguments: {'albumId': item.id});
        break;
      case 'music':
        _playTrackFromSearch(item);
        break;
      case 'video':
        _openVideoFromSearch(item);
        break;
    }
  }

  Future<void> _playTrackFromSearch(SearchResultItem item) async {
    final baseUrl = AppConfig.fromEnv().baseUrl.replaceFirst(RegExp(r'/$'), '');
    String? albumArt = item.imageUrl;
    if (albumArt != null && albumArt.isNotEmpty && !albumArt.startsWith('http')) {
      albumArt = '$baseUrl${albumArt.startsWith('/') ? '' : '/'}$albumArt';
    }
    final parts = item.subtitle.split(' · ');
    final artist = parts.isNotEmpty ? parts.first : '';
    Duration duration = Duration.zero;
    if (item.duration != null && item.duration! > 0) {
      duration = Duration(seconds: item.duration!);
    }
    final played = await playTrack(
      title: item.title,
      artist: artist,
      albumArt: albumArt ?? '',
      audioUrl: item.audioUrl,
      duration: duration,
    );
    if (played) {
      recordPlayIfPossible('audio', item.id);
      Get.toNamed(AppRoutes.musicPlayer);
    }
  }

  void _openVideoFromSearch(SearchResultItem item) {
    final videoUrl = item.videoUrl;
    if (videoUrl != null && videoUrl.isNotEmpty) {
      recordPlayIfPossible('video', item.id);
      Get.to(() => VideoWebView(url: videoUrl));
    } else {
      if (item.albumId != null) {
        Get.toNamed(AppRoutes.albumDetail, arguments: {'albumId': item.albumId});
      }
    }
  }
}
