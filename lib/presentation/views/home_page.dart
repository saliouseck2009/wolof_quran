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
import '../../core/config/theme/app_color.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(audioState.message),
                    backgroundColor: AppColor.error,
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
          body: Container(
            decoration: BoxDecoration(
              gradient: isDark
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppColor.charcoal, AppColor.darkGray],
                    )
                  : LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColor.primaryGreen,
                        AppColor.primaryGreen.withValues(alpha: 0.8),
                        AppColor.offWhite,
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      _buildHeader(context, localizations, isDark),
                      const SizedBox(height: 32),

                      // Daily Inspiration Card (merged greeting + random ayah)
                      _buildDailyInspirationCard(
                        context,
                        localizations,
                        isDark,
                      ),
                      const SizedBox(height: 32),

                      // Quick Actions Title
                      Text(
                        localizations.search, // Using available localization
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColor.pureWhite,
                          fontFamily: 'Hafs',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Main Actions Grid
                      _buildMainActionsGrid(context, localizations, isDark),
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
  required Color color,
  required VoidCallback onTap,
  required bool isDark,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark
              ? AppColor.pureWhite.withValues(alpha: 0.1)
              : AppColor.pureWhite.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? AppColor.pureWhite.withValues(alpha: 0.1)
                : AppColor.lightGray.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : color.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColor.pureWhite : AppColor.charcoal,
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
                color: isDark
                    ? AppColor.mediumGray
                    : AppColor.mediumGray.withValues(alpha: 0.8),
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

Widget _buildHeader(
  BuildContext context,
  AppLocalizations localizations,
  bool isDark,
) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'السلام عليكم',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColor.pureWhite : AppColor.pureWhite,
              fontFamily: 'Hafs',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            localizations.welcome,
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppColor.pureWhite.withValues(alpha: 0.8)
                  : AppColor.pureWhite.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      IconButton(
        onPressed: () {
          Navigator.pushNamed(context, '/settings');
        },
        icon: Icon(
          Icons.settings_outlined,
          color: isDark ? AppColor.pureWhite : AppColor.pureWhite,
          size: 24,
        ),
      ),
    ],
  );
}

Widget _buildDailyInspirationCard(
  BuildContext context,
  AppLocalizations localizations,
  bool isDark,
) {
  return BlocBuilder<DailyInspirationCubit, DailyInspirationState>(
    builder: (context, state) {
      if (state is DailyInspirationLoading) {
        return _buildLoadingCard(isDark);
      } else if (state is DailyInspirationLoaded) {
        return _buildInspirationCard(context, localizations, isDark, state);
      } else if (state is DailyInspirationError) {
        return _buildErrorCard(context, localizations, isDark, state.message);
      }
      return _buildInitialCard(context, localizations, isDark);
    },
  );
}

Widget _buildLoadingCard(bool isDark) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: isDark
          ? AppColor.pureWhite.withValues(alpha: 0.1)
          : AppColor.pureWhite.withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.3)
              : AppColor.primaryGreen.withValues(alpha: 0.1),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
      border: isDark
          ? Border.all(color: AppColor.pureWhite.withValues(alpha: 0.2))
          : null,
    ),
    child: Column(
      children: [
        CircularProgressIndicator(color: AppColor.primaryGreen),
        const SizedBox(height: 16),
        Text(
          'Loading daily inspiration...',
          style: TextStyle(
            fontSize: 16,
            color: isDark ? AppColor.pureWhite : AppColor.charcoal,
            fontFamily: 'Hafs',
          ),
        ),
      ],
    ),
  );
}

