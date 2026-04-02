import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qcf_quran/qcf_quran.dart';

import '../../blocs/mushaf/mushaf_bloc.dart';
import '../../blocs/mushaf/mushaf_state.dart';
import 'mushaf_verse_actions_sheet.dart';

enum _MushafViewportClass {
  small,
  medium,
  large,
  xlarge,
  tabletPortrait,
  tabletLandscape,
}

class _MushafClassTuning {
  final double safetyHeightPx;
  final double viewportBoost;
  final double viewportBonus;
  final double minTextScale;
  final double maxTextScale;
  final double minLineScale;
  final double maxLineScale;

  const _MushafClassTuning({
    required this.safetyHeightPx,
    required this.viewportBoost,
    required this.viewportBonus,
    required this.minTextScale,
    required this.maxTextScale,
    required this.minLineScale,
    required this.maxLineScale,
  });
}

// Easy tuning constants by screen class.
const _smallTuning = _MushafClassTuning(
  safetyHeightPx: 0,
  viewportBoost: 0.02,
  viewportBonus: 0.0,
  minTextScale: 0.82,
  maxTextScale: 1.02,
  minLineScale: 0.80,
  maxLineScale: 1.0,
);

const _mediumTuning = _MushafClassTuning(
  safetyHeightPx: 0,
  viewportBoost: 0.012,
  viewportBonus: 0.0,
  minTextScale: 0.82,
  maxTextScale: 1.03,
  minLineScale: 0.80,
  maxLineScale: 1.0,
);

const _largeTuning = _MushafClassTuning(
  safetyHeightPx: 2,
  viewportBoost: 0.02,
  viewportBonus: 0.055,
  minTextScale: 0.84,
  maxTextScale: 1.06,
  minLineScale: 0.82,
  maxLineScale: 1.04,
);

const _xlargeTuning = _MushafClassTuning(
  safetyHeightPx: 6,
  viewportBoost: 0.0,
  viewportBonus: 0.06,
  minTextScale: 0.86,
  maxTextScale: 1.08,
  minLineScale: 0.84,
  maxLineScale: 1.06,
);

// Dedicated tablet tuning (eg. 2560x1600 px devices).
// Detection is done in logical pixels via shortestSide >= 600.
const _tabletPortraitTuning = _MushafClassTuning(
  safetyHeightPx: 1,
  viewportBoost: 0.0,
  viewportBonus: 0.48,
  minTextScale: 1.45,
  maxTextScale: 2.00,
  minLineScale: 1.18,
  maxLineScale: 1.52,
);

const _tabletLandscapeTuning = _MushafClassTuning(
  safetyHeightPx: 3,
  viewportBoost: 0.01,
  viewportBonus: 0.24,
  minTextScale: 1.10,
  maxTextScale: 1.42,
  minLineScale: 1.00,
  maxLineScale: 1.24,
);

// Extra profile for the stubborn medium-width devices that still overflow.
const double _stubbornWidthMin = 370;
const double _stubbornWidthMax = 420;
const double _stubbornHeightMin = 610;
const double _stubbornHeightMax = 840;
const double _stubbornViewportBoost = 0.03;

class MushafPageContent extends StatelessWidget {
  final int pageNumber;

