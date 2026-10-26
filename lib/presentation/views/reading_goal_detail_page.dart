import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/config/theme/app_color.dart';
import '../../core/navigation/mushaf_arguments.dart';
import '../../core/reading/reading_plan_calculator.dart';
import '../../domain/entities/reading_goal.dart';
import '../../domain/entities/reading_goal_progress.dart';
import '../../domain/entities/reading_validation.dart';
import '../../domain/repositories/reading_goal_repository.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../service_locator.dart';
import '../cubits/reading_goal_detail_cubit.dart';
import '../cubits/reading_goals_cubit.dart';
import '../utils/reading_goal_formatting.dart';
import '../widgets/reading_goals/reading_goal_actions.dart';
import '../widgets/reading_goals/reading_pages_map.dart';
import '../widgets/reading_goals/reading_progress_bar.dart';
import 'mushaf_page.dart';

/// Everything about one goal: progress, today's quota, the page map with
/// its gaps, the daily history and the validation journal.
class ReadingGoalDetailPage extends StatelessWidget {
  static const routeName = '/reading-goals/detail';

  final String goalId;

  const ReadingGoalDetailPage({super.key, required this.goalId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ReadingGoalDetailCubit(
        goalId: goalId,
        repository: locator<ReadingGoalRepository>(),
        goalsCubit: context.read<ReadingGoalsCubit>(),
      )..load(),
      child: _DetailView(goalId: goalId),
    );
  }
}

class _DetailView extends StatelessWidget {
  final String goalId;

  const _DetailView({required this.goalId});

