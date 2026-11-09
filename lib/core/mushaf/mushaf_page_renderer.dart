import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart';
// ignore: implementation_imports
import 'package:qcf_quran_plus/src/services/get_page.dart';

import 'mushaf_fonts.dart';

/// Everything that changes the pixels of a page.
@immutable
class MushafPageSpec {
  final int page;
  final Size size;
  final double devicePixelRatio;
  final Color backgroundColor;
  final Color verseColor;
  final Color accentColor;
  final bool isDark;
  final bool isTajweed;

  const MushafPageSpec({
    required this.page,
    required this.size,
    required this.devicePixelRatio,
    required this.backgroundColor,
    required this.verseColor,
    required this.accentColor,
    required this.isDark,
    required this.isTajweed,
  });

  @override
  bool operator ==(Object other) =>
      other is MushafPageSpec &&
      other.page == page &&
      other.size == size &&
      other.devicePixelRatio == devicePixelRatio &&
      other.backgroundColor == backgroundColor &&
      other.verseColor == verseColor &&
      other.accentColor == accentColor &&
      other.isDark == isDark &&
      other.isTajweed == isTajweed;

  @override
  int get hashCode => Object.hash(
    page,
    size,
    devicePixelRatio,
    backgroundColor,
    verseColor,
    accentColor,
    isDark,
    isTajweed,
  );
}

/// A rendered page: one GPU image plus what is needed to find the verse
/// under a long press.
class MushafPageRender {
  final MushafPageSpec spec;
  final ui.Image image;
  final List<_LineHit> _lines;

  MushafPageRender._(this.spec, this.image, this._lines);

  /// A render with no verse hit areas, for tests and placeholders.
  @visibleForTesting
  MushafPageRender.plain(this.spec, this.image) : _lines = const [];

  /// Logical height of the rendered page (the viewport in portrait).
  double get height => spec.size.height;

  /// The verse at [offset] (logical pixels from the page's top-left), or
  /// `null` between lines.
  (int surah, int ayah)? verseAt(Offset offset) {
    for (final line in _lines) {
      if (!line.rect.contains(offset)) {
        continue;
      }
      return line.verseAt(offset);
    }
    return null;
  }

  void dispose() => image.dispose();
}

/// Paints mushaf pages the way the package's widgets lay them out, but
/// once per page into an image, so swiping only moves textures.
class MushafPageRenderer {
  const MushafPageRenderer._();

  static const _fontSize = 23.55;
  static const _lineHeight = 1.45;
  static const _horizontalPadding = 8.0;

  /// The package laid each stretched line out in a (width - 32) box
  /// centred in the page.
  static const _lineInset = 16.0;

  /// The package wrapped every verse in a WidgetSpan, which made the line
  /// paragraph 45 px tall for a 34 px glyph box sitting 11 px from the top
  /// (measured with the real fonts). The glyphs were stretched into the
  /// line from that taller box, so the same proportions are kept here.
  static const _lineTopRatio = 11 / 34;
  static const _lineBoxRatio = 45 / 34;

  static List<QuranPage>? _pages;
  static ui.Image? _banner;
  static Future<ui.Image>? _bannerLoading;

  static List<QuranPage> get pages =>
      _pages ??= (GetPage()..getQuran(totalPagesCount)).staticPages;

  static Future<MushafPageRender> render(MushafPageSpec spec) async {
    await MushafFonts.ensure(spec.page);
    final page = pages[spec.page - 1];
    final banner = page.numberOfNewSurahs > 0 || spec.page <= 2
        ? await _loadBanner(spec)
        : null;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(spec.devicePixelRatio);
    canvas.drawRect(
      Offset.zero & spec.size,
      Paint()..color = spec.backgroundColor,
    );

    final lines = _LineData.ofPage(page);
    final style = _LineStyle.resolve(spec);
    final hits = spec.page <= 2
        ? _paintOpeningPage(canvas, spec, page, lines, style, banner)
        : _paintStandardPage(canvas, spec, page, lines, style, banner);

    final picture = recorder.endRecording();
    // Rasterised once on the raster thread into a GPU-resident texture.
    final image = picture.toImageSync(
      (spec.size.width * spec.devicePixelRatio).round(),
      (spec.size.height * spec.devicePixelRatio).round(),
    );
    picture.dispose();
    return MushafPageRender._(spec, image, hits);
  }

  // ---------------------------------------------------------------------------
  // Layouts
  // ---------------------------------------------------------------------------

