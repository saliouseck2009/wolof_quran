/// Entity representing the download status of a surah's audio
class SurahAudioStatus {
  final int surahNumber;
  final String reciterId;
  final bool isDownloaded;
  final bool isDownloading;
  final double downloadProgress;
  final String? localPath;
  final DateTime? downloadedAt;

  const SurahAudioStatus({
    required this.surahNumber,
    required this.reciterId,
    this.isDownloaded = false,
    this.isDownloading = false,
    this.downloadProgress = 0.0,
    this.localPath,
    this.downloadedAt,
  });

  SurahAudioStatus copyWith({
    int? surahNumber,
    String? reciterId,
    bool? isDownloaded,
    bool? isDownloading,
    double? downloadProgress,
    String? localPath,
    DateTime? downloadedAt,
  }) {
    return SurahAudioStatus(
      surahNumber: surahNumber ?? this.surahNumber,
      reciterId: reciterId ?? this.reciterId,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      isDownloading: isDownloading ?? this.isDownloading,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      localPath: localPath ?? this.localPath,
      downloadedAt: downloadedAt ?? this.downloadedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SurahAudioStatus &&
          runtimeType == other.runtimeType &&
          surahNumber == other.surahNumber &&
          reciterId == other.reciterId;

  @override
  int get hashCode => surahNumber.hashCode ^ reciterId.hashCode;

  @override
  String toString() =>
      'SurahAudioStatus(surah: $surahNumber, reciter: $reciterId, downloaded: $isDownloaded)';
}
