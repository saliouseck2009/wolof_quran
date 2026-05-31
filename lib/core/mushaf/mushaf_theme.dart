import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class MushafThemeData extends Equatable {
  final int index;
  final Color pageBackgroundColor;
  final Color verseTextColor;
  final Color verseNumberColor;
  final Color appBarBackground;
  final Color appBarForeground;
  final Color bottomBarBackground;
  final Color bottomBarText;
  final Color bottomBarSubtext;

  const MushafThemeData({
    required this.index,
    required this.pageBackgroundColor,
    required this.verseTextColor,
    required this.verseNumberColor,
    required this.appBarBackground,
    required this.appBarForeground,
    required this.bottomBarBackground,
    required this.bottomBarText,
    required this.bottomBarSubtext,
  });

  @override
  List<Object?> get props => [index];

  static MushafThemeData _make({
    required int index,
    required Color pageBg,
    required Color textColor,
    Color? verseNumberColor,
  }) {
    final brightness = ThemeData.estimateBrightnessForColor(pageBg);
    final isDark = brightness == Brightness.dark;

    final barBg = isDark
        ? Color.alphaBlend(Colors.black26, pageBg)
        : Color.alphaBlend(Colors.black.withAlpha(15), pageBg);
    final barFg = textColor;
    final barSub = textColor.withAlpha(153);

    return MushafThemeData(
      index: index,
      pageBackgroundColor: pageBg,
      verseTextColor: textColor,
      verseNumberColor: verseNumberColor ?? textColor,
      appBarBackground: barBg,
      appBarForeground: barFg,
      bottomBarBackground: barBg,
      bottomBarText: barFg,
      bottomBarSubtext: barSub,
    );
  }

  static const int defaultThemeIndex = 2;

  static final List<MushafThemeData> allThemes = [
    _make(
      index: 0,
      pageBg: const Color(0xFFFDFBF5),
      textColor: const Color(0xFF2A241B),
    ),
    _make(
      index: 1,
      pageBg: const Color(0xFFFFFDF8),
      textColor: const Color(0xFF2F2A22),
    ),
    _make(
      index: 2,
      pageBg: const Color(0xFFF8F1E3),
      textColor: const Color(0xFF3A3227),
    ),
    _make(
      index: 3,
      pageBg: const Color(0xFFF3F1EC),
      textColor: const Color(0xFF2E2C29),
    ),
    _make(
      index: 4,
      pageBg: const Color(0xFFEEE2CC),
      textColor: const Color(0xFF3F3528),
    ),
    _make(
      index: 5,
      pageBg: const Color(0xFFE5D2AA),
      textColor: const Color(0xFF4A3A23),
    ),
    _make(
      index: 6,
      pageBg: const Color(0xFF1A1D23),
      textColor: const Color(0xFFEBE6DA),
    ),
    _make(
      index: 7,
      pageBg: const Color(0xFFEAF2F8),
      textColor: const Color(0xFF2D4256),
    ),
    _make(
      index: 8,
      pageBg: const Color(0xFFDFE1DE),
      textColor: const Color(0xFF30322F),
    ),
    _make(
      index: 9,
      pageBg: const Color(0xFF1F1E1B),
      textColor: const Color(0xFFEDE6D7),
    ),
    _make(
      index: 10,
      pageBg: const Color(0xFF151A24),
      textColor: const Color(0xFFE7E3D6),
    ),
    _make(
      index: 11,
      pageBg: const Color(0xFF2A241C),
      textColor: const Color(0xFFF2DEB8),
    ),
    _make(
      index: 12,
      pageBg: const Color(0xFFE9F0E6),
      textColor: const Color(0xFF2F4631),
    ),
    _make(
      index: 13,
      pageBg: const Color(0xFFE5EFEC),
      textColor: const Color(0xFF1F4B46),
    ),
    _make(
      index: 14,
      pageBg: const Color(0xFFDDE8D3),
      textColor: const Color(0xFF32452F),
    ),
    _make(
      index: 15,
      pageBg: const Color(0xFFF2F6EA),
      textColor: const Color(0xFF34492A),
    ),
  ];

  static MushafThemeData fromIndex(int index) {
    if (index < 0 || index >= allThemes.length) {
      return allThemes[defaultThemeIndex];
    }
    return allThemes[index];
  }
}
