import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/config/theme/seasonal_theme.dart';
import '../../domain/repositories/seasonal_theme_repository.dart';

class SeasonalThemeState extends Equatable {
  /// The season the remote config turns on today, whatever the user chose.
  /// The settings offer their switch only while this is not
  /// [SeasonalTheme.none].
  final SeasonalTheme available;

  /// False once the user turned [available] off in the settings.
  final bool enabledByUser;

  const SeasonalThemeState({
    this.available = SeasonalTheme.none,
    this.enabledByUser = true,
  });

  /// The seasonal theme the app wears right now.
  SeasonalTheme get active => enabledByUser ? available : SeasonalTheme.none;

  @override
  List<Object?> get props => [available, enabledByUser];
}

/// Decides which seasonal look the app wears: the one the remote config
/// turns on for today, unless the user prefers the standard look.
///
/// It starts from the cached config, so the right look is there on the first
/// frame, then follows every later answer of the remote config.
class SeasonalThemeCubit extends Cubit<SeasonalThemeState> {
  final SeasonalThemeRepository _repository;
  final DateTime Function() _clock;
  late final StreamSubscription<void> _configChanges;

  SeasonalThemeCubit({
    required SeasonalThemeRepository repository,
    DateTime Function()? clock,
  }) : _repository = repository,
       _clock = clock ?? DateTime.now,
       super(_evaluate(repository, clock ?? DateTime.now)) {
    _configChanges = _repository.configChanges.listen((_) => _update());
  }

  static SeasonalThemeState _evaluate(
    SeasonalThemeRepository repository,
    DateTime Function() clock,
  ) {
    final available = repository.config.themeOn(clock());
    return SeasonalThemeState(
      available: available,
      enabledByUser: !repository.isDisabledByUser(available),
    );
  }

  void _update() {
    if (!isClosed) {
      emit(_evaluate(_repository, _clock));
    }
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
    emit(SeasonalThemeState(available: theme, enabledByUser: enabled));
    try {
      await _repository.setDisabledByUser(theme, !enabled);
    } catch (e) {
      debugPrint('Failed to save the seasonal theme preference: $e');
    }
  }

  @override
  Future<void> close() {
    _configChanges.cancel();
    return super.close();
  }
}
