import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wolof_quran/core/services/audio_download_queue_service.dart';
import 'package:wolof_quran/data/models/downloaded_surah.dart';
import 'package:wolof_quran/domain/entities/ayah_audio.dart';
import 'package:wolof_quran/domain/entities/queued_audio_download_task.dart';
import 'package:wolof_quran/domain/entities/surah_audio_status.dart';
import 'package:wolof_quran/domain/repositories/audio_repository.dart';
import 'package:wolof_quran/domain/repositories/download_queue_repository.dart';
import 'package:wolof_quran/domain/repositories/download_repository.dart';

class _InMemoryDownloadQueueRepository implements DownloadQueueRepository {
  final Map<String, QueuedAudioDownloadTask> _storage =
      <String, QueuedAudioDownloadTask>{};
  int _sequence = 0;

  String _key(String reciterId, int surahNumber) => '${reciterId}_$surahNumber';

  DateTime _nextTime() => DateTime.fromMillisecondsSinceEpoch(++_sequence);

  @override
  Future<void> enqueue(String reciterId, int surahNumber) async {
    final key = _key(reciterId, surahNumber);
    final now = _nextTime();
    final existing = _storage[key];
    if (existing == null) {
      _storage[key] = QueuedAudioDownloadTask(
        reciterId: reciterId,
        surahNumber: surahNumber,
        status: QueuedAudioDownloadStatus.queued,
        progress: 0,
        attemptCount: 0,
        error: null,
        createdAt: now,
        updatedAt: now,
      );
      return;
    }

    if (existing.isQueued || existing.isDownloading) {
      return;
    }

    _storage[key] = existing.copyWith(
      status: QueuedAudioDownloadStatus.queued,
      progress: 0,
      attemptCount: 0,
      clearError: true,
      updatedAt: now,
    );
  }

  @override
  Future<void> enqueueMany(String reciterId, List<int> surahNumbers) async {
    for (final surahNumber in surahNumbers) {
      await enqueue(reciterId, surahNumber);
    }
  }

  @override
  Future<QueuedAudioDownloadTask?> getTask(
    String reciterId,
    int surahNumber,
  ) async {
    return _storage[_key(reciterId, surahNumber)];
  }

  @override
  Future<List<QueuedAudioDownloadTask>> getAllTasks() async {
    final tasks = _storage.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return tasks;
  }

  @override
  Future<List<QueuedAudioDownloadTask>> getTasksForReciter(
    String reciterId,
  ) async {
    final tasks =
        _storage.values.where((task) => task.reciterId == reciterId).toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return tasks;
  }

  @override
  Future<QueuedAudioDownloadTask?> getNextQueuedTask() async {
    final queued = _storage.values.where((task) => task.isQueued).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return queued.isEmpty ? null : queued.first;
  }

  @override
  Future<void> markAsQueued(
    String reciterId,
    int surahNumber, {
    double progress = 0,
    int? attemptCount,
    String? error,
    bool clearError = true,
  }) async {
    final existing = _storage[_key(reciterId, surahNumber)];
    if (existing == null) {
      return;
    }
    _storage[_key(reciterId, surahNumber)] = existing.copyWith(
      status: QueuedAudioDownloadStatus.queued,
      progress: progress.clamp(0.0, 1.0),
      attemptCount: attemptCount ?? existing.attemptCount,
      error: error,
      clearError: clearError,
      updatedAt: _nextTime(),
    );
  }

  @override
  Future<void> markAsDownloading(
    String reciterId,
    int surahNumber, {
    double progress = 0,
  }) async {
    final existing = _storage[_key(reciterId, surahNumber)];
    if (existing == null) {
      return;
    }
    _storage[_key(reciterId, surahNumber)] = existing.copyWith(
      status: QueuedAudioDownloadStatus.downloading,
      progress: progress.clamp(0.0, 1.0),
      updatedAt: _nextTime(),
    );
  }

  @override
  Future<void> updateProgress(
    String reciterId,
    int surahNumber,
    double progress,
  ) async {
    final existing = _storage[_key(reciterId, surahNumber)];
    if (existing == null) {
      return;
    }
    _storage[_key(reciterId, surahNumber)] = existing.copyWith(
      progress: progress.clamp(0.0, 1.0),
      updatedAt: _nextTime(),
    );
  }

  @override
  Future<void> markAsFailed(
    String reciterId,
    int surahNumber, {
    required int attemptCount,
    required String error,
  }) async {
    final existing = _storage[_key(reciterId, surahNumber)];
    if (existing == null) {
      return;
    }
    _storage[_key(reciterId, surahNumber)] = existing.copyWith(
      status: QueuedAudioDownloadStatus.failed,
      progress: 0,
      attemptCount: attemptCount,
      error: error,
      updatedAt: _nextTime(),
    );
  }

