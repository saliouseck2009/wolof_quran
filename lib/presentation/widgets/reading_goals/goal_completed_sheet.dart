import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/reading/local_date.dart';
import '../../../domain/entities/reading_goal.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../cubits/reading_goals_cubit.dart';
import '../../utils/reading_goal_formatting.dart';
import 'reading_goal_actions.dart';

/// Shows the completion sheet once when a goal reaches 100 %, whichever
/// screen triggered the last validation.
class ReadingGoalCompletionListener extends StatelessWidget {
  final Widget child;

  const ReadingGoalCompletionListener({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReadingGoalsCubit, ReadingGoalsState>(
      listenWhen: (previous, current) =>
          current.lastCompletedGoalId != null &&
          previous.lastCompletedGoalId != current.lastCompletedGoalId,
      listener: (context, state) {
        final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? true;
        if (!isCurrentRoute) {
          return;
        }
        final goal = state.progressOf(state.lastCompletedGoalId)?.goal;
        context.read<ReadingGoalsCubit>().clearLastCompleted();
        if (goal != null) {
          showGoalCompletedSheet(context, goal: goal);
        }
      },
      child: child,
    );
  }
}

Future<void> showGoalCompletedSheet(
  BuildContext context, {
  required ReadingGoal goal,
}) {
  final navigationBarHeight = MediaQuery.viewPaddingOf(context).bottom;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _GoalCompletedSheet(
      goal: goal,
      navigationBarHeight: navigationBarHeight,
    ),
  );
}

class _GoalCompletedSheet extends StatelessWidget {
  final ReadingGoal goal;
  final double navigationBarHeight;

  const _GoalCompletedSheet({
    required this.goal,
    required this.navigationBarHeight,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final completedAt = goal.completedAt ?? DateTime.now();
    final endDay = LocalDate.fromDateTime(completedAt);
    final actualDays = goal.startDate.daysUntil(endDay) + 1;

    Widget row(IconData icon, String text) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, navigationBarHeight + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colorScheme.tertiary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.verified_rounded,
              size: 34,
              color: colorScheme.tertiary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            localizations.goalCompletedTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            localizations.goalCompletedBody,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            goal.name,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          row(
            Icons.play_circle_outline_rounded,
            localizations.readingStartsOn(
              ReadingGoalFormatting.date(context, goal.startDate),
            ),
          ),
          row(
            Icons.event_available_outlined,
            localizations.completedOn(
              ReadingGoalFormatting.dateTime(context, completedAt),
            ),
          ),
          row(
            Icons.timer_outlined,
            localizations.actualDuration(
              localizations.durationDays(actualDays),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              ReadingGoalActions.duplicate(context, goal);
            },
            icon: const Icon(Icons.replay_rounded),
            label: Text(localizations.startNewKhatm),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ReadingGoalActions.openDetail(context, goal.id);
            },
            child: Text(localizations.viewHistory),
          ),
        ],
      ),
    );
  }
}
