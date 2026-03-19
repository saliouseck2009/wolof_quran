import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:just_audio/just_audio.dart';
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
  static const String _durationCacheFileName = 'durations_v1.json';
  static const int _durationCacheSchemaVersion = 1;

  Future<void> _warmupChain = Future<void>.value();

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

            // Validate audio file has minimum size and basic header
            if (data.length < 1024 || !_hasValidAudioHeader(data)) {
              log('Skipping invalid audio file: $filename');
              continue;
            }

            final outputFile = File(
              p.join(surahDir.path, p.basename(filename)),
            );
            await outputFile.writeAsBytes(data, flush: true);
          }
        }
      }

      // Update download status
      await _updateDownloadStatus(reciterId, surahNumber, true);
      await _deleteDurationCache(surahDir);

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

    final files = await _getSortedAyahFiles(surahDir);
    final durationsMs = await _readDurationsCacheMs(surahDir, files);
    final audioFiles = <AyahAudio>[];

    for (var index = 0; index < files.length; index++) {
      final file = files[index];
      final ayahNumber = _extractAyahNumberFromPath(file.path);
      if (ayahNumber == null) {
        continue;
      }
      final durationMs = durationsMs != null && index < durationsMs.length
          ? durationsMs[index]
          : null;
      final duration = durationMs != null
          ? Duration(milliseconds: durationMs)
          : null;
      audioFiles.add(
        AyahAudio(
          surahNumber: surahNumber,
          ayahNumber: ayahNumber,
          reciterId: reciterId,
          localPath: file.path,
          duration: duration,
        ),
      );
    }

    return audioFiles;
  }

  @override
  Future<void> warmUpAyahDurations(String reciterId, int surahNumber) async {
    final completer = Completer<void>();
    _warmupChain = _warmupChain.catchError((_) {}).then((_) async {
      try {
        await _performWarmUpAyahDurations(reciterId, surahNumber);
        if (!completer.isCompleted) {
          completer.complete();
        }
      } catch (e, st) {
        if (!completer.isCompleted) {
          completer.completeError(e, st);
        }
      }
    });
    return completer.future;
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

  /// Check if data has a valid audio file header
  bool _hasValidAudioHeader(List<int> data) {
    if (data.length < 4) return false;

    // Check for MP3 header (ID3 tag or MPEG frame sync)
    // ID3v2 starts with "ID3"
    if (data[0] == 0x49 && data[1] == 0x44 && data[2] == 0x33) {
      return true;
    }
    // MPEG frame sync: starts with 0xFF 0xFB, 0xFF 0xFA, or 0xFF 0xF3
    if (data[0] == 0xFF &&
        (data[1] == 0xFB ||
            data[1] == 0xFA ||
            data[1] == 0xF3 ||
            data[1] == 0xF2)) {
      return true;
    }

    // Check for WAV header (RIFF....WAVE)
    if (data.length >= 12 &&
        data[0] == 0x52 &&
        data[1] == 0x49 &&
        data[2] == 0x46 &&
        data[3] == 0x46 &&
        data[8] == 0x57 &&
        data[9] == 0x41 &&
        data[10] == 0x56 &&
        data[11] == 0x45) {
      return true;
    }

    // Check for OGG header (OggS)
    if (data[0] == 0x4F &&
        data[1] == 0x67 &&
        data[2] == 0x67 &&
        data[3] == 0x53) {
      return true;
    }

    // Check for M4A/AAC (ftyp or free/mdat box)
    if (data.length >= 8 &&
        data[4] == 0x66 &&
        data[5] == 0x74 &&
        data[6] == 0x79 &&
        data[7] == 0x70) {
      return true;
    }

    return false;
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

  Future<void> _performWarmUpAyahDurations(
    String reciterId,
    int surahNumber,
  ) async {
    final surahPath = await getSurahAudioPath(reciterId, surahNumber);
    final surahDir = Directory(surahPath);
    if (!surahDir.existsSync()) {
      return;
    }

    final files = await _getSortedAyahFiles(surahDir);
    if (files.isEmpty) {
      return;
    }

    final cachedDurations = await _readDurationsCacheMs(surahDir, files);
    final durationsMs =
        cachedDurations != null && cachedDurations.length == files.length
        ? List<int?>.from(cachedDurations)
        : List<int?>.filled(files.length, null);

    if (durationsMs.every((duration) => duration != null && duration > 0)) {
      return;
    }

    final probePlayer = AudioPlayer();
    try {
      for (var index = 0; index < files.length; index++) {
        if (durationsMs[index] != null && durationsMs[index]! > 0) {
          continue;
        }
        final file = files[index];
        try {
          var duration = await probePlayer.setFilePath(file.path);
          duration ??= probePlayer.duration;
          if (duration != null && duration.inMilliseconds > 0) {
            durationsMs[index] = duration.inMilliseconds;
          }
        } catch (_) {
          // Keep null for this ayah; cache remains partial.
        }
      }
    } finally {
      await probePlayer.dispose();
    }

    await _writeDurationsCacheMs(surahDir, files, durationsMs);
  }

  Future<List<File>> _getSortedAyahFiles(Directory surahDir) async {
    final entries = <MapEntry<int, File>>[];
    final files = surahDir.listSync().whereType<File>();

    for (final file in files) {
      if (!_isAudioFile(file.path)) {
        continue;
      }
      if (!await file.exists() || await file.length() <= 0) {
        continue;
      }
      final ayahNumber = _extractAyahNumberFromPath(file.path);
      if (ayahNumber != null) {
        entries.add(MapEntry(ayahNumber, file));
      }
    }

    entries.sort((a, b) => a.key.compareTo(b.key));
    return entries.map((entry) => entry.value).toList();
  }

  int? _extractAyahNumberFromPath(String path) {
    final filename = p.basenameWithoutExtension(path);
    final parts = filename.split('-');
    if (parts.length != 2) {
      return null;
    }
    return int.tryParse(parts[1]);
  }

  Future<List<int?>?> _readDurationsCacheMs(
    Directory surahDir,
    List<File> sortedAudioFiles,
  ) async {
    final cacheFile = File(p.join(surahDir.path, _durationCacheFileName));
    if (!cacheFile.existsSync()) {
      return null;
    }

    try {
      final raw = await cacheFile.readAsString();
      final payload = json.decode(raw) as Map<String, dynamic>;

      final schemaVersion = payload['schemaVersion'];
      if (schemaVersion != _durationCacheSchemaVersion) {
        return null;
      }

      final trackFiles = payload['trackFiles'];
      final durationsMsRaw = payload['durationsMs'];
      if (trackFiles is! List || durationsMsRaw is! List) {
        return null;
      }
      if (trackFiles.length != sortedAudioFiles.length ||
          durationsMsRaw.length != sortedAudioFiles.length) {
        return null;
      }

      for (var i = 0; i < sortedAudioFiles.length; i++) {
        final expected = p.basename(sortedAudioFiles[i].path);
        if (trackFiles[i] != expected) {
          return null;
        }
      }

      return durationsMsRaw.map<int?>((value) {
        if (value is int && value > 0) {
          return value;
        }
        if (value is num && value > 0) {
          return value.toInt();
        }
        return null;
      }).toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeDurationsCacheMs(
    Directory surahDir,
    List<File> sortedAudioFiles,
    List<int?> durationsMs,
  ) async {
    if (sortedAudioFiles.length != durationsMs.length) {
      return;
    }
    final totalMs = durationsMs.any((item) => item == null)
        ? null
        : durationsMs.fold<int>(0, (sum, value) => sum + value!);
    final payload = <String, dynamic>{
      'schemaVersion': _durationCacheSchemaVersion,
      'generatedAt': DateTime.now().toIso8601String(),
      'trackFiles': sortedAudioFiles
          .map((file) => p.basename(file.path))
          .toList(),
      'durationsMs': durationsMs,
      'totalMs': totalMs,
    };

    final cacheFile = File(p.join(surahDir.path, _durationCacheFileName));
    await cacheFile.writeAsString(json.encode(payload), flush: true);
  }

  Future<void> _deleteDurationCache(Directory surahDir) async {
    final cacheFile = File(p.join(surahDir.path, _durationCacheFileName));
    if (cacheFile.existsSync()) {
      await cacheFile.delete();
    }
  }
}
