import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/navigation/create_reading_goal_arguments.dart';
import '../../../domain/entities/reading_goal_progress.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../cubits/reading_goals_cubit.dart';
import '../../views/create_reading_goal_page.dart';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocBuilder<ReadingGoalsCubit, ReadingGoalsState>(
      builder: (context, state) {
        final goals = state.ongoing;
        final maxHeight = MediaQuery.sizeOf(context).height * 0.75;

        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Padding(
            padding: EdgeInsets.only(bottom: navigationBarHeight + 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localizations.switchGoal,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              localizations.switchGoalSubtitle,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).closeButtonTooltip,
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, size: 20),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _ChoiceTile(
                        selected: state.activeGoalId == null,
                        leading: Icon(
                          Icons.explore_outlined,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        title: localizations.freeReading,
                        subtitle: localizations.freeReadingDescription,
                        onTap: () =>
                            Navigator.of(context).pop(const GoalSwitchChoice()),
                      ),
                      for (final progress in goals)
                        _GoalTile(
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
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
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

class _GoalTile extends StatelessWidget {
  final ReadingGoalProgress progress;
  final bool selected;
  final VoidCallback onTap;

  const _GoalTile({
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

    return _ChoiceTile(
      selected: selected,
      leading: Icon(Icons.flag_rounded, color: colorScheme.primary),
      title: progress.goal.name,
      subtitle:
          '${localizations.readingProgressLabel(metrics.validatedCount, metrics.totalPages)} · '
          '${metrics.isTodayTargetReached ? localizations.todayDoneShort : localizations.todayShort(metrics.readToday, metrics.todayTarget)}',
      bottom: ReadingProgressBar(fraction: metrics.fraction, height: 4),
      onTap: onTap,
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final bool selected;
  final Widget leading;
  final String title;
  final String subtitle;
  final Widget? bottom;
  final VoidCallback onTap;

  const _ChoiceTile({
    required this.selected,
    required this.leading,
    required this.title,
    required this.subtitle,
    this.bottom,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? colorScheme.primaryContainer.withValues(alpha: 0.4)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    leading,
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
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
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (selected) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.check_circle_rounded,
                        color: colorScheme.primary,
                      ),
                    ],
                  ],
                ),
                if (bottom != null) ...[const SizedBox(height: 10), bottom!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
