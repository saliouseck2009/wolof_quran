import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/config/theme/app_color.dart';
import '../../core/mushaf/quran_page_data.dart';
import '../../core/navigation/create_reading_goal_arguments.dart';
import '../../core/reading/local_date.dart';
import '../../core/reading/reading_plan_calculator.dart';
import '../../data/repositories/mushaf_repository.dart';
import '../../domain/entities/reading_goal.dart';
import '../../l10n/generated/app_localizations.dart';
import '../cubits/reading_goals_cubit.dart';
import '../utils/reading_goal_formatting.dart';
import '../widgets/reading_goals/page_picker_field.dart';
import '../widgets/reading_goals/reading_goal_form_widgets.dart';
import '../widgets/reading_goals/reminder_settings_sheet.dart';

enum _DurationMode { preset, custom, endDate }

enum _StartPoint { beginning, currentPage, chosenPage }

enum _Step { form, summary }

const _durationPresets = [7, 15, 30, 60, 90];

/// Two-step form creating (or editing) a reading goal: settings, then a
/// summary to confirm.
class CreateReadingGoalPage extends StatefulWidget {
  static const routeName = '/reading-goals/new';

  final CreateReadingGoalArguments arguments;

  const CreateReadingGoalPage({super.key, required this.arguments});

  @override
  State<CreateReadingGoalPage> createState() => _CreateReadingGoalPageState();
}

class _CreateReadingGoalPageState extends State<CreateReadingGoalPage> {
  final _mushafRepository = MushafRepository();
  late final TextEditingController _nameController;

  var _step = _Step.form;
  var _durationMode = _DurationMode.preset;
  var _days = 30;
  LocalDate? _pickedEndDate;
  var _startPoint = _StartPoint.beginning;
  int? _chosenPage;
  int _currentMushafPage = 1;
  late LocalDate _startDate;
  var _isSaving = false;
  var _reminder = const ReminderSettings();

  ReadingGoal? get _editing => widget.arguments.goalToEdit;

  bool get _isEdit => _editing != null;

