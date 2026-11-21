import 'package:flutter_test/flutter_test.dart';
import 'package:wolof_quran/core/reading/local_date.dart';
import 'package:wolof_quran/core/seasonal/ramadan_calendar.dart';
import 'package:wolof_quran/core/config/seasonal_theme_config.dart';
import 'package:wolof_quran/core/config/theme/seasonal_theme.dart';
import 'package:wolof_quran/presentation/cubits/seasonal_theme_cubit.dart';

import '../support/fake_seasonal_theme_repository.dart';

void main() {
  final ramadanWindow = SeasonalThemeConfig(
    theme: SeasonalTheme.ramadan,
    enabled: true,
    start: DateTime(2027, 2, 8),
    end: DateTime(2027, 3, 9),
  );

  test('starts with the standard look when the switch is off', () {
    final cubit = SeasonalThemeCubit(repository: FakeSeasonalThemeRepository());
    addTearDown(cubit.close);

    expect(cubit.state.available, SeasonalTheme.none);
    expect(cubit.state.active, SeasonalTheme.none);
  });

  test('wears the cached season from the first state', () {
    final cubit = SeasonalThemeCubit(
      repository: FakeSeasonalThemeRepository(config: ramadanWindow),
      clock: () => DateTime(2027, 2, 20),
    );
    addTearDown(cubit.close);

    expect(cubit.state.active, SeasonalTheme.ramadan);
  });

  test('follows the remote switch, on then off', () {
    final repository = FakeSeasonalThemeRepository();
    final cubit = SeasonalThemeCubit(repository: repository);
    addTearDown(cubit.close);

    repository.push(FakeSeasonalThemeRepository.ramadanOn);
    expect(cubit.state.active, SeasonalTheme.ramadan);

    repository.push(SeasonalThemeConfig.disabled);
    expect(cubit.state.active, SeasonalTheme.none);
  });

  test(
    'the season starts and ends with the day when the app resumes',
    () async {
      // Before the eve: the night of 6 to 7 February.
      var now = DateTime(2027, 2, 7, 3);
      final repository = FakeSeasonalThemeRepository(config: ramadanWindow);
      final cubit = SeasonalThemeCubit(
        repository: repository,
        clock: () => now,
      );
      addTearDown(cubit.close);
      expect(cubit.state.active, SeasonalTheme.none);

      now = DateTime(2027, 2, 8, 6);
      await cubit.onAppResumed();
      expect(cubit.state.active, SeasonalTheme.ramadan);

      now = DateTime(2027, 3, 10, 6);
      await cubit.onAppResumed();
      expect(cubit.state.active, SeasonalTheme.none);
      expect(repository.refreshCount, 2);
    },
  );

  test('the user can keep the standard look during the season', () async {
    final repository = FakeSeasonalThemeRepository(
      config: FakeSeasonalThemeRepository.ramadanOn,
    );
    final cubit = SeasonalThemeCubit(repository: repository);
    addTearDown(cubit.close);

    await cubit.setEnabledByUser(false);

    expect(cubit.state.active, SeasonalTheme.none);
    // Still offered, so the settings keep showing the switch.
    expect(cubit.state.available, SeasonalTheme.ramadan);
    expect(repository.disabledByUser, {SeasonalTheme.ramadan});

    await cubit.setEnabledByUser(true);
    expect(cubit.state.active, SeasonalTheme.ramadan);
    expect(repository.disabledByUser, isEmpty);
  });

  test('the choice of the user survives a restart and a remote refresh', () {
    final repository = FakeSeasonalThemeRepository(
      config: FakeSeasonalThemeRepository.ramadanOn,
      disabledByUser: {SeasonalTheme.ramadan},
    );
    final cubit = SeasonalThemeCubit(repository: repository);
    addTearDown(cubit.close);
    expect(cubit.state.active, SeasonalTheme.none);

    // The remote config answers again, with another window.
    repository.push(
      SeasonalThemeConfig(
        theme: SeasonalTheme.ramadan,
        enabled: true,
        end: DateTime(2100),
      ),
    );
    expect(cubit.state.available, SeasonalTheme.ramadan);
    expect(cubit.state.active, SeasonalTheme.none);
  });

  test('the switch does nothing out of season', () async {
    final repository = FakeSeasonalThemeRepository();
    final cubit = SeasonalThemeCubit(repository: repository);
    addTearDown(cubit.close);

    await cubit.setEnabledByUser(false);

    expect(cubit.state, const SeasonalThemeState());
    expect(repository.disabledByUser, isEmpty);
  });

  group('dated Ramadan', () {
    test('turns on with the eve and shows the coming first night', () {
      final cubit = SeasonalThemeCubit(
        repository: FakeSeasonalThemeRepository(config: ramadanWindow),
        clock: () => DateTime(2027, 2, 7, 10),
      );
      addTearDown(cubit.close);

      expect(cubit.state.active, SeasonalTheme.ramadan);
      expect(cubit.state.moment!.period, RamadanPeriod.eve);
      expect(cubit.state.moment!.tonight, 1);
      expect(cubit.state.earliestFirstDay, const LocalDate(2027, 2, 8));
    });

    test(
      'a later start moves the nights and is saved for the season',
      () async {
        final repository = FakeSeasonalThemeRepository(config: ramadanWindow);
        final cubit = SeasonalThemeCubit(
          repository: repository,
          clock: () => DateTime(2027, 3, 5, 21),
        );
        addTearDown(cubit.close);
        expect(cubit.state.moment!.night, 27);

        await cubit.setStartOffset(1);

        expect(cubit.state.startOffset, 1);
        expect(cubit.state.moment!.night, 26);
        expect(cubit.state.calendar!.firstDay, const LocalDate(2027, 2, 9));
        // The days offered stay those of the config.
        expect(cubit.state.earliestFirstDay, const LocalDate(2027, 2, 8));

        // Read back after a restart, offline.
        final restarted = SeasonalThemeCubit(
          repository: repository,
          clock: () => DateTime(2027, 3, 5, 21),
        );
        addTearDown(restarted.close);
        expect(restarted.state.moment!.night, 26);
      },
    );

    test(
      'the start chosen for one season does not carry to the next',
      () async {
        final repository = FakeSeasonalThemeRepository(config: ramadanWindow);
        var now = DateTime(2027, 2, 20, 12);
        final cubit = SeasonalThemeCubit(
          repository: repository,
          clock: () => now,
        );
        addTearDown(cubit.close);
        await cubit.setStartOffset(1);

        now = DateTime(2028, 1, 30, 12);
        repository.push(
          SeasonalThemeConfig(
            theme: SeasonalTheme.ramadan,
            enabled: true,
            start: DateTime(2028, 1, 28),
          ),
        );

        expect(cubit.state.startOffset, 0);
        expect(cubit.state.moment!.day, 3);
      },
    );

    test('the offset never goes beyond the last day offered', () async {
      final repository = FakeSeasonalThemeRepository(config: ramadanWindow);
      final cubit = SeasonalThemeCubit(
        repository: repository,
        clock: () => DateTime(2027, 2, 20, 12),
      );
      addTearDown(cubit.close);

      await cubit.setStartOffset(5);
      expect(cubit.state.startOffset, RamadanCalendar.maxStartOffset);
    });

    test('the user can still keep the standard look', () async {
      final repository = FakeSeasonalThemeRepository(config: ramadanWindow);
      final cubit = SeasonalThemeCubit(
        repository: repository,
        clock: () => DateTime(2027, 2, 20, 12),
      );
      addTearDown(cubit.close);

      await cubit.setEnabledByUser(false);

      expect(cubit.state.active, SeasonalTheme.none);
      expect(cubit.state.available, SeasonalTheme.ramadan);
    });

    testWidgets('a timer turns day 26 into night 27 while the app stays open', (
      tester,
    ) async {
      var now = DateTime(2027, 3, 5, 18, 50);
      final cubit = SeasonalThemeCubit(
        repository: FakeSeasonalThemeRepository(config: ramadanWindow),
        clock: () => now,
      );
      expect(cubit.state.moment!.day, 26);

      now = DateTime(2027, 3, 5, 19);
      await tester.pump(const Duration(minutes: 10));
      expect(cubit.state.moment!.night, 27);

      await cubit.close();
    });

    testWidgets('no timer runs out of season', (tester) async {
      final cubit = SeasonalThemeCubit(
        repository: FakeSeasonalThemeRepository(),
        clock: () => DateTime(2026, 11, 21, 12),
      );
      // Closed only after the test: a pending timer would fail it first.
      addTearDown(cubit.close);
    });
  });
}
