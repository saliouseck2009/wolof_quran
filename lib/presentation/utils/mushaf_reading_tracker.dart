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

  /// Pages shown beside the current one (the facing page of a spread).
  List<int> _facingPages = const [];

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

  /// [facingPages] are the other pages on screen when the mushaf shows
  /// two at once. Each page on screen needs its own [threshold] of time:
  /// the current one is counted first, then the facing ones in order.
  void onPageChanged(int page, {List<int> facingPages = const []}) {
    if (page == _currentPage) {
      // Same page, another layout (the device was rotated): the time
      // spent so far is kept.
      _facingPages = List.of(facingPages);
      if (_goalId != null) {
        pagesViewed.addAll(facingPages);
      }
      return;
    }
    _leavePage(PageLeaveReason.pageChanged);
    _currentPage = page;
    _facingPages = List.of(facingPages);
    if (_goalId != null) {
      pagesViewed
        ..add(page)
        ..addAll(facingPages);
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
      pagesViewed
        ..add(page)
        ..addAll(_facingPages);
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
    _facingPages = const [];
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
    final unread = [
      for (final shown in [page, ..._facingPages])
        if (!_isValidated(shown)) shown,
    ];
    if (unread.isEmpty) {
      return;
    }
    // One threshold of reading time per page still to read.
    var remaining = elapsed;
    var read = 0;
    while (read < unread.length && remaining >= threshold) {
      _onPageRead(unread[read]);
      remaining -= threshold;
      read++;
    }
    if (read > 0) {
      return;
    }
    if (reason == PageLeaveReason.pageChanged &&
        elapsed >= minDurationForHint &&
        _canHint()) {
      _lastHintAt = _now();
      _onPageTooShort(unread.first);
    }
  }

  bool _canHint() {
    final last = _lastHintAt;
    return last == null || _now().difference(last) >= _hintCooldown;
  }
}
