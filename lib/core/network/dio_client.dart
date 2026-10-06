import 'package:dio/dio.dart';
import '../config/env_config.dart';
import '../storage/secure_storage_service.dart';
import 'interceptors/token_interceptor.dart';
import 'interceptors/refresh_token_interceptor.dart';
import 'interceptors/retry_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/cache_interceptor.dart';
import 'error_interceptor.dart';

class DioClient {
  late final Dio dio;
  final SecureStorageService secureStorageService;

  DioClient({required this.secureStorageService}) {
    dio = Dio(
      BaseOptions(
        baseUrl: EnvConfig.baseUrl,
        connectTimeout: Duration(milliseconds: EnvConfig.connectTimeout),
        receiveTimeout: Duration(milliseconds: EnvConfig.receiveTimeout),
        sendTimeout: Duration(milliseconds: EnvConfig.connectTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Interceptors chain
    dio.interceptors
        .add(TokenInterceptor(secureStorageService: secureStorageService));
    dio.interceptors.add(
        RefreshTokenInterceptor(secureStorage: secureStorageService, dio: dio));
    dio.interceptors.add(RetryInterceptor(dio: dio, maxRetries: 2));
    dio.interceptors.add(CustomCacheInterceptor.interceptor);
    dio.interceptors.add(LoggingInterceptor());
    dio.interceptors.add(ErrorInterceptor());
  }
}
