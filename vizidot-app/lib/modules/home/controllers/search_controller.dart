import 'dart:async';

import 'package:get/get.dart';

import '../../../core/network/apis/music_api.dart';
import '../../../core/utils/app_config.dart';
import '../widgets/search_category_tabs.dart';

class SearchController extends GetxController {
  final searchQuery = ''.obs;
  final selectedCategory = SearchCategory.all.obs;
  final results = <SearchResultItem>[].obs;
  final isLoading = false.obs;

  Timer? _debounce;
  static const _debounceMs = 350;

  @override
  void onInit() {
    super.onInit();
    loadSearch();
  }

  void setQuery(String q) {
    searchQuery.value = q;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: _debounceMs), () {
      loadSearch();
    });
  }

  void setCategory(SearchCategory cat) {
    selectedCategory.value = cat;
    loadSearch();
  }

  Future<void> loadSearch() async {
    isLoading.value = true;
    try {
      final config = AppConfig.fromEnv();
      final api = MusicApi(baseUrl: config.baseUrl);
      final resp = await api.search(
        q: searchQuery.value.trim(),
        type: selectedCategory.value.apiType,
        limit: 30,
      );
      if (resp != null) {
        results.assignAll(resp.results);
      } else {
        results.clear();
      }
    } catch (_) {
      results.clear();
    } finally {
      isLoading.value = false;
    }
  }
}
