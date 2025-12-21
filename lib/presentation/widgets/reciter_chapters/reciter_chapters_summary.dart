import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';

class ReciterChaptersSummary extends StatelessWidget {
  final int downloadedCount;
  final Color accentColor;
  final bool isDark;

  const ReciterChaptersSummary({
    super.key,
    required this.downloadedCount,
    required this.accentColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? accentColor.withValues(alpha: 0.05)
            : colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(12),
        border: isDark
            ? Border.all(
                color: accentColor.withValues(alpha: 0.25),
                width: 1,
              )
            : null,
      ),
      child: Row(
        children: [
          Icon(Icons.download_done, color: accentColor, size: 20),
          const SizedBox(width: 8),
          Text(
            localizations.surahsDownloaded(downloadedCount),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w400,
                  color: accentColor,
                ),
          ),
        ],
      ),
    );
  }
}
