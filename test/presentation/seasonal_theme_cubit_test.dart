import 'package:flutter_test/flutter_test.dart';
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
      var now = DateTime(2027, 2, 7, 22);
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
}
