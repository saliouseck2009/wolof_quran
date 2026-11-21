import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/config/theme/seasonal_theme.dart';
import 'night_sky.dart';

/// Loader of the Ramadan look: a crescent with a star circling around it,
/// trailed by a few sparks. With animations turned off in the system it
/// stays still.
class RamadanLoader extends StatefulWidget {
  final double size;

  const RamadanLoader({super.key, this.size = defaultSize});

  static const double defaultSize = 44;

  @override
  State<RamadanLoader> createState() => _RamadanLoaderState();
}

class _RamadanLoaderState extends State<RamadanLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller
        ..stop()
        ..value = 0.125; // The star rests at the top right of the crescent.
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final decor = Theme.of(context).extension<SeasonalDecor>();
    final isDark = colorScheme.brightness == Brightness.dark;
    final gold = decor?.ornament ?? colorScheme.secondary;

    return RepaintBoundary(
      child: SizedBox.square(
        dimension: widget.size,
        child: CustomPaint(
          painter: _LoaderPainter(
            progress: _controller,
            // Gold reads on the night surfaces; on the light ones the
            // crescent takes the indigo and the star a deeper gold.
            moon: isDark ? gold : colorScheme.primary,
            star: isDark
                ? Color.lerp(gold, Colors.white, 0.45)!
                : Color.lerp(colorScheme.secondary, Colors.black, 0.12)!,
          ),
        ),
      ),
    );
  }
}

class _LoaderPainter extends CustomPainter {
  final Animation<double> progress;
  final Color moon;
  final Color star;

  _LoaderPainter({
    required this.progress,
    required this.moon,
    required this.star,
  }) : super(repaint: progress);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final center = size.center(Offset.zero);
    final t = progress.value;
    final turn = 2 * math.pi * t;

    // The crescent breathes slightly while the star goes round.
    canvas.drawPath(
      NightSky.crescent(
        center + Offset(-s * 0.03, s * 0.02),
        s * 0.27 * (1 + 0.04 * math.sin(turn)),
      ),
      Paint()..color = moon,
    );

    final orbit = s * 0.38;
    final angle = turn - math.pi / 2;
    Offset onOrbit(double a) =>
        center + Offset(math.cos(a), math.sin(a)) * orbit;

    for (var i = 3; i >= 1; i--) {
      canvas.drawCircle(
        onOrbit(angle - i * 0.42),
        s * 0.036 * (1 - i * 0.2),
        Paint()..color = star.withValues(alpha: 0.6 - i * 0.15),
      );
    }
    canvas.drawPath(
      NightSky.sparkle(
        onOrbit(angle),
        s * 0.095 * (1 + 0.15 * math.sin(2 * turn)),
      ),
      Paint()..color = star,
    );
  }

  @override
  bool shouldRepaint(_LoaderPainter oldDelegate) =>
      oldDelegate.moon != moon || oldDelegate.star != star;
}
