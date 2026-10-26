import 'package:equatable/equatable.dart';

enum ReadingValidationSource {
  auto,
  manual;

  String get dbValue => name;

  static ReadingValidationSource fromDb(String? value) {
    return ReadingValidationSource.values.firstWhere(
      (source) => source.name == value,
      orElse: () => ReadingValidationSource.manual,
    );
  }
}

enum ReadingValidationAction {
  page,
  range,
  readUntil,
  juz,
  hizb,
  surah,
  unmark;

  String get dbValue => name;

  static ReadingValidationAction fromDb(String? value) {
    return ReadingValidationAction.values.firstWhere(
      (action) => action.name == value,
      orElse: () => ReadingValidationAction.page,
    );
  }
}

/// One entry of a goal's validation journal. [pages] lists the pages this
/// action actually added (or removed, for [ReadingValidationAction.unmark]),
/// which is what undoing the entry reverts.
class ReadingValidation extends Equatable {
  final String id;
  final String goalId;
  final DateTime createdAt;
  final ReadingValidationSource source;
  final ReadingValidationAction action;
  final int? fromPage;
  final int? toPage;
  final List<int> pages;

  const ReadingValidation({
    required this.id,
    required this.goalId,
    required this.createdAt,
    required this.source,
    required this.action,
    this.fromPage,
    this.toPage,
    required this.pages,
  });

  bool get isUnmark => action == ReadingValidationAction.unmark;

  @override
  List<Object?> get props => [
    id,
    goalId,
    createdAt,
    source,
    action,
    fromPage,
    toPage,
    pages,
  ];
}
