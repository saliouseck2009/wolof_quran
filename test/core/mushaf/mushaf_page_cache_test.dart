import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wolof_quran/core/mushaf/mushaf_page_cache.dart';
import 'package:wolof_quran/core/mushaf/mushaf_page_renderer.dart';

MushafPageSpec spec(int page, {bool dark = false}) => MushafPageSpec(
  page: page,
  size: const Size(400, 800),
  devicePixelRatio: 1,
  backgroundColor: Colors.white,
  verseColor: Colors.black,
  accentColor: Colors.black,
  isDark: dark,
  isTajweed: true,
);

Future<ui.Image> blankImage() {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(const Rect.fromLTWH(0, 0, 1, 1), Paint());
  return recorder.endRecording().toImage(1, 1);
}

void main() {
  test('spec equality covers everything that changes the pixels', () {
    expect(spec(3), spec(3));
    expect(spec(3).hashCode, spec(3).hashCode);
    expect(spec(3), isNot(spec(4)));
    expect(spec(3), isNot(spec(3, dark: true)));
  });

  test('renders once per spec and dedups concurrent requests', () async {
    var calls = 0;
    final cache = MushafPageCache(
      render: (s) async {
        calls++;
        return MushafPageRender.plain(s, await blankImage());
      },
    );
    final first = cache.get(spec(1));
    final second = cache.get(spec(1));
    expect(identical(await first, await second), isTrue);
    expect(calls, 1);
    await cache.get(spec(1));
    expect(calls, 1);
    expect(cache.peek(spec(1)), isNotNull);
    expect(cache.peek(spec(2)), isNull);
  });

  test('evicts the least recently used page beyond capacity', () async {
    final cache = MushafPageCache(
      capacity: 2,
      render: (s) async => MushafPageRender.plain(s, await blankImage()),
    );
    await cache.get(spec(1));
    await cache.get(spec(2));
    cache.peek(spec(1)); // page 1 becomes the most recent
    await cache.get(spec(3));
    expect(cache.length, 2);
    expect(cache.peek(spec(2)), isNull);
    expect(cache.peek(spec(1)), isNotNull);
    expect(cache.peek(spec(3)), isNotNull);
  });

  test('a retained page is never evicted until released', () async {
    final cache = MushafPageCache(
      capacity: 1,
      render: (s) async => MushafPageRender.plain(s, await blankImage()),
    );
    cache.retain(spec(1));
    await cache.get(spec(1));
    await cache.get(spec(2));
    expect(cache.peek(spec(1)), isNotNull, reason: 'retained');
    cache.release(spec(1));
    expect(cache.length, 1);
    await cache.get(spec(3));
    expect(cache.peek(spec(1)), isNull);
  });
}
