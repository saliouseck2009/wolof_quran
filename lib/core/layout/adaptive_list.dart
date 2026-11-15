import 'package:flutter/widgets.dart';

import 'breakpoints.dart';
import 'content_constraint.dart';

/// Lays list items out in as many columns as the width allows.
///
/// With one column the items are built exactly as in a plain list, so a
/// phone is unaffected. With more, each list row holds several items
/// side by side, in reading order; items keep their own height.
abstract final class AdaptiveColumns {
  static const double defaultMinItemWidth = 340;
  static const double defaultGap = 12;

  /// Number of columns that fit in [width] without an item getting
  /// narrower than [minItemWidth].
  static int count(
    double width, {
    double minItemWidth = defaultMinItemWidth,
    int maxColumns = 3,
    double gap = defaultGap,
  }) {
    final fitting = ((width + gap) / (minItemWidth + gap)).floor();
    return fitting.clamp(1, maxColumns);
  }

  static int rowCount(int itemCount, int columns) =>
      (itemCount / columns).ceil();

  /// The [row]th row of a [columns]-wide layout.
  static Widget row(
    BuildContext context, {
    required int row,
    required int columns,
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    double gap = defaultGap,
  }) {
    if (columns == 1) {
      return itemBuilder(context, row);
    }
    final first = row * columns;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var c = 0; c < columns; c++) ...[
          if (c > 0) SizedBox(width: gap),
          Expanded(
            child: first + c < itemCount
                ? itemBuilder(context, first + c)
                : const SizedBox.shrink(),
          ),
        ],
      ],
    );
  }
}

/// A lazy sliver list that becomes a multi-column one on wide windows.
class SliverAdaptiveList extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double minItemWidth;
  final int maxColumns;
  final double gap;

  const SliverAdaptiveList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.minItemWidth = AdaptiveColumns.defaultMinItemWidth,
    this.maxColumns = 3,
    this.gap = AdaptiveColumns.defaultGap,
  });

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final columns = AdaptiveColumns.count(
          constraints.crossAxisExtent,
          minItemWidth: minItemWidth,
          maxColumns: maxColumns,
          gap: gap,
        );
        return SliverList.builder(
          itemCount: AdaptiveColumns.rowCount(itemCount, columns),
          itemBuilder: (context, row) => AdaptiveColumns.row(
            context,
            row: row,
            columns: columns,
            itemCount: itemCount,
            itemBuilder: itemBuilder,
            gap: gap,
          ),
        );
      },
    );
  }
}

/// A [ListView] whose content is centred, capped at [maxWidth] and laid
/// out in up to [maxColumns] columns.
///
/// The cap is applied as padding, not by shrinking the list, so the
/// whole width of the window still scrolls it. The horizontal part of
/// [padding] is the phone margin; it grows with the window.
class AdaptiveListView extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final EdgeInsets padding;
  final double maxWidth;
  final double minItemWidth;
  final int maxColumns;
  final double gap;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  const AdaptiveListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding = EdgeInsets.zero,
    this.maxWidth = ContentWidths.page,
    this.minItemWidth = AdaptiveColumns.defaultMinItemWidth,
    this.maxColumns = 1,
    this.gap = AdaptiveColumns.defaultGap,
    this.controller,
    this.physics,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = contentSidePadding(
          constraints.maxWidth,
          maxWidth: maxWidth,
          margin: padding.left,
        );
        final columns = AdaptiveColumns.count(
          constraints.maxWidth - 2 * side,
          minItemWidth: minItemWidth,
          maxColumns: maxColumns,
          gap: gap,
        );
        return ListView.builder(
          controller: controller,
          physics: physics,
          shrinkWrap: shrinkWrap,
          padding: padding.copyWith(left: side, right: side),
          itemCount: AdaptiveColumns.rowCount(itemCount, columns),
          itemBuilder: (context, row) => AdaptiveColumns.row(
            context,
            row: row,
            columns: columns,
            itemCount: itemCount,
            itemBuilder: itemBuilder,
            gap: gap,
          ),
        );
      },
    );
  }
}
