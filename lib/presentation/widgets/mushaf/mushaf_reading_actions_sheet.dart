import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../cubits/reading_goals_cubit.dart';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocBuilder<ReadingGoalsCubit, ReadingGoalsState>(
      builder: (context, state) {
        final progress = state.activeProgress;
        final metrics = progress?.metrics;
        final isPageValidated = progress?.isValidated(currentPage) ?? false;

        void pick(MushafReadingAction action) =>
            Navigator.of(context).pop(action);

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 0, 20, navigationBarHeight + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          progress?.goal.name ?? localizations.freeReading,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          metrics == null
                              ? localizations.freeReadingDescription
                              : '${localizations.readingValidatedOf(metrics.validatedCount, metrics.totalPages)} · '
                                    '${metrics.isTodayTargetReached ? localizations.todayDoneShort : localizations.todayShort(metrics.readToday, metrics.todayTarget)}',
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
              if (metrics != null) ...[
                const SizedBox(height: 12),
                ReadingProgressBar(fraction: metrics.fraction),
              ],
              const SizedBox(height: 12),
              if (progress != null) ...[
                _ActionTile(
                  icon: isPageValidated
                      ? Icons.remove_done_rounded
                      : Icons.check_circle_outline_rounded,
                  label: isPageValidated
                      ? localizations.unmarkThisPage
                      : localizations.markThisPageRead,
                  detail: localizations.pageNumberLabel(currentPage),
                  onTap: () => pick(
                    isPageValidated
                        ? MushafReadingAction.unmarkPage
                        : MushafReadingAction.markPage,
                  ),
                ),
                _ActionTile(
                  icon: Icons.fact_check_outlined,
                  label: localizations.readUntilHere,
                  onTap: () => pick(MushafReadingAction.readUntilHere),
                ),
                _ActionTile(
                  icon: Icons.playlist_add_check_rounded,
                  label: localizations.markSeveralPages,
                  onTap: () => pick(MushafReadingAction.markSeveral),
                ),
                _ActionTile(
                  icon: Icons.menu_book_rounded,
                  label: localizations.markSection,
                  onTap: () => pick(MushafReadingAction.markSection),
                ),
                _ActionTile(
                  icon: Icons.insights_rounded,
                  label: localizations.viewProgress,
                  onTap: () => pick(MushafReadingAction.viewProgress),
                ),
                const Divider(height: 16),
                _ActionTile(
                  icon: Icons.swap_horiz_rounded,
                  label: localizations.switchGoal,
                  onTap: () => pick(MushafReadingAction.switchGoal),
                ),
                _ActionTile(
                  icon: Icons.explore_outlined,
                  label: localizations.switchToFreeReading,
                  onTap: () => pick(MushafReadingAction.freeReading),
                ),
              ] else ...[
                if (state.ongoing.isNotEmpty)
                  _ActionTile(
                    icon: Icons.flag_rounded,
                    label: localizations.followAGoal,
                    onTap: () => pick(MushafReadingAction.followGoal),
                  ),
                _ActionTile(
                  icon: Icons.add_rounded,
                  label: localizations.newReadingGoal,
                  onTap: () => pick(MushafReadingAction.createGoal),
                ),
                _ActionTile(
                  icon: Icons.insights_rounded,
                  label: localizations.readingGoals,
                  onTap: () => pick(MushafReadingAction.viewProgress),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? detail;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    this.detail,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: colorScheme.primary),
      ),
      title: Text(
        label,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: detail == null ? null : Text(detail!),
    );
  }
}
