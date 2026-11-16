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
}
