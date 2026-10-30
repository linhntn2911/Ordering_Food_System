import 'package:flutter_test/flutter_test.dart';
import 'package:ordering_food_system/core/utils/vnd_format.dart';

void main() {
  group('formatVnd', () {
    test('groups thousands with dots and appends the currency sign', () {
      expect(formatVnd(0), '0 ₫');
      expect(formatVnd(999), '999 ₫');
      expect(formatVnd(1000), '1.000 ₫');
      expect(formatVnd(45000), '45.000 ₫');
      expect(formatVnd(1250000), '1.250.000 ₫');
    });
  });

  group('formatVndRange', () {
    test('collapses equal bounds to a single price', () {
      expect(formatVndRange(45000, 45000), '45.000 ₫');
    });

    test('shows both bounds with one currency sign', () {
      expect(formatVndRange(45000, 65000), '45.000 – 65.000 ₫');
    });
  });
}
