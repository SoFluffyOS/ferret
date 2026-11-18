import 'package:ferret_remote_input/src/keys/keys.dart';

/// One raw key press or release, in a platform's codes.
typedef RawKey = ({int code, bool pressed});

/// Turns a key with modifiers into raw presses, for platforms that hold the
/// modifier keys themselves (Windows, uinput, ydotool). Only modifiers that
/// aren't already down are pressed, and released again with the key.
class KeyChords {
  KeyChords(this._modifierCodes);

  final Map<KeyModifier, int> _modifierCodes;
  final Map<int, Set<KeyModifier>> _added = {};

  List<RawKey> press(int code, Set<KeyModifier> modifiers) {
    final held = {for (final added in _added.values) ...added};
    final toPress = modifiers.difference(held);
    _added[code] = toPress;

    return [
      for (final modifier in KeyModifier.values)
        if (toPress.contains(modifier))
          (code: _codeOf(modifier), pressed: true),
      (code: code, pressed: true),
    ];
  }

  List<RawKey> release(int code) {
    final added = _added.remove(code) ?? const <KeyModifier>{};

    return [
      (code: code, pressed: false),
      for (final modifier in KeyModifier.values.reversed)
        if (added.contains(modifier)) (code: _codeOf(modifier), pressed: false),
    ];
  }

  /// A press and release, such as for a typed character with Shift.
  List<RawKey> tap(int code, Set<KeyModifier> modifiers) => [
    ...press(code, modifiers),
    ...release(code),
  ];

  void reset() => _added.clear();

  int _codeOf(KeyModifier modifier) => _modifierCodes[modifier] ?? 0;
}
