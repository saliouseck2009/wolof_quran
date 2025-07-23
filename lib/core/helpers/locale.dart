import 'dart:io';

import 'package:intl/intl.dart';

class LocalHelpers {
  static String formatDateTime(DateTime dateTime) {
    String dayAbbreviation = DateFormat("EEE", "fr_FR").format(dateTime);
    String formattedDate = DateFormat(
      "dd/MM/yyyy HH:mm",
      "fr_FR",
    ).format(dateTime);
    return "$dayAbbreviation $formattedDate";
  }

  static String formatShortDateTime(DateTime dateTime) {
    String formattedDate = DateFormat("dd/MM/yyyy", "fr_FR").format(dateTime);
    return formattedDate;
  }

  static String getUserCurrency() {
    try {
      // Get system locale (e.g., "fr_FR", "en_US", etc.)
      String locale = Platform.localeName;

      // Extract currency from the locale
      return NumberFormat.simpleCurrency(locale: locale).currencyName ?? "XOF";
    } catch (e) {
      return "USD"; // Default to USD in case of error
    }
  }

  static String formatPrice(int price) {
    final formatter = NumberFormat("#,##0", "fr_FR");
    return formatter.format(price).replaceAll(',', ' ');
  }

  static String formatDoublePrice(double price) {
    final formatter = NumberFormat("#,##0", "fr_FR");
    return formatter.format(price).replaceAll(',', ' ');
  }

  static String getFrenchMonthName(int monthNumber) {
    final date = DateTime(2025, monthNumber);
    return DateFormat.MMMM('fr').format(date); // e.g. "juin" for 6
  }

  static ({String date, String time}) getFormattedDateAndTimeSeparately(
    String dateTimeStr,
  ) {
    try {
      final dateTime =
          DateTime.parse(dateTimeStr).toLocal(); // adjust to local if needed
      final date =
          "${dateTime.day.toString().padLeft(2, '0')}/"
          "${dateTime.month.toString().padLeft(2, '0')}/"
          "${dateTime.year}";
      final time =
          "${dateTime.hour.toString().padLeft(2, '0')}:"
          "${dateTime.minute.toString().padLeft(2, '0')}";

      return (date: date, time: time);
    } catch (e) {
      return (date: "N/A", time: "N/A");
    }
  }

  static String getRelativeLabel(DateTime date) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final today = DateTime(now.year, now.month, now.day);

    if (date.year == today.year &&
        date.month == today.month &&
        date.day == today.day) {
      return "Aujourd'hui";
    } else if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return "Hier";
    }

    return "•"; // Will use formatted date instead
  }

  static String getCurrentMonthAndYear() {
    final now = DateTime.now();
    final month = DateFormat.MMMM('fr').format(now);
    final year = now.year;
    return "$month $year";
  }
}
