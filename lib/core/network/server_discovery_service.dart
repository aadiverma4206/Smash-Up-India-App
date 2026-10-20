import 'package:dio/dio.dart';
import '../config/env_config.dart';
import '../utils/app_logger.dart';

/// Server Discovery Service using EnvConfig.baseUrl strictly from .env
class ServerDiscoveryService {
  static const String prefKeyTunnelUrl = 'cctv_public_tunnel_url';

  /// Test if the configured BASE_URL from .env is reachable
  static Future<String?> findWorkingServer([String? priorityUrl]) async {
    final candidate = (priorityUrl != null && priorityUrl.isNotEmpty)
        ? priorityUrl
        : EnvConfig.baseUrl;

    if (candidate.isEmpty) return null;

    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(milliseconds: 3000),
        receiveTimeout: const Duration(milliseconds: 3000),
        headers: {'Accept': 'application/json'},
      ),
    );

    try {
      final rootUrl = candidate.replaceAll(RegExp(r'/api/v1/?$'), '');
      try {
        final res = await dio.get('$rootUrl/api/v1/health');
        if (res.statusCode == 200) {
          AppLogger.info('✅ Connected successfully to health: $candidate');
          return candidate;
        }
      } catch (_) {
        final res = await dio.get('$rootUrl/');
        if (res.statusCode == 200) {
          AppLogger.info('✅ Connected successfully to root: $candidate');
          return candidate;
        }
      }
    } catch (e) {
      AppLogger.warning('Server discovery probe failed for $candidate: $e');
    }

    return null;
  }

  /// Cache public tunnel URL if needed
  static Future<void> saveTunnelUrl(String url) async {}

  /// Ensure active Dio instance uses EnvConfig.baseUrl from .env
  static Future<bool> handleConnectionFailure(Dio dio) async {
    final currentBase = EnvConfig.baseUrl;
    if (currentBase.isNotEmpty && dio.options.baseUrl != currentBase) {
      dio.options.baseUrl = currentBase;
      AppLogger.info(
          '🔄 [ServerDiscovery] Ensured active baseUrl is set to .env: $currentBase');
      return true;
    }
    return false;
  }
}
