import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart' as quran;
import 'package:wolof_quran/core/helpers/revelation_place_enum.dart';
import 'package:wolof_quran/presentation/views/reciter_chapters_download_page.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../core/config/theme/app_color.dart';

import '../cubits/surah_list_cubit.dart';
import '../cubits/quran_settings_cubit.dart';
import '../widgets/app_search_bar.dart';

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

class _SurahListView extends StatefulWidget {
  const _SurahListView();

  @override
  State<_SurahListView> createState() => _SurahListViewState();
}

class _SurahListViewState extends State<_SurahListView> {
  static const double _expandedHeight = 150;
  static const double _collapsedToolbarHeight = 72;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.brightness == Brightness.dark
          ? AppColor.surfaceDark
          : colorScheme.surface,
      body: BlocListener<SurahListCubit, SurahListState>(
        listenWhen: (previous, current) {
          if (current is! SurahListLoaded) return false;
          final previousQuery = previous is SurahListLoaded
              ? previous.searchQuery
              : null;
          // Clear the input when translations reload or search is reset.
          return current.searchQuery.isEmpty &&
              (previousQuery?.isNotEmpty ?? _searchController.text.isNotEmpty);
        },
        listener: (context, state) {
          if (_searchController.text.isNotEmpty) {
            _searchController.clear();
          }
        },
        child: BlocBuilder<SurahListCubit, SurahListState>(
          builder: (context, state) {
            if (state is! SurahListLoaded) {
              return const Center(child: CircularProgressIndicator());
            }

            return CustomScrollView(
              slivers: [
                SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final topPadding = MediaQuery.of(context).padding.top;
                    final collapseOffset =
                        (_expandedHeight - _collapsedToolbarHeight - topPadding)
                            .clamp(0.0, _expandedHeight);
                    final isCollapsed =
                        constraints.scrollOffset > collapseOffset;
                    return SliverAppBar(
                      expandedHeight: _expandedHeight,
                      floating: false,
                      pinned: true,
                      elevation: 0,
                      backgroundColor: colorScheme.brightness == Brightness.dark
                          ? AppColor.surfaceDark
                          : colorScheme.primary,
                      iconTheme: IconThemeData(color: colorScheme.onPrimary),
                      surfaceTintColor: Colors.transparent,
                      shadowColor: colorScheme.shadow.withValues(alpha: 0.3),
                      toolbarHeight: _collapsedToolbarHeight,
                      titleSpacing: isCollapsed ? 0 : null,
                      title: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: isCollapsed
                            ? Padding(
                                key: const ValueKey('search-collapsed'),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: _buildSearchBar(
                                  context,
                                  state,
                                  isInAppBar: true,
                                ),
                              )
                            : Text(
                                localizations.surahs,
                                key: const ValueKey('surah-title'),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onPrimary,
                                  fontSize: 18,
                                ),
                              ),
                      ),
                      actions: [
                        IconButton(
                          icon: Icon(
                            Icons.settings,
                            color: colorScheme.onPrimary,
                          ),
                          onPressed: () async {
                            final result = await Navigator.pushNamed(
                              context,
                              '/quran-settings',
                            );
                            // If translation was changed, reload the Surah list
                            if (result == true && context.mounted) {
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
                            color: colorScheme.brightness == Brightness.dark
                                ? AppColor.surfaceDark
                                : colorScheme.primary,
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
                                child: isCollapsed
                                    ? const SizedBox.shrink()
                                    : _buildSearchBar(context, state),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // Surah List
                state.filteredSurahs.isEmpty && state.isSearching
                    ? _buildNoResults(context)
                    : SliverPadding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 16,
                          bottom: 48,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final surahNumber = state.filteredSurahs[index];
                            return _buildSurahCard(context, surahNumber, state);
                          }, childCount: state.filteredSurahs.length),
                        ),
                      ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar(
    BuildContext context,
    SurahListLoaded state, {
    bool isInAppBar = false,
  }) {
    final localizations = AppLocalizations.of(context)!;

    return AppSearchBar(
      controller: _searchController,
      hintText: localizations.searchSurah,
      isInAppBar: isInAppBar,
      hasActiveFilter: state.searchQuery.isNotEmpty,
      onChanged: (value) {
        context.read<SurahListCubit>().searchSurahs(value);
      },
      onClear: () {
        _searchController.clear();
        context.read<SurahListCubit>().clearSearch();
      },
    );
  }

  Widget _buildSurahCard(
    BuildContext context,
    int surahNumber,
    SurahListLoaded state,
  ) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

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
        color: colorScheme.brightness == Brightness.dark
            ? colorScheme.surfaceContainer
            : colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Surah number circle
                ChapterNumberWidget(
                  color: colorScheme.primary,
                  surahNumber: surahNumber,
                  textTheme: Theme.of(context).textTheme,
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
                              color: colorScheme.primary,
                            ),
                      ),

                      const SizedBox(height: 8),

                      // Verses count and revelation type
                      Row(
                        children: [
                          Flexible(
                            child: _buildInfoChip(
                              context,
                              '$versesCount ${localizations.verses}',
                              Icons.format_list_numbered,
                              colorScheme.secondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: _buildInfoChip(
                              context,
                              revelationType == RevelationPlaceEnum.meccan
                                  ? localizations.meccan
                                  : localizations.medinan,
                              revelationType == RevelationPlaceEnum.meccan
                                  ? Icons.location_on
                                  : Icons.location_city,
                              revelationType == RevelationPlaceEnum.meccan
                                  ? colorScheme.secondary
                                  : colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Arabic name on the right
                Text(
                  surahNameArabic,
                  style: TextStyle(
                    fontFamily: 'Hafs',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  overflow: TextOverflow.ellipsis,
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
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off,
                size: 40,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              localizations.noSurahFound,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              localizations.tryDifferentSearch,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
