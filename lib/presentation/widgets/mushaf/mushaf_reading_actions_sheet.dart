import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/reading/reading_plan_calculator.dart';
import '../../../domain/entities/reading_goal_progress.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../cubits/reading_goals_cubit.dart';
import '../reading_goals/reading_goal_form_widgets.dart';
import '../reading_goals/reading_progress_bar.dart';

enum MushafReadingAction {
  markPage,
  unmarkPage,
  readUntilHere,
  markSeveral,
  markSection,
  viewProgress,
  switchGoal,
  freeReading,
  followGoal,
  createGoal,
}

/// Reading actions available from the mushaf for the followed goal, or the
/// ways to start following one. Returns the chosen action, or `null`.
Future<MushafReadingAction?> showMushafReadingActionsSheet(
  BuildContext context, {
  required int currentPage,
}) {
  final navigationBarHeight = MediaQuery.viewPaddingOf(context).bottom;
  return showModalBottomSheet<MushafReadingAction>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _ReadingActionsSheet(
      currentPage: currentPage,
      navigationBarHeight: navigationBarHeight,
    ),
  );
}

class _ReadingActionsSheet extends StatelessWidget {
  final int currentPage;
  final double navigationBarHeight;

  const _ReadingActionsSheet({
    required this.currentPage,
    required this.navigationBarHeight,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocBuilder<ReadingGoalsCubit, ReadingGoalsState>(
      builder: (context, state) {
        final progress = state.activeProgress;

        void pick(MushafReadingAction action) =>
            Navigator.of(context).pop(action);

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 0, 20, navigationBarHeight + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: progress != null
                ? _goalActions(context, localizations, progress, pick)
                : _freeReadingActions(
                    localizations,
                    hasGoals: state.ongoing.isNotEmpty,
                    pick: pick,
                  ),
          ),
        );
      },
    );
  }

  List<Widget> _goalActions(
    BuildContext context,
    AppLocalizations localizations,
    ReadingGoalProgress progress,
    void Function(MushafReadingAction) pick,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final metrics = progress.metrics;
    final isPageValidated = progress.isValidated(currentPage);
    final continuous = metrics.continuousProgress;
    final isLastRead =
        continuous > 0 &&
        progress.goal.order.pageAt(continuous - 1) == currentPage;
    final pageDetail = isLastRead
        ? '${localizations.pageNumberLabel(currentPage)} · ${localizations.lastPageReadTag}'
        : localizations.pageNumberLabel(currentPage);

    return [
      SheetHeader(
        icon: Icons.menu_book_rounded,
        title: progress.goal.name,
        subtitle:
            '${localizations.readingProgressLabel(metrics.validatedCount, metrics.totalPages)} · '
            '${metrics.isTodayTargetReached ? localizations.todayDoneShort : localizations.todayShort(metrics.readToday, metrics.todayTarget)}',
      ),
      const SizedBox(height: 14),
      Row(
        children: [
          Expanded(
            child: _StatCard(
              label: localizations.totalLabel,
              fraction: metrics.fraction,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              label: localizations.today,
              fraction: _todayFraction(metrics),
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      SheetActionRow(
        icon: isPageValidated
            ? Icons.delete_outline_rounded
            : Icons.check_circle_outline_rounded,
        title: isPageValidated
            ? localizations.unmarkThisPage
            : localizations.markThisPageRead,
        subtitle: pageDetail,
        filled: true,
        tint: isPageValidated ? colorScheme.error : null,
        onTap: () => pick(
          isPageValidated
              ? MushafReadingAction.unmarkPage
              : MushafReadingAction.markPage,
        ),
      ),
      const SizedBox(height: 6),
      SheetActionRow(
        icon: Icons.fact_check_outlined,
        title: localizations.readUntilHere,
        subtitle: localizations.readUntilHereSubtitle,
        onTap: () => pick(MushafReadingAction.readUntilHere),
      ),
      SheetActionRow(
        icon: Icons.playlist_add_check_rounded,
        title: localizations.markSeveralPages,
        subtitle: localizations.markSeveralPagesSubtitle,
        onTap: () => pick(MushafReadingAction.markSeveral),
      ),
      SheetActionRow(
        icon: Icons.auto_stories_outlined,
        title: localizations.markSection,
        subtitle: localizations.markSectionSubtitle,
        onTap: () => pick(MushafReadingAction.markSection),
      ),
      SheetActionRow(
        icon: Icons.insights_rounded,
        title: localizations.viewProgress,
        subtitle: localizations.viewProgressSubtitle,
        onTap: () => pick(MushafReadingAction.viewProgress),
      ),
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: SheetRowDivider(),
      ),
      SheetActionRow(
        icon: Icons.swap_horiz_rounded,
        title: localizations.switchGoal,
        tint: colorScheme.onSurfaceVariant,
        onTap: () => pick(MushafReadingAction.switchGoal),
      ),
      SheetActionRow(
        icon: Icons.explore_outlined,
        title: localizations.switchToFreeReading,
        tint: colorScheme.onSurfaceVariant,
        onTap: () => pick(MushafReadingAction.freeReading),
      ),
    ];
  }

  List<Widget> _freeReadingActions(
    AppLocalizations localizations, {
    required bool hasGoals,
    required void Function(MushafReadingAction) pick,
  }) {
    return [
      SheetHeader(
        icon: Icons.schedule_rounded,
        title: localizations.freeReading,
        subtitle: localizations.freeReadingDescription,
      ),
      const SizedBox(height: 10),
      const SheetRowDivider(),
      const SizedBox(height: 6),
      if (hasGoals) ...[
        SheetActionRow(
          icon: Icons.menu_book_rounded,
          title: localizations.followAGoal,
          subtitle: localizations.followAGoalSubtitle,
          chevron: true,
          onTap: () => pick(MushafReadingAction.followGoal),
        ),
        const SheetRowDivider(),
      ],
      SheetActionRow(
        icon: Icons.add_rounded,
        title: localizations.newReadingGoal,
        subtitle: localizations.newGoalSubtitle,
        chevron: true,
        onTap: () => pick(MushafReadingAction.createGoal),
      ),
      const SheetRowDivider(),
      SheetActionRow(
        icon: Icons.insights_rounded,
        title: localizations.readingGoals,
        subtitle: localizations.viewProgress,
        chevron: true,
        onTap: () => pick(MushafReadingAction.viewProgress),
      ),
    ];
  }

  static double _todayFraction(ReadingPlanMetrics metrics) {
    if (metrics.todayTarget == 0) {
      return 1;
    }
    return (metrics.readToday / metrics.todayTarget).clamp(0.0, 1.0);
  }
}

/// Small card with an uppercase label, a percentage and a progress bar.
class _StatCard extends StatelessWidget {
  final String label;
  final double fraction;

  const _StatCard({required this.label, required this.fraction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final localizations = AppLocalizations.of(context)!;
    final percent = (fraction * 100).floor();

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                localizations.percentValue(percent),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ReadingProgressBar(fraction: fraction, height: 4),
        ],
      ),
    );
  }
}
