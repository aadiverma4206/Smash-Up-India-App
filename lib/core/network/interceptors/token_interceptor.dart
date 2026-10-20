import 'package:dio/dio.dart';
import '../../config/env_config.dart';
import '../../storage/secure_storage_service.dart';

class TokenInterceptor extends Interceptor {
  final SecureStorageService secureStorageService;

  TokenInterceptor({required this.secureStorageService});

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    // Dynamically assign active BASE_URL from .env for every request
    final activeBaseUrl = EnvConfig.baseUrl;
    if (activeBaseUrl.isNotEmpty) {
      options.baseUrl = activeBaseUrl;
    }

    final token = await secureStorageService.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
