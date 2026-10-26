import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart' as qcf;
import 'package:uuid/uuid.dart';

import '../../core/reading/local_date.dart';
import '../../domain/entities/reading_goal.dart';
import '../../domain/entities/reading_goal_progress.dart';
import '../../domain/entities/reading_validation.dart';
import '../../domain/repositories/reading_goal_repository.dart';

class ReadingGoalsState extends Equatable {
  final bool isLoading;

  /// Every goal with its progress, most recently created first.
  final List<ReadingGoalProgress> goals;

  /// Goal followed in the mushaf, `null` for free reading.
  final String? activeGoalId;

  /// Latest journal entry, so the UI can offer to undo it.
  final ReadingValidation? lastValidation;

  /// Goal that just reached 100 %, consumed by the UI to celebrate once.
  final String? lastCompletedGoalId;
  final String? error;

  const ReadingGoalsState({
    this.isLoading = true,
    this.goals = const [],
    this.activeGoalId,
    this.lastValidation,
    this.lastCompletedGoalId,
    this.error,
  });

  ReadingGoalProgress? progressOf(String? goalId) {
    if (goalId == null) {
      return null;
    }
    for (final progress in goals) {
      if (progress.goal.id == goalId) {
        return progress;
      }
    }
    return null;
  }

  ReadingGoalProgress? get activeProgress => progressOf(activeGoalId);

  bool get hasGoals => goals.isNotEmpty;

  /// Goals the user can read in today: active, paused or past their date.
  List<ReadingGoalProgress> get ongoing => goals
      .where(
        (progress) =>
            progress.phase == ReadingGoalPhase.active ||
            progress.phase == ReadingGoalPhase.paused ||
            progress.phase == ReadingGoalPhase.expired,
      )
      .toList();

  List<ReadingGoalProgress> get planned => goals
      .where((progress) => progress.phase == ReadingGoalPhase.planned)
      .toList();

  List<ReadingGoalProgress> get finished => goals
      .where(
        (progress) =>
            progress.phase == ReadingGoalPhase.completed ||
            progress.phase == ReadingGoalPhase.abandoned,
      )
      .toList();

  ReadingGoalsState copyWith({
    bool? isLoading,
    List<ReadingGoalProgress>? goals,
    String? Function()? activeGoalId,
    ReadingValidation? Function()? lastValidation,
    String? Function()? lastCompletedGoalId,
    String? Function()? error,
  }) {
    return ReadingGoalsState(
      isLoading: isLoading ?? this.isLoading,
      goals: goals ?? this.goals,
      activeGoalId: activeGoalId != null ? activeGoalId() : this.activeGoalId,
      lastValidation: lastValidation != null
          ? lastValidation()
          : this.lastValidation,
      lastCompletedGoalId: lastCompletedGoalId != null
          ? lastCompletedGoalId()
          : this.lastCompletedGoalId,
      error: error != null ? error() : this.error,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    goals,
    activeGoalId,
    lastValidation,
    lastCompletedGoalId,
    error,
  ];
}

/// Single source of truth for reading goals. Every mutation targets one goal
/// id and never touches the progress of another goal.
class ReadingGoalsCubit extends Cubit<ReadingGoalsState> {
  final ReadingGoalRepository _repository;
  final LocalDate Function() _today;
  final DateTime Function() _now;
  final Uuid _uuid;
  final int _totalPages;

  ReadingGoalsCubit({
    required ReadingGoalRepository repository,
    LocalDate Function()? today,
    DateTime Function()? now,
    Uuid? uuid,
    int? totalPages,
  }) : _repository = repository,
       _today = today ?? LocalDate.today,
       _now = now ?? DateTime.now,
       _uuid = uuid ?? const Uuid(),
       _totalPages = totalPages ?? qcf.totalPagesCount,
       super(const ReadingGoalsState());

  int get totalPages => _totalPages;

