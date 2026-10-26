import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../cubits/quran_settings_cubit.dart';
import '../reading_goals/reading_goal_form_widgets.dart';

/// Lets the user enable automatic page validation in the mushaf and pick
/// the minimum time a page must stay open.
Future<void> showReadingTrackingSettingsSheet(BuildContext context) {
  final navigationBarHeight = MediaQuery.viewPaddingOf(context).bottom;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) =>
        _ReadingTrackingSettingsSheet(navigationBarHeight: navigationBarHeight),
  );
}

class _ReadingTrackingSettingsSheet extends StatelessWidget {
  final double navigationBarHeight;

  const _ReadingTrackingSettingsSheet({required this.navigationBarHeight});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocBuilder<QuranSettingsCubit, QuranSettingsState>(
      builder: (context, state) {
        final cubit = context.read<QuranSettingsCubit>();
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, navigationBarHeight + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      localizations.readingTrackingSettings,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
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
                      const SizedBox(height: 16),
                      FormSectionLabel(localizations.autoTrackingThreshold),
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
                                  state.autoTrackingThresholdSeconds == seconds,
                              onTap: () =>
                                  cubit.updateAutoTrackingThreshold(seconds),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                localizations.readingTrackingSubtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
