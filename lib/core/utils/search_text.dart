/// Longest keyword used for searching; extra characters are ignored.
const maxSearchKeywordLength = 50;

const _foldGroups = {
  'a': 'àáạảãâầấậẩẫăằắặẳẵ',
  'e': 'èéẹẻẽêềếệểễ',
  'i': 'ìíịỉĩ',
  'o': 'òóọỏõôồốộổỗơờớợởỡ',
  'u': 'ùúụủũưừứựửữ',
  'y': 'ỳýỵỷỹ',
  'd': 'đ',
};

final Map<int, int> _foldTable = {
  for (final entry in _foldGroups.entries)
    for (final rune in entry.value.runes) rune: entry.key.codeUnitAt(0),
};

final _whitespace = RegExp(r'\s+');

/// Lowercases [input], removes Vietnamese diacritics (`đ` becomes `d`) and
/// collapses whitespace, so "Trà  Sữa" and "tra sua" compare equal.
///
/// Characters outside the Vietnamese alphabet are kept as they are.
String normalizeSearchText(String input) {
  final buffer = StringBuffer();
  for (final rune in input.toLowerCase().runes) {
    if (_isCombiningMark(rune)) {
      continue;
    }
    buffer.writeCharCode(_foldTable[rune] ?? rune);
  }
  return buffer.toString().replaceAll(_whitespace, ' ').trim();
}

/// Trims [input] and keeps at most [maxSearchKeywordLength] characters.
String limitSearchKeyword(String input) {
  final trimmed = input.trim();
  final runes = trimmed.runes;
  if (runes.length <= maxSearchKeywordLength) {
    return trimmed;
  }
  return String.fromCharCodes(runes.take(maxSearchKeywordLength)).trimRight();
}

/// Combining diacritical marks left by decomposed (NFD) keyboard input.
bool _isCombiningMark(int rune) => rune >= 0x0300 && rune <= 0x036F;