  Future<void> _openPage(
    BuildContext context,
    ReadingGoalProgress progress,
    int page,
  ) async {
    final cubit = context.read<ReadingGoalsCubit>();
    await cubit.setActiveGoal(progress.goal.id);
    if (!context.mounted) {
      return;
    }
    await Navigator.pushNamed(
      context,
      MushafPage.routeName,
      arguments: MushafArguments(initialPage: page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return BlocBuilder<ReadingGoalsCubit, ReadingGoalsState>(
      builder: (context, goalsState) {
        final progress = goalsState.progressOf(goalId);
        if (progress == null) {
          // Deleted while open: nothing left to show.
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(localizations.noReadingGoalsInSection)),
          );
        }
        final isFollowed = goalsState.activeGoalId == goalId;

        return Scaffold(
          backgroundColor: isDark ? AppColor.surfaceDark : colorScheme.surface,
          appBar: AppBar(
            title: Text(
              progress.goal.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colorScheme.onPrimary,
                fontSize: 18,
              ),
            ),
            centerTitle: false,
            backgroundColor: isDark
                ? AppColor.surfaceDark
                : colorScheme.primary,
            iconTheme: IconThemeData(color: colorScheme.onPrimary),
            elevation: 0,
            scrolledUnderElevation: 0,
            actions: [
              ReadingGoalActions.menuButton(
                context,
                progress,
                isFollowed: isFollowed,
                iconColor: colorScheme.onPrimary,
              ),
            ],
          ),
          body: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverList.list(
                  children: [
                    _OverviewCard(progress: progress, isFollowed: isFollowed),
                    const SizedBox(height: 12),
                    if (progress.phase != ReadingGoalPhase.completed &&
                        progress.phase != ReadingGoalPhase.abandoned)
                      _TodayCard(progress: progress),
                    const SizedBox(height: 12),
                    _ActionsRow(progress: progress),
                    const SizedBox(height: 24),
                    _SectionTitle(localizations.pagesSectionTitle),
                    const SizedBox(height: 10),
                    ReadingPagesMap(
                      progress: progress,
                      onPageTap: (page) => _openPage(context, progress, page),
                    ),
                    const SizedBox(height: 10),
                    const _Legend(),
                    const SizedBox(height: 24),
                    _SectionTitle(localizations.missingPages),
                    const SizedBox(height: 10),
                    _MissingPages(
                      progress: progress,
                      onPageTap: (page) => _openPage(context, progress, page),
                    ),
                    const SizedBox(height: 24),
                    _SectionTitle(localizations.historyTitle),
                    const SizedBox(height: 10),
                    _History(progress: progress),
                    const SizedBox(height: 24),
                    _SectionTitle(localizations.journalTitle),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                sliver: _Journal(progress: progress),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerLow : colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final ReadingGoalProgress progress;
  final bool isFollowed;

  const _OverviewCard({required this.progress, required this.isFollowed});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final goal = progress.goal;
    final metrics = progress.metrics;
    final phase = progress.phase;
    final phaseColor = ReadingGoalFormatting.phaseColor(colorScheme, phase);
    final mutedStyle = theme.textTheme.bodySmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );
    final continuous = metrics.continuousProgress;
    final lastContinuousPage = continuous == 0
        ? null
        : goal.order.pageAt(continuous - 1);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: phaseColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  ReadingGoalFormatting.phaseLabel(localizations, phase),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: phaseColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (isFollowed)
                Text(
                  localizations.readingGoalFollowed,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                localizations.percentValue(metrics.percent),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    localizations.readingValidatedOf(
                      metrics.validatedCount,
                      metrics.totalPages,
                    ),
                    style: mutedStyle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ReadingProgressBar(fraction: metrics.fraction, height: 8),
          const SizedBox(height: 12),
          Text(
            lastContinuousPage == null
                ? localizations.readingNotStarted
                : localizations.continuousProgressLabel(lastContinuousPage),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${localizations.goalDates(ReadingGoalFormatting.date(context, goal.startDate), ReadingGoalFormatting.date(context, goal.endDate))} · '
            '${localizations.readingDaysLeft(metrics.remainingDays)}',
            style: mutedStyle,
          ),
          if (goal.completedAt != null) ...[
            const SizedBox(height: 4),
            Text(
              localizations.completedOn(
                ReadingGoalFormatting.dateTime(context, goal.completedAt!),
              ),
              style: mutedStyle,
            ),
          ],
        ],
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  final ReadingGoalProgress progress;

  const _TodayCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final metrics = progress.metrics;
    final reached = metrics.isTodayTargetReached;
    final average = ReadingPlanCalculator.averagePagesPerDay(
      totalPages: metrics.remainingPages,
      startDate: progress.today,
      endDate: progress.today.addDays(metrics.remainingDays - 1),
    );

    Widget stat(String label, String value, {Color? color}) {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                reached ? Icons.check_circle_rounded : Icons.today_outlined,
                size: 18,
                color: reached
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  reached
                      ? localizations.readingTodayDone
                      : localizations.readingRemainingToday(
                          metrics.remainingForToday,
                        ),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: reached ? colorScheme.primary : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              stat(
                localizations
                    .todayTarget(metrics.todayTarget)
                    .split(':')
                    .first
                    .trim(),
                '${metrics.todayTarget}',
              ),
              stat(
                localizations
                    .todayRead(metrics.readToday)
                    .split(':')
                    .first
                    .trim(),
                '${metrics.readToday}',
              ),
              stat(
                ReadingGoalFormatting.paceLabel(
                  localizations,
                  metrics.paceDelta,
                ),
                metrics.paceDelta > 0
                    ? '+${metrics.paceDelta}'
                    : '${metrics.paceDelta}',
                color: metrics.paceDelta < 0
                    ? colorScheme.error
                    : metrics.paceDelta > 0
                    ? colorScheme.primary
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            localizations.recommendedPace(
              ReadingGoalFormatting.average(context, average),
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionsRow extends StatelessWidget {
  final ReadingGoalProgress progress;

  const _ActionsRow({required this.progress});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final canRead = progress.goal.acceptsProgress;
    final tonal = FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(46),
      backgroundColor: colorScheme.onSurface.withValues(alpha: 0.06),
      foregroundColor: colorScheme.onSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () =>
              ReadingGoalActions.continueReading(context, progress),
          icon: const Icon(Icons.auto_stories_rounded, size: 18),
          label: Text(localizations.resumeAtPage(progress.resumePage)),
        ),
        if (canRead) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: tonal,
                  onPressed: () =>
                      ReadingGoalActions.markPages(context, progress),
                  icon: const Icon(Icons.playlist_add_check_rounded, size: 18),
                  label: Text(
                    localizations.markPagesRead,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  style: tonal,
                  onPressed: () =>
                      ReadingGoalActions.markSection(context, progress),
                  icon: const Icon(Icons.menu_book_rounded, size: 18),
                  label: Text(
                    '${localizations.sectionJuz} · ${localizations.sectionHizb} · ${localizations.sectionSurah}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget item(Color color, String label) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: [
        item(ReadingPagesMap.readColor(colorScheme), localizations.legendRead),
        item(
          ReadingPagesMap.skippedColor(colorScheme),
          localizations.legendSkipped,
        ),
        item(
          ReadingPagesMap.unreadColor(colorScheme),
          localizations.legendUnread,
        ),
      ],
    );
  }
}

class _MissingPages extends StatelessWidget {
  final ReadingGoalProgress progress;
  final ValueChanged<int> onPageTap;

  const _MissingPages({required this.progress, required this.onPageTap});

  /// Groups consecutive pages (in reading order) into ranges.
  static List<(int, int)> _ranges(ReadingGoalProgress progress) {
    final order = progress.goal.order;
    final skipped = order.skippedPages(progress.validatedPages);
    final ranges = <(int, int)>[];
    for (final page in skipped) {
      if (ranges.isNotEmpty &&
          order.indexOf(page) == order.indexOf(ranges.last.$2) + 1) {
        ranges[ranges.length - 1] = (ranges.last.$1, page);
      } else {
        ranges.add((page, page));
      }
    }
    return ranges;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final ranges = _ranges(progress);

    if (ranges.isEmpty) {
      return Text(
        localizations.noMissingPages,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (from, to) in ranges)
          ActionChip(
            avatar: Icon(
              Icons.auto_stories_rounded,
              size: 16,
              color: colorScheme.error,
            ),
            label: Text(
              from == to
                  ? localizations.pageNumberLabel(from)
                  : localizations.pageRangeLabel(from, to),
            ),
            onPressed: () => onPageTap(from),
          ),
      ],
    );
  }
}

class _History extends StatelessWidget {
  final ReadingGoalProgress progress;

  const _History({required this.progress});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final perDay = ReadingPlanCalculator.pagesPerDay(progress.validatedAt);
    final today = progress.today;
    final start = progress.goal.startDate;
    final firstDay = today.daysUntil(start) > 0 ? today : start;
    final daysShown = (firstDay.daysUntil(today) + 1).clamp(1, 14);
    final locale = Localizations.localeOf(context).toString();
    final dayFormat = DateFormat.MMMEd(locale);
    final maxPages = perDay.values.fold<int>(0, (a, b) => a > b ? a : b);

    return _Card(
      child: Column(
        children: [
          for (var i = 0; i < daysShown; i++)
            _HistoryRow(
              label: i == 0
                  ? localizations.today
                  : dayFormat.format(today.addDays(-i).toDateTime()),
              pages: perDay[today.addDays(-i)] ?? 0,
              maxPages: maxPages,
              emptyLabel: localizations.noPagesThatDay,
              pagesLabel: localizations.pagesCount,
              color: colorScheme.primary,
            ),
          if (daysShown == 0)
            Text(
              localizations.readingNotStarted,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final String label;
  final int pages;
  final int maxPages;
  final String emptyLabel;
  final String Function(int) pagesLabel;
  final Color color;

  const _HistoryRow({
    required this.label,
    required this.pages,
    required this.maxPages,
    required this.emptyLabel,
    required this.pagesLabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: ReadingProgressBar(
              fraction: maxPages == 0 ? 0 : pages / maxPages,
              color: color,
              height: 8,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 72,
            child: Text(
              pages == 0 ? emptyLabel : pagesLabel(pages),
              textAlign: TextAlign.end,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: pages == 0 ? colorScheme.onSurfaceVariant : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Journal extends StatelessWidget {
  final ReadingGoalProgress progress;

  const _Journal({required this.progress});

  static String _actionLabel(
    AppLocalizations localizations,
    ReadingValidationAction action,
  ) {
    switch (action) {
      case ReadingValidationAction.page:
        return localizations.actionPage;
      case ReadingValidationAction.range:
        return localizations.actionRange;
      case ReadingValidationAction.readUntil:
        return localizations.actionReadUntil;
      case ReadingValidationAction.juz:
        return localizations.actionJuz;
      case ReadingValidationAction.hizb:
        return localizations.actionHizb;
      case ReadingValidationAction.surah:
        return localizations.actionSurah;
      case ReadingValidationAction.unmark:
        return localizations.actionUnmark;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final locale = Localizations.localeOf(context).toString();
    final timeFormat = DateFormat.MMMd(locale).add_Hm();

    return BlocBuilder<ReadingGoalDetailCubit, ReadingGoalDetailState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }
        if (state.validations.isEmpty) {
          return SliverToBoxAdapter(
            child: Text(
              localizations.noValidations,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }
        return SliverList.builder(
          itemCount: state.validations.length,
          itemBuilder: (context, index) {
            final validation = state.validations[index];
            final pages = validation.pages;
            final range = pages.isEmpty
                ? ''
                : pages.length == 1
                ? localizations.pageNumberLabel(pages.first)
                : localizations.pageRangeLabel(
                    validation.fromPage ?? pages.first,
                    validation.toPage ?? pages.last,
                  );
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
              decoration: BoxDecoration(
                color: isDark
                    ? colorScheme.surfaceContainerLow
                    : colorScheme.onPrimary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    validation.isUnmark
                        ? Icons.remove_done_rounded
                        : validation.source == ReadingValidationSource.auto
                        ? Icons.timer_outlined
                        : Icons.check_circle_outline_rounded,
                    size: 20,
                    color: validation.isUnmark
                        ? colorScheme.error
                        : colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$range · ${localizations.pagesCount(pages.length)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${_actionLabel(localizations, validation.action)} · '
                          '${validation.source == ReadingValidationSource.auto ? localizations.validationSourceAuto : localizations.validationSourceManual} · '
                          '${timeFormat.format(validation.createdAt)}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (progress.goal.acceptsProgress)
                    TextButton(
                      onPressed: () => context
                          .read<ReadingGoalDetailCubit>()
                          .undo(validation.id),
                      child: Text(localizations.undo),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
