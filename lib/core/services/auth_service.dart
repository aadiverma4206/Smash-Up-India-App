import 'package:get/get.dart';
import '../../data/models/user_model.dart';
import '../storage/secure_storage_service.dart';
import '../storage/database_service.dart';
import '../storage/preferences_service.dart';
import '../utils/app_logger.dart';
import 'notification_service.dart';
import '../../modules/auth/repositories/auth_repository.dart';
import '../../modules/player/controllers/player_controller.dart';
import '../../app/routes/app_routes.dart';

class AuthService extends GetxService {
  static AuthService get to => Get.find();

  final SecureStorageService _secureStorage = Get.find<SecureStorageService>();

  final Rxn<UserModel> currentUser = Rxn<UserModel>();
  final RxBool isLoggedIn = false.obs;

  Future<void> init() async {
    final token = await _secureStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      isLoggedIn.value = true;
    }
  }

  void setLoggedInUser(
      UserModel user, String accessToken, String refreshToken) {
    currentUser.value = user;
    isLoggedIn.value = true;
    _secureStorage.saveTokens(
        accessToken: accessToken, refreshToken: refreshToken);

    if (Get.isRegistered<NotificationService>()) {
      try {
        Get.find<NotificationService>().registerFcmTokenWithBackend();
      } catch (_) {}
    }
  }

  /// Comprehensive logout: invalidates server session, deletes tokens from secure storage,
  /// clears SQLite local cache, clears SharedPreferences user data, resets GetX state,
  /// and redirects to login screen.
  Future<void> logout() async {
    AppLogger.info(
        '🔑 Initiating complete user logout and local data purge...');

    // 0. Close active GetX dialogs/overlays safely before navigation
    if (Get.isDialogOpen ?? false) {
      Get.back();
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // 0.5. Unregister FCM token from backend before clearing credentials
    if (Get.isRegistered<NotificationService>()) {
      try {
        await Get.find<NotificationService>().unregisterFcmTokenFromBackend();
      } catch (e) {
        AppLogger.warning('FCM token unregistration failed during logout: $e');
      }
    }

    // 1. Invalidate server session if AuthRepository is available
    if (Get.isRegistered<AuthRepository>()) {
      try {
        final repo = Get.find<AuthRepository>();
        await repo.logout();
      } catch (e) {
        AppLogger.warning('Server logout call failed or offline: $e');
      }
    }

    // 2. Clear Secure Storage (tokens & secrets)
    try {
      if (Get.isRegistered<SecureStorageService>()) {
        final secureStorage = Get.find<SecureStorageService>();
        await secureStorage.clearTokens();
        await secureStorage.clearAll();
      }
    } catch (e) {
      AppLogger.error('Failed to clear SecureStorage during logout: $e');
    }

    // 3. Clear SQLite Local Database Cache
    try {
      if (Get.isRegistered<DatabaseService>()) {
        await Get.find<DatabaseService>().clearAllData();
      }
    } catch (e) {
      AppLogger.error('Failed to clear SQLite DB cache during logout: $e');
    }

    // 4. Clear SharedPreferences user data
    try {
      if (Get.isRegistered<PreferencesService>()) {
        await Get.find<PreferencesService>().clearUserData();
      }
    } catch (e) {
      AppLogger.error('Failed to clear PreferencesService during logout: $e');
    }

    // 5. Reset In-Memory Auth & App State
    currentUser.value = null;
    isLoggedIn.value = false;

    // 6. Delete active GetX controllers holding user data
    if (Get.isRegistered<PlayerController>()) {
      Get.delete<PlayerController>(force: true);
    }

    AppLogger.info(
        '✅ Logout completed and all device local/cached user data removed.');

    // 7. Route to Login and clear route backstack
    Get.offAllNamed(Routes.login);
  }
}
