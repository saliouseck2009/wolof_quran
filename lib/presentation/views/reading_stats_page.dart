import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/config/theme/app_color.dart';
import '../../core/reading/local_date.dart';
import '../../core/reading/reading_stats_calculator.dart';
import '../../domain/repositories/reading_goal_repository.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../service_locator.dart';
import '../cubits/reading_stats_cubit.dart';
import '../utils/reading_goal_formatting.dart';
import '../widgets/reading_goals/reading_goal_form_widgets.dart';
import '../widgets/reading_goals/reading_progress_bar.dart';

/// Cross-goal figures: totals, streaks, pages per day, split by goal and
/// completed khatm. Facts only, no ranking.
class ReadingStatsPage extends StatelessWidget {
  static const routeName = '/reading-stats';

  const ReadingStatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ReadingStatsCubit(repository: locator<ReadingGoalRepository>())
            ..load(),
      child: const _StatsView(),
    );
  }
}

class _StatsView extends StatefulWidget {
  const _StatsView();

  @override
  State<_StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends State<_StatsView> {
  static const _periods = [7, 30, 90];
  var _period = 30;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColor.surfaceDark : colorScheme.surface,
      appBar: AppBar(
        title: Text(
          localizations.statsTitle,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colorScheme.onPrimary,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        backgroundColor: isDark ? AppColor.surfaceDark : colorScheme.primary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: BlocBuilder<ReadingStatsCubit, ReadingStatsState>(
        builder: (context, state) {
          final stats = state.stats;
          if (state.isLoading || stats == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (stats.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.insights_rounded,
                      size: 64,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      localizations.noStatsYet,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            children: [
              _TilesGrid(stats: stats, today: state.today),
              const SizedBox(height: 24),
              _title(theme, localizations.chartTitle),
              const SizedBox(height: 10),
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final days in _periods)
                          QuickChoiceChip(
                            label: localizations.periodDays(days),
                            selected: _period == days,
                            onTap: () => setState(() => _period = days),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 140,
                      child: _PagesChart(
                        data: stats.lastDays(state.today, _period),
                        color: colorScheme.primary,
                        trackColor: colorScheme.onSurface.withValues(
                          alpha: 0.06,
                        ),
                        labelStyle: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        locale: Localizations.localeOf(context).toString(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _title(theme, localizations.byGoalTitle),
              const SizedBox(height: 10),
              _Card(
                child: Column(
                  children: [
                    for (final entry in stats.perGoal)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    entry.goal.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${localizations.readingProgressLabel(entry.validatedCount, entry.goal.totalPages)} · '
                                  '${localizations.percentValue((entry.fraction * 100).floor())}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ReadingProgressBar(fraction: entry.fraction),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (stats.completedGoals.isNotEmpty) ...[
                const SizedBox(height: 24),
                _title(theme, localizations.completedKhatmTitle),
                const SizedBox(height: 10),
                _Card(
                  child: Column(
                    children: [
                      for (final goal in stats.completedGoals)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.verified_rounded,
                            color: colorScheme.tertiary,
                          ),
                          title: Text(
                            goal.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${localizations.goalDates(ReadingGoalFormatting.date(context, goal.startDate), ReadingGoalFormatting.date(context, goal.completedAt == null ? goal.endDate : LocalDate.fromDateTime(goal.completedAt!)))} · '
                            '${localizations.durationDays(goal.startDate.daysUntil(goal.completedAt == null ? goal.endDate : LocalDate.fromDateTime(goal.completedAt!)) + 1)}',
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Center(
                child: Text(
                  localizations.encouragement,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _title(ThemeData theme, String title) => Text(
    title,
    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
  );
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

class _TilesGrid extends StatelessWidget {
  final ReadingStats stats;
  final LocalDate today;

  const _TilesGrid({required this.stats, required this.today});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final time = stats.activeReadingTime;
    final timeLabel = time.inHours > 0
        ? localizations.hoursMinutes(time.inHours, time.inMinutes % 60)
        : localizations.minutesOnly(time.inMinutes);
    final bestDay = stats.bestDay;

    final tiles = [
      (
        Icons.auto_stories_rounded,
        '${stats.totalPagesValidated}',
        localizations.statTotalPages,
      ),
      (
        Icons.verified_rounded,
        '${stats.completedKhatmCount}',
        localizations.statKhatmCompleted,
      ),
      (
        Icons.local_fire_department_outlined,
        localizations.durationDays(stats.currentStreak),
        localizations.statCurrentStreak,
      ),
      (
        Icons.emoji_events_outlined,
        localizations.durationDays(stats.bestStreak),
        localizations.statBestStreak,
      ),
      (
        Icons.speed_rounded,
        ReadingGoalFormatting.average(context, stats.averagePerDayLast30),
        localizations.statAverage,
      ),
      (
        Icons.calendar_today_outlined,
        bestDay == null ? '—' : '${stats.bestDayPages}',
        bestDay == null
            ? localizations.statBestDay
            : localizations.statBestDayOn(
                ReadingGoalFormatting.date(context, bestDay),
              ),
      ),
      (Icons.timer_outlined, timeLabel, localizations.statReadingTime),
    ];

    return Column(
      children: [
        for (var i = 0; i < tiles.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _Tile(tiles[i])),
              if (i + 1 < tiles.length) ...[
                const SizedBox(width: 10),
                Expanded(child: _Tile(tiles[i + 1])),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final (IconData, String, String) data;

  const _Tile(this.data);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final (icon, value, label) = data;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            maxLines: 2,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bars for pages per day; dates are labelled at the ends.
class _PagesChart extends StatelessWidget {
  final List<(LocalDate, int)> data;
  final Color color;
  final Color trackColor;
  final TextStyle? labelStyle;
  final String locale;

  const _PagesChart({
    required this.data,
    required this.color,
    required this.trackColor,
    required this.labelStyle,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final format = DateFormat.MMMd(locale);
    final maxValue = data.fold<int>(0, (a, b) => a > b.$2 ? a : b.$2);
    return Column(
      children: [
        Expanded(
          child: CustomPaint(
            size: Size.infinite,
            painter: _BarsPainter(
              values: [for (final d in data) d.$2],
              maxValue: maxValue,
              color: color,
              trackColor: trackColor,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(format.format(data.first.$1.toDateTime()), style: labelStyle),
            Text('max $maxValue', style: labelStyle),
            Text(format.format(data.last.$1.toDateTime()), style: labelStyle),
          ],
        ),
      ],
    );
  }
}

class _BarsPainter extends CustomPainter {
  final List<int> values;
  final int maxValue;
  final Color color;
  final Color trackColor;

  const _BarsPainter({
    required this.values,
    required this.maxValue,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) {
      return;
    }
    final gap = values.length > 30 ? 1.0 : 3.0;
    final barWidth = (size.width - gap * (values.length - 1)) / values.length;
    final radius = Radius.circular(barWidth.clamp(1.0, 4.0));
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < values.length; i++) {
      final x = i * (barWidth + gap);
      paint.color = trackColor;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 0, barWidth, size.height),
          radius,
        ),
        paint,
      );
      if (maxValue > 0 && values[i] > 0) {
        final h = (values[i] / maxValue * size.height).clamp(2.0, size.height);
        paint.color = color;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, size.height - h, barWidth, h),
            radius,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BarsPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}
