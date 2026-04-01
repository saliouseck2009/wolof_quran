import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/services/audio_download_queue_service.dart';
import '../../domain/entities/queued_audio_download_task.dart';

class AudioDownloadQueueState extends Equatable {
  final List<QueuedAudioDownloadTask> tasks;
  final QueuedAudioDownloadTask? lastCompletedTask;
  final QueuedAudioDownloadTask? lastFailedTask;
  final int completionVersion;
  final int failureVersion;

  const AudioDownloadQueueState({
    this.tasks = const [],
    this.lastCompletedTask,
    this.lastFailedTask,
    this.completionVersion = 0,
    this.failureVersion = 0,
  });

  QueuedAudioDownloadTask? taskFor(String reciterId, int surahNumber) {
    try {
      return tasks.firstWhere(
        (task) =>
            task.reciterId == reciterId && task.surahNumber == surahNumber,
      );
    } catch (_) {
      return null;
    }
  }

  int queuedPositionFor(String reciterId, int surahNumber) {
    final queue =
        tasks
            .where((task) => task.status == QueuedAudioDownloadStatus.queued)
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final index = queue.indexWhere(
      (task) => task.reciterId == reciterId && task.surahNumber == surahNumber,
    );
    return index >= 0 ? index + 1 : -1;
  }

  int taskCountForReciter(String reciterId) {
    return tasks.where((task) => task.reciterId == reciterId).length;
  }

  bool hasActiveOrQueuedForReciter(String reciterId) {
    return tasks.any(
      (task) =>
          task.reciterId == reciterId &&
          (task.status == QueuedAudioDownloadStatus.queued ||
              task.status == QueuedAudioDownloadStatus.downloading),
    );
  }

  AudioDownloadQueueState copyWith({
    List<QueuedAudioDownloadTask>? tasks,
    QueuedAudioDownloadTask? lastCompletedTask,
    bool clearLastCompletedTask = false,
    QueuedAudioDownloadTask? lastFailedTask,
    bool clearLastFailedTask = false,
    int? completionVersion,
    int? failureVersion,
  }) {
    return AudioDownloadQueueState(
      tasks: tasks ?? this.tasks,
      lastCompletedTask: clearLastCompletedTask
          ? null
          : (lastCompletedTask ?? this.lastCompletedTask),
      lastFailedTask: clearLastFailedTask
          ? null
          : (lastFailedTask ?? this.lastFailedTask),
      completionVersion: completionVersion ?? this.completionVersion,
      failureVersion: failureVersion ?? this.failureVersion,
    );
  }

  @override
  List<Object?> get props => [
    tasks,
    lastCompletedTask,
    lastFailedTask,
    completionVersion,
    failureVersion,
  ];
}

class AudioDownloadQueueCubit extends Cubit<AudioDownloadQueueState> {
  final AudioDownloadQueueService _queueService;

  StreamSubscription<List<QueuedAudioDownloadTask>>? _tasksSubscription;
  StreamSubscription<QueuedAudioDownloadTask>? _completedSubscription;
  StreamSubscription<QueuedAudioDownloadTask>? _failedSubscription;

  AudioDownloadQueueCubit({required AudioDownloadQueueService queueService})
    : _queueService = queueService,
      super(const AudioDownloadQueueState()) {
    _listen();
    unawaited(_queueService.initialize());
  }

  void _listen() {
    _tasksSubscription = _queueService.tasks.listen((tasks) {
      emit(state.copyWith(tasks: tasks));
    });

    _completedSubscription = _queueService.completedTasks.listen((task) {
      emit(
        state.copyWith(
          lastCompletedTask: task,
          completionVersion: state.completionVersion + 1,
        ),
      );
    });

    _failedSubscription = _queueService.failedTasks.listen((task) {
      emit(
        state.copyWith(
          lastFailedTask: task,
          failureVersion: state.failureVersion + 1,
        ),
      );
    });
  }

  Future<EnqueueAudioDownloadResult> enqueue(
    String reciterId,
    int surahNumber,
  ) {
    return _queueService.enqueue(reciterId, surahNumber);
  }

  Future<Map<int, EnqueueAudioDownloadResult>> enqueueMany(
    String reciterId,
    List<int> surahNumbers,
  ) {
    return _queueService.enqueueMany(reciterId, surahNumbers);
  }

  Future<bool> retryFailed(String reciterId, int surahNumber) {
    return _queueService.retryFailed(reciterId, surahNumber);
  }

  Future<void> clearFailed({String? reciterId}) {
    return _queueService.clearFailed(reciterId: reciterId);
  }

  @override
  Future<void> close() async {
    await _tasksSubscription?.cancel();
    await _completedSubscription?.cancel();
    await _failedSubscription?.cancel();
    return super.close();
  }
}
