import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/navigation/create_reading_goal_arguments.dart';
import '../../../domain/entities/reading_goal_progress.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../cubits/reading_goals_cubit.dart';
import '../../views/create_reading_goal_page.dart';
import '../../views/reading_goals_page.dart';
import 'reading_goal_actions.dart';
import 'reading_progress_bar.dart';

/// Home card showing the goal followed in the mushaf (or the first ongoing
/// one) with today's quota, or an invitation to create a first goal.
class HomeReadingCard extends StatelessWidget {
  const HomeReadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReadingGoalsCubit, ReadingGoalsState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const SizedBox.shrink();
        }
        final progress =
            state.activeProgress ??
            (state.ongoing.isNotEmpty ? state.ongoing.first : null);
        if (progress == null) {
          return const _EmptyReadingCard();
        }
        return _GoalReadingCard(progress: progress);
      },
    );
  }
}

class _GoalReadingCard extends StatelessWidget {
  final ReadingGoalProgress progress;

  const _GoalReadingCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final metrics = progress.metrics;
    final todayReached = metrics.isTodayTargetReached;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_rounded, size: 16, color: colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  localizations.homeReadingTitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _LinkButton(
                label: localizations.seeAllGoals,
                onTap: () =>
                    Navigator.pushNamed(context, ReadingGoalsPage.routeName),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            progress.goal.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ReadingProgressBar(fraction: metrics.fraction),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  localizations.readingProgressLabel(
                    metrics.validatedCount,
                    metrics.totalPages,
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                localizations.percentValue(metrics.percent),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                todayReached
                    ? Icons.check_circle_rounded
                    : Icons.today_outlined,
                size: 16,
                color: todayReached
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  todayReached
                      ? localizations.readingTodayDone
                      : localizations.readingRemainingToday(
                          metrics.remainingForToday,
                        ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: todayReached
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () =>
                ReadingGoalActions.continueReading(context, progress),
            icon: const Icon(Icons.auto_stories_rounded, size: 18),
            label: Text(localizations.continueReading),
          ),
        ],
      ),
    );
  }
}

class _EmptyReadingCard extends StatelessWidget {
  const _EmptyReadingCard();

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.flag_rounded,
              size: 20,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.homeReadingEmptyTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  localizations.homeReadingEmptyBody,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                _LinkButton(
                  label: localizations.createReadingGoal,
                  icon: Icons.add_rounded,
                  onTap: () => Navigator.pushNamed(
                    context,
                    CreateReadingGoalPage.routeName,
                    arguments: const CreateReadingGoalArguments(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;

  const _LinkButton({required this.label, this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: colorScheme.primary),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
