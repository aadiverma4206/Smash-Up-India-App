import 'package:flutter/material.dart';

class ResponsiveTypography {
  static TextScaler getClampedTextScaler(
    BuildContext context, {
    double minScale = 0.85,
    double maxScale = 2.2,
  }) {
    final mediaQuery = MediaQuery.of(context);
    final currentScale = mediaQuery.textScaler.scale(10) / 10;
    final clampedScale = currentScale.clamp(minScale, maxScale);
    return TextScaler.linear(clampedScale);
  }

  static double responsiveFontSize(
    BuildContext context, {
    required double baseSize,
    double minSize = 10.0,
    double maxSize = 36.0,
  }) {
    final width = MediaQuery.of(context).size.width;
    double widthFactor = 1.0;

    if (width < 360) {
      widthFactor = 0.90;
    } else if (width > 600) {
      widthFactor = 1.15;
    }

    final calculated = baseSize * widthFactor;
    return calculated.clamp(minSize, maxSize);
  }
}
