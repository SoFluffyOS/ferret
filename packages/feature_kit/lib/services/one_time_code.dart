/// Spots texts and notifications that carry a one-time code: a sign-in, bank or
/// delivery code that shouldn't show up on every computer in the house.
abstract final class OneTimeCode {
  /// 4 to 8 digits, alone or split once by a space or a dash ("123 456"),
  /// or after a "G-" style prefix.
  static final _code = RegExp(
    r'(?<![\d.,:/-])(?:[A-Z]-)?\d{3,4}[ -]?\d{1,4}(?![\d,:/-]|\.\d)',
  );

  /// Words that sit next to such codes, in the languages people mostly
  /// get them in. Lowercase.
  static const _words = [
    'code',
    'otp',
    'one-time',
    'one time',
    'verification',
    'verify',
    'passcode',
    'password',
    'pin',
    '2fa',
    'two-factor',
    'security',
    'sign in',
    'sign-in',
    'log in',
    'login',
    'authenticat',
    'código',
    'codice',
    'kod',
    'код',
    'mã',
    '验证码',
    '認証',
  ];

  /// Whether [text] holds a code next to a word that says it is one.
  static bool isIn(String text) {
    final lower = text.toLowerCase();
    final hasWord = _words.any(lower.contains);
    if (!hasWord) {
      return false;
    }

    return _code.allMatches(text).any((match) => _digits(match[0]) >= 4);
  }

  /// The code in [text], digits only ("123 456" gives "123456"), or null
  /// when [isIn] says there is none.
  static String? find(String text) {
    if (!isIn(text)) {
      return null;
    }

    final match = _code
        .allMatches(text)
        .where((match) => _digits(match[0]) >= 4)
        .first;
    return (match[0] ?? '').replaceAll(RegExp(r'[^0-9]'), '');
  }

  static int _digits(String? found) =>
      (found ?? '').runes.where((rune) => rune >= 0x30 && rune <= 0x39).length;
}
