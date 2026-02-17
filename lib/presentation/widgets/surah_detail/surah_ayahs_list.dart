import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart' as quran;

import '../../../domain/entities/bookmark.dart';
import '../../cubits/bookmark_cubit.dart';
import '../../cubits/surah_detail_cubit.dart';
import '../ayah_card.dart';
import '../ayah_play_button.dart';

class SurahAyahsList extends StatelessWidget {
  final int surahNumber;
  final List<AyahData> ayahs;
  final String translationSource;
  final AyahDisplayMode displayMode;
  final List<GlobalKey> ayahKeys;

  const SurahAyahsList({
    super.key,
    required this.surahNumber,
    required this.ayahs,
    required this.translationSource,
    required this.displayMode,
    required this.ayahKeys,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final ayah = ayahs[index];
        return AyahCard(
          key: ayahKeys[index],
          verseNumber: ayah.verseNumber,
          arabicText: ayah.arabicText,
          translationSource: translationSource,
          translation: ayah.translation,
          displayMode: displayMode,
          surahNumber: surahNumber,
          surahName: quran.getSurahName(surahNumber),
          actions: [
            AyahPlayButton(
              surahNumber: surahNumber,
              ayahNumber: ayah.verseNumber,
              surahName: quran.getSurahName(surahNumber),
            ),
            IconButton(
              icon: BlocBuilder<BookmarkCubit, BookmarkState>(
                builder: (context, bookmarkState) {
                  final isBookmarked = context
                      .read<BookmarkCubit>()
                      .isBookmarked(surahNumber, ayah.verseNumber);

                  return Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color:
                        isBookmarked ? colorScheme.primary : colorScheme.outline,
                  );
                },
              ),
              onPressed: () {
                final bookmarkCubit = context.read<BookmarkCubit>();
                final bookmark = BookmarkedAyah(
                  surahNumber: surahNumber,
                  verseNumber: ayah.verseNumber,
                  surahName: quran.getSurahName(surahNumber),
                  arabicText: ayah.arabicText,
                  translation: ayah.translation,
                  translationSource: translationSource,
                  createdAt: DateTime.now(),
                );

                bookmarkCubit.toggleBookmark(bookmark);
              },
            ),
          ],
        );
      }, childCount: ayahs.length),
    );
  }
}
