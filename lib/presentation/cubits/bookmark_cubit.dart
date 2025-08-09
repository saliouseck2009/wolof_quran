import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/bookmark.dart';
import '../../domain/repositories/bookmark_repository.dart';

// States
abstract class BookmarkState extends Equatable {
  const BookmarkState();

  @override
  List<Object> get props => [];
}

class BookmarkInitial extends BookmarkState {}

class BookmarkLoading extends BookmarkState {}

class BookmarkLoaded extends BookmarkState {
  final List<BookmarkedAyah> bookmarks;

  const BookmarkLoaded({required this.bookmarks});

  @override
  List<Object> get props => [bookmarks];

  BookmarkLoaded copyWith({List<BookmarkedAyah>? bookmarks}) {
    return BookmarkLoaded(bookmarks: bookmarks ?? this.bookmarks);
  }
}

class BookmarkError extends BookmarkState {
  final String message;

  const BookmarkError(this.message);

  @override
  List<Object> get props => [message];
}

// Cubit
class BookmarkCubit extends Cubit<BookmarkState> {
  final BookmarkRepository _bookmarkRepository;

  BookmarkCubit(this._bookmarkRepository) : super(BookmarkInitial());

  /// Load all bookmarks from storage
  Future<void> loadBookmarks() async {
    try {
      emit(BookmarkLoading());
      final bookmarks = await _bookmarkRepository.getAllBookmarks();
      emit(BookmarkLoaded(bookmarks: bookmarks));
    } catch (e) {
      emit(BookmarkError('Failed to load bookmarks: ${e.toString()}'));
    }
  }

  /// Check if an ayah is bookmarked
  bool isBookmarked(int surahNumber, int verseNumber) {
    final currentState = state;
    if (currentState is BookmarkLoaded) {
      return currentState.bookmarks.any(
        (bookmark) =>
            bookmark.surahNumber == surahNumber &&
            bookmark.verseNumber == verseNumber,
      );
    }
    return false;
  }

  /// Add a bookmark
  Future<void> addBookmark(BookmarkedAyah bookmark) async {
    try {
      emit(BookmarkLoading());
      await _bookmarkRepository.addBookmark(bookmark);
      await loadBookmarks(); // Reload to get updated list
    } catch (e) {
      emit(BookmarkError('Failed to add bookmark: ${e.toString()}'));
    }
  }

  /// Remove a bookmark
  Future<void> removeBookmark(int surahNumber, int verseNumber) async {
    try {
      emit(BookmarkLoading());
      await _bookmarkRepository.removeBookmark(surahNumber, verseNumber);
      await loadBookmarks(); // Reload to get updated list
    } catch (e) {
      emit(BookmarkError('Failed to remove bookmark: ${e.toString()}'));
    }
  }

  /// Toggle bookmark status
  Future<bool> toggleBookmark(BookmarkedAyah bookmark) async {
    try {
      final isCurrentlyBookmarked = await _bookmarkRepository.isBookmarked(
        bookmark.surahNumber,
        bookmark.verseNumber,
      );

      if (isCurrentlyBookmarked) {
        await removeBookmark(bookmark.surahNumber, bookmark.verseNumber);
        return false;
      } else {
        await addBookmark(bookmark);
        return true;
      }
    } catch (e) {
      emit(BookmarkError('Failed to toggle bookmark: ${e.toString()}'));
      return false;
    }
  }

  /// Clear all bookmarks
  Future<void> clearAllBookmarks() async {
    try {
      emit(BookmarkLoading());
      await _bookmarkRepository.clearAllBookmarks();
      emit(const BookmarkLoaded(bookmarks: []));
    } catch (e) {
      emit(BookmarkError('Failed to clear bookmarks: ${e.toString()}'));
    }
  }

  /// Get bookmarks count
  Future<int> getBookmarkCount() async {
    try {
      return await _bookmarkRepository.getBookmarkCount();
    } catch (e) {
      return 0;
    }
  }

  /// Get bookmarks for specific surah
  Future<List<BookmarkedAyah>> getBookmarksForSurah(int surahNumber) async {
    try {
      return await _bookmarkRepository.getBookmarksForSurah(surahNumber);
    } catch (e) {
      return [];
    }
  }

  /// Get bookmark count synchronously from current state
  int get bookmarkCount {
    final currentState = state;
    if (currentState is BookmarkLoaded) {
      return currentState.bookmarks.length;
    }
    return 0;
  }
}
