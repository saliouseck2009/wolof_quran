import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/config/theme/seasonal_theme.dart';

/// Progress shown as a phase of the moon: nothing lit at the start, a
/// crescent that widens as the reading advances, the full moon at the end.
/// The lit share of the disc is exactly [fraction].
///
/// The [label] is written across the moon, dark on its lit part and light
/// on the rest, so it stays readable at every phase.
class MoonPhaseProgress extends StatelessWidget {
  final double fraction;
  final String label;
  final double size;

  const MoonPhaseProgress({
    super.key,
    required this.fraction,
    required this.label,
    this.size = 46,
  });

  /// The lit limb faces the bottom left, like the crescents of the banner
  /// and of the loader.
  static const double _tilt = math.pi - 0.4636;

  /// The lit part of a moon of [radius] around [center] at [fraction] of its
  /// way from the new moon to the full moon.
  static Path litPath(Offset center, double radius, double fraction) {
    final f = fraction.clamp(0.0, 1.0);
    if (f <= 0) {
      return Path();
    }
    final disc = Rect.fromCircle(center: center, radius: radius);
    if (f >= 1) {
      return Path()..addOval(disc);
    }
    final top = Offset(center.dx, center.dy - radius);
    final bottom = Offset(center.dx, center.dy + radius);
    // Half a disc, closed by the terminator: an ellipse that eats into the
    // half before the first quarter and adds to it afterwards.
    final path = Path()
      ..moveTo(top.dx, top.dy)
      ..arcToPoint(bottom, radius: Radius.circular(radius))
      ..arcToPoint(
        top,
        radius: Radius.elliptical(radius * (1 - 2 * f).abs(), radius),
        clockwise: f > 0.5,
      )
      ..close();
    final turn = Matrix4.identity()
      ..translateByDouble(center.dx, center.dy, 0, 1)
      ..rotateZ(_tilt)
      ..translateByDouble(-center.dx, -center.dy, 0, 1);
    return path.transform(turn.storage);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final decor = theme.extension<SeasonalDecor>();
    final isDark = colorScheme.brightness == Brightness.dark;
    // Gold reads on the night cards; the white cards need a deeper one.
    final gold = isDark
        ? decor?.ornament ?? colorScheme.secondary
        : colorScheme.secondary;
    final night = Color.lerp(
      decor?.skyStart ?? colorScheme.onSurface,
      Colors.black,
      0.3,
    )!;
    final labelStyle = DefaultTextStyle.of(context).style.merge(
      const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, height: 1),
    );

    return Semantics(
      label: label,
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        // The moon waxes up to the progress when the card shows up.
        tween: Tween(begin: 0, end: fraction.clamp(0.0, 1.0)),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) => CustomPaint(
          size: Size.square(size),
          painter: _MoonPhasePainter(
            fraction: value,
            lit: gold,
            unlit: gold.withValues(alpha: isDark ? 0.14 : 0.16),
            outline: isDark
                ? gold.withValues(alpha: 0.55)
                : Color.lerp(gold, Colors.black, 0.18)!,
            label: label,
            labelStyle: labelStyle,
            onLit: night,
            onUnlit: colorScheme.onSurface,
            textDirection: Directionality.of(context),
          ),
        ),
      ),
    );
  }
}

class _MoonPhasePainter extends CustomPainter {
  final double fraction;
  final Color lit;
  final Color unlit;
  final Color outline;
  final String label;
  final TextStyle labelStyle;
  final Color onLit;
  final Color onUnlit;
  final TextDirection textDirection;

  const _MoonPhasePainter({
    required this.fraction,
    required this.lit,
    required this.unlit,
    required this.outline,
    required this.label,
    required this.labelStyle,
    required this.onLit,
    required this.onUnlit,
    required this.textDirection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 1;
    final discRect = Rect.fromCircle(center: center, radius: radius);
    final disc = Path()..addOval(discRect);
    final litPart = MoonPhaseProgress.litPath(center, radius, fraction);
    final darkPart = Path.combine(PathOperation.difference, disc, litPart);

    canvas
      ..drawPath(disc, Paint()..color = unlit)
      ..drawPath(
        litPart,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.lerp(lit, Colors.white, 0.3)!, lit],
          ).createShader(discRect),
      )
      ..drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = outline,
      );

    _paintLabel(canvas, center, radius, onLit, litPart);
    _paintLabel(canvas, center, radius, onUnlit, darkPart);
  }

  /// Writes the label in [color], only where it lies over [region].
  void _paintLabel(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    Path region,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: labelStyle.copyWith(color: color),
      ),
      textDirection: textDirection,
      maxLines: 1,
    )..layout();
    final scale = math.min(1.0, radius * 1.4 / painter.width);
    canvas
      ..save()
      ..clipPath(region)
      ..translate(center.dx, center.dy)
      ..scale(scale);
    painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
    canvas.restore();
    painter.dispose();
  }

  @override
  bool shouldRepaint(_MoonPhasePainter oldDelegate) =>
      oldDelegate.fraction != fraction ||
      oldDelegate.lit != lit ||
      oldDelegate.unlit != unlit ||
      oldDelegate.outline != outline ||
      oldDelegate.label != label ||
      oldDelegate.labelStyle != labelStyle ||
      oldDelegate.onLit != onLit ||
      oldDelegate.onUnlit != onUnlit ||
      oldDelegate.textDirection != textDirection;
}
