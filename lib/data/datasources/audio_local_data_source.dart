import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import '../../domain/entities/surah_audio_status.dart';
import '../../domain/entities/ayah_audio.dart';
import '../datasources/audio_data_source.dart';

/// Local implementation of AudioDataSource for downloading and managing audio files
class AudioLocalDataSource implements AudioDataSource {
  final Dio _dio;
  static const String _baseUrl =
      'https://github.com/saliouseck2009/algo-practice/raw/refs/heads/main';
  static const String _audioFolderName = 'quran_audio';
  static const String _statusFileName = 'download_status.json';

  AudioLocalDataSource(this._dio);

  @override
  Future<void> downloadSurahAudio(
    String reciterId,
    int surahNumber, {
    Function(double progress)? onProgress,
  }) async {
    try {
      // Create URL for the ZIP file
      final surahString = surahNumber.toString().padLeft(3, '0');
      final url = '$_baseUrl/$reciterId/$surahString.zip';

      // Get target directory
      final targetDir = await _getReciterDirectory(reciterId);
      final surahDir = Directory(p.join(targetDir.path, surahString));

      // Create directory if it doesn't exist
      if (!surahDir.existsSync()) {
        surahDir.createSync(recursive: true);
      }

      // Download the ZIP file
      final tempDir = await getTemporaryDirectory();
      final zipFilePath = p.join(tempDir.path, '$surahString.zip');

      await _dio.download(
        url,
        zipFilePath,
        onReceiveProgress: (received, total) {
          if (total != -1 && onProgress != null) {
            final progress = received / total;
            onProgress(progress);
          }
        },
      );

      // Extract the ZIP file
      final zipFile = File(zipFilePath);
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        if (file.isFile) {
          final filename = file.name;
          // Process only audio files
          if (_isAudioFile(filename)) {
            final data = file.content as List<int>;
            final outputFile = File(
              p.join(surahDir.path, p.basename(filename)),
            );
            await outputFile.writeAsBytes(data, flush: true);
          }
        }
      }

      // Update download status
      await _updateDownloadStatus(reciterId, surahNumber, true);

      // Clean up temporary file
      if (zipFile.existsSync()) {
        await zipFile.delete();
      }
    } catch (e) {
      // Update status to indicate failure
      await _updateDownloadStatus(reciterId, surahNumber, false);
      rethrow;
    }
  }

  @override
  Future<bool> isSurahAudioDownloaded(String reciterId, int surahNumber) async {
    final status = await getSurahAudioStatus(reciterId, surahNumber);
    return status.isDownloaded;
  }

  @override
  Future<SurahAudioStatus> getSurahAudioStatus(
    String reciterId,
    int surahNumber,
  ) async {
    final statusMap = await _getDownloadStatusMap(reciterId);
    final key = surahNumber.toString();

    if (statusMap.containsKey(key)) {
      final data = statusMap[key] as Map<String, dynamic>;
      return SurahAudioStatus(
        surahNumber: surahNumber,
        reciterId: reciterId,
        isDownloaded: data['isDownloaded'] ?? false,
        localPath: data['localPath'],
        downloadedAt: data['downloadedAt'] != null
            ? DateTime.parse(data['downloadedAt'])
            : null,
      );
    }

    return SurahAudioStatus(surahNumber: surahNumber, reciterId: reciterId);
  }

  @override
  Future<List<int>> getDownloadedSurahs(String reciterId) async {
    final statusMap = await _getDownloadStatusMap(reciterId);
    final downloadedSurahs = <int>[];

    for (final entry in statusMap.entries) {
      final data = entry.value as Map<String, dynamic>;
      if (data['isDownloaded'] == true) {
        final surahNumber = int.tryParse(entry.key);
        if (surahNumber != null) {
          downloadedSurahs.add(surahNumber);
        }
      }
    }

    downloadedSurahs.sort();
    return downloadedSurahs;
  }

  @override
  Future<List<AyahAudio>> getAyahAudios(
    String reciterId,
    int surahNumber,
  ) async {
    final surahPath = await getSurahAudioPath(reciterId, surahNumber);
    final surahDir = Directory(surahPath);

    if (!surahDir.existsSync()) {
      return [];
    }

    final audioFiles = <AyahAudio>[];
    final files = surahDir.listSync().whereType<File>().toList();

    for (final file in files) {
      if (_isAudioFile(file.path)) {
        // Extract ayah number from filename (assuming format like "001.mp3", "002.mp3", etc.)
        final filename = p.basenameWithoutExtension(file.path);
        final ayahNumber = int.tryParse(filename);

        if (ayahNumber != null) {
          audioFiles.add(
            AyahAudio(
              surahNumber: surahNumber,
              ayahNumber: ayahNumber,
              reciterId: reciterId,
              localPath: file.path,
            ),
          );
        }
      }
    }

    // Sort by ayah number
    audioFiles.sort((a, b) => a.ayahNumber.compareTo(b.ayahNumber));
    return audioFiles;
  }

  @override
  Future<void> deleteSurahAudio(String reciterId, int surahNumber) async {
    final surahPath = await getSurahAudioPath(reciterId, surahNumber);
    final surahDir = Directory(surahPath);

    if (surahDir.existsSync()) {
      await surahDir.delete(recursive: true);
    }

    // Update download status
    await _updateDownloadStatus(reciterId, surahNumber, false);
  }

  @override
  Future<String> getSurahAudioPath(String reciterId, int surahNumber) async {
    final reciterDir = await _getReciterDirectory(reciterId);
    final surahString = surahNumber.toString().padLeft(3, '0');
    return p.join(reciterDir.path, surahString);
  }

  /// Get the directory for a specific reciter
  Future<Directory> _getReciterDirectory(String reciterId) async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final audioDir = Directory(
      p.join(appDocDir.path, _audioFolderName, reciterId),
    );

    if (!audioDir.existsSync()) {
      audioDir.createSync(recursive: true);
    }

    return audioDir;
  }

  /// Check if a file is an audio file based on its extension
  bool _isAudioFile(String filename) {
    final extension = p.extension(filename).toLowerCase();
    return ['.mp3', '.wav', '.m4a', '.aac', '.ogg'].contains(extension);
  }

  /// Get the download status map for a reciter
  Future<Map<String, dynamic>> _getDownloadStatusMap(String reciterId) async {
    final reciterDir = await _getReciterDirectory(reciterId);
    final statusFile = File(p.join(reciterDir.path, _statusFileName));

    if (!statusFile.existsSync()) {
      return {};
    }

    try {
      final content = await statusFile.readAsString();
      return json.decode(content) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  /// Update the download status for a surah
  Future<void> _updateDownloadStatus(
    String reciterId,
    int surahNumber,
    bool isDownloaded,
  ) async {
    final statusMap = await _getDownloadStatusMap(reciterId);
    final key = surahNumber.toString();

    if (isDownloaded) {
      final surahPath = await getSurahAudioPath(reciterId, surahNumber);
      statusMap[key] = {
        'isDownloaded': true,
        'localPath': surahPath,
        'downloadedAt': DateTime.now().toIso8601String(),
      };
    } else {
      statusMap.remove(key);
    }

    final reciterDir = await _getReciterDirectory(reciterId);
    final statusFile = File(p.join(reciterDir.path, _statusFileName));
    await statusFile.writeAsString(json.encode(statusMap));
  }
}
