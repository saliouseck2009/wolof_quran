import 'dart:developer';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/return_code.dart';

/// One verse of a shared video: its card, shown while its audio plays.
class VerseVideoSegment {
  final String imagePath;
  final String audioPath;

  const VerseVideoSegment({required this.imagePath, required this.audioPath});
}

enum VerseVideoStatus { success, cancelled, failed }

class VerseVideoResult {
  final VerseVideoStatus status;

  /// The video file, set only on [VerseVideoStatus.success].
  final String? path;

  const VerseVideoResult.success(String this.path)
    : status = VerseVideoStatus.success;
  const VerseVideoResult.cancelled()
    : status = VerseVideoStatus.cancelled,
      path = null;
  const VerseVideoResult.failed()
    : status = VerseVideoStatus.failed,
      path = null;
}

/// Runs ffmpeg with [arguments]; `true` when it succeeded.
typedef FfmpegRunner = Future<bool> Function(List<String> arguments);

/// Builds the video of one or several verses.
///
/// Each verse is encoded on its own (a still card over its audio), then
/// the pieces are joined without re-encoding. Encoding verse by verse
/// gives a progress step per verse and lets a cancel stop early.
class VerseVideoBuilder {
  /// Every piece is encoded with the same frame rate and audio format:
  /// joining without re-encoding needs identical streams.
  static const int frameRate = 25;
  static const int audioSampleRate = 44100;

  final FfmpegRunner _run;
  final Future<void> Function() _cancelRunning;
  bool _cancelled = false;

  VerseVideoBuilder({
    FfmpegRunner run = _runFfmpeg,
    Future<void> Function() cancelRunning = _cancelFfmpeg,
  }) : _run = run,
       _cancelRunning = cancelRunning;

  /// Stops the current [build]; it then returns a cancelled result.
  Future<void> cancel() async {
    _cancelled = true;
    await _cancelRunning();
  }

  /// Encodes [segments] in order into [outputPath].
  ///
  /// Temporary pieces are written to [workDir] and deleted before
  /// returning. [onProgress] is called with the number of verses done.
  Future<VerseVideoResult> build({
    required List<VerseVideoSegment> segments,
    required Directory workDir,
    required String outputPath,
    void Function(int done, int total)? onProgress,
  }) async {
    assert(segments.isNotEmpty);
    _cancelled = false;
    final total = segments.length;
    final temporaryFiles = <String>[];

    try {
      onProgress?.call(0, total);

      if (total == 1) {
        final ok = await _run(
          segmentArguments(segment: segments.single, outputPath: outputPath),
        );
        if (_cancelled) return await _abandon(outputPath, cancelled: true);
        if (!ok) return await _abandon(outputPath, cancelled: false);
        onProgress?.call(1, 1);
        return VerseVideoResult.success(outputPath);
      }

      final stamp = DateTime.now().microsecondsSinceEpoch;
      final piecePaths = <String>[];
      for (var index = 0; index < total; index++) {
        final piecePath = '${workDir.path}/verse_video_${stamp}_$index.mp4';
        temporaryFiles.add(piecePath);
        final ok = await _run(
          segmentArguments(segment: segments[index], outputPath: piecePath),
        );
        if (_cancelled) return await _abandon(outputPath, cancelled: true);
        if (!ok) return await _abandon(outputPath, cancelled: false);
        piecePaths.add(piecePath);
        onProgress?.call(index + 1, total);
      }

      final listPath = '${workDir.path}/verse_video_$stamp.txt';
      temporaryFiles.add(listPath);
      await File(listPath).writeAsString(concatList(piecePaths));

      final ok = await _run(
        concatArguments(listPath: listPath, outputPath: outputPath),
      );
      if (_cancelled) return await _abandon(outputPath, cancelled: true);
      if (!ok) return await _abandon(outputPath, cancelled: false);
      return VerseVideoResult.success(outputPath);
    } finally {
      for (final path in temporaryFiles) {
        await _deleteQuietly(path);
      }
    }
  }

  Future<VerseVideoResult> _abandon(
    String outputPath, {
    required bool cancelled,
  }) async {
    await _deleteQuietly(outputPath);
    return cancelled
        ? const VerseVideoResult.cancelled()
        : const VerseVideoResult.failed();
  }

  static Future<void> _deleteQuietly(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // A leftover temporary file is harmless: the system clears them.
    }
  }

  /// A 1080x1920 video of the still [segment] image, as long as its audio.
  static List<String> segmentArguments({
    required VerseVideoSegment segment,
    required String outputPath,
  }) => [
    '-y',
    '-loop', '1',
    '-framerate', '$frameRate',
    '-i', segment.imagePath,
    '-i', segment.audioPath,
    '-vf',
    'scale=1080:1920:force_original_aspect_ratio=decrease,'
        'pad=1080:1920:(1080-iw)/2:(1920-ih)/2,format=yuv420p',
    '-c:v', 'libx264',
    '-preset', 'veryfast',
    '-tune', 'stillimage',
    '-r', '$frameRate',
    '-c:a', 'aac',
    '-b:a', '192k',
    '-ar', '$audioSampleRate',
    '-ac', '2',
    // Stops the looping picture with the audio. FFmpeg 8 cuts within a
    // frame of it, so the clips join without an audible gap.
    '-shortest',
    outputPath,
  ];

  /// Joins the pieces listed in [listPath] without re-encoding them.
  static List<String> concatArguments({
    required String listPath,
    required String outputPath,
  }) => [
    '-y',
    '-f',
    'concat',
    '-safe',
    '0',
    '-i',
    listPath,
    '-c',
    'copy',
    '-movflags',
    '+faststart',
    outputPath,
  ];

  /// Content of the list file read by ffmpeg's concat demuxer.
  static String concatList(List<String> paths) => [
    for (final path in paths) "file '${path.replaceAll("'", r"'\''")}'\n",
  ].join();

  static Future<bool> _runFfmpeg(List<String> arguments) async {
    final session = await FFmpegKit.executeWithArguments(arguments);
    final returnCode = await session.getReturnCode();
    if (ReturnCode.isSuccess(returnCode)) {
      return true;
    }
    if (!ReturnCode.isCancel(returnCode)) {
      log('FFmpeg failed with output: ${await session.getOutput()}');
    }
    return false;
  }

  static Future<void> _cancelFfmpeg() => FFmpegKit.cancel();

  /// Length of the audio file at [path], read by ffprobe; `null` when
  /// it cannot be read.
  static Future<Duration?> probeDuration(String path) async {
    try {
      final session = await FFprobeKit.getMediaInformation(path);
      final seconds = double.tryParse(
        session.getMediaInformation()?.getDuration() ?? '',
      );
      if (seconds == null || seconds <= 0) {
        return null;
      }
      return Duration(milliseconds: (seconds * 1000).round());
    } catch (_) {
      return null;
    }
  }
}
