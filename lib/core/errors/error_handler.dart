import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import 'app_exception.dart';
import 'error_mapper.dart';

class ErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error == null) return 'An unexpected error occurred.';

    String message;

    if (error is AppException) {
      message = error.message;
    } else if (error is DioException) {
      if (error.error is AppException) {
        message = (error.error as AppException).message;
      } else {
        message = ErrorMapper.mapDioError(error).message;
      }
    } else if (error is SocketException ||
        error.toString().contains('SocketException')) {
      message = 'No internet connection';
    } else if (error is TimeoutException) {
      message = 'No internet connection';
    } else if (error is FormatException || error is TypeError) {
      message = 'Something went wrong';
    } else {
      final String raw = error.toString().trim();
      if (raw.startsWith('Exception: ')) {
        message = raw.substring(11).trim();
      } else {
        message = raw
            .replaceAll(
                RegExp(
                    r'^(?:DioException\s*\[.*?\]:?\s*null\s*Error:\s*AppException:\s*|AppException:\s*|DioException\s*\[.*?\]:\s*)'),
                '')
            .trim();
      }
    }

    if (message.isEmpty) {
      return 'An unexpected error occurred.';
    }

    // Sanitize technical error strings, internal IP addresses, URLs, or network timeout logs
    final lower = message.toLowerCase();
    if (lower.contains('http://') ||
        lower.contains('https://') ||
        lower.contains('connection timed out') ||
        lower.contains('connection refused') ||
        lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('dioexception') ||
        lower.contains('check server connectivity') ||
        lower.contains('server took too long') ||
        lower.contains('timed out after') ||
        lower.contains('no_internet')) {
      return 'No internet connection';
    }

    return message;
  }

  /// Immediately cancels any active or queued snackbars,
  /// and displays an ultra-compact single-line Navi UPI style pill toast.
  static void showErrorSnackBar(String title, dynamic error,
      {Duration? duration}) {
    final message = getErrorMessage(error);
    final isNetwork = message.contains('No internet') ||
        message.contains('Unable to connect');

    _showCompactPillToast(
      message: message,
      icon: isNetwork ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
      backgroundColor: const Color(0xFFDC2626),
      duration: duration,
    );
  }

  static void showSuccessSnackBar(String title, String message,
      {Duration? duration}) {
    _showCompactPillToast(
      message: message,
      icon: Icons.check_circle_outline_rounded,
      backgroundColor: AppColors.primary,
      duration: duration,
    );
  }

  static void showWarningSnackBar(String title, String message,
      {Duration? duration}) {
    _showCompactPillToast(
      message: message,
      icon: Icons.warning_amber_rounded,
      backgroundColor: const Color(0xFFD97706),
      duration: duration,
    );
  }

  static void _showCompactPillToast({
    required String message,
    required IconData icon,
    required Color backgroundColor,
    Duration? duration,
  }) {
    try {
      // Immediately cancel and close any active or queued snackbar
      Get.closeAllSnackbars();
    } catch (_) {}

    Get.rawSnackbar(
      messageText: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      borderRadius: 25,
      duration: duration ?? const Duration(seconds: 2),
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
