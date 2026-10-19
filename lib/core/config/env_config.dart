import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/device_detector.dart';

class EnvConfig {
  static const String _prefBaseUrlKey = 'app_custom_base_url';
  static String _dynamicBaseUrl = '';

  static String get appName => dotenv.env['APP_NAME'] ?? 'ALL STARS ARENA';

  static String get baseUrl {
    if (_dynamicBaseUrl.isNotEmpty) return _dynamicBaseUrl;
    return dotenv.env['BASE_URL'] ?? 'http://192.168.1.21:5000/api/v1';
  }

  static set baseUrl(String url) {
    _dynamicBaseUrl = url.trim();
  }

  static String get razorpayKeyId => dotenv.env['RAZORPAY_KEY_ID'] ?? '';
  static int get connectTimeout =>
      int.parse(dotenv.env['CONNECT_TIMEOUT'] ?? '15000');
  static int get receiveTimeout =>
      int.parse(dotenv.env['RECEIVE_TIMEOUT'] ?? '15000');

  static Future<void> init({String envFile = '.env.dev'}) async {
    try {
      await dotenv.load(fileName: envFile);
    } catch (_) {}

    final isRealDevice = await DeviceDetector.isPhysicalDevice();

    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefBaseUrlKey);
      if (saved != null &&
          saved.trim().isNotEmpty &&
          !saved.contains('192.168.1.100') &&
          !saved.contains('192.168.1.23')) {
        _dynamicBaseUrl = saved.trim();
      }
    } catch (_) {}

    // Auto-adapt base URL if running on real physical mobile device vs emulator
    final current = baseUrl;
    if (isRealDevice &&
        (current.contains('10.0.2.2') ||
            current.contains('localhost') ||
            current.contains('127.0.0.1'))) {
      _dynamicBaseUrl =
          'https://integrity-bookmarks-options-matches.trycloudflare.com/api/v1';
    } else if (!isRealDevice &&
        (current.contains('192.168.1.') || current.isEmpty)) {
      _dynamicBaseUrl = 'http://10.0.2.2:5000/api/v1';
    }
  }

  static Future<void> saveBaseUrl(String newUrl) async {
    final clean = newUrl.trim();
    if (clean.isEmpty) return;
    _dynamicBaseUrl = clean;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefBaseUrlKey, clean);
    } catch (_) {}
  }
}