  @override
  void initState() {
    super.initState();
    final today = LocalDate.today();
    final source = _editing ?? widget.arguments.template;
    _nameController = TextEditingController(text: source?.name ?? '');
    if (source != null) {
      _reminder = source.reminder;
      _startDate = _isEdit ? source.startDate : today;
      _days = source.durationDays;
      if (!_durationPresets.contains(_days)) {
        _durationMode = _DurationMode.custom;
      }
      _startPoint = source.startPage == 1
          ? _StartPoint.beginning
          : _StartPoint.chosenPage;
      _chosenPage = source.startPage;
    } else {
      _startDate = today;
    }
    _mushafRepository.getLastReadPage().then((page) {
      if (mounted) {
        setState(() => _currentMushafPage = page);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Derived values
  // ---------------------------------------------------------------------------

  int get _totalPages =>
      _editing?.totalPages ?? context.read<ReadingGoalsCubit>().totalPages;

  LocalDate get _endDate {
    switch (_durationMode) {
      case _DurationMode.preset:
      case _DurationMode.custom:
        return _startDate.addDays(_days - 1);
      case _DurationMode.endDate:
        final picked = _pickedEndDate;
        return picked == null || picked.isBefore(_startDate)
            ? _startDate
            : picked;
    }
  }

  int get _durationDays => _startDate.daysUntil(_endDate) + 1;

  int get _startPage {
    switch (_startPoint) {
      case _StartPoint.beginning:
        return 1;
      case _StartPoint.currentPage:
        return _currentMushafPage;
      case _StartPoint.chosenPage:
        return _chosenPage ?? 1;
    }
  }

  bool get _isStartPageValid =>
      _startPoint != _StartPoint.chosenPage ||
      (_chosenPage != null && _chosenPage! >= 1 && _chosenPage! <= _totalPages);

  bool get _isDurationValid =>
      _durationMode != _DurationMode.custom || _days >= 1;

  bool get _isFormValid => _isStartPageValid && _isDurationValid;

  String _resolvedName(AppLocalizations localizations) {
    final typed = _nameController.text.trim();
    if (typed.isNotEmpty) {
      return typed;
    }
    final count = context.read<ReadingGoalsCubit>().state.goals.length;
    return localizations.defaultGoalName(count + 1);
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _pickEndDate() async {
    final initial = _pickedEndDate ?? _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.toDateTime(),
      firstDate: _startDate.toDateTime(),
      lastDate: _startDate.addDays(3650).toDateTime(),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _durationMode = _DurationMode.endDate;
      _pickedEndDate = LocalDate.fromDateTime(picked);
    });
  }

  Future<void> _pickStartDate() async {
    final today = LocalDate.today();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate.toDateTime(),
      firstDate: today.toDateTime(),
      lastDate: today.addDays(365).toDateTime(),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _startDate = LocalDate.fromDateTime(picked));
  }

  Future<void> _submit() async {
    final localizations = AppLocalizations.of(context)!;
    final cubit = context.read<ReadingGoalsCubit>();
    setState(() => _isSaving = true);
    final editing = _editing;
    if (editing != null) {
      await cubit.renameGoal(editing.id, _resolvedName(localizations));
      await cubit.updateDates(
        editing.id,
        startDate: _startDate,
        endDate: _endDate,
      );
      await cubit.updateReminder(editing.id, _reminder);
    } else {
      await cubit.createGoal(
        name: _resolvedName(localizations),
        startPage: _startPage,
        startDate: _startDate,
        endDate: _endDate,
        reminder: _reminder,
      );
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return PopScope(
      canPop: _step == _Step.form,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          setState(() => _step = _Step.form);
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColor.surfaceDark : colorScheme.surface,
        appBar: AppBar(
          title: Text(
            _step == _Step.summary
                ? localizations.goalSummary
                : _isEdit
                ? localizations.editReadingGoal
                : localizations.newReadingGoal,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colorScheme.onPrimary,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          backgroundColor: isDark ? AppColor.surfaceDark : colorScheme.primary,
          iconTheme: IconThemeData(color: colorScheme.onPrimary),
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () {
              if (_step == _Step.summary) {
                setState(() => _step = _Step.form);
              } else {
                Navigator.of(context).maybePop();
              }
            },
          ),
        ),
        body: SafeArea(
          bottom: false,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            child: _step == _Step.form
                ? _buildForm(context, localizations)
                : _buildSummary(context, localizations),
          ),
        ),
        bottomNavigationBar: _BottomBar(
          child: _step == _Step.form
              ? PrimaryActionButton(
                  label: localizations.nextStep,
                  icon: Icons.arrow_forward_rounded,
                  iconLeading: false,
                  onPressed: _isFormValid
                      ? () {
                          FocusScope.of(context).unfocus();
                          setState(() => _step = _Step.summary);
                        }
                      : null,
                )
              : PrimaryActionButton(
                  label: _isEdit
                      ? localizations.goalSave
                      : localizations.goalCreate,
                  icon: _isEdit ? Icons.save_outlined : Icons.check_rounded,
                  onPressed: _isSaving ? null : _submit,
                ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, AppLocalizations localizations) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isPlanned =
        _editing == null || LocalDate.today().isBefore(_editing!.startDate);
    final today = LocalDate.today();
    final average = ReadingPlanCalculator.averagePagesPerDay(
      totalPages: _totalPages,
      startDate: _startDate,
      endDate: _endDate,
    );

    Widget durationChip(int days) => QuickChoiceChip(
      expanded: true,
      label: localizations.durationDays(days),
      selected: _durationMode == _DurationMode.preset && _days == days,
      onTap: () => setState(() {
        _durationMode = _DurationMode.preset;
        _days = days;
      }),
    );

    return ListView(
      key: const ValueKey('form'),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        FormSectionLabel(localizations.goalName),
        TextField(
          controller: _nameController,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            hintText: localizations.goalNameHint,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 26),
        FormSectionLabel(localizations.goalDuration),
        Row(
          children: [
            for (final days in _durationPresets.take(3)) ...[
              if (days != _durationPresets.first) const SizedBox(width: 8),
              Expanded(child: durationChip(days)),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final days in _durationPresets.skip(3)) ...[
              Expanded(child: durationChip(days)),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: QuickChoiceChip(
                expanded: true,
                label: localizations.customDuration,
                icon: Icons.tune_rounded,
                selected: _durationMode == _DurationMode.custom,
                onTap: () =>
                    setState(() => _durationMode = _DurationMode.custom),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        QuickChoiceChip(
          expanded: true,
          label: _durationMode == _DurationMode.endDate
              ? ReadingGoalFormatting.date(context, _endDate)
              : localizations.pickEndDateAction,
          icon: Icons.event_outlined,
          selected: _durationMode == _DurationMode.endDate,
          onTap: _pickEndDate,
        ),
        if (_durationMode == _DurationMode.custom) ...[
          const SizedBox(height: 12),
          _CustomDurationCard(
            days: _days,
            onChanged: (days) => setState(() => _days = days),
          ),
        ],
        const SizedBox(height: 12),
        _InfoLine(
          icon: Icons.schedule_rounded,
          text:
              '${localizations.pagesPerDayApprox(ReadingGoalFormatting.average(context, average))} · '
              '${localizations.durationDays(_durationDays)} · '
              '${localizations.readingEndsOn(ReadingGoalFormatting.date(context, _endDate))}',
          emphasis: localizations.pagesPerDayApprox(
            ReadingGoalFormatting.average(context, average),
          ),
        ),
        if (!_isEdit) ...[
          const SizedBox(height: 26),
          FormSectionLabel(localizations.goalStartPoint),
          SegmentedSwitch<_StartPoint>(
            value: _startPoint,
            options: [
              (_StartPoint.beginning, localizations.startFromBeginning),
              (_StartPoint.currentPage, localizations.startFromCurrentPage),
              (_StartPoint.chosenPage, localizations.startFromChosenPage),
            ],
            onChanged: (point) => setState(() {
              _startPoint = point;
              _chosenPage ??= _currentMushafPage;
            }),
          ),
          const SizedBox(height: 12),
          if (_startPoint == _StartPoint.chosenPage)
            PagePickerField(
              label: localizations.pageFieldLabel,
              value: _chosenPage,
              totalPages: _totalPages,
              onChanged: (page) => setState(() => _chosenPage = page),
            )
          else
            Text(
              '${localizations.pageNumberLabel(_startPage)} · '
              '${quran.getSurahName(getPageInfo(_startPage).primarySurahNumber)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
        ],
        if (isPlanned) ...[
          const SizedBox(height: 26),
          FormSectionLabel(localizations.goalStartDate),
          Row(
            children: [
              Expanded(
                child: QuickChoiceChip(
                  expanded: true,
                  label: localizations.today,
                  selected: _startDate == today,
                  onTap: () => setState(() => _startDate = today),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: QuickChoiceChip(
                  expanded: true,
                  label: _startDate == today
                      ? localizations.chooseShort
                      : ReadingGoalFormatting.date(context, _startDate),
                  icon: Icons.event_outlined,
                  selected: _startDate != today,
                  onTap: _pickStartDate,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSummary(BuildContext context, AppLocalizations localizations) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final average = ReadingPlanCalculator.averagePagesPerDay(
      totalPages: _totalPages,
      startDate: _startDate,
      endDate: _endDate,
    );
    final startInfo = getPageInfo(_startPage);

    Widget row(IconData icon, String label, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: colorScheme.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      key: const ValueKey('summary'),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Text(
          _resolvedName(localizations),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.surfaceContainerLow
                : colorScheme.onPrimary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              row(
                Icons.auto_stories_rounded,
                localizations.pagesToRead,
                '$_totalPages',
              ),
              row(
                Icons.timer_outlined,
                localizations.goalDuration,
                localizations.durationDays(_durationDays),
              ),
              row(
                Icons.speed_rounded,
                localizations.averagePerDay(
                  ReadingGoalFormatting.average(context, average),
                ),
                '',
              ),
              row(
                Icons.play_circle_outline_rounded,
                localizations.goalStartPoint,
                '${localizations.pageNumberLabel(_startPage)} · '
                '${quran.getSurahName(startInfo.primarySurahNumber)}',
              ),
              row(
                Icons.event_outlined,
                localizations.goalStartDate,
                ReadingGoalFormatting.date(context, _startDate),
              ),
              row(
                Icons.event_available_outlined,
                localizations.pickEndDate,
                ReadingGoalFormatting.date(context, _endDate),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _ReminderCard(
          reminder: _reminder,
          onChanged: (reminder) => setState(() => _reminder = reminder),
        ),
      ],
    );
  }
}

/// Slider card for a custom duration, 1 to 365 days.
class _CustomDurationCard extends StatelessWidget {
  final int days;
  final ValueChanged<int> onChanged;

  const _CustomDurationCard({required this.days, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final max = days > 365 ? days : 365;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    localizations.customDurationLabel.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              Text(
                '$days',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.primary,
                  height: 1,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  localizations.daysUnit(days),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          GoalSliderTheme(
            child: Slider(
              value: days.toDouble(),
              min: 1,
              max: max.toDouble(),
              divisions: max - 1,
              onChanged: (value) => onChanged(value.round()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localizations.durationDays(1),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  localizations.durationDays(max),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
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

/// Small line with an icon, the first part of [text] in bold.
class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final String emphasis;

  const _InfoLine({
    required this.icon,
    required this.text,
    required this.emphasis,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final base = theme.textTheme.bodySmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );
    final rest = text.startsWith(emphasis)
        ? text.substring(emphasis.length)
        : text;

    return Row(
      children: [
        Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                if (text.startsWith(emphasis))
                  TextSpan(
                    text: emphasis,
                    style: base?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                TextSpan(text: rest),
              ],
            ),
            style: base,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Pinned bottom area holding the main action of the page.
class _BottomBar extends StatelessWidget {
  final Widget child;

  const _BottomBar({required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColor.surfaceDark : colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.12)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: child,
        ),
      ),
    );
  }
}

/// Optional daily reminder, set while creating or editing a goal.
class _ReminderCard extends StatelessWidget {
  final ReminderSettings reminder;
  final ValueChanged<ReminderSettings> onChanged;

  const _ReminderCard({required this.reminder, required this.onChanged});

  Future<void> _toggle(BuildContext context, bool on) async {
    if (on && !await enableRemindersGlobally(context)) {
      return;
    }
    onChanged(reminder.copyWith(enabled: on));
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: reminder.hour, minute: reminder.minute),
    );
    if (picked != null) {
      onChanged(reminder.copyWith(hour: picked.hour, minute: picked.minute));
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final time = TimeOfDay(hour: reminder.hour, minute: reminder.minute);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerLow : colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: reminder.enabled,
            onChanged: (on) => _toggle(context, on),
            title: Text(
              localizations.reminderDaily,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(localizations.reminderSheetHint),
          ),
          if (reminder.enabled)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule_rounded),
              title: Text(localizations.reminderTime),
              trailing: Text(
                time.format(context),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
              onTap: () => _pickTime(context),
            ),
        ],
      ),
    );
  }
}
