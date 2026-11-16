import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wolof_quran/core/services/verse_video_builder.dart';

void main() {
  late Directory workDir;

  setUp(() {
    workDir = Directory.systemTemp.createTempSync('verse_video_test');
  });

  tearDown(() {
    if (workDir.existsSync()) {
      workDir.deleteSync(recursive: true);
    }
  });

  List<VerseVideoSegment> segments(int count) => [
    for (var i = 1; i <= count; i++)
      VerseVideoSegment(imagePath: '/img/$i.jpg', audioPath: '/audio/$i.mp3'),
  ];

  String outputOf(List<String> arguments) => arguments.last;

  /// A runner that writes the output file, as ffmpeg would.
  Future<bool> writingRunner(List<String> arguments) async {
    File(outputOf(arguments)).writeAsStringSync('video');
    return true;
  }

  group('ffmpeg arguments', () {
    test('a piece loops the card over its audio and stops with it', () {
      final arguments = VerseVideoBuilder.segmentArguments(
        segment: const VerseVideoSegment(
          imagePath: '/tmp/card 1.jpg',
          audioPath: '/tmp/001.mp3',
        ),
        outputPath: '/tmp/out.mp4',
      );

      expect(arguments, containsAllInOrder(['-loop', '1']));
      // Paths are passed as they are, spaces included: no shell quoting.
      expect(arguments, containsAllInOrder(['-i', '/tmp/card 1.jpg']));
      expect(arguments, containsAllInOrder(['-i', '/tmp/001.mp3']));
      expect(arguments, containsAllInOrder(['-c:v', 'libx264']));
      expect(arguments, containsAllInOrder(['-c:a', 'aac']));
      expect(arguments, contains('-shortest'));
      expect(arguments.last, '/tmp/out.mp4');
    });

    test('every piece shares frame rate and audio format', () {
      final arguments = VerseVideoBuilder.segmentArguments(
        segment: segments(1).single,
        outputPath: '/tmp/out.mp4',
      );

      expect(arguments, containsAllInOrder(['-r', '25']));
      expect(arguments, containsAllInOrder(['-ar', '44100']));
      expect(arguments, containsAllInOrder(['-ac', '2']));
    });

    test('pieces are joined without re-encoding', () {
      final arguments = VerseVideoBuilder.concatArguments(
        listPath: '/tmp/list.txt',
        outputPath: '/tmp/out.mp4',
      );

      expect(arguments, containsAllInOrder(['-f', 'concat']));
      expect(arguments, containsAllInOrder(['-safe', '0']));
      expect(arguments, containsAllInOrder(['-i', '/tmp/list.txt']));
      expect(arguments, containsAllInOrder(['-c', 'copy']));
      expect(arguments.last, '/tmp/out.mp4');
    });

    test('the join list keeps the order and escapes quotes', () {
      expect(
        VerseVideoBuilder.concatList(['/a/1.mp4', "/it's/2.mp4"]),
        "file '/a/1.mp4'\nfile '/it'\\''s/2.mp4'\n",
      );
    });
  });

  group('build', () {
    test('one verse is encoded straight to the output', () async {
      final calls = <List<String>>[];
      final progress = <String>[];
      final output = '${workDir.path}/out.mp4';
      final builder = VerseVideoBuilder(
        run: (arguments) {
          calls.add(arguments);
          return writingRunner(arguments);
        },
        cancelRunning: () async {},
      );

      final result = await builder.build(
        segments: segments(1),
        workDir: workDir,
        outputPath: output,
        onProgress: (done, total) => progress.add('$done/$total'),
      );

      expect(result.status, VerseVideoStatus.success);
      expect(result.path, output);
      expect(calls, hasLength(1));
      expect(outputOf(calls.single), output);
      expect(progress, ['0/1', '1/1']);
    });

    test('several verses are encoded in order, then joined', () async {
      final calls = <List<String>>[];
      final progress = <String>[];
      String? joinList;
      final output = '${workDir.path}/out.mp4';
      final builder = VerseVideoBuilder(
        run: (arguments) {
          calls.add(arguments);
          final listIndex = arguments.indexOf('concat');
          if (listIndex != -1) {
            final listPath = arguments[arguments.indexOf('-i') + 1];
            joinList = File(listPath).readAsStringSync();
          }
          return writingRunner(arguments);
        },
        cancelRunning: () async {},
      );

      final result = await builder.build(
        segments: segments(3),
        workDir: workDir,
        outputPath: output,
        onProgress: (done, total) => progress.add('$done/$total'),
      );

      expect(result.status, VerseVideoStatus.success);
      expect(calls, hasLength(4));
      expect(calls[0], contains('/audio/1.mp3'));
      expect(calls[1], contains('/audio/2.mp3'));
      expect(calls[2], contains('/audio/3.mp3'));
      expect(
        joinList,
        [for (final call in calls.take(3)) "file '${outputOf(call)}'\n"].join(),
      );
      expect(progress, ['0/3', '1/3', '2/3', '3/3']);
    });

    test('only the video is left behind', () async {
      final output = '${workDir.path}/out.mp4';
      final builder = VerseVideoBuilder(
        run: writingRunner,
        cancelRunning: () async {},
      );

      await builder.build(
        segments: segments(3),
        workDir: workDir,
        outputPath: output,
      );

      expect(workDir.listSync().map((entry) => entry.path), [output]);
    });

    test('a failing verse stops the build and leaves nothing', () async {
      var calls = 0;
      final builder = VerseVideoBuilder(
        run: (arguments) async {
          calls++;
          if (calls == 2) return false;
          return writingRunner(arguments);
        },
        cancelRunning: () async {},
      );

      final result = await builder.build(
        segments: segments(3),
        workDir: workDir,
        outputPath: '${workDir.path}/out.mp4',
      );

      expect(result.status, VerseVideoStatus.failed);
      expect(result.path, isNull);
      expect(calls, 2);
      expect(workDir.listSync(), isEmpty);
    });

    test('cancelling stops after the running verse', () async {
      var calls = 0;
      var cancelRequests = 0;
      late VerseVideoBuilder builder;
      builder = VerseVideoBuilder(
        run: (arguments) async {
          calls++;
          if (calls == 2) {
            await builder.cancel();
            return false;
          }
          return writingRunner(arguments);
        },
        cancelRunning: () async => cancelRequests++,
      );

      final result = await builder.build(
        segments: segments(4),
        workDir: workDir,
        outputPath: '${workDir.path}/out.mp4',
      );

      expect(result.status, VerseVideoStatus.cancelled);
      expect(calls, 2);
      expect(cancelRequests, 1);
      expect(workDir.listSync(), isEmpty);
    });

    test('a builder can be used again after a cancel', () async {
      var cancelNext = true;
      late VerseVideoBuilder builder;
      builder = VerseVideoBuilder(
        run: (arguments) async {
          if (cancelNext) {
            cancelNext = false;
            await builder.cancel();
            return false;
          }
          return writingRunner(arguments);
        },
        cancelRunning: () async {},
      );
      final output = '${workDir.path}/out.mp4';

      final first = await builder.build(
        segments: segments(1),
        workDir: workDir,
        outputPath: output,
      );
      final second = await builder.build(
        segments: segments(1),
        workDir: workDir,
        outputPath: output,
      );

      expect(first.status, VerseVideoStatus.cancelled);
      expect(second.status, VerseVideoStatus.success);
    });
  });
}
