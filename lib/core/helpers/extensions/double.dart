import 'package:intl/intl.dart';

extension DoubleFormatting on double {
  String formatPrice() {
    final formatter = NumberFormat(
      "#,##0.##",
      "fr_FR",
    ); // Uses space as thousand separator
    return formatter.format(this);
  }
}

extension DoubleExtension on double {
  String roundToMaxTwoDecimals() {
    if (this % 1 == 0) {
      return toInt().toString(); // Pas de partie décimale, retourne l'entier
    } else {
      return toStringAsFixed(
        2,
      ).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
    }
  }
}
