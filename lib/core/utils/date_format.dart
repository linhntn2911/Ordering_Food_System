/// Formats a review date as `dd/MM/yyyy` in the device's local time.
String formatReviewDate(DateTime date) {
  final local = date.toLocal();
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  return '${twoDigits(local.day)}/${twoDigits(local.month)}/${local.year}';
}
