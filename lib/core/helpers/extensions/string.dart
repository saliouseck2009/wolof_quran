extension CapitalCase on String {
  String toCapitalCase() {
    return split(' ')
        .map(
          (word) =>
              word.isEmpty
                  ? word
                  : word[0].toUpperCase() + word.substring(1).toLowerCase(),
        )
        .join(' ');
  }
}

// convert string date in this format 2025-04-10T12:34:56.789Z to this format dd/MM/yyyy"
extension DateFormatExtension on String {
  String toFormattedDate() {
    // Check if the string in this format DateFormat("dd/MM/yyyy")
    try {
      if (RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(this)) {
        return this; // Already in the correct format
      }
      final dateTime = DateTime.parse(this).toLocal();
      return "${dateTime.day.toString().padLeft(2, '0')}/"
          "${dateTime.month.toString().padLeft(2, '0')}/"
          "${dateTime.year}";
    } catch (e) {
      return "Invalid Date";
    }
  }
}
