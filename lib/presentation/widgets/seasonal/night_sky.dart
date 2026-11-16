import 'package:flutter/material.dart';

import '../../../core/config/theme/seasonal_theme.dart';

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

  const NightSkyDecoration({required this.base, required this.decor});

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
      other is NightSkyDecoration && other.base == base && other.decor == decor;

  @override
  int get hashCode => Object.hash(base, decor);
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
    NightSky.paintStars(canvas, rect, _decoration.decor);
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
Decoration seasonalSky(BuildContext context, BoxDecoration base) {
  final decor = Theme.of(context).extension<SeasonalDecor>();
  if (decor == null || decor.season != SeasonalTheme.ramadan) {
    return base;
  }
  return NightSkyDecoration(base: base, decor: decor);
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
