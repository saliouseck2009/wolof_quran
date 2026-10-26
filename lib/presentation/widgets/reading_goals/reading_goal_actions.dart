import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/navigation/create_reading_goal_arguments.dart';
import '../../../core/navigation/mushaf_arguments.dart';
import '../../../core/navigation/reading_goal_detail_arguments.dart';
import '../../../core/reading/local_date.dart';
import '../../../domain/entities/reading_goal.dart';
import '../../../domain/entities/reading_goal_progress.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../cubits/reading_goals_cubit.dart';
import '../../views/create_reading_goal_page.dart';
import '../../views/mushaf_page.dart';
import '../../views/reading_goal_detail_page.dart';
import '../snackbar.dart';
import 'mark_pages_sheet.dart';
import 'mark_section_sheet.dart';

enum ReadingGoalMenuAction {
  follow,
  markPages,
  markSection,
  rename,
  changeEndDate,
  pause,
  resume,
  reactivate,
  duplicate,
  edit,
  abandon,
  delete,
}

/// User actions on a reading goal, shared by the goal cards and the home
/// card: navigation, dialogs and the overflow menu.
class ReadingGoalActions {
  const ReadingGoalActions._();

  /// Follows [progress] in the mushaf and opens it at its next page.
  static Future<void> continueReading(
    BuildContext context,
    ReadingGoalProgress progress,
  ) async {
    final cubit = context.read<ReadingGoalsCubit>();
    if (progress.goal.status == ReadingGoalStatus.paused) {
      await cubit.resumeGoal(progress.goal.id);
    }
    await cubit.setActiveGoal(progress.goal.id);
    if (!context.mounted) {
      return;
    }
    final resumePage =
        cubit.state.progressOf(progress.goal.id)?.resumePage ??
        progress.resumePage;
    await Navigator.pushNamed(
      context,
      MushafPage.routeName,
      arguments: MushafArguments(initialPage: resumePage),
    );
  }

  static Future<void> markPages(
    BuildContext context,
    ReadingGoalProgress progress, {
    int? initialPage,
  }) async {
    final cubit = context.read<ReadingGoalsCubit>();
    final validation = await showMarkPagesSheet(
      context,
      progress: progress,
      initialPage: initialPage,
    );
    if (validation == null || !context.mounted) {
      return;
    }
    final localizations = AppLocalizations.of(context)!;
    CustomSnackbar.showSnackbarAction(
      context,
      localizations.pagesMarked(validation.pages.length),
      () => cubit.undoValidation(validation.id),
      actionLabel: localizations.undo,
    );
  }

  static Future<void> markSection(
    BuildContext context,
    ReadingGoalProgress progress, {
    int? currentPage,
  }) async {
    final cubit = context.read<ReadingGoalsCubit>();
    final validation = await showMarkSectionSheet(
      context,
      progress: progress,
      currentPage: currentPage,
    );
    if (validation == null || !context.mounted) {
      return;
    }
    final localizations = AppLocalizations.of(context)!;
    CustomSnackbar.showSnackbarAction(
      context,
      localizations.pagesMarked(validation.pages.length),
      () => cubit.undoValidation(validation.id),
      actionLabel: localizations.undo,
    );
  }

  static Future<void> openDetail(BuildContext context, String goalId) {
    return Navigator.pushNamed(
      context,
      ReadingGoalDetailPage.routeName,
      arguments: ReadingGoalDetailArguments(goalId: goalId),
    );
  }

  static Future<void> rename(BuildContext context, ReadingGoal goal) async {
    final localizations = AppLocalizations.of(context)!;
    final cubit = context.read<ReadingGoalsCubit>();
    final controller = TextEditingController(text: goal.name);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          localizations.renameGoal,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: localizations.goalName,
            hintText: localizations.goalNameHint,
          ),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(localizations.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: Text(
              localizations.goalSave,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name != null && name.trim().isNotEmpty) {
      await cubit.renameGoal(goal.id, name);
    }
  }

