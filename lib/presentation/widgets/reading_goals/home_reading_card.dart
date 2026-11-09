import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/navigation/create_reading_goal_arguments.dart';
import '../../../domain/entities/reading_goal_progress.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../cubits/reading_goals_cubit.dart';
import '../../utils/home_card_colors.dart';
import '../../views/create_reading_goal_page.dart';
import 'reading_goal_actions.dart';

/// Home strip showing the goal followed in the mushaf (or the first ongoing
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

/// Compact strip: progress ring, goal name, today's quota and a button that
/// reopens the mushaf at the next page. Tapping the strip opens the goal.
class _GoalReadingCard extends StatelessWidget {
  final ReadingGoalProgress progress;

  const _GoalReadingCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final accent = homeAccentColor(colorScheme);
    final metrics = progress.metrics;
    final todayReached = metrics.isTodayTargetReached;

    return Material(
      color: homeCardColor(colorScheme),
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => ReadingGoalActions.openDetail(context, progress.goal.id),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 14, 14),
          child: Row(
            children: [
              _ProgressRing(
                fraction: metrics.fraction,
                label: localizations.percentValue(metrics.percent),
                color: accent,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      progress.goal.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      todayReached
                          ? localizations.readingTodayDone
                          : localizations.readingPagesToday(
                              metrics.remainingForToday,
                            ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: todayReached
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: todayReached
                            ? accent
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () =>
                    ReadingGoalActions.continueReading(context, progress),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(localizations.pageNumberLabel(progress.resumePage)),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  final double fraction;
  final String label;
  final Color color;

  const _ProgressRing({
    required this.fraction,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: SizedBox(
        width: 46,
        height: 46,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: fraction.clamp(0.0, 1.0),
                strokeWidth: 5,
                // A round cap draws a dot at 0 %, so only round a real arc.
                strokeCap: fraction > 0 ? StrokeCap.round : StrokeCap.butt,
                color: color,
                backgroundColor: color.withValues(alpha: 0.14),
              ),
            ),
            SizedBox(
              width: 30,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ),
          ],
        ),
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

    final accent = homeAccentColor(colorScheme);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: homeCardColor(colorScheme),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.flag_rounded, size: 20, color: accent),
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
