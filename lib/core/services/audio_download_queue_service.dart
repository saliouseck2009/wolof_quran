import 'dart:async';

import 'package:rxdart/rxdart.dart';

import '../../domain/entities/queued_audio_download_task.dart';
import '../../domain/repositories/audio_repository.dart';
import '../../domain/repositories/download_queue_repository.dart';
import '../../domain/repositories/download_repository.dart';

enum EnqueueAudioDownloadResult { enqueued, alreadyQueued, alreadyDownloaded }

class AudioDownloadQueueService {
  final DownloadQueueRepository _queueRepository;
  final AudioRepository _audioRepository;
  final DownloadRepository _downloadRepository;

  final BehaviorSubject<List<QueuedAudioDownloadTask>> _tasksSubject =
      BehaviorSubject<List<QueuedAudioDownloadTask>>.seeded(const []);
  final PublishSubject<QueuedAudioDownloadTask> _completedSubject =
      PublishSubject<QueuedAudioDownloadTask>();
  final PublishSubject<QueuedAudioDownloadTask> _failedSubject =
      PublishSubject<QueuedAudioDownloadTask>();

  final Map<String, double> _lastPersistedProgress = <String, double>{};
  final Map<String, DateTime> _lastPersistedAt = <String, DateTime>{};

  bool _initialized = false;
  bool _isProcessing = false;

  static const int _maxAutoAttempts = 2;

  AudioDownloadQueueService({
    required DownloadQueueRepository queueRepository,
    required AudioRepository audioRepository,
    required DownloadRepository downloadRepository,
  }) : _queueRepository = queueRepository,
       _audioRepository = audioRepository,
       _downloadRepository = downloadRepository;

  Stream<List<QueuedAudioDownloadTask>> get tasks => _tasksSubject.stream;
  Stream<QueuedAudioDownloadTask> get completedTasks =>
      _completedSubject.stream;
  Stream<QueuedAudioDownloadTask> get failedTasks => _failedSubject.stream;

