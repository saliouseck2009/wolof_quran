import 'package:equatable/equatable.dart';

import 'theme/seasonal_theme.dart';

/// Remote switch of the seasonal look, read from the `seasonal_theme` object
/// of the remote config JSON (the same Gist as [SupportConfig]):
///
/// ```json
/// "seasonal_theme": {
///   "id": "ramadan",
///   "enabled": true,
///   "start": "2027-02-08",
///   "end": "2027-03-09"
/// }
/// ```
///
/// - `enabled` is the master switch: `false` (or no object at all) turns the
///   seasonal look off everywhere.
/// - `start` and `end` are optional calendar days, both included, compared
///   with the date of the device. With them the look turns itself on and
///   off, even offline once the config is cached. Without them it follows
///   `enabled` alone.
///
/// The default is off, so nothing changes until the config says so.
class SeasonalThemeConfig extends Equatable {
  final SeasonalTheme theme;
  final bool enabled;

  /// First and last day of the season, both included; null when open-ended.
  final DateTime? start;
  final DateTime? end;

  const SeasonalThemeConfig({
    this.theme = SeasonalTheme.none,
    this.enabled = false,
    this.start,
    this.end,
  });

  static const SeasonalThemeConfig disabled = SeasonalThemeConfig();

  /// Reads the `seasonal_theme` value of the remote config. Anything
  /// unexpected (missing object, wrong types, unknown theme, unreadable
  /// date) gives [disabled]: a typo in the remote file must never leave the
  /// seasonal look on by accident.
  factory SeasonalThemeConfig.fromJson(Object? json) {
    if (json is! Map) {
      return disabled;
    }
    final theme = SeasonalTheme.fromId(json['id']);
    final enabled = json['enabled'];
    if (theme == SeasonalTheme.none || enabled is! bool) {
      return disabled;
    }
    final start = _parseDay(json['start']);
    final end = _parseDay(json['end']);
    if (start == _invalidDay || end == _invalidDay) {
      return disabled;
    }
    return SeasonalThemeConfig(
      theme: theme,
      enabled: enabled,
      start: start,
      end: end,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': theme.id,
    'enabled': enabled,
    if (start != null) 'start': _formatDay(start!),
    if (end != null) 'end': _formatDay(end!),
  };

  /// The seasonal theme to show on the calendar day of [now], or
  /// [SeasonalTheme.none].
  SeasonalTheme themeOn(DateTime now) {
    if (!enabled) {
      return SeasonalTheme.none;
    }
    final today = DateTime(now.year, now.month, now.day);
    final start = this.start;
    final end = this.end;
    if (start != null && today.isBefore(start)) {
      return SeasonalTheme.none;
    }
    if (end != null && today.isAfter(end)) {
      return SeasonalTheme.none;
    }
    return theme;
  }

  @override
  List<Object?> get props => [theme, enabled, start, end];

  static final DateTime _invalidDay = DateTime.utc(0);
  static final RegExp _dayPattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})');

  /// A `YYYY-MM-DD` day (a longer ISO date keeps its day only) as a local
  /// midnight, null when absent, [_invalidDay] when unreadable.
  static DateTime? _parseDay(Object? value) {
    if (value == null) {
      return null;
    }
    final match = value is String ? _dayPattern.firstMatch(value) : null;
    if (match == null) {
      return _invalidDay;
    }
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final date = DateTime(year, month, day);
    // DateTime rolls 2027-02-31 over to March: refuse such days.
    if (date.month != month || date.day != day) {
      return _invalidDay;
    }
    return date;
  }

  static String _formatDay(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';
}
