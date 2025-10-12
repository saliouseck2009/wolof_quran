import 'package:flutter/material.dart';

/// Helper methods to generate gradients that stay in sync with the active
/// [ColorScheme]. This keeps decorative elements consistent between light
/// and dark themes without hard-coding palette values.
class AppGradients {
  const AppGradients._();

  static LinearGradient primary(ColorScheme colorScheme) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [colorScheme.primary, colorScheme.primaryContainer],
    );
  }

  static LinearGradient surface(ColorScheme colorScheme) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [colorScheme.surface, colorScheme.surfaceContainerHigh],
    );
  }

  static LinearGradient backdrop(ColorScheme colorScheme) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        colorScheme.surfaceContainerLowest,
        colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
      ],
    );
  }
}
