import '../../domain/repositories/download_repository.dart';
import '../models/downloaded_surah.dart';
import '../datasources/database_helper.dart';

class DownloadRepositoryImpl implements DownloadRepository {
  final DatabaseHelper _databaseHelper;

  DownloadRepositoryImpl(this._databaseHelper);

  @override
  Future<bool> isSurahDownloaded(String reciterId, int surahNumber) async {
    return await _databaseHelper.isSurahDownloaded(reciterId, surahNumber);
  }

  @override
  Future<void> markSurahAsDownloaded(
    String reciterId,
    int surahNumber,
    String filePath,
  ) async {
    final surah = DownloadedSurah(
      reciterId: reciterId,
      surahNumber: surahNumber,
      filePath: filePath,
      isComplete: true,
    );
    await _databaseHelper.insertDownloadedSurah(surah);
  }

  @override
  Future<void> markSurahAsInProgress(
    String reciterId,
    int surahNumber,
    String filePath,
  ) async {
    final surah = DownloadedSurah(
      reciterId: reciterId,
      surahNumber: surahNumber,
      filePath: filePath,
      isComplete: false,
    );
    await _databaseHelper.insertDownloadedSurah(surah);
  }

  @override
  Future<void> removeSurahDownload(String reciterId, int surahNumber) async {
    await _databaseHelper.deleteDownloadedSurah(reciterId, surahNumber);
  }

  @override
  Future<List<DownloadedSurah>> getDownloadedSurahs(String reciterId) async {
    return await _databaseHelper.getDownloadedSurahs(reciterId);
  }

  @override
  Future<DownloadedSurah?> getDownloadedSurah(
    String reciterId,
    int surahNumber,
  ) async {
    return await _databaseHelper.getDownloadedSurah(reciterId, surahNumber);
  }

  @override
  Future<Map<String, int>> getDownloadStats(String reciterId) async {
    return await _databaseHelper.getDownloadStats(reciterId);
  }
}
