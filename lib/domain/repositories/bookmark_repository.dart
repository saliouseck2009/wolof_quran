import '../entities/bookmark.dart';

/// Repository interface for managing ayah bookmarks
abstract class BookmarkRepository {
  /// Add a bookmark for an ayah
  Future<void> addBookmark(BookmarkedAyah bookmark);

  /// Remove a bookmark for an ayah
  Future<void> removeBookmark(int surahNumber, int verseNumber);

  /// Toggle bookmark status for an ayah
  Future<bool> toggleBookmark(BookmarkedAyah bookmark);

  /// Check if an ayah is bookmarked
  Future<bool> isBookmarked(int surahNumber, int verseNumber);

  /// Get all bookmarked ayahs
  Future<List<BookmarkedAyah>> getAllBookmarks();

  /// Clear all bookmarks
  Future<void> clearAllBookmarks();

  /// Get total number of bookmarks
  Future<int> getBookmarkCount();

  /// Get bookmarks for a specific surah
  Future<List<BookmarkedAyah>> getBookmarksForSurah(int surahNumber);
}
