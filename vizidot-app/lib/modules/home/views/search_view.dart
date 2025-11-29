import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../widgets/search_category_tabs.dart';
import '../widgets/search_result_item.dart';
import '../../../routes/app_pages.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final TextEditingController _searchController = TextEditingController();
  SearchCategory _selectedCategory = SearchCategory.albums;

  // Dummy data for albums
  final List<Map<String, String>> _albums = const [
    {
      'image': 'assets/artists/Choc B.png',
      'title': 'This is Harry Styles',
      'subtitle': 'Album / 2021',
      'details': '18 Songs - 2h 20min',
    },
    {
      'image': 'assets/artists/Choc B.png',
      'title': 'Love on Tour 2023',
      'subtitle': 'Album / 2021',
      'details': '18 Songs - 2h 20min',
    },
    {
      'image': 'assets/artists/Choc B.png',
      'title': 'The setlist march',
      'subtitle': 'Album / 2021',
      'details': '18 Songs - 2h 20min',
    },
    {
      'image': 'assets/artists/Choc B.png',
      'title': 'All songs, live & covers',
      'subtitle': 'Album / 2021',
      'details': '18 Songs - 2h 20min',
    },
    {
      'image': 'assets/artists/Choc B.png',
      'title': 'This is Harry Styles',
      'subtitle': 'Album / 2021',
      'details': '18 Songs - 2h 20min',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          // Navigation Bar with Large Title - matching home screen
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
                  Get.toNamed(AppRoutes.filters);
                },
                child: const Icon(
                  CupertinoIcons.slider_horizontal_3,
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
                  // Search Bar
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
                      controller: _searchController,
                      placeholder: 'Search',
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: const BoxDecoration(),
                      prefix: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Icon(
                          CupertinoIcons.search,
                          color: colors.onSurface.withOpacity(0.5),
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
                  // Category Tabs
                  SearchCategoryTabs(
                    selectedCategory: _selectedCategory,
                    onCategoryChanged: (category) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  // Search Results
                  ..._albums.map((album) {
                    return SearchResultItem(
                      imageUrl: album['image']!,
                      title: album['title']!,
                      subtitle: album['subtitle']!,
                      details: album['details']!,
                      onTap: () {
                        // TODO: Navigate to album detail
                      },
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

