import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qcf_quran/qcf_quran.dart';

import '../../blocs/mushaf/mushaf_bloc.dart';
import '../../blocs/mushaf/mushaf_state.dart';
import 'mushaf_verse_actions_sheet.dart';

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
            final safetyHeightPx = constraints.maxHeight <= 560
                ? 18.0
                : constraints.maxHeight <= 620
                ? 14.0
                : constraints.maxHeight <= 760
                ? 12.0
                : 10.0;
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

            final tinyViewportBoost = constraints.maxHeight <= 620 ? 0.02 : 0.0;
            final mediumViewportBoost =
                constraints.maxHeight > 620 && constraints.maxHeight <= 760
                ? 0.012
                : 0.0;
            final stubbornViewportBoost =
                constraints.maxWidth >= 370 &&
                    constraints.maxWidth <= 420 &&
                    constraints.maxHeight > 610 &&
                    constraints.maxHeight <= 840
                ? 0.03
                : 0.0;
            final totalViewportBoost =
                tinyViewportBoost + mediumViewportBoost + stubbornViewportBoost;
            final finalTextScale = (textScale - totalViewportBoost)
                .clamp(0.82, 1.02)
                .toDouble();
            final finalLineScale = (lineScale - totalViewportBoost)
                .clamp(0.80, 1.0)
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
