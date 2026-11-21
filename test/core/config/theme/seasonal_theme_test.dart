import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wolof_quran/core/config/theme/app_color.dart';
import 'package:wolof_quran/core/config/theme/seasonal_theme.dart';
import 'package:wolof_quran/core/config/theme/theme.dart';
import 'package:wolof_quran/core/seasonal/ramadan_calendar.dart';
import 'package:wolof_quran/presentation/widgets/seasonal/ramadan_banner.dart';

/// WCAG contrast ratio between two opaque colors.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (hi, lo) = la > lb ? (la, lb) : (lb, la);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  test('out of season the theme is the standard one', () {
    final light = const MaterialTheme().light();
    final dark = const MaterialTheme().dark();

    expect(light.colorScheme.primary, AppColor.primary);
    expect(dark.colorScheme.surface, AppColor.surfaceDark);
    expect(light.extension<SeasonalDecor>(), isNull);
    expect(dark.extension<SeasonalDecor>(), isNull);
  });

  test('unknown seasons fall back to none', () {
    expect(SeasonalTheme.fromId('ramadan'), SeasonalTheme.ramadan);
    expect(SeasonalTheme.fromId('eid'), SeasonalTheme.none);
    expect(SeasonalTheme.fromId(null), SeasonalTheme.none);
    expect(SeasonalTheme.fromId(3), SeasonalTheme.none);
  });

  group('Ramadan theme', () {
    const theme = MaterialTheme(season: SeasonalTheme.ramadan);

    test('swaps the palette and carries its ornaments', () {
      for (final data in [theme.light(), theme.dark()]) {
        expect(data.colorScheme.primary, isNot(AppColor.primary));
        expect(
          data.extension<SeasonalDecor>()?.season,
          SeasonalTheme.ramadan,
          reason: '${data.brightness}',
        );
      }
      expect(theme.light().brightness, Brightness.light);
      expect(theme.dark().brightness, Brightness.dark);
    });

    test('text stays readable on its surfaces', () {
      for (final data in [theme.light(), theme.dark()]) {
        final scheme = data.colorScheme;
        final reason = '${data.brightness}';
        // Body text, and titles on the filled app bars and buttons.
        expect(
          _contrast(scheme.onSurface, scheme.surface),
          greaterThan(7),
          reason: reason,
        );
        expect(
          _contrast(scheme.onPrimary, scheme.primary),
          greaterThan(4.5),
          reason: reason,
        );
        expect(
          _contrast(scheme.onPrimaryContainer, scheme.primaryContainer),
          greaterThan(7),
          reason: reason,
        );
        expect(
          _contrast(scheme.onTertiary, scheme.tertiary),
          greaterThan(3),
          reason: reason,
        );
      }
    });

    test('the dark accent reads on the night cards', () {
      final scheme = theme.dark().colorScheme;

      for (final card in [
        scheme.surface,
        scheme.surfaceContainerLow,
        scheme.surfaceContainerHighest,
      ]) {
        expect(_contrast(scheme.tertiary, card), greaterThan(4.5));
      }
    });

    test('the banner text reads on the whole night sky', () {
      final decor = theme.light().extension<SeasonalDecor>()!;
      final tagline = Color.lerp(decor.ornament, decor.onSky, 0.35)!;

      for (final sky in [decor.skyStart, decor.skyEnd]) {
        expect(_contrast(decor.onSky, sky), greaterThan(7));
        expect(_contrast(tagline, sky), greaterThan(4.5));
      }
    });
  });

  test('the banner text reads on every sky of the day and on the Korité', () {
    final decor = const MaterialTheme(
      season: SeasonalTheme.ramadan,
    ).light().extension<SeasonalDecor>()!;
    final status = RamadanBanner.statusColor(decor);
    // The tagline is white at 85 %: check its blend on each color.
    Color tagline(Color sky) =>
        Color.alphaBlend(decor.onSky.withValues(alpha: 0.85), sky);

    for (final moment in [
      for (final sky in RamadanSky.values)
        RamadanMoment(period: RamadanPeriod.ramadan, sky: sky, moonPhase: 0),
      const RamadanMoment(
        period: RamadanPeriod.eid,
        sky: RamadanSky.day,
        moonPhase: 0,
      ),
    ]) {
      final (start, end) = RamadanBanner.skyOf(decor, moment);
      for (final sky in [start, end]) {
        expect(
          _contrast(decor.onSky, sky),
          greaterThan(4.5),
          reason: '$moment',
        );
        expect(_contrast(status, sky), greaterThan(4.5), reason: '$moment');
        expect(
          _contrast(tagline(sky), sky),
          greaterThan(4.5),
          reason: '$moment',
        );
      }
    }
  });
}
