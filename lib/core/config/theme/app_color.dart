import 'package:flutter/material.dart';

class AppColor {
  // Islamic-inspired color palette
  // Primary colors - Deep Islamic Green
  static const Color primaryGreen = Color(0xFF1B4332);
  static const Color lightGreen = Color(0xFF2D5A41);
  static const Color mintGreen = Color(0xFF52B788);
  static const Color lightMint = Color(0xFF95D5B2);
  static const Color accentGreen = Color(0xFF4CAF50);

  // Secondary colors - Golden/Warm tones
  static const Color gold = Color(0xFFDAA520);
  static const Color lightGold = Color(0xFFF4E4A6);
  static const Color warmBrown = Color(0xFF8B4513);
  static const Color lightBrown = Color(0xFFD2B48C);

  // Neutral colors
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF8F8F8);
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color mediumGray = Color(0xFF757575);
  static const Color darkGray = Color(0xFF424242);
  static const Color charcoal = Color(0xFF1F252B);
  // static const Color charcoal = Color(0xFF2E2E2E);

  // Arabic/Quran text colors
  static const Color arabicTextDark = Color(0xFF1A1A1A);
  static const Color arabicTextLight = Color(0xFFFFFFFF);
  static const Color translationText = Color(0xFF4A4A4A);

  // Accent colors for special elements
  static const Color accent = Color(0xFF52B788);
  static const Color accentLight = Color(0xFF95D5B2);
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFF57C00);

  // Dark theme surface colors for improved contrast
  static const Color darkSurface = Color(0xFF1F252B); // elevated card base
  static const Color darkSurfaceHigh = Color(0xFF263038); // higher elevation
  static const Color darkBackdropTop = Color(0xFF101418); // gradient top
  static const Color darkBackdropBottom = Color(0xFF182027); // gradient bottom
  static const Color darkDivider = Color(0xFF364148);
  static const Color darkSubtle = Color(0xFF2A3238);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryGreen, lightGreen],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gold, lightGold],
  );

  static const LinearGradient lightGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [pureWhite, lightGray],
  );
}
