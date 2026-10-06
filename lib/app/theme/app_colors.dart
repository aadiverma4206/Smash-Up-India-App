import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors (Vibrant Pitch Green & Sports Accents)
  static const Color primary = Color(0xFF00C853); // Vibrant Pitch Green
  static const Color primaryDark = Color(0xFF00A843); // Deep Green
  static const Color primaryLight = Color(0xFF5EFC82); // Light Green Accent
  static const Color secondary = Color(0xFFFFB300); // Gold Accent
  static const Color accent = Color(0xFF00E676); // Bright Turf Accent
  static const Color vibrantRed = Color(0xFFFF3B30); // Red Accent

  // AppBar Colors (Light Mode & Dark Mode)
  static const Color sageGreenAppBar =
      Color(0xFFA7D7B5); // Light Mode Sage Green
  static const Color darkAppBar =
      Color(0xFF130722); // Dark Mode Midnight Purple/Navy

  // Neutral Colors - Dark Mode (Rich Deep Emerald Pitch Dark)
  static const Color darkBackground =
      Color(0xFF07120E); // Deep Turf Dark Background
  static const Color darkCard = Color(0xFF0E1E19); // Rich Dark Surface Card
  static const Color darkInputBg = Color(0xFF132822); // Input Field Fill
  static const Color darkBorder = Color(0xFF1C3830); // Subtle Border Color

  // Neutral Colors - Light Mode
  static const Color lightBackground = Color(0xFFF8FAFC); // Clean Light Slate
  static const Color lightCard = Color(0xFFFFFFFF); // Pure White Surface
  static const Color lightInputBg = Color(0xFFF1F5F9); // Light Gray Input
  static const Color lightBorder = Color(0xFFE2E8F0); // Subtle Light Border

  // Text Colors - Dark Mode
  static const Color textPrimaryDark = Color(0xFFF1F8F5); // Crisp White Mint
  static const Color textSecondaryDark =
      Color(0xFF8BA69E); // Muted Secondary Mint
  static const Color textMutedDark = Color(0xFF5A786E); // Muted Dark Text

  // Text Colors - Light Mode
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textMutedLight = Color(0xFF94A3B8);

  // Status Colors
  static const Color success = Color(0xFF00C853);
  static const Color error = Color(0xFFFF3B30);
  static const Color warning = Color(0xFFFFB300);

  // Hero Image Overlay Gradient
  static const List<Color> heroGradientDark = [
    Colors.transparent,
    Color(0xCC07120E),
    Color(0xFF07120E),
  ];

  static const List<Color> heroGradientLight = [
    Colors.transparent,
    Color(0x99F8FAFC),
    Color(0xFFF8FAFC),
  ];
}

extension ThemeContextExtension on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get backgroundColor =>
      isDark ? AppColors.darkBackground : AppColors.lightBackground;
  Color get cardColor => isDark ? AppColors.darkCard : AppColors.lightCard;
  Color get inputBgColor =>
      isDark ? AppColors.darkInputBg : AppColors.lightInputBg;
  Color get borderColor =>
      isDark ? AppColors.darkBorder : AppColors.lightBorder;
  Color get textPrimary =>
      isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
  Color get textSecondary =>
      isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
  Color get textMuted =>
      isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
}
