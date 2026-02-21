import '../../domain/entities/reciter.dart';

class ReciterAudioUpdatesArguments {
  final Reciter reciter;
  final List<int> newSurahNumbers;

  const ReciterAudioUpdatesArguments({
    required this.reciter,
    required this.newSurahNumbers,
  });
}