  /// Pages 3 to 604: lines stretched to the width and sharing the height.
  static List<_LineHit> _paintStandardPage(
    Canvas canvas,
    MushafPageSpec spec,
    QuranPage page,
    List<_LineData> lines,
    _LineStyle style,
    ui.Image? banner,
  ) {
    final width = spec.size.width;
    final lineCount = lines.isEmpty ? 1 : lines.length;
    final hits = <_LineHit>[];
    var y = 0.0;
    for (final line in lines) {
      // Same figures as the package so pages keep their proportions.
      final headerOffset =
          page.numberOfNewSurahs *
          (line.surahNumber != null && line.surahNumber != 9 ? 110 : 80);
      final lineHeight = (spec.size.height - headerOffset) * 0.95 / lineCount;
      if (line.startsSurah) {
        y += _paintSurahHeader(canvas, spec, banner, line.surahNumber!, y);
        if (line.surahNumber != 9) {
          y += _paintBasmallah(canvas, spec, line.surahNumber!, y);
        }
      }
      final rect = Rect.fromLTWH(
        _lineInset,
        y,
        width - 2 * _lineInset,
        lineHeight > 0 ? lineHeight : 40,
      );
      hits.add(_paintLine(canvas, line, style, rect, fill: !line.centered));
      y += rect.height;
    }
    return hits;
  }

  /// Al-Fatiha and the start of Al-Baqara: centered, never stretched.
  static List<_LineHit> _paintOpeningPage(
    Canvas canvas,
    MushafPageSpec spec,
    QuranPage page,
    List<_LineData> lines,
    _LineStyle style,
    ui.Image? banner,
  ) {
    final surah = page.ayahs.isEmpty ? null : page.ayahs.first.surahNumber;
    final maxWidth = spec.size.width - 2 * _horizontalPadding;
    final painters = [
      for (final line in lines) line.painter(style, maxWidth: maxWidth),
    ];
    var contentHeight = 0.0;
    for (final painter in painters) {
      contentHeight += painter.height * _lineBoxRatio;
    }
    if (surah != null) {
      contentHeight += _surahHeaderHeight(spec);
      if (spec.page == 2) {
        contentHeight += _basmallahHeight(spec, surah);
      }
    }
    var y = ((spec.size.height - contentHeight) / 2).clamp(
      0.0,
      double.infinity,
    );
    if (surah != null) {
      y += _paintSurahHeader(canvas, spec, banner, surah, y);
      if (spec.page == 2) {
        y += _paintBasmallah(canvas, spec, surah, y);
      }
    }
    final hits = <_LineHit>[];
    for (var i = 0; i < lines.length; i++) {
      final painter = painters[i];
      final boxHeight = painter.height * _lineBoxRatio;
      final rect = Rect.fromLTWH(
        (spec.size.width - painter.width) / 2,
        y,
        painter.width,
        boxHeight,
      );
      hits.add(_paintLine(canvas, lines[i], style, rect, fill: false));
      y += boxHeight;
      painter.dispose();
    }
    return hits;
  }

  /// Lays the line out at its natural size and scales it into [rect]:
  /// stretched on both axes when [fill], otherwise scaled down uniformly
  /// and centered.
  static _LineHit _paintLine(
    Canvas canvas,
    _LineData line,
    _LineStyle style,
    Rect rect, {
    required bool fill,
  }) {
    final painter = line.painter(style);
    final naturalWidth = painter.width;
    final glyphTop = painter.height * _lineTopRatio;
    final naturalHeight = painter.height * _lineBoxRatio;
    double scaleX;
    double scaleY;
    Offset origin;
    if (fill) {
      scaleX = rect.width / naturalWidth;
      scaleY = rect.height / naturalHeight;
      origin = rect.topLeft;
    } else {
      final scale = [
        rect.width / naturalWidth,
        rect.height / naturalHeight,
        1.0,
      ].reduce((a, b) => a < b ? a : b);
      scaleX = scale;
      scaleY = scale;
      origin = Offset(
        rect.left + (rect.width - naturalWidth * scale) / 2,
        rect.top + (rect.height - naturalHeight * scale) / 2,
      );
    }
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.scale(scaleX, scaleY);
    painter.paint(canvas, Offset(0, glyphTop));
    canvas.restore();
    painter.dispose();
    return _LineHit(
      line: line,
      style: style,
      rect: Rect.fromLTWH(
        origin.dx,
        origin.dy,
        naturalWidth * scaleX,
        naturalHeight * scaleY,
      ),
      glyphTop: glyphTop,
      scaleX: scaleX,
      scaleY: scaleY,
    );
  }