  Future<void> load() async {
    try {
      final goals = await _repository.getGoals();
      final pagesByGoal = await _repository.getAllValidatedPages();
      final activeGoalId = await _repository.getActiveGoalId();
      final today = _today();
      final progresses = [
        for (final goal in goals)
          ReadingGoalProgress(
            goal: goal,
            validatedAt: pagesByGoal[goal.id] ?? const {},
            today: today,
          ),
      ];
      final activeExists = progresses.any(
        (progress) => progress.goal.id == activeGoalId,
      );
      emit(
        state.copyWith(
          isLoading: false,
          goals: progresses,
          activeGoalId: () => activeExists ? activeGoalId : null,
          error: () => null,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: () => 'Failed to load: $e'));
    }
  }

  /// Recomputes every goal for the current day, e.g. after midnight.
  void refreshToday() {
    final today = _today();
    if (state.goals.isEmpty || state.goals.first.today == today) {
      return;
    }
    emit(
      state.copyWith(
        goals: [
          for (final progress in state.goals)
            ReadingGoalProgress(
              goal: progress.goal,
              validatedAt: progress.validatedAt,
              today: today,
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Goal lifecycle
  // ---------------------------------------------------------------------------

  Future<ReadingGoal> createGoal({
    required String name,
    required int startPage,
    required LocalDate startDate,
    required LocalDate endDate,
    ReminderSettings reminder = const ReminderSettings(),
    bool activate = true,
  }) async {
    final now = _now();
    final goal = ReadingGoal(
      id: _uuid.v4(),
      name: name.trim(),
      status: ReadingGoalStatus.active,
      startPage: startPage.clamp(1, _totalPages),
      totalPages: _totalPages,
      startDate: startDate,
      endDate: endDate.isBefore(startDate) ? startDate : endDate,
      reminder: reminder,
      createdAt: now,
      updatedAt: now,
    );
    await _repository.saveGoal(goal);
    final progress = ReadingGoalProgress(
      goal: goal,
      validatedAt: const {},
      today: _today(),
    );
    emit(state.copyWith(goals: [progress, ...state.goals]));
    if (activate) {
      await setActiveGoal(goal.id);
    }
    return goal;
  }

  Future<void> renameGoal(String goalId, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return;
    }
    await _updateGoal(goalId, (goal) => goal.copyWith(name: trimmed));
  }

  Future<void> updateDates(
    String goalId, {
    LocalDate? startDate,
    LocalDate? endDate,
  }) async {
    await _updateGoal(goalId, (goal) {
      final newStart = startDate ?? goal.startDate;
      final newEnd = endDate ?? goal.endDate;
      return goal.copyWith(
        startDate: newStart,
        endDate: newEnd.isBefore(newStart) ? newStart : newEnd,
      );
    });
  }

  Future<void> updateReminder(String goalId, ReminderSettings reminder) async {
    await _updateGoal(goalId, (goal) => goal.copyWith(reminder: reminder));
  }

  Future<void> pauseGoal(String goalId) async {
    await _updateGoal(goalId, (goal) {
      if (goal.status != ReadingGoalStatus.active) {
        return goal;
      }
      return goal.copyWith(
        status: ReadingGoalStatus.paused,
        pausedAt: _today(),
      );
    });
  }

  /// Resumes a paused goal, pushing its end date by the days spent paused
  /// so the daily pace stays what it was.
  Future<void> resumeGoal(String goalId) async {
    await _updateGoal(goalId, (goal) {
      if (goal.status != ReadingGoalStatus.paused) {
        return goal;
      }
      final pausedDays = goal.pausedAt?.daysUntil(_today()) ?? 0;
      return goal.copyWith(
        status: ReadingGoalStatus.active,
        endDate: goal.endDate.addDays(pausedDays.clamp(0, 36500)),
        clearPausedAt: true,
      );
    });
  }

  /// Reactivates a completed or abandoned goal so it can keep going.
  Future<void> reactivateGoal(String goalId) async {
    await _updateGoal(goalId, (goal) {
      return goal.copyWith(
        status: ReadingGoalStatus.active,
        clearCompletedAt: true,
        clearPausedAt: true,
      );
    });
  }

  Future<void> abandonGoal(String goalId) async {
    await _updateGoal(
      goalId,
      (goal) => goal.copyWith(
        status: ReadingGoalStatus.abandoned,
        clearPausedAt: true,
      ),
    );
    if (state.activeGoalId == goalId) {
      await setActiveGoal(null);
    }
  }

  Future<void> deleteGoal(String goalId) async {
    await _repository.deleteGoal(goalId);
    emit(
      state.copyWith(
        goals: state.goals
            .where((progress) => progress.goal.id != goalId)
            .toList(),
        activeGoalId: () =>
            state.activeGoalId == goalId ? null : state.activeGoalId,
        lastValidation: () => state.lastValidation?.goalId == goalId
            ? null
            : state.lastValidation,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Active goal and reading position
  // ---------------------------------------------------------------------------

  Future<void> setActiveGoal(String? goalId) async {
    if (goalId != null && state.progressOf(goalId) == null) {
      return;
    }
    await _repository.setActiveGoalId(goalId);
    emit(state.copyWith(activeGoalId: () => goalId));
  }

  /// Remembers [page] as the last page seen in the active goal. Viewing a
  /// page never validates it.
  Future<void> recordPageViewed(int page) async {
    final activeGoalId = state.activeGoalId;
    if (activeGoalId == null) {
      return;
    }
    final progress = state.progressOf(activeGoalId);
    if (progress == null || progress.goal.lastViewedPage == page) {
      return;
    }
    await _updateGoal(
      activeGoalId,
      (goal) => goal.copyWith(lastViewedPage: page),
    );
  }

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  Future<ReadingValidation?> validatePage(
    String goalId,
    int page, {
    ReadingValidationSource source = ReadingValidationSource.manual,
  }) {
    return validatePages(
      goalId: goalId,
      pages: [page],
      source: source,
      action: ReadingValidationAction.page,
      fromPage: page,
      toPage: page,
    );
  }

  /// Validates every page from [fromPage] to [toPage] following the goal's
  /// reading order. Pages already read are not counted twice.
  Future<ReadingValidation?> validateRange(
    String goalId,
    int fromPage,
    int toPage,
  ) {
    final progress = state.progressOf(goalId);
    if (progress == null) {
      return Future.value(null);
    }
    return validatePages(
      goalId: goalId,
      pages: progress.goal.order.pagesBetween(fromPage, toPage),
      source: ReadingValidationSource.manual,
      action: ReadingValidationAction.range,
      fromPage: fromPage,
      toPage: toPage,
    );
  }

  /// Pages "read until here" would add: the unread pages from the first
  /// unvalidated page up to [page] in reading order. Empty when [page] sits
  /// before the continuous progress.
  List<int> pagesUntil(String goalId, int page) {
    final progress = state.progressOf(goalId);
    if (progress == null) {
      return const [];
    }
    final first = progress.metrics.firstUnvalidatedPage;
    if (first == null) {
      return const [];
    }
    return progress.goal.order
        .pagesBetween(first, page)
        .where((candidate) => !progress.isValidated(candidate))
        .toList();
  }

  Future<ReadingValidation?> readUntil(String goalId, int page) {
    final progress = state.progressOf(goalId);
    final pages = pagesUntil(goalId, page);
    if (progress == null || pages.isEmpty) {
      return Future.value(null);
    }
    return validatePages(
      goalId: goalId,
      pages: pages,
      source: ReadingValidationSource.manual,
      action: ReadingValidationAction.readUntil,
      fromPage: pages.first,
      toPage: page,
    );
  }

  Future<ReadingValidation?> validatePages({
    required String goalId,
    required List<int> pages,
    required ReadingValidationSource source,
    required ReadingValidationAction action,
    int? fromPage,
    int? toPage,
  }) async {
    final progress = state.progressOf(goalId);
    if (progress == null || !progress.goal.acceptsProgress) {
      return null;
    }
    final validation = await _repository.validatePages(
      goalId: goalId,
      pages: pages,
      source: source,
      action: action,
      fromPage: fromPage,
      toPage: toPage,
    );
    if (validation == null) {
      return null;
    }
    final updated = Map<int, DateTime>.from(progress.validatedAt);
    for (final page in validation.pages) {
      updated[page] = validation.createdAt;
    }
    await _replaceProgress(
      ReadingGoalProgress(
        goal: progress.goal,
        validatedAt: updated,
        today: _today(),
      ),
      lastValidation: validation,
    );
    await _completeIfDone(goalId);
    return validation;
  }

  Future<ReadingValidation?> unmarkPage(String goalId, int page) async {
    final progress = state.progressOf(goalId);
    if (progress == null) {
      return null;
    }
    final validation = await _repository.unmarkPages(
      goalId: goalId,
      pages: [page],
    );
    if (validation == null) {
      return null;
    }
    final updated = Map<int, DateTime>.from(progress.validatedAt)
      ..removeWhere((key, _) => validation.pages.contains(key));
    await _replaceProgress(
      ReadingGoalProgress(
        goal: progress.goal,
        validatedAt: updated,
        today: _today(),
      ),
      lastValidation: validation,
    );
    return validation;
  }

  Future<void> undoValidation(String validationId) async {
    final validation = state.lastValidation?.id == validationId
        ? state.lastValidation
        : null;
    await _repository.undoValidation(validationId);
    final goalId = validation?.goalId;
    if (goalId != null) {
      await _reloadGoal(goalId);
    } else {
      await load();
    }
    emit(state.copyWith(lastValidation: () => null));
  }

  void clearLastValidation() {
    if (state.lastValidation != null) {
      emit(state.copyWith(lastValidation: () => null));
    }
  }

  void clearLastCompleted() {
    if (state.lastCompletedGoalId != null) {
      emit(state.copyWith(lastCompletedGoalId: () => null));
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<void> _completeIfDone(String goalId) async {
    final progress = state.progressOf(goalId);
    if (progress == null ||
        !progress.metrics.isComplete ||
        progress.goal.status == ReadingGoalStatus.completed) {
      return;
    }
    final now = _now();
    await _updateGoal(
      goalId,
      (goal) => goal.copyWith(
        status: ReadingGoalStatus.completed,
        completedAt: now,
        clearPausedAt: true,
      ),
    );
    emit(state.copyWith(lastCompletedGoalId: () => goalId));
  }

  Future<void> _updateGoal(
    String goalId,
    ReadingGoal Function(ReadingGoal goal) update,
  ) async {
    final progress = state.progressOf(goalId);
    if (progress == null) {
      return;
    }
    final updated = update(progress.goal);
    if (updated == progress.goal) {
      return;
    }
    final saved = updated.copyWith(updatedAt: _now());
    await _repository.saveGoal(saved);
    await _replaceProgress(
      ReadingGoalProgress(
        goal: saved,
        validatedAt: progress.validatedAt,
        today: _today(),
      ),
    );
  }

  Future<void> _reloadGoal(String goalId) async {
    final goal = await _repository.getGoal(goalId);
    if (goal == null) {
      emit(
        state.copyWith(
          goals: state.goals
              .where((progress) => progress.goal.id != goalId)
              .toList(),
        ),
      );
      return;
    }
    final pages = await _repository.getValidatedPages(goalId);
    await _replaceProgress(
      ReadingGoalProgress(goal: goal, validatedAt: pages, today: _today()),
    );
  }

  Future<void> _replaceProgress(
    ReadingGoalProgress progress, {
    ReadingValidation? lastValidation,
  }) async {
    emit(
      state.copyWith(
        goals: [
          for (final existing in state.goals)
            existing.goal.id == progress.goal.id ? progress : existing,
        ],
        lastValidation: lastValidation == null ? null : () => lastValidation,
      ),
    );
  }
}
