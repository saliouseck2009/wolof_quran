import 'package:flutter/material.dart';

import '../../../core/config/theme/seasonal_theme.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Home greeting of the Ramadan look: a night sky with a crescent, a few
/// stars and two lanterns next to the greeting. Purely decorative, it draws
/// itself (no image asset) with the [SeasonalDecor] colors of the theme and
/// renders nothing out of season.
class RamadanBanner extends StatelessWidget {
  const RamadanBanner({super.key});

  static const double _radius = 24;
  static const double _minHeight = 104;

  /// Room kept free of text for the ornaments, on the end side.
  static const double _ornamentWidth = 132;

  @override
  Widget build(BuildContext context) {
    final decor = Theme.of(context).extension<SeasonalDecor>();
    if (decor == null || decor.season != SeasonalTheme.ramadan) {
      return const SizedBox.shrink();
    }
    final localizations = AppLocalizations.of(context)!;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Semantics(
      container: true,
      label:
          '${localizations.ramadanGreeting}. ${localizations.ramadanTagline}',
      child: ExcludeSemantics(
        child: Container(
          constraints: const BoxConstraints(minHeight: _minHeight),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_radius),
            gradient: LinearGradient(
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
              colors: [decor.skyStart, decor.skyEnd],
            ),
            // Outlines the banner on the night surfaces of the dark mode.
            border: Border.all(color: decor.ornament.withValues(alpha: 0.22)),
          ),
          child: CustomPaint(
            painter: _NightSkyPainter(decor: decor, mirrored: isRtl),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                20,
                18,
                _ornamentWidth,
                18,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      localizations.ramadanGreeting,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        height: 1.3,
                        color: decor.onSky,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    localizations.ramadanTagline,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                      color: Color.lerp(decor.ornament, decor.onSky, 0.35),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Crescent, stars and lanterns, anchored to the top end corner. Sizes are
/// in logical pixels: the ornaments keep their size when the banner grows
/// with the text.
class _NightSkyPainter extends CustomPainter {
  final SeasonalDecor decor;

  /// Draws the scene on the left, for right-to-left languages.
  final bool mirrored;

  const _NightSkyPainter({required this.decor, required this.mirrored});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    if (mirrored) {
      canvas
        ..translate(size.width, 0)
        ..scale(-1, 1);
    }
    final w = size.width;

    _paintMoon(canvas, Offset(w - 44, 46), 24);

    // Bright stars near the moon, faint ones over the rest of the sky.
    _paintSparkle(canvas, Offset(w - 30, 38), 5.5, 1);
    _paintSparkle(canvas, Offset(w - 84, 20), 4, 0.85);
    _paintSparkle(canvas, Offset(w - 14, 84), 3.5, 0.7);
    _paintSparkle(canvas, Offset(w - 150, 14), 3, 0.5);
    for (final (dx, dy, radius, alpha) in const [
      (0.08, 0.16, 1.1, 0.45),
      (0.22, 0.84, 0.9, 0.35),
      (0.34, 0.12, 1.0, 0.4),
      (0.47, 0.9, 1.2, 0.35),
      (0.56, 0.22, 0.9, 0.5),
      (0.74, 0.86, 1.0, 0.45),
      (0.9, 0.12, 1.1, 0.6),
    ]) {
      canvas.drawCircle(
        Offset(w * dx, size.height * dy),
        radius,
        Paint()..color = decor.onSky.withValues(alpha: alpha),
      );
    }

    _paintLantern(canvas, x: w - 98, drop: 14, height: 34);
    _paintLantern(canvas, x: w - 124, drop: 6, height: 24);
    canvas.restore();
  }

  void _paintMoon(Canvas canvas, Offset center, double radius) {
    final halo = Rect.fromCircle(center: center, radius: radius * 2.6);
    canvas.drawCircle(
      center,
      radius * 2.6,
      Paint()
        ..shader = RadialGradient(
          colors: [
            decor.glow.withValues(alpha: 0.20),
            decor.glow.withValues(alpha: 0),
          ],
        ).createShader(halo),
    );

    final disc = Rect.fromCircle(center: center, radius: radius);
    final crescent = Path.combine(
      PathOperation.difference,
      Path()..addOval(disc),
      Path()..addOval(
        Rect.fromCircle(
          center: center + Offset(radius * 0.36, -radius * 0.18),
          radius: radius * 0.82,
        ),
      ),
    );
    canvas.drawPath(
      crescent,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(decor.ornament, Colors.white, 0.45)!,
            decor.ornament,
          ],
        ).createShader(disc),
    );
  }

  /// Four-pointed star with hollowed sides.
  void _paintSparkle(Canvas canvas, Offset c, double r, double alpha) {
    final k = r * 0.16;
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx + k, c.dy - k, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx + k, c.dy + k, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx - k, c.dy + k, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx - k, c.dy - k, c.dx, c.dy - r)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = Color.lerp(
          decor.ornament,
          Colors.white,
          0.5,
        )!.withValues(alpha: alpha),
    );
  }

  /// A lantern hanging from the top edge at [x]: [drop] is the length of
  /// its string, [height] the height of its glass body.
  void _paintLantern(
    Canvas canvas, {
    required double x,
    required double drop,
    required double height,
  }) {
    final s = height;
    final gold = Paint()..color = decor.ornament;
    final thread = Paint()
      ..color = decor.ornament.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawLine(Offset(x, 0), Offset(x, drop), thread);
    canvas.drawCircle(Offset(x, drop + s * 0.06), s * 0.06, thread);

    final capTop = drop + s * 0.12;
    final bodyTop = capTop + s * 0.2;
    final bodyBottom = bodyTop + s * 0.62;
    final bodyCenter = Offset(x, (bodyTop + bodyBottom) / 2);

    final haloRect = Rect.fromCircle(center: bodyCenter, radius: s * 0.95);
    canvas.drawCircle(
      bodyCenter,
      s * 0.95,
      Paint()
        ..shader = RadialGradient(
          colors: [
            decor.glow.withValues(alpha: 0.38),
            decor.glow.withValues(alpha: 0),
          ],
        ).createShader(haloRect),
    );

    final cap = Path()
      ..moveTo(x - s * 0.22, bodyTop)
      ..quadraticBezierTo(x - s * 0.2, capTop + s * 0.03, x, capTop)
      ..quadraticBezierTo(x + s * 0.2, capTop + s * 0.03, x + s * 0.22, bodyTop)
      ..close();
    canvas.drawPath(cap, gold);

    final body = Path()
      ..moveTo(x - s * 0.2, bodyTop)
      ..lineTo(x + s * 0.2, bodyTop)
      ..quadraticBezierTo(
        x + s * 0.38,
        bodyTop + s * 0.3,
        x + s * 0.15,
        bodyBottom,
      )
      ..lineTo(x - s * 0.15, bodyBottom)
      ..quadraticBezierTo(x - s * 0.38, bodyTop + s * 0.3, x - s * 0.2, bodyTop)
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..shader = RadialGradient(
          colors: [Color.lerp(decor.glow, Colors.white, 0.6)!, decor.glow],
        ).createShader(Rect.fromCircle(center: bodyCenter, radius: s * 0.4)),
    );
    final frame = Paint()
      ..color = decor.ornament
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(body, frame);
    canvas.drawLine(Offset(x, bodyTop), Offset(x, bodyBottom), frame);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(
          x - s * 0.19,
          bodyBottom,
          x + s * 0.19,
          bodyBottom + s * 0.08,
        ),
        const Radius.circular(1),
      ),
      gold,
    );
    canvas.drawLine(
      Offset(x, bodyBottom + s * 0.08),
      Offset(x, bodyBottom + s * 0.24),
      thread,
    );
    canvas.drawCircle(Offset(x, bodyBottom + s * 0.26), s * 0.04, gold);
  }

  @override
  bool shouldRepaint(_NightSkyPainter oldDelegate) =>
      oldDelegate.decor != decor || oldDelegate.mirrored != mirrored;
}
