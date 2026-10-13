extension StringImageUtils on String? {
  bool get isValidNetworkUrl {
    if (this == null) return false;
    final trimmed = this!.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed.startsWith('/assets/') || trimmed.startsWith('assets/')) {
      return false;
    }
    return trimmed.startsWith('http://') || trimmed.startsWith('https://');
  }

  String? get sanitizedNetworkUrl {
    return isValidNetworkUrl ? this!.trim() : null;
  }
}
