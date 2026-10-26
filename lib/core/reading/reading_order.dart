/// The order in which a goal walks the mushaf: from [startPage] to the last
/// page, then from page 1 up to the page before [startPage].
///
/// Every goal covers all [totalPages] pages, whatever its starting page.
class ReadingOrder {
  final int startPage;
  final int totalPages;

  const ReadingOrder({required this.startPage, required this.totalPages})
    : assert(startPage >= 1 && startPage <= totalPages);

  /// Position of [page] in the reading order, 0 for [startPage].
  int indexOf(int page) => (page - startPage + totalPages) % totalPages;

  /// Page at position [index] in the reading order.
  int pageAt(int index) => ((startPage - 1 + index) % totalPages) + 1;

  /// Whether [page] comes strictly before [other] in the reading order.
  bool isBefore(int page, int other) => indexOf(page) < indexOf(other);

  /// Pages from [from] to [to] inclusive, following the reading order.
  /// Returns an empty list when [to] comes before [from].
  List<int> pagesBetween(int from, int to) {
    final start = indexOf(from);
    final end = indexOf(to);
    if (end < start) {
      return const [];
    }
    return [for (var i = start; i <= end; i++) pageAt(i)];
  }

  /// Number of consecutive validated pages from [startPage].
  int continuousProgress(Set<int> validatedPages) {
    var count = 0;
    while (count < totalPages && validatedPages.contains(pageAt(count))) {
      count++;
    }
    return count;
  }

  /// First page of the goal that is not validated yet, or `null` once every
  /// page is validated.
  int? firstUnvalidatedPage(Set<int> validatedPages) {
    final progress = continuousProgress(validatedPages);
    return progress >= totalPages ? null : pageAt(progress);
  }

  /// Validated pages that come after at least one unvalidated page, i.e.
  /// pages read out of order, sorted by reading order.
  List<int> pagesReadAhead(Set<int> validatedPages) {
    final progress = continuousProgress(validatedPages);
    return [
      for (var i = progress + 1; i < totalPages; i++)
        if (validatedPages.contains(pageAt(i))) pageAt(i),
    ];
  }

  /// Unvalidated pages that sit before the furthest validated page, i.e.
  /// the gaps left by reading ahead, sorted by reading order.
  List<int> skippedPages(Set<int> validatedPages) {
    var furthest = -1;
    for (final page in validatedPages) {
      final index = indexOf(page);
      if (index > furthest) {
        furthest = index;
      }
    }
    return [
      for (var i = 0; i < furthest; i++)
        if (!validatedPages.contains(pageAt(i))) pageAt(i),
    ];
  }
}
