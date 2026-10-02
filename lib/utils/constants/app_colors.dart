import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Colors
  static const Color primary = Color(0xFF103166);
  static const Color primaryDark = Color(0xFF08244D);
  static const Color primaryLight = Color(0xFF315B91);

  // Secondary Colors
  static const Color secondary = Color(0xFFFF6B2D);
  static const Color secondaryDark = Color(0xFFD94F16);
  static const Color secondaryLight = Color(0xFFFF9566);

  // Neutral Colors
  static const Color background = Color(0xFFF8F9FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFF0F3F8);

  // Neutral Colors - Light Mode
  static const Color backgroundLight = Color(0xFFF8F9FC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFF3F6FA);
  static const Color dividerLight = Color(0xFFDDE2E9);

  // Neutral Colors - Dark Mode
  static const Color backgroundDark = Color(0xFF0D1117);
  static const Color surfaceDark = Color(0xFF151B23);
  static const Color cardDark = Color(0xFF202833);
  static const Color dividerDark = Color(0xFF343D49);

  // Text Colors - Light Mode
  static const Color textPrimaryLight = Color(0xFF171A1F);
  static const Color textSecondaryLight = Color(0xFF5F6875);
  static const Color textHintLight = Color(0xFF9299A5);

  // Text Colors - Dark Mode
  static const Color textPrimaryDark = Color(0xFFF2F4F7);
  static const Color textSecondaryDark = Color(0xFFB5BDC8);
  static const Color textHintDark = Color(0xFF7F8996);

  // Status Colors - Light Mode
  static const Color success = Color(0xFF16834A);
  static const Color successLight = Color(0xFFE1F4E9);

  static const Color warning = Color(0xFFB96800);
  static const Color warningLight = Color(0xFFFFEFD9);

  static const Color error = Color(0xFFC62828);
  static const Color errorLight = Color(0xFFFFE4E4);

  static const Color info = Color(0xFF1769AA);
  static const Color infoLight = Color(0xFFE2F0FC);

  // Status Colors - Dark Mode
  static const Color successDark = Color(0xFF63D39A);
  static const Color successDarkBackground = Color(0xFF123A29);

  static const Color warningDark = Color(0xFFFFB95C);
  static const Color warningDarkBackground = Color(0xFF3D2B12);

  static const Color errorDark = Color(0xFFFF8A80);
  static const Color errorDarkBackground = Color(0xFF40191A);

  static const Color infoDark = Color(0xFF64B5F6);
  static const Color infoDarkBackground = Color(0xFF132E45);

  // Shadow Colors
  static Color shadowLight = Colors.black.withValues(alpha: 0.08);
  static Color shadowDark = Colors.black.withValues(alpha: 0.40);
}
