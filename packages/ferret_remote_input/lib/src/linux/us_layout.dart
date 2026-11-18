import 'package:ferret_remote_input/src/keys/keys.dart';

/// A character as keys on a US keyboard: the key's Linux code, and whether
/// Shift is held. Typing through uinput goes through the computer's
/// keyboard layout, so only a US layout types these exactly.
typedef UsKey = ({int code, bool shift});

abstract final class UsLayout {
  static final Map<String, UsKey> _keys = _build();

  /// The keys for [character], or null when a US keyboard can't type it.
  static UsKey? keyOf(String character) => _keys[character];

  static Map<String, UsKey> _build() {
    final keys = <String, UsKey>{};
    for (final key in InputKey.values) {
      final code = LinuxKeyCodes.keys[key];
      if (code == null) {
        continue;
      }

      if (key.name.length == 1) {
        keys[key.name] = (code: code, shift: false);
        keys[key.name.toUpperCase()] = (code: code, shift: true);
      }
    }

    const shiftedDigits = ')!@#\$%^&*(';
    for (var digit = 0; digit < 10; digit++) {
      final code = LinuxKeyCodes.keys[InputKey.values.byName('digit$digit')];
      if (code == null) {
        continue;
      }

      keys['$digit'] = (code: code, shift: false);
      keys[shiftedDigits[digit]] = (code: code, shift: true);
    }

    const punctuation = [
      ('-', '_', LinuxKeyCodes.minus),
      ('=', '+', LinuxKeyCodes.equal),
      ('[', '{', LinuxKeyCodes.leftBrace),
      (']', '}', LinuxKeyCodes.rightBrace),
      (';', ':', LinuxKeyCodes.semicolon),
      ("'", '"', LinuxKeyCodes.apostrophe),
      ('`', '~', LinuxKeyCodes.grave),
      ('\\', '|', LinuxKeyCodes.backslash),
      (',', '<', LinuxKeyCodes.comma),
      ('.', '>', LinuxKeyCodes.dot),
      ('/', '?', LinuxKeyCodes.slash),
    ];
    for (final (plain, shifted, code) in punctuation) {
      keys[plain] = (code: code, shift: false);
      keys[shifted] = (code: code, shift: true);
    }

    final space = LinuxKeyCodes.keys[InputKey.space];
    final enter = LinuxKeyCodes.keys[InputKey.enter];
    final tab = LinuxKeyCodes.keys[InputKey.tab];
    if (space != null && enter != null && tab != null) {
      keys[' '] = (code: space, shift: false);
      keys['\n'] = (code: enter, shift: false);
      keys['\t'] = (code: tab, shift: false);
    }

    return keys;
  }
}
