import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart' as quran;

import '../../../core/reading/quran_sections.dart';
import '../../../domain/entities/reading_goal_progress.dart';
import '../../../domain/entities/reading_validation.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../cubits/reading_goals_cubit.dart';
import 'reading_goal_form_widgets.dart';

/// Lets the user mark a whole juz, hizb or surah as read in one goal.
/// Pages shared with a neighbouring section are listed for explicit
/// confirmation. Returns the journal entry, or `null`.
Future<ReadingValidation?> showMarkSectionSheet(
  BuildContext context, {
  required ReadingGoalProgress progress,
  int? currentPage,
}) {
  final navigationBarHeight = MediaQuery.viewPaddingOf(context).bottom;
  return showModalBottomSheet<ReadingValidation>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _MarkSectionSheet(
      goalId: progress.goal.id,
      currentPage: currentPage,
      navigationBarHeight: navigationBarHeight,
    ),
  );
}

String sectionLabel(
  AppLocalizations localizations,
  QuranSectionType type,
  int number,
) {
  switch (type) {
    case QuranSectionType.juz:
      return localizations.juzLabel(number);
    case QuranSectionType.hizb:
      return localizations.hizbFull(number);
    case QuranSectionType.surah:
      return '$number. ${quran.getSurahName(number)}';
  }
}

class _MarkSectionSheet extends StatefulWidget {
  final String goalId;
  final int? currentPage;
  final double navigationBarHeight;

  const _MarkSectionSheet({
    required this.goalId,
    required this.currentPage,
    required this.navigationBarHeight,
  });

  @override
  State<_MarkSectionSheet> createState() => _MarkSectionSheetState();
}

class _MarkSectionSheetState extends State<_MarkSectionSheet> {
  var _type = QuranSectionType.juz;
  QuranSection? _selected;
  var _includeSharedFirst = true;
  var _includeSharedLast = true;

  void _select(QuranSection section) {
    setState(() {
      _selected = section;
      _includeSharedFirst = true;
      _includeSharedLast = true;
    });
  }

  Future<void> _confirm(ReadingGoalsCubit cubit, QuranSection section) async {
    final pages = section.pagesIncluding(
      sharedFirst: _includeSharedFirst,
      sharedLast: _includeSharedLast,
    );
    final action = switch (section.type) {
      QuranSectionType.juz => ReadingValidationAction.juz,
      QuranSectionType.hizb => ReadingValidationAction.hizb,
      QuranSectionType.surah => ReadingValidationAction.surah,
    };
    final validation = await cubit.validatePages(
      goalId: widget.goalId,
      pages: pages,
      source: ReadingValidationSource.manual,
      action: action,
      fromPage: pages.isEmpty ? null : pages.first,
      toPage: pages.isEmpty ? null : pages.last,
    );
    if (mounted) {
      Navigator.of(context).pop(validation);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final height = MediaQuery.sizeOf(context).height * 0.8;

    return BlocBuilder<ReadingGoalsCubit, ReadingGoalsState>(
      builder: (context, state) {
        final progress = state.progressOf(widget.goalId);
        if (progress == null) {
          return const SizedBox.shrink();
        }
        final selected = _selected;
        return SizedBox(
          height: height,
          child: Padding(
            padding: EdgeInsets.only(bottom: widget.navigationBarHeight + 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Row(
                    children: [
                      if (selected != null) ...[
                        IconButton.filledTonal(
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).backButtonTooltip,
                          onPressed: () => setState(() => _selected = null),
                          icon: const Icon(Icons.arrow_back_rounded, size: 20),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selected == null
                                  ? localizations.markSection
                                  : sectionLabel(
                                      localizations,
                                      selected.type,
                                      selected.number,
                                    ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                ),
                Expanded(
                  child: selected == null
                      ? _buildList(context, progress)
                      : _buildConfirm(context, progress, selected),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildList(BuildContext context, ReadingGoalProgress progress) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sections = QuranSections.of(_type);
    final currentPage = widget.currentPage;
    final currentIndex = currentPage == null
        ? -1
        : sections.indexWhere(
            (s) => currentPage >= s.firstPage && currentPage <= s.lastPage,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: SegmentedSwitch<QuranSectionType>(
            value: _type,
            options: [
              (QuranSectionType.juz, localizations.sectionJuz),
              (QuranSectionType.hizb, localizations.sectionHizb),
              (QuranSectionType.surah, localizations.sectionSurah),
            ],
            onChanged: (type) => setState(() => _type = type),
          ),
        ),
        Expanded(
          child: ListView.builder(
            key: PageStorageKey<String>('sections-${_type.name}'),
            controller: ScrollController(
              initialScrollOffset: currentIndex > 2
                  ? (currentIndex - 2) * 64.0
                  : 0,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemExtent: 64,
            itemCount: sections.length,
            itemBuilder: (context, index) {
              final section = sections[index];
              final read = section.pages.where(progress.isValidated).length;
              final complete = read == section.pageCount;
              final isCurrent = index == currentIndex;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Material(
                  color: isCurrent
                      ? colorScheme.primaryContainer.withValues(alpha: 0.4)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _select(section),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: complete
                                  ? colorScheme.primary
                                  : colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: complete
                                ? Icon(
                                    Icons.check_rounded,
                                    size: 18,
                                    color: colorScheme.onPrimary,
                                  )
                                : Text(
                                    '${section.number}',
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sectionLabel(
                                    localizations,
                                    section.type,
                                    section.number,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${localizations.pageRangeLabel(section.firstPage, section.lastPage)} · '
                                  '$read/${section.pageCount}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildConfirm(
    BuildContext context,
    ReadingGoalProgress progress,
    QuranSection section,
  ) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cubit = context.read<ReadingGoalsCubit>();
    final pages = section.pagesIncluding(
      sharedFirst: _includeSharedFirst,
      sharedLast: _includeSharedLast,
    );
    final newPages = pages.where((p) => !progress.isValidated(p)).length;
    final alreadyRead = pages.length - newPages;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        Text(
          localizations.sectionPagesSummary(
            localizations.pageRangeLabel(section.firstPage, section.lastPage),
            localizations.pagesCount(section.pageCount),
          ),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        if (section.sharesFirstPage) ...[
          const SizedBox(height: 12),
          _SharedPageTile(
            note: localizations.sharedPagePrevious(section.firstPage),
            label: localizations.includePage(section.firstPage),
            value: _includeSharedFirst,
            onChanged: (value) => setState(() => _includeSharedFirst = value),
          ),
        ],
        if (section.sharesLastPage) ...[
          const SizedBox(height: 12),
          _SharedPageTile(
            note: localizations.sharedPageNext(section.lastPage),
            label: localizations.includePage(section.lastPage),
            value: _includeSharedLast,
            onChanged: (value) => setState(() => _includeSharedLast = value),
          ),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                      ? '${localizations.pagesToMarkSummary(newPages)} · '
                            '${localizations.pagesAlreadyRead(alreadyRead)}'
                      : localizations.pagesToMarkSummary(newPages),
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
          onPressed: newPages == 0 ? null : () => _confirm(cubit, section),
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
          label: Text(
            localizations.markSectionConfirm(
              sectionLabel(localizations, section.type, section.number),
            ),
          ),
        ),
      ],
    );
  }
}

class _SharedPageTile extends StatelessWidget {
  final String note;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SharedPageTile({
    required this.note,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 6),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: colorScheme.secondary,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(note, style: theme.textTheme.bodySmall)),
            ],
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            value: value,
            onChanged: (checked) => onChanged(checked ?? false),
            title: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
