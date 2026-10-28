import 'dart:async';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../repositories/auth_repository.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/storage/database_service.dart';
import '../../../data/models/login_request_model.dart';
import '../../../data/models/register_model.dart';
import '../../../data/models/user_model.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/config/env_config.dart';
import '../../../core/utils/app_logger.dart';

class AuthController extends GetxController {
  final AuthRepository repository = Get.find<AuthRepository>();
  final SecureStorageService secureStorage = Get.find<SecureStorageService>();

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  final RxInt registrationStep = 1.obs;
  final RxString regName = ''.obs;
  final RxString regEmail = ''.obs;
  final RxString regPhone = ''.obs;
  final RxString regCity = 'Raipur'.obs;
  final RxString regVerificationToken = ''.obs;

  final RxInt otpTimerSeconds = 60.obs;
  final RxBool canResendOtp = false.obs;
  Timer? _timer;

  final RxString forgotIdentifier = ''.obs;
  final RxString resetToken = ''.obs;

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  void startOtpTimer() {
    otpTimerSeconds.value = 60;
    canResendOtp.value = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (otpTimerSeconds.value > 0) {
        otpTimerSeconds.value--;
      } else {
        canResendOtp.value = true;
        timer.cancel();
      }
    });
  }

  Future<void> checkAuthStatusAndRoute() async {
    isLoading.value = true;
    try {
      final token = await secureStorage.getAccessToken();
      final cachedUser = await secureStorage.getUser();

      if (token != null && token.isNotEmpty) {
        if (cachedUser != null) {
          AuthService.to.currentUser.value = cachedUser;
          AuthService.to.isLoggedIn.value = true;
        }

        final isOnline = Get.isRegistered<ConnectivityService>()
            ? ConnectivityService.to.isConnected.value
            : true;

        if (isOnline) {
          try {
            final UserModel user =
                await repository.getMe().timeout(const Duration(seconds: 4));

            if (user.status == 'SUSPENDED') {
              await AuthService.to.logout();
              Get.offAllNamed(Routes.login);
              ErrorHandler.showErrorSnackBar('Account Suspended',
                  'Your account has been suspended by administration. Please contact support.');
              return;
            }

            AuthService.to.currentUser.value = user;
            AuthService.to.isLoggedIn.value = true;
            await secureStorage.saveUser(user);

            if (Get.isRegistered<DatabaseService>()) {
              await Get.find<DatabaseService>().recordOnlineSync();
            }

            routeUserByRole(user.roleId);
            return;
          } catch (onlineErr) {
            AppLogger.warning(
                'Online profile sync timed out or failed: $onlineErr. Falling back to persistent offline credentials.');

            // Only logout if server explicitly responded with 401 Unauthorized (token invalid/revoked)
            if (onlineErr is DioException &&
                onlineErr.response?.statusCode == 401) {
              await AuthService.to.logout();
              Get.offAllNamed(Routes.login);
              return;
            }

            // Otherwise (no internet, timeout, server down): Seamlessly route using cached user!
            if (cachedUser != null) {
              if (Get.isRegistered<DatabaseService>()) {
                await Get.find<DatabaseService>().checkAndPruneIfOfflineExpired(
                  maxAge: const Duration(days: 3),
                );
              }
              routeUserByRole(cachedUser.roleId);
              return;
            }
          }
        } else {
          // Device is completely OFFLINE without internet
          if (cachedUser != null) {
            AppLogger.info(
                '📱 Device is offline: Restoring persistent offline session for role: ${cachedUser.roleId}');

            if (Get.isRegistered<DatabaseService>()) {
              await Get.find<DatabaseService>().checkAndPruneIfOfflineExpired(
                maxAge: const Duration(days: 3),
              );
            }

            routeUserByRole(cachedUser.roleId);
            return;
          }
        }
      }
    } catch (e) {
      AppLogger.warning('Session check exception: $e');
    } finally {
      isLoading.value = false;
    }

    Get.offAllNamed(Routes.login);
  }

  void routeUserByRole(int roleId) {
    if (roleId == 1) {
      Get.offAllNamed(Routes.adminDashboard);
    } else if (roleId == 2) {
      Get.offAllNamed(Routes.cctvDashboard);
    } else {
      Get.offAllNamed(Routes.home);
    }
  }

  Future<void> login(String identifier, String password) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final request = LoginRequestModel(
        identifier: identifier.trim(),
        password: password,
      );

      final response =
          await repository.login(request).timeout(const Duration(seconds: 12));

      if (response.user.status == 'SUSPENDED') {
        const suspendedMsg =
            'Your account has been suspended by administration. Please contact support.';
        errorMessage.value = suspendedMsg;
        ErrorHandler.showErrorSnackBar('Account Suspended', suspendedMsg);
        return;
      }

      AuthService.to.setLoggedInUser(
          response.user, response.accessToken, response.refreshToken);
      routeUserByRole(response.user.roleId);
    } on TimeoutException {
      final host = Uri.tryParse(EnvConfig.baseUrl)?.host ?? EnvConfig.baseUrl;
      final timeoutMsg =
          'Server at $host did not respond. Check your connection or verify that the backend is running.';
      errorMessage.value = timeoutMsg;
      ErrorHandler.showErrorSnackBar('Connection Timeout', timeoutMsg);
    } catch (e) {
      final msg = ErrorHandler.getErrorMessage(e);
      errorMessage.value = msg;
      ErrorHandler.showErrorSnackBar('Login Failed', e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> sendRegisterOtp(
      String name, String email, String phone, String city) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      regName.value = name;
      regEmail.value = email;
      regPhone.value = phone;
      regCity.value = city;

      final request = RegisterSendOtpRequestModel(
        name: name,
        email: email,
        phone: phone,
        city: city,
      );

      await repository
          .sendRegisterOtp(request)
          .timeout(const Duration(seconds: 20));
      startOtpTimer();
      registrationStep.value = 2;
    } on TimeoutException {
      const timeoutMsg =
          'Registration Timed Out: Server took too long to respond (20s limit).';
      errorMessage.value = timeoutMsg;
      ErrorHandler.showErrorSnackBar('Timeout Error', timeoutMsg);
    } catch (e) {
      final msg = ErrorHandler.getErrorMessage(e);
      errorMessage.value = msg;
      ErrorHandler.showErrorSnackBar('Registration Error', e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyRegisterOtp(String emailOtp) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final request = RegisterVerifyOtpRequestModel(
        name: regName.value,
        email: regEmail.value,
        phone: regPhone.value,
        emailOtp: emailOtp,
      );

      final token = await repository
          .verifyRegisterOtp(request)
          .timeout(const Duration(seconds: 20));
      regVerificationToken.value = token;
      registrationStep.value = 3;
    } on TimeoutException {
      const timeoutMsg =
          'OTP Verification Timed Out: Server took too long to respond (20s limit).';
      errorMessage.value = timeoutMsg;
      ErrorHandler.showErrorSnackBar('Timeout Error', timeoutMsg);
    } catch (e) {
      final msg = ErrorHandler.getErrorMessage(e);
      errorMessage.value = msg;
      ErrorHandler.showErrorSnackBar('Verification Failed', e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> registerPlayer(String password) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final request = RegisterPlayerRequestModel(
        name: regName.value,
        email: regEmail.value,
        phone: regPhone.value,
        password: password,
        city: regCity.value,
        verificationToken: regVerificationToken.value,
      );

      final response = await repository
          .registerPlayer(request)
          .timeout(const Duration(seconds: 20));
      AuthService.to.setLoggedInUser(
          response.user, response.accessToken, response.refreshToken);

      registrationStep.value = 4;
      routeUserByRole(response.user.roleId);
    } on TimeoutException {
      const timeoutMsg =
          'Registration Timed Out: Server took too long to respond (20s limit).';
      errorMessage.value = timeoutMsg;
      ErrorHandler.showErrorSnackBar('Timeout Error', timeoutMsg);
    } catch (e) {
      final msg = ErrorHandler.getErrorMessage(e);
      errorMessage.value = msg;
      ErrorHandler.showErrorSnackBar('Registration Failed', e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> forgotPasswordSendOtp(String identifier) async {
    isLoading.value = true;
    try {
      forgotIdentifier.value = identifier;
      await repository
          .forgotSendOtp(identifier)
          .timeout(const Duration(seconds: 20));
      startOtpTimer();
      Get.toNamed('/forgot-verify');
    } on TimeoutException {
      ErrorHandler.showErrorSnackBar(
          'Timeout Error', 'Request timed out after 20s.');
    } catch (e) {
      ErrorHandler.showErrorSnackBar('Error', e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> forgotPasswordVerifyOtp(String otp) async {
    isLoading.value = true;
    try {
      final token = await repository
          .forgotVerifyOtp(forgotIdentifier.value, otp)
          .timeout(const Duration(seconds: 20));
      resetToken.value = token;
      Get.toNamed('/reset-password');
    } on TimeoutException {
      ErrorHandler.showErrorSnackBar(
          'Timeout Error', 'Verification timed out after 20s.');
    } catch (e) {
      ErrorHandler.showErrorSnackBar('OTP Verification Error', e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resetPassword(String newPassword) async {
    isLoading.value = true;
    try {
      await repository
          .resetPassword(resetToken.value, newPassword)
          .timeout(const Duration(seconds: 20));
      Get.offAllNamed(Routes.login);
      ErrorHandler.showSuccessSnackBar('Success',
          'Password reset successfully. Please log in with your new password.');
    } on TimeoutException {
      ErrorHandler.showErrorSnackBar(
          'Timeout Error', 'Reset password timed out after 20s.');
    } catch (e) {
      ErrorHandler.showErrorSnackBar('Reset Error', e);
    } finally {
      isLoading.value = false;
    }
  }
}
