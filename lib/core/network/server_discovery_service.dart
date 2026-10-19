import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/env_config.dart';
import '../utils/app_logger.dart';
import '../utils/device_detector.dart';

/// Production-ready Dynamic Server Discovery & Failover Service.
/// Automatically detects and switches to working backend host across:
/// 1. Current WiFi LAN IP (e.g. 192.168.1.21 - Botivate_5g)
/// 2. Public Cloudflare Tunnel (Universal - Mobile Data 4G/5G & Real Physical Mobile Devices)
/// 3. Android Emulator Host Loopback (10.0.2.2)
/// 4. Localhost / ADB (127.0.0.1)
class ServerDiscoveryService {
  static const String prefKeyTunnelUrl = 'cctv_public_tunnel_url';

  /// Test a list of candidates in priority order based on physical device vs emulator
  static Future<String?> findWorkingServer([String? priorityUrl]) async {
    final isRealDevice = await DeviceDetector.isPhysicalDevice();
    final candidates = <String>[];

    // Priority 1: Current EnvConfig.baseUrl if valid
    final current = priorityUrl ?? EnvConfig.baseUrl;
    if (current.isNotEmpty) {
      if (!isRealDevice ||
          (!current.contains('10.0.2.2') && !current.contains('127.0.0.1'))) {
        candidates.add(current);
      }
    }

    // Priority 2: Saved public tunnel URL
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTunnel = prefs.getString(prefKeyTunnelUrl);
      if (savedTunnel != null && savedTunnel.isNotEmpty) {
        final tunnelApi = savedTunnel.endsWith('/api/v1')
            ? savedTunnel
            : '${savedTunnel.replaceAll(RegExp(r'/$'), '')}/api/v1';
        if (!candidates.contains(tunnelApi)) candidates.add(tunnelApi);
      }
    } catch (_) {}

    // Priority 3: Public Cloudflare Tunnel (Universal for Real Phones & Mobile Data 4G/5G)
    const publicTunnel =
        'https://integrity-bookmarks-options-matches.trycloudflare.com/api/v1';
    if (!candidates.contains(publicTunnel)) candidates.add(publicTunnel);

    // Priority 4: WiFi LAN IPs
    const lan1 = 'http://192.168.1.21:5000/api/v1';
    const lan2 = 'http://192.168.1.23:5000/api/v1';
    if (!candidates.contains(lan1)) candidates.add(lan1);
    if (!candidates.contains(lan2)) candidates.add(lan2);

    // Priority 5: Emulator Host Loopback (10.0.2.2 / 127.0.0.1) - ONLY for emulators
    if (!isRealDevice) {
      const emu = 'http://10.0.2.2:5000/api/v1';
      const local = 'http://127.0.0.1:5000/api/v1';
      if (!candidates.contains(emu)) candidates.add(emu);
      if (!candidates.contains(local)) candidates.add(local);
    }

    AppLogger.info(
        '🔍 [ServerDiscovery] Probing backend candidates (isPhysicalDevice=$isRealDevice): $candidates');

    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(milliseconds: 2000),
        receiveTimeout: const Duration(milliseconds: 2000),
        headers: {'Accept': 'application/json'},
      ),
    );

    for (final candidate in candidates) {
      try {
        final rootUrl = candidate.replaceAll(RegExp(r'/api/v1/?$'), '');
        final res = await dio.get('$rootUrl/');
        if (res.statusCode == 200) {
          AppLogger.info(
              '✅ [ServerDiscovery] Connected successfully to: $candidate');
          return candidate;
        }
      } catch (_) {
        // Candidate failed, try next
      }
    }

    return null;
  }

  /// Cache public tunnel URL discovered from backend or user configuration
  static Future<void> saveTunnelUrl(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefKeyTunnelUrl, url.trim());
      AppLogger.info('💾 [ServerDiscovery] Cached public tunnel URL: $url');
    } catch (_) {}
  }

  /// Automatically attempt failover when a network request experiences a connection error or timeout
  static Future<bool> handleConnectionFailure(Dio dio) async {
    final workingServer = await findWorkingServer();
    if (workingServer != null && workingServer != dio.options.baseUrl) {
      AppLogger.info(
          '🔄 [ServerDiscovery] Switching active baseUrl to: $workingServer');
      dio.options.baseUrl = workingServer;
      await EnvConfig.saveBaseUrl(workingServer);
      return true;
    }
    return false;
  }
}
