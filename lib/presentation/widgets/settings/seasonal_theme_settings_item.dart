import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/theme/seasonal_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../cubits/seasonal_theme_cubit.dart';
import 'settings_menu_item.dart';

/// Settings switch that lets the user keep the standard look during a
/// season. It only exists while the remote config turns a season on: out of
/// season it takes no room at all.
class SeasonalThemeSettingsItem extends StatelessWidget {
  const SeasonalThemeSettingsItem({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SeasonalThemeCubit>().state;
    if (state.available != SeasonalTheme.ramadan) {
      return const SizedBox.shrink();
    }
    final localizations = AppLocalizations.of(context)!;
    final enabled = state.enabledByUser;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      // One node for screen readers: the row is the switch.
      child: MergeSemantics(
        child: Semantics(
          toggled: enabled,
          child: SettingsMenuItem(
            icon: Icons.nights_stay_outlined,
            title: localizations.ramadanTheme,
            subtitle: localizations.ramadanThemeSubtitle,
            value: enabled ? localizations.enabled : localizations.disabled,
            onTap: () =>
                context.read<SeasonalThemeCubit>().setEnabledByUser(!enabled),
            trailing: ExcludeSemantics(
              child: IgnorePointer(
                child: Switch.adaptive(value: enabled, onChanged: (_) {}),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
