import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import '../../data/models/user_model.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveTokens(
      {required String accessToken, required String refreshToken}) async {
    await _storage.write(key: AppConstants.accessTokenKey, value: accessToken);
    await _storage.write(
        key: AppConstants.refreshTokenKey, value: refreshToken);
  }

  Future<void> saveUser(UserModel user) async {
    final userJsonStr = jsonEncode(user.toJson());
    await _storage.write(key: AppConstants.userKey, value: userJsonStr);
  }

  Future<UserModel?> getUser() async {
    final userJsonStr = await _storage.read(key: AppConstants.userKey);
    if (userJsonStr != null && userJsonStr.trim().isNotEmpty) {
      try {
        final Map<String, dynamic> decoded =
            jsonDecode(userJsonStr) as Map<String, dynamic>;
        return UserModel.fromJson(decoded);
      } catch (_) {}
    }
    return null;
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: AppConstants.accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: AppConstants.refreshTokenKey);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: AppConstants.accessTokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
    await _storage.delete(key: AppConstants.userKey);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
