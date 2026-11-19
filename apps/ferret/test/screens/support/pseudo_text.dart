/// Turns English into a pseudo-locale: accented letters, about 40% longer
/// and wrapped in brackets. Untranslated text shows without brackets, a
/// sentence glued from two strings shows two bracket pairs, and the extra
/// length finds labels that only fit in English.
String pseudo(String english) {
  if (english.trim().isEmpty) {
    return english;
  }

  final accented = english.split('').map((char) => _accents[char] ?? char);
  final padding = '~' * (english.length * 0.4).ceil();
  return '[${accented.join()}$padding]';
}

const _accents = {
  'a': 'á',
  'c': 'ç',
  'e': 'é',
  'i': 'í',
  'n': 'ñ',
  'o': 'ö',
  'u': 'ü',
  'y': 'ý',
  'A': 'Å',
  'C': 'Ç',
  'E': 'É',
  'I': 'Î',
  'N': 'Ñ',
  'O': 'Ö',
  'U': 'Û',
  'Y': 'Ý',
};
