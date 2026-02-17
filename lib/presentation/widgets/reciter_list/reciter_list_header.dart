import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';

class ReciterListHeader extends StatelessWidget {
  const ReciterListHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final localizations = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: colorScheme.brightness == Brightness.dark
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.surfaceContainer.withValues(alpha: 0.8),
                    colorScheme.surfaceContainer.withValues(alpha: 0.9),
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.onPrimary,
                    colorScheme.onPrimary,
                  ],
                ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              Icons.record_voice_over,
              size: 48,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              localizations.selectReciter,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              localizations.browseAndSelectReciterHint,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
