import '../../data/models/api_response_model.dart';
import '../errors/app_exception.dart';
import '../utils/app_logger.dart';

class ApiResponseParser {
  static ApiResponseModel<T> parse<T>(
    dynamic responseData,
    T Function(dynamic json) fromJsonT,
  ) {
    if (responseData is Map<String, dynamic>) {
      final success = responseData['success'] == true;
      final message = responseData['message'] as String? ?? '';
      final dataJson = responseData['data'];
      final errorMap = responseData['error'] as Map<String, dynamic>?;

      if (!success) {
        String errMessage = message;
        String? errCode = errorMap?['code'] as String?;
        dynamic errDetails = errorMap?['details'];

        // Extract individual field validation messages if available
        if (errDetails is List && errDetails.isNotEmpty) {
          final fieldMessages = <String>[];
          for (final item in errDetails) {
            if (item is Map<String, dynamic> && item['message'] != null) {
              fieldMessages.add(item['message'].toString());
            } else if (item is String) {
              fieldMessages.add(item);
            }
          }
          if (fieldMessages.isNotEmpty) {
            errMessage = fieldMessages.join(', ');
          }
        }

        if (errMessage.isEmpty && errorMap != null) {
          errMessage = errorMap['message'] as String? ?? '';
        }

        if (errMessage.isEmpty) {
          errMessage = 'Action failed. Please try again.';
        }

        if (errCode == 'ACCOUNT_SUSPENDED') {
          throw AuthException(
            'Your account has been suspended. Please contact support.',
            code: 'ACCOUNT_SUSPENDED',
            details: errDetails,
          );
        } else if (errCode == 'UNAUTHORIZED' ||
            errCode == 'TOKEN_EXPIRED' ||
            errCode == 'INVALID_TOKEN') {
          throw AuthException(
            errMessage.isNotEmpty &&
                    errMessage != 'Action failed. Please try again.'
                ? errMessage
                : 'Session expired. Please log in again.',
            code: 'UNAUTHORIZED',
            details: errDetails,
          );
        } else if (errCode == 'FORBIDDEN' || errCode == 'FORBIDDEN_ROLE') {
          throw AuthException(
            errMessage,
            code: 'FORBIDDEN',
            details: errDetails,
          );
        } else if (errCode == 'VALIDATION_ERROR' ||
            errCode == 'DUPLICATE_ENTRY') {
          throw ValidationException(
            errMessage,
            code: errCode,
            details: errDetails,
          );
        } else if (errCode == 'INTERNAL_SERVER_ERROR' ||
            errCode == 'DATABASE_ERROR') {
          throw ServerException(
            'Internal server error. Our servers are experiencing issues. Please try again later.',
            code: 'SERVER_ERROR',
            details: errDetails,
          );
        }

        throw AppException(
          errMessage,
          code: errCode,
          details: errDetails,
        );
      }

      T? parsedData;
      if (dataJson != null) {
        try {
          parsedData = fromJsonT(dataJson);
        } catch (e, stackTrace) {
          AppLogger.error(
              'JSON Parsing Error in API Response: $e', e, stackTrace);
          throw ServerException(
            'Internal server error. Failed to process data from server.',
            code: 'PARSING_ERROR',
          );
        }
      }

      return ApiResponseModel<T>(
        success: success,
        message: message,
        data: parsedData,
        error: errorMap,
      );
    }

    if (responseData is String) {
      if (responseData.contains('500') ||
          responseData.contains('Internal Server Error') ||
          responseData.contains('Bad Gateway') ||
          responseData.contains('502') ||
          responseData.contains('503') ||
          responseData.contains('<html>')) {
        throw ServerException(
          'Internal server error. Our servers are experiencing issues. Please try again later.',
          code: 'SERVER_ERROR',
        );
      }
    }

    throw ServerException(
      'Internal server error. Invalid response received from server.',
      code: 'INVALID_RESPONSE',
    );
  }
}
