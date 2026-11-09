import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../cubits/quran_settings_cubit.dart';
import '../reading_goals/reading_goal_form_widgets.dart';
import '../reading_goals/reminder_settings_sheet.dart';
import '../settings/settings_sheet.dart';

/// Lets the user enable automatic page validation in the mushaf and pick
/// the minimum time a page must stay open.
Future<void> showReadingTrackingSettingsSheet(BuildContext context) {
  return showSettingsSheet<void>(
    context: context,
    title: AppLocalizations.of(context)!.readingTrackingSettings,
    builder: (_) => const _ReadingTrackingSettings(),
  );
}

class _ReadingTrackingSettings extends StatelessWidget {
  const _ReadingTrackingSettings();

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocBuilder<QuranSettingsCubit, QuranSettingsState>(
      builder: (context, state) {
        final cubit = context.read<QuranSettingsCubit>();
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SettingsSheetCard(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: state.autoTrackingEnabled,
                    onChanged: cubit.updateAutoTrackingEnabled,
                    title: Text(
                      localizations.autoTracking,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(localizations.autoTrackingDescription),
                  ),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: state.autoTrackingEnabled ? 1 : 0.4,
                    child: IgnorePointer(
                      ignoring: !state.autoTrackingEnabled,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          FormSectionLabel(
                            localizations.autoTrackingThreshold,
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final seconds
                                  in QuranSettingsCubit
                                      .autoTrackingThresholdOptions)
                                QuickChoiceChip(
                                  label: localizations.secondsShort(seconds),
                                  selected:
                                      state.autoTrackingThresholdSeconds ==
                                      seconds,
                                  onTap: () => cubit
                                      .updateAutoTrackingThreshold(seconds),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SettingsSheetCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: state.remindersEnabled,
                onChanged: (on) async {
                  if (on) {
                    await enableRemindersGlobally(context);
                  } else {
                    cubit.updateRemindersEnabled(false);
                  }
                },
                title: Text(
                  localizations.remindersGlobal,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(localizations.remindersGlobalDescription),
              ),
            ),
          ],
        );
      },
    );
  }
}
