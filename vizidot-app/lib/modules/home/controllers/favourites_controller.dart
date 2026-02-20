import 'package:get/get.dart';

import '../../../core/network/apis/music_api.dart';
import '../../../core/utils/app_config.dart';
import '../../../core/utils/auth_service.dart';

class FavouritesController extends GetxController {
  static const int pageSize = 20;

  final RxString selectedType = 'track'.obs; // track | video | album
  final RxList<Map<String, dynamic>> items = <Map<String, dynamic>>[].obs;
  final RxInt total = 0.obs;
  final RxBool isLoading = false.obs;
  final RxBool hasMore = true.obs;
  int _offset = 0;

  @override
  void onInit() {
    super.onInit();
    loadPage();
  }

  Future<void> loadPage() async {
    if (!Get.isRegistered<AuthService>()) return;
    final auth = Get.find<AuthService>();
    final token = await auth.getIdToken();
    if (token == null || token.isEmpty) return;
    isLoading.value = true;
    try {
      final config = AppConfig.fromEnv();
      final api = MusicApi(baseUrl: config.baseUrl, authToken: token);
      final res = await api.getFavourites(
        type: selectedType.value,
        limit: pageSize,
        offset: _offset,
        enrich: true,
      );
      items.addAll(res.favourites);
      total.value = res.total;
      hasMore.value = items.length < res.total;
      _offset += res.favourites.length;
    } catch (_) {
      hasMore.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  void setType(String type) {
    if (selectedType.value == type) return;
    selectedType.value = type;
    items.clear();
    _offset = 0;
    hasMore.value = true;
    loadPage();
  }

  Future<void> loadMore() async {
    if (isLoading.value || !hasMore.value) return;
    await loadPage();
  }

  void refresh() {
    items.clear();
    _offset = 0;
    hasMore.value = true;
    loadPage();
  }
}