  // ---------------------------------------------------------------------------
  // Surah header and basmallah, as in the app's widgets
  // ---------------------------------------------------------------------------

  static const _bannerAspect = 3421 / 403;
  static const _headerPadding = 8.0;
  static const _basmallahPaddingTop = 5.0;
  static const _basmallahFontSize = 20.0;

  static double _headerWidth(MushafPageSpec spec) => spec.size.width * 0.9;

  static double _surahHeaderHeight(MushafPageSpec spec) =>
      _headerWidth(spec) / _bannerAspect + 2 * _headerPadding;

  static double _paintSurahHeader(
    Canvas canvas,
    MushafPageSpec spec,
    ui.Image? banner,
    int surah,
    double top,
  ) {
    final headerWidth = _headerWidth(spec);
    final bannerHeight = headerWidth / _bannerAspect;
    final left = (spec.size.width - headerWidth) / 2;
    final bannerRect = Rect.fromLTWH(
      left,
      top + _headerPadding,
      headerWidth,
      bannerHeight,
    );
    if (banner != null) {
      canvas.drawImageRect(
        banner,
        Rect.fromLTWH(0, 0, banner.width.toDouble(), banner.height.toDouble()),
        bannerRect,
        Paint()..filterQuality = FilterQuality.medium,
      );
    }
    final painter = TextPainter(
      text: TextSpan(
        text: '$surah',
        style: QuranTextStyles.surahHeaderStyle(
          fontSize: headerWidth * 0.085,
          color: spec.accentColor,
        ),
      ),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
    )..layout();
    painter.paint(
      canvas,
      Offset(
        bannerRect.center.dx - painter.width / 2,
        bannerRect.center.dy - painter.height / 2,
      ),
    );
    painter.dispose();
    return _surahHeaderHeight(spec);
  }

  static TextPainter _basmallahPainter(MushafPageSpec spec, int surah) {
    // CJK compatibility code points mapped by the QCF4_BSML font. They are
    // escaped because text tooling normalises them to their canonical
    // ideographs, which the font does not have.
    final text = surah == 97 || surah == 95
        ? '\uFAD8\uFAD7\uFAD6\uFAD9'
        : '\uFAD8\uFAD7\uFAD6\uFAD5';
    return TextPainter(
      text: TextSpan(
        text: text,
        style: QuranTextStyles.basmallahStyle(
          fontSize: _basmallahFontSize,
          color: spec.accentColor,
        ),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
  }

  static double _basmallahHeight(MushafPageSpec spec, int surah) {
    final painter = _basmallahPainter(spec, surah);
    final height = painter.height + _basmallahPaddingTop;
    painter.dispose();
    return height;
  }

  static double _paintBasmallah(
    Canvas canvas,
    MushafPageSpec spec,
    int surah,
    double top,
  ) {
    final painter = _basmallahPainter(spec, surah);
    painter.paint(
      canvas,
      Offset((spec.size.width - painter.width) / 2, top + _basmallahPaddingTop),
    );
    final height = painter.height + _basmallahPaddingTop;
    painter.dispose();
    return height;
  }

  /// The package's banner, decoded once at the width it is drawn at.
  static Future<ui.Image> _loadBanner(MushafPageSpec spec) {
    final cached = _banner;
    if (cached != null) {
      return Future.value(cached);
    }
    return _bannerLoading ??= () async {
      final data = await rootBundle.load(
        'packages/qcf_quran_plus/assets/surah_banner.png',
      );
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: (_headerWidth(spec) * spec.devicePixelRatio).round(),
      );
      final frame = await codec.getNextFrame();
      codec.dispose();
      return _banner = frame.image;
    }();
  }
}

// -----------------------------------------------------------------------------
// Line data and hit testing
// -----------------------------------------------------------------------------

class _LineHit {
  final _LineData line;
  final _LineStyle style;
  final Rect rect;
  final double glyphTop;
  final double scaleX;
  final double scaleY;

  const _LineHit({
    required this.line,
    required this.style,
    required this.rect,
    required this.glyphTop,
    required this.scaleX,
    required this.scaleY,
  });

