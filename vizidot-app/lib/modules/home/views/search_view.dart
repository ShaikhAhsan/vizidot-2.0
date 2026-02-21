import 'package:flutter/material.dart' hide SearchController;
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../controllers/search_controller.dart';
import '../widgets/search_category_tabs.dart';
import '../widgets/search_result_item.dart' as search_widget;
import '../../../routes/app_pages.dart';
import '../../../core/utils/app_config.dart';
import '../../../core/network/apis/music_api.dart';

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
                        if (item.duration != null && item.duration! > 0) {
                          final m = item.duration! ~/ 60;
                          final s = item.duration! % 60;
                          details = '${m}:${s.toString().padLeft(2, '0')}';
                        }
                        return search_widget.SearchResultItem(
                          imageUrl: imageUrl,
                          title: item.title,
                          subtitle: item.subtitle,
                          details: details,
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
        Get.toNamed(AppRoutes.albumDetail, parameters: {'id': item.id.toString()});
        break;
      case 'music':
      case 'video':
        if (item.albumId != null) {
          Get.toNamed(AppRoutes.albumDetail, parameters: {'id': item.albumId.toString()});
        }
        break;
    }
  }
}
