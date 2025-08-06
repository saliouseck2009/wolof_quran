import '../../data/models/downloaded_surah.dart';

abstract class DownloadRepository {
  Future<bool> isSurahDownloaded(String reciterId, int surahNumber);
  Future<void> markSurahAsDownloaded(
    String reciterId,
    int surahNumber,
    String filePath,
  );
  Future<void> markSurahAsInProgress(
    String reciterId,
    int surahNumber,
    String filePath,
  );
  Future<void> removeSurahDownload(String reciterId, int surahNumber);
  Future<List<DownloadedSurah>> getDownloadedSurahs(String reciterId);
  Future<DownloadedSurah?> getDownloadedSurah(
    String reciterId,
    int surahNumber,
  );
  Future<Map<String, int>> getDownloadStats(String reciterId);
}
