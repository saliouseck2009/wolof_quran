import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';

class HomeActionsGrid extends StatelessWidget {
  const HomeActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ModernActionCard(
                icon: Icons.menu_book_outlined,
                title: localizations.quran,
                subtitle: localizations.readSurahs,
                onTap: () => Navigator.pushNamed(context, '/surahs'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ModernActionCard(
                icon: Icons.headphones_outlined,
                title: localizations.recitation,
                subtitle: localizations.listenAudio,
                onTap: () => Navigator.pushNamed(context, '/surah-audio-list'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ModernActionCard(
                icon: Icons.search_outlined,
                title: localizations.search,
                subtitle: localizations.findVerses,
                onTap: () => Navigator.pushNamed(context, '/search'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ModernActionCard(
                icon: Icons.bookmark_outline,
                title: localizations.bookmarks,
                subtitle: localizations.savedAyahs,
                onTap: () => Navigator.pushNamed(context, '/bookmarks'),
              ),
            ),
          ],
        ),
      ],
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
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
