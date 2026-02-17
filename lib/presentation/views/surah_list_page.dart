import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart' as quran;
import 'package:wolof_quran/core/helpers/revelation_place_enum.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../core/config/theme/app_color.dart';

import '../cubits/surah_list_cubit.dart';
import '../cubits/quran_settings_cubit.dart';
import '../widgets/app_search_bar.dart';
import '../widgets/surah_list/surah_card.dart';
import '../widgets/surah_list/surah_list_no_results.dart';
import '../widgets/surah_list/surah_list_sliver_header.dart';

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
                SurahListSliverHeader(
                  expandedHeight: _expandedHeight,
                  collapsedToolbarHeight: _collapsedToolbarHeight,
                  colorScheme: colorScheme,
                  localizations: localizations,
                  searchBarBuilder: (isCollapsed) => _buildSearchBar(
                    context,
                    state,
                    isInAppBar: isCollapsed,
                  ),
                  onSettingsTap: () async {
                    final result = await Navigator.pushNamed(
                      context,
                      '/quran-settings',
                    );
                    if (result == true && context.mounted) {
                      context.read<SurahListCubit>().reloadTranslationSettings();
                    }
                  },
                ),
                // Surah List
                state.filteredSurahs.isEmpty && state.isSearching
                    ? const SurahListNoResults()
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
                            return _buildSurahCard(
                              context,
                              surahNumber,
                              state,
                              localizations,
                            );
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
    AppLocalizations localizations,
  ) {
    final surahNameArabic = quran.getSurahNameArabic(surahNumber);
    final surahNameTranslated = QuranSettingsCubit.getSurahNameInTranslation(
      surahNumber,
      state.selectedTranslation,
    );
    final versesCount = quran.getVerseCount(surahNumber);
    final revelationType = quran.getPlaceOfRevelation(surahNumber);

    final revelationLabel = revelationType == RevelationPlaceEnum.meccan
        ? localizations.meccan
        : localizations.medinan;

    return SurahCard(
      surahNumber: surahNumber,
      translatedName: surahNameTranslated,
      arabicName: surahNameArabic,
      versesLabel: '$versesCount ${localizations.verses}',
      revelationLabel: revelationLabel,
      revelationPlace: revelationType == RevelationPlaceEnum.meccan
          ? RevelationPlaceEnum.meccan
          : RevelationPlaceEnum.medinan,
      onTap: () {
        Navigator.pushNamed(
          context,
          '/surah-detail',
          arguments: surahNumber,
        );
      },
    );
  }
}
