import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';

class EnvConfig {
  static const String _prefBaseUrlKey = 'app_custom_base_url';
  static String _customBaseUrl = '';

  static String get appName => dotenv.env['APP_NAME'] ?? 'ALL STARS ARENA';

  /// Primary getter for backend Base URL.
  /// If a runtime custom URL is set, it returns that.
  /// Otherwise, it returns the BASE_URL from the .env file.
  static String get baseUrl {
    if (_customBaseUrl.trim().isNotEmpty) {
      return _customBaseUrl.trim();
    }
    final envUrl = dotenv.env['BASE_URL']?.trim();
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }
    return 'http://192.168.1.28:5000/api/v1';
  }

  static set baseUrl(String url) {
    _customBaseUrl = url.trim();
  }

  static String get razorpayKeyId =>
      dotenv.env['RAZORPAY_KEY_ID'] ?? 'rzp_test_Sb44esbmpGlzBd';

  static int get connectTimeout {
    final val = dotenv.env['CONNECT_TIMEOUT'];
    return val != null ? (int.tryParse(val) ?? 15000) : 15000;
  }

  static int get receiveTimeout {
    final val = dotenv.env['RECEIVE_TIMEOUT'];
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

    // Clear stale cached base URLs from SharedPreferences if they contain old unreachable IPs
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefBaseUrlKey)?.trim();
      final envUrl = dotenv.env['BASE_URL']?.trim() ?? '';

      if (saved != null && saved.isNotEmpty) {
        if (saved.contains('192.168.1.21') ||
            saved.contains('192.168.1.100') ||
            saved.contains('192.168.1.23')) {
          await prefs.remove(_prefBaseUrlKey);
          _customBaseUrl = '';
          AppLogger.info(
              '🧹 Cleared stale cached Base URL ($saved) in favor of .env ($envUrl)');
        } else {
          _customBaseUrl = saved;
        }
      }
    } catch (_) {}

    AppLogger.info('🚀 Active BASE_URL: $baseUrl');
  }

  /// Save new custom Base URL at runtime
  static Future<void> saveBaseUrl(String newUrl) async {
    final clean = newUrl.trim();
    if (clean.isEmpty) return;
    _customBaseUrl = clean;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefBaseUrlKey, clean);
      AppLogger.info('💾 Custom Base URL saved: $clean');
    } catch (e) {
      AppLogger.error('Failed to save custom Base URL', e);
    }
  }

  /// Reset Base URL back to `.env` default
  static Future<void> resetBaseUrl() async {
    _customBaseUrl = '';
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefBaseUrlKey);
      AppLogger.info('🔄 Base URL reset to .env default: $baseUrl');
    } catch (e) {
      AppLogger.error('Failed to reset Base URL', e);
    }
  }
}
