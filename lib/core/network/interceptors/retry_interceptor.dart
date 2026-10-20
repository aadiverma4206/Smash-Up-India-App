import 'package:dio/dio.dart';
import '../../config/env_config.dart';
import '../../utils/app_logger.dart';

class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;

  RetryInterceptor({required this.dio, this.maxRetries = 2});

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    final requestOptions = err.requestOptions;

    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.connectionError) {
      bool failoverDone = requestOptions.extra['failoverDone'] ?? false;
      if (!failoverDone) {
        requestOptions.extra['failoverDone'] = true;
        final currentBase = EnvConfig.baseUrl;
        if (currentBase.isNotEmpty) {
          requestOptions.baseUrl = currentBase;
          AppLogger.info(
              '🔄 [RetryInterceptor] Retrying request with .env baseUrl: ${requestOptions.baseUrl}');
          try {
            final response = await dio.fetch(requestOptions);
            return handler.resolve(response);
          } catch (retryErr) {
            if (retryErr is DioException) {
              return handler.next(retryErr);
            }
          }
        }
      }
    }

    if (requestOptions.method.toUpperCase() == 'GET' &&
        (err.type == DioExceptionType.connectionTimeout ||
            err.type == DioExceptionType.receiveTimeout ||
            err.type == DioExceptionType.connectionError)) {
      int retryCount = requestOptions.extra['retryCount'] ?? 0;

      if (retryCount < maxRetries) {
        retryCount++;
        requestOptions.extra['retryCount'] = retryCount;

        AppLogger.info(
            '🔄 [Retry Attempt $retryCount/$maxRetries] for ${requestOptions.path}');

        await Future.delayed(Duration(milliseconds: 1000 * retryCount));

        try {
          final response = await dio.fetch(requestOptions);
          return handler.resolve(response);
        } catch (retryErr) {
          if (retryErr is DioException) {
            return handler.next(retryErr);
          }
        }
      }
    }

    handler.next(err);
  }
}
