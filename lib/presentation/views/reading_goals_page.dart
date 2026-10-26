import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/config/theme/app_color.dart';
import '../../core/navigation/create_reading_goal_arguments.dart';
import '../../domain/entities/reading_goal_progress.dart';
import '../../l10n/generated/app_localizations.dart';
import '../cubits/reading_goals_cubit.dart';
import '../widgets/reading_goals/reading_goal_card.dart';
import '../widgets/reading_goals/reading_goal_form_widgets.dart';
import 'create_reading_goal_page.dart';
import 'reading_stats_page.dart';

enum _GoalsSection { ongoing, planned, finished }

/// Lists every reading goal, grouped by phase, with the entry point to
/// create a new one.
class ReadingGoalsPage extends StatefulWidget {
  static const routeName = '/reading-goals';

  const ReadingGoalsPage({super.key});

  @override
  State<ReadingGoalsPage> createState() => _ReadingGoalsPageState();
}

class _ReadingGoalsPageState extends State<ReadingGoalsPage> {
  var _section = _GoalsSection.ongoing;

  void _createGoal() {
    Navigator.pushNamed(
      context,
      CreateReadingGoalPage.routeName,
      arguments: const CreateReadingGoalArguments(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColor.surfaceDark : colorScheme.surface,
      appBar: AppBar(
        title: Text(
          localizations.readingGoals,
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
        actions: [
          IconButton(
            tooltip: localizations.statsTitle,
            icon: const Icon(Icons.insights_rounded),
            onPressed: () =>
                Navigator.pushNamed(context, ReadingStatsPage.routeName),
          ),
        ],
      ),
      floatingActionButton: BlocBuilder<ReadingGoalsCubit, ReadingGoalsState>(
        buildWhen: (previous, current) =>
            previous.hasGoals != current.hasGoals ||
            previous.isLoading != current.isLoading,
        builder: (context, state) {
          if (state.isLoading || !state.hasGoals) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton.extended(
            onPressed: _createGoal,
            icon: const Icon(Icons.add_rounded),
            label: Text(localizations.newReadingGoal),
          );
        },
      ),
      body: BlocBuilder<ReadingGoalsCubit, ReadingGoalsState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!state.hasGoals) {
            return _EmptyState(onCreate: _createGoal);
          }
          final List<ReadingGoalProgress> goals;
          switch (_section) {
            case _GoalsSection.ongoing:
              goals = state.ongoing;
            case _GoalsSection.planned:
              goals = state.planned;
            case _GoalsSection.finished:
              goals = state.finished;
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: SegmentedSwitch<_GoalsSection>(
                  value: _section,
                  options: [
                    (
                      _GoalsSection.ongoing,
                      _count(localizations.readingGoalsOngoing, state.ongoing),
                    ),
                    (
                      _GoalsSection.planned,
                      _count(localizations.readingGoalsPlanned, state.planned),
                    ),
                    (
                      _GoalsSection.finished,
                      _count(
                        localizations.readingGoalsFinished,
                        state.finished,
                      ),
                    ),
                  ],
                  onChanged: (section) => setState(() => _section = section),
                ),
              ),
              Expanded(
                child: goals.isEmpty
                    ? Center(
                        child: Text(
                          localizations.noReadingGoalsInSection,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      )
                    : ListView.builder(
                        key: PageStorageKey<String>('reading-goals-$_section'),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                        itemCount: goals.length,
                        itemBuilder: (context, index) {
                          final progress = goals[index];
                          return ReadingGoalCard(
                            key: ValueKey(progress.goal.id),
                            progress: progress,
                            isFollowed: progress.goal.id == state.activeGoalId,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _count(String label, List<ReadingGoalProgress> goals) =>
      goals.isEmpty ? label : '$label (${goals.length})';
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flag_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              localizations.noReadingGoalsTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              localizations.noReadingGoalsDescription,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreate,
              style: FilledButton.styleFrom(
                minimumSize: const Size(220, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: Text(localizations.createReadingGoal),
            ),
          ],
        ),
      ),
    );
  }
}