  const MushafPageContent({super.key, required this.pageNumber});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MushafBloc, MushafState>(
      buildWhen: (previous, current) => previous.theme != current.theme,
      builder: (context, state) {
        final qcfTheme = state.theme.qcfTheme;
        final fullScreenSize = MediaQuery.sizeOf(context);
        final mediaQuery = MediaQuery.of(context);

        return LayoutBuilder(
          builder: (context, constraints) {
            final viewportClass = _resolveViewportClass(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
            );
            final tuning = _tuningForClass(viewportClass);
            final ultraSmallExtraSafety = constraints.maxHeight <= 560
                ? 4.0
                : 0.0;
            final safetyHeightPx =
                tuning.safetyHeightPx + ultraSmallExtraSafety;
            final effectiveHeight = (constraints.maxHeight - safetyHeightPx)
                .clamp(0.0, constraints.maxHeight);
            final viewportSize = Size(constraints.maxWidth, effectiveHeight);

            // QcfPage uses MediaQuery size internally for layout and spacing.
            // Override it with the actual body viewport so the page uses all
            // available height without over-shrinking text.
            final scopedMediaQuery = mediaQuery.copyWith(
              size: viewportSize,
              padding: EdgeInsets.zero,
              viewPadding: EdgeInsets.zero,
              viewInsets: EdgeInsets.zero,
            );

            final heightRatio = (effectiveHeight / fullScreenSize.height).clamp(
              0.80,
              1.0,
            );
            final widthRatio = (constraints.maxWidth / fullScreenSize.width)
                .clamp(0.88, 1.0);
            final fitRatio =
                (heightRatio < widthRatio ? heightRatio : widthRatio)
                    .toDouble();

            // For very small phones, reduce scale enough to guarantee fit
            // without vertical scrolling inside the mushaf page.
            final verticalPenalty = ((640 - constraints.maxHeight) / 220).clamp(
              0.0,
              0.24,
            );
            final horizontalPenalty = ((360 - constraints.maxWidth) / 140)
                .clamp(0.0, 0.18);
            final compactSafety = (verticalPenalty + horizontalPenalty).clamp(
              0.0,
              0.30,
            );

            // Keep text large on regular devices, but prioritize no-scroll fit
            // on very compact screens.
            final textScale =
                ((fitRatio + (1 - fitRatio) * 0.88) - compactSafety)
                    .clamp(0.84, 1.02)
                    .toDouble();
            final lineScale =
                ((fitRatio + (1 - fitRatio) * 0.72) - compactSafety * 0.92)
                    .clamp(0.82, 1.0)
                    .toDouble();

            final stubbornViewportBoost =
                constraints.maxWidth >= _stubbornWidthMin &&
                    constraints.maxWidth <= _stubbornWidthMax &&
                    constraints.maxHeight > _stubbornHeightMin &&
                    constraints.maxHeight <= _stubbornHeightMax
                ? _stubbornViewportBoost
                : 0.0;
            final tabletHorizontalBonus =
                viewportClass == _MushafViewportClass.tabletPortrait
                ? 0.08
                : viewportClass == _MushafViewportClass.tabletLandscape
                ? 0.05
                : 0.0;
            final totalViewportBoost =
                tuning.viewportBoost + stubbornViewportBoost;
            final finalTextScale =
                (textScale -
                        totalViewportBoost +
                        tuning.viewportBonus +
                        tabletHorizontalBonus)
                    .clamp(tuning.minTextScale, tuning.maxTextScale)
                    .toDouble();
            final finalLineScale =
                (lineScale -
                        totalViewportBoost +
                        tuning.viewportBonus * 0.85 +
                        tabletHorizontalBonus * 0.65)
                    .clamp(tuning.minLineScale, tuning.maxLineScale)
                    .toDouble();

            return ColoredBox(
              color: qcfTheme.pageBackgroundColor,
              child: MediaQuery(
                data: scopedMediaQuery,
                child: QcfPage(
                  pageNumber: pageNumber,
                  theme: qcfTheme,
                  sp: finalTextScale,
                  h: finalLineScale,
                  onTap: (surahNumber, verseNumber) {
                    MushafVerseActionsSheet.show(
                      context,
                      surahNumber: surahNumber,
                      verseNumber: verseNumber,
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}

_MushafViewportClass _resolveViewportClass({
  required double width,
  required double height,
}) {
  final shortestSide = width < height ? width : height;
  final isLandscape = width > height;

  if (shortestSide >= 600) {
    return isLandscape
        ? _MushafViewportClass.tabletLandscape
        : _MushafViewportClass.tabletPortrait;
  }

  if (height <= 620) {
    return _MushafViewportClass.small;
  }
  if (height <= 760) {
    return _MushafViewportClass.medium;
  }
  if (height <= 900) {
    return _MushafViewportClass.large;
  }
  return _MushafViewportClass.xlarge;
}

_MushafClassTuning _tuningForClass(_MushafViewportClass viewportClass) {
  switch (viewportClass) {
    case _MushafViewportClass.small:
      return _smallTuning;
    case _MushafViewportClass.medium:
      return _mediumTuning;
    case _MushafViewportClass.large:
      return _largeTuning;
    case _MushafViewportClass.xlarge:
      return _xlargeTuning;
    case _MushafViewportClass.tabletPortrait:
      return _tabletPortraitTuning;
    case _MushafViewportClass.tabletLandscape:
      return _tabletLandscapeTuning;
  }
}
