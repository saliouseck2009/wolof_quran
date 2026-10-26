import 'package:flutter/material.dart';
import '../views/surah_audio_list_page.dart';
import '../views/mushaf_page.dart';
import '../views/reading_goals_page.dart';
import '../../l10n/generated/app_localizations.dart';

class HomeActionsGrid extends StatelessWidget {
  const HomeActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final cards = [
      _GridCard(
        icon: Icons.menu_book_rounded,
        title: localizations.quran,
        subtitle: localizations.readSurahs,
        onTap: () => Navigator.pushNamed(context, '/surahs'),
      ),
      _GridCard(
        icon: Icons.headphones_rounded,
        title: localizations.recitation,
        subtitle: localizations.listenAudio,
        onTap: () => Navigator.pushNamed(context, SurahAudioListPage.routeName),
      ),
      _GridCard(
        icon: Icons.auto_stories_rounded,
        title: localizations.mushaf,
        subtitle: localizations.readByPage,
        onTap: () => Navigator.pushNamed(context, MushafPage.routeName),
      ),
      _GridCard(
        icon: Icons.flag_rounded,
        title: localizations.readingGoals,
        subtitle: localizations.readingGoalsSubtitle,
        onTap: () => Navigator.pushNamed(context, ReadingGoalsPage.routeName),
      ),
      _GridCard(
        icon: Icons.search_rounded,
        title: localizations.explorer,
        subtitle: '${localizations.search} & ${localizations.bookmarks}',
        onTap: () => Navigator.pushNamed(context, '/search'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.features,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 16),
        // Two cards per row; an odd last card spans the full width.
        for (var i = 0; i < cards.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: cards[i]),
              if (i + 1 < cards.length) ...[
                const SizedBox(width: 12),
                Expanded(child: cards[i + 1]),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _GridCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _GridCard({
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
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colorScheme.onSurface.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(18),
          ),
          child: _buildSquareLayout(colorScheme),
        ),
      ),
    );
  }

  Widget _buildSquareLayout(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: colorScheme.primary),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
