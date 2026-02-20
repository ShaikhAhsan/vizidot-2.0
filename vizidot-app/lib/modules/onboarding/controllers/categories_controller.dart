import 'package:get/get.dart';

import '../../../core/network/apis/music_api.dart';
import '../../../core/utils/app_config.dart';

class CategoryItem {
  final int id;
  final String name;
  final String? imageUrl; // full URL when from API

  CategoryItem({required this.id, required this.name, this.imageUrl});
}

class CategoriesController extends GetxController {
  final items = <CategoryItem>[].obs;
  final isLoading = true.obs;

  final selected = <int>{}.obs;

  bool get canContinue => selected.length >= 3;

  @override
  void onInit() {
    super.onInit();
    loadCategories();
  }

  Future<void> loadCategories() async {
    isLoading.value = true;
    try {
      final config = AppConfig.fromEnv();
      final api = MusicApi(baseUrl: config.baseUrl);
      final list = await api.getCategories();
      final baseUrl = config.baseUrl.replaceFirst(RegExp(r'/$'), '');
      items.assignAll(
        list.map((c) {
          final raw = c.imageUrl;
          final String? imageUrl;
          if (raw == null || raw.isEmpty) {
            imageUrl = null;
          } else if (raw.startsWith('http://') || raw.startsWith('https://')) {
            imageUrl = raw; // use full URL as-is (e.g. Firebase Storage)
          } else {
            imageUrl = '$baseUrl${raw.startsWith('/') ? '' : '/'}$raw';
          }
          return CategoryItem(id: c.id, name: c.name, imageUrl: imageUrl);
        }),
      );
    } catch (_) {
      items.clear();
    } finally {
      isLoading.value = false;
    }
  }

  void toggle(int index) {
    if (index < 0 || index >= items.length) return;
    final id = items[index].id;
    if (selected.contains(id)) {
      selected.remove(id);
    } else {
      selected.add(id);
    }
    selected.refresh();
  }

  void toggleByIndex(int index) {
    toggle(index);
  }
}
