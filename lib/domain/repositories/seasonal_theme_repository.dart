import '../../core/config/seasonal_theme_config.dart';
import '../../core/config/theme/seasonal_theme.dart';

/// Where the seasonal look comes from: the remote switch, and the choice of
/// the user to keep the standard look during a season.
abstract class SeasonalThemeRepository {
  /// Last known remote switch (cached, so available offline).
  SeasonalThemeConfig get config;

  /// Emits each time a refresh changes the remote switch.
  Stream<SeasonalThemeConfig> get configChanges;

  /// Asks the remote config again if the last answer is getting old. Never
  /// throws.
  Future<void> refresh();

  /// Whether the user turned [theme] off in the settings.
  bool isDisabledByUser(SeasonalTheme theme);

  Future<void> setDisabledByUser(SeasonalTheme theme, bool disabled);

  /// Days the user started the season after the `start` of [config] (their
  /// community started later), 0 when they never chose. The choice belongs
  /// to that season: a new `start` the next year starts again from 0.
  int startOffset(SeasonalThemeConfig config);

  /// Saves [days] as the start offset of the season of [config]. Does
  /// nothing for a season without a start.
  Future<void> setStartOffset(SeasonalThemeConfig config, int days);
}
