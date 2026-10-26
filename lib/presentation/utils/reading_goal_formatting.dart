import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/reading/local_date.dart';
import '../../domain/entities/reading_goal.dart';
import '../../l10n/generated/app_localizations.dart';

/// Shared labels and colours of reading goals.
class ReadingGoalFormatting {
  const ReadingGoalFormatting._();

  static String date(BuildContext context, LocalDate date) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMd(locale).format(date.toDateTime());
  }

  static String dateTime(BuildContext context, DateTime dateTime) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMd(locale).format(dateTime);
  }

  static String phaseLabel(AppLocalizations l10n, ReadingGoalPhase phase) {
    switch (phase) {
      case ReadingGoalPhase.planned:
        return l10n.readingStatusPlanned;
      case ReadingGoalPhase.active:
        return l10n.readingStatusActive;
      case ReadingGoalPhase.paused:
        return l10n.readingStatusPaused;
      case ReadingGoalPhase.completed:
        return l10n.readingStatusCompleted;
      case ReadingGoalPhase.expired:
        return l10n.readingStatusExpired;
      case ReadingGoalPhase.abandoned:
        return l10n.readingStatusAbandoned;
    }
  }

  static Color phaseColor(ColorScheme colorScheme, ReadingGoalPhase phase) {
    switch (phase) {
      case ReadingGoalPhase.active:
        return colorScheme.primary;
      case ReadingGoalPhase.completed:
        return colorScheme.tertiary;
      case ReadingGoalPhase.expired:
        return colorScheme.error;
      case ReadingGoalPhase.planned:
        return colorScheme.secondary;
      case ReadingGoalPhase.paused:
      case ReadingGoalPhase.abandoned:
        return colorScheme.onSurfaceVariant;
    }
  }

  static String paceLabel(AppLocalizations l10n, int paceDelta) {
    if (paceDelta > 0) {
      return l10n.readingPaceAhead(paceDelta);
    }
    if (paceDelta < 0) {
      return l10n.readingPaceBehind(-paceDelta);
    }
    return l10n.readingPaceOnTrack;
  }

  /// One decimal, e.g. `20.1`, in the current locale.
  static String average(BuildContext context, double pagesPerDay) {
    final locale = Localizations.localeOf(context).toString();
    return NumberFormat('0.#', locale).format(pagesPerDay);
  }
}
