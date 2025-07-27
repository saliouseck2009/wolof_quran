import '../entities/surah_audio_status.dart';
import '../entities/ayah_audio.dart';

/// Repository interface for managing audio downloads and playback
abstract class AudioRepository {
  /// Download audio for a specific surah and reciter
  Future<void> downloadSurahAudio(
    String reciterId,
    int surahNumber, {
    Function(double progress)? onProgress,
  });

  /// Check if surah audio is downloaded
  Future<bool> isSurahAudioDownloaded(String reciterId, int surahNumber);

  /// Get download status for a surah
  Future<SurahAudioStatus> getSurahAudioStatus(
    String reciterId,
    int surahNumber,
  );

  /// Get all downloaded surahs for a reciter
  Future<List<int>> getDownloadedSurahs(String reciterId);

  /// Get ayah audio files for a surah
  Future<List<AyahAudio>> getAyahAudios(String reciterId, int surahNumber);

  /// Delete downloaded audio for a surah
  Future<void> deleteSurahAudio(String reciterId, int surahNumber);

  /// Get local path for surah audio directory
  Future<String> getSurahAudioPath(String reciterId, int surahNumber);
}
