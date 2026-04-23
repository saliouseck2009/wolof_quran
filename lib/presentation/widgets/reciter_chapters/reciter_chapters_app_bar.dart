import 'package:flutter/material.dart';

import '../../../domain/entities/reciter.dart';
import '../../../l10n/generated/app_localizations.dart';

class ReciterChaptersAppBar extends StatelessWidget {
  final Reciter reciter;
  final Color accentColor;

  const ReciterChaptersAppBar({
    super.key,
    required this.reciter,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context)!;

    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      backgroundColor: isDark
          ? colorScheme.surfaceContainer
          : accentColor,
      iconTheme: IconThemeData(
        color: colorScheme.onPrimary,
      ),
      surfaceTintColor: Colors.transparent,
      shadowColor: isDark
          ? Colors.black.withValues(alpha: 0.4)
          : accentColor.withValues(alpha: 0.3),
      title: Text(
        reciter.name,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onPrimary,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.zero,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      colorScheme.surfaceContainer,
                      colorScheme.surface,
                    ]
                  : [accentColor.withValues(alpha: 0.85), accentColor],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.audioDownloads,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimary.withValues(alpha: 0.7),
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reciter.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
