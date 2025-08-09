import '../../domain/entities/bookmark.dart';
import '../../domain/repositories/bookmark_repository.dart';
import '../datasources/database_helper.dart';

/// Implementation of BookmarkRepository
class BookmarkRepositoryImpl implements BookmarkRepository {
  final DatabaseHelper databaseHelper;

  BookmarkRepositoryImpl(this.databaseHelper);

  @override
  Future<void> addBookmark(BookmarkedAyah bookmark) async {
    await databaseHelper.insertBookmark(bookmark);
  }

  @override
  Future<void> removeBookmark(int surahNumber, int verseNumber) async {
    await databaseHelper.deleteBookmark(surahNumber, verseNumber);
  }

  @override
  Future<bool> toggleBookmark(BookmarkedAyah bookmark) async {
    final isCurrentlyBookmarked = await isBookmarked(
      bookmark.surahNumber,
      bookmark.verseNumber,
    );

    if (isCurrentlyBookmarked) {
      await removeBookmark(bookmark.surahNumber, bookmark.verseNumber);
      return false; // Now unbookmarked
    } else {
      await addBookmark(bookmark);
      return true; // Now bookmarked
    }
  }

  @override
  Future<bool> isBookmarked(int surahNumber, int verseNumber) async {
    return await databaseHelper.isBookmarked(surahNumber, verseNumber);
  }

  @override
  Future<List<BookmarkedAyah>> getAllBookmarks() async {
    return await databaseHelper.getAllBookmarks();
  }

  @override
  Future<void> clearAllBookmarks() async {
    await databaseHelper.clearAllBookmarks();
  }

  @override
  Future<int> getBookmarkCount() async {
    return await databaseHelper.getBookmarkCount();
  }

  @override
  Future<List<BookmarkedAyah>> getBookmarksForSurah(int surahNumber) async {
    final allBookmarks = await getAllBookmarks();
    return allBookmarks
        .where((bookmark) => bookmark.surahNumber == surahNumber)
        .toList();
  }
}
