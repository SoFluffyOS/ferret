/// A key by what it is, the same on every platform. Text is typed as text;
/// keys are for shortcuts and keys that type nothing.
enum InputKey {
  enter,
  backspace,
  delete,
  tab,
  escape,
  space,
  arrowLeft,
  arrowRight,
  arrowUp,
  arrowDown,
  home,
  end,
  pageUp,
  pageDown,
  mediaPlayPause,
  mediaNext,
  mediaPrevious,
  volumeUp,
  volumeDown,
  volumeMute,
  f1,
  f2,
  f3,
  f4,
  f5,
  f6,
  f7,
  f8,
  f9,
  f10,
  f11,
  f12,
  a,
  b,
  c,
  d,
  e,
  f,
  g,
  h,
  i,
  j,
  k,
  l,
  m,
  n,
  o,
  p,
  q,
  r,
  s,
  t,
  u,
  v,
  w,
  x,
  y,
  z,
  digit0,
  digit1,
  digit2,
  digit3,
  digit4,
  digit5,
  digit6,
  digit7,
  digit8,
  digit9,
  minus,
  equal,
  bracketLeft,
  bracketRight,
  backslash,
  semicolon,
  quote,
  backquote,
  comma,
  period,
  slash;

  /// Punctuation keys and what each types on a US keyboard without Shift.
  static const Map<InputKey, String> punctuation = {
    minus: '-',
    equal: '=',
    bracketLeft: '[',
    bracketRight: ']',
    backslash: '\\',
    semicolon: ';',
    quote: "'",
    backquote: '`',
    comma: ',',
    period: '.',
    slash: '/',
  };

  /// What this key types on a US keyboard without Shift, or null for a
  /// key that types nothing.
  String? get character => switch (this) {
    space => ' ',
    final digit when digit.name.startsWith('digit') => digit.name.substring(5),
    final letter when letter.index >= a.index && letter.index <= z.index =>
      letter.name,
    _ => punctuation[this],
  };

  /// Media and volume keys, which macOS sends as system events.
  bool get isMedia => switch (this) {
    mediaPlayPause ||
    mediaNext ||
    mediaPrevious ||
    volumeUp ||
    volumeDown ||
    volumeMute => true,
    _ => false,
  };

  /// The key for a letter, digit or US punctuation mark, ignoring case,
  /// or null.
  static InputKey? ofCharacter(String character) {
    if (character.length != 1) {
      return null;
    }

    final lower = character.toLowerCase();
    final code = lower.codeUnitAt(0);
    if (code >= 0x61 && code <= 0x7a) {
      return InputKey.values.byName(lower);
    }

    if (code >= 0x30 && code <= 0x39) {
      return InputKey.values.byName('digit$lower');
    }

    if (lower == ' ') {
      return space;
    }

    for (final MapEntry(:key, :value) in punctuation.entries) {
      if (value == lower) {
        return key;
      }
    }

    return null;
  }
}
