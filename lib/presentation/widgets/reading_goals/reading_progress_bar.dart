import 'package:flutter/material.dart';

/// Thin rounded progress bar, 6 px high, in the style of the verse range
/// sheet.
class ReadingProgressBar extends StatelessWidget {
  final double fraction;
  final Color? color;
  final Color? trackColor;
  final double height;

  const ReadingProgressBar({
    super.key,
    required this.fraction,
    this.color,
    this.trackColor,
    this.height = 6,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(height / 2);

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: trackColor ?? colorScheme.surfaceContainerHighest,
                ),
              ),
            ),
            FractionallySizedBox(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: fraction.clamp(0.0, 1.0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color ?? colorScheme.primary,
                  borderRadius: radius,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
