import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/seasonal_theme_config.dart';
import '../../core/config/theme/seasonal_theme.dart';
import '../../core/reading/local_date.dart';
import '../../core/seasonal/ramadan_calendar.dart';
import '../../domain/repositories/seasonal_theme_repository.dart';
import '../datasources/remote_config_service.dart';

class SeasonalThemeRepositoryImpl implements SeasonalThemeRepository {
  /// The remote file is tiny, but there is no point in asking for it each
  /// time the app comes back to the foreground.
  static const Duration refreshInterval = Duration(hours: 1);

  static const String _disabledKeyPrefix = 'seasonal_theme_disabled_';
  static const String _startOffsetKeyPrefix = 'seasonal_theme_start_offset_';

  final RemoteConfigService _remoteConfig;
  final SharedPreferences _prefs;

  SeasonalThemeRepositoryImpl({
    required RemoteConfigService remoteConfig,
    required SharedPreferences prefs,
  }) : _remoteConfig = remoteConfig,
       _prefs = prefs;

  @override
  SeasonalThemeConfig get config => _remoteConfig.seasonalTheme;

  @override
  Stream<SeasonalThemeConfig> get configChanges =>
      _remoteConfig.seasonalThemeChanges;

  @override
  Future<void> refresh() => _remoteConfig.refresh(minInterval: refreshInterval);

  @override
  bool isDisabledByUser(SeasonalTheme theme) =>
      _prefs.getBool('$_disabledKeyPrefix${theme.id}') ?? false;

  @override
  Future<void> setDisabledByUser(SeasonalTheme theme, bool disabled) =>
      _prefs.setBool('$_disabledKeyPrefix${theme.id}', disabled);

  @override
  int startOffset(SeasonalThemeConfig config) {
    final key = _startOffsetKey(config);
    final days = key == null ? null : _prefs.getInt(key);
    return (days ?? 0).clamp(0, RamadanCalendar.maxStartOffset);
  }

  @override
  Future<void> setStartOffset(SeasonalThemeConfig config, int days) async {
    final key = _startOffsetKey(config);
    if (key == null) {
      return;
    }
    await _prefs.setInt(key, days.clamp(0, RamadanCalendar.maxStartOffset));
  }

  /// One key per season, e.g. `seasonal_theme_start_offset_ramadan_2027-02-08`.
  static String? _startOffsetKey(SeasonalThemeConfig config) {
    final start = config.start;
    if (start == null) {
      return null;
    }
    return '$_startOffsetKeyPrefix${config.theme.id}_'
        '${LocalDate.fromDateTime(start).toIso()}';
  }
}