Widget _buildInitialCard(
  BuildContext context,
  AppLocalizations localizations,
  bool isDark,
) {
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
        color: isDark
            ? AppColor.pureWhite.withValues(alpha: 0.1)
            : AppColor.pureWhite.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : AppColor.primaryGreen.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: isDark
            ? Border.all(color: AppColor.pureWhite.withValues(alpha: 0.2))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColor.primaryGreen,
                      AppColor.primaryGreen.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppColor.primaryGreen.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.auto_stories_outlined,
                  size: 30,
                  color: AppColor.pureWhite,
                ),
              ),
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
                        color: isDark ? AppColor.pureWhite : AppColor.charcoal,
                        fontFamily: 'Hafs',
                      ),
                    ),
                    Text(
                      'القرآن الكريم',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColor.primaryGreen,
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
              color: isDark ? AppColor.pureWhite : AppColor.charcoal,
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
                  color: AppColor.primaryGreen,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: [
                  // Disabled play button (no ayah loaded yet)
                  Icon(
                    Icons.play_disabled,
                    color: AppColor.mediumGray,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.touch_app, color: AppColor.primaryGreen, size: 20),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _buildInspirationCard(
  BuildContext context,
  AppLocalizations localizations,
  bool isDark,
  DailyInspirationLoaded state,
) {
  return GestureDetector(
    onTap: () => context.read<DailyInspirationCubit>().toggleExpansion(),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? AppColor.pureWhite.withValues(alpha: 0.1)
            : AppColor.pureWhite.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : AppColor.primaryGreen.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: isDark
            ? Border.all(color: AppColor.pureWhite.withValues(alpha: 0.2))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Islamic logo and title
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColor.primaryGreen,
                      AppColor.primaryGreen.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppColor.primaryGreen.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.auto_stories_outlined,
                  size: 30,
                  color: AppColor.pureWhite,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Inspiration',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColor.pureWhite : AppColor.charcoal,
                        fontFamily: 'Hafs',
                      ),
                    ),
                    Text(
                      'القرآن الكريم',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColor.primaryGreen,
                        fontFamily: 'Hafs',
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  // Play button for the current ayah
                  AyahPlayButton(
                    surahNumber: state.surahNumber,
                    ayahNumber: state.verseNumber,
                    surahName: state.surahName,
                    size: 24.0,
                    color: AppColor.primaryGreen,
                  ),
                  const SizedBox(width: 4),
                  // Share button
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
                    icon: Icon(
                      Icons.share,
                      color: AppColor.primaryGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Refresh button
                  IconButton(
                    onPressed: () {
                      final settingsCubit = context.read<QuranSettingsCubit>();
                      final currentTranslation =
                          settingsCubit.state is QuranSettingsLoaded
                          ? (settingsCubit.state as QuranSettingsLoaded)
                                .selectedTranslation
                          : quran.Translation.enSaheeh;
                      context.read<DailyInspirationCubit>().refreshAyah(
                        currentTranslation,
                      );
                    },
                    icon: Icon(
                      Icons.refresh,
                      color: AppColor.primaryGreen,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Ayah info with improved layout
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColor.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColor.primaryGreen.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '${state.surahName} - Ayah ${state.verseNumber}',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColor.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Translation text (main content)
          Text(
            state.isExpanded || state.translation.length <= 150
                ? state.translation
                : '${state.translation.substring(0, 150)}...',
            style: TextStyle(
              fontSize: state.isExpanded ? 18 : 16,
              color: isDark ? AppColor.pureWhite : AppColor.charcoal,
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
                color: isDark
                    ? AppColor.darkGray.withValues(alpha: 0.3)
                    : AppColor.primaryGreen.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColor.primaryGreen.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                state.arabicText,
                style: TextStyle(
                  fontSize: 20,
                  fontFamily: 'Hafs',
                  color: isDark ? AppColor.pureWhite : AppColor.charcoal,
                  height: 1.8,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(height: 20),

            // Action buttons when expanded
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
                    icon: Icon(Icons.open_in_new, size: 16),
                    label: Text('Open Surah'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColor.primaryGreen,
                      side: BorderSide(color: AppColor.primaryGreen),
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
                        label: Text(isBookmarked ? 'Bookmarked' : 'Bookmark'),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColor.primaryGreen),
                          backgroundColor: isBookmarked
                              ? AppColor.primaryGreen
                              : Colors.transparent,
                          foregroundColor: isBookmarked
                              ? AppColor.pureWhite
                              : AppColor.primaryGreen,
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
                    color: AppColor.primaryGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(Icons.expand_more, color: AppColor.primaryGreen, size: 20),
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
  bool isDark,
  String errorMessage,
) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: isDark
          ? Colors.red.withValues(alpha: 0.2)
          : Colors.red.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 24),
            const SizedBox(width: 12),
            Text(
              'Daily Inspiration',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColor.pureWhite : AppColor.charcoal,
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
            color: isDark ? AppColor.pureWhite : AppColor.charcoal,
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
            backgroundColor: AppColor.primaryGreen,
            foregroundColor: AppColor.pureWhite,
          ),
        ),
      ],
    ),
  );
}

Widget _buildMainActionsGrid(
  BuildContext context,
  AppLocalizations localizations,
  bool isDark,
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
              color: AppColor.primaryGreen,
              onTap: () => Navigator.pushNamed(context, '/surahs'),
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildModernActionCard(
              context,
              icon: Icons.headphones_outlined,
              title: localizations.recitation,
              subtitle: 'Listen Audio',
              color: Colors.blue,
              onTap: () => Navigator.pushNamed(context, '/surah-audio-list'),
              isDark: isDark,
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
              color: Colors.purple,
              onTap: () => Navigator.pushNamed(context, '/search'),
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildModernActionCard(
              context,
              icon: Icons.bookmark_outline,
              title: 'Bookmarks',
              subtitle: 'Saved Ayahs',
              color: Colors.orange,
              onTap: () => Navigator.pushNamed(context, '/bookmarks'),
              isDark: isDark,
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
  Color _selectedBackgroundColor = AppColor.primaryGreen;
  AyahDisplayMode _selectedDisplayMode = AyahDisplayMode.both;

  // Available background colors
  final List<Color> _backgroundColors = [
    AppColor.primaryGreen,
    AppColor.charcoal,
    const Color(0xFF2E3440), // Nord dark
    const Color(0xFF3B4252), // Nord darker
    const Color(0xFF5D4037), // Brown
    const Color(0xFF37474F), // Blue Grey
    const Color(0xFF424242), // Grey
    const Color(0xFF1A237E), // Indigo
    const Color(0xFF4A148C), // Purple
    const Color(0xFF0D47A1), // Blue
  ];

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: isDark ? AppColor.charcoal : AppColor.pureWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColor.mediumGray,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Share Daily Inspiration',
                  style: TextStyle(
                    fontFamily: 'Hafs',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColor.pureWhite : AppColor.darkGray,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: isDark ? AppColor.pureWhite : AppColor.darkGray,
                  ),
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
                  // Preview Card
                  RepaintBoundary(key: _captureKey, child: _buildPreviewCard()),

                  const SizedBox(height: 32),

                  // Background Style Section
                  _buildSectionTitle('Background Style'),
                  const SizedBox(height: 16),
                  _buildBackgroundColorSelector(),

                  const SizedBox(height: 32),

                  // Display Style Section
                  _buildSectionTitle('Display Style'),
                  const SizedBox(height: 16),
                  _buildDisplayModeSelector(localizations),

                  const SizedBox(height: 32),

                  // Share Button
                  ElevatedButton.icon(
                    onPressed: _shareImage,
                    icon: const Icon(Icons.share, color: AppColor.pureWhite),
                    label: Text(
                      'Share Image',
                      style: const TextStyle(
                        fontFamily: 'Hafs',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColor.pureWhite,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primaryGreen,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'Hafs',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColor.pureWhite : AppColor.darkGray,
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _selectedBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Daily Inspiration Header
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            child: Column(
              children: [
                Icon(
                  Icons.auto_stories_outlined,
                  color: AppColor.pureWhite,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'Daily Inspiration',
                  style: TextStyle(
                    fontFamily: 'Hafs',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColor.pureWhite.withValues(alpha: 0.9),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          // Arabic text
          if (_selectedDisplayMode == AyahDisplayMode.both ||
              _selectedDisplayMode == AyahDisplayMode.arabicOnly)
            Text(
              widget.arabicText,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontFamily: 'Hafs',
                fontSize: 30,
                fontWeight: FontWeight.w500,
                color: AppColor.pureWhite,
                height: 1.8,
              ),
            ),

          // Separator
          if (_selectedDisplayMode == AyahDisplayMode.both)
            Container(
              width: 60,
              height: 2,
              margin: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: AppColor.pureWhite.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(1),
              ),
            ),

          // Translation text
          if (_selectedDisplayMode == AyahDisplayMode.both ||
              _selectedDisplayMode == AyahDisplayMode.translationOnly)
            Text(
              widget.translation,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Hafs',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: AppColor.pureWhite,
                height: 1.5,
              ),
            ),

          const SizedBox(height: 20),

          // Surah name
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColor.pureWhite.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.surahName,
              style: const TextStyle(
                fontFamily: 'Hafs',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColor.pureWhite,
                letterSpacing: 0.3,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Bottom row with surah info and app name
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left side: Surah and Ayah numbers
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColor.pureWhite.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${widget.surahNumber}:${widget.verseNumber}',
                  style: const TextStyle(
                    fontFamily: 'Hafs',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColor.pureWhite,
                  ),
                ),
              ),

              // Right side: App name
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColor.pureWhite.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Wolof-Quran',
                  style: TextStyle(
                    fontFamily: 'Hafs',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColor.pureWhite,
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
                color: isSelected ? AppColor.pureWhite : Colors.transparent,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: isSelected
                ? const Icon(Icons.check, color: AppColor.pureWhite, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDisplayModeSelector(AppLocalizations localizations) {
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
        final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  ? AppColor.primaryGreen.withValues(alpha: 0.1)
                  : (isDark
                        ? AppColor.charcoal.withValues(alpha: 0.5)
                        : AppColor.lightGray.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColor.primaryGreen : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? AppColor.primaryGreen
                      : AppColor.mediumGray,
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
                          ? AppColor.primaryGreen
                          : (isDark ? AppColor.pureWhite : AppColor.darkGray),
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: AppColor.primaryGreen,
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
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColor.primaryGreen),
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
      if (mounted) Navigator.pop(context);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            'Daily Inspiration - ${widget.surahName} - Verse ${widget.verseNumber}',
      );

      // Close modal
      if (mounted) Navigator.pop(context);
    } catch (e) {
      // Hide loading dialog if still showing
      if (mounted) Navigator.pop(context);

      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing image: $e'),
            backgroundColor: AppColor.error,
          ),
        );
      }
    }
  }
}
