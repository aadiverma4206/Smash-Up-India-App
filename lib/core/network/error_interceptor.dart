import 'package:dio/dio.dart';
import '../errors/error_mapper.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final appException = ErrorMapper.mapDioError(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: appException,
      ),
    );
  }
}
