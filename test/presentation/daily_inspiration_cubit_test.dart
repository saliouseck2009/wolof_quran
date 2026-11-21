import 'package:flutter_test/flutter_test.dart';
import 'package:quran/quran.dart' as quran;
import 'package:wolof_quran/presentation/cubits/daily_inspiration_cubit.dart';

void main() {
  const french = quran.Translation.frHamidullah;

  DailyInspirationLoaded loaded(DailyInspirationCubit cubit) =>
      cubit.state as DailyInspirationLoaded;

  test('the picker chooses the first verse and the next ones', () {
    final calls = <bool>[];
    final cubit = DailyInspirationCubit(
      picker: ({required first}) {
        calls.add(first);
        return first ? (97, 3) : (2, 186);
      },
    );
    addTearDown(cubit.close);

    cubit.generateRandomAyah(french);
    expect((loaded(cubit).surahNumber, loaded(cubit).verseNumber), (97, 3));
    expect(loaded(cubit).surahName, quran.getSurahName(97));

    cubit.refreshAyah(french);
    expect((loaded(cubit).surahNumber, loaded(cubit).verseNumber), (2, 186));
    expect(calls, [true, false]);
  });

  test('changing the translation keeps the verse', () {
    final cubit = DailyInspirationCubit(picker: ({required first}) => (97, 3));
    addTearDown(cubit.close);
    cubit.generateRandomAyah(french);

    cubit.updateTranslation(quran.Translation.enSaheeh);

    expect((loaded(cubit).surahNumber, loaded(cubit).verseNumber), (97, 3));
    expect(
      loaded(cubit).translation,
      quran.getVerseTranslation(97, 3, translation: quran.Translation.enSaheeh),
    );
  });

  test('without a choice from the picker the verse is random', () {
    for (final cubit in [
      DailyInspirationCubit(),
      DailyInspirationCubit(picker: ({required first}) => null),
    ]) {
      addTearDown(cubit.close);
      cubit.generateRandomAyah(french);

      final state = loaded(cubit);
      expect(state.surahNumber, inInclusiveRange(1, 114));
      expect(
        state.verseNumber,
        inInclusiveRange(1, quran.getVerseCount(state.surahNumber)),
      );
    }
  });
}
