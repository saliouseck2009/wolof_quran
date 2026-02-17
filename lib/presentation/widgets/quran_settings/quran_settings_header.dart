import 'package:flutter/material.dart';
import '../../../l10n/generated/app_localizations.dart';

class QuranSettingsHeader extends StatelessWidget {
  final AppLocalizations localizations;

  const QuranSettingsHeader({super.key, required this.localizations});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.brightness == Brightness.dark
            ? colorScheme.surfaceContainer
            : colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.brightness == Brightness.dark
              ? colorScheme.outline.withValues(alpha: 0.1)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.settings, size: 48, color: colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            localizations.quranSettings,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            localizations.quranSettingsDescription,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
