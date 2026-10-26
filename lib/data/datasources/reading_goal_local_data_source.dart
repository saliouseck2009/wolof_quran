import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../core/reading/local_date.dart';
import '../../domain/entities/reading_goal.dart';
import '../../domain/entities/reading_validation.dart';
import 'database_helper.dart';

/// SQLite storage of reading goals, their validated pages and journal.
class ReadingGoalLocalDataSource {
  final DatabaseHelper _databaseHelper;

  ReadingGoalLocalDataSource(this._databaseHelper);

  Future<Database> get _db => _databaseHelper.database;

  Future<List<ReadingGoal>> getGoals() async {
    final db = await _db;
    final rows = await db.query(
      DatabaseHelper.readingGoalsTable,
      orderBy: 'created_at DESC',
    );
    return rows.map(goalFromMap).toList();
  }

  Future<ReadingGoal?> getGoal(String id) async {
    final db = await _db;
    final rows = await db.query(
      DatabaseHelper.readingGoalsTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : goalFromMap(rows.first);
  }

  Future<void> saveGoal(ReadingGoal goal) async {
    final db = await _db;
    await db.insert(
      DatabaseHelper.readingGoalsTable,
      goalToMap(goal),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteGoal(String id) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete(
        DatabaseHelper.readingGoalPagesTable,
        where: 'goal_id = ?',
        whereArgs: [id],
      );
      await txn.delete(
        DatabaseHelper.readingValidationsTable,
        where: 'goal_id = ?',
        whereArgs: [id],
      );
      await txn.delete(
        DatabaseHelper.readingSessionsTable,
        where: 'goal_id = ?',
        whereArgs: [id],
      );
      await txn.delete(
        DatabaseHelper.readingGoalsTable,
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  Future<Map<int, DateTime>> getValidatedPages(String goalId) async {
    final db = await _db;
    final rows = await db.query(
      DatabaseHelper.readingGoalPagesTable,
      columns: ['page', 'validated_at'],
      where: 'goal_id = ?',
      whereArgs: [goalId],
    );
    return {
      for (final row in rows)
        row['page'] as int: DateTime.fromMillisecondsSinceEpoch(
          row['validated_at'] as int,
        ),
    };
  }

  Future<Map<String, Map<int, DateTime>>> getAllValidatedPages() async {
    final db = await _db;
    final rows = await db.query(
      DatabaseHelper.readingGoalPagesTable,
      columns: ['goal_id', 'page', 'validated_at'],
    );
    final result = <String, Map<int, DateTime>>{};
    for (final row in rows) {
      final pages = result.putIfAbsent(row['goal_id'] as String, () => {});
      pages[row['page'] as int] = DateTime.fromMillisecondsSinceEpoch(
        row['validated_at'] as int,
      );
    }
    return result;
  }

  /// Inserts the pages of [validation] that are not validated yet and, when
  /// at least one was added, the journal entry listing exactly those pages.
  /// Returns the stored entry, or `null` when every page was already read.
  Future<ReadingValidation?> insertValidation(
    ReadingValidation validation,
  ) async {
    final db = await _db;
    return db.transaction((txn) async {
      final existing = await _existingPages(
        txn,
        validation.goalId,
        validation.pages,
      );
      final added = validation.pages
          .where((page) => !existing.contains(page))
          .toList();
      if (added.isEmpty) {
        return null;
      }
      final batch = txn.batch();
      for (final page in added) {
        batch.insert(DatabaseHelper.readingGoalPagesTable, {
          'goal_id': validation.goalId,
          'page': page,
          'validated_at': validation.createdAt.millisecondsSinceEpoch,
          'validation_id': validation.id,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      await batch.commit(noResult: true);

      final stored = ReadingValidation(
        id: validation.id,
        goalId: validation.goalId,
        createdAt: validation.createdAt,
        source: validation.source,
        action: validation.action,
        fromPage: validation.fromPage,
        toPage: validation.toPage,
        pages: added,
      );
      await txn.insert(
        DatabaseHelper.readingValidationsTable,
        validationToMap(stored),
      );
      return stored;
    });
  }

  /// Removes the validated pages of [validation] (an unmark entry) and
  /// journals the pages that were actually removed.
  Future<ReadingValidation?> insertUnmark(ReadingValidation validation) async {
    final db = await _db;
    return db.transaction((txn) async {
      final existing = await _existingPages(
        txn,
        validation.goalId,
        validation.pages,
      );
      final removed = validation.pages.where(existing.contains).toList();
      if (removed.isEmpty) {
        return null;
      }
      await txn.delete(
        DatabaseHelper.readingGoalPagesTable,
        where: 'goal_id = ? AND page IN (${_placeholders(removed.length)})',
        whereArgs: [validation.goalId, ...removed],
      );
      final stored = ReadingValidation(
        id: validation.id,
        goalId: validation.goalId,
        createdAt: validation.createdAt,
        source: validation.source,
        action: ReadingValidationAction.unmark,
        fromPage: validation.fromPage,
        toPage: validation.toPage,
        pages: removed,
      );
      await txn.insert(
        DatabaseHelper.readingValidationsTable,
        validationToMap(stored),
      );
      return stored;
    });
  }

  Future<List<ReadingValidation>> getValidations(String goalId) async {
    final db = await _db;
    final rows = await db.query(
      DatabaseHelper.readingValidationsTable,
      where: 'goal_id = ?',
      whereArgs: [goalId],
      orderBy: 'created_at DESC',
    );
    return rows.map(validationFromMap).toList();
  }

  Future<ReadingValidation?> getValidation(String id) async {
    final db = await _db;
    final rows = await db.query(
      DatabaseHelper.readingValidationsTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : validationFromMap(rows.first);
  }

  /// Reverts [validation]: an unmark entry puts its pages back, any other
  /// entry removes the pages it had added. The entry itself is deleted.
  Future<void> undoValidation(ReadingValidation validation) async {
    final db = await _db;
    await db.transaction((txn) async {
      if (validation.isUnmark) {
        final batch = txn.batch();
        for (final page in validation.pages) {
          batch.insert(DatabaseHelper.readingGoalPagesTable, {
            'goal_id': validation.goalId,
            'page': page,
            'validated_at': validation.createdAt.millisecondsSinceEpoch,
            'validation_id': validation.id,
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
        await batch.commit(noResult: true);
      } else if (validation.pages.isNotEmpty) {
        await txn.delete(
          DatabaseHelper.readingGoalPagesTable,
          where:
              'goal_id = ? AND validation_id = ? '
              'AND page IN (${_placeholders(validation.pages.length)})',
          whereArgs: [validation.goalId, validation.id, ...validation.pages],
        );
      }
      await txn.delete(
        DatabaseHelper.readingValidationsTable,
        where: 'id = ?',
        whereArgs: [validation.id],
      );
    });
  }

  Future<Set<int>> _existingPages(
    DatabaseExecutor executor,
    String goalId,
    List<int> pages,
  ) async {
    if (pages.isEmpty) {
      return const {};
    }
    final rows = await executor.query(
      DatabaseHelper.readingGoalPagesTable,
      columns: ['page'],
      where: 'goal_id = ? AND page IN (${_placeholders(pages.length)})',
      whereArgs: [goalId, ...pages],
    );
    return rows.map((row) => row['page'] as int).toSet();
  }

  static String _placeholders(int count) => List.filled(count, '?').join(', ');

  static Map<String, Object?> goalToMap(ReadingGoal goal) {
    return {
      'id': goal.id,
      'name': goal.name,
      'status': goal.status.dbValue,
      'start_page': goal.startPage,
      'total_pages': goal.totalPages,
      'mushaf_edition': goal.mushafEdition,
      'start_date': goal.startDate.toIso(),
      'end_date': goal.endDate.toIso(),
      'paused_at': goal.pausedAt?.toIso(),
      'last_viewed_page': goal.lastViewedPage,
      'reminder_enabled': goal.reminder.enabled ? 1 : 0,
      'reminder_time': goal.reminder.timeLabel,
      'created_at': goal.createdAt.millisecondsSinceEpoch,
      'updated_at': goal.updatedAt.millisecondsSinceEpoch,
      'completed_at': goal.completedAt?.millisecondsSinceEpoch,
    };
  }

  static ReadingGoal goalFromMap(Map<String, Object?> map) {
    final completedAt = map['completed_at'] as int?;
    return ReadingGoal(
      id: map['id'] as String,
      name: map['name'] as String,
      status: ReadingGoalStatus.fromDb(map['status'] as String?),
      startPage: map['start_page'] as int,
      totalPages: map['total_pages'] as int,
      mushafEdition:
          map['mushaf_edition'] as String? ?? ReadingGoal.defaultMushafEdition,
      startDate: LocalDate.parse(map['start_date'] as String),
      endDate: LocalDate.parse(map['end_date'] as String),
      pausedAt: LocalDate.tryParse(map['paused_at'] as String?),
      lastViewedPage: map['last_viewed_page'] as int?,
      reminder: ReminderSettings.fromDb(
        enabled: (map['reminder_enabled'] as int? ?? 0) == 1,
        time: map['reminder_time'] as String?,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      completedAt: completedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(completedAt),
    );
  }

  static Map<String, Object?> validationToMap(ReadingValidation validation) {
    return {
      'id': validation.id,
      'goal_id': validation.goalId,
      'created_at': validation.createdAt.millisecondsSinceEpoch,
      'source': validation.source.dbValue,
      'action': validation.action.dbValue,
      'from_page': validation.fromPage,
      'to_page': validation.toPage,
      'pages_json': jsonEncode(validation.pages),
    };
  }

  static ReadingValidation validationFromMap(Map<String, Object?> map) {
    final rawPages = jsonDecode(map['pages_json'] as String? ?? '[]');
    return ReadingValidation(
      id: map['id'] as String,
      goalId: map['goal_id'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      source: ReadingValidationSource.fromDb(map['source'] as String?),
      action: ReadingValidationAction.fromDb(map['action'] as String?),
      fromPage: map['from_page'] as int?,
      toPage: map['to_page'] as int?,
      pages: rawPages is List ? rawPages.whereType<int>().toList() : const [],
    );
  }
}
