import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:qcf_quran/qcf_quran.dart';

class MushafThemeData extends Equatable {
  final int index;
  final Color appBarBackground;
  final Color appBarForeground;
  final Color bottomBarBackground;
  final Color bottomBarText;
  final Color bottomBarSubtext;
  final QcfThemeData qcfTheme;

  const MushafThemeData({
    required this.index,
    required this.appBarBackground,
    required this.appBarForeground,
    required this.bottomBarBackground,
    required this.bottomBarText,
    required this.bottomBarSubtext,
    required this.qcfTheme,
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
      appBarBackground: barBg,
      appBarForeground: barFg,
      bottomBarBackground: barBg,
      bottomBarText: barFg,
      bottomBarSubtext: barSub,
      qcfTheme: QcfThemeData(
        pageBackgroundColor: pageBg,
        verseTextColor: textColor,
        verseNumberColor: verseNumberColor ?? textColor,
        basmalaColor: textColor,
        headerTextColor: const Color(0xFF5D4037),
      ),
    );
  }

  static const int defaultThemeIndex = 2;

  static final List<MushafThemeData> allThemes = [
    _make(
      index: 0,
      pageBg: const Color(0xFFFFFFFF),
      textColor: const Color(0xFF1A1A1A),
    ),
    _make(
      index: 1,
      pageBg: const Color(0xFFFFFFFF),
      textColor: const Color(0xFF5D4037),
    ),
    _make(
      index: 2,
      pageBg: const Color(0xFFFFF8E7),
      textColor: const Color(0xFF3E4A34),
    ),
    _make(
      index: 3,
      pageBg: const Color(0xFFFAF8F5),
      textColor: const Color(0xFF2C2C2C),
    ),
    _make(
      index: 4,
      pageBg: const Color(0xFFF0E8DA),
      textColor: const Color(0xFF5C5C5C),
    ),
    _make(
      index: 5,
      pageBg: const Color(0xFFE8D5A3),
      textColor: const Color(0xFF4A3520),
    ),
    _make(
      index: 6,
      pageBg: const Color(0xFF1B2838),
      textColor: const Color(0xFFE0E0E0),
    ),
    _make(
      index: 7,
      pageBg: const Color(0xFFE3F2FD),
      textColor: const Color(0xFF1565C0),
    ),
    _make(
      index: 8,
      pageBg: const Color(0xFFBDBDBD),
      textColor: const Color(0xFF212121),
    ),
    _make(
      index: 9,
      pageBg: const Color(0xFF424242),
      textColor: const Color(0xFFF5F5F5),
    ),
    _make(
      index: 10,
      pageBg: const Color(0xFF1A1A2E),
      textColor: const Color(0xFFEEEEEE),
    ),
    _make(
      index: 11,
      pageBg: const Color(0xFF616161),
      textColor: const Color(0xFFFFCC80),
    ),
    _make(
      index: 12,
      pageBg: const Color(0xFFE8F5E9),
      textColor: const Color(0xFF1B5E20),
    ),
    _make(
      index: 13,
      pageBg: const Color(0xFFE0F2F1),
      textColor: const Color(0xFF00695C),
    ),
    _make(
      index: 14,
      pageBg: const Color(0xFFC8E6C9),
      textColor: const Color(0xFF2E4D2E),
    ),
    _make(
      index: 15,
      pageBg: const Color(0xFFF1F8E9),
      textColor: const Color(0xFF33691E),
    ),
  ];

  static MushafThemeData fromIndex(int index) {
    if (index < 0 || index >= allThemes.length) {
      return allThemes[defaultThemeIndex];
    }
    return allThemes[index];
  }
}