  @override
  Future<void> removeTask(String reciterId, int surahNumber) async {
    _storage.remove(_key(reciterId, surahNumber));
  }

  @override
  Future<void> clearFailed({String? reciterId}) async {
    final keysToDelete = _storage.entries
        .where(
          (entry) =>
              entry.value.isFailed &&
              (reciterId == null || entry.value.reciterId == reciterId),
        )
        .map((entry) => entry.key)
        .toList();
    for (final key in keysToDelete) {
      _storage.remove(key);
    }
  }

  @override
  Future<void> requeueInterruptedDownloads() async {
    for (final entry in _storage.entries.toList()) {
      if (!entry.value.isDownloading) {
        continue;
      }
      _storage[entry.key] = entry.value.copyWith(
        status: QueuedAudioDownloadStatus.queued,
        progress: 0,
        updatedAt: _nextTime(),
      );
    }
  }
}

class _FakeAudioRepository implements AudioRepository {
  final Map<int, int> failuresLeftBySurah;
  final List<int> downloadCalls = <int>[];
  final Duration perDownloadDelay;
  final Set<int> succeededSurahs = <int>{};

  _FakeAudioRepository({
    this.failuresLeftBySurah = const <int, int>{},
    this.perDownloadDelay = Duration.zero,
  });

  @override
  Future<void> downloadSurahAudio(
    String reciterId,
    int surahNumber, {
    Function(double p1)? onProgress,
  }) async {
    downloadCalls.add(surahNumber);
    onProgress?.call(0.25);
    if (perDownloadDelay > Duration.zero) {
      await Future<void>.delayed(perDownloadDelay);
    }
    final remaining = failuresLeftBySurah[surahNumber] ?? 0;
    if (remaining > 0) {
      failuresLeftBySurah[surahNumber] = remaining - 1;
      throw Exception('failure-$surahNumber');
    }
    onProgress?.call(1.0);
    succeededSurahs.add(surahNumber);
  }

  @override
  Future<SurahAudioStatus> getSurahAudioStatus(
    String reciterId,
    int surahNumber,
  ) async {
    return SurahAudioStatus(
      reciterId: reciterId,
      surahNumber: surahNumber,
      localPath: succeededSurahs.contains(surahNumber)
          ? '/tmp/$reciterId/$surahNumber'
          : null,
    );
  }

  @override
  Future<String> getSurahAudioPath(String reciterId, int surahNumber) async {
    return '/tmp/$reciterId/$surahNumber';
  }

  @override
  Future<void> deleteSurahAudio(String reciterId, int surahNumber) async {}

  @override
  Future<List<AyahAudio>> getAyahAudios(
    String reciterId,
    int surahNumber,
  ) async {
    return const <AyahAudio>[];
  }

  @override
  Future<List<int>> getDownloadedSurahs(String reciterId) async {
    return const <int>[];
  }

  @override
  Future<bool> isSurahAudioDownloaded(String reciterId, int surahNumber) async {
    return succeededSurahs.contains(surahNumber);
  }

  @override
  Future<void> warmUpAyahDurations(String reciterId, int surahNumber) async {}
}

class _FakeDownloadRepository implements DownloadRepository {
  final Set<String> _downloadedKeys = <String>{};
  final List<int> completedOrder = <int>[];
  final List<int> inProgressCalls = <int>[];
  final List<int> removedCalls = <int>[];

  String _key(String reciterId, int surahNumber) => '${reciterId}_$surahNumber';

  @override
  Future<bool> isSurahDownloaded(String reciterId, int surahNumber) async {
    return _downloadedKeys.contains(_key(reciterId, surahNumber));
  }

  @override
  Future<void> markSurahAsDownloaded(
    String reciterId,
    int surahNumber,
    String filePath,
  ) async {
    _downloadedKeys.add(_key(reciterId, surahNumber));
    completedOrder.add(surahNumber);
  }

  @override
  Future<void> markSurahAsInProgress(
    String reciterId,
    int surahNumber,
    String filePath,
  ) async {
    inProgressCalls.add(surahNumber);
  }

  @override
  Future<void> removeSurahDownload(String reciterId, int surahNumber) async {
    _downloadedKeys.remove(_key(reciterId, surahNumber));
    removedCalls.add(surahNumber);
  }

  @override
  Future<DownloadedSurah?> getDownloadedSurah(
    String reciterId,
    int surahNumber,
  ) async {
    if (!await isSurahDownloaded(reciterId, surahNumber)) {
      return null;
    }
    return DownloadedSurah(
      reciterId: reciterId,
      surahNumber: surahNumber,
      filePath: '/tmp/$reciterId/$surahNumber',
      isComplete: true,
    );
  }

