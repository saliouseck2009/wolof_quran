import '../../domain/entities/surah_audio_status.dart';
import '../../domain/entities/ayah_audio.dart';

/// Data source for managing audio downloads and storage
abstract class AudioDataSource {
  /// Download surah audio ZIP file and extract it
  Future<void> downloadSurahAudio(
    String reciterId,
    int surahNumber, {
    Function(double progress)? onProgress,
  });

  /// Check if surah audio exists locally
  Future<bool> isSurahAudioDownloaded(String reciterId, int surahNumber);

  /// Get surah audio status from local storage
  Future<SurahAudioStatus> getSurahAudioStatus(
    String reciterId,
    int surahNumber,
  );

  /// Get list of downloaded surahs for a reciter
  Future<List<int>> getDownloadedSurahs(String reciterId);

  /// Get ayah audio files from local storage
  Future<List<AyahAudio>> getAyahAudios(String reciterId, int surahNumber);

  /// Delete downloaded surah audio
  Future<void> deleteSurahAudio(String reciterId, int surahNumber);

  /// Get local directory path for surah audio
  Future<String> getSurahAudioPath(String reciterId, int surahNumber);
}
