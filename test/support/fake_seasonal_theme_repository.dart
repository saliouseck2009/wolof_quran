import 'dart:async';

import 'package:wolof_quran/core/config/seasonal_theme_config.dart';
import 'package:wolof_quran/core/config/theme/seasonal_theme.dart';
import 'package:wolof_quran/domain/repositories/seasonal_theme_repository.dart';

/// In-memory [SeasonalThemeRepository]: [push] plays the remote config
/// answering with a new switch.
class FakeSeasonalThemeRepository implements SeasonalThemeRepository {
  FakeSeasonalThemeRepository({
    this.config = SeasonalThemeConfig.disabled,
    Set<SeasonalTheme>? disabledByUser,
  }) : disabledByUser = disabledByUser ?? {};

  /// A Ramadan switch that is on whatever the day.
  static const SeasonalThemeConfig ramadanOn = SeasonalThemeConfig(
    theme: SeasonalTheme.ramadan,
    enabled: true,
  );

  @override
  SeasonalThemeConfig config;

  final Set<SeasonalTheme> disabledByUser;
  final StreamController<SeasonalThemeConfig> _changes =
      StreamController<SeasonalThemeConfig>.broadcast(sync: true);
  int refreshCount = 0;

  /// Saved start offsets, by `start` of the season.
  final Map<DateTime?, int> startOffsets = {};

  void push(SeasonalThemeConfig newConfig) {
    config = newConfig;
    _changes.add(newConfig);
  }

  @override
  Stream<SeasonalThemeConfig> get configChanges => _changes.stream;

  @override
  Future<void> refresh() async => refreshCount++;

  @override
  bool isDisabledByUser(SeasonalTheme theme) => disabledByUser.contains(theme);

  @override
  Future<void> setDisabledByUser(SeasonalTheme theme, bool disabled) async {
    if (disabled) {
      disabledByUser.add(theme);
    } else {
      disabledByUser.remove(theme);
    }
  }

  @override
  int startOffset(SeasonalThemeConfig config) =>
      startOffsets[config.start] ?? 0;

  @override
  Future<void> setStartOffset(SeasonalThemeConfig config, int days) async {
    if (config.start != null) {
      startOffsets[config.start] = days;
    }
  }
}
