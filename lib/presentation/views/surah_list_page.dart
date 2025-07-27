import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart' as quran;
import 'package:google_fonts/google_fonts.dart';
import 'package:wolof_quran/core/helpers/revelation_place_enum.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../core/config/theme/app_color.dart';
import '../cubits/surah_list_cubit.dart';
import '../cubits/quran_settings_cubit.dart';

class SurahListPage extends StatelessWidget {
  static const String routeName = "/surahs";

  const SurahListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SurahListCubit()..initialize(),
      child: const _SurahListView(),
    );
  }
}

class _SurahListView extends StatelessWidget {
  const _SurahListView();

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: BlocBuilder<SurahListCubit, SurahListState>(
        builder: (context, state) {
          if (state is! SurahListLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          return CustomScrollView(
            slivers: [
              // Modern App Bar with search
              SliverAppBar(
                expandedHeight: 180,
                floating: false,
                pinned: true,
                elevation: 2,
                title: Text(
                  localizations.surahs,
                  style: GoogleFonts.amiri(
                    fontWeight: FontWeight.w600,
                    color: AppColor.pureWhite,
                    fontSize: 18,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.settings, color: AppColor.pureWhite),
                    onPressed: () async {
                      final result = await Navigator.pushNamed(
                        context,
                        '/quran-settings',
                      );
                      // If translation was changed, reload the Surah list
                      if (result == true) {
                        context
                            .read<SurahListCubit>()
                            .reloadTranslationSettings();
                      }
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: EdgeInsets.zero,
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: isDark
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AppColor.charcoal, AppColor.darkGray],
                            )
                          : AppColor.primaryGradient,
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          bottom: 16,
                        ),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: _buildSearchBar(context, state),
                        ),
                      ),
                    ),
                  ),
                ),
                backgroundColor: isDark
                    ? AppColor.charcoal
                    : AppColor.primaryGreen,
                foregroundColor: AppColor.pureWhite,
              ),

              // Surah List
              state.filteredSurahs.isEmpty && state.isSearching
                  ? _buildNoResults(context)
                  : SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final surahNumber = state.filteredSurahs[index];
                          return _buildSurahCard(context, surahNumber, state);
                        }, childCount: state.filteredSurahs.length),
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, SurahListLoaded state) {
    final localizations = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: AppColor.pureWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColor.charcoal.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) {
          context.read<SurahListCubit>().searchSurahs(value);
        },
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: localizations.searchSurah,
          hintStyle: TextStyle(color: AppColor.translationText),
          prefixIcon: Icon(Icons.search, color: AppColor.primaryGreen),
          suffixIcon: state.searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: AppColor.translationText),
                  onPressed: () {
                    context.read<SurahListCubit>().clearSearch();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          filled: true,
          fillColor: AppColor.pureWhite,
        ),
      ),
    );
  }

  Widget _buildSurahCard(
    BuildContext context,
    int surahNumber,
    SurahListLoaded state,
  ) {
    final localizations = AppLocalizations.of(context)!;

    final surahNameArabic = quran.getSurahNameArabic(surahNumber);
    final surahNameTranslated = QuranSettingsCubit.getSurahNameInTranslation(
      surahNumber,
      state.selectedTranslation,
    );
    final versesCount = quran.getVerseCount(surahNumber);
    final revelationType = quran.getPlaceOfRevelation(surahNumber);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColor.primaryGreen.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Navigate to Surah detail page
            Navigator.pushNamed(
              context,
              '/surah-detail',
              arguments: surahNumber,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Surah number circle
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: AppColor.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      surahNumber.toString(),
                      style: GoogleFonts.amiri(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColor.pureWhite,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Surah info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Translated name
                      Text(
                        surahNameTranslated,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppColor.primaryGreen,
                            ),
                      ),

                      const SizedBox(height: 8),

                      // Verses count and revelation type
                      Row(
                        children: [
                          _buildInfoChip(
                            context,
                            '$versesCount ${localizations.verses}',
                            Icons.format_list_numbered,
                            AppColor.accent,
                          ),
                          const SizedBox(width: 8),
                          _buildInfoChip(
                            context,
                            revelationType == RevelationPlaceEnum.meccan
                                ? localizations.meccan
                                : localizations.medinan,
                            revelationType == RevelationPlaceEnum.meccan
                                ? Icons.location_on
                                : Icons.location_city,
                            revelationType == RevelationPlaceEnum.meccan
                                ? AppColor.gold
                                : AppColor.primaryGreen,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Arabic name on the right
                Text(
                  surahNameArabic,
                  style: GoogleFonts.amiriQuran(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColor.primaryGreen,
                  ),
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColor.lightGray,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off,
                size: 40,
                color: AppColor.mediumGray,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              localizations.noSurahFound,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColor.translationText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              localizations.tryDifferentSearch,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColor.mediumGray),
            ),
          ],
        ),
      ),
    );
  }
}
