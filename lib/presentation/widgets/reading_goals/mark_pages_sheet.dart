import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart' as quran;

import '../../../core/mushaf/quran_page_data.dart';
import '../../../core/reading/quran_sections.dart';
import '../../../domain/entities/reading_goal_progress.dart';
import '../../../domain/entities/reading_validation.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../cubits/reading_goals_cubit.dart';
import 'page_picker_field.dart';
import 'reading_goal_form_widgets.dart';
import 'surah_picker_sheet.dart';

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
  late int _untilPage = widget.initialPage;
  late int? _fromPage = widget.initialPage;
  late int? _toPage = widget.initialPage;

  bool _isPage(int? page, int total) =>
      page != null && page >= 1 && page <= total;

  bool _isInverted(ReadingGoalProgress progress) =>
      _isPage(_fromPage, progress.goal.totalPages) &&
      _isPage(_toPage, progress.goal.totalPages) &&
      progress.goal.order.isBefore(_toPage!, _fromPage!);

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
        final added = cubit.pagesUntil(widget.goalId, _untilPage);
        final order = progress.goal.order;
        final first = progress.metrics.firstUnvalidatedPage;
        if (first == null || order.isBefore(_untilPage, first)) {
          // Every page up to the cursor is already read.
          return (added, order.indexOf(_untilPage) + 1);
        }
        final selected = order.pagesBetween(first, _untilPage).length;
        return (added, selected - added.length);
      case _MarkMode.range:
        if (!_isPage(_fromPage, total) ||
            !_isPage(_toPage, total) ||
            _isInverted(progress)) {
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
        validation = await cubit.readUntil(widget.goalId, _untilPage);
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
        final (added, alreadyRead) = _preview(cubit, progress);
        final inverted = _mode == _MarkMode.range && _isInverted(progress);
        final continuous = progress.metrics.continuousProgress;
        final lastRead = continuous == 0
            ? null
            : progress.goal.order.pageAt(continuous - 1);

        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset + 16),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SheetHeader(
                  title: localizations.markPagesShort,
                  subtitle: lastRead == null
                      ? progress.goal.name
                      : '${progress.goal.name} · ${localizations.lastPageReadLabel(lastRead)}',
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
                const SizedBox(height: 18),
                if (_mode == _MarkMode.untilPage)
                  _buildUntilPage(context, localizations, progress)
                else
                  _buildRange(context, localizations, progress),
                const SizedBox(height: 16),
                _InfoRow(
                  icon: inverted
                      ? Icons.warning_amber_rounded
                      : Icons.info_outline_rounded,
                  warning: inverted,
                  text: inverted
                      ? localizations.rangeInverted
                      : added.isEmpty &&
                            alreadyRead == 0 &&
                            _mode == _MarkMode.untilPage
                      ? localizations.untilPageHint
                      : alreadyRead > 0
                      ? '${localizations.pagesToMarkSummary(added.length)} · '
                            '${localizations.pagesAlreadyRead(alreadyRead)}'
                      : localizations.pagesToMarkSummary(added.length),
                ),
                const SizedBox(height: 18),
                PrimaryActionButton(
                  label: localizations.markAsRead,
                  icon: Icons.check_rounded,
                  onPressed: added.isEmpty ? null : () => _confirm(cubit),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUntilPage(
    BuildContext context,
    AppLocalizations localizations,
    ReadingGoalProgress progress,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final total = progress.goal.totalPages;
    final order = progress.goal.order;
    final info = getPageInfo(_untilPage);

    void setPage(int page) => setState(() => _untilPage = page.clamp(1, total));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$_untilPage',
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                localizations.pageOfTotal(total),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: [
                  _RoundButton(
                    icon: Icons.remove_rounded,
                    filled: false,
                    onTap: _untilPage > 1
                        ? () => setPage(_untilPage - 1)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  _RoundButton(
                    icon: Icons.add_rounded,
                    filled: true,
                    onTap: _untilPage < total
                        ? () => setPage(_untilPage + 1)
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () async {
            final surah = await showSurahPickerSheet(
              context,
              selectedSurah: info.primarySurahNumber,
            );
            if (surah != null && mounted) {
              setPage(getFirstPageOfSurah(surah));
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bookmark_border_rounded,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '${localizations.juzLabel(info.juzNumber)} · ${quran.getSurahName(info.primarySurahNumber)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.expand_more_rounded,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        _SliderTheme(
          child: Slider(
            value: _untilPage.toDouble(),
            min: 1,
            max: total.toDouble(),
            divisions: total - 1,
            onChanged: (value) => setPage(value.round()),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1', style: _edgeLabelStyle(theme)),
              Text('$total', style: _edgeLabelStyle(theme)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _QuickJumpChip(
                label: localizations.juzEndChip,
                onTap: () => setPage(
                  QuranSections.nextEndAfter(
                    QuranSectionType.juz,
                    _untilPage,
                    order,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _QuickJumpChip(
                label: localizations.hizbEndChip,
                onTap: () => setPage(
                  QuranSections.nextEndAfter(
                    QuranSectionType.hizb,
                    _untilPage,
                    order,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _QuickJumpChip(
                label: localizations.surahEndChip,
                onTap: () => setPage(
                  QuranSections.nextEndAfter(
                    QuranSectionType.surah,
                    _untilPage,
                    order,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRange(
    BuildContext context,
    AppLocalizations localizations,
    ReadingGoalProgress progress,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final total = progress.goal.totalPages;
    final order = progress.goal.order;
    final hasBoth = _isPage(_fromPage, total) && _isPage(_toPage, total);
    final fromIndex = hasBoth ? order.indexOf(_fromPage!) : 0;
    final toIndex = hasBoth ? order.indexOf(_toPage!) : total - 1;
    final lowIndex = fromIndex < toIndex ? fromIndex : toIndex;
    final highIndex = fromIndex < toIndex ? toIndex : fromIndex;
    final inverted = _isInverted(progress);
    final count = hasBoth && !inverted ? highIndex - lowIndex + 1 : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PagePickerField(
          label: localizations.fromPageLabel,
          value: _fromPage,
          totalPages: total,
          onChanged: (page) => setState(() => _fromPage = page),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          decoration: BoxDecoration(
            color: colorScheme.onSurface.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    localizations.pageNumberLabel(
                      hasBoth ? order.pageAt(lowIndex) : 1,
                    ),
                    style: _edgeLabelStyle(theme),
                  ),
                  Text(
                    localizations.pageNumberLabel(
                      hasBoth ? order.pageAt(highIndex) : total,
                    ),
                    style: _edgeLabelStyle(theme),
                  ),
                ],
              ),
              _SliderTheme(
                child: RangeSlider(
                  values: RangeValues(
                    lowIndex.toDouble(),
                    highIndex.toDouble(),
                  ),
                  min: 0,
                  max: (total - 1).toDouble(),
                  divisions: total - 1,
                  onChanged: (values) => setState(() {
                    _fromPage = order.pageAt(values.start.round());
                    _toPage = order.pageAt(values.end.round());
                  }),
                ),
              ),
              Text(
                '— ${localizations.pagesInRange(count)} —',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: inverted
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        PagePickerField(
          label: localizations.toPageLabel,
          value: _toPage,
          totalPages: total,
          onChanged: (page) => setState(() => _toPage = page),
        ),
      ],
    );
  }

  static TextStyle? _edgeLabelStyle(ThemeData theme) =>
      theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      );
}

class _SliderTheme extends StatelessWidget {
  final Widget child;

  const _SliderTheme({required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 4,
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.onSurface.withValues(alpha: 0.1),
        thumbColor: colorScheme.surface,
        overlayColor: colorScheme.primary.withValues(alpha: 0.12),
        thumbShape: const _OutlinedThumb(),
        rangeThumbShape: const _OutlinedRangeThumb(),
        showValueIndicator: ShowValueIndicator.never,
        trackShape: const _PaddedTrackShape(),
        activeTickMarkColor: Colors.transparent,
        inactiveTickMarkColor: Colors.transparent,
      ),
      child: child,
    );
  }
}

class _PaddedTrackShape extends RoundedRectSliderTrackShape {
  const _PaddedTrackShape();

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final height = sliderTheme.trackHeight ?? 4;
    final top = offset.dy + (parentBox.size.height - height) / 2;
    return Rect.fromLTWH(
      offset.dx + 12,
      top,
      parentBox.size.width - 24,
      height,
    );
  }
}

void _paintThumb(Canvas canvas, Offset center, Color fill, Color ring) {
  canvas.drawCircle(
    center,
    12,
    Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
  );
  canvas.drawCircle(center, 11, Paint()..color = fill);
  canvas.drawCircle(
    center,
    11,
    Paint()
      ..color = ring
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3,
  );
}

class _OutlinedThumb extends SliderComponentShape {
  const _OutlinedThumb();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(24, 24);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    _paintThumb(
      context.canvas,
      center,
      sliderTheme.thumbColor ?? Colors.white,
      sliderTheme.activeTrackColor ?? Colors.green,
    );
  }
}

class _OutlinedRangeThumb extends RangeSliderThumbShape {
  const _OutlinedRangeThumb();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(24, 24);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    bool isDiscrete = false,
    bool isEnabled = false,
    bool? isOnTop,
    TextDirection? textDirection,
    required SliderThemeData sliderTheme,
    Thumb? thumb,
    bool? isPressed,
  }) {
    _paintThumb(
      context.canvas,
      center,
      sliderTheme.thumbColor ?? Colors.white,
      sliderTheme.activeTrackColor ?? Colors.green,
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final bool filled;
  final VoidCallback? onTap;

  const _RoundButton({
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final enabled = onTap != null;
    return Material(
      color: filled
          ? colorScheme.primary.withValues(alpha: enabled ? 1 : 0.4)
          : colorScheme.onSurface.withValues(alpha: 0.06),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            size: 22,
            color: filled
                ? colorScheme.onPrimary
                : colorScheme.onSurface.withValues(alpha: enabled ? 0.8 : 0.3),
          ),
        ),
      ),
    );
  }
}

class _QuickJumpChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickJumpChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: theme.colorScheme.onSurface,
        textStyle: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool warning;

  const _InfoRow({
    required this.icon,
    required this.text,
    required this.warning,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tint = warning ? colorScheme.secondary : colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: warning
            ? colorScheme.secondary.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: warning
            ? Border.all(color: colorScheme.secondary.withValues(alpha: 0.5))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: tint),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: warning ? colorScheme.onSurface : tint,
                fontWeight: warning ? FontWeight.w600 : FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
