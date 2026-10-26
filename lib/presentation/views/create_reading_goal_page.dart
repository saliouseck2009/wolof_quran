import 'package:flutter/material.dart';
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

  ReadingGoal? get _editing => widget.arguments.goalToEdit;

  bool get _isEdit => _editing != null;

  @override
  void initState() {
    super.initState();
    final today = LocalDate.today();
    final source = _editing ?? widget.arguments.template;
    _nameController = TextEditingController(text: source?.name ?? '');
    if (source != null) {
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
    } else {
      await cubit.createGoal(
        name: _resolvedName(localizations),
        startPage: _startPage,
        startDate: _startDate,
        endDate: _endDate,
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
          centerTitle: false,
          backgroundColor: isDark ? AppColor.surfaceDark : colorScheme.primary,
          iconTheme: IconThemeData(color: colorScheme.onPrimary),
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: _step == _Step.summary
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => setState(() => _step = _Step.form),
                )
              : null,
        ),
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            child: _step == _Step.form
                ? _buildForm(context, localizations)
                : _buildSummary(context, localizations),
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

    return ListView(
      key: const ValueKey('form'),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        FormSectionLabel(localizations.goalName),
        TextField(
          controller: _nameController,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            hintText: localizations.goalNameHint,
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 28),
        FormSectionLabel(localizations.goalDuration),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final days in _durationPresets)
              QuickChoiceChip(
                label: localizations.durationDays(days),
                selected:
                    _durationMode == _DurationMode.preset && _days == days,
                onTap: () => setState(() {
                  _durationMode = _DurationMode.preset;
                  _days = days;
                }),
              ),
            QuickChoiceChip(
              label: localizations.customDuration,
              icon: Icons.tune_rounded,
              selected: _durationMode == _DurationMode.custom,
              onTap: () => setState(() => _durationMode = _DurationMode.custom),
            ),
            QuickChoiceChip(
              label: _durationMode == _DurationMode.endDate
                  ? ReadingGoalFormatting.date(context, _endDate)
                  : localizations.pickEndDate,
              icon: Icons.event_outlined,
              selected: _durationMode == _DurationMode.endDate,
              onTap: _pickEndDate,
            ),
          ],
        ),
        if (_durationMode == _DurationMode.custom) ...[
          const SizedBox(height: 12),
          _DaysField(
            days: _days,
            onChanged: (days) => setState(() => _days = days),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          '${localizations.durationDays(_durationDays)} · '
          '${localizations.readingEndsOn(ReadingGoalFormatting.date(context, _endDate))}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        if (!_isEdit) ...[
          const SizedBox(height: 28),
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
              '${getPageInfo(_startPage).surahNameEnglish}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
        ],
        if (isPlanned) ...[
          const SizedBox(height: 28),
          FormSectionLabel(localizations.goalStartDate),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              QuickChoiceChip(
                label: localizations.today,
                selected: _startDate == LocalDate.today(),
                onTap: () => setState(() => _startDate = LocalDate.today()),
              ),
              QuickChoiceChip(
                label: _startDate == LocalDate.today()
                    ? localizations.chooseDate
                    : ReadingGoalFormatting.date(context, _startDate),
                icon: Icons.event_outlined,
                selected: _startDate != LocalDate.today(),
                onTap: _pickStartDate,
              ),
            ],
          ),
        ],
        const SizedBox(height: 36),
        FilledButton.icon(
          onPressed: _isFormValid
              ? () {
                  FocusScope.of(context).unfocus();
                  setState(() => _step = _Step.summary);
                }
              : null,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          icon: const Icon(Icons.arrow_forward_rounded),
          label: Text(localizations.nextStep),
        ),
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
                '${startInfo.surahNameEnglish}',
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
        const SizedBox(height: 32),
        FilledButton.icon(
          onPressed: _isSaving ? null : _submit,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          icon: Icon(_isEdit ? Icons.save_outlined : Icons.check_rounded),
          label: Text(
            _isEdit ? localizations.goalSave : localizations.goalCreate,
          ),
        ),
      ],
    );
  }
}

/// Number of days field for a custom duration.
class _DaysField extends StatefulWidget {
  final int days;
  final ValueChanged<int> onChanged;

  const _DaysField({required this.days, required this.onChanged});

  @override
  State<_DaysField> createState() => _DaysFieldState();
}

class _DaysFieldState extends State<_DaysField> {
  late final TextEditingController _controller = TextEditingController(
    text: '${widget.days}',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return TextField(
      controller: _controller,
      autofocus: true,
      keyboardType: TextInputType.number,
      onChanged: (text) {
        final days = int.tryParse(text);
        if (days != null && days >= 1) {
          widget.onChanged(days.clamp(1, 3650));
        }
      },
      decoration: InputDecoration(
        labelText: localizations.goalDuration,
        helperText: localizations.durationDays(widget.days),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
