class DownloadedSurah {
  final int? id;
  final String reciterId;
  final int surahNumber;
  final String filePath;
  final bool isComplete;

  const DownloadedSurah({
    this.id,
    required this.reciterId,
    required this.surahNumber,
    required this.filePath,
    required this.isComplete,
  });

  factory DownloadedSurah.fromMap(Map<String, dynamic> map) {
    return DownloadedSurah(
      id: map['id'],
      reciterId: map['reciter_id'],
      surahNumber: map['surah_number'],
      filePath: map['file_path'],
      isComplete: map['is_complete'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reciter_id': reciterId,
      'surah_number': surahNumber,
      'file_path': filePath,
      'is_complete': isComplete ? 1 : 0,
    };
  }
}
