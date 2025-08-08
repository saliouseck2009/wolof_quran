// Test file to verify AyahShareModal imports and compiles correctly
import 'package:flutter/material.dart';
import 'lib/presentation/widgets/ayah_card.dart';

void main() {
  // This is just a compilation test
  const modal = AyahShareModal(
    verseNumber: 1,
    arabicText: 'Test Arabic',
    translation: 'Test Translation',
    translationSource: 'Test Source',
    surahName: 'Test Surah',
    surahNumber: 1,
  );

  print('AyahShareModal compiles successfully: ${modal.runtimeType}');
}
