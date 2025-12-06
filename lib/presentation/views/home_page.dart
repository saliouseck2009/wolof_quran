import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wolof_quran/presentation/cubits/audio_management_cubit.dart';
import 'package:quran/quran.dart' as quran;
import 'package:wolof_quran/presentation/cubits/daily_inspiration_cubit.dart';
import '../../l10n/generated/app_localizations.dart';
import '../cubits/quran_settings_cubit.dart';
import '../cubits/bookmark_cubit.dart';
import '../cubits/surah_detail_cubit.dart';
import '../../domain/entities/bookmark.dart';
import '../../domain/repositories/bookmark_repository.dart';
import '../../service_locator.dart';
import '../widgets/ayah_play_button.dart';

class HomePage extends StatelessWidget {
  static const String routeName = "/";

  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              BookmarkCubit(locator<BookmarkRepository>())..loadBookmarks(),
        ),
        BlocProvider(create: (context) => DailyInspirationCubit()),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<AudioManagementCubit, AudioManagementState>(
            listener: (context, audioState) {
              if (audioState is AudioManagementError) {
                final theme = Theme.of(context);
                final colorScheme = theme.colorScheme;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      audioState.message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onError,
                      ),
                    ),
                    backgroundColor: colorScheme.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
          ),
        ],
        child: Scaffold(
          backgroundColor: colorScheme.surface,
          body: Container(
            height: double.infinity,
            decoration: colorScheme.brightness == Brightness.dark
                ? BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        colorScheme.surfaceContainerLowest,
                        colorScheme.surfaceDim,
                      ],
                    ),
                  )
                : null, // No gradient for light theme
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      _buildHeader(context, localizations),
                      const SizedBox(height: 32),

                      // Daily Inspiration Card (merged greeting + random ayah)
                      _buildDailyInspirationCard(context, localizations),
                      const SizedBox(height: 32),

                      // Quick Actions Title
                      Text(
                        localizations.search, // Using available localization
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                          fontFamily: 'Hafs',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Main Actions Grid
                      _buildMainActionsGrid(context, localizations),
                    ],
                  ),
                ),
              ),
            ),
          ), // Scaffold
        ), // MultiBlocListener
      ),
    ); // MultiBlocProvider
  }
}

Widget _buildModernActionCard(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
}) {
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

Widget _buildHeader(BuildContext context, AppLocalizations localizations) {
  final colorScheme = Theme.of(context).colorScheme;
  final accentGreen = colorScheme.primary;

  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Row(
        children: [
          AppIcon(accentGreen: accentGreen, colorScheme: colorScheme),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'السلام عليكم',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                  fontFamily: 'Hafs',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                localizations.welcome,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),

      IconButton(
        onPressed: () {
          Navigator.pushNamed(context, '/settings');
        },
        icon: Icon(
          Icons.settings_outlined,
          color: colorScheme.onSurface,
          size: 24,
        ),
      ),
    ],
  );
}

Widget _buildDailyInspirationCard(
  BuildContext context,
  AppLocalizations localizations,
) {
  return BlocBuilder<DailyInspirationCubit, DailyInspirationState>(
    builder: (context, state) {
      if (state is DailyInspirationLoading) {
        return _buildLoadingCard(context);
      } else if (state is DailyInspirationLoaded) {
        return _buildInspirationCard(context, localizations, state);
      } else if (state is DailyInspirationError) {
        return _buildErrorCard(context, localizations, state.message);
      }
      return _buildInitialCard(context, localizations);
    },
  );
}

Widget _buildLoadingCard(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: colorScheme
          .surfaceContainer, // darkSurfaceHigh in dark, light surface in light
      borderRadius: BorderRadius.circular(24),
      boxShadow: colorScheme.brightness == Brightness.dark
          ? [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.1),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ]
          : null,
      border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
    ),
    child: Column(
      children: [
        CircularProgressIndicator(color: colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          'Loading daily inspiration...',
          style: TextStyle(
            fontSize: 16,
            color: colorScheme.onSurface,
            fontFamily: 'Hafs',
          ),
        ),
      ],
    ),
  );
}

