import '../entities/queued_audio_download_task.dart';

abstract class DownloadQueueRepository {
  Future<void> enqueue(String reciterId, int surahNumber);

  Future<void> enqueueMany(String reciterId, List<int> surahNumbers);

  Future<QueuedAudioDownloadTask?> getTask(String reciterId, int surahNumber);

  Future<List<QueuedAudioDownloadTask>> getAllTasks();

  Future<List<QueuedAudioDownloadTask>> getTasksForReciter(String reciterId);

  Future<QueuedAudioDownloadTask?> getNextQueuedTask();

  Future<void> markAsQueued(
    String reciterId,
    int surahNumber, {
    double progress = 0,
    int? attemptCount,
    String? error,
    bool clearError = true,
  });

  Future<void> markAsDownloading(
    String reciterId,
    int surahNumber, {
    double progress = 0,
  });

  Future<void> updateProgress(
    String reciterId,
    int surahNumber,
    double progress,
  );

  Future<void> markAsFailed(
    String reciterId,
    int surahNumber, {
    required int attemptCount,
    required String error,
  });

  Future<void> removeTask(String reciterId, int surahNumber);

  Future<void> clearFailed({String? reciterId});

  Future<void> requeueInterruptedDownloads();
}
