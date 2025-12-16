import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';

class HomeActionsGrid extends StatelessWidget {
  const HomeActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 16.0;
        final cardWidth = (constraints.maxWidth - spacing) / 2;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: cardWidth,
              child: _ModernActionCard(
                icon: Icons.menu_book_outlined,
                title: localizations.quran,
                subtitle: localizations.readSurahs,
                onTap: () => Navigator.pushNamed(context, '/surahs'),
              ),
            ),
            // SizedBox(
            //   width: cardWidth,
            //   child: _ModernActionCard(
            //     icon: Icons.headphones_outlined,
            //     title: localizations.recitation,
            //     subtitle: localizations.listenAudio,
            //     onTap: () => Navigator.pushNamed(context, '/surah-audio-list'),
            //   ),
            // ),
            SizedBox(
              width: cardWidth,
              child: _ModernActionCard(
                icon: Icons.explore_outlined,
                title: 'Explorer',
                subtitle:
                    '${localizations.search} & ${localizations.bookmarks}',
                onTap: () => Navigator.pushNamed(context, '/search'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ModernActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModernActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.surfaceContainer
                : colorScheme.onPrimary,
            borderRadius: BorderRadius.circular(20),
            // border: Border.all(
            //   color: colorScheme.outline.withValues(alpha: 0.2),
            // ),
            boxShadow: colorScheme.brightness == Brightness.dark
                ? [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.1),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 24, color: colorScheme.primary),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                  fontFamily: 'Hafs',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