Widget _buildInitialCard(BuildContext context, AppLocalizations localizations) {
  final colorScheme = Theme.of(context).colorScheme;
  final accentGreen = colorScheme.primary;
  return GestureDetector(
    onTap: () {
      final settingsCubit = context.read<QuranSettingsCubit>();
      final currentTranslation = settingsCubit.state is QuranSettingsLoaded
          ? (settingsCubit.state as QuranSettingsLoaded).selectedTranslation
          : quran.Translation.enSaheeh;
      context.read<DailyInspirationCubit>().generateRandomAyah(
        currentTranslation,
      );
    },
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        boxShadow: colorScheme.brightness == Brightness.dark
            ? [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.2),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ]
            : null,
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon(accentGreen: accentGreen, colorScheme: colorScheme),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Inspiration',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                        fontFamily: 'Hafs',
                      ),
                    ),
                    Text(
                      'القرآن الكريم',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: accentGreen,
                        fontFamily: 'Hafs',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Tap to get your daily verse from the Quran',
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurfaceVariant,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tap anywhere to start',
                style: TextStyle(
                  fontSize: 12,
                  color: accentGreen,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.play_disabled,
                    color: colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.touch_app, color: accentGreen, size: 20),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class AppIcon extends StatelessWidget {
  final double width;
  final double height;
  const AppIcon({
    super.key,
    required this.accentGreen,
    required this.colorScheme,
    this.width = 60,
    this.height = 60,
  });

  final ui.Color accentGreen;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accentGreen, accentGreen.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: colorScheme.brightness == Brightness.dark
            ? [
                BoxShadow(
                  color: accentGreen.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Icon(
        Icons.auto_stories_outlined,
        size: 30,
        color: colorScheme.onPrimary,
      ),
    );
  }
}

Widget _buildInspirationCard(
  BuildContext context,
  AppLocalizations localizations,
  DailyInspirationLoaded state,
) {
  final colorScheme = Theme.of(context).colorScheme;
  final accentGreen = colorScheme.primary;
  return GestureDetector(
    onTap: () => context.read<DailyInspirationCubit>().toggleExpansion(),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        boxShadow: colorScheme.brightness == Brightness.dark
            ? [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.2),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ]
            : null,
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Islamic logo and title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.4),
                  ),
                ),
                child: Flexible(
                  child: Text(
                    '${state.surahName} - Ayah ${state.verseNumber}',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AyahPlayButton(
                      surahNumber: state.surahNumber,
                      ayahNumber: state.verseNumber,
                      surahName: state.surahName,
                      size: 18.0,
                      color: accentGreen,
                    ),
                    IconButton(
                      onPressed: () {
                        _showDailyInspirationShareModal(
                          context,
                          state.verseNumber,
                          state.arabicText,
                          state.translation,
                          _getTranslationSourceName(state.currentTranslation),
                          state.surahName,
                          state.surahNumber,
                        );
                      },
                      icon: Icon(Icons.share, color: accentGreen, size: 18),
                    ),
                    IconButton(
                      onPressed: () {
                        final settingsCubit = context
                            .read<QuranSettingsCubit>();
                        final currentTranslation =
                            settingsCubit.state is QuranSettingsLoaded
                            ? (settingsCubit.state as QuranSettingsLoaded)
                                  .selectedTranslation
                            : quran.Translation.enSaheeh;
                        context.read<DailyInspirationCubit>().refreshAyah(
                          currentTranslation,
                        );
                      },
                      icon: Icon(Icons.refresh, color: accentGreen, size: 18),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Row(
          //   children: [
          //     Container(
          //       padding: const EdgeInsets.symmetric(
          //         horizontal: 12,
          //         vertical: 6,
          //       ),
          //       decoration: BoxDecoration(
          //         color: colorScheme.primary.withValues(alpha: 0.1),
          //         borderRadius: BorderRadius.circular(12),
          //         border: Border.all(
          //           color: colorScheme.primary.withValues(alpha: 0.4),
          //         ),
          //       ),
          //       child: Text(
          //         '${state.surahName} - Ayah ${state.verseNumber}',
          //         style: TextStyle(
          //           fontSize: 12,
          //           color: colorScheme.primary,
          //           fontWeight: FontWeight.w600,
          //         ),
          //       ),
          //     ),
          //   ],
          // ),
          const SizedBox(height: 16),
          Text(
            state.isExpanded || state.translation.length <= 150
                ? state.translation
                : '${state.translation.substring(0, 150)}...',
            style: TextStyle(
              fontSize: state.isExpanded ? 14 : 12,
              color: colorScheme.onSurface,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          // Arabic text (shown when expanded)
          if (state.isExpanded) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: accentGreen.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accentGreen.withValues(alpha: 0.2)),
              ),
              child: Text(
                state.arabicText,
                style: TextStyle(
                  fontSize: 20,
                  fontFamily: 'Hafs',
                  color: colorScheme.onSurface,
                  height: 1.8,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/surah-detail',
                        arguments: state.surahNumber,
                      );
                    },
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text(
                      'Open Surah',
                      style: TextStyle(fontSize: 11),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      foregroundColor: accentGreen,
                      side: BorderSide(color: accentGreen),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: BlocBuilder<BookmarkCubit, BookmarkState>(
                    builder: (context, bookmarkState) {
                      final isBookmarked = context
                          .read<BookmarkCubit>()
                          .isBookmarked(state.surahNumber, state.verseNumber);

                      return OutlinedButton.icon(
                        onPressed: () {
                          final bookmarkCubit = context.read<BookmarkCubit>();
                          final bookmark = BookmarkedAyah(
                            surahNumber: state.surahNumber,
                            verseNumber: state.verseNumber,
                            surahName: state.surahName,
                            arabicText: state.arabicText,
                            translation: state.translation,
                            translationSource: _getTranslationSourceName(
                              state.currentTranslation,
                            ),
                            createdAt: DateTime.now(),
                          );

                          bookmarkCubit.toggleBookmark(bookmark);
                        },
                        icon: Icon(
                          isBookmarked
                              ? Icons.bookmark
                              : Icons.bookmark_outline,
                          size: 16,
                        ),
                        label: Text(
                          isBookmarked ? 'Bookmarked' : 'Bookmark',
                          style: TextStyle(fontSize: 11),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: accentGreen),
                          backgroundColor: isBookmarked
                              ? accentGreen
                              : Colors.transparent,
                          foregroundColor: isBookmarked
                              ? colorScheme.onPrimary
                              : accentGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ] else ...[
            // Tap to expand hint
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tap to read Arabic & more',
                  style: TextStyle(
                    fontSize: 12,
                    color: accentGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(Icons.expand_more, color: accentGreen, size: 20),
              ],
            ),
          ],
        ],
      ),
    ),
  );
}

Widget _buildErrorCard(
  BuildContext context,
  AppLocalizations localizations,
  String errorMessage,
) {
  final colorScheme = Theme.of(context).colorScheme;
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: colorScheme.error.withValues(alpha: 0.3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.error_outline, color: colorScheme.error, size: 24),
            const SizedBox(width: 12),
            Text(
              'Daily Inspiration',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onErrorContainer,
                fontFamily: 'Hafs',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          errorMessage,
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onErrorContainer,
            fontFamily: 'Hafs',
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            final settingsCubit = context.read<QuranSettingsCubit>();
            final currentTranslation =
                settingsCubit.state is QuranSettingsLoaded
                ? (settingsCubit.state as QuranSettingsLoaded)
                      .selectedTranslation
                : quran.Translation.enSaheeh;
            context.read<DailyInspirationCubit>().generateRandomAyah(
              currentTranslation,
            );
          },
          icon: Icon(Icons.refresh),
          label: Text('Try Again'),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
          ),
        ),
      ],
    ),
  );
}

