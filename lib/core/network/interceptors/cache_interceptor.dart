import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';

class CustomCacheInterceptor {
  static CacheOptions get cacheOptions => CacheOptions(
        store: MemCacheStore(),
        policy: CachePolicy.request,
        hitCacheOnErrorExcept: [401, 403, 422],
        maxStale: const Duration(days: 1),
        priority: CachePriority.normal,
        cipher: null,
        keyBuilder: CacheOptions.defaultCacheKeyBuilder,
        allowPostMethod: false,
      );

  static DioCacheInterceptor get interceptor =>
      DioCacheInterceptor(options: cacheOptions);

  static bool isUncacheableRoute(String path) {
    return path.contains('/wallet') ||
        path.contains('/bookings') ||
        path.contains('/payments') ||
        path.contains('/cctv');
  }
}