  List<QueuedAudioDownloadTask> get currentTasks => _tasksSubject.value;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;
    await _queueRepository.requeueInterruptedDownloads();
    await _publishTasks();
    unawaited(_processQueue());
  }

  Future<EnqueueAudioDownloadResult> enqueue(
    String reciterId,
    int surahNumber,
  ) async {
    final isAlreadyDownloaded = await _downloadRepository.isSurahDownloaded(
      reciterId,
      surahNumber,
    );
    if (isAlreadyDownloaded) {
      return EnqueueAudioDownloadResult.alreadyDownloaded;
    }

    final existingTask = await _queueRepository.getTask(reciterId, surahNumber);
    if (existingTask != null &&
        (existingTask.isQueued || existingTask.isDownloading)) {
      return EnqueueAudioDownloadResult.alreadyQueued;
    }

    await _queueRepository.enqueue(reciterId, surahNumber);
    await _publishTasks();
    unawaited(_processQueue());
    return EnqueueAudioDownloadResult.enqueued;
  }

  Future<Map<int, EnqueueAudioDownloadResult>> enqueueMany(
    String reciterId,
    List<int> surahNumbers,
  ) async {
    final results = <int, EnqueueAudioDownloadResult>{};
    for (final surahNumber in surahNumbers) {
      results[surahNumber] = await enqueue(reciterId, surahNumber);
    }
    return results;
  }

  Future<bool> retryFailed(String reciterId, int surahNumber) async {
    final task = await _queueRepository.getTask(reciterId, surahNumber);
    if (task == null || !task.isFailed) {
      return false;
    }
    await _queueRepository.markAsQueued(
      reciterId,
      surahNumber,
      progress: 0,
      attemptCount: 0,
      clearError: true,
    );
    await _publishTasks();
    unawaited(_processQueue());
    return true;
  }

  Future<void> clearFailed({String? reciterId}) async {
    await _queueRepository.clearFailed(reciterId: reciterId);
    await _publishTasks();
  }

  Future<bool> hasActiveOrQueuedForReciter(String reciterId) async {
    final tasks = await _queueRepository.getTasksForReciter(reciterId);
    return tasks.any((task) => task.isQueued || task.isDownloading);
  }

  Future<void> _processQueue() async {
    if (_isProcessing) {
      return;
    }
    _isProcessing = true;
    try {
      while (true) {
        final task = await _queueRepository.getNextQueuedTask();
        if (task == null) {
          break;
        }
        await _runTask(task);
      }
    } finally {
      _isProcessing = false;
    }

    final hasMore = await _queueRepository.getNextQueuedTask();
    if (hasMore != null && !_isProcessing) {
      unawaited(_processQueue());
    }
  }

  Future<void> _runTask(QueuedAudioDownloadTask task) async {
    await _queueRepository.markAsDownloading(
      task.reciterId,
      task.surahNumber,
      progress: 0,
    );
    await _publishTasks();

    try {
      await _downloadRepository.markSurahAsInProgress(
        task.reciterId,
        task.surahNumber,
        '',
      );
    } catch (_) {
      // Download queue should continue even if DB progress metadata fails.
    }

    final nextAttemptCount = task.attemptCount + 1;

    try {
      await _audioRepository.downloadSurahAudio(
        task.reciterId,
        task.surahNumber,
        onProgress: (progress) {
          _onProgress(task.reciterId, task.surahNumber, progress);
        },
      );

      final status = await _audioRepository.getSurahAudioStatus(
        task.reciterId,
        task.surahNumber,
      );
      final resolvedPath =
          (status.localPath != null && status.localPath!.isNotEmpty)
          ? status.localPath!
          : await _audioRepository.getSurahAudioPath(
              task.reciterId,
              task.surahNumber,
            );

      await _downloadRepository.markSurahAsDownloaded(
        task.reciterId,
        task.surahNumber,
        resolvedPath,
      );

      await _queueRepository.removeTask(task.reciterId, task.surahNumber);
      _lastPersistedProgress.remove(task.key);
      _lastPersistedAt.remove(task.key);
      _completedSubject.add(
        task.copyWith(
          status: QueuedAudioDownloadStatus.downloading,
          progress: 1.0,
          attemptCount: nextAttemptCount,
          updatedAt: DateTime.now(),
        ),
      );
      await _publishTasks();
    } catch (error) {
      try {
        await _downloadRepository.removeSurahDownload(
          task.reciterId,
          task.surahNumber,
        );
      } catch (_) {
        // Keep queue resilient even if cleanup fails.
      }

      final errorMessage = _normalizeError(error);
      if (nextAttemptCount < _maxAutoAttempts) {
        await _queueRepository.markAsQueued(
          task.reciterId,
          task.surahNumber,
          progress: 0,
          attemptCount: nextAttemptCount,
          error: errorMessage,
          clearError: false,
        );
      } else {
        await _queueRepository.markAsFailed(
          task.reciterId,
          task.surahNumber,
          attemptCount: nextAttemptCount,
          error: errorMessage,
        );
        _failedSubject.add(
          task.copyWith(
            status: QueuedAudioDownloadStatus.failed,
            progress: 0,
            attemptCount: nextAttemptCount,
            error: errorMessage,
            updatedAt: DateTime.now(),
          ),
        );
      }
      await _publishTasks();
    }
  }

  void _onProgress(String reciterId, int surahNumber, double progress) {
    final normalized = progress.clamp(0.0, 1.0);
    final key = '${reciterId}_$surahNumber';
    final now = DateTime.now();
    final lastProgress = _lastPersistedProgress[key] ?? -1;
    final lastTime = _lastPersistedAt[key];
    final shouldPersist =
        normalized >= 1.0 ||
        (normalized - lastProgress).abs() >= 0.02 ||
        (lastTime == null ||
            now.difference(lastTime) >= const Duration(milliseconds: 350));

    if (!shouldPersist) {
      return;
    }

    _lastPersistedProgress[key] = normalized;
    _lastPersistedAt[key] = now;

    unawaited(
      _queueRepository
          .updateProgress(reciterId, surahNumber, normalized)
          .then((_) => _publishTasks()),
    );
  }

  Future<void> _publishTasks() async {
    final tasks = await _queueRepository.getAllTasks();
    _tasksSubject.add(tasks);
  }

  String _normalizeError(Object error) {
    final raw = '$error'.trim();
    if (raw.isEmpty) {
      return 'Download failed';
    }
    if (raw.length <= 280) {
      return raw;
    }
    return raw.substring(0, 280);
  }

  Future<void> dispose() async {
    await _tasksSubject.close();
    await _completedSubject.close();
    await _failedSubject.close();
  }
}
