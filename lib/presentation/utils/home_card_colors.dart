import 'package:flutter/material.dart';

/// Background of the home cards: white on the light grey surface, a raised
/// container in dark mode.
Color homeCardColor(ColorScheme colorScheme) =>
    colorScheme.brightness == Brightness.dark
    ? colorScheme.surfaceContainerLow
    : Colors.white;

/// Accent for icons and figures drawn on a home card. The primary green is
/// too dark on the dark cards, so the lighter tertiary takes over there.
Color homeAccentColor(ColorScheme colorScheme) =>
    colorScheme.brightness == Brightness.dark
    ? colorScheme.tertiary
    : colorScheme.primary;

/// Text drawn on a light tint of [homeAccentColor] (chips, tonal buttons):
/// a shade darker in light mode, lighter in dark mode, to stay readable.
Color homeAccentInk(ColorScheme colorScheme) =>
    colorScheme.brightness == Brightness.dark
    ? Color.lerp(colorScheme.tertiary, Colors.white, 0.3)!
    : Color.lerp(colorScheme.primary, Colors.black, 0.2)!;

/// The gold of the palette, adjusted to be readable as text or icon on a
/// home card.
Color homeGoldInk(ColorScheme colorScheme) =>
    colorScheme.brightness == Brightness.dark
    ? Color.lerp(colorScheme.secondary, Colors.white, 0.35)!
    : Color.lerp(colorScheme.secondary, Colors.black, 0.35)!;
