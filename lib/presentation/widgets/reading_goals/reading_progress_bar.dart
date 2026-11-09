import 'package:flutter/material.dart';

/// Thin rounded progress bar, 6 px high, in the style of the verse range
/// sheet. Takes the full available width whatever the parent's alignment.
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

    return SizedBox(
      width: double.infinity,
      height: height,
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: trackColor ?? colorScheme.surfaceContainerHighest,
              ),
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FractionallySizedBox(
                widthFactor: fraction.clamp(0.0, 1.0),
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color ?? colorScheme.primary,
                    borderRadius: radius,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
