import 'package:dio/dio.dart';
import '../../utils/app_logger.dart';

class LoggingInterceptor extends Interceptor {
  static const List<String> sensitiveKeys = [
    'password',
    'oldPassword',
    'newPassword',
    'otp',
    'emailOtp',
    'walletPin',
    'pin',
    'accessToken',
    'refreshToken',
    'razorpaySignature',
    'rtspUrl',
    'secret',
  ];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final sanitizedData = _sanitizeMap(options.data);
    AppLogger.info(
        '🌐 [REQUEST] ${options.method} ${options.path} Data: $sanitizedData');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    AppLogger.info(
        '✅ [RESPONSE] ${response.statusCode} ${response.requestOptions.path}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLogger.error(
        '❌ [ERROR] ${err.response?.statusCode} ${err.requestOptions.path}: ${err.message}');
    handler.next(err);
  }

  dynamic _sanitizeMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      final Map<String, dynamic> sanitized = {};
      data.forEach((key, value) {
        if (sensitiveKeys.contains(key)) {
          sanitized[key] = '***REDACTED***';
        } else {
          sanitized[key] = _sanitizeMap(value);
        }
      });
      return sanitized;
    }
    return data;
  }
}
