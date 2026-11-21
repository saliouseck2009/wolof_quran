import 'package:flutter_test/flutter_test.dart';
import 'package:wolof_quran/core/config/seasonal_theme_config.dart';
import 'package:wolof_quran/core/config/theme/seasonal_theme.dart';

void main() {
  group('SeasonalThemeConfig.fromJson', () {
    test('is off when the remote file says nothing', () {
      expect(SeasonalThemeConfig.fromJson(null), SeasonalThemeConfig.disabled);
      expect(
        SeasonalThemeConfig.disabled.themeOn(DateTime(2027, 2, 20)),
        SeasonalTheme.none,
      );
    });

    test('reads the switch and the window', () {
      final config = SeasonalThemeConfig.fromJson({
        'id': 'ramadan',
        'enabled': true,
        'start': '2027-02-08',
        'end': '2027-03-09',
      });

      expect(config.theme, SeasonalTheme.ramadan);
      expect(config.enabled, isTrue);
      expect(config.start, DateTime(2027, 2, 8));
      expect(config.end, DateTime(2027, 3, 9));
    });

    test('keeps the day of a longer ISO date', () {
      final config = SeasonalThemeConfig.fromJson({
        'id': 'ramadan',
        'enabled': true,
        'start': '2027-02-08T18:30:00Z',
      });

      expect(config.start, DateTime(2027, 2, 8));
      expect(config.end, isNull);
    });

    test('anything unexpected turns the theme off', () {
      for (final json in <Object?>[
        'ramadan',
        <String, dynamic>{},
        {'enabled': true}, // no theme
        {'id': 'eid', 'enabled': true}, // a season this version ignores
        {'id': 'ramadan'}, // no switch
        {'id': 'ramadan', 'enabled': 'true'},
        {'id': 'ramadan', 'enabled': true, 'start': '8 février 2027'},
        {'id': 'ramadan', 'enabled': true, 'end': 20270309},
        {'id': 'ramadan', 'enabled': true, 'end': '2027-02-31'},
        {'id': 'ramadan', 'enabled': true, 'eid_end': 'Korité'},
      ]) {
        expect(
          SeasonalThemeConfig.fromJson(json),
          SeasonalThemeConfig.disabled,
          reason: '$json',
        );
      }
    });

    test('toJson round-trips', () {
      final config = SeasonalThemeConfig(
        theme: SeasonalTheme.ramadan,
        enabled: true,
        start: DateTime(2027, 2, 8),
        end: DateTime(2027, 3, 9),
      );

      expect(config.toJson(), {
        'id': 'ramadan',
        'enabled': true,
        'start': '2027-02-08',
        'end': '2027-03-09',
      });
      expect(SeasonalThemeConfig.fromJson(config.toJson()), config);
    });

    test('reads the optional end of the Eid', () {
      final config = SeasonalThemeConfig.fromJson({
        'id': 'ramadan',
        'enabled': true,
        'start': '2027-02-08',
        'end': '2027-03-09',
        'eid_end': '2027-03-11',
      });

      expect(config.eidEnd, DateTime(2027, 3, 11));
      expect(config.toJson()['eid_end'], '2027-03-11');
      expect(SeasonalThemeConfig.fromJson(config.toJson()), config);
    });
  });

  group('SeasonalThemeConfig.themeOn', () {
    final window = SeasonalThemeConfig(
      theme: SeasonalTheme.ramadan,
      enabled: true,
      start: DateTime(2027, 2, 8),
      end: DateTime(2027, 3, 9),
    );

    test('is on from the first to the last day, both included', () {
      expect(window.themeOn(DateTime(2027, 2, 7, 23, 59)), SeasonalTheme.none);
      expect(window.themeOn(DateTime(2027, 2, 8)), SeasonalTheme.ramadan);
      expect(window.themeOn(DateTime(2027, 2, 20, 13)), SeasonalTheme.ramadan);
      expect(
        window.themeOn(DateTime(2027, 3, 9, 23, 59)),
        SeasonalTheme.ramadan,
      );
      expect(window.themeOn(DateTime(2027, 3, 10)), SeasonalTheme.none);
    });

    test('the master switch wins over the window', () {
      final off = SeasonalThemeConfig(
        theme: SeasonalTheme.ramadan,
        enabled: false,
        start: window.start,
        end: window.end,
      );

      expect(off.themeOn(DateTime(2027, 2, 20)), SeasonalTheme.none);
    });

    test('without a window it follows the switch alone', () {
      const on = SeasonalThemeConfig(
        theme: SeasonalTheme.ramadan,
        enabled: true,
      );

      expect(on.themeOn(DateTime(2026, 11, 16)), SeasonalTheme.ramadan);
    });

    test('a single bound leaves the other side open', () {
      final fromStart = SeasonalThemeConfig(
        theme: SeasonalTheme.ramadan,
        enabled: true,
        start: DateTime(2027, 2, 8),
      );
      final untilEnd = SeasonalThemeConfig(
        theme: SeasonalTheme.ramadan,
        enabled: true,
        end: DateTime(2027, 3, 9),
      );

      expect(fromStart.themeOn(DateTime(2027, 2, 7)), SeasonalTheme.none);
      expect(fromStart.themeOn(DateTime(2028, 1, 1)), SeasonalTheme.ramadan);
      expect(untilEnd.themeOn(DateTime(2026, 11, 16)), SeasonalTheme.ramadan);
      expect(untilEnd.themeOn(DateTime(2027, 3, 10)), SeasonalTheme.none);
    });
  });
}
