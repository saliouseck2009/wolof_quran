import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Lazy loading of the per-page QCF fonts.
///
/// Every mushaf page has its own ~280 KB font, shipped zipped in the
/// qcf_quran_plus package. Registering all 604 of them in the engine at
/// startup cost ~170 MB of memory and fired 604 global "fonts changed"
/// relayouts while the user was reading, which is what made swiping
/// stutter. A font is now extracted (once, to the documents directory the
/// package also uses) and registered when its page is about to be shown.
class MushafFonts {
  const MushafFonts._();

  static final _loaded = <int>{};
  static final _loading = <int, Future<void>>{};
  static Directory? _directory;

  static bool isLoaded(int page) => _loaded.contains(page);

  /// Registers the font of [page]; cheap once loaded.
  static Future<void> ensure(int page) {
    if (_loaded.contains(page)) {
      return Future.value();
    }
    return _loading[page] ??= _load(page)
        .then((_) => _loaded.add(page))
        .whenComplete(() {
          // A block body: returning the removed future would make the
          // chain wait for itself.
          _loading.remove(page);
        });
  }

  static String _fontName(int page) =>
      'QCF4_tajweed_${page.toString().padLeft(3, '0')}';

  static Future<Directory> _fontDirectory() async {
    final cached = _directory;
    if (cached != null) {
      return cached;
    }
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory('${documents.path}/qcf_fonts');
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
    return _directory = directory;
  }

  static Future<void> _load(int page) async {
    final name = _fontName(page);
    final file = File('${(await _fontDirectory()).path}/$name.ttf');
    Uint8List bytes;
    if (file.existsSync() && file.lengthSync() > 1000) {
      bytes = await file.readAsBytes();
    } else {
      final zip = await rootBundle.load(
        'packages/qcf_quran_plus/assets/fonts/qcf_tajweed/$name.zip',
      );
      final zipBytes = zip.buffer.asUint8List();
      final path = file.path;
      bytes = await Isolate.run(() {
        final extracted = _extractFont(zipBytes);
        File(path)
          ..parent.createSync(recursive: true)
          ..writeAsBytesSync(extracted, flush: true);
        return extracted;
      });
    }
    final loader = FontLoader(name)
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  }

  static Uint8List _extractFont(Uint8List zipBytes) {
    for (final entry in ZipDecoder().decodeBytes(zipBytes)) {
      if (entry.name.endsWith('.ttf')) {
        return Uint8List.fromList(entry.content as List<int>);
      }
    }
    throw StateError('No .ttf in the font archive');
  }
}
