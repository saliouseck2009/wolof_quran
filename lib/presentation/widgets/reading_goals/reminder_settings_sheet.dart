import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/reading_goal.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../cubits/quran_settings_cubit.dart';
import '../../cubits/reading_goals_cubit.dart';
import '../../../core/services/reading_reminder_service.dart';
import '../../../service_locator.dart';
import '../snackbar.dart';

/// Daily reminder of one goal: on/off and time. Turning it on also turns
/// on reminders globally, asking for the notification permission first.
Future<void> showReminderSettingsSheet(
  BuildContext context, {
  required ReadingGoal goal,
}) {
  final navigationBarHeight = MediaQuery.viewPaddingOf(context).bottom;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _ReminderSettingsSheet(
      goalId: goal.id,
      navigationBarHeight: navigationBarHeight,
    ),
  );
}

/// Asks for the notification permission and records the global switch.
/// Returns whether reminders are now allowed.
Future<bool> enableRemindersGlobally(BuildContext context) async {
  final settings = context.read<QuranSettingsCubit>();
  if (settings.state.remindersEnabled) {
    return true;
  }
  final granted = await locator<ReadingReminderService>().requestPermission();
  if (!context.mounted) {
    return false;
  }
  if (!granted) {
    CustomSnackbar.showSnackbar(
      context,
      AppLocalizations.of(context)!.reminderPermissionDenied,
      duration: 4,
    );
    return false;
  }
  settings.updateRemindersEnabled(true);
  return true;
}

class _ReminderSettingsSheet extends StatelessWidget {
  final String goalId;
  final double navigationBarHeight;

  const _ReminderSettingsSheet({
    required this.goalId,
    required this.navigationBarHeight,
  });

  Future<void> _toggle(BuildContext context, ReadingGoal goal, bool on) async {
    final cubit = context.read<ReadingGoalsCubit>();
    if (on && !await enableRemindersGlobally(context)) {
      return;
    }
    await cubit.updateReminder(goal.id, goal.reminder.copyWith(enabled: on));
  }

  Future<void> _pickTime(BuildContext context, ReadingGoal goal) async {
    final cubit = context.read<ReadingGoalsCubit>();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: goal.reminder.hour,
        minute: goal.reminder.minute,
      ),
    );
    if (picked == null) {
      return;
    }
    await cubit.updateReminder(
      goal.id,
      goal.reminder.copyWith(hour: picked.hour, minute: picked.minute),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocBuilder<ReadingGoalsCubit, ReadingGoalsState>(
      builder: (context, state) {
        final goal = state.progressOf(goalId)?.goal;
        if (goal == null) {
          return const SizedBox.shrink();
        }
        final reminder = goal.reminder;
        final time = TimeOfDay(hour: reminder.hour, minute: reminder.minute);

        return Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, navigationBarHeight + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations.setReminder,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          goal.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: reminder.enabled,
                onChanged: (on) => _toggle(context, goal, on),
                title: Text(
                  localizations.reminderDaily,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(localizations.reminderSheetHint),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                enabled: reminder.enabled,
                leading: const Icon(Icons.schedule_rounded),
                title: Text(localizations.reminderTime),
                trailing: Text(
                  time.format(context),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: reminder.enabled ? colorScheme.primary : null,
                  ),
                ),
                onTap: () => _pickTime(context, goal),
              ),
            ],
          ),
        );
      },
    );
  }
}
