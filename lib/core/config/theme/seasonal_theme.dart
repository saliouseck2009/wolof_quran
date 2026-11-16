import 'package:flutter/material.dart';

/// Temporary looks the app wears for a religious season, on top of the
/// user's light or dark choice. They ship with the app: the remote config
/// only says which one is on (see `SeasonalThemeConfig`).
enum SeasonalTheme {
  none('none'),
  ramadan('ramadan');

  const SeasonalTheme(this.id);

  /// Identifier used in the remote config and in the saved preferences.
  final String id;

  /// An unknown id, e.g. a season added by a later version of the app,
  /// falls back to [none].
  static SeasonalTheme fromId(Object? id) {
    for (final theme in values) {
      if (theme.id == id) {
        return theme;
      }
    }
    return none;
  }

  /// Season of the theme around [context], [none] out of season.
  static SeasonalTheme of(BuildContext context) =>
      Theme.of(context).extension<SeasonalDecor>()?.season ?? none;
}

/// Colors of the seasonal ornaments, carried by the theme so that widgets
/// read them like any other theme value and do not need to know where the
/// season comes from. Absent from the theme out of season.
@immutable
class SeasonalDecor extends ThemeExtension<SeasonalDecor> {
  final SeasonalTheme season;

  /// Gradient of the decorated surfaces (the home banner).
  final Color skyStart;
  final Color skyEnd;

  /// Drawn ornaments: crescent, stars, lantern frames.
  final Color ornament;

  /// Light halo around the ornaments.
  final Color glow;

  /// Text on the decorated surfaces.
  final Color onSky;

  const SeasonalDecor({
    required this.season,
    required this.skyStart,
    required this.skyEnd,
    required this.ornament,
    required this.glow,
    required this.onSky,
  });

  @override
  SeasonalDecor copyWith({
    SeasonalTheme? season,
    Color? skyStart,
    Color? skyEnd,
    Color? ornament,
    Color? glow,
    Color? onSky,
  }) {
    return SeasonalDecor(
      season: season ?? this.season,
      skyStart: skyStart ?? this.skyStart,
      skyEnd: skyEnd ?? this.skyEnd,
      ornament: ornament ?? this.ornament,
      glow: glow ?? this.glow,
      onSky: onSky ?? this.onSky,
    );
  }

  @override
  SeasonalDecor lerp(SeasonalDecor? other, double t) {
    if (other == null) {
      return this;
    }
    return SeasonalDecor(
      season: t < 0.5 ? season : other.season,
      skyStart: Color.lerp(skyStart, other.skyStart, t)!,
      skyEnd: Color.lerp(skyEnd, other.skyEnd, t)!,
      ornament: Color.lerp(ornament, other.ornament, t)!,
      glow: Color.lerp(glow, other.glow, t)!,
      onSky: Color.lerp(onSky, other.onSky, t)!,
    );
  }
}
