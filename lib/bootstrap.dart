import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app/bindings/initial_binding.dart';
import 'core/config/env_config.dart';
import 'core/storage/preferences_service.dart';
import 'core/storage/database_service.dart';
import 'core/services/auth_service.dart';
import 'core/utils/app_logger.dart';

Future<void> bootstrap({String envFile = '.env.dev'}) async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await EnvConfig.init(envFile: envFile);
    AppLogger.info('⚡ Environment config loaded: ${EnvConfig.appName}');
  } catch (e) {
    AppLogger.warning(
        'Failed to load env config, falling back to defaults: $e');
  }

  try {
    final prefs = PreferencesService();
    await prefs.init();
    Get.put<PreferencesService>(prefs, permanent: true);
  } catch (e) {
    AppLogger.error('Failed to initialize SharedPreferences', e);
  }

  try {
    final dbService = DatabaseService();
    await dbService.init();
    Get.put<DatabaseService>(dbService, permanent: true);
  } catch (e) {
    AppLogger.error('Failed to initialize SQLite Database', e);
  }

  // Register remaining core dependencies
  InitialBinding().dependencies();

  // Initialize AuthService (checks persisted login token)
  try {
    await Get.find<AuthService>().init();
  } catch (e) {
    AppLogger.error('Failed to initialize AuthService', e);
  }
}
