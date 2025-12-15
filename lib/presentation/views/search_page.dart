import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../l10n/generated/app_localizations.dart';
import '../cubits/search_cubit.dart';
import '../cubits/bookmark_cubit.dart' as bookmark_cubit;
import '../widgets/ayah_card.dart';
import '../widgets/ayah_play_button.dart';
import '../widgets/bookmarks_tab.dart';
import '../widgets/app_search_bar.dart';
import '../../service_locator.dart';
import '../../domain/repositories/bookmark_repository.dart';

class SearchPage extends StatelessWidget {
  static const String routeName = "/search";
  final int initialTab;

  const SearchPage({super.key, this.initialTab = 0});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => SearchCubit()),
        BlocProvider(
          create: (context) =>
              bookmark_cubit.BookmarkCubit(locator<BookmarkRepository>())
                ..loadBookmarks(),
        ),
      ],
      child: SearchView(initialTab: initialTab),
    );
  }
}

class SearchView extends StatefulWidget {
  final int initialTab;

  const SearchView({super.key, this.initialTab = 0});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  static const double _expandedHeight = 150;
  static const double _collapsedToolbarHeight = 72;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab.clamp(0, 1).toInt();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      context.read<SearchCubit>().clearSearch();
      return;
    }
    context.read<SearchCubit>().searchWords(trimmed);
    FocusScope.of(context).unfocus();
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<SearchCubit>().clearSearch();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: IndexedStack(
        index: _currentIndex,
        children: [_buildSearchTab(localizations, colorScheme), BookmarksTab()],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: NavigationBar(
            selectedIndex: _currentIndex,
            backgroundColor: Colors.transparent,
            elevation: 0,
            indicatorColor: colorScheme.primary.withValues(alpha: 0.1),
            height: 64,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
              if (index != 0) {
                _searchFocusNode.unfocus();
              }
            },
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.search_outlined),
                selectedIcon: Icon(
                  Icons.search,
                  color: Theme.of(context).colorScheme.primary,
                ),
                label: localizations.search,
              ),
              NavigationDestination(
                icon: const Icon(Icons.bookmark_outline),
                selectedIcon: Icon(
                  Icons.bookmark,
                  color: Theme.of(context).colorScheme.primary,
                ),
                label: localizations.bookmarks,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchTab(
    AppLocalizations localizations,
    ColorScheme colorScheme,
  ) {
    final searchState = context.watch<SearchCubit>().state;
    final hasActiveFilter =
        _searchController.text.isNotEmpty ||
        (searchState is SearchLoaded && searchState.searchQuery.isNotEmpty);
    final isDark = colorScheme.brightness == Brightness.dark;
    final accentGreen = isDark ? const Color(0xFF4CAF50) : colorScheme.primary;

    return NestedScrollView(
      headerSliverBuilder: (context, _) => [
        _buildSearchHeader(localizations, colorScheme, hasActiveFilter),
      ],
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Expanded(
              child: BlocBuilder<SearchCubit, SearchState>(
                builder: (context, state) {
                  if (state is SearchInitial) {
                    return _buildInitialState(localizations);
                  }

                  if (state is SearchLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is SearchError) {
                    return _buildErrorState(localizations, state.message);
                  }

                  if (state is SearchLoaded) {
                    return _buildSearchResults(
                      localizations,
                      state,
                      accentGreen,
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader(
    AppLocalizations localizations,
    ColorScheme colorScheme,
    bool hasActiveFilter,
  ) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final topPadding = MediaQuery.of(context).padding.top;
        final collapseOffset =
            (_expandedHeight - _collapsedToolbarHeight - topPadding).clamp(
              0.0,
              _expandedHeight,
            );
        final isCollapsed = constraints.scrollOffset > collapseOffset;

        return SliverAppBar(
          expandedHeight: _expandedHeight,
          floating: false,
          pinned: true,
          elevation: 2,
          backgroundColor: colorScheme.primary,
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
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _buildSearchBar(
                      localizations: localizations,
                      isInAppBar: true,
                      hasActiveFilter: hasActiveFilter,
                    ),
                  )
                : Text(
                    'Explorer',
                    key: const ValueKey('search-title'),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onPrimary,
                      fontSize: 18,
                    ),
                  ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: EdgeInsets.zero,
            background: Container(
              color: colorScheme.primary,
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
                        : _buildSearchBar(
                            localizations: localizations,
                            isInAppBar: false,
                            hasActiveFilter: hasActiveFilter,
                          ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar({
    required AppLocalizations localizations,
    required bool isInAppBar,
    required bool hasActiveFilter,
  }) {
    return AppSearchBar(
      controller: _searchController,
      focusNode: _searchFocusNode,
      hintText: localizations.enterWordsToSearch,
      isInAppBar: isInAppBar,
      hasActiveFilter: hasActiveFilter,
      onSubmitted: _performSearch,
      onSearch: () => _performSearch(_searchController.text),
      onClear: _clearSearch,
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildInitialState(AppLocalizations localizations) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.explore,
            size: 80,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 24),
          Text(
            localizations.searchInQuran,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              localizations.enterWordsToFindVerses,
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(AppLocalizations localizations, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 24),
          Text(
            localizations.searchError,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(
    AppLocalizations localizations,
    SearchLoaded state,
    Color accentGreen,
  ) {
    if (state.results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.travel_explore,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              localizations.noResultsFound,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              localizations.tryDifferentSearchTerms,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                localizations.foundOccurrences(
                  state.totalOccurrences,
                  state.results.length,
                ),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: state.results.length,
            itemBuilder: (context, index) {
              final result = state.results[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (index == 0 ||
                      state.results[index - 1].surahNumber !=
                          result.surahNumber)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(
                        top: 8,
                        bottom: 12,
                        left: 16,
                        right: 16,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: accentGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: accentGreen.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: accentGreen.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '${result.surahNumber}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: accentGreen,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            result.surahName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: accentGreen,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // margin: const EdgeInsets.only(bottom: 16),
                  AyahCard(
                    verseNumber: result.verseNumber,
                    arabicText: result.arabicText,
                    translationSource: state.translationSource,
                    translation: result.translation,
                    surahNumber: result.surahNumber,
                    surahName: result.surahName,
                    actions: [
                      AyahPlayButton(
                        surahNumber: result.surahNumber,
                        ayahNumber: result.verseNumber,
                        surahName: result.surahName,
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.open_in_new,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/surah-detail',
                            arguments: result.surahNumber,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
