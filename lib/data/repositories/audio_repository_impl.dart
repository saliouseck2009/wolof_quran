import '../../domain/entities/surah_audio_status.dart';
import '../../domain/entities/ayah_audio.dart';
import '../../domain/repositories/audio_repository.dart';
import '../datasources/audio_data_source.dart';

/// Implementation of AudioRepository
class AudioRepositoryImpl implements AudioRepository {
  final AudioDataSource localDataSource;

  AudioRepositoryImpl(this.localDataSource);

  @override
  Future<void> downloadSurahAudio(
    String reciterId,
    int surahNumber, {
    Function(double progress)? onProgress,
  }) async {
    await localDataSource.downloadSurahAudio(
      reciterId,
      surahNumber,
      onProgress: onProgress,
    );
  }

  @override
  Future<bool> isSurahAudioDownloaded(String reciterId, int surahNumber) async {
    return await localDataSource.isSurahAudioDownloaded(reciterId, surahNumber);
  }

  @override
  Future<SurahAudioStatus> getSurahAudioStatus(
    String reciterId,
    int surahNumber,
  ) async {
    return await localDataSource.getSurahAudioStatus(reciterId, surahNumber);
  }

  @override
  Future<List<int>> getDownloadedSurahs(String reciterId) async {
    return await localDataSource.getDownloadedSurahs(reciterId);
  }

  @override
  Future<List<AyahAudio>> getAyahAudios(
    String reciterId,
    int surahNumber,
  ) async {
    return await localDataSource.getAyahAudios(reciterId, surahNumber);
  }

  @override
  Future<void> deleteSurahAudio(String reciterId, int surahNumber) async {
    await localDataSource.deleteSurahAudio(reciterId, surahNumber);
  }

  @override
  Future<String> getSurahAudioPath(String reciterId, int surahNumber) async {
    return await localDataSource.getSurahAudioPath(reciterId, surahNumber);
  }
}
