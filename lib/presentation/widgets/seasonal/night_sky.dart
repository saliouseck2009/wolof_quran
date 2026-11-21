import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/config/theme/seasonal_theme.dart';
import 'moon_phase_progress.dart';

/// Shapes shared by the Ramadan ornaments: the home banner, the loader and
/// the starry headers.
abstract final class NightSky {
  /// A crescent whose horns open towards the top right.
  static Path crescent(Offset center, double radius) {
    return Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
      Path()..addOval(
        Rect.fromCircle(
          center: center + Offset(radius * 0.36, -radius * 0.18),
          radius: radius * 0.82,
        ),
      ),
    );
  }

  /// A four-pointed star with hollowed sides.
  static Path sparkle(Offset center, double radius) {
    final c = center;
    final r = radius;
    final k = r * 0.16;
    return Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx + k, c.dy - k, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx + k, c.dy + k, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx - k, c.dy + k, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx - k, c.dy - k, c.dx, c.dy - r)
      ..close();
  }

  /// The color of the bright stars: the ornament gold, washed out.
  static Color starColor(SeasonalDecor decor) =>
      Color.lerp(decor.ornament, Colors.white, 0.5)!;

  /// Scatters faint stars over [rect]. They sit at fixed places from its top
  /// left corner, so a header that grows or collapses does not move them.
  static void paintStars(Canvas canvas, Rect rect, SeasonalDecor decor) {
    final bright = starColor(decor);
    for (var top = rect.top; top < rect.bottom; top += _tile.height) {
      for (var left = rect.left; left < rect.right; left += _tile.width) {
        for (final (dx, dy, radius, alpha) in _dots) {
          final center = Offset(left + dx, top + dy);
          if (rect.contains(center)) {
            canvas.drawCircle(
              center,
              radius,
              Paint()..color = decor.onSky.withValues(alpha: alpha),
            );
          }
        }
        for (final (dx, dy, radius, alpha) in _sparkles) {
          final center = Offset(left + dx, top + dy);
          if (rect.contains(center)) {
            canvas.drawPath(
              sparkle(center, radius),
              Paint()..color = bright.withValues(alpha: alpha),
            );
          }
        }
      }
    }
  }

  /// A bright star of [radius] at [center].
  static void paintSparkle(
    Canvas canvas,
    Offset center,
    double radius,
    SeasonalDecor decor, {
    double opacity = 1,
  }) {
    canvas.drawPath(
      sparkle(center, radius),
      Paint()..color = starColor(decor).withValues(alpha: opacity),
    );
  }

  /// The golden crescent, in a soft halo.
  static void paintMoon(
    Canvas canvas,
    Offset center,
    double radius,
    SeasonalDecor decor,
  ) {
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
    canvas.drawPath(
      crescent(center, radius),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(decor.ornament, Colors.white, 0.45)!,
            decor.ornament,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  /// The real moon of the night, [phase] being its place in the lunar cycle
  /// (see `LunarPhase.fractionAt`). Seen from Senegal, the waxing moon is
  /// lit on its right side and the waning moon on its left. The rest of
  /// the disc keeps a faint earthshine, and the thinnest crescents keep a
  /// minimum width so the moon of the first nights still shows.
  static void paintRealMoon(
    Canvas canvas,
    Offset center,
    double radius,
    double phase,
    SeasonalDecor decor,
  ) {
    final halo = Rect.fromCircle(center: center, radius: radius * 2.6);
    final waxing = phase < 0.5;
    final lit = (1 - math.cos(2 * math.pi * phase)) / 2;
    canvas.drawCircle(
      center,
      radius * 2.6,
      Paint()
        ..shader = RadialGradient(
          colors: [
            decor.glow.withValues(alpha: 0.08 + 0.14 * lit),
            decor.glow.withValues(alpha: 0),
          ],
        ).createShader(halo),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = decor.onSky.withValues(alpha: 0.10),
    );

    // [MoonPhaseProgress.litPath] lights the side facing the bottom left:
    // mirror it for the waxing moon.
    var litPart = MoonPhaseProgress.litPath(
      center,
      radius,
      lit.clamp(0.06, 1.0),
    );
    if (waxing) {
      final mirror = Matrix4.identity()
        ..translateByDouble(center.dx, center.dy, 0, 1)
        ..scaleByDouble(-1, 1, 1, 1)
        ..translateByDouble(-center.dx, -center.dy, 0, 1);
      litPart = litPart.transform(mirror.storage);
    }
    canvas.drawPath(
      litPart,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(decor.ornament, Colors.white, 0.45)!,
            decor.ornament,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  /// A lit lantern hanging from [anchor], a point of the top edge: [drop]
  /// is the length of its string, [height] the height of its glass body.
  static void paintLantern(
    Canvas canvas,
    Offset anchor, {
    required double drop,
    required double height,
    required SeasonalDecor decor,
  }) {
    final x = anchor.dx;
    final s = height;
    final gold = Paint()..color = decor.ornament;
    final thread = Paint()
      ..color = decor.ornament.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final hook = anchor.dy + drop;
    canvas.drawLine(anchor, Offset(x, hook), thread);
    canvas.drawCircle(Offset(x, hook + s * 0.06), s * 0.06, thread);

    final capTop = hook + s * 0.12;
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

  /// The star pattern repeats beyond this size, on tablets.
  static const Size _tile = Size(420, 230);

  /// (x, y, radius, opacity) of the small stars of one tile.
  static const List<(double, double, double, double)> _dots = [
    (14, 18, 1.0, 0.40),
    (52, 64, 0.8, 0.30),
    (88, 12, 1.1, 0.45),
    (121, 96, 0.9, 0.28),
    (150, 40, 0.8, 0.35),
    (187, 8, 1.0, 0.30),
    (204, 122, 1.1, 0.32),
    (236, 58, 0.9, 0.40),
    (268, 20, 1.2, 0.45),
    (291, 104, 0.8, 0.30),
    (322, 70, 1.0, 0.38),
    (351, 14, 0.9, 0.34),
    (384, 48, 1.1, 0.42),
    (405, 112, 0.8, 0.30),
    (30, 142, 1.0, 0.30),
    (74, 190, 0.9, 0.34),
    (132, 168, 1.1, 0.30),
    (176, 208, 0.8, 0.28),
    (248, 176, 1.0, 0.34),
    (300, 214, 0.9, 0.30),
    (346, 158, 1.1, 0.36),
    (396, 196, 0.8, 0.30),
  ];

  /// (x, y, radius, opacity) of the bright stars of one tile.
  static const List<(double, double, double, double)> _sparkles = [
    (110, 30, 3.2, 0.55),
    (306, 46, 4.0, 0.65),
    (398, 84, 2.8, 0.50),
    (212, 162, 3.4, 0.50),
    (44, 104, 2.6, 0.45),
  ];
}

/// A [base] box with the stars of the season scattered over it, behind the
/// content of the box.
class NightSkyDecoration extends Decoration {
  final BoxDecoration base;
  final SeasonalDecor decor;

  /// Also hangs two lanterns from the top of the box and puts the crescent
  /// in its top end corner: for a picture, not for a header.
  final bool ornaments;

  const NightSkyDecoration({
    required this.base,
    required this.decor,
    this.ornaments = false,
  });

  @override
  EdgeInsetsGeometry get padding => base.padding;

  @override
  bool get isComplex => base.isComplex;

  @override
  Path getClipPath(Rect rect, TextDirection textDirection) =>
      base.getClipPath(rect, textDirection);

  @override
  bool hitTest(Size size, Offset position, {TextDirection? textDirection}) =>
      base.hitTest(size, position, textDirection: textDirection);

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _NightSkyBoxPainter(base.createBoxPainter(onChanged), this);

  @override
  bool operator ==(Object other) =>
      other is NightSkyDecoration &&
      other.base == base &&
      other.decor == decor &&
      other.ornaments == ornaments;

  @override
  int get hashCode => Object.hash(base, decor, ornaments);
}

class _NightSkyBoxPainter extends BoxPainter {
  final BoxPainter _base;
  final NightSkyDecoration _decoration;

  _NightSkyBoxPainter(this._base, this._decoration);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    _base.paint(canvas, offset, configuration);
    final size = configuration.size;
    if (size == null) {
      return;
    }
    final rect = offset & size;
    canvas
      ..save()
      ..clipPath(
        _decoration.base.getClipPath(
          rect,
          configuration.textDirection ?? TextDirection.ltr,
        ),
      );
    final decor = _decoration.decor;
    NightSky.paintStars(canvas, rect, decor);
    if (_decoration.ornaments) {
      final side = rect.shortestSide;
      NightSky.paintMoon(
        canvas,
        rect.topRight + Offset(-side * 0.24, side * 0.25),
        side * 0.115,
        decor,
      );
      NightSky.paintSparkle(
        canvas,
        rect.topRight + Offset(-side * 0.2, side * 0.21),
        side * 0.026,
        decor,
      );
      NightSky.paintLantern(
        canvas,
        rect.topLeft + Offset(side * 0.2, 0),
        drop: side * 0.07,
        height: side * 0.16,
        decor: decor,
      );
      NightSky.paintLantern(
        canvas,
        rect.topLeft + Offset(side * 0.34, 0),
        drop: side * 0.03,
        height: side * 0.11,
        decor: decor,
      );
    }
    canvas.restore();
  }

  @override
  void dispose() {
    _base.dispose();
    super.dispose();
  }
}

/// The decoration of a header: [base] as it is out of season, with a starry
/// sky over it during Ramadan.
///
/// With [ornaments] the sky also gets its crescent and lanterns, for a
/// picture such as the artwork of the audio player.
Decoration seasonalSky(
  BuildContext context,
  BoxDecoration base, {
  bool ornaments = false,
}) {
  final decor = Theme.of(context).extension<SeasonalDecor>();
  if (decor == null || decor.season != SeasonalTheme.ramadan) {
    return base;
  }
  return NightSkyDecoration(base: base, decor: decor, ornaments: ornaments);
}

/// Starry sky to put in the `flexibleSpace` of an app bar. It keeps the
/// color of the bar and paints nothing out of season.
class SeasonalSky extends StatelessWidget {
  const SeasonalSky({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: DecoratedBox(
        decoration: seasonalSky(context, const BoxDecoration()),
      ),
    );
  }
}
