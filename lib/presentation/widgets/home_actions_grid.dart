import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;

import '../../l10n/generated/app_localizations.dart';
import '../utils/home_card_colors.dart';
import '../views/mushaf_page.dart';
import '../views/reading_goals_page.dart';
import '../views/surah_audio_list_page.dart';

/// Home menu laid out as a mosaic: the surahs in a tall featured tile, the
/// other entries in small tiles, two per row. A new entry only needs a
/// [_MenuEntry] appended to the list.
class HomeActionsGrid extends StatelessWidget {
  /// Number of ongoing reading goals, or null while they are loading.
  final int? ongoingGoals;

  const HomeActionsGrid({super.key, this.ongoingGoals});

  static const double _gap = 12;
  static const double _tileHeight = 104;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final goldInk = homeGoldInk(colorScheme);
    final goals = ongoingGoals ?? 0;

    final featured = _MenuEntry(
      icon: Icons.menu_book_rounded,
      title: localizations.surahs,
      subtitle: localizations.surahCountLabel(quran.totalSurahCount),
      routeName: '/surahs',
    );
    final entries = [
      _MenuEntry(
        icon: Icons.auto_stories_outlined,
        title: localizations.mushaf,
        subtitle: localizations.mushafPageCountLabel(quran.totalPagesCount),
        routeName: MushafPage.routeName,
      ),
      _MenuEntry(
        icon: Icons.headphones_outlined,
        title: localizations.recitation,
        routeName: SurahAudioListPage.routeName,
        background: colorScheme.secondary.withValues(alpha: 0.16),
        iconColor: goldInk,
      ),
      _MenuEntry(
        icon: Icons.flag_outlined,
        title: localizations.readingGoals,
        // Without goals the home strip already invites to create one.
        subtitle: goals > 0 ? localizations.ongoingGoalsCount(goals) : null,
        routeName: ReadingGoalsPage.routeName,
      ),
      _MenuEntry(
        icon: Icons.bookmark_outline_rounded,
        title: localizations.bookmarks,
        routeName: '/bookmarks',
      ),
    ];

    // Tiles keep their proportions when the user enlarges the text.
    final tileHeight = MediaQuery.textScalerOf(
      context,
    ).scale(_tileHeight).clamp(_tileHeight, _tileHeight * 2);
    final besideFeatured = entries.take(2).toList();
    final rest = entries.skip(2).toList();

    return Column(
      children: [
        SizedBox(
          height: tileHeight * 2 + _gap,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _MenuTile(entry: featured, featured: true)),
              const SizedBox(width: _gap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < besideFeatured.length; i++) ...[
                      if (i > 0) const SizedBox(height: _gap),
                      Expanded(child: _MenuTile(entry: besideFeatured[i])),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        for (var i = 0; i < rest.length; i += 2) ...[
          const SizedBox(height: _gap),
          SizedBox(
            height: tileHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _MenuTile(entry: rest[i])),
                const SizedBox(width: _gap),
                Expanded(
                  child: i + 1 < rest.length
                      ? _MenuTile(entry: rest[i + 1])
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _MenuEntry {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String routeName;
  final Color? background;
  final Color? iconColor;

  const _MenuEntry({
    required this.icon,
    required this.title,
    required this.routeName,
    this.subtitle,
    this.background,
    this.iconColor,
  });
}

class _MenuTile extends StatelessWidget {
  final _MenuEntry entry;
  final bool featured;

  const _MenuTile({required this.entry, this.featured = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = homeAccentColor(colorScheme);
    final background = featured
        ? accent.withValues(alpha: 0.12)
        : entry.background ?? homeCardColor(colorScheme);
    final subtitle = entry.subtitle;

    return Semantics(
      button: true,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, entry.routeName),
          child: Padding(
            padding: EdgeInsets.all(featured ? 18 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (featured)
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      entry.icon,
                      size: 24,
                      color: colorScheme.onPrimary,
                    ),
                  )
                else
                  Icon(entry.icon, size: 22, color: entry.iconColor ?? accent),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      entry.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: featured ? 18 : 15,
                        fontWeight: featured
                            ? FontWeight.w700
                            : FontWeight.w600,
                        letterSpacing: featured ? -0.2 : 0,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
