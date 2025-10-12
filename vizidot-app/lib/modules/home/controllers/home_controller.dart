import 'package:get/get.dart';
import '../../../core/utils/image_cache.dart';

class HomeController extends GetxController {
  final RxInt counter = 0.obs;
  final RxInt selectedIndex = 0.obs;
  final List<String> _prefetchUrls = <String>[];

  void increment() {
    counter.value++;
  }

  void onNavTap(int index) {
    selectedIndex.value = index;
  }

  void setPrefetchUrls(List<String> urls) {
    _prefetchUrls
      ..clear()
      ..addAll(urls);
  }

  Future<void> prefetchImages() async {
    await AppImageCache.prefetchAll(_prefetchUrls);
  }
}


