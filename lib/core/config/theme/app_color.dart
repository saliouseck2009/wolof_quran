import 'package:flutter/material.dart';

/// Brand color tokens used to seed the global [ColorScheme]s.
/// These values intentionally lean toward high contrast emerald and amber
/// combinations that stay legible across light and dark surfaces.
class AppColor {
  AppColor._();

  // Primary emerald palette
  static const Color primaryGreen = Color(0xFF146C43);
  static const Color lightGreen = Color(0xFF1E7D4D);
  static const Color mintGreen = Color(0xFF2FB885);
  static const Color lightMint = Color(0xFF9EE1C8);
  static const Color accentGreen = Color(0xFF2FAB75);

  // Secondary warm palette
  static const Color gold = Color(0xFFB8841D);
  static const Color lightGold = Color(0xFFF7D278);
  static const Color warmBrown = Color(0xFF6D4D25);
  static const Color lightBrown = Color(0xFFE6C89F);

  // Neutral palette
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF7F9F4);
  static const Color lightGray = Color(0xFFE1E5DF);
  static const Color mediumGray = Color(0xFF64726A);
  static const Color darkGray = Color(0xFF2F3D36);
  static const Color charcoal = Color(0xFF16211B);

  // Text-specific accents
  static const Color arabicTextDark = Color(0xFF102118);
  static const Color arabicTextLight = Color(0xFFF5FBF8);
  static const Color translationText = Color(0xFF3E4742);

  // Functional states
  static const Color accent = Color(0xFF2FB885);
  static const Color accentLight = Color(0xFF9EE1C8);
  static const Color error = Color(0xFFBA1A1A);
  static const Color success = Color(0xFF1E7D4D);
  static const Color warning = Color(0xFFE86F08);

  // Dark surfaces for elevated layers
  static const Color darkSurface = Color(0xFF101714);
  static const Color darkSurfaceHigh = Color(0xFF1A241F);
  static const Color darkBackdropTop = Color(0xFF0B110E);
  static const Color darkBackdropBottom = Color(0xFF141E19);
  static const Color darkDivider = Color(0xFF24332B);
  static const Color darkSubtle = Color(0xFF1C2B23);
}
