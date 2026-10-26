import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/reading_goal_progress.dart';
import '../../../domain/entities/reading_validation.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../cubits/reading_goals_cubit.dart';
import 'page_picker_field.dart';
import 'reading_goal_form_widgets.dart';

/// Lets the user validate pages read outside the app in one goal, either
/// everything up to a page or an explicit range. Returns the journal entry,
/// or `null` when dismissed or nothing was added.
Future<ReadingValidation?> showMarkPagesSheet(
  BuildContext context, {
  required ReadingGoalProgress progress,
  int? initialPage,
}) {
  final navigationBarHeight = MediaQuery.viewPaddingOf(context).bottom;
  return showModalBottomSheet<ReadingValidation>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _MarkPagesSheet(
      goalId: progress.goal.id,
      initialPage: initialPage ?? progress.resumePage,
      navigationBarHeight: navigationBarHeight,
    ),
  );
}

enum _MarkMode { untilPage, range }

class _MarkPagesSheet extends StatefulWidget {
  final String goalId;
  final int initialPage;
  final double navigationBarHeight;

  const _MarkPagesSheet({
    required this.goalId,
    required this.initialPage,
    required this.navigationBarHeight,
  });

  @override
  State<_MarkPagesSheet> createState() => _MarkPagesSheetState();
}

class _MarkPagesSheetState extends State<_MarkPagesSheet> {
  var _mode = _MarkMode.untilPage;
  late int? _untilPage = widget.initialPage;
  late int? _fromPage = widget.initialPage;
  late int? _toPage = widget.initialPage;

  bool _isPage(int? page, int total) =>
      page != null && page >= 1 && page <= total;

  /// Pages the confirmation would add, and how many of the selection are
  /// already read.
  (List<int> added, int alreadyRead) _preview(
    ReadingGoalsCubit cubit,
    ReadingGoalProgress progress,
  ) {
    final total = progress.goal.totalPages;
    switch (_mode) {
      case _MarkMode.untilPage:
        if (!_isPage(_untilPage, total)) {
          return (const [], 0);
        }
        final added = cubit.pagesUntil(widget.goalId, _untilPage!);
        final first = progress.metrics.firstUnvalidatedPage;
        final selected = first == null
            ? 0
            : progress.goal.order.pagesBetween(first, _untilPage!).length;
        return (added, selected - added.length);
      case _MarkMode.range:
        if (!_isPage(_fromPage, total) || !_isPage(_toPage, total)) {
          return (const [], 0);
        }
        final selected = progress.goal.order.pagesBetween(_fromPage!, _toPage!);
        final added = selected
            .where((page) => !progress.isValidated(page))
            .toList();
        return (added, selected.length - added.length);
    }
  }

  Future<void> _confirm(ReadingGoalsCubit cubit) async {
    final ReadingValidation? validation;
    switch (_mode) {
      case _MarkMode.untilPage:
        validation = await cubit.readUntil(widget.goalId, _untilPage!);
      case _MarkMode.range:
        validation = await cubit.validateRange(
          widget.goalId,
          _fromPage!,
          _toPage!,
        );
    }
    if (mounted) {
      Navigator.of(context).pop(validation);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom > 0
        ? mediaQuery.viewInsets.bottom
        : widget.navigationBarHeight;

    return BlocBuilder<ReadingGoalsCubit, ReadingGoalsState>(
      builder: (context, state) {
        final cubit = context.read<ReadingGoalsCubit>();
        final progress = state.progressOf(widget.goalId);
        if (progress == null) {
          return const SizedBox.shrink();
        }
        final total = progress.goal.totalPages;
        final (added, alreadyRead) = _preview(cubit, progress);

        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset + 16),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
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
                            localizations.markPagesRead,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            progress.goal.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                const SizedBox(height: 16),
                SegmentedSwitch<_MarkMode>(
                  value: _mode,
                  options: [
                    (_MarkMode.untilPage, localizations.untilPageMode),
                    (_MarkMode.range, localizations.pageRangeMode),
                  ],
                  onChanged: (mode) => setState(() => _mode = mode),
                ),
                const SizedBox(height: 16),
                if (_mode == _MarkMode.untilPage) ...[
                  PagePickerField(
                    label: localizations.pageFieldLabel,
                    value: _untilPage,
                    totalPages: total,
                    onChanged: (page) => setState(() => _untilPage = page),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localizations.untilPageHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ] else ...[
                  PagePickerField(
                    label: localizations.fromPageLabel,
                    value: _fromPage,
                    totalPages: total,
                    onChanged: (page) => setState(() => _fromPage = page),
                  ),
                  const SizedBox(height: 12),
                  PagePickerField(
                    label: localizations.toPageLabel,
                    value: _toPage,
                    totalPages: total,
                    onChanged: (page) => setState(() => _toPage = page),
                  ),
                ],
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_stories_rounded,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          alreadyRead > 0
                              ? '${localizations.pagesToMarkSummary(added.length)} · '
                                    '${localizations.pagesAlreadyRead(alreadyRead)}'
                              : localizations.pagesToMarkSummary(added.length),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: added.isEmpty ? null : () => _confirm(cubit),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  icon: const Icon(Icons.check_rounded),
                  label: Text(localizations.markAsRead),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
