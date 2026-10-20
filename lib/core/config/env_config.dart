import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';

class EnvConfig {
  static const String _prefBaseUrlKey = 'app_custom_base_url';

  static String get appName =>
      dotenv.env['APP_NAME']?.trim() ?? 'ALL STARS ARENA';

  /// Primary getter for backend Base URL.
  /// Always reads strictly from the .env file.
  static String get baseUrl {
    final envUrl = dotenv.env['BASE_URL']?.trim();
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }
    return '';
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

  /// Initialize Environment Configuration.
  /// Attempts to load `.env` file first, falling back to `.env.example`.
  static Future<void> init({String envFile = '.env'}) async {
    bool loaded = false;

    // 1. Try specified envFile (.env)
    try {
      await dotenv.load(fileName: envFile);
      loaded = true;
      AppLogger.info('⚡ Environment file loaded successfully: $envFile');
    } catch (e) {
      AppLogger.warning('Failed to load $envFile: $e');
    }

    // 2. Fallback to .env.example if needed
    if (!loaded) {
      try {
        await dotenv.load(fileName: '.env.example');
        loaded = true;
        AppLogger.info('⚡ Fallback environment file loaded: .env.example');
      } catch (e) {
        AppLogger.warning('Failed to load .env.example fallback: $e');
      }
    }

    // Clear any stale cached base URL overrides from SharedPreferences so .env is the single source of truth
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefBaseUrlKey);
    } catch (_) {}

    AppLogger.info('🚀 Active BASE_URL from .env: $baseUrl');
  }

  /// Compatibility method for saving custom Base URL
  static Future<void> saveBaseUrl(String newUrl) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefBaseUrlKey);
    } catch (_) {}
  }

  /// Reset Base URL back to `.env` default
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
