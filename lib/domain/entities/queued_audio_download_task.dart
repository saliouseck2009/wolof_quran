import 'package:equatable/equatable.dart';

enum QueuedAudioDownloadStatus { queued, downloading, failed }

extension QueuedAudioDownloadStatusX on QueuedAudioDownloadStatus {
  String get dbValue {
    switch (this) {
      case QueuedAudioDownloadStatus.queued:
        return 'queued';
      case QueuedAudioDownloadStatus.downloading:
        return 'downloading';
      case QueuedAudioDownloadStatus.failed:
        return 'failed';
    }
  }

  static QueuedAudioDownloadStatus fromDb(String raw) {
    switch (raw) {
      case 'downloading':
        return QueuedAudioDownloadStatus.downloading;
      case 'failed':
        return QueuedAudioDownloadStatus.failed;
      case 'queued':
      default:
        return QueuedAudioDownloadStatus.queued;
    }
  }
}

class QueuedAudioDownloadTask extends Equatable {
  final String reciterId;
  final int surahNumber;
  final QueuedAudioDownloadStatus status;
  final double progress;
  final int attemptCount;
  final String? error;
  final DateTime createdAt;
  final DateTime updatedAt;

  const QueuedAudioDownloadTask({
    required this.reciterId,
    required this.surahNumber,
    required this.status,
    required this.progress,
    required this.attemptCount,
    required this.error,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isQueued => status == QueuedAudioDownloadStatus.queued;
  bool get isDownloading => status == QueuedAudioDownloadStatus.downloading;
  bool get isFailed => status == QueuedAudioDownloadStatus.failed;

  String get key => '${reciterId}_$surahNumber';

  QueuedAudioDownloadTask copyWith({
    String? reciterId,
    int? surahNumber,
    QueuedAudioDownloadStatus? status,
    double? progress,
    int? attemptCount,
    String? error,
    bool clearError = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return QueuedAudioDownloadTask(
      reciterId: reciterId ?? this.reciterId,
      surahNumber: surahNumber ?? this.surahNumber,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      attemptCount: attemptCount ?? this.attemptCount,
      error: clearError ? null : (error ?? this.error),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    reciterId,
    surahNumber,
    status,
    progress,
    attemptCount,
    error,
    createdAt,
    updatedAt,
  ];
}
