import 'package:dio/dio.dart';
import '../../utils/app_logger.dart';
import '../server_discovery_service.dart';

class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;

  RetryInterceptor({required this.dio, this.maxRetries = 2});

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    final requestOptions = err.requestOptions;

    // Check if error is due to an unreachable host (timeout or connection refused)
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.connectionError) {
      bool failoverDone = requestOptions.extra['failoverDone'] ?? false;
      if (!failoverDone) {
        requestOptions.extra['failoverDone'] = true;
        final switched =
            await ServerDiscoveryService.handleConnectionFailure(dio);
        if (switched) {
          AppLogger.info(
              '🔄 [RetryInterceptor] Retrying request with new baseUrl: ${dio.options.baseUrl}');
          requestOptions.baseUrl = dio.options.baseUrl;
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

    // Standard retry for idempotent GET requests
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

        // Backoff delay before retry
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
