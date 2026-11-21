import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wolof_quran/core/config/seasonal_theme_config.dart';
import 'package:wolof_quran/core/config/theme/seasonal_theme.dart';
import 'package:wolof_quran/data/datasources/remote_config_service.dart';
import 'package:wolof_quran/data/repositories/seasonal_theme_repository_impl.dart';

void main() {
  SeasonalThemeConfig ramadanFrom(DateTime start) => SeasonalThemeConfig(
    theme: SeasonalTheme.ramadan,
    enabled: true,
    start: start,
  );

  Future<SeasonalThemeRepositoryImpl> repository() async {
    final prefs = await SharedPreferences.getInstance();
    return SeasonalThemeRepositoryImpl(
      remoteConfig: RemoteConfigService(dio: Dio(), prefs: prefs),
      prefs: prefs,
    );
  }

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('the start offset belongs to its season', () async {
    final repo = await repository();
    final season2027 = ramadanFrom(DateTime(2027, 2, 8));
    final season2028 = ramadanFrom(DateTime(2028, 1, 28));

    expect(repo.startOffset(season2027), 0);
    await repo.setStartOffset(season2027, 1);

    expect(repo.startOffset(season2027), 1);
    expect((await repository()).startOffset(season2027), 1);
    expect(repo.startOffset(season2028), 0);
  });

  test('the start offset stays within one day', () async {
    final repo = await repository();
    final season = ramadanFrom(DateTime(2027, 2, 8));

    await repo.setStartOffset(season, 3);
    expect(repo.startOffset(season), 1);
    await repo.setStartOffset(season, -2);
    expect(repo.startOffset(season), 0);
  });

  test('a season without a start keeps no offset', () async {
    final repo = await repository();
    const undated = SeasonalThemeConfig(
      theme: SeasonalTheme.ramadan,
      enabled: true,
    );

    await repo.setStartOffset(undated, 1);
    expect(repo.startOffset(undated), 0);
  });
}
