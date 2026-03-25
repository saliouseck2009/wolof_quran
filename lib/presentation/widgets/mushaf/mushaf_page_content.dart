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

        return ColoredBox(
          color: qcfTheme.pageBackgroundColor,
          child: QcfPage(
            pageNumber: pageNumber,
            theme: qcfTheme,
            onTap: (surahNumber, verseNumber) {
              MushafVerseActionsSheet.show(
                context,
                surahNumber: surahNumber,
                verseNumber: verseNumber,
              );
            },
          ),
        );
      },
    );
  }
}
