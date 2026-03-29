import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart';
import '../models/downloaded_surah.dart';
import '../../domain/entities/bookmark.dart';
import '../../domain/entities/queued_audio_download_task.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  static const String _downloadedSurahsTable = 'downloaded_surahs';
  static const String _bookmarksTable = 'bookmarks';
  static const String _downloadQueueTable = 'download_queue';

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
        version: 3,
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
    await _createDownloadedSurahsTable(db);
    await _createBookmarksTable(db);
    await _createDownloadQueueTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createBookmarksTable(db);
    }
    if (oldVersion < 3) {
      await _createDownloadQueueTable(db);
    }
  }

  Future<void> _createDownloadedSurahsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_downloadedSurahsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        reciter_id TEXT NOT NULL,
        surah_number INTEGER NOT NULL,
        file_path TEXT NOT NULL,
        is_complete INTEGER NOT NULL DEFAULT 0,
        downloaded_at INTEGER NOT NULL,
        UNIQUE(reciter_id, surah_number)
      )
    ''');
  }

  Future<void> _createBookmarksTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_bookmarksTable (
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

  Future<void> _createDownloadQueueTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_downloadQueueTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        reciter_id TEXT NOT NULL,
        surah_number INTEGER NOT NULL,
        status TEXT NOT NULL,
        progress REAL NOT NULL DEFAULT 0,
        attempt_count INTEGER NOT NULL DEFAULT 0,
        error TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        UNIQUE(reciter_id, surah_number)
      )
    ''');
  }

  // Insert downloaded surah
  Future<int> insertDownloadedSurah(DownloadedSurah surah) async {
    final db = await database;
    return await db.insert(_downloadedSurahsTable, {
      ...surah.toMap(),
      'downloaded_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Check if surah is downloaded
  Future<bool> isSurahDownloaded(String reciterId, int surahNumber) async {
    final db = await database;
    final result = await db.query(
      _downloadedSurahsTable,
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
      _downloadedSurahsTable,
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
      _downloadedSurahsTable,
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
      _downloadedSurahsTable,
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
      _downloadedSurahsTable,
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
      FROM $_downloadedSurahsTable 
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

  Future<void> enqueueDownloadTask(String reciterId, int surahNumber) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final existing = await db.query(
      _downloadQueueTable,
      where: 'reciter_id = ? AND surah_number = ?',
      whereArgs: [reciterId, surahNumber],
      limit: 1,
    );

    if (existing.isEmpty) {
      await db.insert(_downloadQueueTable, {
        'reciter_id': reciterId,
        'surah_number': surahNumber,
        'status': QueuedAudioDownloadStatus.queued.dbValue,
        'progress': 0.0,
        'attempt_count': 0,
        'error': null,
        'created_at': now,
        'updated_at': now,
      });
      return;
    }

    final currentStatus = QueuedAudioDownloadStatusX.fromDb(
      '${existing.first['status'] ?? 'queued'}',
    );
    if (currentStatus == QueuedAudioDownloadStatus.queued ||
        currentStatus == QueuedAudioDownloadStatus.downloading) {
      return;
    }

    await db.update(
      _downloadQueueTable,
      {
        'status': QueuedAudioDownloadStatus.queued.dbValue,
        'progress': 0.0,
        'attempt_count': 0,
        'error': null,
        'updated_at': now,
      },
      where: 'reciter_id = ? AND surah_number = ?',
      whereArgs: [reciterId, surahNumber],
    );
  }

  Future<QueuedAudioDownloadTask?> getDownloadQueueTask(
    String reciterId,
    int surahNumber,
  ) async {
    final db = await database;
    final result = await db.query(
      _downloadQueueTable,
      where: 'reciter_id = ? AND surah_number = ?',
      whereArgs: [reciterId, surahNumber],
      limit: 1,
    );
    if (result.isEmpty) {
      return null;
    }
    return _mapQueueTask(result.first);
  }

  Future<List<QueuedAudioDownloadTask>> getDownloadQueueTasks({
    String? reciterId,
  }) async {
    final db = await database;
    final result = await db.query(
      _downloadQueueTable,
      where: reciterId == null ? null : 'reciter_id = ?',
      whereArgs: reciterId == null ? null : [reciterId],
      orderBy:
          "CASE status WHEN 'downloading' THEN 0 WHEN 'queued' THEN 1 ELSE 2 END, created_at ASC",
    );
    return result.map(_mapQueueTask).toList();
  }

  Future<QueuedAudioDownloadTask?> getNextQueuedDownloadTask() async {
    final db = await database;
    final result = await db.query(
      _downloadQueueTable,
      where: 'status = ?',
      whereArgs: [QueuedAudioDownloadStatus.queued.dbValue],
      orderBy: 'created_at ASC',
      limit: 1,
    );
    if (result.isEmpty) {
      return null;
    }
    return _mapQueueTask(result.first);
  }

  Future<void> markQueueTaskAsQueued(
    String reciterId,
    int surahNumber, {
    double progress = 0,
    int? attemptCount,
    String? error,
    bool clearError = true,
  }) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final values = <String, Object?>{
      'status': QueuedAudioDownloadStatus.queued.dbValue,
      'progress': progress.clamp(0.0, 1.0),
      'updated_at': now,
    };
    if (attemptCount != null) {
      values['attempt_count'] = attemptCount;
    }
    if (clearError) {
      values['error'] = null;
    } else if (error != null) {
      values['error'] = error;
    }

    await db.update(
      _downloadQueueTable,
      values,
      where: 'reciter_id = ? AND surah_number = ?',
      whereArgs: [reciterId, surahNumber],
    );
  }

  Future<void> markQueueTaskAsDownloading(
    String reciterId,
    int surahNumber, {
    double progress = 0,
  }) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      _downloadQueueTable,
      {
        'status': QueuedAudioDownloadStatus.downloading.dbValue,
        'progress': progress.clamp(0.0, 1.0),
        'updated_at': now,
      },
      where: 'reciter_id = ? AND surah_number = ?',
      whereArgs: [reciterId, surahNumber],
    );
  }

  Future<void> updateQueueTaskProgress(
    String reciterId,
    int surahNumber,
    double progress,
  ) async {
    final db = await database;
    await db.update(
      _downloadQueueTable,
      {
        'progress': progress.clamp(0.0, 1.0),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'reciter_id = ? AND surah_number = ?',
      whereArgs: [reciterId, surahNumber],
    );
  }

  Future<void> markQueueTaskAsFailed(
    String reciterId,
    int surahNumber, {
    required int attemptCount,
    required String? error,
  }) async {
    final db = await database;
    await db.update(
      _downloadQueueTable,
      {
        'status': QueuedAudioDownloadStatus.failed.dbValue,
        'attempt_count': attemptCount,
        'progress': 0.0,
        'error': error,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'reciter_id = ? AND surah_number = ?',
      whereArgs: [reciterId, surahNumber],
    );
  }

  Future<void> removeQueueTask(String reciterId, int surahNumber) async {
    final db = await database;
    await db.delete(
      _downloadQueueTable,
      where: 'reciter_id = ? AND surah_number = ?',
      whereArgs: [reciterId, surahNumber],
    );
  }

  Future<void> clearFailedQueueTasks({String? reciterId}) async {
    final db = await database;
    await db.delete(
      _downloadQueueTable,
      where: reciterId == null ? 'status = ?' : 'status = ? AND reciter_id = ?',
      whereArgs: reciterId == null
          ? [QueuedAudioDownloadStatus.failed.dbValue]
          : [QueuedAudioDownloadStatus.failed.dbValue, reciterId],
    );
  }

  Future<void> requeueInterruptedQueueTasks() async {
    final db = await database;
    await db.update(
      _downloadQueueTable,
      {
        'status': QueuedAudioDownloadStatus.queued.dbValue,
        'progress': 0.0,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'status = ?',
      whereArgs: [QueuedAudioDownloadStatus.downloading.dbValue],
    );
  }

  QueuedAudioDownloadTask _mapQueueTask(Map<String, Object?> row) {
    final createdAtEpoch = row['created_at'];
    final updatedAtEpoch = row['updated_at'];
    final progressRaw = row['progress'];
    final attemptRaw = row['attempt_count'];

    return QueuedAudioDownloadTask(
      reciterId: '${row['reciter_id'] ?? ''}',
      surahNumber: row['surah_number'] as int? ?? 0,
      status: QueuedAudioDownloadStatusX.fromDb('${row['status'] ?? 'queued'}'),
      progress: progressRaw is num ? progressRaw.toDouble() : 0.0,
      attemptCount: attemptRaw is int
          ? attemptRaw
          : int.tryParse('$attemptRaw') ?? 0,
      error: row['error'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        createdAtEpoch is int
            ? createdAtEpoch
            : int.tryParse('$createdAtEpoch') ?? 0,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        updatedAtEpoch is int
            ? updatedAtEpoch
            : int.tryParse('$updatedAtEpoch') ?? 0,
      ),
    );
  }

  // Bookmark operations
  Future<int> insertBookmark(BookmarkedAyah bookmark) async {
    final db = await database;
    return await db.insert(_bookmarksTable, {
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
      _bookmarksTable,
      where: 'surah_number = ? AND verse_number = ?',
      whereArgs: [surahNumber, verseNumber],
    );
    return result.isNotEmpty;
  }

  Future<int> deleteBookmark(int surahNumber, int verseNumber) async {
    final db = await database;
    return await db.delete(
      _bookmarksTable,
      where: 'surah_number = ? AND verse_number = ?',
      whereArgs: [surahNumber, verseNumber],
    );
  }

  Future<List<BookmarkedAyah>> getAllBookmarks() async {
    final db = await database;
    final result = await db.query(_bookmarksTable, orderBy: 'created_at DESC');

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
    return await db.delete(_bookmarksTable);
  }

  Future<int> getBookmarkCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_bookmarksTable',
    );
    return result.first['count'] as int;
  }
}
