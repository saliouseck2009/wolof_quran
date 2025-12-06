import 'package:flutter/material.dart';

/// Brand color tokens used to seed the global [ColorScheme]s.
/// These values intentionally lean toward high contrast emerald and amber
/// combinations that stay legible across light and dark surfaces.
class AppColor {
  AppColor._();

  // Primary Palette (Deep Teal)
  static const Color primary = Color(0xFF006E62);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF6FF8E0); // Lighter teal for containers
  static const Color onPrimaryContainer = Color(0xFF00201B);

  // Secondary Palette (Muted Gold)
  static const Color secondary = Color(0xFFB49F56);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFFFE08F);
  static const Color onSecondaryContainer = Color(0xFF251C00);

  // Tertiary Palette (Teal 300 - Complementary)
  static const Color tertiary = Color(0xFF4DB6AC);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFB0F2E6);
  static const Color onTertiaryContainer = Color(0xFF00201E);

  // Error Palette
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF410002);

  // Neutral Palette (Light)
  static const Color surfaceLight = Color(0xFFFBFDFD);
  static const Color onSurfaceLight = Color(0xFF191C1C);
  static const Color surfaceContainerLight = Color(0xFFF0F4F3); // Slightly darker background
  static const Color outlineLight = Color(0xFF6F7977);

  // Neutral Palette (Dark)
  static const Color surfaceDark = Color(0xFF19211F); // Dark Green-Grey
  static const Color onSurfaceDark = Color(0xFFE1E3E3);
  static const Color surfaceContainerDark = Color(0xFF101413); // Darker background
  static const Color outlineDark = Color(0xFF899390);

  // Legacy/Compatibility colors (mapped to new palette where possible)
  static const Color primaryGreen = primary;
  static const Color lightGreen = primaryContainer; // Approximation
  static const Color mintGreen = tertiary;
  static const Color gold = secondary;
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color darkSurface = surfaceDark;
}
