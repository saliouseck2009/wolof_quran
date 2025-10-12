import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/config/theme/app_color.dart';
import '../../l10n/generated/app_localizations.dart';
import '../cubits/bookmark_cubit.dart';
import '../widgets/ayah_card.dart';
import '../widgets/ayah_play_button.dart';

class BookmarksTab extends StatelessWidget {
  const BookmarksTab({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocBuilder<BookmarkCubit, BookmarkState>(
      builder: (context, state) {
        if (state is BookmarkLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is BookmarkError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppColor.error),
                const SizedBox(height: 16),
                Text(
                  'Error loading bookmarks',
                  style: TextStyle(
                    fontFamily: 'Hafs',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColor.error,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.message,
                  style: TextStyle(
                    fontFamily: 'Hafs',
                    fontSize: 14,
                    color: AppColor.mediumGray,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (state is BookmarkLoaded) {
          if (state.bookmarks.isEmpty) {
            return _buildEmptyState(localizations);
          }

          return Column(
            children: [
              // Header with clear all button
              if (state.bookmarks.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${state.bookmarks.length} ${localizations.bookmarks.toLowerCase()}',
                        style: TextStyle(
                          fontFamily: 'Hafs',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColor.primaryGreen,
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            _showClearDialog(context, localizations),
                        child: Text(
                          localizations.clearAllBookmarks,
                          style: TextStyle(
                            fontFamily: 'Hafs',
                            color: AppColor.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Bookmarks list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: state.bookmarks.length,
                  itemBuilder: (context, index) {
                    final bookmark = state.bookmarks[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Surah header (show when different from previous)
                        if (index == 0 ||
                            state.bookmarks[index - 1].surahNumber !=
                                bookmark.surahNumber)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColor.primaryGreen.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColor.primaryGreen.withValues(
                                  alpha: 0.3,
                                ),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '${bookmark.surahNumber}. ${bookmark.surahName}',
                              style: TextStyle(
                                fontFamily: 'Hafs',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColor.primaryGreen,
                              ),
                            ),
                          ),

                        // Ayah card
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: AyahCard(
                            verseNumber: bookmark.verseNumber,
                            arabicText: bookmark.arabicText,
                            translationSource: bookmark.translationSource,
                            translation: bookmark.translation,
                            surahNumber: bookmark.surahNumber,
                            surahName: bookmark.surahName,
                            actions: [
                              AyahPlayButton(
                                surahNumber: bookmark.surahNumber,
                                ayahNumber: bookmark.verseNumber,
                                surahName: bookmark.surahName,
                              ),
                              // Bookmark button (filled since it's in bookmarks)
                              IconButton(
                                icon: Icon(
                                  Icons.bookmark,
                                  color: AppColor.primaryGreen,
                                ),
                                onPressed: () {
                                  context.read<BookmarkCubit>().removeBookmark(
                                    bookmark.surahNumber,
                                    bookmark.verseNumber,
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        localizations.bookmarkRemoved,
                                      ),
                                      duration: const Duration(seconds: 1),
                                      backgroundColor: AppColor.primaryGreen,
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.open_in_new,
                                  color: AppColor.mediumGray,
                                ),
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/surah-detail',
                                    arguments: bookmark.surahNumber,
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

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildEmptyState(AppLocalizations localizations) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_border, size: 64, color: AppColor.mediumGray),
          const SizedBox(height: 16),
          Text(
            'No Bookmarks', // Use hardcoded text since noBookmarks key doesn't exist
            style: TextStyle(
              fontFamily: 'Hafs',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColor.mediumGray,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              localizations.noBookmarksDescription,
              style: TextStyle(
                fontFamily: 'Hafs',
                fontSize: 14,
                color: AppColor.mediumGray,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  void _showClearDialog(BuildContext context, AppLocalizations localizations) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            localizations.confirmClearBookmarks,
            style: TextStyle(fontFamily: 'Hafs', fontWeight: FontWeight.w600),
          ),
          content: Text(
            localizations.clearBookmarksMessage,
            style: TextStyle(fontFamily: 'Hafs'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                localizations.cancel,
                style: TextStyle(
                  fontFamily: 'Hafs',
                  color: AppColor.mediumGray,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<BookmarkCubit>().clearAllBookmarks();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('All bookmarks cleared'),
                    backgroundColor: AppColor.primaryGreen,
                  ),
                );
              },
              child: Text(
                localizations.clear,
                style: TextStyle(
                  fontFamily: 'Hafs',
                  color: AppColor.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
