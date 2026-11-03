import 'package:flutter_test/flutter_test.dart';
import 'package:ordering_food_system/core/utils/search_text.dart';

void main() {
  group('normalizeSearchText', () {
    test('lowercases text', () {
      expect(normalizeSearchText('KIMBAP'), 'kimbap');
    });

    test('removes every Vietnamese tone mark', () {
      expect(normalizeSearchText('àáạảã'), 'aaaaa');
      expect(normalizeSearchText('èéẹẻẽ'), 'eeeee');
      expect(normalizeSearchText('ìíịỉĩ'), 'iiiii');
      expect(normalizeSearchText('òóọỏõ'), 'ooooo');
      expect(normalizeSearchText('ùúụủũ'), 'uuuuu');
      expect(normalizeSearchText('ỳýỵỷỹ'), 'yyyyy');
    });

    test('removes letter modifiers with and without tones', () {
      expect(normalizeSearchText('ăằắặẳẵ'), 'aaaaaa');
      expect(normalizeSearchText('âầấậẩẫ'), 'aaaaaa');
      expect(normalizeSearchText('êềếệểễ'), 'eeeeee');
      expect(normalizeSearchText('ôồốộổỗ'), 'oooooo');
      expect(normalizeSearchText('ơờớợởỡ'), 'oooooo');
      expect(normalizeSearchText('ưừứựửữ'), 'uuuuuu');
    });

    test('handles uppercase accented letters', () {
      expect(normalizeSearchText('ĂÂÊÔƠƯ ẤỀỘỮ'), 'aaeoou aeou');
    });

    test('maps đ and Đ to d', () {
      expect(normalizeSearchText('Đồ uống đá'), 'do uong da');
    });

    test('removes combining marks from decomposed input', () {
      // "Trà sữa" typed as base letters followed by combining marks.
      expect(normalizeSearchText('Trà sưã'), 'tra sua');
    });

    test('collapses and trims whitespace', () {
      expect(normalizeSearchText('  Trà   sữa \t trân  '), 'tra sua tran');
    });

    test('keeps symbols and digits', () {
      expect(normalizeSearchText('Mỳ ý + Gà rán'), 'my y + ga ran');
      expect(normalizeSearchText('7UP & Coca-Cola'), '7up & coca-cola');
    });

    test('is idempotent', () {
      const input = 'Trà Sữa Trân Châu Đường Đen';
      final once = normalizeSearchText(input);
      expect(normalizeSearchText(once), once);
    });
  });

  group('limitSearchKeyword', () {
    test('trims surrounding whitespace', () {
      expect(limitSearchKeyword('  gà  '), 'gà');
    });

    test('whitespace only becomes empty', () {
      expect(limitSearchKeyword('   \t '), isEmpty);
    });

    test('keeps at most 50 characters', () {
      final long = 'ă' * 60;
      expect(limitSearchKeyword(long).runes.length, maxSearchKeywordLength);
      expect(limitSearchKeyword(long), 'ă' * 50);
    });

    test('keeps short keywords unchanged', () {
      expect(limitSearchKeyword('trà sữa'), 'trà sữa');
    });
  });
}
