import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class AppImageCache {
  static final BaseCacheManager _cache = DefaultCacheManager();

  static Future<void> prefetchAll(Iterable<String> urls) async {
    final List<Future<void>> tasks = <Future<void>>[];
    for (final String url in urls) {
      if (url.isEmpty) continue;
      tasks.add(_cache.downloadFile(url).then((_) {}));
    }
    await Future.wait(tasks);
  }

  static Future<void> prefetch(String url) async {
    if (url.isEmpty) return;
    await _cache.downloadFile(url);
  }

  static Future<void> clear() async {
    await _cache.emptyCache();
  }
}


