import 'package:dio/dio.dart';
import '../../storage/secure_storage_service.dart';

class TokenInterceptor extends Interceptor {
  final SecureStorageService secureStorageService;

  TokenInterceptor({required this.secureStorageService});

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await secureStorageService.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
