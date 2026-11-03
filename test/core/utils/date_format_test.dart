import 'package:flutter_test/flutter_test.dart';
import 'package:ordering_food_system/core/utils/date_format.dart';

void main() {
  test('pads day and month', () {
    expect(formatReviewDate(DateTime(2026, 3, 5)), '05/03/2026');
  });

  test('keeps two-digit values', () {
    expect(formatReviewDate(DateTime(2026, 10, 20, 23, 59)), '20/10/2026');
  });

  test('uses local time for UTC dates', () {
    final utc = DateTime.utc(2026, 10, 18, 12);
    final local = utc.toLocal();
    final expected =
        '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year}';

    expect(formatReviewDate(utc), expected);
  });
}
