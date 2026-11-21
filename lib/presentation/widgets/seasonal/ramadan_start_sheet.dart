import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/seasonal/ramadan_calendar.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../cubits/seasonal_theme_cubit.dart';
import '../settings/settings_sheet.dart';

/// Lets the user say on which day their community started to fast: the
/// earliest start of the config, or one day later. Does nothing out of a
/// dated Ramadan.
Future<void> showRamadanStartSheet(BuildContext context) async {
  final cubit = context.read<SeasonalThemeCubit>();
  final earliest = cubit.state.earliestFirstDay;
  if (earliest == null) {
    return;
  }
  final localizations = AppLocalizations.of(context)!;
  await showSettingsSheet<void>(
    context: context,
    title: localizations.ramadanStartTitle,
    subtitle: localizations.ramadanStartSubtitle,
    builder: (sheetContext) =>
        BlocProvider.value(value: cubit, child: const _StartChoices()),
  );
}

class _StartChoices extends StatelessWidget {
  const _StartChoices();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SeasonalThemeCubit>().state;
    final earliest = state.earliestFirstDay;
    if (earliest == null) {
      return const SizedBox.shrink();
    }
    final materialLocalizations = MaterialLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return SettingsSheetCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          for (
            var offset = 0;
            offset <= RamadanCalendar.maxStartOffset;
            offset++
          )
            _StartChoice(
              label: materialLocalizations.formatFullDate(
                earliest.addDays(offset).toDateTime(),
              ),
              selected: state.startOffset == offset,
              color: colorScheme.primary,
              onTap: () async {
                await context.read<SeasonalThemeCubit>().setStartOffset(offset);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
        ],
      ),
    );
  }
}

class _StartChoice extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _StartChoice({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected ? color : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
