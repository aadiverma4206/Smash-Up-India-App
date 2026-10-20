class ImageUtils {
  ImageUtils._();

  static bool isValidNetworkUrl(dynamic input) {
    if (input == null) return false;
    final str = input.toString().trim();
    if (str.isEmpty) return false;
    if (str.startsWith('/assets/') || str.startsWith('assets/')) {
      return false;
    }
    return str.startsWith('http://') || str.startsWith('https://');
  }
}

extension StringImageUtils on String? {
  bool get isValidNetworkUrl {
    return ImageUtils.isValidNetworkUrl(this);
  }

  String? get sanitizedNetworkUrl {
    return isValidNetworkUrl ? this!.trim() : null;
  }
}