  @override
  Future<List<DownloadedSurah>> getDownloadedSurahs(String reciterId) async {
    return _downloadedKeys.where((key) => key.startsWith('${reciterId}_')).map((
      key,
    ) {
      final surah = int.parse(key.split('_').last);
      return DownloadedSurah(
        reciterId: reciterId,
        surahNumber: surah,
        filePath: '/tmp/$reciterId/$surah',
        isComplete: true,
      );
    }).toList();
  }

  @override
  Future<Map<String, int>> getDownloadStats(String reciterId) async {
    final downloaded = await getDownloadedSurahs(reciterId);
    return <String, int>{
      'total': downloaded.length,
      'completed': downloaded.length,
    };
  }
}

Future<void> _waitUntil(
  FutureOr<bool> Function() predicate, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (await predicate()) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  fail('Timed out while waiting for condition.');
}

void main() {
  group('AudioDownloadQueueService', () {
    test('processes tasks in strict FIFO order', () async {
      final queueRepository = _InMemoryDownloadQueueRepository();
      final audioRepository = _FakeAudioRepository(
        perDownloadDelay: const Duration(milliseconds: 15),
      );
      final downloadRepository = _FakeDownloadRepository();

      final service = AudioDownloadQueueService(
        queueRepository: queueRepository,
        audioRepository: audioRepository,
        downloadRepository: downloadRepository,
      );
      addTearDown(service.dispose);

      await service.initialize();
      await service.enqueue('imamsarr', 1);
      await service.enqueue('imamsarr', 2);
      await service.enqueue('imamsarr', 3);

      await _waitUntil(
        () async => downloadRepository.completedOrder.length == 3,
      );

      expect(audioRepository.downloadCalls, [1, 2, 3]);
      expect(downloadRepository.completedOrder, [1, 2, 3]);
      expect(await queueRepository.getAllTasks(), isEmpty);
    });

    test(
      'deduplicates enqueue when task is already queued/downloading',
      () async {
        final queueRepository = _InMemoryDownloadQueueRepository();
        final audioRepository = _FakeAudioRepository(
          perDownloadDelay: const Duration(milliseconds: 60),
        );
        final downloadRepository = _FakeDownloadRepository();

        final service = AudioDownloadQueueService(
          queueRepository: queueRepository,
          audioRepository: audioRepository,
          downloadRepository: downloadRepository,
        );
        addTearDown(service.dispose);

        await service.initialize();
        final first = await service.enqueue('imamsarr', 1);
        final second = await service.enqueue('imamsarr', 1);

        expect(first, EnqueueAudioDownloadResult.enqueued);
        expect(second, EnqueueAudioDownloadResult.alreadyQueued);

        await _waitUntil(
          () async => downloadRepository.completedOrder.length == 1,
        );
        expect(
          audioRepository.downloadCalls.where((surah) => surah == 1),
          hasLength(1),
        );
      },
    );

    test(
      'retries failed task twice then marks failed and proceeds to next',
      () async {
        final queueRepository = _InMemoryDownloadQueueRepository();
        final audioRepository = _FakeAudioRepository(
          failuresLeftBySurah: <int, int>{1: 10},
        );
        final downloadRepository = _FakeDownloadRepository();

        final service = AudioDownloadQueueService(
          queueRepository: queueRepository,
          audioRepository: audioRepository,
          downloadRepository: downloadRepository,
        );
        addTearDown(service.dispose);

        await service.initialize();
        await service.enqueue('imamsarr', 1);
        await service.enqueue('imamsarr', 2);

        await _waitUntil(() async {
          final failed = await queueRepository.getTask('imamsarr', 1);
          return failed?.isFailed == true &&
              downloadRepository.completedOrder.contains(2);
        });

        final failedTask = await queueRepository.getTask('imamsarr', 1);
        expect(failedTask, isNotNull);
        expect(failedTask!.isFailed, isTrue);
        expect(failedTask.attemptCount, 2);
        expect(
          audioRepository.downloadCalls.where((surah) => surah == 1),
          hasLength(2),
        );
        expect(downloadRepository.completedOrder, [2]);
      },
    );

    test('requeues interrupted downloading tasks on startup', () async {
      final queueRepository = _InMemoryDownloadQueueRepository();
      await queueRepository.enqueue('imamsarr', 1);
      await queueRepository.markAsDownloading('imamsarr', 1, progress: 0.5);

      final audioRepository = _FakeAudioRepository();
      final downloadRepository = _FakeDownloadRepository();

      final service = AudioDownloadQueueService(
        queueRepository: queueRepository,
        audioRepository: audioRepository,
        downloadRepository: downloadRepository,
      );
      addTearDown(service.dispose);

      await service.initialize();
      await _waitUntil(
        () async => downloadRepository.completedOrder.contains(1),
      );

      expect(audioRepository.downloadCalls, [1]);
      expect(await queueRepository.getAllTasks(), isEmpty);
    });
  });
}
