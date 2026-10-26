/// Why a page is being left, which decides whether a "too short" hint makes
/// sense.
enum PageLeaveReason { pageChanged, hidden, goalChanged, disposed }

/// Measures how long each mushaf page stays visible and decides when it
/// counts as read in the followed goal.
///
/// Pure Dart: time comes from [now] so tests can drive it. The clock only
/// runs while a goal is followed, tracking is enabled and the page is
/// visible (app in the foreground, mushaf route on top, no sheet above).
class MushafReadingTracker {
  /// Below this the user was only flipping through; no hint is shown.
  static const minDurationForHint = Duration(seconds: 3);

  final DateTime Function() _now;
  final void Function(int page) _onPageRead;
  final void Function(int page) _onPageTooShort;
  final bool Function(int page) _isValidated;
  final Duration _hintCooldown;

  Duration threshold;
  bool _enabled;
  String? _goalId;
  bool _visible;
  int? _currentPage;

  Duration _accumulated = Duration.zero;
  DateTime? _runningSince;
  DateTime? _lastHintAt;

  /// Pages visited while a goal was followed, for the reading session.
  final Set<int> pagesViewed = {};

  /// Time spent reading with a goal followed, for the reading session.
  Duration activeTotal = Duration.zero;

  MushafReadingTracker({
    required this.threshold,
    required bool enabled,
    required String? goalId,
    required bool Function(int page) isValidated,
    required void Function(int page) onPageRead,
    required void Function(int page) onPageTooShort,
    DateTime Function()? now,
    Duration hintCooldown = const Duration(seconds: 30),
    bool visible = true,
  }) : _enabled = enabled,
       _goalId = goalId,
       _isValidated = isValidated,
       _onPageRead = onPageRead,
       _onPageTooShort = onPageTooShort,
       _now = now ?? DateTime.now,
       _hintCooldown = hintCooldown,
       _visible = visible;

  bool get isTracking => _enabled && _goalId != null && _visible;

  String? get goalId => _goalId;

  /// Time spent on the current page so far.
  Duration get elapsedOnCurrentPage {
    final since = _runningSince;
    if (since == null) {
      return _accumulated;
    }
    return _accumulated + _now().difference(since);
  }

  void onPageChanged(int page) {
    if (page == _currentPage) {
      return;
    }
    _leavePage(PageLeaveReason.pageChanged);
    _currentPage = page;
    if (_goalId != null) {
      pagesViewed.add(page);
    }
    _resume();
  }

  void onVisibilityChanged(bool visible) {
    if (visible == _visible) {
      return;
    }
    if (visible) {
      _visible = true;
      _resume();
    } else {
      // Leaving the app with the threshold reached counts as having read
      // the page; the counter restarts from zero on return.
      _leavePage(PageLeaveReason.hidden);
      _visible = false;
    }
  }

  /// Switching goals drops the time spent so far: it is never carried over
  /// to the new goal.
  void onGoalChanged(String? goalId) {
    if (goalId == _goalId) {
      return;
    }
    _pause();
    _accumulated = Duration.zero;
    _goalId = goalId;
    final page = _currentPage;
    if (goalId != null && page != null) {
      pagesViewed.add(page);
    }
    _resume();
  }

  void setEnabled(bool enabled) {
    if (enabled == _enabled) {
      return;
    }
    if (enabled) {
      _enabled = true;
      _resume();
    } else {
      _pause();
      _accumulated = Duration.zero;
      _enabled = false;
    }
  }

  /// Flushes the current page; call when the mushaf is closed.
  void dispose() {
    _leavePage(PageLeaveReason.disposed);
    _currentPage = null;
  }

  void _resume() {
    if (isTracking && _runningSince == null) {
      _runningSince = _now();
    }
  }

  void _pause() {
    final since = _runningSince;
    if (since != null) {
      final slice = _now().difference(since);
      _accumulated += slice;
      activeTotal += slice;
      _runningSince = null;
    }
  }

  void _leavePage(PageLeaveReason reason) {
    _pause();
    final elapsed = _accumulated;
    _accumulated = Duration.zero;
    final page = _currentPage;
    final goalId = _goalId;
    if (page == null || goalId == null || !_enabled) {
      return;
    }
    if (_isValidated(page)) {
      return;
    }
    if (elapsed >= threshold) {
      _onPageRead(page);
      return;
    }
    if (reason == PageLeaveReason.pageChanged &&
        elapsed >= minDurationForHint &&
        _canHint()) {
      _lastHintAt = _now();
      _onPageTooShort(page);
    }
  }

  bool _canHint() {
    final last = _lastHintAt;
    return last == null || _now().difference(last) >= _hintCooldown;
  }
}
