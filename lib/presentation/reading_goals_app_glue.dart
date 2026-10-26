import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/services/reading_reminder_service.dart';
import '../l10n/generated/app_localizations.dart';
import '../service_locator.dart';
import 'cubits/language_cubit.dart';
import 'cubits/quran_settings_cubit.dart';
import 'cubits/reading_goals_cubit.dart';

/// App-level wiring of reading goals: reminders follow every change of the
/// goals or of the settings, and the day rolls over when the app resumes.
List<BlocListener> readingGoalsAppListeners() {
  return [
    BlocListener<ReadingGoalsCubit, ReadingGoalsState>(
      listenWhen: (previous, current) =>
          !current.isLoading &&
          (previous.goals != current.goals || previous.isLoading),
      listener: (context, _) => _syncReminders(context),
    ),
    BlocListener<QuranSettingsCubit, QuranSettingsState>(
      listenWhen: (previous, current) =>
          previous.remindersEnabled != current.remindersEnabled,
      listener: (context, _) => _syncReminders(context),
    ),
  ];
}

void _syncReminders(BuildContext context) {
  final goalsState = context.read<ReadingGoalsCubit>().state;
  final settings = context.read<QuranSettingsCubit>().state;
  final l10n = lookupAppLocalizations(context.read<LanguageCubit>().state);
  locator<ReadingReminderService>().sync(
    goals: goalsState.goals,
    remindersEnabled: settings.remindersEnabled,
    copy: ReminderCopy(
      title: l10n.reminderTitle,
      singleGoalBody: (goal, pages) => l10n.reminderBodySingle(pages, goal),
      multiGoalBody: l10n.reminderBodyMulti,
    ),
  );
}

/// Recomputes today's quotas when the app comes back to the foreground, so
/// a day change while in the background is reflected.
class ReadingGoalsLifecycle extends StatefulWidget {
  final Widget child;

  const ReadingGoalsLifecycle({super.key, required this.child});

  @override
  State<ReadingGoalsLifecycle> createState() => _ReadingGoalsLifecycleState();
}

class _ReadingGoalsLifecycleState extends State<ReadingGoalsLifecycle> {
  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(
      onResume: () {
        if (mounted) {
          context.read<ReadingGoalsCubit>().refreshToday();
        }
      },
    );
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
