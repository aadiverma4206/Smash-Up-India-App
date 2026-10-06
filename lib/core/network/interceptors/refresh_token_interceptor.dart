import 'package:dio/dio.dart';
import '../../config/env_config.dart';
import '../../constants/api_constants.dart';
import '../../storage/secure_storage_service.dart';
import '../../services/auth_service.dart';
import '../../utils/app_logger.dart';

class RefreshTokenInterceptor extends Interceptor {
  final SecureStorageService secureStorage;
  final Dio dio;

  bool _isRefreshing = false;
  final List<_PendingRequest> _pendingRequests = [];

  RefreshTokenInterceptor({required this.secureStorage, required this.dio});

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;
    String? errCode;
    if (err.response?.data is Map<String, dynamic>) {
      final map = err.response!.data as Map<String, dynamic>;
      if (map['error'] is Map) {
        errCode = map['error']['code']?.toString();
      } else if (map['code'] != null) {
        errCode = map['code']?.toString();
      }
    }

    final isUnauthorized = (statusCode == 401 ||
            errCode == 'TOKEN_EXPIRED' ||
            errCode == 'UNAUTHORIZED') &&
        !err.requestOptions.path.contains(ApiConstants.refresh);

    if (isUnauthorized) {
      final requestOptions = err.requestOptions;

      // Check if this request was already retried once
      if (requestOptions.extra['isRetry'] == true) {
        return handler.next(err);
      }

      if (_isRefreshing) {
        // Queue pending requests while refresh is in progress
        _pendingRequests.add(_PendingRequest(requestOptions, handler));
        return;
      }

      _isRefreshing = true;
      requestOptions.extra['isRetry'] = true;

      try {
        final refreshToken = await secureStorage.getRefreshToken();
        if (refreshToken == null || refreshToken.isEmpty) {
          throw Exception('No refresh token available');
        }

        // Dedicated un-intercepted Dio instance for refresh call
        final refreshDio = Dio(
          BaseOptions(
            baseUrl: EnvConfig.baseUrl,
            connectTimeout: Duration(milliseconds: EnvConfig.connectTimeout),
            receiveTimeout: Duration(milliseconds: EnvConfig.receiveTimeout),
          ),
        );

        final response = await refreshDio.post(
          ApiConstants.refresh,
          data: {'refreshToken': refreshToken},
        );

        Map<String, dynamic>? dataMap;
        if (response.data is Map<String, dynamic>) {
          if (response.data['data'] is Map<String, dynamic>) {
            dataMap = response.data['data'] as Map<String, dynamic>;
          } else if (response.data['accessToken'] != null) {
            dataMap = response.data as Map<String, dynamic>;
          }
        }

        if (response.statusCode == 200 &&
            dataMap != null &&
            dataMap['accessToken'] != null) {
          final newAccessToken = dataMap['accessToken'] as String;
          final newRefreshToken =
              (dataMap['refreshToken'] ?? refreshToken) as String;

          await secureStorage.saveTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
          );

          AppLogger.info(
              '🔑 Tokens rotated successfully via RefreshTokenInterceptor');

          // Retry the original request
          requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
          final retriedResponse = await dio.fetch(requestOptions);
          handler.resolve(retriedResponse);

          // Resolve all queued pending requests
          for (final pending in _pendingRequests) {
            pending.options.headers['Authorization'] = 'Bearer $newAccessToken';
            pending.options.extra['isRetry'] = true;
            try {
              final res = await dio.fetch(pending.options);
              pending.handler.resolve(res);
            } catch (retryErr) {
              if (retryErr is DioException) {
                pending.handler.next(retryErr);
              }
            }
          }
          _pendingRequests.clear();
          return;
        } else {
          throw Exception('Refresh token endpoint returned non-200');
        }
      } catch (refreshErr) {
        AppLogger.warning(
            '🚨 Refresh token failed or revoked. Logging out user.');
        _pendingRequests.clear();
        await AuthService.to.logout();
        return handler.next(err);
      } finally {
        _isRefreshing = false;
      }
    }

    handler.next(err);
  }
}

class _PendingRequest {
  final RequestOptions options;
  final ErrorInterceptorHandler handler;

  _PendingRequest(this.options, this.handler);
}