Widget _buildMainActionsGrid(
  BuildContext context,
  AppLocalizations localizations,
) {
  return Column(
    children: [
      Row(
        children: [
          Expanded(
            child: _buildModernActionCard(
              context,
              icon: Icons.menu_book_outlined,
              title: localizations.quran,
              subtitle: 'Read Surahs',
              onTap: () => Navigator.pushNamed(context, '/surahs'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildModernActionCard(
              context,
              icon: Icons.headphones_outlined,
              title: localizations.recitation,
              subtitle: 'Listen Audio',
              onTap: () => Navigator.pushNamed(context, '/surah-audio-list'),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: _buildModernActionCard(
              context,
              icon: Icons.search_outlined,
              title: localizations.search,
              subtitle: 'Find Verses',
              onTap: () => Navigator.pushNamed(context, '/search'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildModernActionCard(
              context,
              icon: Icons.bookmark_outline,
              title: 'Bookmarks',
              subtitle: 'Saved Ayahs',
              onTap: () => Navigator.pushNamed(context, '/bookmarks'),
            ),
          ),
        ],
      ),
    ],
  );
}

String _getTranslationSourceName(quran.Translation translation) {
  switch (translation) {
    case quran.Translation.enSaheeh:
      return 'Saheeh International';
    case quran.Translation.enClearQuran:
      return 'Clear Quran';
    case quran.Translation.frHamidullah:
      return 'Muhammad Hamidullah';
    case quran.Translation.trSaheeh:
      return 'Türkçe';
    case quran.Translation.mlAbdulHameed:
      return 'Malayalam';
    case quran.Translation.faHusseinDari:
      return 'Farsi';
    case quran.Translation.portuguese:
      return 'Português';
    case quran.Translation.itPiccardo:
      return 'Italiano';
    case quran.Translation.nlSiregar:
      return 'Nederlands';
    case quran.Translation.ruKuliev:
      return 'Русский';
    case quran.Translation.bengali:
      return 'Bengali';
    case quran.Translation.chinese:
      return 'Chinese';
    default:
      return 'Translation';
  }
}

void _showDailyInspirationShareModal(
  BuildContext context,
  int verseNumber,
  String arabicText,
  String translation,
  String translationSource,
  String surahName,
  int surahNumber,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DailyInspirationShareModal(
      verseNumber: verseNumber,
      arabicText: arabicText,
      translation: translation,
      translationSource: translationSource,
      surahName: surahName,
      surahNumber: surahNumber,
    ),
  );
}

class DailyInspirationShareModal extends StatefulWidget {
  final int verseNumber;
  final String arabicText;
  final String translation;
  final String translationSource;
  final String surahName;
  final int surahNumber;

  const DailyInspirationShareModal({
    super.key,
    required this.verseNumber,
    required this.arabicText,
    required this.translation,
    required this.translationSource,
    required this.surahName,
    required this.surahNumber,
  });

  @override
  State<DailyInspirationShareModal> createState() =>
      _DailyInspirationShareModalState();
}

class _DailyInspirationShareModalState
    extends State<DailyInspirationShareModal> {
  final GlobalKey _captureKey = GlobalKey();

  // Customization options
  late Color _selectedBackgroundColor;
  AyahDisplayMode _selectedDisplayMode = AyahDisplayMode.both;

  // Available background colors
  late List<Color> _backgroundColors;
  bool _didConfigureTheme = false;

  Color get _selectedForeground {
    final brightness = ThemeData.estimateBrightnessForColor(
      _selectedBackgroundColor,
    );
    return brightness == Brightness.dark ? Colors.white : Colors.black87;
  }

  Color get _selectedForegroundMuted =>
      _selectedForeground.withValues(alpha: 0.72);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didConfigureTheme) return;
    final colorScheme = Theme.of(context).colorScheme;
    _selectedBackgroundColor = colorScheme.primary;
    _backgroundColors = <Color>{
      colorScheme.primary,
      colorScheme.primaryContainer,
      colorScheme.secondary,
      colorScheme.secondaryContainer,
      colorScheme.tertiary,
      colorScheme.tertiaryContainer,
      colorScheme.surface,
      colorScheme.surfaceContainerHighest,
      colorScheme.inverseSurface,
      colorScheme.error,
    }.toList();
    _didConfigureTheme = true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final localizations = AppLocalizations.of(context)!;
    final isDark = colorScheme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(
            alpha: isDark ? 0.35 : 0.2,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Share Daily Inspiration',
                  style: textTheme.titleMedium?.copyWith(
                    fontFamily: 'Hafs',
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RepaintBoundary(key: _captureKey, child: _buildPreviewCard()),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Background Style'),
                  const SizedBox(height: 16),
                  _buildBackgroundColorSelector(),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Display Style'),
                  const SizedBox(height: 16),
                  _buildDisplayModeSelector(localizations),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _shareImage,
                    icon: Icon(Icons.share, color: colorScheme.onPrimary),
                    label: Text(
                      'Share Image',
                      style: textTheme.titleSmall?.copyWith(
                        fontFamily: 'Hafs',
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        fontFamily: 'Hafs',
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildPreviewCard() {
    final onBackground = _selectedForeground;
    final onBackgroundMuted = _selectedForegroundMuted;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _selectedBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            child: Column(
              children: [
                Icon(
                  Icons.auto_stories_outlined,
                  color: onBackground,
                  size: 36,
                ),
                const SizedBox(height: 8),
                Text(
                  'Daily Inspiration',
                  style: TextStyle(
                    fontFamily: 'Hafs',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: onBackground,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          if (_selectedDisplayMode == AyahDisplayMode.both ||
              _selectedDisplayMode == AyahDisplayMode.arabicOnly)
            Text(
              widget.arabicText,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'Hafs',
                fontSize: 30,
                fontWeight: FontWeight.w500,
                color: onBackground,
                height: 1.8,
              ),
            ),
          if (_selectedDisplayMode == AyahDisplayMode.both)
            Container(
              width: 60,
              height: 2,
              margin: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: onBackgroundMuted,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          if (_selectedDisplayMode == AyahDisplayMode.both ||
              _selectedDisplayMode == AyahDisplayMode.translationOnly)
            Text(
              widget.translation,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Hafs',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: onBackground,
                height: 1.5,
              ),
            ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: onBackgroundMuted.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.surahName,
              style: TextStyle(
                fontFamily: 'Hafs',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: onBackground,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: onBackgroundMuted.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${widget.surahNumber}:${widget.verseNumber}',
                  style: TextStyle(
                    fontFamily: 'Hafs',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: onBackground,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: onBackgroundMuted.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Wolof-Quran',
                  style: TextStyle(
                    fontFamily: 'Hafs',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: onBackground,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundColorSelector() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _backgroundColors.map((color) {
        final isSelected = color == _selectedBackgroundColor;
        final onColor =
            ThemeData.estimateBrightnessForColor(color) == Brightness.dark
            ? Colors.white
            : Colors.black87;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedBackgroundColor = color;
            });
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? onColor : Colors.transparent,
                width: 3,
              ),
              boxShadow: Theme.of(context).brightness == Brightness.dark
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? Icon(Icons.check, color: onColor, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDisplayModeSelector(AppLocalizations localizations) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    final modes = [
      (
        AyahDisplayMode.both,
        localizations.arabicAndTranslation,
        Icons.view_headline,
      ),
      (
        AyahDisplayMode.arabicOnly,
        localizations.arabicOnly,
        Icons.format_textdirection_r_to_l,
      ),
      (
        AyahDisplayMode.translationOnly,
        localizations.translationOnly,
        Icons.translate,
      ),
    ];

    return Column(
      children: modes.map((modeData) {
        final mode = modeData.$1;
        final label = modeData.$2;
        final icon = modeData.$3;
        final isSelected = mode == _selectedDisplayMode;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDisplayMode = mode;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primary.withValues(alpha: 0.14)
                  : colorScheme.surfaceContainerHigh.withValues(
                      alpha: isDark ? 0.35 : 0.6,
                    ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outlineVariant.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Hafs',
                      fontSize: 16,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: colorScheme.primary,
                    size: 20,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _shareImage() async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
      );

      // Capture the widget as an image
      final RenderRepaintBoundary boundary =
          _captureKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final Uint8List uint8List = byteData!.buffer.asUint8List();

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/daily_inspiration_${widget.surahNumber}_${widget.verseNumber}.png',
      );
      await file.writeAsBytes(uint8List);

      // Hide loading dialog
      if (!mounted) return;
      Navigator.pop(context);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            'Daily Inspiration - ${widget.surahName} - Verse ${widget.verseNumber}',
      );

      // Close modal
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      // Hide loading dialog if still showing
      if (mounted) Navigator.pop(context);

      // Show error
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error sharing image: $e',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onError,
            ),
          ),
          backgroundColor: colorScheme.error,
        ),
      );
    }
  }
}
