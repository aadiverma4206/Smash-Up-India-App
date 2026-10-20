import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'app/bindings/initial_binding.dart';
import 'core/config/env_config.dart';
import 'core/storage/preferences_service.dart';
import 'core/storage/database_service.dart';
import 'core/services/auth_service.dart';
import 'core/utils/app_logger.dart';
import 'firebase_options.dart';

Future<void> bootstrap({String envFile = '.env'}) async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      AppLogger.info('🔥 Firebase initialized successfully during bootstrap.');
    }
  } catch (e) {
    AppLogger.warning(
        'Firebase initialization skipped or failed during bootstrap: $e');
  }

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

  try {
    InitialBinding().dependencies();
  } catch (e) {
    AppLogger.error('Failed to initialize InitialBinding dependencies', e);
  }

  try {
    await Get.find<AuthService>().init();
  } catch (e) {
    AppLogger.error('Failed to initialize AuthService', e);
  }
}
