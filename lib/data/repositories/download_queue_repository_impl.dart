import '../../domain/entities/queued_audio_download_task.dart';
import '../../domain/repositories/download_queue_repository.dart';
import '../datasources/database_helper.dart';

class DownloadQueueRepositoryImpl implements DownloadQueueRepository {
  final DatabaseHelper _databaseHelper;

  DownloadQueueRepositoryImpl(this._databaseHelper);

  @override
  Future<void> enqueue(String reciterId, int surahNumber) {
    return _databaseHelper.enqueueDownloadTask(reciterId, surahNumber);
  }

  @override
  Future<void> enqueueMany(String reciterId, List<int> surahNumbers) async {
    for (final surahNumber in surahNumbers) {
      await enqueue(reciterId, surahNumber);
    }
  }

  @override
  Future<List<QueuedAudioDownloadTask>> getAllTasks() {
    return _databaseHelper.getDownloadQueueTasks();
  }

  @override
  Future<QueuedAudioDownloadTask?> getNextQueuedTask() {
    return _databaseHelper.getNextQueuedDownloadTask();
  }

  @override
  Future<QueuedAudioDownloadTask?> getTask(String reciterId, int surahNumber) {
    return _databaseHelper.getDownloadQueueTask(reciterId, surahNumber);
  }

  @override
  Future<List<QueuedAudioDownloadTask>> getTasksForReciter(String reciterId) {
    return _databaseHelper.getDownloadQueueTasks(reciterId: reciterId);
  }

  @override
  Future<void> markAsDownloading(
    String reciterId,
    int surahNumber, {
    double progress = 0,
  }) {
    return _databaseHelper.markQueueTaskAsDownloading(
      reciterId,
      surahNumber,
      progress: progress,
    );
  }

  @override
  Future<void> markAsFailed(
    String reciterId,
    int surahNumber, {
    required int attemptCount,
    required String error,
  }) {
    return _databaseHelper.markQueueTaskAsFailed(
      reciterId,
      surahNumber,
      attemptCount: attemptCount,
      error: error,
    );
  }

  @override
  Future<void> markAsQueued(
    String reciterId,
    int surahNumber, {
    double progress = 0,
    int? attemptCount,
    String? error,
    bool clearError = true,
  }) {
    return _databaseHelper.markQueueTaskAsQueued(
      reciterId,
      surahNumber,
      progress: progress,
      attemptCount: attemptCount,
      error: error,
      clearError: clearError,
    );
  }

  @override
  Future<void> removeTask(String reciterId, int surahNumber) {
    return _databaseHelper.removeQueueTask(reciterId, surahNumber);
  }

  @override
  Future<void> updateProgress(
    String reciterId,
    int surahNumber,
    double progress,
  ) {
    return _databaseHelper.updateQueueTaskProgress(
      reciterId,
      surahNumber,
      progress,
    );
  }

  @override
  Future<void> clearFailed({String? reciterId}) {
    return _databaseHelper.clearFailedQueueTasks(reciterId: reciterId);
  }

  @override
  Future<void> requeueInterruptedDownloads() {
    return _databaseHelper.requeueInterruptedQueueTasks();
  }
}
