import 'package:flutter/material.dart';

import '../../../domain/entities/reading_goal.dart';
import '../../../domain/entities/reading_goal_progress.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../utils/reading_goal_formatting.dart';
import 'reading_goal_actions.dart';
import 'reading_progress_bar.dart';

/// One goal in the goals list: name, status, progress, today's quota and
/// the main action for its phase.
class ReadingGoalCard extends StatelessWidget {
  final ReadingGoalProgress progress;
  final bool isFollowed;

  const ReadingGoalCard({
    super.key,
    required this.progress,
    required this.isFollowed,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final goal = progress.goal;
    final phase = progress.phase;
    final phaseColor = ReadingGoalFormatting.phaseColor(colorScheme, phase);
    final mutedStyle = theme.textTheme.bodySmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerLow : colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(20),
        border: isFollowed
            ? Border.all(color: colorScheme.primary.withValues(alpha: 0.5))
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => ReadingGoalActions.openDetail(context, goal.id),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 8, 16),
          child: _buildBody(
            context,
            localizations,
            theme,
            colorScheme,
            phase,
            phaseColor,
            mutedStyle,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations localizations,
    ThemeData theme,
    ColorScheme colorScheme,
    ReadingGoalPhase phase,
    Color phaseColor,
    TextStyle? mutedStyle,
  ) {
    final goal = progress.goal;
    final metrics = progress.metrics;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _StatusChip(
                        label: ReadingGoalFormatting.phaseLabel(
                          localizations,
                          phase,
                        ),
                        color: phaseColor,
                      ),
                      if (isFollowed)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_stories_rounded,
                              size: 14,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              localizations.readingGoalFollowed,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
            ReadingGoalActions.menuButton(
              context,
              progress,
              isFollowed: isFollowed,
              iconColor: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 14),
              ReadingProgressBar(
                fraction: metrics.fraction,
                color: phase == ReadingGoalPhase.completed
                    ? colorScheme.tertiary
                    : colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      localizations.readingValidatedOf(
                        metrics.validatedCount,
                        metrics.totalPages,
                      ),
                      style: mutedStyle,
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
              const SizedBox(height: 10),
              ..._phaseDetails(context, localizations, mutedStyle),
              const SizedBox(height: 14),
              _primaryAction(context, localizations),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _phaseDetails(
    BuildContext context,
    AppLocalizations localizations,
    TextStyle? mutedStyle,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final goal = progress.goal;
    final metrics = progress.metrics;

    switch (progress.phase) {
      case ReadingGoalPhase.active:
      case ReadingGoalPhase.paused:
        final todayReached = metrics.isTodayTargetReached;
        return [
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
                      : localizations.readingTodayProgress(
                          metrics.readToday,
                          metrics.todayTarget,
                        ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: todayReached ? colorScheme.primary : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${localizations.readingDaysLeft(metrics.remainingDays)} · '
            '${localizations.readingEndsOn(ReadingGoalFormatting.date(context, goal.endDate))}',
            style: mutedStyle,
          ),
        ];
      case ReadingGoalPhase.planned:
        return [
          Text(
            localizations.readingStartsOn(
              ReadingGoalFormatting.date(context, goal.startDate),
            ),
            style: mutedStyle,
          ),
        ];
      case ReadingGoalPhase.expired:
        return [
          Text(
            '${localizations.readingEndsOn(ReadingGoalFormatting.date(context, goal.endDate))} · '
            '${localizations.readingPaceBehind(metrics.remainingPages)}',
            style: mutedStyle?.copyWith(color: colorScheme.error),
          ),
        ];
      case ReadingGoalPhase.completed:
        final completedAt = goal.completedAt;
        return [
          Text(
            completedAt == null
                ? localizations.goalDates(
                    ReadingGoalFormatting.date(context, goal.startDate),
                    ReadingGoalFormatting.date(context, goal.endDate),
                  )
                : localizations.completedOn(
                    ReadingGoalFormatting.dateTime(context, completedAt),
                  ),
            style: mutedStyle,
          ),
        ];
      case ReadingGoalPhase.abandoned:
        return [
          Text(
            localizations.goalDates(
              ReadingGoalFormatting.date(context, goal.startDate),
              ReadingGoalFormatting.date(context, goal.endDate),
            ),
            style: mutedStyle,
          ),
        ];
    }
  }

  Widget _primaryAction(BuildContext context, AppLocalizations localizations) {
    final colorScheme = Theme.of(context).colorScheme;
    final goal = progress.goal;
    ButtonStyle style(bool filled) =>
        (filled
                ? FilledButton.styleFrom(minimumSize: const Size.fromHeight(46))
                : FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    backgroundColor: colorScheme.onSurface.withValues(
                      alpha: 0.06,
                    ),
                    foregroundColor: colorScheme.onSurface,
                  ))
            .copyWith(
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );

    switch (progress.phase) {
      case ReadingGoalPhase.active:
      case ReadingGoalPhase.paused:
      case ReadingGoalPhase.planned:
        return FilledButton.icon(
          style: style(isFollowed),
          onPressed: () =>
              ReadingGoalActions.continueReading(context, progress),
          icon: const Icon(Icons.auto_stories_rounded, size: 18),
          label: Text(
            progress.phase == ReadingGoalPhase.planned
                ? localizations.continueReading
                : localizations.resumeAtPage(progress.resumePage),
          ),
        );
      case ReadingGoalPhase.expired:
        return Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                style: style(true),
                onPressed: () =>
                    ReadingGoalActions.changeEndDate(context, goal),
                icon: const Icon(Icons.event_repeat_rounded, size: 18),
                label: Text(localizations.extendGoal),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                style: style(false),
                onPressed: () =>
                    ReadingGoalActions.continueReading(context, progress),
                icon: const Icon(Icons.auto_stories_rounded, size: 18),
                label: Text(localizations.continueReading),
              ),
            ),
          ],
        );
      case ReadingGoalPhase.completed:
      case ReadingGoalPhase.abandoned:
        return FilledButton.icon(
          style: style(false),
          onPressed: () => ReadingGoalActions.duplicate(context, goal),
          icon: const Icon(Icons.replay_rounded, size: 18),
          label: Text(localizations.duplicateGoal),
        );
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
