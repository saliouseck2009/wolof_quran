import 'package:flutter/material.dart';

import '../../../domain/entities/reading_goal_progress.dart';

/// One cell per mushaf page, in reading order, coloured by state. Drawn
/// with a painter so the 604 cells cost nothing; taps resolve to a page.
class ReadingPagesMap extends StatelessWidget {
  static const _columns = 24;
  static const _gap = 2.0;

  final ReadingGoalProgress progress;
  final ValueChanged<int> onPageTap;

  const ReadingPagesMap({
    super.key,
    required this.progress,
    required this.onPageTap,
  });

  static Color readColor(ColorScheme colorScheme) => colorScheme.primary;

  static Color skippedColor(ColorScheme colorScheme) =>
      colorScheme.error.withValues(alpha: 0.55);

  static Color unreadColor(ColorScheme colorScheme) =>
      colorScheme.onSurface.withValues(alpha: 0.08);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final order = progress.goal.order;
    final validated = progress.validatedPages;
    final skipped = order.skippedPages(validated).toSet();
    final total = progress.goal.totalPages;
    final rows = (total / _columns).ceil();

    return LayoutBuilder(
      builder: (context, constraints) {
        final cell = (constraints.maxWidth - _gap * (_columns - 1)) / _columns;
        final height = rows * cell + (rows - 1) * _gap;
        return GestureDetector(
          onTapUp: (details) {
            final column = (details.localPosition.dx / (cell + _gap)).floor();
            final row = (details.localPosition.dy / (cell + _gap)).floor();
            final index = row * _columns + column;
            if (column >= 0 &&
                column < _columns &&
                index >= 0 &&
                index < total) {
              onPageTap(order.pageAt(index));
            }
          },
          child: CustomPaint(
            size: Size(constraints.maxWidth, height),
            painter: _PagesPainter(
              total: total,
              columns: _columns,
              gap: _gap,
              cell: cell,
              isRead: (index) => validated.contains(order.pageAt(index)),
              isSkipped: (index) => skipped.contains(order.pageAt(index)),
              readColor: readColor(colorScheme),
              skippedColor: skippedColor(colorScheme),
              unreadColor: unreadColor(colorScheme),
            ),
          ),
        );
      },
    );
  }
}

class _PagesPainter extends CustomPainter {
  final int total;
  final int columns;
  final double gap;
  final double cell;
  final bool Function(int index) isRead;
  final bool Function(int index) isSkipped;
  final Color readColor;
  final Color skippedColor;
  final Color unreadColor;

  const _PagesPainter({
    required this.total,
    required this.columns,
    required this.gap,
    required this.cell,
    required this.isRead,
    required this.isSkipped,
    required this.readColor,
    required this.skippedColor,
    required this.unreadColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final radius = Radius.circular(cell * 0.25);
    for (var index = 0; index < total; index++) {
      final column = index % columns;
      final row = index ~/ columns;
      paint.color = isRead(index)
          ? readColor
          : isSkipped(index)
          ? skippedColor
          : unreadColor;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(column * (cell + gap), row * (cell + gap), cell, cell),
          radius,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PagesPainter oldDelegate) => true;
}
