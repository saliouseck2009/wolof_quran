import 'package:flutter/material.dart';

import '../../../core/config/theme/seasonal_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'night_sky.dart';

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

    NightSky.paintMoon(canvas, Offset(w - 44, 46), 24, decor);

    // Bright stars near the moon, faint ones over the rest of the sky.
    NightSky.paintSparkle(canvas, Offset(w - 30, 38), 5.5, decor);
    NightSky.paintSparkle(canvas, Offset(w - 84, 20), 4, decor, opacity: 0.85);
    NightSky.paintSparkle(canvas, Offset(w - 14, 84), 3.5, decor, opacity: 0.7);
    NightSky.paintSparkle(canvas, Offset(w - 150, 14), 3, decor, opacity: 0.5);
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

    NightSky.paintLantern(
      canvas,
      Offset(w - 98, 0),
      drop: 14,
      height: 34,
      decor: decor,
    );
    NightSky.paintLantern(
      canvas,
      Offset(w - 124, 0),
      drop: 6,
      height: 24,
      decor: decor,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_NightSkyPainter oldDelegate) =>
      oldDelegate.decor != decor || oldDelegate.mirrored != mirrored;
}
