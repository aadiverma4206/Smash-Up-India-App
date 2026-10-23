import '../config/env_config.dart';

class ImageUtils {
  ImageUtils._();

  static String? resolveImageUrl(dynamic input) {
    if (input == null) return null;
    final str = input.toString().trim();
    if (str.isEmpty || str == 'null' || str == 'undefined') return null;

    if (str.startsWith('/assets/') || str.startsWith('assets/')) {
      return null;
    }

    if (str.startsWith('http://') ||
        str.startsWith('https://') ||
        str.startsWith('data:image/')) {
      return str;
    }

    // Handle relative paths by prepending backend server origin
    final cleanBase = EnvConfig.baseUrl
        .replaceAll(RegExp(r'/api/v1/?$'), '')
        .replaceAll(RegExp(r'/$'), '');

    if (cleanBase.isNotEmpty) {
      final path = str.startsWith('/') ? str : '/$str';
      return '$cleanBase$path';
    }

    return str;
  }

  static bool isValidNetworkUrl(dynamic input) {
    final resolved = resolveImageUrl(input);
    if (resolved == null) return false;
    return resolved.startsWith('http://') ||
        resolved.startsWith('https://') ||
        resolved.startsWith('data:image/');
  }
}

extension StringImageUtils on String? {
  bool get isValidNetworkUrl {
    return ImageUtils.isValidNetworkUrl(this);
  }

  String? get resolvedImageUrl {
    return ImageUtils.resolveImageUrl(this);
  }

  String? get sanitizedNetworkUrl {
    return isValidNetworkUrl ? resolvedImageUrl : null;
  }
}
