import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart';
import '../models/downloaded_surah.dart';
import '../../domain/entities/bookmark.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'quran_downloads.db');

      return await openDatabase(
        path,
        version: 2,
        onCreate: _createTables,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      // If sqflite is not available, throw a more descriptive error
      if (e is MissingPluginException) {
        throw Exception(
          'Database plugin not available. Please restart the app after installing dependencies.',
        );
      }
      rethrow;
    }
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE downloaded_surahs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        reciter_id TEXT NOT NULL,
        surah_number INTEGER NOT NULL,
        file_path TEXT NOT NULL,
        is_complete INTEGER NOT NULL DEFAULT 0,
        downloaded_at INTEGER NOT NULL,
        UNIQUE(reciter_id, surah_number)
      )
    ''');

    await db.execute('''
      CREATE TABLE bookmarks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        surah_number INTEGER NOT NULL,
        verse_number INTEGER NOT NULL,
        surah_name TEXT NOT NULL,
        arabic_text TEXT NOT NULL,
        translation TEXT NOT NULL,
        translation_source TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        UNIQUE(surah_number, verse_number)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE bookmarks (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          surah_number INTEGER NOT NULL,
          verse_number INTEGER NOT NULL,
          surah_name TEXT NOT NULL,
          arabic_text TEXT NOT NULL,
          translation TEXT NOT NULL,
          translation_source TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          UNIQUE(surah_number, verse_number)
        )
      ''');
    }
  }

  // Insert downloaded surah
  Future<int> insertDownloadedSurah(DownloadedSurah surah) async {
    final db = await database;
    return await db.insert('downloaded_surahs', {
      ...surah.toMap(),
      'downloaded_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Check if surah is downloaded
  Future<bool> isSurahDownloaded(String reciterId, int surahNumber) async {
    final db = await database;
    final result = await db.query(
      'downloaded_surahs',
      where: 'reciter_id = ? AND surah_number = ? AND is_complete = 1',
      whereArgs: [reciterId, surahNumber],
    );
    return result.isNotEmpty;
  }

  // Get downloaded surah
  Future<DownloadedSurah?> getDownloadedSurah(
    String reciterId,
    int surahNumber,
  ) async {
    final db = await database;
    final result = await db.query(
      'downloaded_surahs',
      where: 'reciter_id = ? AND surah_number = ?',
      whereArgs: [reciterId, surahNumber],
    );

    if (result.isNotEmpty) {
      return DownloadedSurah.fromMap(result.first);
    }
    return null;
  }

  // Get all downloaded surahs for a reciter
  Future<List<DownloadedSurah>> getDownloadedSurahs(String reciterId) async {
    final db = await database;
    final result = await db.query(
      'downloaded_surahs',
      where: 'reciter_id = ? AND is_complete = 1',
      whereArgs: [reciterId],
      orderBy: 'surah_number ASC',
    );

    return result.map((map) => DownloadedSurah.fromMap(map)).toList();
  }

  // Delete downloaded surah
  Future<int> deleteDownloadedSurah(String reciterId, int surahNumber) async {
    final db = await database;
    return await db.delete(
      'downloaded_surahs',
      where: 'reciter_id = ? AND surah_number = ?',
      whereArgs: [reciterId, surahNumber],
    );
  }

  // Update download completion status
  Future<int> updateDownloadStatus(
    String reciterId,
    int surahNumber,
    bool isComplete,
  ) async {
    final db = await database;
    return await db.update(
      'downloaded_surahs',
      {'is_complete': isComplete ? 1 : 0},
      where: 'reciter_id = ? AND surah_number = ?',
      whereArgs: [reciterId, surahNumber],
    );
  }

  // Get download statistics
  Future<Map<String, int>> getDownloadStats(String reciterId) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT 
        COUNT(*) as total_downloads,
        COUNT(CASE WHEN is_complete = 1 THEN 1 END) as completed_downloads
      FROM downloaded_surahs 
      WHERE reciter_id = ?
    ''',
      [reciterId],
    );

    if (result.isNotEmpty) {
      return {
        'total': result.first['total_downloads'] as int,
        'completed': result.first['completed_downloads'] as int,
      };
    }
    return {'total': 0, 'completed': 0};
  }

  // Bookmark operations
  Future<int> insertBookmark(BookmarkedAyah bookmark) async {
    final db = await database;
    return await db.insert('bookmarks', {
      'surah_number': bookmark.surahNumber,
      'verse_number': bookmark.verseNumber,
      'surah_name': bookmark.surahName,
      'arabic_text': bookmark.arabicText,
      'translation': bookmark.translation,
      'translation_source': bookmark.translationSource,
      'created_at': bookmark.createdAt.millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<bool> isBookmarked(int surahNumber, int verseNumber) async {
    final db = await database;
    final result = await db.query(
      'bookmarks',
      where: 'surah_number = ? AND verse_number = ?',
      whereArgs: [surahNumber, verseNumber],
    );
    return result.isNotEmpty;
  }

  Future<int> deleteBookmark(int surahNumber, int verseNumber) async {
    final db = await database;
    return await db.delete(
      'bookmarks',
      where: 'surah_number = ? AND verse_number = ?',
      whereArgs: [surahNumber, verseNumber],
    );
  }

  Future<List<BookmarkedAyah>> getAllBookmarks() async {
    final db = await database;
    final result = await db.query('bookmarks', orderBy: 'created_at DESC');

    return result
        .map(
          (map) => BookmarkedAyah(
            surahNumber: map['surah_number'] as int,
            verseNumber: map['verse_number'] as int,
            surahName: map['surah_name'] as String,
            arabicText: map['arabic_text'] as String,
            translation: map['translation'] as String,
            translationSource: map['translation_source'] as String,
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              map['created_at'] as int,
            ),
          ),
        )
        .toList();
  }

  Future<int> clearAllBookmarks() async {
    final db = await database;
    return await db.delete('bookmarks');
  }

  Future<int> getBookmarkCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM bookmarks');
    return result.first['count'] as int;
  }
}
