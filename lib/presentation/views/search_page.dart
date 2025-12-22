import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../core/config/theme/app_color.dart';
import '../cubits/search_cubit.dart';
import '../cubits/bookmark_cubit.dart' as bookmark_cubit;
import '../widgets/bookmarks_tab.dart';
import '../widgets/app_search_bar.dart';
import '../widgets/search/search_error_state.dart';
import '../widgets/search/search_initial_state.dart';
import '../widgets/search/search_results_list.dart';
import '../widgets/search/search_sliver_header.dart';
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
      backgroundColor: colorScheme.brightness == Brightness.dark
          ? AppColor.surfaceDark
          : colorScheme.surface,
      body: IndexedStack(
        index: _currentIndex,
        children: [_buildSearchTab(localizations, colorScheme), BookmarksTab()],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.brightness == Brightness.dark
              ? colorScheme.surfaceContainer
              : colorScheme.surfaceContainer,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
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

    return NestedScrollView(
      headerSliverBuilder: (context, _) => [
        SearchSliverHeader(
          expandedHeight: _expandedHeight,
          collapsedToolbarHeight: _collapsedToolbarHeight,
          colorScheme: colorScheme,
          localizations: localizations,
          searchBarBuilder: (isCollapsed) => _buildSearchBar(
            localizations: localizations,
            isInAppBar: isCollapsed,
            hasActiveFilter: hasActiveFilter,
          ),
        ),
      ],
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Expanded(
              child: BlocBuilder<SearchCubit, SearchState>(
                builder: (context, state) {
                  if (state is SearchInitial) {
                    return const SearchInitialStateView();
                  }

                  if (state is SearchLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is SearchError) {
                    return SearchErrorStateView(message: state.message);
                  }

                  if (state is SearchLoaded) {
                    return SearchResultsList(state: state);
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

}
