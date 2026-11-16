import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/config/theme/seasonal_theme.dart';
import 'seasonal/ramadan_loader.dart';

/// The loader shown while a screen or a card gets its content: the standard
/// spinner, replaced by the ornament of the season when there is one.
///
/// Progress with a known value, and the small spinners inside buttons, stay
/// plain [CircularProgressIndicator]s: they are feedback on a control, not
/// decoration.
class AppLoader extends StatelessWidget {
  /// Diameter of the spinner; the size of [CircularProgressIndicator] when
  /// null. The seasonal loader never gets smaller than its drawing allows.
  final double? size;

  /// Color and stroke of the standard spinner. The seasonal loader keeps
  /// the colors of its season.
  final Color? color;
  final double? strokeWidth;

  const AppLoader({super.key, this.size, this.color, this.strokeWidth});

  static const double _minSeasonalSize = 28;

  @override
  Widget build(BuildContext context) {
    final size = this.size;
    if (SeasonalTheme.of(context) == SeasonalTheme.ramadan) {
      return RamadanLoader(
        size: size == null
            ? RamadanLoader.defaultSize
            : math.max(size, _minSeasonalSize),
      );
    }
    final spinner = CircularProgressIndicator(
      color: color,
      strokeWidth: strokeWidth,
    );
    return size == null
        ? spinner
        : SizedBox.square(dimension: size, child: spinner);
  }
}
