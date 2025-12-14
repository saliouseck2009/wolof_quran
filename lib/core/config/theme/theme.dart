import "package:flutter/material.dart";
import "package:flutter/services.dart";

import "app_color.dart";

class MaterialTheme {
  const MaterialTheme();

  static final ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColor.primary,
    onPrimary: AppColor.onPrimary,
    primaryContainer: AppColor.primaryContainer,
    onPrimaryContainer: AppColor.onPrimaryContainer,
    secondary: AppColor.secondary,
    onSecondary: AppColor.onSecondary,
    secondaryContainer: AppColor.secondaryContainer,
    onSecondaryContainer: AppColor.onSecondaryContainer,
    tertiary: AppColor.tertiary,
    onTertiary: AppColor.onTertiary,
    tertiaryContainer: AppColor.tertiaryContainer,
    onTertiaryContainer: AppColor.onTertiaryContainer,
    error: AppColor.error,
    onError: AppColor.onError,
    errorContainer: AppColor.errorContainer,
    onErrorContainer: AppColor.onErrorContainer,
    surface: AppColor.surfaceLight,
    onSurface: AppColor.onSurfaceLight,
    surfaceContainerLowest: AppColor.surfaceLight, // Base
    surfaceContainerLow: AppColor.surfaceContainerLight.withValues(alpha: 0.5),
    surfaceContainer: AppColor.surfaceContainerLight,
    surfaceContainerHigh: AppColor.surfaceContainerLight,
    surfaceContainerHighest: AppColor.surfaceContainerLight.withValues(alpha: 0.8), // Slightly distinct
    outline: AppColor.outlineLight,
  );

  static final ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColor.primary,
    onPrimary: AppColor.onPrimary,
    primaryContainer: AppColor.primaryContainer,
    onPrimaryContainer: AppColor.onPrimaryContainer,
    secondary: AppColor.secondary,
    onSecondary: AppColor.onSecondary,
    secondaryContainer: AppColor.secondaryContainer,
    onSecondaryContainer: AppColor.onSecondaryContainer,
    tertiary: AppColor.tertiary,
    onTertiary: AppColor.onTertiary,
    tertiaryContainer: AppColor.tertiaryContainer,
    onTertiaryContainer: AppColor.onTertiaryContainer,
    error: AppColor.error,
    onError: AppColor.onError,
    errorContainer: AppColor.errorContainer,
    onErrorContainer: AppColor.onErrorContainer,
    surface: AppColor.surfaceDark,
    onSurface: AppColor.onSurfaceDark,
    surfaceContainerLowest: AppColor.surfaceDark,
    surfaceContainerLow: AppColor.surfaceContainerLowDark,
    surfaceContainer: AppColor.surfaceContainerDark,
    surfaceContainerHigh: AppColor.surfaceContainerHighDark,
    surfaceContainerHighest: AppColor.surfaceContainerHighestDark,
    outline: AppColor.outlineDark,
  );

  ThemeData light() => _theme(_lightScheme);

  ThemeData dark() => _theme(_darkScheme);

  static ThemeData _theme(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    final baseTextTheme = ThemeData(
      brightness: colorScheme.brightness,
      useMaterial3: true,
    ).textTheme;

    final textTheme = baseTextTheme
        .apply(
          fontFamily: "Poppins",
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface,
        )
        .copyWith(
          displayLarge: baseTextTheme.displayLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          displayMedium: baseTextTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          displaySmall: baseTextTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          headlineLarge: baseTextTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          headlineMedium: baseTextTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          titleLarge: baseTextTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          titleMedium: baseTextTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: baseTextTheme.bodyLarge?.copyWith(height: 1.6),
          bodyMedium: baseTextTheme.bodyMedium?.copyWith(height: 1.6),
          bodySmall: baseTextTheme.bodySmall?.copyWith(height: 1.5),
        );

    final iconColor = colorScheme.onSurfaceVariant;

    return ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      fontFamily: "Poppins",
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      canvasColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerHighest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          side: BorderSide(color: colorScheme.outline, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        labelStyle: textTheme.labelLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(
          color: colorScheme.onSecondary,
        ),
        selectedColor: colorScheme.primaryContainer,
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        iconColor: iconColor,
        textColor: colorScheme.onSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tileColor: Colors.transparent,
        selectedTileColor: colorScheme.primaryContainer.withValues(alpha: 0.5),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outline.withValues(alpha: 0.2),
        thickness: 1,
        space: 32,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        modalBackgroundColor: colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        contentTextStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: iconColor,
          backgroundColor: Colors.transparent,
          highlightColor: colorScheme.primary.withValues(alpha: 0.1),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimary;
          }
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.surfaceContainerHighest;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.surfaceContainerHighest;
        }),
        checkColor: WidgetStateProperty.all(colorScheme.onPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        side: BorderSide(color: colorScheme.outline, width: 1.5),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.outline;
        }),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        circularTrackColor: colorScheme.primaryContainer,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            );
          }
          return textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colorScheme.onPrimaryContainer);
          }
          return IconThemeData(color: colorScheme.onSurfaceVariant);
        }),
      ),
    );
  }
}
