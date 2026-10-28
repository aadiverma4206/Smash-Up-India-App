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

  bool get isPlayer =>
      currentUser.value?.isPlayer ?? (currentUser.value?.roleId == 3);
  bool get isAdmin =>
      currentUser.value?.isAdmin ?? (currentUser.value?.roleId == 1);
  bool get isManager =>
      currentUser.value?.isManager ?? (currentUser.value?.roleId == 2);

  Future<void> init() async {
    final token = await _secureStorage.getAccessToken();
    final savedUser = await _secureStorage.getUser();
    if (token != null && token.isNotEmpty && savedUser != null) {
      currentUser.value = savedUser;
      isLoggedIn.value = true;
      AppLogger.info(
          '🔑 Restored persistent user session: ${savedUser.name} (Role: ${savedUser.roleId})');
    } else if (token != null && token.isNotEmpty) {
      isLoggedIn.value = true;
    }
  }

  void setLoggedInUser(
      UserModel user, String accessToken, String refreshToken) {
    currentUser.value = user;
    isLoggedIn.value = true;
    _secureStorage.saveTokens(
        accessToken: accessToken, refreshToken: refreshToken);
    _secureStorage.saveUser(user);

    if (Get.isRegistered<NotificationService>()) {
      try {
        Get.find<NotificationService>().registerFcmTokenWithBackend();
      } catch (_) {}
    }
  }

  Future<void> logout() async {
    AppLogger.info(
        '🔑 Initiating complete user logout and local data purge...');

    if (Get.isDialogOpen ?? false) {
      Get.back();
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (Get.isRegistered<NotificationService>()) {
      try {
        await Get.find<NotificationService>().unregisterFcmTokenFromBackend();
      } catch (e) {
        AppLogger.warning('FCM token unregistration failed during logout: $e');
      }
    }

    if (Get.isRegistered<AuthRepository>()) {
      try {
        final repo = Get.find<AuthRepository>();
        await repo.logout();
      } catch (e) {
        AppLogger.warning('Server logout call failed or offline: $e');
      }
    }

    try {
      if (Get.isRegistered<SecureStorageService>()) {
        final secureStorage = Get.find<SecureStorageService>();
        await secureStorage.clearTokens();
        await secureStorage.clearAll();
      }
    } catch (e) {
      AppLogger.error('Failed to clear SecureStorage during logout: $e');
    }

    try {
      if (Get.isRegistered<DatabaseService>()) {
        await Get.find<DatabaseService>().clearAllData();
      }
    } catch (e) {
      AppLogger.error('Failed to clear SQLite DB cache during logout: $e');
    }

    try {
      if (Get.isRegistered<PreferencesService>()) {
        await Get.find<PreferencesService>().clearAll();
      }
    } catch (e) {
      AppLogger.error('Failed to clear PreferencesService during logout: $e');
    }

    currentUser.value = null;
    isLoggedIn.value = false;

    if (Get.isRegistered<PlayerController>()) {
      Get.delete<PlayerController>(force: true);
    }

    AppLogger.info(
        '✅ Logout completed and all device local/cached user data removed.');

    Get.offAllNamed(Routes.login);
  }
}