  (int, int)? verseAt(Offset offset) {
    if (line.segments.length == 1) {
      final only = line.segments.single;
      return (only.surahNumber, only.ayahNumber);
    }
    final painter = line.painter(style);
    final local = Offset(
      (offset.dx - rect.left) / scaleX,
      (offset.dy - rect.top) / scaleY - glyphTop,
    );
    final position = painter.getPositionForOffset(local);
    painter.dispose();
    var start = 0;
    for (final segment in line.segments) {
      final end = start + segment.length;
      if (position.offset < end) {
        return (segment.surahNumber, segment.ayahNumber);
      }
      start = end;
    }
    final last = line.segments.last;
    return (last.surahNumber, last.ayahNumber);
  }
}

/// Text styles of a page, resolved once per page.
class _LineStyle {
  final TextStyle base;
  final TextStyle text;
  final TextStyle number;

  const _LineStyle({
    required this.base,
    required this.text,
    required this.number,
  });

  static const _invert = ColorFilter.matrix([
    -1, 0, 0, 0, 255, //
    0, -1, 0, 0, 255, //
    0, 0, -1, 0, 255, //
    0, 0, 0, 1, 0, //
  ]);

  static _LineStyle resolve(MushafPageSpec spec) {
    final base = QuranTextStyles.qcfStyle(
      fontSize: MushafPageRenderer._fontSize,
      height: MushafPageRenderer._lineHeight,
      pageNumber: spec.page,
    ).copyWith(color: spec.verseColor);
    final flat = base.copyWith(height: null);

    // The tajweed fonts carry their colours: inverted in dark mode, and
    // flattened to one colour when tajweed is off.
    ColorFilter? textFilter;
    if (spec.isDark && spec.isTajweed) {
      textFilter = _invert;
    } else if (spec.isDark) {
      textFilter = const ColorFilter.mode(Colors.white, BlendMode.srcIn);
    } else if (!spec.isTajweed) {
      textFilter = const ColorFilter.mode(Colors.black, BlendMode.srcIn);
    }
    TextStyle withFilter(ColorFilter? filter) => filter == null
        ? flat
        : flat.copyWith(color: null, foreground: Paint()..colorFilter = filter);

    return _LineStyle(
      base: base,
      text: withFilter(textFilter),
      number: withFilter(spec.isDark ? _invert : null),
    );
  }
}

class _Segment {
  final String text;
  final String? glyph;
  final int surahNumber;
  final int ayahNumber;

  const _Segment({
    required this.text,
    required this.glyph,
    required this.surahNumber,
    required this.ayahNumber,
  });

  int get length => text.length + (glyph?.length ?? 0);
}

/// A line's verse segments, split once from the package data.
class _LineData {
  final List<_Segment> segments;
  final bool centered;
  final bool startsSurah;
  final int? surahNumber;

  const _LineData({
    required this.segments,
    required this.centered,
    required this.startsSurah,
    required this.surahNumber,
  });

  static List<_LineData> ofPage(QuranPage page) {
    final seenSurahs = <int>{};
    return [
      for (final line in page.lines) _LineData._fromLine(line, seenSurahs),
    ];
  }

  factory _LineData._fromLine(Line line, Set<int> seenSurahs) {
    final first = line.ayahs.isEmpty ? null : line.ayahs.first;
    final startsSurah =
        first != null &&
        first.ayahNumber == 1 &&
        seenSurahs.add(first.surahNumber);
    return _LineData(
      segments: [for (final ayah in line.ayahs) _segmentOf(ayah)],
      centered: line.ayahs.isNotEmpty && line.ayahs.last.centered,
      startsSurah: startsSurah,
      surahNumber: first?.surahNumber,
    );
  }

  static _Segment _segmentOf(Ayah ayah) {
    final text = ayah.qcfData.trimRight();
    final glyph = getaya_noQCF(ayah.surahNumber, ayah.ayahNumber);
    final hasGlyph = glyph.isNotEmpty && text.endsWith(glyph);
    return _Segment(
      text: hasGlyph ? text.substring(0, text.length - glyph.length) : text,
      glyph: hasGlyph ? glyph : null,
      surahNumber: ayah.surahNumber,
      ayahNumber: ayah.ayahNumber,
    );
  }

  /// A laid-out paragraph of the line at its natural size.
  TextPainter painter(_LineStyle style, {double maxWidth = double.infinity}) {
    return TextPainter(
      text: TextSpan(
        style: style.base,
        children: [
          for (final segment in segments) ...[
            TextSpan(text: segment.text, style: style.text),
            if (segment.glyph != null)
              TextSpan(text: segment.glyph, style: style.number),
          ],
        ],
      ),
      textDirection: TextDirection.rtl,
      maxLines: 1,
    )..layout(maxWidth: maxWidth);
  }
}
