import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Dependency-free utility to detect whether the app is running on a real physical mobile device or an emulator.
class DeviceDetector {
  static bool? _isPhysicalDeviceCached;

  /// Returns true if running on a real physical mobile device, false if running on an emulator/simulator.
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
      // Fast socket probe to 10.0.2.2:5000 (Android Emulator Host Loopback)
      // On real physical phones, connecting to 10.0.2.2 fails/times out immediately.
      // On Android Emulators, 10.0.2.2 routes directly to host localhost.
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
