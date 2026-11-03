/// Keeps the currency sign on the same line as the amount.
const _nbsp = ' ';

/// Formats a whole VND amount with Vietnamese digit grouping.
String formatVnd(int amount) => '${_groupThousands(amount)}$_nbsp₫';

/// Formats a price range, collapsing to a single price when both ends match.
String formatVndRange(int min, int max) {
  if (min == max) {
    return formatVnd(min);
  }
  return '${_groupThousands(min)} – ${_groupThousands(max)}$_nbsp₫';
}

String _groupThousands(int amount) {
  final digits = amount.abs().toString();
  final buffer = StringBuffer(amount < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(digits[i]);
  }
  return buffer.toString();
}
