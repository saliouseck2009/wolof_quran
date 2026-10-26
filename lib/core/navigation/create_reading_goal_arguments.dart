import '../../domain/entities/reading_goal.dart';

/// Arguments of the reading goal form.
///
/// With [goalToEdit], the form edits that goal in place. With [template],
/// it starts a new goal prefilled from an existing one. Otherwise it creates
/// a blank goal.
class CreateReadingGoalArguments {
  final ReadingGoal? goalToEdit;
  final ReadingGoal? template;

  const CreateReadingGoalArguments({this.goalToEdit, this.template});

  bool get isEdit => goalToEdit != null;
}
