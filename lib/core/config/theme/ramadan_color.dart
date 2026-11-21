import 'package:flutter/material.dart';

/// Color tokens of the Ramadan look: the indigo of the night sky, the gold
/// of the lanterns and paper white surfaces. They mirror the roles of
/// [AppColor] one for one, so the whole app follows through the
/// [ColorScheme].
class RamadanColor {
  RamadanColor._();

  // Primary (night indigo). White text stays readable on both; the dark
  // variant is lifted so filled buttons stand out on the night surfaces.
  static const Color primary = Color(0xFF2A2F7A);
  static const Color primaryDark = Color(0xFF5A60CC);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFC7CCFF);
  static const Color onPrimaryContainer = Color(0xFF0D1045);

  // Secondary (lantern gold)
  static const Color secondary = Color(0xFFC9A24B);
  static const Color secondaryDark = Color(0xFFD4AE5C);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFFFE4A8);
  static const Color onSecondaryContainer = Color(0xFF2A1F00);

  // Tertiary (lighter indigo). As in the standard palette it is the accent
  // that stays readable on the dark cards.
  static const Color tertiary = Color(0xFF6C78E0);
  static const Color tertiaryDark = Color(0xFFA3ADFF);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryDark = Color(0xFF0D1045);
  static const Color tertiaryContainer = Color(0xFFDDE0FF);
  static const Color onTertiaryContainer = Color(0xFF0D1045);

  // Neutrals (light): a paper white, barely warm so that the indigo tints
  // laid over it stay clean
  static const Color surfaceLight = Color(0xFFF7F5F1);
  static const Color onSurfaceLight = Color(0xFF1B1B2F);
  static const Color surfaceContainerLight = Color(0xFFEEEBE5);
  static const Color outlineLight = Color(0xFF77746D);

  // Neutrals (dark): night sky
  static const Color surfaceDark = Color(0xFF0C1027);
  static const Color onSurfaceDark = Color(0xFFE9E9F5);
  static const Color surfaceContainerDark = Color(0xFF121735);
  static const Color surfaceContainerLowDark = Color(0xFF171D40);
  static const Color surfaceContainerHighDark = Color(0xFF1F264E);
  static const Color surfaceContainerHighestDark = Color(0xFF28305C);
  static const Color outlineDark = Color(0xFF3C4573);

  // Ornaments of the decorated surfaces (same night sky in light and dark)
  static const Color skyStart = Color(0xFF1A1E5A);
  static const Color skyEnd = Color(0xFF3A2E86);
  static const Color ornament = Color(0xFFE9C46A);
  static const Color glow = Color(0xFFFFC766);
  static const Color onSky = Color(0xFFFFFFFF);

  // Skies of the home banner through the day (the night is skyStart and
  // skyEnd). Each stays dark enough for the white and gold text.
  static const Color preDawnStart = Color(0xFF0E1638);
  static const Color preDawnEnd = Color(0xFF34457E);
  static const Color dayStart = Color(0xFF1F3A80);
  static const Color dayEnd = Color(0xFF3A58A8);
  static const Color sunsetStart = Color(0xFF2E2766);
  static const Color sunsetEnd = Color(0xFF94443A);

  // Korité: a festive green under the same gold
  static const Color eidStart = Color(0xFF0B3D30);
  static const Color eidEnd = Color(0xFF1B6650);
}
