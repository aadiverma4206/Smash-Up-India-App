import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF00C853);
  static const Color primaryDark = Color(0xFF00A843);
  static const Color primaryLight = Color(0xFF5EFC82);
  static const Color secondary = Color(0xFFFFB300);
  static const Color accent = Color(0xFF00E676);
  static const Color vibrantRed = Color(0xFFFF3B30);

  static const Color sageGreenAppBar = Color(0xFFA7D7B5);
  static const Color darkAppBar = Color(0xFF130722);

  static const Color darkBackground = Color(0xFF07120E);
  static const Color darkCard = Color(0xFF0E1E19);
  static const Color darkInputBg = Color(0xFF132822);
  static const Color darkBorder = Color(0xFF1C3830);

  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightInputBg = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);

  static const Color textPrimaryDark = Color(0xFFF1F8F5);
  static const Color textSecondaryDark = Color(0xFF8BA69E);
  static const Color textMutedDark = Color(0xFF5A786E);

  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textMutedLight = Color(0xFF94A3B8);

  static const Color success = Color(0xFF00C853);
  static const Color error = Color(0xFFFF3B30);
  static const Color warning = Color(0xFFFFB300);

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
