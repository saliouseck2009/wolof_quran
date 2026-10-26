import 'package:equatable/equatable.dart';

/// One stretch of reading in the mushaf with a goal followed.
class ReadingSession extends Equatable {
  final String id;
  final String goalId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final Duration activeDuration;
  final List<int> pagesViewed;

  const ReadingSession({
    required this.id,
    required this.goalId,
    required this.startedAt,
    this.endedAt,
    this.activeDuration = Duration.zero,
    this.pagesViewed = const [],
  });

  @override
  List<Object?> get props => [
    id,
    goalId,
    startedAt,
    endedAt,
    activeDuration,
    pagesViewed,
  ];
}
