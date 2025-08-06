import 'dart:async';

enum DownloadEventType {
  downloadStarted,
  downloadCompleted,
  downloadFailed,
  downloadProgress,
  downloadRemoved,
}

class DownloadEvent {
  final DownloadEventType type;
  final String reciterId;
  final int surahNumber;
  final double? progress;
  final String? filePath;
  final String? error;

  const DownloadEvent({
    required this.type,
    required this.reciterId,
    required this.surahNumber,
    this.progress,
    this.filePath,
    this.error,
  });
}

class DownloadEventService {
  static final DownloadEventService _instance =
      DownloadEventService._internal();
  factory DownloadEventService() => _instance;
  DownloadEventService._internal();

  final _controller = StreamController<DownloadEvent>.broadcast();

  Stream<DownloadEvent> get stream => _controller.stream;

  void emit(DownloadEvent event) {
    _controller.add(event);
  }

  void dispose() {
    _controller.close();
  }
}
