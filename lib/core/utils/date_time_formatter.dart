abstract final class DateTimeFormatter {
  static String orderTime(DateTime value, {DateTime? now}) {
    final local = value.toLocal();
    final current = (now ?? DateTime.now()).toLocal();
    final valueDate = DateTime(local.year, local.month, local.day);
    final currentDate = DateTime(current.year, current.month, current.day);
    final difference = currentDate.difference(valueDate).inDays;
    final time = '${_two(local.hour)}:${_two(local.minute)}';
    if (difference == 0) return 'Today, $time';
    if (difference == 1) return 'Yesterday, $time';
    return '${_two(local.day)}/${_two(local.month)}/${local.year}, $time';
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}
