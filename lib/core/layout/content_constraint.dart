import 'package:flutter/widgets.dart';

import 'breakpoints.dart';

/// Side padding that centres a [maxWidth] column in [available] width.
///
/// [margin] is the phone margin of the screen; it grows with the window
/// (see [pageMarginFor]) and is always kept, even when the content is
/// narrower than [maxWidth].
double contentSidePadding(
  double available, {
  double maxWidth = ContentWidths.page,
  double margin = 0,
}) {
  final pageMargin = margin == 0
      ? 0.0
      : pageMarginFor(available, compact: margin);
  final centring = (available - maxWidth) / 2;
  return centring > pageMargin ? centring : pageMargin;
}

/// [padding] for a scroll view as wide as the window, with its sides
/// grown so the content is centred and at most [maxWidth] wide.
///
/// Capping with padding, not by shrinking the scroll view, keeps the
/// whole width of the window scrollable.
EdgeInsets centredPadding(
  BuildContext context,
  EdgeInsets padding, {
  double maxWidth = ContentWidths.page,
}) {
  final side = contentSidePadding(
    MediaQuery.sizeOf(context).width,
    maxWidth: maxWidth,
    margin: padding.left,
  );
  return padding.copyWith(left: side, right: side);
}

/// Centres [child] and stops it from growing wider than [maxWidth].
///
/// On a phone the child fills the width as before; on a tablet it stays
/// a readable column in the middle of the window.
class ContentConstraint extends StatelessWidget {
  final double maxWidth;
  final AlignmentGeometry alignment;
  final Widget child;

  const ContentConstraint({
    super.key,
    this.maxWidth = ContentWidths.page,
    this.alignment = Alignment.topCenter,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// [ContentConstraint] for slivers: pads [sliver] on both sides so its
/// content is centred and at most [maxWidth] wide.
///
/// See [contentSidePadding] for [margin].
class SliverContentConstraint extends StatelessWidget {
  final double maxWidth;
  final double margin;
  final Widget sliver;

  const SliverContentConstraint({
    super.key,
    this.maxWidth = ContentWidths.page,
    this.margin = 0,
    required this.sliver,
  });

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) => SliverPadding(
        padding: EdgeInsets.symmetric(
          horizontal: contentSidePadding(
            constraints.crossAxisExtent,
            maxWidth: maxWidth,
            margin: margin,
          ),
        ),
        sliver: sliver,
      ),
    );
  }
}