  static Future<void> changeEndDate(
    BuildContext context,
    ReadingGoal goal,
  ) async {
    final cubit = context.read<ReadingGoalsCubit>();
    final today = LocalDate.today();
    final earliest = today.isAfter(goal.startDate) ? today : goal.startDate;
    final current = goal.endDate.isBefore(earliest) ? earliest : goal.endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current.toDateTime(),
      firstDate: earliest.toDateTime(),
      lastDate: earliest.addDays(3650).toDateTime(),
    );
    if (picked == null) {
      return;
    }
    await cubit.updateDates(goal.id, endDate: LocalDate.fromDateTime(picked));
  }

  static Future<void> confirmAbandon(
    BuildContext context,
    ReadingGoal goal,
  ) async {
    final localizations = AppLocalizations.of(context)!;
    final confirmed = await _confirm(
      context,
      title: localizations.abandonGoalConfirmTitle,
      body: localizations.abandonGoalConfirmBody,
      actionLabel: localizations.abandonGoal,
    );
    if (confirmed && context.mounted) {
      await context.read<ReadingGoalsCubit>().abandonGoal(goal.id);
    }
  }

  static Future<void> confirmDelete(
    BuildContext context,
    ReadingGoal goal,
  ) async {
    final localizations = AppLocalizations.of(context)!;
    final confirmed = await _confirm(
      context,
      title: localizations.deleteGoalConfirmTitle,
      body: localizations.deleteGoalConfirmBody,
      actionLabel: localizations.delete,
    );
    if (confirmed && context.mounted) {
      await context.read<ReadingGoalsCubit>().deleteGoal(goal.id);
    }
  }

  static Future<void> duplicate(BuildContext context, ReadingGoal goal) {
    return Navigator.pushNamed(
      context,
      CreateReadingGoalPage.routeName,
      arguments: CreateReadingGoalArguments(template: goal),
    );
  }

  static Future<void> edit(BuildContext context, ReadingGoal goal) {
    return Navigator.pushNamed(
      context,
      CreateReadingGoalPage.routeName,
      arguments: CreateReadingGoalArguments(goalToEdit: goal),
    );
  }

  static Future<void> handleMenu(
    BuildContext context,
    ReadingGoalProgress progress,
    ReadingGoalMenuAction action,
  ) async {
    final cubit = context.read<ReadingGoalsCubit>();
    final goal = progress.goal;
    switch (action) {
      case ReadingGoalMenuAction.follow:
        await cubit.setActiveGoal(goal.id);
      case ReadingGoalMenuAction.markPages:
        await markPages(context, progress);
      case ReadingGoalMenuAction.markSection:
        await markSection(context, progress);
      case ReadingGoalMenuAction.rename:
        await rename(context, goal);
      case ReadingGoalMenuAction.changeEndDate:
        await changeEndDate(context, goal);
      case ReadingGoalMenuAction.pause:
        await cubit.pauseGoal(goal.id);
      case ReadingGoalMenuAction.resume:
        await cubit.resumeGoal(goal.id);
      case ReadingGoalMenuAction.reactivate:
        await cubit.reactivateGoal(goal.id);
      case ReadingGoalMenuAction.duplicate:
        await duplicate(context, goal);
      case ReadingGoalMenuAction.edit:
        await edit(context, goal);
      case ReadingGoalMenuAction.abandon:
        await confirmAbandon(context, goal);
      case ReadingGoalMenuAction.delete:
        await confirmDelete(context, goal);
    }
  }

  /// Overflow menu of a goal card, with the actions that make sense for
  /// its phase.
  static Widget menuButton(
    BuildContext context,
    ReadingGoalProgress progress, {
    required bool isFollowed,
    Color? iconColor,
  }) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final phase = progress.phase;
    final isFinished =
        phase == ReadingGoalPhase.completed ||
        phase == ReadingGoalPhase.abandoned;

    PopupMenuItem<ReadingGoalMenuAction> item(
      ReadingGoalMenuAction action,
      IconData icon,
      String label, {
      Color? color,
    }) {
      return PopupMenuItem(
        value: action,
        child: Row(
          children: [
            Icon(icon, size: 20, color: color ?? colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(color: color)),
          ],
        ),
      );
    }

    return PopupMenuButton<ReadingGoalMenuAction>(
      tooltip: MaterialLocalizations.of(context).showMenuTooltip,
      icon: Icon(Icons.more_vert_rounded, color: iconColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (action) => handleMenu(context, progress, action),
      itemBuilder: (_) => [
        if (!isFinished) ...[
          if (!isFollowed)
            item(
              ReadingGoalMenuAction.follow,
              Icons.auto_stories_rounded,
              localizations.followGoal,
            ),
          item(
            ReadingGoalMenuAction.markPages,
            Icons.playlist_add_check_rounded,
            localizations.markPagesRead,
          ),
          item(
            ReadingGoalMenuAction.markSection,
            Icons.menu_book_rounded,
            localizations.markSection,
          ),
          item(
            ReadingGoalMenuAction.rename,
            Icons.edit_outlined,
            localizations.renameGoal,
          ),
          item(
            ReadingGoalMenuAction.changeEndDate,
            Icons.event_outlined,
            localizations.changeEndDate,
          ),
          if (phase == ReadingGoalPhase.paused)
            item(
              ReadingGoalMenuAction.resume,
              Icons.play_arrow_rounded,
              localizations.resumeGoal,
            )
          else if (phase == ReadingGoalPhase.active)
            item(
              ReadingGoalMenuAction.pause,
              Icons.pause_rounded,
              localizations.pauseGoal,
            ),
        ] else
          item(
            ReadingGoalMenuAction.reactivate,
            Icons.replay_rounded,
            localizations.reactivateGoal,
          ),
        item(
          ReadingGoalMenuAction.duplicate,
          Icons.control_point_duplicate_rounded,
          localizations.duplicateGoal,
        ),
        const PopupMenuDivider(),
        if (!isFinished)
          item(
            ReadingGoalMenuAction.abandon,
            Icons.flag_outlined,
            localizations.abandonGoal,
          ),
        item(
          ReadingGoalMenuAction.delete,
          Icons.delete_outline_rounded,
          localizations.deleteGoal,
          color: colorScheme.error,
        ),
      ],
    );
  }

  static Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String actionLabel,
  }) async {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              localizations.cancel,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              actionLabel,
              style: TextStyle(
                color: colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
