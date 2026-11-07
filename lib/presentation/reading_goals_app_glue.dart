import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/navigation/app_routes.dart';
import '../core/navigation/mushaf_arguments.dart';
import '../core/services/reading_reminder_service.dart';
import '../domain/entities/reading_goal.dart';
import '../l10n/generated/app_localizations.dart';
import '../service_locator.dart';
import 'cubits/language_cubit.dart';
import 'cubits/quran_settings_cubit.dart';
import 'cubits/reading_goals_cubit.dart';
import 'views/mushaf_page.dart';
import 'views/reading_goals_page.dart';

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
  // Reminders are best effort: a platform without notification support
  // must never break the goals themselves.
  locator<ReadingReminderService>()
      .sync(
        goals: goalsState.goals,
        remindersEnabled: settings.remindersEnabled,
        copy: ReminderCopy(
          title: l10n.reminderTitle,
          singleGoalBody: (goal, pages) => l10n.reminderBodySingle(pages, goal),
          multiGoalBody: l10n.reminderBodyMulti,
        ),
      )
      .catchError((Object _) {});
}

/// Recomputes today's quotas when the app comes back to the foreground, so
/// a day change while in the background is reflected, and opens the mushaf
/// at the goal's next page when a reminder is tapped.
class ReadingGoalsLifecycle extends StatefulWidget {
  final Widget child;

  const ReadingGoalsLifecycle({super.key, required this.child});

  @override
  State<ReadingGoalsLifecycle> createState() => _ReadingGoalsLifecycleState();
}

class _ReadingGoalsLifecycleState extends State<ReadingGoalsLifecycle> {
  late final AppLifecycleListener _listener;
  StreamSubscription<String>? _taps;

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
    try {
      _taps = locator<ReadingReminderService>().taps.listen(_onReminderTap);
    } catch (_) {
      // No notification support on this platform.
    }
  }

  Future<void> _onReminderTap(String payload) async {
    final cubit = context.read<ReadingGoalsCubit>();
    if (cubit.state.isLoading) {
      await cubit.stream.firstWhere((state) => !state.isLoading);
    }
    if (!mounted) {
      return;
    }
    final navigator = AppRoutes.navigatorKey.currentState;
    if (navigator == null) {
      return;
    }
    final goalId = ReminderPayload.goalIdOf(payload);
    final progress = goalId == null ? null : cubit.state.progressOf(goalId);
    if (progress == null || progress.goal.status != ReadingGoalStatus.active) {
      navigator.pushNamed(ReadingGoalsPage.routeName);
      return;
    }
    await cubit.setActiveGoal(goalId);
    navigator.pushNamed(
      MushafPage.routeName,
      arguments: MushafArguments(initialPage: progress.resumePage),
    );
  }

  @override
  void dispose() {
    _taps?.cancel();
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
