import "package:flutter/material.dart";
import "app_color.dart";

class MaterialTheme {
  const MaterialTheme();

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: AppColor.primaryGreen,
      surfaceTint: AppColor.primaryGreen,
      onPrimary: AppColor.pureWhite,
      primaryContainer: AppColor.lightMint,
      onPrimaryContainer: AppColor.primaryGreen,
      secondary: AppColor.gold,
      onSecondary: AppColor.pureWhite,
      secondaryContainer: AppColor.lightGold,
      onSecondaryContainer: AppColor.warmBrown,
      tertiary: AppColor.mintGreen,
      onTertiary: AppColor.pureWhite,
      tertiaryContainer: AppColor.accentLight,
      onTertiaryContainer: AppColor.primaryGreen,
      error: AppColor.error,
      onError: AppColor.pureWhite,
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF93000A),
      surface: AppColor.offWhite,
      onSurface: AppColor.arabicTextDark,
      onSurfaceVariant: AppColor.translationText,
      outline: AppColor.mediumGray,
      outlineVariant: AppColor.lightGray,
      shadow: AppColor.charcoal,
      scrim: AppColor.charcoal,
      inverseSurface: AppColor.charcoal,
      inversePrimary: AppColor.lightMint,
      primaryFixed: AppColor.lightMint,
      onPrimaryFixed: AppColor.primaryGreen,
      primaryFixedDim: AppColor.mintGreen,
      onPrimaryFixedVariant: AppColor.primaryGreen,
      secondaryFixed: AppColor.lightGold,
      onSecondaryFixed: AppColor.warmBrown,
      secondaryFixedDim: AppColor.lightBrown,
      onSecondaryFixedVariant: AppColor.warmBrown,
      tertiaryFixed: AppColor.accentLight,
      onTertiaryFixed: AppColor.primaryGreen,
      tertiaryFixedDim: AppColor.accent,
      onTertiaryFixedVariant: AppColor.primaryGreen,
      surfaceDim: AppColor.lightGray,
      surfaceBright: AppColor.pureWhite,
      surfaceContainerLowest: AppColor.pureWhite,
      surfaceContainerLow: AppColor.offWhite,
      surfaceContainer: AppColor.lightGray,
      surfaceContainerHigh: AppColor.mediumGray,
      surfaceContainerHighest: AppColor.darkGray,
    );
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: AppColor.lightMint,
      surfaceTint: AppColor.lightMint,
      onPrimary: AppColor.primaryGreen,
      primaryContainer: AppColor.lightGreen,
      onPrimaryContainer: AppColor.pureWhite,
      secondary: AppColor.lightGold,
      onSecondary: AppColor.warmBrown,
      secondaryContainer: AppColor.warmBrown,
      onSecondaryContainer: AppColor.lightGold,
      tertiary: AppColor.accentLight,
      onTertiary: AppColor.primaryGreen,
      tertiaryContainer: AppColor.accent,
      onTertiaryContainer: AppColor.pureWhite,
      error: AppColor.error,
      onError: AppColor.pureWhite,
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: AppColor.charcoal,
      onSurface: AppColor.arabicTextLight,
      onSurfaceVariant: AppColor.lightGray,
      outline: AppColor.darkGray,
      outlineVariant: AppColor.charcoal,
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: AppColor.offWhite,
      inversePrimary: AppColor.primaryGreen,
      primaryFixed: AppColor.lightMint,
      onPrimaryFixed: AppColor.primaryGreen,
      primaryFixedDim: AppColor.mintGreen,
      onPrimaryFixedVariant: AppColor.lightGreen,
      secondaryFixed: AppColor.lightGold,
      onSecondaryFixed: AppColor.warmBrown,
      secondaryFixedDim: AppColor.lightBrown,
      onSecondaryFixedVariant: AppColor.warmBrown,
      tertiaryFixed: AppColor.accentLight,
      onTertiaryFixed: AppColor.primaryGreen,
      tertiaryFixedDim: AppColor.accent,
      onTertiaryFixedVariant: AppColor.lightGreen,
      surfaceDim: Color(0xFF1A1A1A),
      surfaceBright: AppColor.darkGray,
      surfaceContainerLowest: Color(0xFF0F0F0F),
      surfaceContainerLow: AppColor.charcoal,
      surfaceContainer: Color(0xFF383838),
      surfaceContainerHigh: AppColor.darkGray,
      surfaceContainerHighest: Color(0xFF4F4F4F),
    );
  }

  ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: lightScheme(),
      fontFamily: 'Poppins',
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColor.primaryGreen,
        foregroundColor: AppColor.pureWhite,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.primaryGreen,
          foregroundColor: AppColor.pureWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: darkScheme(),
      fontFamily: 'Poppins',
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColor.charcoal,
        foregroundColor: AppColor.arabicTextLight,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.lightMint,
          foregroundColor: AppColor.primaryGreen,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
