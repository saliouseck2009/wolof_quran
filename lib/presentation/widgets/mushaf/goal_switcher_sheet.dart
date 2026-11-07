import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/navigation/create_reading_goal_arguments.dart';
import '../../../domain/entities/reading_goal_progress.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../cubits/reading_goals_cubit.dart';
import '../../utils/reading_goal_formatting.dart';
import '../../views/create_reading_goal_page.dart';
import '../reading_goals/reading_goal_form_widgets.dart';
import '../reading_goals/reading_progress_bar.dart';

/// What the user picked in [showGoalSwitcherSheet]: a goal and the page to
/// open for it, or free reading when [goalId] is `null`.
class GoalSwitchChoice {
  final String? goalId;
  final int? page;

  const GoalSwitchChoice({this.goalId, this.page});

  bool get isFreeReading => goalId == null;
}

/// Lets the user pick which goal the mushaf follows, or free reading.
/// Returns `null` when dismissed.
Future<GoalSwitchChoice?> showGoalSwitcherSheet(BuildContext context) {
  final navigationBarHeight = MediaQuery.viewPaddingOf(context).bottom;
  return showModalBottomSheet<GoalSwitchChoice>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) =>
        _GoalSwitcherSheet(navigationBarHeight: navigationBarHeight),
  );
}

class _GoalSwitcherSheet extends StatelessWidget {
  final double navigationBarHeight;

  const _GoalSwitcherSheet({required this.navigationBarHeight});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<ReadingGoalsCubit, ReadingGoalsState>(
      builder: (context, state) {
        final goals = state.ongoing;
        final maxHeight = MediaQuery.sizeOf(context).height * 0.8;

        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Padding(
            padding: EdgeInsets.only(bottom: navigationBarHeight + 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                  child: SheetHeader(
                    title: localizations.switchGoal,
                    subtitle: localizations.switchGoalSubtitle,
                  ),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _ChoiceCard(
                        selected: state.activeGoalId == null,
                        onTap: () =>
                            Navigator.of(context).pop(const GoalSwitchChoice()),
                        child: Row(
                          children: [
                            IconBadge(
                              icon: Icons.schedule_rounded,
                              size: 44,
                              color: state.activeGoalId == null
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _TitleSubtitle(
                                title: localizations.freeReading,
                                subtitle: localizations.freeReadingShort,
                              ),
                            ),
                            _SelectionMark(
                              selected: state.activeGoalId == null,
                            ),
                          ],
                        ),
                      ),
                      for (final progress in goals)
                        _GoalCard(
                          progress: progress,
                          selected: progress.goal.id == state.activeGoalId,
                          onTap: () => Navigator.of(context).pop(
                            GoalSwitchChoice(
                              goalId: progress.goal.id,
                              page:
                                  progress.goal.lastViewedPage ??
                                  progress.resumePage,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      side: BorderSide(
                        color: colorScheme.primary.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.pushNamed(
                        context,
                        CreateReadingGoalPage.routeName,
                        arguments: const CreateReadingGoalArguments(),
                      );
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: Text(localizations.newReadingGoal),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GoalCard extends StatelessWidget {
  final ReadingGoalProgress progress;
  final bool selected;
  final VoidCallback onTap;

  const _GoalCard({
    required this.progress,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final metrics = progress.metrics;
    final goal = progress.goal;

    return _ChoiceCard(
      selected: selected,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconBadge(
                icon: Icons.menu_book_rounded,
                size: 44,
                color: selected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TitleSubtitle(
                  title: goal.name,
                  subtitle:
                      '${localizations.durationDays(goal.durationDays)} · '
                      '${localizations.readingEndsOn(ReadingGoalFormatting.date(context, goal.endDate))}',
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    localizations.today,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    metrics.isTodayTargetReached
                        ? '✓'
                        : '${metrics.readToday}/${metrics.todayTarget}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              if (selected) ...[
                const SizedBox(width: 10),
                const _SelectionMark(selected: true),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  localizations.readingProgressLabel(
                    metrics.validatedCount,
                    metrics.totalPages,
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                localizations.percentValue(metrics.percent),
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ReadingProgressBar(fraction: metrics.fraction, height: 5),
        ],
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final bool selected;
  final Widget child;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.selected,
    required this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected
            ? colorScheme.primary.withValues(alpha: 0.07)
            : colorScheme.onSurface.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? colorScheme.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _TitleSubtitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _TitleSubtitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

class _SelectionMark extends StatelessWidget {
  final bool selected;

  const _SelectionMark({required this.selected});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return selected
        ? Icon(Icons.check_circle_rounded, color: colorScheme.primary, size: 24)
        : Icon(
            Icons.circle_outlined,
            color: colorScheme.outline.withValues(alpha: 0.5),
            size: 24,
          );
  }
}
