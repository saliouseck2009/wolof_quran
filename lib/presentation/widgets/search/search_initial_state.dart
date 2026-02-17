import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';

class SearchInitialStateView extends StatelessWidget {
  const SearchInitialStateView({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.explore,
            size: 80,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 24),
          Text(
            localizations.searchInQuran,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              localizations.enterWordsToFindVerses,
              style: TextStyle(
                fontSize: 15,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
