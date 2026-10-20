import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

class DeviceDetector {
  static bool? _isPhysicalDeviceCached;

  static Future<bool> isPhysicalDevice() async {
    if (_isPhysicalDeviceCached != null) return _isPhysicalDeviceCached!;

    if (kIsWeb) {
      _isPhysicalDeviceCached = true;
      return true;
    }

    if (!Platform.isAndroid && !Platform.isIOS) {
      _isPhysicalDeviceCached = true;
      return true;
    }

    try {
      final socket = await Socket.connect(
        '10.0.2.2',
        5000,
        timeout: const Duration(milliseconds: 300),
      );
      socket.destroy();
      _isPhysicalDeviceCached = false;
      return false;
    } catch (_) {
      _isPhysicalDeviceCached = true;
      return true;
    }
  }
}
