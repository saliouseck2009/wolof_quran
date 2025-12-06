import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../l10n/generated/app_localizations.dart';
import '../cubits/search_cubit.dart';
import '../cubits/bookmark_cubit.dart' as bookmark_cubit;
import '../widgets/ayah_card.dart';
import '../widgets/ayah_play_button.dart';
import '../widgets/bookmarks_tab.dart';
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

class SearchView extends StatelessWidget {
  final int initialTab;

  const SearchView({super.key, this.initialTab = 0});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentGreen = isDark
        ? const Color(0xFF4CAF50)
        : Theme.of(context).colorScheme.primary;

    return DefaultTabController(
      length: 2,
      initialIndex: initialTab,
      child: Scaffold(
        backgroundColor: isDark ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: isDark ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            localizations.searchInQuran,
            style: TextStyle(
              fontFamily: 'Hafs',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface,
            ),
          ),
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: accentGreen,
            labelColor: accentGreen,
            unselectedLabelColor: isDark
                ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75)
                : Theme.of(context).colorScheme.onSurface,
            labelStyle: const TextStyle(
              fontFamily: 'Hafs',
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: 'Hafs',
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            tabs: [
              Tab(icon: const Icon(Icons.search), text: localizations.search),
              Tab(
                icon: const Icon(Icons.bookmark),
                text: localizations.bookmarks,
              ),
            ],
          ),
        ),
        body: TabBarView(children: [const _SearchBody(), const BookmarksTab()]),
      ),
    );
  }
}

class _SearchBody extends StatefulWidget {
  const _SearchBody();

  @override
  State<_SearchBody> createState() => _SearchBodyState();
}

class _SearchBodyState extends State<_SearchBody> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.trim().isNotEmpty) {
      context.read<SearchCubit>().searchWords(query.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentGreen = isDark
        ? const Color(0xFF4CAF50)
        : Theme.of(context).colorScheme.primary;

    return Column(
      children: [
        // Search Input
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Theme.of(context).colorScheme.surfaceContainer : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF364148)
                  : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            style: TextStyle(
              fontFamily: 'Hafs',
              fontSize: 16,
              color: isDark ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: localizations.enterWordsToSearch,
              hintStyle: TextStyle(
                fontFamily: 'Hafs',
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              prefixIcon: Icon(Icons.search, color: accentGreen),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      onPressed: () {
                        _searchController.clear();
                        context.read<SearchCubit>().clearSearch();
                        setState(() {}); // Update UI for clear button
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
            onChanged: (value) {
              setState(() {}); // Update UI for clear button
            },
            onSubmitted: _performSearch,
            textInputAction: TextInputAction.search,
          ),
        ),

        // Search Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _performSearch(_searchController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentGreen,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                localizations.search,
                style: TextStyle(
                  fontFamily: 'Hafs',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Search Results
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
                return _buildSearchResults(localizations, state);
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInitialState(AppLocalizations localizations) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            localizations.searchTheQuran,
            style: TextStyle(
              fontFamily: 'Hafs',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            localizations.enterWordsToFindVerses,
            style: TextStyle(
              fontFamily: 'Hafs',
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
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
          Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 16),
          Text(
            localizations.searchError,
            style: TextStyle(
              fontFamily: 'Hafs',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontFamily: 'Hafs',
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(
    AppLocalizations localizations,
    SearchLoaded state,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentGreen = isDark
        ? const Color(0xFF4CAF50)
        : Theme.of(context).colorScheme.primary;

    if (state.results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              localizations.noResultsFound,
              style: TextStyle(
                fontFamily: 'Hafs',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              localizations.tryDifferentSearchTerms,
              style: TextStyle(
                fontFamily: 'Hafs',
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
        // Results header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                localizations.foundOccurrences(
                  state.totalOccurrences,
                  state.results.length,
                ),
                style: TextStyle(
                  fontFamily: 'Hafs',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),

        // Results list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: state.results.length,
            itemBuilder: (context, index) {
              final result = state.results[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Surah header
                  if (index == 0 ||
                      state.results[index - 1].surahNumber !=
                          result.surahNumber)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: accentGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: accentGreen.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${result.surahNumber}. ${result.surahName}',
                        style: TextStyle(
                          fontFamily: 'Hafs',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: accentGreen,
                        ),
                      ),
                    ),

                  // Ayah card
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: AyahCard(
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
