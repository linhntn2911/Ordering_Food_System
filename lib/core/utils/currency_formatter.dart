/// Utility for formatting VND currency
class CurrencyFormatter {
  static String formatVND(num amount) {
    final int value = amount.round();
    final String str = value.abs().toString();
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return '${value < 0 ? '-' : ''}${buffer.toString()} đ';
  }
}
