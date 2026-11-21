import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/config/theme/seasonal_theme.dart';
import '../../core/reading/local_date.dart';
import '../../core/seasonal/ramadan_calendar.dart';
import '../../domain/repositories/seasonal_theme_repository.dart';

class SeasonalThemeState extends Equatable {
  /// The season the remote config turns on today, whatever the user chose.
  /// The settings offer their switch only while this is not
  /// [SeasonalTheme.none].
  final SeasonalTheme available;

  /// False once the user turned [available] off in the settings.
  final bool enabledByUser;

  /// Days the user started the month after the earliest community, from 0
  /// to [RamadanCalendar.maxStartOffset].
  final int startOffset;

  /// The month of this user, with [startOffset] applied. Null out of season
  /// and for a Ramadan switch without dates.
  final RamadanCalendar? calendar;

  /// Where the user stands in the month right now, null when [calendar] is.
  final RamadanMoment? moment;

  const SeasonalThemeState({
    this.available = SeasonalTheme.none,
    this.enabledByUser = true,
    this.startOffset = 0,
    this.calendar,
    this.moment,
  });

  /// The seasonal theme the app wears right now.
  SeasonalTheme get active => enabledByUser ? available : SeasonalTheme.none;

  /// First day of fasting of the earliest community: the first of the days
  /// offered to the user.
  LocalDate? get earliestFirstDay => calendar?.firstDay.addDays(-startOffset);

  @override
  List<Object?> get props => [
    available,
    enabledByUser,
    startOffset,
    calendar,
    moment,
  ];
}

/// Decides which seasonal look the app wears: the one the remote config
/// turns on for today, unless the user prefers the standard look.
///
/// It starts from the cached config, so the right look is there on the first
/// frame, then follows every later answer of the remote config. During a
/// dated Ramadan it also follows the hours of the month: the look turns on
/// with the eve, the nights start at nightfall, and a single timer wakes it
/// for the next change while the app stays open.
class SeasonalThemeCubit extends Cubit<SeasonalThemeState> {
  final SeasonalThemeRepository _repository;
  final DateTime Function() _clock;
  late final StreamSubscription<void> _configChanges;
  Timer? _nextChange;

  SeasonalThemeCubit({
    required SeasonalThemeRepository repository,
    DateTime Function()? clock,
  }) : _repository = repository,
       _clock = clock ?? DateTime.now,
       super(_evaluate(repository, (clock ?? DateTime.now)())) {
    _configChanges = _repository.configChanges.listen((_) => _update());
    _scheduleNextChange();
  }

  static SeasonalThemeState _evaluate(
    SeasonalThemeRepository repository,
    DateTime now,
  ) {
    final config = repository.config;
    final startOffset = repository.startOffset(config);
    final calendar = config.enabled
        ? RamadanCalendar.fromConfig(config, startOffset: startOffset)
        : null;

    // A dated Ramadan follows its calendar (eve, nights, Korité); any other
    // switch follows its window of whole days.
    final moment = calendar?.momentAt(now);
    final available = calendar == null
        ? config.themeOn(now)
        : (moment == null ? SeasonalTheme.none : SeasonalTheme.ramadan);

    return SeasonalThemeState(
      available: available,
      enabledByUser: !repository.isDisabledByUser(available),
      startOffset: startOffset,
      calendar: moment == null ? null : calendar,
      moment: moment,
    );
  }

  void _update() {
    if (isClosed) {
      return;
    }
    emit(_evaluate(_repository, _clock()));
    _scheduleNextChange();
  }

  /// Only while a dated Ramadan is switched on: out of season no timer runs.
  void _scheduleNextChange() {
    _nextChange?.cancel();
    _nextChange = null;
    final config = _repository.config;
    if (!config.enabled || RamadanCalendar.fromConfig(config) == null) {
      return;
    }
    final now = _clock();
    final delay = RamadanCalendar.nextChangeAfter(now).difference(now);
    _nextChange = Timer(delay, _update);
  }

  /// To call when the app comes back to the foreground: the season may have
  /// started or ended with the day, or been switched remotely meanwhile.
  Future<void> onAppResumed() async {
    _update();
    await _repository.refresh();
  }

  /// The settings switch: lets the user keep the standard look during a
  /// season.
  Future<void> setEnabledByUser(bool enabled) async {
    final theme = state.available;
    if (theme == SeasonalTheme.none) {
      return;
    }
    emit(
      SeasonalThemeState(
        available: theme,
        enabledByUser: enabled,
        startOffset: state.startOffset,
        calendar: state.calendar,
        moment: state.moment,
      ),
    );
    try {
      await _repository.setDisabledByUser(theme, !enabled);
    } catch (e) {
      debugPrint('Failed to save the seasonal theme preference: $e');
    }
  }

  /// The user's community started [days] after the earliest one (0 to
  /// [RamadanCalendar.maxStartOffset]).
  /// Moves the days, the nights and the Korité of this user.
  Future<void> setStartOffset(int days) async {
    final config = _repository.config;
    if (RamadanCalendar.fromConfig(config) == null) {
      return;
    }
    try {
      await _repository.setStartOffset(
        config,
        days.clamp(0, RamadanCalendar.maxStartOffset),
      );
    } catch (e) {
      debugPrint('Failed to save the Ramadan start: $e');
    }
    _update();
  }

  @override
  Future<void> close() {
    _nextChange?.cancel();
    _configChanges.cancel();
    return super.close();
  }
}
