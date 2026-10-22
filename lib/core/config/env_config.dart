import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';

class EnvConfig {
  static const String _prefBaseUrlKey = 'app_custom_base_url';

  static String get appName =>
      dotenv.env['APP_NAME']?.trim() ?? 'ALL STARS ARENA';

  static String get baseUrl {
    final envUrl = dotenv.env['BASE_URL'];
    return _sanitizeUrl(envUrl);
  }

  static String get razorpayKeyId =>
      dotenv.env['RAZORPAY_KEY_ID']?.trim() ?? '';

  static int get connectTimeout {
    final val = dotenv.env['CONNECT_TIMEOUT']?.trim();
    return val != null ? (int.tryParse(val) ?? 15000) : 15000;
  }

  static int get receiveTimeout {
    final val = dotenv.env['RECEIVE_TIMEOUT']?.trim();
    return val != null ? (int.tryParse(val) ?? 15000) : 15000;
  }

  /// Sanitizes and extracts pure, valid HTTP/HTTPS URL from `.env` strings
  /// even if comments like `(For Android Emulator)` or `# local dev` were appended on the same line.
  static String _sanitizeUrl(String? raw) {
    if (raw == null) return '';
    var url = raw.trim();
    if (url.isEmpty) return '';

    // Strip inline comment starting with #
    if (url.contains('#')) {
      url = url.split('#').first.trim();
    }

    // Extract valid HTTP/HTTPS URL and drop any trailing descriptions/text
    final urlMatch = RegExp(r'https?://[^\s#()]+').firstMatch(url);
    if (urlMatch != null) {
      url = urlMatch.group(0) ?? url;
    }

    // Remove trailing slashes
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }

    return url;
  }

  static Future<void> init({String envFile = '.env'}) async {
    bool loaded = false;

    try {
      await dotenv.load(fileName: envFile);
      loaded = true;
      AppLogger.info('⚡ Environment file loaded successfully: $envFile');
    } catch (e) {
      AppLogger.warning('Failed to load $envFile: $e');
    }

    if (!loaded) {
      try {
        await dotenv.load(fileName: '.env.example');
        loaded = true;
        AppLogger.info('⚡ Fallback environment file loaded: .env.example');
      } catch (e) {
        AppLogger.warning('Failed to load .env.example fallback: $e');
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefBaseUrlKey);
    } catch (_) {}

    AppLogger.info('🚀 Active BASE_URL from .env: $baseUrl');
  }

  static Future<void> saveBaseUrl(String newUrl) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefBaseUrlKey);
    } catch (_) {}
  }

  static Future<void> resetBaseUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefBaseUrlKey);
      AppLogger.info('🔄 Base URL set to .env default: $baseUrl');
    } catch (e) {
      AppLogger.error('Failed to reset Base URL', e);
    }
  }
}
